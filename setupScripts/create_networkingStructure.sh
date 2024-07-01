#!/bin/bash

# Path to the export file
EXPORT_VARIABLES_FILE="/home/kld/Github_projects/aws-infra-builder-with-airflow/infrastructure_variables.sh"
# Path to the folder containing (yaml) templates for networking creation for CloudFormation deployment
YAML_FILE="/home/kld/Github_projects/aws-infra-builder-with-airflow/CloudFormation_yaml/step-01-create-networkingStructure.yaml"
# VPC variables
VPC_NAME="My-VPC-2024"
VPC_CIDR="10.0.0.0/16"
REGION="me-south-1"
# Subnet variables
AVALIABILITY_ZONE1="me-south-1a"
AVALIABILITY_ZONE2="me-south-1b"
PUBLIC_SUBNET1_CIDR="10.0.0.0/24"
PUBLIC_SUBNET2_CIDR="10.0.1.0/24"
APP_SUBNET1_CIDR="10.0.2.0/24"
APP_SUBNET2_CIDR="10.0.3.0/24"
DATABASE_SUBNET1_CIDR="10.0.4.0/24"
DATABASE_SUBNET2_CIDR="10.0.5.0/24"

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

# Send the (VPC ID) to the (infrastructure_variables file) to use it with anotherr services configuration
echo "export VPC_ID=\"$VPC_ID\"" > "$EXPORT_VARIABLES_FILE"

# Delay to ensure the VPC is created before tagging
sleep 5

# Enable DNS support and DNS hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support "{\"Value\":true}"
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames "{\"Value\":true}"

# Tagging the VPC for easier identification
aws ec2 create-tags \
    --resources "$VPC_ID" \
    --tags Key=Name,Value=$VPC_NAME \
    --region $REGION

# To ensure VPC is available before creating subnets
sleep 5

# --------- CREATE SUBNETS -----------------------------
# -- PUBLIC SUBNETS --
# Create public subnet 1
PUBLIC_SUBNET1_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $PUBLIC_SUBNET1_CIDR \
    --availability-zone $AVALIABILITY_ZONE1 \
    --query 'Subnet.SubnetId' \
    --output text)

# Enable public IP on launch
aws ec2 modify-subnet-attribute --subnet-id $PUBLIC_SUBNET1_ID --map-public-ip-on-launch

# Tagging the public subnet 1 for easier identification
aws ec2 create-tags \
    --resources $PUBLIC_SUBNET1_ID \
    --tags Key=Name,Value=Public-subnet-1

# Send the (Public subnet 1 ID) to the (infrastructure_variables file) to use it with anotherr services configuration
echo "export PUBLIC_SUBNET1_ID=\"$PUBLIC_SUBNET1_ID\"" >> "$EXPORT_VARIABLES_FILE"

# Create public subnet 2
PUBLIC_SUBNET2_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $PUBLIC_SUBNET2_CIDR \
    --availability-zone $AVALIABILITY_ZONE2 \
    --query 'Subnet.SubnetId' \
    --output text)

# Enable public IP on launch
aws ec2 modify-subnet-attribute --subnet-id $PUBLIC_SUBNET2_ID --map-public-ip-on-launch

# Tagging the public subnet 2 for easier identification
aws ec2 create-tags \
    --resources $PUBLIC_SUBNET2_ID \
    --tags Key=Name,Value=Public-subnet-2

# Send the (Public subnet 2 ID) to the (infrastructure_variables file) to use it with anotherr services configuration
echo "export PUBLIC_SUBNET2_ID=\"$PUBLIC_SUBNET2_ID\"" >> "$EXPORT_VARIABLES_FILE"

# -- PRIVATE SUBNETS/APP SUBNETS --
# Create APP subnet 1
APP_SUBNET1_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $APP_SUBNET1_CIDR \
    --availability-zone $AVALIABILITY_ZONE1 \
    --query 'Subnet.SubnetId' \
    --output text)

# Tagging the APP subnet 1 for easier identification
aws ec2 create-tags \
    --resources $APP_SUBNET1_ID \
    --tags Key=Name,Value=App-subnet-1

# Send the (APP subnet 1 ID) to the (infrastructure_variables file) to use it with anotherr services configuration
echo "export APP_SUBNET1_ID=\"$APP_SUBNET1_ID\"" >> "$EXPORT_VARIABLES_FILE"

# Create APP subnet 2
APP_SUBNET2_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $APP_SUBNET2_CIDR \
    --availability-zone $AVALIABILITY_ZONE2 \
    --query 'Subnet.SubnetId' \
    --output text)

# Tagging the APP subnet 2 for easier identification
aws ec2 create-tags \
    --resources $APP_SUBNET2_ID \
    --tags Key=Name,Value=App-subnet-2

# Send the (App subnet 2 ID) to the (infrastructure_variables file) to use it with anotherr services configuration
echo "export APP_SUBNET2_ID=\"$APP_SUBNET2_ID\"" >> "$EXPORT_VARIABLES_FILE"

# -- PRIVATE SUBNETS/DATABASE SUBNETS --
# Create Database subnet 1
DATABASE_SUBNET1_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $DATABASE_SUBNET1_CIDR \
    --availability-zone $AVALIABILITY_ZONE1 \
    --query 'Subnet.SubnetId' \
    --output text)

# Tagging the Database subnet 1 for easier identification
aws ec2 create-tags \
    --resources $DATABASE_SUBNET1_ID \
    --tags Key=Name,Value=Database-subnet-1

# Send the (Database subnet 1 ID) to the (infrastructure_variables file) to use it with anotherr services configuration
echo "export DATABASE_SUBNET1_ID=\"$DATABASE_SUBNET1_ID\"" >> "$EXPORT_VARIABLES_FILE"

# Create Database subnet 2
DATABASE_SUBNET2_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $DATABASE_SUBNET2_CIDR \
    --availability-zone $AVALIABILITY_ZONE2 \
    --query 'Subnet.SubnetId' \
    --output text)

# Tagging the Database subnet 2 for easier identification
aws ec2 create-tags \
    --resources $DATABASE_SUBNET2_ID \
    --tags Key=Name,Value=Database-subnet-2

# Send the (Database subnet 2 ID) to the (infrastructure_variables file) to use it with anotherr services configuration
echo "export DATABASE_SUBNET2_ID=\"$DATABASE_SUBNET2_ID\"" >> "$EXPORT_VARIABLES_FILE"


# --------- CREATE INTERNET GATEWAY --------------------
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

# To ensure internet gateway is available before creating NAT gateways
sleep 10

# ----------------- CREATE NATGATEWAY ------------------
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

# To ensure NAT gateways are available before creating route tables
sleep 30

# -------------- CREATE ROUTE TABLES ------------------
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


# ------------- CREATE SECURITY GROUPS -----------------
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
echo "export APPINSTANCE_SECURITY_GROUP_ID=\"$APP_INSTANCE_SECURITY_GROUP_ID\"" >> "$EXPORT_VARIABLES_FILE"

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
    --source-group $APP_INSTANCE_SECURITY_GROUP_ID
# Tagging the security group for easier identification
aws ec2 create-tags \
    --resources $EFS_SECURITY_GROUP_ID \
    --tags Key=Name,Value=$SG_EFS_NAME

# Send the (EFS Mount Target security group ID) to the (infrastructure_variables file) to use it with anotherr services configuration
echo "export EFSMountTarget_SECURITY_GROUP_ID=\"$EFS_SECURITY_GROUP_ID\"" >> "$EXPORT_VARIABLES_FILE"

# [step-01-create-networkingStructure.yaml]
# YAML templete to create a networking structure to use it with CloudFormation service
cat << EOF > $YAML_FILE
AWSTemplateFormatVersion: 2010-09-09

Description: template which builds VPC, supporting resources, a basic networking structure, and some Security groups.

Parameters:
  VPCCIDR:
    Description: CIDR Block for VPC
    Type: String
    Default: $VPC_CIDR

  PublicSubnet1Param:
    Description: Public Subnet 1
    Type: String
    Default: $PUBLIC_SUBNET1_CIDR

  PublicSubnet2Param:
    Description: Public Subnet 2
    Type: String
    Default: $PUBLIC_SUBNET2_CIDR

  AppSubnet1Param:
    Description: App Subnet 1
    Type: String
    Default: $APP_SUBNET1_CIDR

  AppSubnet2Param:
    Description: App Subnet 2
    Type: String
    Default: $APP_SUBNET2_CIDR

  DatabaseSubnet1Param:
    Description: Private Subnet 1
    Type: String
    Default: $DATABASE_SUBNET1_CIDR

  DatabaseSubnet2Param:
    Description: Private Subnet 2
    Type: String
    Default: $DATABASE_SUBNET2_CIDR

Resources:
###########
# VPC and Network Structure
###########
  LabVPC:
    Type: 'AWS::EC2::VPC'
    Properties:
      CidrBlock: !Ref VPCCIDR
      EnableDnsSupport: True
      EnableDnsHostnames: True
      InstanceTenancy: 'default'
      Tags:
        - Key: Name
          Value: My-VPC-2024

  LabInternetGateway:
    Type: 'AWS::EC2::InternetGateway'

  AttachGateway:
    Type: 'AWS::EC2::VPCGatewayAttachment'
    Properties:
      VpcId: !Ref LabVPC
      InternetGatewayId: !Ref LabInternetGateway

#NATs
  NATGateway1:
    Type: AWS::EC2::NatGateway
    Properties:
      AllocationId: !GetAtt ElasticIPAddress1.AllocationId
      SubnetId: !Ref PublicSubnet1
      Tags:
        - Key: Name
          Value: NAT_publicSubnet-01

  ElasticIPAddress1:
    Type: AWS::EC2::EIP
    Properties:
      Domain: vpc

  NATGateway2:
    Type: AWS::EC2::NatGateway
    Properties:
      AllocationId: !GetAtt ElasticIPAddress2.AllocationId
      SubnetId: !Ref PublicSubnet2
      Tags:
        - Key: Name
          Value: NAT_publicSubnet-02

  ElasticIPAddress2:
    Type: AWS::EC2::EIP
    Properties:
      Domain: vpc

#Subnets
  PublicSubnet1:
    Type: 'AWS::EC2::Subnet'
    Properties:
      VpcId: !Ref LabVPC
      CidrBlock: !Ref PublicSubnet1Param
      MapPublicIpOnLaunch: True
      AvailabilityZone: !Select
        - '0'
        - !GetAZs ''
      Tags:
        - Key: Name
          Value: Public-subnet-1

  PublicSubnet2:
    Type: 'AWS::EC2::Subnet'
    Properties:
      VpcId: !Ref LabVPC
      CidrBlock: !Ref PublicSubnet2Param
      MapPublicIpOnLaunch: True
      AvailabilityZone: !Select
        - '1'
        - !GetAZs ''
      Tags:
        - Key: Name
          Value: Public-subnet-2

  AppSubnet1:
    Type: 'AWS::EC2::Subnet'
    Properties:
      VpcId: !Ref LabVPC
      CidrBlock: !Ref AppSubnet1Param
      MapPublicIpOnLaunch: False
      AvailabilityZone: !Select
        - '0'
        - !GetAZs ''
      Tags:
        - Key: Name
          Value: App-subnet-1

  AppSubnet2:
    Type: 'AWS::EC2::Subnet'
    Properties:
      VpcId: !Ref LabVPC
      CidrBlock: !Ref AppSubnet2Param
      MapPublicIpOnLaunch: False
      AvailabilityZone: !Select
        - '1'
        - !GetAZs ''
      Tags:
        - Key: Name
          Value: App-subnet-2

  DatabaseSubnet1:
    Type: 'AWS::EC2::Subnet'
    Properties:
      VpcId: !Ref LabVPC
      CidrBlock: !Ref DatabaseSubnet1Param
      MapPublicIpOnLaunch: False
      AvailabilityZone: !Select
        - '0'
        - !GetAZs ''
      Tags:
        - Key: Name
          Value: Database-subnet-1

  DatabaseSubnet2:
    Type: 'AWS::EC2::Subnet'
    Properties:
      VpcId: !Ref LabVPC
      CidrBlock: !Ref DatabaseSubnet2Param
      MapPublicIpOnLaunch: False
      AvailabilityZone: !Select
        - '1'
        - !GetAZs ''
      Tags:
        - Key: Name
          Value: Database-subnet-2

#Routing
#Route Tables
  PublicRouteTable:
    Type: 'AWS::EC2::RouteTable'
    Properties:
      VpcId: !Ref LabVPC
      Tags:
        - Key: Name
          Value: Public-routeTable

  PrivateRouteTableAZ1:
    Type: 'AWS::EC2::RouteTable'
    Properties:
      VpcId: !Ref LabVPC
      Tags:
        - Key: Name
          Value: Private-routeTable-AZ1

  PrivateRouteTableAZ2:
    Type: 'AWS::EC2::RouteTable'
    Properties:
      VpcId: !Ref LabVPC
      Tags:
        - Key: Name
          Value: Private-routeTable-AZ2
#Routes
  PublicRoute:
    Type: 'AWS::EC2::Route'
    Properties:
      RouteTableId: !Ref PublicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref LabInternetGateway

  PrivateRouteAZ1:
    Type: 'AWS::EC2::Route'
    Properties:
      RouteTableId: !Ref PrivateRouteTableAZ1
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId: !Ref NATGateway1

  PrivateRouteAZ2:
    Type: 'AWS::EC2::Route'
    Properties:
      RouteTableId: !Ref PrivateRouteTableAZ2
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId: !Ref NATGateway2
#Subnet Associations
  PublicSubnet1RouteTableAssociation:
    Type: 'AWS::EC2::SubnetRouteTableAssociation'
    Properties:
      SubnetId: !Ref PublicSubnet1
      RouteTableId: !Ref PublicRouteTable

  PublicSubnet2RouteTableAssociation:
    Type: 'AWS::EC2::SubnetRouteTableAssociation'
    Properties:
      SubnetId: !Ref PublicSubnet2
      RouteTableId: !Ref PublicRouteTable

  AppSubnet1RouteTableAssociation:
    Type: 'AWS::EC2::SubnetRouteTableAssociation'
    Properties:
      SubnetId: !Ref AppSubnet1
      RouteTableId: !Ref PrivateRouteTableAZ1

  AppSubnet2RouteTableAssociation:
    Type: 'AWS::EC2::SubnetRouteTableAssociation'
    Properties:
      SubnetId: !Ref AppSubnet2
      RouteTableId: !Ref PrivateRouteTableAZ2

  DatabaseSubnet1RouteTableAssociation:
    Type: 'AWS::EC2::SubnetRouteTableAssociation'
    Properties:
      SubnetId: !Ref DatabaseSubnet1
      RouteTableId: !Ref PrivateRouteTableAZ1

  DatabaseSubnet2RouteTableAssociation:
    Type: 'AWS::EC2::SubnetRouteTableAssociation'
    Properties:
      SubnetId: !Ref DatabaseSubnet2
      RouteTableId: !Ref PrivateRouteTableAZ2

###########
# Security Groups
###########
  AppInstanceSecurityGroup:
    Type: 'AWS::EC2::SecurityGroup'
    Properties:
      GroupDescription: Security Group allowing HTTP traffic for lab instances
      VpcId: !Ref LabVPC
      Tags:
        - Key: Name
          Value: AppInstanceSecurityGroup
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0

  RDSSecurityGroup:
    Type: 'AWS::EC2::SecurityGroup'
    Properties:
      GroupDescription: Security Group allowing RDS instances to have internet traffic
      VpcId: !Ref LabVPC
      Tags:
        - Key: Name
          Value: RDSSecurityGroup

  EFSMountTargetSecurityGroup:
    Type: 'AWS::EC2::SecurityGroup'
    Properties:
      GroupDescription: Security Group allowing traffic between EFS Mount Targets and Amazon EC2 instances
      VpcId: !Ref LabVPC
      Tags:
        - Key: Name
          Value: EFSMountTargetSecurityGroup
      SecurityGroupIngress:
        - IpProtocol: tcp
          SourceSecurityGroupId: !Ref AppInstanceSecurityGroup
          FromPort: 80
          ToPort: 80

Outputs:

  Region:
    Description: "Lab Region"
    Value: !Ref AWS::Region
    
  DatabaseSubnet1CIDR:
    Description: "CIDR block for the DB Subnet in AZ a"
    Value: !Ref DatabaseSubnet1Param

  DatabaseSubnet2CIDR:
    Description: "CIDR block for the DB Subnet in AZ b"
    Value: !Ref DatabaseSubnet2Param

  DatabaseSubnet1ID:
    Description: "The Subnet ID for the DB Subnet in AZ a"
    Value: !Ref DatabaseSubnet1
    Export:
      Name: "DatabaseSubnet1ID"

  DatabaseSubnet2ID:
    Description: "The Subnet ID for the DB Subnet in AZ b"
    Value: !Ref DatabaseSubnet2
    Export:
      Name: "DatabaseSubnet2ID"

  AppInstanceSecurityGroupID:
    Description: "The Security Group ID for the Lab Instance Security Group"
    Value: !Ref AppInstanceSecurityGroup
    Export:
      Name: "AppInstanceSecurityGroupID"

  EFSMountTargetSecurityGroupID:
    Description: "The Security Group ID for the Lab EFS Mount Target"
    Value: !Ref EFSMountTargetSecurityGroup
    Export:
      Name: "EFSMountTargetSecurityGroupID"

  RDSSecurityGroupID:
    Description: "The Security Group ID for the Lab RDS cluster"
    Value: !Ref RDSSecurityGroup
    Export:
      Name: "RDSSecurityGroupID"

  VPCID:
    Description: "The VPC ID for the lab"
    Value: !Ref LabVPC
    Export:
      Name: "VPCID"
EOF