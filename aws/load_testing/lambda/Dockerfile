FROM amazon/aws-lambda-python:3.7@sha256:4aead3a75aa0c0b63a493bb8c5417ee0f1a166cde60e9c49f382817761ea827e

COPY lambda_locust.py .
COPY tests ./tests
COPY requirements.txt .

RUN pip3 install --upgrade pip

RUN pip3 install -r requirements.txt

CMD ["lambda_locust.handler"]