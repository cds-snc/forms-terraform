FROM amazon/aws-lambda-python:3.11@sha256:8d7a189af42d0cbd14ccda1621192e0caeca1e131c16c6ad94ce4541335e7057

COPY lambda_locust.py .
COPY tests ./tests
COPY requirements.txt .

RUN pip3 install -r requirements.txt

CMD ["lambda_locust.handler"]