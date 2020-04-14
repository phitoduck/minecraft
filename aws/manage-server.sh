#!/bin/bash

# fantastic resources
# comparison operators in bash: https://ryanstutorials.net/bash-scripting-tutorial/bash-if-statements.php
# jq quick reference: https://stedolan.github.io/jq/tutorial/

PATH_TO_SSH_KEY="/Users/eric/.aws/eric-personal.pem"
ELASTIC_IP=54.184.232.92

if [ "$1" = "spin-up" ]
then
    echo "spin-up: creating spot instance request according to the yaml file in /spin-up"

    # base64 encode the bootstrap-instance.sh script, and put the encoded string in the UserData YAML field
    cat ./spin-up/spot-instance-request-specification.yaml | \
        sed "s/UserData.*/UserData: \"$(base64 ./spin-up/bootstrap-instance.sh)\"/g" \
        > ./spin-up/spot-instance-request-specification.yaml

    # use the YAML file to create a spot instance request
    aws ec2 request-spot-instances \
        --profile personal \
        --cli-input-yaml file://spin-up/spot-instance-request-specification.yaml \
        > last-spot-request-output.json # output is stored here, to be used in spin-down
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

    # remove the ssh-key from known hosts so that ssh doesn't freak out
    # that we're connecting to a different machine at the same ip address next time
    # explanation here: https://stackabuse.com/how-to-fix-warning-remote-host-identification-has-changed-on-mac-and-linux/
    ssh-keygen -R "$ELASTIC_IP"
fi


# run a command on the minecraft server
# usage: run "time set day"
if [ "$1" = "run" ]; then
    ssh -i $PATH_TO_SSH_KEY ec2-user@$ELASTIC_IP "sudo docker exec minecraft mc_send \"$2\"" 
fi

# run any ssh command on the server
if [ "$1" = "ssh-command" ]; then
    ssh -i $PATH_TO_SSH_KEY ec2-user@$ELASTIC_IP "$2" 
fi

# run any ssh command on the server
if [ "$1" = "ssh" ]; then
    ssh -i $PATH_TO_SSH_KEY ec2-user@$ELASTIC_IP
fi 