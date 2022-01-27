#!/bin/bash

#
# Helper script to invoke archiver lambda function
#

echo '{}' | sam local invoke -t ./local_development/template.yml --event - "Archiver"