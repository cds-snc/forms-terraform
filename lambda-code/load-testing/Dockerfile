# Due to some incompatibility between Locust and Python3.13 we are forced to use 3.12 (see https://github.com/locustio/locust/issues/3050)
FROM amazon/aws-lambda-python:3.12@sha256:1965397387bae8db437d907cbb8e17b490edc8912b9ecab6abd394649bd25c1f

COPY requirements.txt .
RUN pip3 install -r requirements.txt

COPY main.py .
COPY custom_create_settings.py .
COPY tests ./tests

CMD ["main.handler"]