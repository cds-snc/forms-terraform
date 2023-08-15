FROM amazon/aws-lambda-python:3.11@sha256:b0eb4dec74144e9c78a5111659833a5fd4eca1fa01f08b7668db07436c18c40b

COPY lambda_locust.py .
COPY tests ./tests
COPY requirements.txt .

RUN pip3 install -r requirements.txt

CMD ["lambda_locust.handler"]