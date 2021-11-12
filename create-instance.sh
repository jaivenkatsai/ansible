 #!/bin/bash

LID="lt-0ff4d1f08d27a230e" 
LVER=5
INSTANCE_NAME=$1

if [ -z "${INSTANCE_NAME}" ]; then
    echo "Input is missing"
    exit 1
fi

aws ec2 describe-instances --filters "Name=tag:Name,Values=$INSTANCE_NAME" | jq .Reservations[].Instances[].State.Name | grep running &>/dev/null
if [ $? -eq 0 ]; then
    echo "Instance $INSTANCE_NAME is already running"
    exit 0
fi

aws ec2 describe-instances --filters "Name=tag:Name,Values=$INSTANCE_NAME" | jq .Reservations[].Instances[].State.Name | grep stopped &>/dev/null
if [ $? -eq 0 ]; then
    echo "Instance $INSTANCE_NAME is already created and stopped"
    exit 0
fi

IP=$(aws ec2 run-instances --launch-template LaunchTemplateId=$LID,Version=$LVER --tag-specifications "ResourceType=spot-instances-request,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" | jq .Instances[].PrivateIpAddress | sed -e 's/"//g')

sed -e "s/INSTANCE_NAME/$INSTANCE_NAME/" -e "s/INSTANCE_IP/$IP/" record.json >/tmp/record.json
aws route53 change-resource-record-sets --hosted-zone-id Z04611413KBLOLPCU34DM --change-batch file:///tmp/record.json | jq