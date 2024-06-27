#!/bin/bash

# Creaete [infrastructure-bucket-2024] bucket
aws s3api create-bucket --bucket infrastructure-bucket-2024 --region me-south-1 --create-bucket-configuration LocationConstraint=me-south-1

# -- PREPARING A PLACE FOR (NETWORKING) JSON FILES --
# create [NetworkingSetup] folder
aws s3api put-object --bucket infrastructure-bucket-2024 --key NetworkingSetup/
# create [json and ymal] folders
aws s3api put-object --bucket infrastructure-bucket-2024 --key NetworkingSetup/Json/
aws s3api put-object --bucket infrastructure-bucket-2024 --key NetworkingSetup/Yaml/
# Upload json file that created a network infrastructure
aws s3 cp ../CloudFormation_json/step-01-create-VPC.json s3://infrastructure-bucket-2024/NetworkingSetup/Json/step-01-create-VPC.json
aws s3 cp ../CloudFormation_json/step-02-create-subnets.json s3://infrastructure-bucket-2024/NetworkingSetup/Json/step-02-create-subnets.json
aws s3 cp ../CloudFormation_json/step-03-create-internetGateway.json s3://infrastructure-bucket-2024/NetworkingSetup/Json/step-03-create-internetGateway.json
aws s3 cp ../CloudFormation_json/step-04-create-NATgateways.json s3://infrastructure-bucket-2024/NetworkingSetup/Json/step-04-create-NATgateways.json
aws s3 cp ../CloudFormation_json/step-05-create-routeTables.json s3://infrastructure-bucket-2024/NetworkingSetup/Json/step-05-create-routeTables.json
aws s3 cp ../CloudFormation_json/step-06-create-securityGroups.json s3://infrastructure-bucket-2024/NetworkingSetup/Json/step-06-create-securityGroups.json



