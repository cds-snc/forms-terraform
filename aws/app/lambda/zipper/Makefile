test_case = '' # Run all tests by default; otherwise run user specified test
.PHONY: dev fmt install lint migrations test fmt-ci lint-ci build install-dev load-test

build: ;

dev: ;

fmt:
	yarn --cwd=nodejs format:write

install:
	yarn --cwd=nodejs install

install-dev: ;
	
lint:
	yarn --cwd=nodejs lint

lint-ci:
	yarn --cwd=nodejs lint

load-test: ;

migrations: ;

test:
	yarn --cwd=nodejs test

fmt-ci:
	yarn --cwd=nodejs format:check