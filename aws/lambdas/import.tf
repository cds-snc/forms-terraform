import {
    to = aws_cloudwatch_log_group.archive_form_templates
    id = "aws/lambda/ArchiveFormTemplates"
}

import {
    to = aws_cloudwatch_log_group.audit_logs
    id = "/aws/lambda/AuditLogs"
}

import {
    to = aws_cloudwatch_log_group.dead_letter_queue_consumer
    id = "/aws/lambda/DeadLetterQueueConsumer"
}

import {
    to = aws_cloudwatch_log_group.nagware
    id = "/aws/lambda/Nagware"
}

import {
    to = aws_cloudwatch_log_group.reliability
    id = "/aws/lambda/Reliability"
}

import {
    to = aws_cloudwatch_log_group.submission
    id = "/aws/lambda/Submission"
}

import {
    to = aws_cloudwatch_log_group.vault_integrity
    id = "/aws/lambda/VaultDataIntegrityCheck"
}

import {
    to = aws_cloudwatch_log_group.response_archiver
    id = "/aws/lambda/Archiver"
}