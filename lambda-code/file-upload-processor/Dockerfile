FROM public.ecr.aws/lambda/nodejs:22 AS build

WORKDIR /usr/app

RUN npm install -g yarn
RUN yarn set version 4.10.3

COPY .yarnrc.yml package.json yarn.lock ./

RUN yarn install --frozen-lockfile

COPY src ./src
COPY tsconfig.json ./

RUN yarn build

FROM public.ecr.aws/lambda/nodejs:22

WORKDIR ${LAMBDA_TASK_ROOT}

COPY package.json ./
COPY --from=build /usr/app/node_modules ./node_modules
COPY --from=build /usr/app/build ./

CMD ["main.handler"]