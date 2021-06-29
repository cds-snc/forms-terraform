#!/bin/bash
find . -maxdepth 3 -name package.json -execdir yarn install \;