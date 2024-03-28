#FROM amazon/aws-lambda-python:3.11@sha256:99cadc3bd9674a32a4ef694ff2e27f0b3d6c7f369b174db792b0099699fa0da4
#COPY lambda_locust.py .
#COPY tests ./tests
#COPY requirements.txt .
#RUN yum -y groupinstall "Development Tools"
#RUN pip3 install --upgrade pip
#RUN pip3 install -r requirements.txt
#CMD ["lambda_locust.handler"]

FROM public.ecr.aws/lambda/nodejs:18 as builder
WORKDIR /usr/app
COPY package.json tsconfig.json yarn.lock nagware.ts ./
COPY lib ./lib
COPY types ./types
RUN npm install -g yarn
RUN yarn install
RUN yarn build
    
FROM public.ecr.aws/lambda/nodejs:18
WORKDIR ${LAMBDA_TASK_ROOT}
COPY --from=builder /usr/app/dist/* ./
CMD ["nagware.handler"]

#docker build --platform linux/amd64 -t nagware-lambda-image:test .