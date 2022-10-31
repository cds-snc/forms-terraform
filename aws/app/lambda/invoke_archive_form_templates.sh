#!/bin/bash

#
# Helper script to invoke archive form templates lambda function
#

cp -a ./reliability/lib/. ./reliability/nodejs/node_modules

echo '{}' | sam local invoke -t ./local_development/template.yml --event - "ArchiveFormTemplates"