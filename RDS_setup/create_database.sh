#!/bin/bash

# Path to the export file
EXPORT_VARIABLES_FILE="../infrastructure_variables.sh"
# Path to the folder containing JSON templates for RDS database creation for CloudFormation deployment
JSON_FILE="../CloudFormation_json/step-07-create-database.json"

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

# JSON templet to create a RDS database to use it for CloudFormation
# note: you should execute these templates before using this template
# [1][step-01-create-VPC.json] 
# [2][step-02-create-subnets.json] 
# [3][step-03-create-internetGateway.json] 
# [4][step-04-create-NATgateways.json]
# [5][step-05-create-routeTables.json]
# [6][step-06-create_securityGroups.json]
cat << EOF > $JSON_FILE
{
    "AWSTemplateFormatVersion": "2010-09-09",
    "Description": "CloudFormation template to create an Aurora MySQL DB Cluster with instances in two AZs.",
    "Resources": {
        "AuroraSubnetGroup": {
            "Type": "AWS::RDS::DBSubnetGroup",
            "Properties": {
                "DBSubnetGroupName": "$DB_SUBNET_GROUP_NAME",
                "DBSubnetGroupDescription": "$DB_SUBNET_GROUP_DESCRIPTION",
                "SubnetIds": [
                    "$DATABASE_SUBNET1_ID",
                    "$DATABASE_SUBNET2_ID"
                ],
                "Tags": [
                    {
                        "Key": "Name",
                        "Value": "AuroraDBSubnetGroup"
                    }
                ]
            }
        },
        "MyDBCluster": {
            "Type": "AWS::RDS::DBCluster",
            "Properties": {
                "DBClusterIdentifier": "$DB_CLUSTER_IDENTIFIER",
                "Engine": "$ENGINE",
                "EngineVersion": "$ENGINE_VERSION",
                "DBSubnetGroupName": { "Ref": "AuroraSubnetGroup" },
                "VpcSecurityGroupIds": ["$RDS_SECURITY_GROUP_ID"],
                "BackupRetentionPeriod": 1,
                "MasterUsername": "$MASTER_USERNAME",
                "MasterUserPassword": "$MASTER_USERPASSWORD",
                "DatabaseName": "$INITIAL_DATABASE_NAME",
                "AvailabilityZones": ["me-south-1a", "me-south-1b"],
                "Tags": [
                    {
                        "Key": "Name",
                        "Value": "MyDBCluster"
                    }
                ]
            }
        },
        "MyDBClusterInstance1": {
            "Type": "AWS::RDS::DBInstance",
            "Properties": {
                "DBInstanceIdentifier": "mydbcluster-instance-1",
                "DBClusterIdentifier": { "Ref": "MyDBCluster" },
                "DBInstanceClass": "$DB_INSTANCE_CLASS",
                "Engine": "$ENGINE",
                "EngineVersion": "$ENGINE_VERSION",
                "AvailabilityZone": "me-south-1a",
                "AutoMinorVersionUpgrade": false,
                "PubliclyAccessible": false
            }
        },
        "MyDBClusterInstance1MeSouth1b": {
            "Type": "AWS::RDS::DBInstance",
            "Properties": {
                "DBInstanceIdentifier": "mydbcluster-instance-1-me-south-1b",
                "DBClusterIdentifier": { "Ref": "MyDBCluster" },
                "DBInstanceClass": "$DB_INSTANCE_CLASS",
                "Engine": "$ENGINE",
                "EngineVersion": "$ENGINE_VERSION",
                "AvailabilityZone": "me-south-1b",
                "AutoMinorVersionUpgrade": false,
                "PubliclyAccessible": false
            }
        }
    }
}
EOF