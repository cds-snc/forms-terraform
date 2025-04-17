FROM --platform=linux/amd64 public.ecr.aws/lambda/nodejs:22 as builder

WORKDIR /usr/app

RUN npm install -g yarn

COPY package.json yarn.lock ./

RUN yarn install --frozen-lockfile

COPY lib ./lib
COPY main.ts tsconfig.json ./

RUN yarn build

FROM --platform=linux/amd64 public.ecr.aws/lambda/nodejs:22

WORKDIR ${LAMBDA_TASK_ROOT}

COPY --from=builder /usr/app/dist/ ./

CMD ["main.handler"]