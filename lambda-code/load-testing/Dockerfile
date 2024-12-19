FROM amazon/aws-lambda-python:3.13@sha256:356eadf91ea8afa08ab2eea32834141a696c4feaae41120b837ebe38258091d1

COPY requirements.txt .
RUN pip3 install -r requirements.txt

COPY main.py .
COPY tests ./tests

CMD ["main.handler"]