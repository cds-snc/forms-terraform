#!/bin/bash

#
# Helper script to invoke dead letter queue consumer lambda function
#

echo '{}' | sam local invoke -t ./local_development/template.yml --event - "DeadLetterQueueConsumer"