FROM amazon/aws-lambda-python:3.8

COPY lambda_locust.py .
COPY tests ./tests
COPY requirements.txt .

RUN pip3 install -r requirements.txt

CMD ["lambda_locust.handler"]