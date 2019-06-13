resource "aws_security_group" "coda_sg" {
  name        = "${var.region}_${var.rolename}_${var.netname}_coda_sg"
  description = "Allow control access and coda ports open"

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TCP RPC - snark coordination"
    from_port   = "${var.port_rpc}"
    to_port     = "${var.port_rpc}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TCP Gossip"
    from_port   = "${var.port_gossip}"
    to_port     = "${var.port_gossip}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "UDP Peer Discovery"
    from_port   = "${var.port_dht}"
    to_port     = "${var.port_dht}"
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TCP ql"
    from_port   = "${var.port_ql}"
    to_port     = "${var.port_ql}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  tags = {
    Name = "${var.netname}_coda_sg"
  }
}
