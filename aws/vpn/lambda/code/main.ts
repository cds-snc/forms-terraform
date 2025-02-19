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
              response.ClientVpnTargetNetworks?.map((network) => network.AssociationId)
            );
          return {
            vpnEndpointId: vpnEndpoint.ClientVpnEndpointId,
            vpcId: vpnEndpoint.VpcId,
            networkAssociations,
          };
        })
      );
    });

  // Get VPN Connections for each VPN Endpoint
  const vpnConnectionsPromises = vpnEndpoints.map((vpnEndpoint) => {
    return ec2Client.send(
      new DescribeClientVpnConnectionsCommand({ ClientVpnEndpointId: vpnEndpoint.vpnEndpointId })
    );
  });

  // GMT time is 4 hours ahead of EST time
  // 06h to 20h EST is 10h to 00h GMT
  // Outside of this time range, the VPN connections should be terminated
  if (isCurrentTimeBetween("10:00", "23:59")) {
    // After normal working hours, the VPN connections should be terminated
    await disassociateVpnEndpoint(vpnEndpoints, ec2Client);
  } else {
    // Get VPN Connections for each VPN Endpoint
    const vpnConnections = await Promise.all(vpnConnectionsPromises)
      .then((responses) => responses.map((response) => response.Connections))
      .then((connections) => connections.flat());
    // Check if there are any active connections
    const activeVpnConnections = vpnConnections.filter(
      (vpnConnection) => vpnConnection?.Status?.Code === "active"
    );

    if (activeVpnConnections.length > 0) {
      console.log("Active VPN connections found. Not removing VPN Endpoint.");
    } else {
      console.log("No active VPN connections found. Removing VPN Endpoint.");
      await disassociateVpnEndpoint(vpnEndpoints, ec2Client);
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

async function disassociateVpnEndpoint(
  vpnEndpoints: {
    vpnEndpointId?: string;
    vpcId?: string;
    networkAssociations?: (string | undefined)[];
  }[],
  ec2Client: EC2Client
) {
  return Promise.all(
    vpnEndpoints.map((vpnEndpoint) => {
      if (vpnEndpoint.networkAssociations && vpnEndpoint.networkAssociations.length > 0) {
        console.info(
          `Disassociating VPN Endpoint ${vpnEndpoint.vpnEndpointId} from VPC ${vpnEndpoint.vpcId}`
        );
        // Dissociate the VPN Endpoint from the VPC
        return vpnEndpoint.networkAssociations.map((associationId) =>
          ec2Client.send(
            new DisassociateClientVpnTargetNetworkCommand({
              AssociationId: associationId,
              ClientVpnEndpointId: vpnEndpoint.vpnEndpointId,
            })
          )
        );
      } else {
        console.info(`No network associations found for VPN Endpoint ${vpnEndpoint.vpnEndpointId}`);
      }
    })
  );
}
