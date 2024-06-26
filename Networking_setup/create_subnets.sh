#!/bin/bash

# Path to the export file
EXPORT_NETWORKING_FILE="networking_variables.sh"
EXPORT_RDS_FILE="../RDS_setup/RDS_variables.sh"
# Path to the folder containing JSON templates for subnet creation for CloudFormation deployment
JSON_FILE="../CloudFormation_json/step-02-create-subnets.json"
# Subnet variables
AVALIABILITY_ZONE1="me-south-1a"
AVALIABILITY_ZONE2="me-south-1b"
PUBLIC_SUBNET1_CIDR="10.0.0.0/24"
PUBLIC_SUBNET2_CIDR="10.0.1.0/24"
APP_SUBNET1_CIDR="10.0.2.0/24"
APP_SUBNET2_CIDR="10.0.3.0/24"
DATABASE_SUBNET1_CIDR="10.0.4.0/24"
DATABASE_SUBNET2_CIDR="10.0.5.0/24"


# Source the export file to get the VPC_ID variable
if [[ -f "$EXPORT_NETWORKING_FILE" ]]; then
    source "$EXPORT_NETWORKING_FILE"
else
    echo "Export file not found: $EXPORT_NETWORKING_FILE"
    exit 1
fi

# -- PUBLIC SUBNETS --
# Create public subnet 1
PUBLIC_SUBNET1_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $PUBLIC_SUBNET1_CIDR \
    --availability-zone $AVALIABILITY_ZONE1 \
    --query 'Subnet.SubnetId' \
    --output text)

aws ec2 create-tags \
    --resources $PUBLIC_SUBNET1_ID \
    --tags Key=Name,Value=Public-subnet-1

echo "export PUBLIC_SUBNET1_ID=\"$PUBLIC_SUBNET1_ID\"" >> "$EXPORT_NETWORKING_FILE"

# Create public subnet 2
PUBLIC_SUBNET2_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $PUBLIC_SUBNET2_CIDR \
    --availability-zone $AVALIABILITY_ZONE2 \
    --query 'Subnet.SubnetId' \
    --output text)

aws ec2 create-tags \
    --resources $PUBLIC_SUBNET2_ID \
    --tags Key=Name,Value=Public-subnet-2

echo "export PUBLIC_SUBNET2_ID=\"$PUBLIC_SUBNET2_ID\"" >> "$EXPORT_NETWORKING_FILE"

# -- PRIVATE SUBNETS/APP SUBNETS --
# Create APP subnet 1
APP_SUBNET1_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $APP_SUBNET1_CIDR \
    --availability-zone $AVALIABILITY_ZONE1 \
    --query 'Subnet.SubnetId' \
    --output text)

aws ec2 create-tags \
    --resources $APP_SUBNET1_ID \
    --tags Key=Name,Value=App-subnet-1

echo "export APP_SUBNET1_ID=\"$APP_SUBNET1_ID\"" >> "$EXPORT_NETWORKING_FILE"

# Create APP subnet 2
APP_SUBNET2_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $APP_SUBNET2_CIDR \
    --availability-zone $AVALIABILITY_ZONE2 \
    --query 'Subnet.SubnetId' \
    --output text)

aws ec2 create-tags \
    --resources $APP_SUBNET2_ID \
    --tags Key=Name,Value=App-subnet-2

echo "export APP_SUBNET2_ID=\"$APP_SUBNET2_ID\"" >> "$EXPORT_NETWORKING_FILE"

# -- PRIVATE SUBNETS/DATABASE SUBNETS --
# Create Database subnet 1
DATABASE_SUBNET1_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $DATABASE_SUBNET1_CIDR \
    --availability-zone $AVALIABILITY_ZONE1 \
    --query 'Subnet.SubnetId' \
    --output text)

aws ec2 create-tags \
    --resources $DATABASE_SUBNET1_ID \
    --tags Key=Name,Value=Database-subnet-1

echo "export DATABASE_SUBNET1_ID=\"$DATABASE_SUBNET1_ID\"" >> "$EXPORT_NETWORKING_FILE"
echo "export DATABASE_SUBNET1_ID=\"$DATABASE_SUBNET1_ID\"" >> "$EXPORT_RDS_FILE"

# Create Database subnet 2
DATABASE_SUBNET2_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $DATABASE_SUBNET2_CIDR \
    --availability-zone $AVALIABILITY_ZONE2 \
    --query 'Subnet.SubnetId' \
    --output text)

aws ec2 create-tags \
    --resources $DATABASE_SUBNET2_ID \
    --tags Key=Name,Value=Database-subnet-2

echo "export DATABASE_SUBNET2_ID=\"$DATABASE_SUBNET2_ID\"" >> "$EXPORT_NETWORKING_FILE"
echo "export DATABASE_SUBNET2_ID=\"$DATABASE_SUBNET2_ID\"" >> "$EXPORT_RDS_FILE"

# JSON templet to create a new subnets by using CloudFormation based on VPC i created before
# note: you should use [step-01-create-VPC.json] templete before using this templet
cat << EOF > $JSON_FILE
{
    "AWSTemplateFormatVersion": "2010-09-09",
    "Description": "AWS CloudFormation template to create a subnets and tag it.",
    "Resources": {
        "PublicSubnet1": {
            "Type": "AWS::EC2::Subnet",
            "Properties": {
                "VpcId": "$VPC_ID",
                "CidrBlock": "$PUBLIC_SUBNET1_CIDR",
                "AvailabilityZone": "$AVALIABILITY_ZONE",
                "Tags": [
                    {"Key": "Name", "Value": "Public-subnet-1"}
                ]
            }
        },
        "PublicSubnet2": {
            "Type": "AWS::EC2::Subnet",
            "Properties": {
                "VpcId": "$VPC_ID",
                "CidrBlock": "$PUBLIC_SUBNET2_CIDR",
                "AvailabilityZone": "$AVALIABILITY_ZONE",
                "Tags": [
                    {"Key": "Name", "Value": "Public-subnet-2"}
                ]
            }
        },
        "AppSubnet1": {
            "Type": "AWS::EC2::Subnet",
            "Properties": {
                "VpcId": "$VPC_ID",
                "CidrBlock": "$APP_SUBNET1_CIDR",
                "AvailabilityZone": "$AVALIABILITY_ZONE",
                "Tags": [
                    {"Key": "Name", "Value": "App-subnet-1"}
                ]
            }
        },
        "AppSubnet2": {
            "Type": "AWS::EC2::Subnet",
            "Properties": {
                "VpcId": "$VPC_ID",
                "CidrBlock": "$APP_SUBNET2_CIDR",
                "AvailabilityZone": "$AVALIABILITY_ZONE",
                "Tags": [
                    {"Key": "Name", "Value": "App-subnet-2"}
                ]
            }
        },
        "DatabaseSubnet1": {
            "Type": "AWS::EC2::Subnet",
            "Properties": {
                "VpcId": "$VPC_ID",
                "CidrBlock": "$DATABASE_SUBNET1_CIDR",
                "AvailabilityZone": "$AVALIABILITY_ZONE",
                "Tags": [
                    {"Key": "Name", "Value": "Database-subnet-1"}
                ]
            }
        },
        "DatabaseSubnet2": {
            "Type": "AWS::EC2::Subnet",
            "Properties": {
                "VpcId": "$VPC_ID",
                "CidrBlock": "$DATABASE_SUBNET2_CIDR",
                "AvailabilityZone": "$AVALIABILITY_ZONE",
                "Tags": [
                    {"Key": "Name", "Value": "Database-subnet-2"}
                ]
            }
        }
    }
}
EOF