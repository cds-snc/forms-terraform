#!/bin/bash
find . -maxdepth 3 -name package.json -execdir yarn install \;
sam local start-lambda -t ./local_development/template.yml