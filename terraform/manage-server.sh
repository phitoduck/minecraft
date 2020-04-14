#!/bin/bash

PATH_TO_SSH_KEY="/Users/eric/.aws/eric-personal.pem"
ELASTIC_IP=54.184.232.92

if [ "$1" = "spin-up" ]
then
    echo "spin-up: creating spot instance request according to the terraform/main.tf"
    terraform apply
fi

# cancel all spot instance requests and terminate all ec2 instances
if [ "$1" = "spin-down" ]
then
    echo "spinning down!"
    terraform destroy

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