#!/bin/bash

# Path to the export file
EXPORT_VARIABLES_FILE="/home/kld/Github_projects/aws-infra-builder-with-airflow/infrastructure_variables.sh"
# Path to the folder containing (yaml) templates for RDS database creation for CloudFormation deployment
YAML_FILE="/home/kld/Github_projects/aws-infra-builder-with-airflow/CloudFormation_yaml/step-02-create-database.yaml"

# Source the export file to get the VPC_ID variable
if [[ -f "$EXPORT_VARIABLES_FILE" ]]; then
    source "$EXPORT_VARIABLES_FILE"
else
    echo "Export file not found: $EXPORT_VARIABLES_FILE"
    exit 1
fi

# DB subnet group variables
DB_SUBNET_GROUP_NAME="AuroraSubnetGroup"
DB_SUBNET_GROUP_DESCRIPTION="A 2 AZ subnet group for my database"

# Database variables
DB_CLUSTER_IDENTIFIER="MyDBCluster"
INITIAL_DATABASE_NAME="WPDatabase"
ENGINE="aurora-mysql"
ENGINE_VERSION="8.0.mysql_aurora.3.05.2"
DB_INSTANCE_CLASS="db.t3.medium"

# Create the DB Subnet Group [aurorasubnetgroup]
aws rds create-db-subnet-group \
    --db-subnet-group-name $DB_SUBNET_GROUP_NAME \
    --db-subnet-group-description "$DB_SUBNET_GROUP_DESCRIPTION" \
    --subnet-ids $DATABASE_SUBNET1_ID $DATABASE_SUBNET2_ID \
    --tags Key=Name,Value=AuroraDBSubnetGroup

# Create Aurora MySQL DB Cluster
aws rds create-db-cluster \
    --db-cluster-identifier $DB_CLUSTER_IDENTIFIER \
    --engine "$ENGINE" \
    --engine-version $ENGINE_VERSION \
    --db-subnet-group-name aurorasubnetgroup \
    --availability-zones me-south-1a me-south-1b \
    --vpc-security-group-ids $RDS_SECURITY_GROUP_ID \
    --backup-retention-period 1 \
    --master-username $MASTER_USERNAME \
    --master-user-password $MASTER_USERPASSWORD \
    --database-name $INITIAL_DATABASE_NAME \
    --tags Key=Name,Value=MyDBCluster \

# Create Aurora MySQL DB Instance in the [MyDBCluster] Cluster in the AZ1/me-south-1a
aws rds create-db-instance \
    --db-instance-identifier mydbcluster-instance-1 \
    --db-cluster-identifier $DB_CLUSTER_IDENTIFIER \
    --db-instance-class "$DB_INSTANCE_CLASS" \
    --engine "$ENGINE" \
    --engine-version $ENGINE_VERSION \
    --availability-zone me-south-1a \
    --no-auto-minor-version-upgrade \
    --no-publicly-accessible \

# Create Aurora MySQL DB Instance in the [MyDBCluster] Cluster in the AZ2/me-south-1b
aws rds create-db-instance \
    --db-instance-identifier mydbcluster-instance-1-me-south-1b \
    --db-cluster-identifier $DB_CLUSTER_IDENTIFIER \
    --db-instance-class "$DB_INSTANCE_CLASS" \
    --engine $ENGINE \
    --engine-version $ENGINE_VERSION \
    --availability-zone me-south-1b \
    --no-auto-minor-version-upgrade \
    --no-publicly-accessible \


# [step-02-create-database.yaml]
# YAML template to create RDS database structure to use it with CloudFormation service
# note: you should execute [step-01-create-networkingStructure.yaml] template before using this template
cat << EOF > $YAML_FILE
AWSTemplateFormatVersion: "2010-09-09"
Description: CloudFormation template to create an Aurora MySQL DB Cluster with instances in two AZs.

Parameters:
  DBSubnetGroupName:
    Type: String
    Default: $DB_SUBNET_GROUP_NAME
    Description: The name of the DB Subnet Group
  DBSubnetGroupDescription:
    Type: String
    Default: $DB_SUBNET_GROUP_DESCRIPTION
    Description: Description of the DB Subnet Group
  DatabaseSubnet1Id:
    Type: String
    Default: $DATABASE_SUBNET1_ID
    Description: Subnet ID for the first database subnet
  DatabaseSubnet2Id:
    Type: String
    Default: $DATABASE_SUBNET2_ID
    Description: Subnet ID for the second database subnet
  DBClusterIdentifier:
    Type: String
    Default: $DB_CLUSTER_IDENTIFIER
    Description: Identifier for the DB Cluster
  Engine:
    Type: String
    Default: $ENGINE
    Description: The database engine to use
  EngineVersion:
    Type: String
    Default: $ENGINE_VERSION
    Description: The version of the database engine
  RDSSecurityGroupId:
    Type: String
    Default: $RDS_SECURITY_GROUP_ID
    Description: Security group ID for the RDS
  MasterUsername:
    Type: String
    Default: $MASTER_USERNAME
    Description: The master username for the database
  MasterUserPassword:
    Type: String
    Default: $MASTER_USERPASSWORD
    Description: The master user password for the database
  InitialDatabaseName:
    Type: String
    Default: $INITIAL_DATABASE_NAME
    Description: The initial database name
  DBInstanceClass:
    Type: String
    Default: $DB_INSTANCE_CLASS
    Description: The instance class for the database

Resources:
  AuroraSubnetGroup:
    Type: "AWS::RDS::DBSubnetGroup"
    Properties:
      DBSubnetGroupName: !Ref DBSubnetGroupName
      DBSubnetGroupDescription: !Ref DBSubnetGroupDescription
      SubnetIds:
        - !Ref DatabaseSubnet1Id
        - !Ref DatabaseSubnet2Id
      Tags:
        - Key: Name
          Value: AuroraDBSubnetGroup

  MyDBCluster:
    Type: "AWS::RDS::DBCluster"
    Properties:
      DBClusterIdentifier: !Ref DBClusterIdentifier
      Engine: !Ref Engine
      EngineVersion: !Ref EngineVersion
      DBSubnetGroupName: !Ref AuroraSubnetGroup
      VpcSecurityGroupIds:
        - !Ref RDSSecurityGroupId
      BackupRetentionPeriod: 1
      MasterUsername: !Ref MasterUsername
      MasterUserPassword: !Ref MasterUserPassword
      DatabaseName: !Ref InitialDatabaseName
      AvailabilityZones:
        - me-south-1a
        - me-south-1b
      Tags:
        - Key: "Name"
          Value: "MyDBCluster"

  MyDBClusterInstance1:
    Type: "AWS::RDS::DBInstance"
    Properties:
      DBInstanceIdentifier: "mydbcluster-instance-1"
      DBClusterIdentifier: !Ref MyDBCluster
      DBInstanceClass: !Ref DBInstanceClass
      Engine: !Ref Engine
      EngineVersion: !Ref EngineVersion
      AvailabilityZone: me-south-1a
      AutoMinorVersionUpgrade: false
      PubliclyAccessible: false

  MyDBClusterInstance1MeSouth1b:
    Type: "AWS::RDS::DBInstance"
    Properties:
      DBInstanceIdentifier: "mydbcluster-instance-1-me-south-1b"
      DBClusterIdentifier: !Ref MyDBCluster
      DBInstanceClass: !Ref DBInstanceClass
      Engine: !Ref Engine
      EngineVersion: !Ref EngineVersion
      AvailabilityZone: me-south-1b
      AutoMinorVersionUpgrade: false
      PubliclyAccessible: false
EOF