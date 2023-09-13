FROM amazon/aws-lambda-python:3.11@sha256:1f9ef82734d372f89ab92acef2acb208961d186bc197f3f28f634d0141782c4c
COPY lambda_locust.py .
COPY tests ./tests
COPY requirements.txt .

RUN yum -y groupinstall "Development Tools"

RUN pip3 install --upgrade pip

RUN pip3 install -r requirements.txt

CMD ["lambda_locust.handler"]