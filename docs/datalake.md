# Datalake Documentation

Internal Documentation can be found (here)[https://docs.google.com/document/d/1vEZ4vpQDuu6UCpSlkwCLD_dOQnqZeVfvq8Ml1hz5hHo/edit?tab=t.0#heading=h.jrx19nczj5fa].

Setup and initialization instructions are detailed in the base repository README file.

## AWS Glue

Forms leverages (AWS Glue)[https://docs.aws.amazon.com/glue/latest/dg/what-is-glue.html] for ETL (Extract, Transform, Load) jobs. Glue provides scalable data processing capabilities with Apache Spark under the hood, allowing for efficient large-scale data manipulation.

In case of a future migration away from AWS Glue, Lambda functions can serve as an alternative solution. However, migrating to Lambda may reduce performance due to cold starts and concurrency limitations, potentially increasing operational costs. Carefully evaluate trade-offs before making such a transition

### Structure
* ./aws/glue contains the necessary terraform scripts.
* ./aws/glue/data contains dummy data for a historical data import. This script is a one time run handled by the Platform team, and this file exists for the purpose of local testing.
* ./aws/glue/scripts contains the ETL Jobs.

## Data Elements Extracted

* Form
** id
** isPublished
** created_at
** updated_at
** name
** securityAttribute
** closingDate
** formPurpose
** publishDesc
** publishFormType
** publishReason
** timestamp
** [elementType]_count
** ttl
** closedDetails
** titleEn
** titleFr
** brand
** deliveryoption

* Form to User
** userId
** templateId

* User
** id
** name
** email
** lastLogin
** active
** createdAt
** timestamp

* Submissions
** Form ID
** Submission ID
** timestamp

## ETL Scripts

ETL Scripts leverage Python and (Apache PySpark)[https://spark.apache.org/docs/latest/api/python/index.html]. All data extracts use the (Apache Paraquet Dataformat)[https://parquet.apache.org].

### Historical

The Historical scripts serves to extra data exported from Airtable CSV Extract. It applies no transformations, and is simply for the purpose of accessing data stored prior to the launch of the Data Lake for reporting purposes.

### RDS

The RDS Script serves to extract data from the PostgresSQL RDS source, transform it, and load the processed results into an S3 bucket.

It strips unnecessary or potentially sensitive information, and converts timestamps to a format that can be viewed by Amazon's Athena service.

### Submissions

The RDS Script serves to extract counts for submissions, allowing a simple aggregate.

## Testing and Validation

To test and validate Glue Jobs...

### Glue Jobs General Testing Steps
1. Start the platform-forms-client application.
2. Log in to the desired account with sufficient permissions.
3. Create or modify a form to trigger ETL processes.

### To test RDS...
1. Navigate to AWS Glue console.
2. Go to Jobs → Visual ETL → Execute "rds_glue_job".
3. Once completed, initiate the RDS crawler from Crawlers menu to update AWS Glue catalog.
4. Inspect the updated tables (rds_report_forms, rds_report_users) via the Glue console to validate data accuracy.

### To Test submissions...
1. Submit a test entry via the forms client application.
2. Run the "submissions_glue_job" via AWS Glue console (Jobs → Visual ETL).
3. After completion, trigger the crawler to update Glue data catalog.
4. Validate the results by viewing the table rds_report_submissions in AWS Glue.

### For Errors...
Errors occurring in Glue Jobs will be logged to AWS CloudWatch Logs.

When a Critical errors affecting a Glue operation occurs will also be reported directly in the AWS Web UI for that component for rapid visibility.