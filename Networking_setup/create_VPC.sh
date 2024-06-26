#!/bin/bash

# Path to the export file
EXPORT_NETWORKING_FILE="networking_variables.sh"
# EXPORT_RDS_FILE="../RDS_setup/RDS_variables.sh"
# Path to the folder containing JSON templates for VPC creation for CloudFormation deployment
JSON_FILE="../CloudFormation_json/step-01-create-VPC.json"
# VPC variables
VPC_NAME="My-VPC-2024"
VPC_CIDR="10.0.0.0/16"
REGION="me-south-1"
DELAY=5

# Create VPC
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block $VPC_CIDR \
    --region $REGION \
    --query 'Vpc.VpcId' \
    --output text)

# Check if VPC_ID is valid
if [ -z "$VPC_ID" ]; then
    echo "Failed to create VPC"
    exit 1
fi

# Send the (VPC ID) to the (variables_files) to use it with anotherr services configuration
echo "export VPC_ID=\"$VPC_ID\"" > "$EXPORT_NETWORKING_FILE"
# echo "export VPC_ID=\"$VPC_ID\"" >> "$EXPORT_RDS_FILE"

# Delay to ensure the VPC is created before tagging
sleep $DELAY

# Tagging the VPC for easier identification
aws ec2 create-tags \
    --resources "$VPC_ID" \
    --tags Key=Name,Value=$VPC_NAME \
    --region $REGION

# JSON templet to create a new VPC by using CloudFormation
cat << EOF > $JSON_FILE
{
    "AWSTemplateFormatVersion": "2010-09-09",
    "Description": "AWS CloudFormation template to create a VPC and tag it.",
    "Resources": {
        "MyVPC": {
            "Type": "AWS::EC2::VPC",
            "Properties": {
                "CidrBlock": "$VPC_CIDR",
                "Tags": [
                    {
                        "Key": "Name",
                        "Value": "$VPC_NAME"
                    }
                ]
            }
        }
    },
    "Outputs": {
        "VPCId": {
            "Description": "VPC ID",
            "Value": { "Ref": "MyVPC" }
        }
    }
}
EOF