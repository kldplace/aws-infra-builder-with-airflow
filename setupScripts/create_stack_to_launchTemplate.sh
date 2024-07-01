#!/bin/bash

# Path to the export file
EXPORT_VARIABLES_FILE="/home/kld/Github_projects/aws-infra-builder-with-airflow/infrastructure_variables.sh"
# Source the export file to get the VPC_ID variable
if [[ -f "$EXPORT_VARIABLES_FILE" ]]; then
    source "$EXPORT_VARIABLES_FILE"
else
    echo "Export file not found: $EXPORT_VARIABLES_FILE"
    exit 1
fi

# DatabaseName: WPDatabase
# DatabaseHostName: The writer endpoint of the DB cluster
# DatabaseUsername: admin
# DatabasePassword: <password>
# Username: wpadmin / note: WordPress admin username
# Password: <password> / note: WordPress admin password
# Email: <email> / note: WordPress admin email address
# EC2ServerInstanceType: t3.medium
# ALBDnsName: <Application load balancer DNS name>
# WPElasticFileSystemID: <EFS: File system ID>
# AppInstanceSecurityGroupID: <APP instance security group ID>
# VPCID: <VPC ID>
# EFSMountTargetSecurityGroupID: <EFS Mount Target security group>
# RDSSecurityGroupID: <RDS security group ID>

aws cloudformation create-stack \
  --stack-name myWordPressStack \
  --template-body file:///home/kld/Github_projects/aws-infra-builder-with-airflow/CloudFormation_yaml/step-05-launchTemplate.yaml \
  --parameters ParameterKey=DatabaseName,ParameterValue=$INITIAL_DATABASE_NAME \
               ParameterKey=DatabaseHostName,ParameterValue=$WRITER_ENDPOINT \
               ParameterKey=DatabaseUsername,ParameterValue=$MASTER_USERNAME \
               ParameterKey=DatabasePassword,ParameterValue=$MASTER_USERPASSWORD \
               ParameterKey=Username,ParameterValue=wpadmin \
               ParameterKey=Password,ParameterValue=$MASTER_USERPASSWORD \
               ParameterKey=Email,ParameterValue=$EMAIL \
               ParameterKey=EC2ServerInstanceType,ParameterValue=t3.medium \
               ParameterKey=ALBDnsName,ParameterValue=$APP_LOADBALANCER_DNS \
               ParameterKey=WPElasticFileSystemID,ParameterValue=$FILE_SYSTEM_ID \
               ParameterKey=AppInstanceSecurityGroupID,ParameterValue=$APPINSTANCE_SECURITY_GROUP_ID \
               ParameterKey=VPCID,ParameterValue=$VPC_ID \
               ParameterKey=EFSMountTargetSecurityGroupID,ParameterValue=$EFSMountTarget_SECURITY_GROUP_ID \
               ParameterKey=RDSSecurityGroupID,ParameterValue=$RDS_SECURITY_GROUP_ID \
  --capabilities CAPABILITY_NAMED_IAM
