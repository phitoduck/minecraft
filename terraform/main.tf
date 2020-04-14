provider "aws" {
  region = "us-west-2"
}

# Fantastic spot instance terraform documentation:
# https://www.terraform.io/docs/providers/aws/r/spot_instance_request.html
resource "aws_spot_instance_request" "mc_spot_request" {
  spot_price                      = "0.03"
  instance_type                   = "m1.large"
  spot_type                       = "one-time"
  instance_interruption_behaviour = "terminate" # optional (setting this to "terminate" is the default behavior)

  # Terraform will wait 10m for the request to complete
  # when set, the spot_instance_id will be accessible which
  # we can use to auto-associate the elastic ip
  wait_for_fulfillment = "true"

  # ec2 config
  ami             = "ami-0d254cd055795bb69" # Minecraft AMI id
  key_name        = "eric-personal"
  user_data       = file("./bootstrap-instance.sh")
  security_groups = ["MinecraftSecurityGroup"]

  tags = {
    Name = "mc_spot_request"
  }
}

resource "aws_eip_association" "mc_ip_association" {
  allocation_id = "eipalloc-0f3aa93bd0c66657d" # allocation id of the minecraft elastic ip
  instance_id   = aws_spot_instance_request.mc_spot_request.spot_instance_id
}
