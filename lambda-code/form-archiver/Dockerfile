
FROM public.ecr.aws/lambda/nodejs:22 AS open_telemetry

# Install utilities
RUN dnf install -y unzip wget

# Download the OpenTelemetry Layer with AppSignals Support
RUN wget https://github.com/aws-observability/aws-otel-js-instrumentation/releases/latest/download/layer.zip -O /tmp/layer.zip

# Extract and include Lambda layer contents
RUN mkdir -p /opt
WORKDIR /opt
RUN unzip /tmp/layer.zip -d ./
RUN chmod -R 755 /opt/

FROM public.ecr.aws/lambda/nodejs:22 as build

WORKDIR /usr/app

RUN npm install -g yarn
RUN yarn set version 4.9.1

COPY .yarnrc.yml package.json yarn.lock ./

RUN yarn install --frozen-lockfile

COPY src ./src
COPY tsconfig.json ./

RUN yarn build

FROM public.ecr.aws/lambda/nodejs:22
ENV AWS_LAMBDA_EXEC_WRAPPER=/opt/otel-instrument
WORKDIR ${LAMBDA_TASK_ROOT}

COPY package.json ./
COPY --from=build /usr/app/node_modules ./node_modules
COPY --from=build /usr/app/build ./
COPY --from=open_telemetry /opt /opt

CMD ["main.handler"]