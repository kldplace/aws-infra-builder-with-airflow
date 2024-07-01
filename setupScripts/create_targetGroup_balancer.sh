#!/bin/bash

# Path to the export file
EXPORT_VARIABLES_FILE="/home/kld/Github_projects/aws-infra-builder-with-airflow/infrastructure_variables.sh"
# Path to the folder containing (yaml) templates for Target group and Load balancer creation for CloudFormation deployment
YAML_FILE="/home/kld/Github_projects/aws-infra-builder-with-airflow/CloudFormation_yaml/step-04-create-targetGroup-and-loadBalancer.yaml"

# Source the export file to get the VPC_ID variable
if [[ -f "$EXPORT_VARIABLES_FILE" ]]; then
    source "$EXPORT_VARIABLES_FILE"
else
    echo "Export file not found: $EXPORT_VARIABLES_FILE"
    exit 1
fi

# Creat the Target group
TARGETGROUP_ARN=$(aws elbv2 create-target-group \
    --name myWPTargetGroup \
    --protocol HTTP \
    --port 80 \
    --vpc-id $VPC_ID \
    --health-check-protocol HTTP \
    --health-check-path /wp-login.php \
    --health-check-port traffic-port \
    --health-check-interval-seconds 60 \
    --health-check-timeout-seconds 50 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 10 \
    --matcher HttpCode=200 \
    --query TargetGroups[0].TargetGroupArn \
    --output text)

# Send the (Target group ARN) to the (infrastructure_variables file) to use it with Auto scaling configuration configuration
echo "export TARGETGROUP_ARN=\"$TARGETGROUP_ARN\"" >> "$EXPORT_VARIABLES_FILE"

# Create load balancer
APP_LOADBALANCER_ARN=$(aws elbv2 create-load-balancer \
  --name myWPAppALB \
  --type application \
  --scheme internet-facing \
  --ip-address-type ipv4 \
  --security-groups $APPINSTANCE_SECURITY_GROUP_ID \
  --subnets $PUBLIC_SUBNET1_ID $PUBLIC_SUBNET2_ID \
  --query LoadBalancers[0].LoadBalancerArn \
  --output text)

# Get the DNS name of the load balancer using the ARN
APP_LOADBALANCER_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns $APP_LOADBALANCER_ARN \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

# Send the (DNS name) to the (infrastructure_variables file) to use it with Auto scaling configuration for launch template
echo "export APP_LOADBALANCER_DNS=\"$APP_LOADBALANCER_DNS\"" >> "$EXPORT_VARIABLES_FILE"

# Create listener to listen to the port 80 for laad balancer and target group
aws elbv2 create-listener \
  --load-balancer-arn $APP_LOADBALANCER_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TARGETGROUP_ARN


# [step-04-create-targetGroup-and-loadBalancer.yaml]
# YAML template to create Target group and Load balancer to use it with CloudFormation service
# note: you should execute [step-01-create-networkingStructure.yaml] template before using this template
cat << EOF > $YAML_FILE
AWSTemplateFormatVersion: 2010-09-09
Description: AWS CloudFormation template to create target group and load balancer

Parameters:
  MyVPC:
    Type: "AWS::EC2::VPC::Id"
    Description: The ID of the VPC
    Default: $VPC_ID
  AppInstanceSecurityGroup:
    Type: "AWS::EC2::SecurityGroup::Id"
    Description: The ID of the security group for the application instances
    Default: $APPINSTANCE_SECURITY_GROUP_ID
  PublicSubnet1:
    Type: "AWS::EC2::Subnet::Id"
    Description: The ID of the first public subnet
    Default: $PUBLIC_SUBNET1_ID
  PublicSubnet2:
    Type: "AWS::EC2::Subnet::Id"
    Description: The ID of the second public subnet
    Default: $PUBLIC_SUBNET2_ID

Resources:
  MyTargetGroup:
    Type: "AWS::ElasticLoadBalancingV2::TargetGroup"
    Properties:
      Name: myWPTargetGroup
      Protocol: HTTP
      Port: 80
      VpcId: !Ref MyVPC
      HealthCheckProtocol: HTTP
      HealthCheckPath: /wp-login.php
      HealthCheckPort: traffic-port
      HealthCheckIntervalSeconds: 60
      HealthCheckTimeoutSeconds: 50
      HealthyThresholdCount: 2
      UnhealthyThresholdCount: 10
      Matcher:
        HttpCode: 200

  MyLoadBalancer:
    Type: "AWS::ElasticLoadBalancingV2::LoadBalancer"
    Properties:
      Name: myWPAppALB
      Type: application
      Scheme: internet-facing
      IpAddressType: ipv4
      SecurityGroups:
        - !Ref AppInstanceSecurityGroup
      Subnets:
        - !Ref PublicSubnet1
        - !Ref PublicSubnet2

  MyListener:
    Type: "AWS::ElasticLoadBalancingV2::Listener"
    Properties:
      LoadBalancerArn: !Ref MyLoadBalancer
      Protocol: HTTP
      Port: 80
      DefaultActions:
        - Type: forward
          TargetGroupArn: !Ref MyTargetGroup
EOF