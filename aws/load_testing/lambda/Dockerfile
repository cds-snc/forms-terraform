FROM amazon/aws-lambda-python:3.11@sha256:93f1bd317ac630ad7fac3e5acd782697a6c1c0a461b2cb254e205328fd27ca53
COPY lambda_locust.py .
COPY tests ./tests
COPY requirements.txt .

RUN yum groupinstall "Development Tools"

RUN pip3 install --upgrade pip

RUN pip3 install -r requirements.txt

CMD ["lambda_locust.handler"]