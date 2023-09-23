provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "ec2-server-1" {
  ami = "ami-03a6eaae9938c858c"
  instance_type = "t2.micro"
  tags = {
    Name = "terraform-example"
  }
  user_data = <<-EOF
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
  user_data_replace_on_change = true
  vpc_security_group_ids = [aws_security_group.ec2-security-group.id]
}

resource "aws_security_group" "ec2-security-group" {
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}