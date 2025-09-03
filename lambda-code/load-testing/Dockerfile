FROM amazon/aws-lambda-python:3.13@sha256:01b4aadb2181e2aa473dd7eb8a125de366cbcf77e6aa75cc2b3b719775da49b4

COPY requirements.txt .
RUN pip3 install -r requirements.txt

COPY main.py .
COPY custom_create_settings.py .
COPY tests ./tests

CMD ["main.handler"]