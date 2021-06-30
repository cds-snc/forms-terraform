#!/bin/bash
find . -maxdepth 3 -name package.json -execdir yarn install \;
cd ./local_development
sam local start-lambda