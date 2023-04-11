#!/bin/bash

#
# Helper script to invoke the Nagware lambda function
#

cp -a ./nagware/lib/. ./nagware/nodejs/node_modules

echo '{}' | sam local invoke -t ./local_development/template.yml --event - "Nagware"