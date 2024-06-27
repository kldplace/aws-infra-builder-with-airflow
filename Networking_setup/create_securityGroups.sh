#!/bin/bash

# Path to the export file
EXPORT_VARIABLES_FILE="../infrastructure_variables.sh"
# Path to the folder containing JSON templates for internet gateway creation for CloudFormation deployment
JSON_FILE="../CloudFormation_json/step-06-create_securityGroups.json"

# --SECURITY GROUPS VARIABLES --
# APP Instance
SG_APP_NAME="AppInstanceSecurityGroup"
SG_APP_DESCRIPTION="Security Group allowing HTTP traffic for lab instances"
# RDS Database
SG_RDS_NAME="RDSSecurityGroup"
SG_RDS_DESCRIPTION="Security Group allowing RDS instances to have internet traffic"
# EFS Mount Target
SG_EFS_NAME="EFSMountTargetSecurityGroup"
SG_EFS_DESCRIPTION="Security Group allowing traffic between EFS Mount Targets and Amazon EC2 instances"


# Source the export file to get the public subnets ID variables
if [[ -f "$EXPORT_VARIABLES_FILE" ]]; then
    source "$EXPORT_VARIABLES_FILE"
else
    echo "Export file not found: $EXPORT_VARIABLES_FILE"
    exit 1
fi


# -- APP INSTANCE SECURITY GROUP --
# Create security group for APP Instance
APP_INSTANCE_SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name $SG_APP_NAME \
    --description "$SG_APP_DESCRIPTION" \
    --vpc-id $VPC_ID \
    --query 'GroupId' \
    --output text)
# Authorize inbound traffic for HTTP on port 80 for all IP addresses (0.0.0.0/0)
aws ec2 authorize-security-group-ingress \
    --group-id $APP_INSTANCE_SECURITY_GROUP_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0
# Tagging the security group for easier identification
aws ec2 create-tags \
    --resources $APP_INSTANCE_SECURITY_GROUP_ID \
    --tags Key=Name,Value=$SG_APP_NAME

# Send the (APP Instance security group ID) to the (infrastructure_variables file) to use it with anotherr services configuration
echo "export APPINSTANCE_SECURITY_GROUP_ID=\"$APPINSTANCE_SECURITY_GROUP_ID\"" >> "$EXPORT_VARIABLES_FILE"

# -- RDS SECURITY GROUP --
# Create security group for RDS Database
RDS_SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name $SG_RDS_NAME \
    --description "$SG_RDS_DESCRIPTION" \
    --vpc-id $VPC_ID \
    --query 'GroupId' \
    --output text)
# Tagging the security group for easier identification
aws ec2 create-tags \
    --resources $RDS_SECURITY_GROUP_ID \
    --tags Key=Name,Value=$SG_RDS_NAME

# Send the (RDS security group ID) to the (infrastructure_variables file) to use it with anotherr services configuration
echo "export RDS_SECURITY_GROUP_ID=\"$RDS_SECURITY_GROUP_ID\"" >> "$EXPORT_VARIABLES_FILE"

# -- EFS MOUNT TARGET SECURITY GROUP --
# Create security group for EFS Mount Target
EFS_SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name $SG_EFS_NAME \
    --description "$SG_EFS_DESCRIPTION" \
    --vpc-id $VPC_ID \
    --query 'GroupId' \
    --output text)
# Authorize inbound traffic for HTTP on port 80 for all IP addresses (0.0.0.0/0)
aws ec2 authorize-security-group-ingress \
    --group-id $EFS_SECURITY_GROUP_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0
# Tagging the security group for easier identification
aws ec2 create-tags \
    --resources $EFS_SECURITY_GROUP_ID \
    --tags Key=Name,Value=$SG_EFS_NAME

# Send the (EFS Mount Target security group ID) to the (infrastructure_variables file) to use it with anotherr services configuration
echo "export EFSMountTarget_SECURITY_GROUP_ID=\"$EFSMountTarget_SECURITY_GROUP_ID\"" >> "$EXPORT_VARIABLES_FILE"

# JSON templet to create security group to use it for CloudFormation based on VPC i created before
# note: you should execute [step-01-create-VPC.json] template before using this template
cat << EOF > $JSON_FILE
{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Description": "CloudFormation template for creating security groups for an app instance, RDS, and EFS mount targets",
  "Parameters": {
    "VPCID": {
      "Type": "AWS::EC2::VPC::Id",
      "Default": "$VPC_ID",
      "Description": "The ID of the VPC"
    }
  },
  "Resources": {
    "AppInstanceSecurityGroup": {
      "Type": "AWS::EC2::SecurityGroup",
      "Properties": {
        "GroupName": "AppInstanceSecurityGroup",
        "GroupDescription": "Security Group allowing HTTP traffic for lab instances",
        "VpcId": {
          "Ref": "VPCID"
        },
        "SecurityGroupIngress": [
          {
            "IpProtocol": "tcp",
            "FromPort": 80,
            "ToPort": 80,
            "CidrIp": "0.0.0.0/0"
          }
        ],
        "Tags": [
          {
            "Key": "Name",
            "Value": "AppInstanceSecurityGroup"
          }
        ]
      }
    },
    "RDSSecurityGroup": {
      "Type": "AWS::EC2::SecurityGroup",
      "Properties": {
        "GroupName": "RDSSecurityGroup",
        "GroupDescription": "Security Group allowing RDS instances to have internet traffic",
        "VpcId": {
          "Ref": "VPCID"
        },
        "Tags": [
          {
            "Key": "Name",
            "Value": "RDSSecurityGroup"
          }
        ]
      }
    },
    "EFSMountTargetSecurityGroup": {
      "Type": "AWS::EC2::SecurityGroup",
      "Properties": {
        "GroupName": "EFSMountTargetSecurityGroup",
        "GroupDescription": "Security Group allowing traffic between EFS Mount Targets and Amazon EC2 instances",
        "VpcId": {
          "Ref": "VPCID"
        },
        "SecurityGroupIngress": [
          {
            "IpProtocol": "tcp",
            "FromPort": 80,
            "ToPort": 80,
            "CidrIp": "0.0.0.0/0"
          }
        ],
        "Tags": [
          {
            "Key": "Name",
            "Value": "EFSMountTargetSecurityGroup"
          }
        ]
      }
    }
  }
}
EOF