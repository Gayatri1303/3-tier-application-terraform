
module "threetier" {
  source = "./modules/vpc"

}
module "public_subnet1" {
  
  source = "./modules/subnet"
  vpc_id = module.threetier.vpc_id
  pub_cidr="10.0.1.0/24"
  az = "ap-south-1b"
  
}
module "public_subnet2" {
  
  source = "./modules/subnet"
  vpc_id = module.threetier.vpc_id
  pub_cidr="10.0.3.0/24"
  az = "ap-south-1a"
  
}

module "private_subnet1" {
  
  source = "./modules/subnet"
  vpc_id = module.threetier.vpc_id
  pub_cidr="10.0.2.0/24"
  az = "ap-south-1a"
  
}

module "private_subnet2" {
  
  source = "./modules/subnet"
  vpc_id = module.threetier.vpc_id
  pub_cidr="10.0.4.0/24"
  az = "ap-south-1b"
  
}



resource "aws_internet_gateway" "example" {
  vpc_id = module.threetier.vpc_id

  tags = {
    Name = "IGW1"
  }
}

resource "aws_eip" "eip" {
  tags = {
    Name=" eip11"
  }
}

resource "aws_nat_gateway" "example" {
  allocation_id = aws_eip.eip.id
  subnet_id     = module.public_subnet1.subnet_id

  tags = {
    Name = "NATgw"
  }

  
  
}


resource "aws_route" "pbrt1" {
  
  route_table_id= module.threetier.mrtid

  
    destination_cidr_block = "0.0.0.0/0"
    gateway_id=aws_internet_gateway.example.id
  
  
    
}


resource "aws_route_table" "privrt1" {
  vpc_id = module.threetier.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.example.id
  }

  tags = {
    Name = "privrt1"
  }
}


resource "aws_route_table_association" "pvt" {
  subnet_id      = module.private_subnet1.subnet_id
  route_table_id = aws_route_table.privrt1.id
}

resource "aws_route_table_association" "pvt2" {
  subnet_id      = module.private_subnet2.subnet_id
  route_table_id = aws_route_table.privrt1.id
}


resource "aws_network_acl_association" "pubnacl" {
  network_acl_id = module.threetier.naclid
  subnet_id      = module.public_subnet1.subnet_id
}

resource "aws_network_acl_association" "pubnacl2" {
  network_acl_id = module.threetier.naclid
  subnet_id      = module.public_subnet2.subnet_id
}

resource "aws_network_acl" "privnacl" {
  vpc_id = module.threetier.vpc_id
  subnet_ids = [module.private_subnet1.subnet_id]
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = module.public_subnet1.pub_cidr
    from_port  = 80
    to_port    = 80
  }

  ingress {
    
    protocol = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = module.public_subnet1.pub_cidr
    from_port  = 80
    to_port    = 80
  }

  tags = {
    Name = "privnacl"
  }
}


resource "aws_network_acl_association" "privnacl" {
  network_acl_id = aws_network_acl.privnacl.id
  subnet_id      = module.private_subnet1.subnet_id
}

resource "aws_network_acl_rule" "ephemeral" {
  network_acl_id = aws_network_acl.privnacl.id
  rule_number    = 200
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0" 
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "ephemeral2" {
  network_acl_id = aws_network_acl.privnacl.id
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0" 
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "ssh1" {
  network_acl_id = aws_network_acl.privnacl.id
  rule_number    = 300
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0" 
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "ssh2" {
  network_acl_id = aws_network_acl.privnacl.id
  rule_number    = 300
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0" 
  from_port      = 22
  to_port        = 22
}

#EC2_ins





module "frontend" {
  source = "./modules/ec2"
  subnet_id = module.public_subnet1.subnet_id
  az="ap-south-1b"
  type=var.type
  name="frontend"
  key_name = "key123"
  sg=aws_security_group.frontendsg.id
  flag=true
  user = templatefile("./script1.sh",{
  DB_HOST = ""
  DB_USER = ""
  DB_PASS = ""
  DB_NAME = ""
  }
  )
}

module "backend1" {
  source = "./modules/ec2"
  subnet_id = module.private_subnet1.subnet_id
  az="ap-south-1a"
  type=var.type
  key_name = "key123"
  name="backend"
  sg=aws_security_group.backendsg.id
  flag=false
   user = templatefile("./script.sh", {
    DB_HOST = aws_db_instance.rds.address
    DB_USER = aws_db_instance.rds.username
    DB_PASS = aws_db_instance.rds.password
    DB_NAME = aws_db_instance.rds.db_name
    
  })

depends_on = [ aws_db_instance.rds ]
  
}

resource "aws_security_group" "frontendsg" {
  name        = "frontendsg"
  vpc_id      = module.threetier.vpc_id

  tags = {
    Name = "frontendsg"
  }
}


resource "aws_security_group" "backendsg" {
  name        = "backendsg"
  vpc_id      = module.threetier.vpc_id


  ingress {
    description              = "Allow API traffic from ALB"
    from_port                = 5000
    to_port                  = 5000
    protocol                 = "tcp"
    security_groups          = [aws_security_group.albsg.id]
  }

  
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "backendsg"
  }
}




resource "aws_vpc_security_group_ingress_rule" "rule1" {
  security_group_id = aws_security_group.frontendsg.id
  ip_protocol = "tcp"
  from_port = 0
  to_port = 65535
  cidr_ipv4 = "0.0.0.0/0"
  

}

resource "aws_vpc_security_group_ingress_rule" "rule3" {
  security_group_id = aws_security_group.backendsg.id
  ip_protocol = "tcp"
  from_port = 22
  to_port = 22
  cidr_ipv4 = "0.0.0.0/0"
  

}

resource "aws_vpc_security_group_egress_rule" "rule2" {
  security_group_id = aws_security_group.frontendsg.id
  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0"
  

}






#RDS

resource "aws_security_group" "rds_sg" {
vpc_id = module.threetier.vpc_id

ingress {
from_port = 5432
to_port = 5432
protocol = "tcp"
cidr_blocks = [module.private_subnet1.pub_cidr]
}

egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
}

resource "aws_db_subnet_group" "rds_subnet_group" {
name = "rds-subnet-group"
subnet_ids = [module.private_subnet2.subnet_id,module.private_subnet1.subnet_id]
}



resource "aws_db_instance" "rds" {
  
  allocated_storage    = 20
  db_name              = "mydb"
  engine               = "postgres"
  instance_class       = "db.t3.micro"
  username             = "postgres"
  password             = "Terraform5830"
  skip_final_snapshot  = true
  publicly_accessible  = false
  storage_type         = "gp2"
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  

}


#ALB


resource "aws_security_group" "albsg" {
  name        = "albsg"
  vpc_id      = module.threetier.vpc_id
  
  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "albsg"
  }
}


resource "aws_alb" "alb" {
  name = "3-tier"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.albsg.id]
  subnets            = [module.public_subnet1.subnet_id,module.public_subnet2.subnet_id]
  

}


resource "aws_lb_target_group" "frontend" {
  name     = "frontend"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.threetier.vpc_id
  target_type = "instance"
  health_check {
    path = "/"
}
}

resource "aws_lb_target_group" "backend" {
  name     = "backend"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = module.threetier.vpc_id
  target_type = "instance"
  health_check {
    path = "/api"
}
}



resource "aws_lb_listener" "example_listener" {
  load_balancer_arn = aws_alb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
  
}




resource "aws_lb_target_group_attachment" "frontend_attach" {
  target_group_arn = aws_lb_target_group.frontend.arn
  target_id        = module.frontend.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "backend_attach" {
  target_group_arn = aws_lb_target_group.backend.arn
  target_id        = module.backend1.id
  port             = 5000
}


resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_alb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
  
}


resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api*", "/api/*"]
    }
  }
}







