#!/bin/bash

# Path to the export file
EXPORT_VARIABLES_FILE="/home/kld/Github_projects/aws-infra-builder-with-airflow/infrastructure_variables.sh"
# Path to the folder containing (yaml) templates for EFS Mount Target creation for CloudFormation deployment
YAML_FILE="/home/kld/Github_projects/aws-infra-builder-with-airflow/CloudFormation_yaml/step-03-create-EFSMountTarget.yaml"

# Source the export file to get the VPC_ID variable
if [[ -f "$EXPORT_VARIABLES_FILE" ]]; then
    source "$EXPORT_VARIABLES_FILE"
else
    echo "Export file not found: $EXPORT_VARIABLES_FILE"
    exit 1
fi

# Create Elastic file system
FILE_SYSTEM_ID=$(aws efs create-file-system \
  --creation-token myWPEFS \
  --performance-mode generalPurpose \
  --no-encrypted \
  --region me-south-1 \
  --output text \
  --query 'FileSystemId' \
  --tags Key=Name,Value=myWPEFS)

# Delay execution to ensure the EFS is created before setting the backup policy.
sleep 10

# Disabling the automatic backups
aws efs put-backup-policy \
  --file-system-id "$FILE_SYSTEM_ID" \
  --backup-policy Status=DISABLED \
  --region me-south-1

# Create Mount target for AZ1/me-south-1a
aws efs create-mount-target \
  --file-system-id "$FILE_SYSTEM_ID" \
  --subnet-id $APP_SUBNET1_ID \
  --security-groups $EFSMountTarget_SECURITY_GROUP_ID \
  --region me-south-1

# Create Mount target for AZ2/me-south-1b
aws efs create-mount-target \
  --file-system-id "$FILE_SYSTEM_ID" \
  --subnet-id $APP_SUBNET2_ID \
  --security-groups $EFSMountTarget_SECURITY_GROUP_ID \
  --region me-south-1

# [step-03-create-EFSMountTarget.yaml]
# YAML template to create EFS Mount Target to use it with CloudFormation service
# note: you should execute [step-01-create-networkingStructure.yaml] template before using this template
cat << EOF > $YAML_FILE
AWSTemplateFormatVersion: "2010-09-09"
Description: CloudFormation template to create an EFS FileSystem with mount targets in two subnets at two availability zones

Parameters:
  AppSubnet1Id:
    Type: String
    Default: $APP_SUBNET1_ID
    Description: Subnet ID for the first application subnet in AZ1
  AppSubnet2Id:
    Type: String
    Default: $APP_SUBNET2_ID
    Description: Subnet ID for the second application subnet in AZ2
  EFSMountTargetSecurityGroupId:
    Type: String
    Default: $EFSMountTarget_SECURITY_GROUP_ID
    Description: Security group ID for the EFS mount targets

Resources:
  MyEFSFileSystem:
    Type: "AWS::EFS::FileSystem"
    Properties:
      PerformanceMode: generalPurpose
      Encrypted: false
      FileSystemTags:
        - Key: Name
          Value: myWPEFS

  EFSMountTarget1:
    Type: "AWS::EFS::MountTarget"
    Properties:
      FileSystemId: !Ref MyEFSFileSystem
      SubnetId: !Ref AppSubnet1Id
      SecurityGroups: 
        - !Ref EFSMountTargetSecurityGroupId

  EFSMountTarget2:
    Type: "AWS::EFS::MountTarget"
    Properties:
      FileSystemId: !Ref MyEFSFileSystem
      SubnetId: !Ref AppSubnet2Id
      SecurityGroups: 
        - !Ref EFSMountTargetSecurityGroupId
EOF