#!/bin/bash


if [ "$1" = "spin-up" ]
then
    echo "spin-up: creating spot instance request according to the yaml file in /spin-up"
    aws ec2 request-spot-instances \
        --profile personal \
        --cli-input-yaml file://spin-up/spot-instance-request-specification.yaml \
        > last-spot-request-output.json
fi


# cancel all spot instance requests and terminate all ec2 instances
if [ "$1" = "spin-down" ]
then
    echo "spinning down!"

    # terminate every ec2 instance; TODO look into filtering this by minecraft tag
    EC2_INSTANCE_IDS=`aws ec2 describe-instances --profile personal | \
                      jq '.Reservations[] | .Instances[] | .InstanceId'`
    for ec2_id in $(echo "$EC2_INSTANCE_IDS" | jq -r); do
        echo "Terminating ec2 instance with id: $ec2_id"
        aws ec2 terminate-instances \
            --profile personal \
            --instance-ids "$ec2_id" | grep ''
    done

    # cancel each spot request
    spot_request_ids=`jq '.SpotInstanceRequests[] | .SpotInstanceRequestId' < last-spot-request-output.json`
    for rid in $(echo "$spot_request_ids" | jq -r) # jq -r removes quotes from a string
    do
        echo "Deleting spot request with id: $rid"
        aws ec2 cancel-spot-instance-requests \
            --profile personal \
            --spot-instance-request-ids "$rid" | grep ''
    done

    # remove the last-spot-request file
    rm /Users/eric/Desktop/minecraft/aws/last-spot-request-output.json

fi