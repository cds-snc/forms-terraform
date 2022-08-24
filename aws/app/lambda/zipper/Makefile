.PHONY: clean fmt fmt-ci install lint

clean:
	yarn --cwd=nodejs --force autoclean

fmt:
	yarn --cwd=nodejs format:write

fmt-ci:
	yarn --cwd=nodejs format:check

install:
	yarn --cwd=nodejs install
	
lint:
	yarn --cwd=nodejs lint
