#!/bin/bash

# Path to the export file
EXPORT_VARIABLES_FILE="../infrastructure_variables.sh"
# Path to the folder containing JSON templates for internet gateway creation for CloudFormation deployment
JSON_FILE="../CloudFormation_json/step-03-create-internetGateway.json"

# Source the export file to get the VPC_ID variable
if [[ -f "$EXPORT_VARIABLES_FILE" ]]; then
    source "$EXPORT_VARIABLES_FILE"
else
    echo "Export file not found: $EXPORT_VARIABLES_FILE"
    exit 1
fi

# Create internet gateway
IGW_ID=$(aws ec2 create-internet-gateway \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)

# Send the (internet gateway ID) to the (infrastructure_variables file) to use it with anotherr services configuration
echo "export IGW_ID=\"$IGW_ID\"" >> "$EXPORT_VARIABLES_FILE"

# Attach the internet gateway with VPC
aws ec2 attach-internet-gateway \
    --internet-gateway-id $IGW_ID \
    --vpc-id $VPC_ID

# Tagging the internet gateway for easier identification
aws ec2 create-tags \
    --resources $IGW_ID \
    --tags Key=Name,Value=IGW


# JSON templet to create a new internet gateway to use it for CloudFormation based on VPC i created before
# note: you should execute [step-01-create-VPC.json] template before using this template
cat << EOF > $JSON_FILE
{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Description": "CloudFormation template to create an Internet Gateway and attach it to a VPC.",
  "Parameters": {
    "VpcId": {
      "Type": "AWS::EC2::VPC::Id",
      "Description": "The ID of the VPC to attach the Internet Gateway to."
      "Default": "$VPC_ID"  
    }
  },
  "Resources": {
    "MyInternetGateway": {
      "Type": "AWS::EC2::InternetGateway",
      "Properties": {
        "Tags": [
          {
            "Key": "Name",
            "Value": "IGW"
          }
        ]
      }
    },
    "AttachGateway": {
      "Type": "AWS::EC2::VPCGatewayAttachment",
      "Properties": {
        "VpcId": {
          "Ref": "VpcId"
        },
        "InternetGatewayId": {
          "Ref": "MyInternetGateway"
        }
      }
    }
  },
  "Outputs": {
    "InternetGatewayId": {
      "Description": "The ID of the created Internet Gateway.",
      "Value": {
        "Ref": "MyInternetGateway"
      }
    }
  }
}
EOF