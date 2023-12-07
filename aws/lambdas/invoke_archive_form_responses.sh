#!/bin/bash

#
# Helper script to invoke the archive form responses lambda function
#

cp -a ./archive_form_responses/lib/. ./archive_form_responses/nodejs/node_modules

echo '{}' | sam local invoke -t ./local_development/template.yml --event - "ArchiveFormResponses"