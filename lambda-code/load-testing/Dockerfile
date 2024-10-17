FROM amazon/aws-lambda-python:3.12@sha256:37b95206c4c78331f6d5cb0e8389ef573f39cfea01f73c530f28f3ac6f6493c7

COPY requirements.txt .
RUN pip3 install -r requirements.txt

COPY main.py .
COPY tests ./tests

CMD ["main.handler"]