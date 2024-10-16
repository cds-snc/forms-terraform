fmt:
	black .

install:
	pip3 install --user -r requirements.txt

locust:
	locust -f tests/locust_test_file.py --host=https://forms-staging.cdssandbox.xyz

.PHONY: \
	fmt \
	install	\
	locust
