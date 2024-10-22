FROM public.ecr.aws/lambda/nodejs:20 as builder

WORKDIR /usr/app

RUN npm install -g yarn

COPY package.json yarn.lock ./

RUN yarn install --frozen-lockfile

COPY main.ts utils.ts tsconfig.json ./

RUN yarn build
    
FROM public.ecr.aws/lambda/nodejs:20

WORKDIR ${LAMBDA_TASK_ROOT}

COPY --from=builder /usr/app/dist/ ./

CMD ["main.handler"]