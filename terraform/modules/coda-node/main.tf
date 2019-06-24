# Declare provider for region taken as input
provider "aws" {
  region = "${var.region}"
}

# Discover availability zones
data "aws_availability_zones" "azs" {
  state = "available"
}

# Discover most recent debian stretch image
data "aws_ami" "image" {
  most_recent = true
  owners      = ["379101102735"]

  filter {
    name   = "name"
    values = ["debian-stretch-hvm-x86_64-gp2-*"]
  }
}

# The Node instance
resource "aws_instance" "coda_node" {
  count                       = "${var.server_count}"
  ami                         = "${data.aws_ami.image.id}"
  instance_type               = "${var.instance_type}"
  security_groups             = ["${aws_security_group.coda_sg.name}"]
  key_name                    = "${var.public_key != "" ? aws_key_pair.testnet[0].key_name : var.key_name}"
  availability_zone           = "${element(data.aws_availability_zones.azs.names, count.index)}"
  associate_public_ip_address = "${var.use_eip}"

  tags = {
    Name = "${var.netname}_${var.region}_${var.rolename}_${count.index}"
    role = "${var.netname}_${var.rolename}"
    testnet = "${var.netname}"
  }

  # Default root is 8GB
  root_block_device {
    volume_size = 32
  }

  # Role Specific Magic Happens Here
  user_data = <<-EOF
#!/bin/bash
echo "Setting hostname"
hostnamectl set-hostname ${var.netname}_${var.region}_${var.rolename}_${count.index}.${var.region}
echo '127.0.1.1  ${var.netname}_${var.region}_${var.rolename}_${count.index}.${var.region}' >> /etc/hosts

# coda flags
echo ${var.rolename} > /etc/coda-rolename

# journal logs on disk
mkdir /var/log/journal

# user tools
apt-get --yes install \
  bc \
  dnsutils \
  emacs-nox \
  htop \
  jq \
  lsof \
  ncdu \
  rsync \
  tmux \
  ttyload

# dev tools
apt-get --yes install python3-pip
pip3 install \
  'elasticsearch>=6.0.0,<7.0.0' \
  certifi \
  geoip2 \
  psutil \
  sexpdata

  EOF
}

resource "aws_key_pair" "testnet" {
  count = "${var.public_key != "" ? 1 : 0}"
  key_name   = "${var.netname}_${var.region}_${var.rolename}_keypair"
  public_key = "${var.public_key}"
}

