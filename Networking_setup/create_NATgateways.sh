#!/bin/bash

# Path to the export file
EXPORT_VARIABLES_FILE="../infrastructure_variables.sh"
# Path to the folder containing JSON templates for NAT gateway creation for CloudFormation deployment
JSON_FILE="../CloudFormation_json/step-04-create-NATgateways.json"

# Source the export file to get the VPC_ID and both Public subnets variable
if [[ -f "$EXPORT_VARIABLES_FILE" ]]; then
    source "$EXPORT_VARIABLES_FILE"
else
    echo "Export file not found: $EXPORT_VARIABLES_FILE"
    exit 1
fi

# --CREATE NAT GATEWAY FOR PUBLIC SUBNET 1 -- 
# Create elastic IP for NAT gateway in the first availability zone 
NAT01_ALLOCATION_ID=$(aws ec2 allocate-address \
    --domain $VPC_ID \
    --query 'AllocationId' \
    --output text)
# Create NAT gateway in the first availability zone for (Public subnet 1)
NAT_GATEWAY_AZ1_ID=$(aws ec2 create-nat-gateway \
    --subnet-id $PUBLIC_SUBNET1_ID \
    --allocation-id $NAT01_ALLOCATION_ID \
    --query 'NatGateway.NatGatewayId'\
    --output text)
# Tagging the NAT gateway for easier identification
aws ec2 create-tags \
    --resources $NAT_GATEWAY_AZ1_ID \
    --tags Key=Name,Value=NAT_publicSubnet-01

# Send the (NAT gateway ID) to the (infrastructure_variables file) to use it with anotherr services configuration
echo "export NAT_GATEWAY_AZ1_ID=\"$NAT_GATEWAY_AZ1_ID\"" >> "$EXPORT_VARIABLES_FILE"

# --CREATE NAT GATEWAY FOR PUBLIC SUBNET 2 -- 
# Create elastic IP for NAT gateway in the second availability zone 
NAT02_ALLOCATION_ID=$(aws ec2 allocate-address \
    --domain $VPC_ID \
    --query 'AllocationId' \
    --output text)
# Create NAT gateway in the first availability zone for (Public subnet 2)
NAT_GATEWAY_AZ2_ID=$(aws ec2 create-nat-gateway \
    --subnet-id $PUBLIC_SUBNET2_ID \
    --allocation-id $NAT02_ALLOCATION_ID \
    --query 'NatGateway.NatGatewayId'\
    --output text)
# Tagging the NAT gateway for easier identification
aws ec2 create-tags \
    --resources $NAT_GATEWAY_AZ2_ID \
    --tags Key=Name,Value=NAT_publicSubnet-02

# Send the (NAT gateway ID) to the (infrastructure_variables file) to use it with anotherr services configuration
echo "export NAT_GATEWAY_AZ2_ID=\"$NAT_GATEWAY_AZ2_ID\"" >> "$EXPORT_VARIABLES_FILE"

# JSON templet to create a new NAT gateway to use it for CloudFormation based on VPC and both Public subnets i created before
# note: you should execute these templates before using this template
# [1][step-01-create-VPC.json] 
# [2][step-02-create-subnets.json] 
cat << EOF >$JSON_FILE 
{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Parameters": {
    "VpcId": {
      "Type": "String",
      "Description": "The ID of the VPC",
      "Default": "$VPC_ID"  
    },
    "PublicSubnet1Id": {
      "Type": "String",
      "Description": "The ID of the first public subnet",
      "Default": "$PUBLIC_SUBNET1_ID"  
    },
    "PublicSubnet2Id": {
      "Type": "String",
      "Description": "The ID of the second public subnet",
      "Default": "$PUBLIC_SUBNET2_ID"  
    }
  },
  "Resources": {
    "NatGatewayEIP1": {
      "Type": "AWS::EC2::EIP",
      "Properties": {
        "Domain": "vpc"
      }
    },
    "NatGatewayEIP2": {
      "Type": "AWS::EC2::EIP",
      "Properties": {
        "Domain": "vpc"
      }
    },
    "NatGateway1": {
      "Type": "AWS::EC2::NatGateway",
      "Properties": {
        "SubnetId": {
          "Ref": "PublicSubnet1Id"
        },
        "AllocationId": {
          "Fn::GetAtt": ["NatGatewayEIP1", "AllocationId"]
        },
        "Tags": [
          {
            "Key": "Name",
            "Value": "NAT_publicSubnet-01"
          }
        ]
      }
    },
    "NatGateway2": {
      "Type": "AWS::EC2::NatGateway",
      "Properties": {
        "SubnetId": {
          "Ref": "PublicSubnet2Id"
        },
        "AllocationId": {
          "Fn::GetAtt": ["NatGatewayEIP2", "AllocationId"]
        },
        "Tags": [
          {
            "Key": "Name",
            "Value": "NAT_publicSubnet-02"
          }
        ]
      }
    }
  },
  "Outputs": {
    "NatGateway1Id": {
      "Description": "The ID of the first NAT Gateway",
      "Value": {
        "Ref": "NatGateway1"
      }
    },
    "NatGateway2Id": {
      "Description": "The ID of the second NAT Gateway",
      "Value": {
        "Ref": "NatGateway2"
      }
    },
    "VpcId": {
      "Description": "The ID of the VPC",
      "Value": {
        "Ref": "VpcId"
      }
    }
  }
}
EOF