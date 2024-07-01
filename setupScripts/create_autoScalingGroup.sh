#!/bin/bash

# Path to the export file
EXPORT_VARIABLES_FILE="/home/kld/Github_projects/aws-infra-builder-with-airflow/infrastructure_variables.sh"
# Path to the folder containing (yaml) templates for auto scaling group creation for CloudFormation deployment
YAML_FILE="/home/kld/Github_projects/aws-infra-builder-with-airflow/CloudFormation_yaml/step-06-create-autoScalingGroup.yaml"

# Source the export file to get the VPC_ID variable
if [[ -f "$EXPORT_VARIABLES_FILE" ]]; then
    source "$EXPORT_VARIABLES_FILE"
else
    echo "Export file not found: $EXPORT_VARIABLES_FILE"
    exit 1
fi

# Create auto scaling group
aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name WP-ASG \
    --launch-template "LaunchTemplateName=LabLaunchTemplate" \
    --vpc-zone-identifier "$APP_SUBNET1_ID,$APP_SUBNET2_ID" \
    --health-check-type ELB \
    --health-check-grace-period 300 \
    --desired-capacity 2 \
    --min-size 2 \
    --max-size 4 \
    --target-group-arns "$TARGETGROUP_ARN" \
    --tags "ResourceId=WP-ASG,ResourceType=auto-scaling-group,Key=Name,Value=WP-App,PropagateAtLaunch=true" \
    --default-cooldown 300 \
    --termination-policies "Default" \
    --availability-zones "me-south-1a" "me-south-1b"

# Set a target tracking scaling policy
aws autoscaling put-scaling-policy \
    --auto-scaling-group-name WP-ASG \
    --policy-name myTargetTrackingPolicy \
    --policy-type TargetTrackingScaling \
    --estimated-instance-warmup 300 \
    --target-tracking-configuration "TargetValue=50.0,PredefinedMetricSpecification={PredefinedMetricType=ASGAverageCPUUtilization}"

# [step-06-create-autoScalingGroup.yaml]
# YAML template to create auto scaling group to use it with CloudFormation service
# note: you should execute these templates before using this template
# [1]-[step-01-create-networkingStructure.yaml]
# [2]-[step-04-create-targetGroup-and-loadBalancer.yaml]
cat << EOF > $YAML_FILE
AWSTemplateFormatVersion: 2010-09-09
Description: AWS CloudFormation template to create Auto Scaling Group and Target Tracking Scaling Policy for WordPress

Parameters:
  AutoScalingGroupName:
    Type: String
    Default: WP-ASG
    Description: The name of the Auto Scaling Group

  LaunchTemplateName:
    Type: String
    Default: LabLaunchTemplate
    Description: The name of the Launch Template to use

  LaunchTemplateVersion:
    Type: String
    Default: 1
    Description: The version of the Launch Template to use

  AppSubnet1ID:
    Type: AWS::EC2::Subnet::Id
    Default: $APP_SUBNET1_ID
    Description: The ID of the first APP subnet

  AppSubnet2ID:
    Type: AWS::EC2::Subnet::Id
    Default: $APP_SUBNET2_ID
    Description: The ID of the second APP subnet

  DesiredCapacity:
    Type: Number
    Default: 2
    Description: The desired capacity for the Auto Scaling Group

  MinSize:
    Type: Number
    Default: 2
    Description: The minimum size of the Auto Scaling Group

  MaxSize:
    Type: Number
    Default: 4
    Description: The maximum size of the Auto Scaling Group

  TargetGroupARN:
    Type: String
    Default: $TARGETGROUP_ARN
    Description: The ARN of the Target Group

Resources:
  WordPressAutoScalingGroup:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      AutoScalingGroupName: !Ref AutoScalingGroupName
      LaunchTemplate:
        LaunchTemplateName: !Ref LaunchTemplateName
        Version: !Ref LaunchTemplateVersion
      VPCZoneIdentifier:
        - !Ref AppSubnet1ID
        - !Ref AppSubnet2ID
      HealthCheckType: ELB
      HealthCheckGracePeriod: 300
      DesiredCapacity: !Ref DesiredCapacity
      MinSize: !Ref MinSize
      MaxSize: !Ref MaxSize
      TargetGroupARNs:
        - !Ref TargetGroupARN
      Tags:
        - Key: Name
          Value: WP-App
          PropagateAtLaunch: true
      TerminationPolicies:
        - Default

  TargetTrackingScalingPolicy:
    Type: AWS::AutoScaling::ScalingPolicy
    Properties:
      AutoScalingGroupName: !Ref WordPressAutoScalingGroup
      PolicyName: myTargetTrackingPolicy
      PolicyType: TargetTrackingScaling
      EstimatedInstanceWarmup: 300
      TargetTrackingConfiguration:
        TargetValue: 50.0
        PredefinedMetricSpecification:
          PredefinedMetricType: ASGAverageCPUUtilization

Outputs:
  AutoScalingGroupName:
    Description: The name of the Auto Scaling Group
    Value: !Ref WordPressAutoScalingGroup
  TargetTrackingPolicyName:
    Description: The name of the Target Tracking Scaling Policy
    Value: !Ref TargetTrackingScalingPolicy
EOF