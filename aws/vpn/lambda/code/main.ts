import {
  EC2Client,
  DescribeClientVpnConnectionsCommand,
  DescribeClientVpnEndpointsCommand,
  DisassociateClientVpnTargetNetworkCommand,
  DescribeClientVpnTargetNetworksCommand,
} from "@aws-sdk/client-ec2";
import { Handler } from "aws-lambda";

export const handler: Handler = async () => {
  const ec2Client = new EC2Client({ region: "ca-central-1" });
  // Get VPN Endpoints available in the account
  const vpnEndpoints = await ec2Client
    .send(new DescribeClientVpnEndpointsCommand({}))
    .then(async (response) => {
      const endpoints = response.ClientVpnEndpoints;
      if (!endpoints) {
        return [];
      }
      return Promise.all(
        endpoints.map(async (vpnEndpoint) => {
          const networkAssociations = await ec2Client
            .send(
              new DescribeClientVpnTargetNetworksCommand({
                ClientVpnEndpointId: vpnEndpoint.ClientVpnEndpointId,
              })
            )
            .then((response) =>
              response.ClientVpnTargetNetworks?.filter(
                (network) => network.Status?.Code === "associated"
              ).map((network) => network.AssociationId)
            );
          return {
            vpnEndpointId: vpnEndpoint.ClientVpnEndpointId,
            vpcId: vpnEndpoint.VpcId,
            networkAssociations,
          };
        })
      );
    });

  console.info(`Found ${vpnEndpoints.length} VPN Endpoints`);
  vpnEndpoints.forEach((vpnEndpoint) => {
    console.info(`VPN Endpoint data:`, vpnEndpoint);
  });

  // GMT time is 4 hours ahead of EST time
  // 20h to 06h EST is 00h to 10h GMT
  // Outside of this time range, the VPN connections should be terminated
  if (isCurrentTimeBetween("00:00", "10:00")) {
    // After normal working hours, the VPN connections should be terminated
    await disassociateVpnEndpoints(vpnEndpoints, ec2Client);
  } else {
    // Get VPN Connections for each VPN Endpoint
    const vpnConnections = await Promise.all(
      vpnEndpoints.map((vpnEndpoint) => {
        return ec2Client.send(
          new DescribeClientVpnConnectionsCommand({
            ClientVpnEndpointId: vpnEndpoint.vpnEndpointId,
          })
        );
      })
    )
      .then((responses) => responses.map((response) => response.Connections))
      .then((connections) => connections.flat());
    // Check if there are any active connections
    const activeVpnConnections = vpnConnections.filter(
      (vpnConnection) => vpnConnection?.Status?.Code === "active"
    );

    if (activeVpnConnections.length > 0) {
      console.log("Active VPN connections found. Not removing VPN Endpoint associations.");
    } else {
      console.log("No active VPN connections found. Removing VPN Endpoint associations.");
      // Logging only for now to see how often this is triggered
      // await disassociateVpnEndpoints(vpnEndpoints, ec2Client);
      console.warn("VPN Endpoint associations would have been removed during working hours.");
    }
  }
};

function isCurrentTimeBetween(startTime: string, endTime: string): boolean {
  const currentTime = new Date();
  const [startHour, startMinute] = startTime.split(":").map(Number);
  const [endHour, endMinute] = endTime.split(":").map(Number);

  const start = new Date(currentTime);
  start.setHours(startHour, startMinute, 0, 0);

  const end = new Date(currentTime);
  end.setHours(endHour, endMinute, 0, 0);

  return currentTime >= start && currentTime <= end;
}

async function disassociateVpnEndpoints(
  vpnEndpoints: {
    vpnEndpointId?: string;
    vpcId?: string;
    networkAssociations?: (string | undefined)[];
  }[],
  ec2Client: EC2Client
) {
  const disassociationPromises = vpnEndpoints.flatMap(async (vpnEndpoint) => {
    console.info(
      `Processing VPN Endpoint ${vpnEndpoint.vpnEndpointId} with ${vpnEndpoint.networkAssociations?.length} network associations`
    );
    if (vpnEndpoint.networkAssociations && vpnEndpoint.networkAssociations.length > 0) {
      console.info(
        `Disassociating VPN Endpoint association ${vpnEndpoint.vpnEndpointId} from VPC ${vpnEndpoint.vpcId}`
      );
      //Dissociate the VPN Endpoint from the VPC
      return await Promise.all(
        vpnEndpoint.networkAssociations.map((associationId) =>
          ec2Client.send(
            new DisassociateClientVpnTargetNetworkCommand({
              AssociationId: associationId,
              ClientVpnEndpointId: vpnEndpoint.vpnEndpointId,
            })
          )
        )
      );
    } else {
      console.info(`No network associations found for VPN Endpoint ${vpnEndpoint.vpnEndpointId}`);
    }
  });
  const results = await Promise.all(disassociationPromises);
  results.forEach((result) => {
    console.info("Disassociation result:", result);
  });
}
