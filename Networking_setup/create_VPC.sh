#!/bin/bash

# VPC variables
VPC_NAME="My-VPC-2024"
VPC_CIDR="10.0.0.0/16"
REGION="me-south-1"
DELAY=5
EXPORT_NETWORKING_FILE="networking_variables.sh"
# EXPORT_RDS_FILE="../RDS_setup/RDS_variables.sh"
JSON_FILE="../CloudFormation_json/step-01-create_VPC.json"

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

echo "export VPC_ID=\"$VPC_ID\"" > "$EXPORT_NETWORKING_FILE"
# echo "export VPC_ID=\"$VPC_ID\"" >> "$EXPORT_RDS_FILE"


# Delay to ensure the VPC is created before tagging
sleep $DELAY

# Tag VPC
aws ec2 create-tags \
    --resources "$VPC_ID" \
    --tags Key=Name,Value=$VPC_NAME \
    --region $REGION


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