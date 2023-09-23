provider "aws" {
  region = "us-east-1"
}

resource "tls_private_key" "rsa" {
algorithm = "RSA"
rsa_bits  = 4096
}

resource "local_file" "tf-key" {
  content = tls_private_key.rsa.private_key_pem
  filename = "ssh-key"
}

resource "aws_key_pair" "ssh-key" {
  key_name = "ssh-key"
  public_key = tls_private_key.rsa.public_key_openssh

}
resource "aws_instance" "jenkins-ec2" {
  ami = "ami-03a6eaae9938c858c"
  instance_type = "t2.medium"
  tags = {
    Name = "jenkins-master"
  }
  key_name = aws_key_pair.ssh-key.key_name
  user_data = <<-EOF
              sudo yum update –y
              sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
              sudo yum upgrade
              sudo dnf install java-11-amazon-corretto -y
              sudo yum install jenkins -y
              sudo systemctl enable jenkins
              sudo systemctl start jenkins
              sudo yum install -y yum-utils
              sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
              sudo yum -y install terraform
              sudo yum install git -y
              EOF
  user_data_replace_on_change = true
  vpc_security_group_ids = [aws_security_group.jenkins-security-group.id]
}

resource "aws_security_group" "jenkins-security-group" {
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

output "jenkins-server" {
  value = aws_instance.jenkins-ec2.public_dns
}