FROM public.ecr.aws/lambda/nodejs:22

WORKDIR /var/task

# install unzip
RUN dnf install -y unzip groff less

# install new aws v2 cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" 
RUN unzip awscliv2.zip && ./aws/install && rm awscliv2.zip

# Install Yarn
RUN npm install -g yarn
RUN export PATH="$(yarn global bin):$PATH"

# Install global dependencies
RUN yarn global add prisma@6 tsx@4

# Install Prisma Seeding dependencies to current directory
RUN yarn add @prisma/client@6 prisma@6 ts-command-line-args@2 typescript@5

# Download correct Prisma engines for runtime
COPY base_schema.prisma ${LAMBDA_TASK_ROOT}
RUN prisma generate --schema=base_schema.prisma --allow-no-models
RUN rm -f base_schema.prisma

# Copy custom runtime bootstrap
COPY bootstrap ${LAMBDA_RUNTIME_DIR}
# Copy function code
COPY prisma.sh ${LAMBDA_TASK_ROOT}

RUN chmod +x ${LAMBDA_TASK_ROOT}/prisma.sh ${LAMBDA_RUNTIME_DIR}/bootstrap




# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "prisma.handler" ]