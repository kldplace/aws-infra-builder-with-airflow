#!/bin/bash

# Path to (CloudFormation_yaml) folder
CLOUDFORMATION_FOLDER_PATH="/home/kld/Github_projects/aws-infra-builder-with-airflow/CloudFormation_yaml/"
# Creaete [infrastructure-bucket-2024] bucket
aws s3api create-bucket --bucket infrastructure-bucket-2024 --region me-south-1 --create-bucket-configuration LocationConstraint=me-south-1

# Upload yaml files that create our infrastructure
aws s3 cp $CLOUDFORMATION_FOLDER_PATH/step-01-create-networkingStructure.yaml s3://infrastructure-bucket-2024/step-01-create-networkingStructure.yaml
aws s3 cp $CLOUDFORMATION_FOLDER_PATH/step-02-create-database.yaml s3://infrastructure-bucket-2024/step-02-create-database.yaml
aws s3 cp $CLOUDFORMATION_FOLDER_PATH/step-03-create-EFSMountTarget.yaml s3://infrastructure-bucket-2024/step-03-create-EFSMountTarget.yaml
aws s3 cp $CLOUDFORMATION_FOLDER_PATH/step-04-create-targetGroup-and-loadBalancer.yaml s3://infrastructure-bucket-2024/step-04-create-targetGroup-and-loadBalancer.yaml
aws s3 cp $CLOUDFORMATION_FOLDER_PATH/step-05-launchTemplate.yaml s3://infrastructure-bucket-2024/step-05-launchTemplate.yaml
aws s3 cp $CLOUDFORMATION_FOLDER_PATH/step-06-create-autoScalingGroup.yaml s3://infrastructure-bucket-2024/step-06-create-autoScalingGroup.yaml



