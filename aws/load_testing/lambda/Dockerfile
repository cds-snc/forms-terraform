FROM amazon/aws-lambda-python:3.10@sha256:287bf8bb9a03c96d18d52f6a5e4ab4a9e687ec103ab6f6a6c6d255c8f4854253

COPY lambda_locust.py .
COPY tests ./tests
COPY requirements.txt .

RUN pip3 install -r requirements.txt

CMD ["lambda_locust.handler"]