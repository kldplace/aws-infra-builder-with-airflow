from airflow import DAG
from airflow.operators.bash_operator import BashOperator
from datetime import datetime, timedelta


default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# Dag definition
dag = DAG(
        'aws_infrastructure_builder',
        default_args=default_args,
        description='A DAG to run a shell scripts to build aws infrastructure',
        schedule_interval=None,
    )

# Bash scripts tasks
aws_networking_task = BashOperator(
        task_id='creating_aws_networking',
        bash_command='bash {{ params.var }}',
        params={'var': '~/Github_projects/aws-infra-builder-with-airflow/setupScripts/create_networkingStructure.sh'},
        dag=dag,
    )

variables_for_configuration_task = BashOperator(
        task_id='create_some_essential_environment_variables',
        bash_command='bash {{ params.var }}',
        params={'var': '~/Github_projects/aws-infra-builder-with-airflow/setupScripts/config_variables.sh'},
        dag=dag,
    )

aws_database_task = BashOperator(
        task_id='creating_aws_database',
        bash_command='bash {{ params.var }}',
        params={'var': '~/Github_projects/aws-infra-builder-with-airflow/setupScripts/create_database.sh'},
        dag=dag,
    )


aws_EFSMountTarget_task = BashOperator(
        task_id='creating_aws_EFSMountTarget',
        bash_command='bash {{ params.var }}',
        params={'var': '~/Github_projects/aws-infra-builder-with-airflow/setupScripts/create_EFSMountTarget.sh'},
        dag=dag,
    )

aws_loadBalancing_task = BashOperator(
        task_id='creating_aws_targetGroupAndLoadBalancing',
        bash_command='bash {{ params.var }}',
        params={'var': '~/Github_projects/aws-infra-builder-with-airflow/setupScripts/create_targetGroup_balancer.sh'},
        dag=dag,
    )

delay_30min_task = BashOperator(
        task_id='delay_until_database_be_available',
        bash_command='sleep 30m',
        dag=dag,
    )

aws_launchTemplate_task = BashOperator(
        task_id='launchTemplate_for_aws_ec2',
        bash_command='bash {{ params.var }}',
        params={'var': '~/Github_projects/aws-infra-builder-with-airflow/setupScripts/create_stack_to_launchTemplate.sh'},
        dag=dag,
    )

delay_5min_task = BashOperator(
        task_id='delay_until_launchTemplate_and_wordPressSG_available',
        bash_command='sleep 5m',
        dag=dag,
    )

aws_autoScalingGroup_task = BashOperator(
        task_id='creating_aws_autoScalingGroup',
        bash_command='bash {{ params.var }}',
        params={'var': '~/Github_projects/aws-infra-builder-with-airflow/setupScripts/create_autoScalingGroup.sh'},
        dag=dag,
    )

aws_createBucket_task = BashOperator(
        task_id='creating_aws_s3Bucket_with_yaml_files',
        bash_command='bash {{ params.var }}',
        params={'var': '~/Github_projects/aws-infra-builder-with-airflow/aws_infrastructure_bucket/infrastructureBucket.sh'},
        dag=dag,
    )

# Run tasks
aws_networking_task >> variables_for_configuration_task >> [aws_database_task, aws_EFSMountTarget_task, aws_loadBalancing_task] >> delay_30min_task >> aws_launchTemplate_task >> delay_5min_task >> aws_autoScalingGroup_task >> aws_createBucket_task 