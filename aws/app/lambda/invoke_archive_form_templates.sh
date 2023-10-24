#!/bin/bash

#
# Helper script to invoke archive form templates lambda function
#

cp -a ./archive_form_templates/lib/. ./archive_form_templates/nodejs/node_modules

echo '{}' | sam local invoke -t ./local_development/template.yml --event - "ArchiveFormTemplates"