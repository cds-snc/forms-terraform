FROM public.ecr.aws/lambda/nodejs:22 as builder

WORKDIR /usr/app

RUN npm install -g yarn
RUN yarn set version stable

COPY package.json yarn.lock ./

RUN yarn install --frozen-lockfile

COPY src ./src
COPY tsconfig.json ./

RUN yarn build
    
FROM public.ecr.aws/lambda/nodejs:22

WORKDIR ${LAMBDA_TASK_ROOT}

COPY --from=builder /usr/app/dist/ ./

CMD ["main.handler"]