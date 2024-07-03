.PHONY: build cert

# Build the IdP's Docker image
build: cert
	docker build -t idp/zitadel:latest ./docker -f ./docker/Dockerfile

# Generate the certificate used to encrypt load balancer traffic to the ECS task
cert:
	openssl \
		req \
		-nodes \
		-newkey rsa:2048 \
		-x509 -days 3650 \
		-keyout ./docker/private.key \
		-out ./docker/certificate.crt \
		-subj "/C=CA/ST=Ontario/L=Ottawa/O=cds-snc/OU=platform/CN=auth.forms-formulaires.alpha.canada.ca/emailAddress=platform@cds-snc.ca" > /dev/null 2>&1 &&\
	chmod +r ./docker/private.key
