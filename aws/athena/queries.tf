resource "aws_athena_prepared_statement" "metric_number_of_forms" {
    name = "metric_number_of_forms"
    workgroup = aws_athena_workgroup.data_lake.name
    query_statement = <<EOF
        SELECT COUNT(unique_id)+(SELECT COUNT(*) FROM (
            SELECT 
           MAX(timestamp)
        FROM 
            ${var.glue_database_name}.rds_report_processed_data 
        GROUP BY id)) as "Form Count" FROM ${var.glue_database_name}.rds_report_historical_data
    EOF
}

resource "aws_athena_prepared_statement" "metric_historical_count" {
    name = "metric_historical_count"
    workgroup = aws_athena_workgroup.data_lake.name
    query_statement = "SELECT COUNT(unique_id) FROM ${var.glue_database_name}.rds_report_historical_data"
}