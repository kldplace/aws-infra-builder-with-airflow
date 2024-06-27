#!/bin/bash

# Path to the export file
EXPORT_VARIABLES_FILE="../infrastructure_variables.sh"
# Path to the folder containing JSON templates for route tables creation for CloudFormation deployment
JSON_FILE="../CloudFormation_json/step-05-create-routeTables.json"

# Source the export file to get the VPC_ID variable
if [[ -f "$EXPORT_VARIABLES_FILE" ]]; then
    source "$EXPORT_VARIABLES_FILE"
else
    echo "Export file not found: $EXPORT_VARIABLES_FILE"
    exit 1
fi

# -- PUBLIC ROUTE TABLE --
PUBLIC_ROUTE_TABLE_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --query 'RouteTable.RouteTableId' \
    --output text)
# Create public route table
aws ec2 create-route \
    --route-table-id $PUBLIC_ROUTE_TABLE_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $IGW_ID
# Associate public route table with (Public subnet 1 [me-south-1a])
aws ec2 associate-route-table \
    --route-table-id $PUBLIC_ROUTE_TABLE_ID \
    --subnet-id $PUBLIC_SUBNET1_ID
# Associate public route table with (Public subnet 2 [me-south-1b])
aws ec2 associate-route-table \
    --route-table-id $PUBLIC_ROUTE_TABLE_ID \
    --subnet-id $PUBLIC_SUBNET2_ID
# Tagging the public route table for easier identification
aws ec2 create-tags \
    --resources $PUBLIC_ROUTE_TABLE_ID \
    --tags Key=Name,Value=Public-routeTable

# -- PRIVATE ROUTE TABLE / AZ1 --
PRIVATE_ROUTE_TABLE_AZ1_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --query 'RouteTable.RouteTableId' \
    --output text)
# Create private route table in the first availability zone [me-south-1a]
aws ec2 create-route \
    --route-table-id $PRIVATE_ROUTE_TABLE_AZ1_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $NAT_GATEWAY_AZ1_ID
# Associate private route table with (APP subnet 1 [me-south-1a])
aws ec2 associate-route-table \
    --route-table-id $PRIVATE_ROUTE_TABLE_AZ1_ID \
    --subnet-id $APP_SUBNET1_ID
# Associate private route table with (Database subnet 1 [me-south-1a])
aws ec2 associate-route-table \
    --route-table-id $PRIVATE_ROUTE_TABLE_AZ1_ID \
    --subnet-id $DATABASE_SUBNET1_ID
# Tagging the private route table in the AZ1 for easier identification
aws ec2 create-tags \
    --resources $PRIVATE_ROUTE_TABLE_AZ1_ID \
    --tags Key=Name,Value=Private-routeTable-AZ1

# -- PRIVATE ROUTE TABLE / AZ2 --
PRIVATE_ROUTE_TABLE_AZ2_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --query 'RouteTable.RouteTableId' \
    --output text)
# Create private route table in the first availability zone [me-south-1b]
aws ec2 create-route \
    --route-table-id $PRIVATE_ROUTE_TABLE_AZ2_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $NAT_GATEWAY_AZ2_ID
# Associate private route table with (APP subnet 2 [me-south-1b])
aws ec2 associate-route-table \
    --route-table-id $PRIVATE_ROUTE_TABLE_AZ2_ID \
    --subnet-id $APP_SUBNET2_ID
# Associate private route table with (Database subnet 2 [me-south-1b])
aws ec2 associate-route-table \
    --route-table-id $PRIVATE_ROUTE_TABLE_AZ2_ID \
    --subnet-id $DATABASE_SUBNET2_ID
# Tagging the private route table in the AZ2 for easier identification
aws ec2 create-tags \
    --resources $PRIVATE_ROUTE_TABLE_AZ2_ID \
    --tags Key=Name,Value=Private-routeTable-AZ2

# JSON templet to create a route tables to use it for CloudFormation based on VPC, subnets, internet gateway and NAT gateways IDs i created before
# note: you should execute these templates before using this template
# [1][step-01-create-VPC.json] 
# [2][step-02-create-subnets.json] 
# [3][step-03-create-internetGateway.json] 
# [4][step-04-create-NATgateways.json] 

cat << EOF > $JSON_FILE
{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Resources": {
    "PublicRouteTable": {
      "Type": "AWS::EC2::RouteTable",
      "Properties": {
        "VpcId": {"Ref": "VPCID"},
        "Tags": [
          {
            "Key": "Name",
            "Value": "Public-routeTable"
          }
        ]
      }
    },
    "PublicRoute": {
      "Type": "AWS::EC2::Route",
      "Properties": {
        "RouteTableId": {"Ref": "PublicRouteTable"},
        "DestinationCidrBlock": "0.0.0.0/0",
        "GatewayId": {"Ref": "IGWID"}
      }
    },
    "PublicSubnet1RouteTableAssociation": {
      "Type": "AWS::EC2::SubnetRouteTableAssociation",
      "Properties": {
        "RouteTableId": {"Ref": "PublicRouteTable"},
        "SubnetId": {"Ref": "PublicSubnet1ID"}
      }
    },
    "PublicSubnet2RouteTableAssociation": {
      "Type": "AWS::EC2::SubnetRouteTableAssociation",
      "Properties": {
        "RouteTableId": {"Ref": "PublicRouteTable"},
        "SubnetId": {"Ref": "PublicSubnet2ID"}
      }
    },
    "PrivateRouteTableAZ1": {
      "Type": "AWS::EC2::RouteTable",
      "Properties": {
        "VpcId": {"Ref": "VPCID"},
        "Tags": [
          {
            "Key": "Name",
            "Value": "Private-routeTable-AZ1"
          }
        ]
      }
    },
    "PrivateRouteAZ1": {
      "Type": "AWS::EC2::Route",
      "Properties": {
        "RouteTableId": {"Ref": "PrivateRouteTableAZ1"},
        "DestinationCidrBlock": "0.0.0.0/0",
        "NatGatewayId": {"Ref": "NATGatewayAZ1ID"}
      }
    },
    "AppSubnet1RouteTableAssociation": {
      "Type": "AWS::EC2::SubnetRouteTableAssociation",
      "Properties": {
        "RouteTableId": {"Ref": "PrivateRouteTableAZ1"},
        "SubnetId": {"Ref": "AppSubnet1ID"}
      }
    },
    "DatabaseSubnet1RouteTableAssociation": {
      "Type": "AWS::EC2::SubnetRouteTableAssociation",
      "Properties": {
        "RouteTableId": {"Ref": "PrivateRouteTableAZ1"},
        "SubnetId": {"Ref": "DatabaseSubnet1ID"}
      }
    },
    "PrivateRouteTableAZ2": {
      "Type": "AWS::EC2::RouteTable",
      "Properties": {
        "VpcId": {"Ref": "VPCID"},
        "Tags": [
          {
            "Key": "Name",
            "Value": "Private-routeTable-AZ2"
          }
        ]
      }
    },
    "PrivateRouteAZ2": {
      "Type": "AWS::EC2::Route",
      "Properties": {
        "RouteTableId": {"Ref": "PrivateRouteTableAZ2"},
        "DestinationCidrBlock": "0.0.0.0/0",
        "NatGatewayId": {"Ref": "NATGatewayAZ2ID"}
      }
    },
    "AppSubnet2RouteTableAssociation": {
      "Type": "AWS::EC2::SubnetRouteTableAssociation",
      "Properties": {
        "RouteTableId": {"Ref": "PrivateRouteTableAZ2"},
        "SubnetId": {"Ref": "AppSubnet2ID"}
      }
    },
    "DatabaseSubnet2RouteTableAssociation": {
      "Type": "AWS::EC2::SubnetRouteTableAssociation",
      "Properties": {
        "RouteTableId": {"Ref": "PrivateRouteTableAZ2"},
        "SubnetId": {"Ref": "DatabaseSubnet2ID"}
      }
    }
  },
  "Parameters": {
    "VPCID": {
      "Type": "String",
      "Default": "$VPC_ID",
      "Description": "The ID of the VPC"
    },
    "IGWID": {
      "Type": "String",
      "Default": "$IGW_ID",
      "Description": "The ID of the Internet Gateway"
    },
    "NATGatewayAZ1ID": {
      "Type": "String",
      "Default": "$NAT_GATEWAY_AZ1_ID",
      "Description": "The ID of the NAT Gateway in AZ1"
    },
    "NATGatewayAZ2ID": {
      "Type": "String",
      "Default": "$NAT_GATEWAY_AZ2_ID",
      "Description": "The ID of the NAT Gateway in AZ2"
    },
    "PublicSubnet1ID": {
      "Type": "String",
      "Default": "$PUBLIC_SUBNET1_ID",
      "Description": "The ID of the first public subnet"
    },
    "PublicSubnet2ID": {
      "Type": "String",
      "Default": "$PUBLIC_SUBNET2_ID",
      "Description": "The ID of the second public subnet"
    },
    "AppSubnet1ID": {
      "Type": "String",
      "Default": "$APP_SUBNET1_ID",
      "Description": "The ID of the first application subnet"
    },
    "DatabaseSubnet1ID": {
      "Type": "String",
      "Default": "$DATABASE_SUBNET1_ID",
      "Description": "The ID of the first database subnet"
    },
    "AppSubnet2ID": {
      "Type": "String",
      "Default": "$APP_SUBNET2_ID",
      "Description": "The ID of the second application subnet"
    },
    "DatabaseSubnet2ID": {
      "Type": "String",
      "Default": "$DATABASE_SUBNET2_ID",
      "Description": "The ID of the second database subnet"
    }
  }
}
EOF