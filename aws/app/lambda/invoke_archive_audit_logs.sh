#!/bin/bash

#
# Helper script to invoke the archive audit log lambda function
#

echo '{}' | sam local invoke -t ./local_development/template.yml --event - "ArchiveAuditLogs"