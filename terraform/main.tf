variable "access_key" {}

variable "secret_key" {}

variable "region" {
  default = "ap-southeast-2"
}

variable "home_ip" {}

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_vpc" "main" {
  cidr_block = "10.125.0.0/16"

  tags {
    Name = "cits5503 vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "cits5503 igw"
  }
}

resource "aws_subnet" "public-a" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "10.125.1.0/24"
  availability_zone = "ap-southeast-2a"

  tags {
    Name = "cits5503 public subnet a"
  }
}

resource "aws_route_table" "public-a" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  tags {
    Name = "main"
  }
}

resource "aws_main_route_table_association" "a" {
  vpc_id         = "${aws_vpc.main.id}"
  route_table_id = "${aws_route_table.public-a.id}"
}

resource "aws_route_table_association" "a" {
  subnet_id      = "${aws_subnet.public-a.id}"
  route_table_id = "${aws_route_table.public-a.id}"
}

resource "aws_security_group" "cits5503" {
  name        = "cits5503"
  description = "ingress ssh, http/s from my ip, egress everywhere"
  vpc_id      = "${aws_vpc.main.id}"

  # Allow all traffic internally
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.125.0.0/16"]
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.home_ip}/32"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.home_ip}/32"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${var.home_ip}/32"]
  }

  # Mosh
  ingress {
    from_port   = 60000
    to_port     = 61000
    protocol    = "udp"
    cidr_blocks = ["${var.home_ip}/32"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "cits5503"
  }
}

resource "aws_key_pair" "cits5503" {
  key_name   = "cits5503"
  public_key = "${file("cits5503.pub")}"
}

resource "aws_instance" "cits5503" {
  ami                         = "ami-ba3e14d9"
  instance_type               = "t2.small"
  key_name                    = "${aws_key_pair.cits5503.key_name}"
  vpc_security_group_ids      = ["${aws_security_group.cits5503.id}"]
  subnet_id                   = "${aws_subnet.public-a.id}"
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.cits5503.id}"
  user_data                   = "${file("userdata.sh")}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 15
    delete_on_termination = true
  }

  tags {
    Name = "cits5503"
  }

  lifecycle {
    prevent_destroy = true

    ignore_changes = [
      "instance_type",
    ]
  }
}

resource "aws_ebs_volume" "data" {
  availability_zone = "ap-southeast-2a"
  type              = "gp2"
  size              = 40
  encrypted         = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "data-att" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.data.id}"
  instance_id = "${aws_instance.cits5503.id}"
}

resource "aws_iam_instance_profile" "cits5503" {
  name  = "cits5503"
  roles = ["${aws_iam_role.cits5503.name}"]
}

resource "aws_iam_role" "cits5503" {
  name = "cits5503"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

output "instance_address" {
  value = "${aws_instance.cits5503.public_ip}"
}
