#!/bin/bash

# Path to the export file
EXPORT_VARIABLES_FILE="../infrastructure_variables.sh"
# Path to the folder containing JSON templates for EFS Mount Target creation for CloudFormation deployment
JSON_FILE="../CloudFormation_json/step-08-create-EFSMountTarget.json"

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

# JSON templet to create a route tables to use it for CloudFormation based on VPC, subnets, internet gateway and NAT gateways IDs i created before
# note: you should execute these templates before using this template
# [1][step-01-create-VPC.json] 
# [2][step-02-create-subnets.json] 
# [3][step-03-create-internetGateway.json] 
# [4][step-04-create-NATgateways.json]
# [5][step-05-create-routeTables.json]
# [6][step-06-create_securityGroups.json]
cat << EOF > $JSON_FILE
{
  "Resources": {
    "MyEFSFileSystem": {
      "Type": "AWS::EFS::FileSystem",
      "Properties": {
        "PerformanceMode": "generalPurpose",
        "Encrypted": false,
        "FileSystemTags": [
          {
            "Key": "Name",
            "Value": "myWPEFS"
          }
        ]
      }
    },
    "EFSMountTarget1": {
      "Type": "AWS::EFS::MountTarget",
      "Properties": {
        "FileSystemId": { "Ref": "MyEFSFileSystem" },
        "SubnetId": "$APP_SUBNET1_ID",
        "SecurityGroups": [ "$EFSMountTarget_SECURITY_GROUP_ID" ]
      }
    },
    "EFSMountTarget2": {
      "Type": "AWS::EFS::MountTarget",
      "Properties": {
        "FileSystemId": { "Ref": "MyEFSFileSystem" },
        "SubnetId": "$APP_SUBNET2_ID",
        "SecurityGroups": [ "$EFSMountTarget_SECURITY_GROUP_ID" ]
      }
    }
  }
}
EOF