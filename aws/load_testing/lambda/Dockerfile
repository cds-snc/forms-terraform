FROM amazon/aws-lambda-python:3.10@sha256:d313fe8d38c0f279ddc1198fb2d14db0235d895c74b89c107a2aa62e206c7223

COPY lambda_locust.py .
COPY tests ./tests
COPY requirements.txt .

RUN pip3 install -r requirements.txt

CMD ["lambda_locust.handler"]