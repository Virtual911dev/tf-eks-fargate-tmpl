

resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name                                                   = "${var.name}-${var.environment}-vpc"
    Environment                                            = var.environment
    "kubernetes.io/cluster/${var.name}-${var.environment}" = "shared"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.name}-${var.environment}-igw"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[1].id
  depends_on    = [aws_internet_gateway.main]

  tags = {
    Name        = "${var.name}-${var.environment}-nat-01"
    Environment = var.environment
  }
}

resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name        = "${var.name}-${var.environment}-eip-01"
    Environment = var.environment
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnets, count.index)
  availability_zone = element(var.availability_zones, count.index)
  count             = length(var.private_subnets)

  tags = {
    Name                                                   = "${var.name}-${var.environment}-private-subnet-${format("%03d", count.index+1)}",
    Environment                                            = var.environment,
    "kubernetes.io/cluster/${var.name}-${var.environment}" = "shared"
    "kubernetes.io/role/internal-elb"                      = "1"
  }
}

resource "aws_subnet" "private_db" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnets_db, count.index)
  availability_zone = element(var.availability_zones, count.index)
  count             = length(var.private_subnets_db)

  tags = {
    Name                                                   = "${var.name}-${var.environment}-private-db-subnet-${format("%03d", count.index+1)}",
    Environment                                            = var.environment
  }
}

resource "aws_route_table" "private_db" {
  count  = length(var.private_subnets_db)
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.name}-${var.environment}-routing-table-private-db-${format("%03d", count.index+1)}"
    Environment = var.environment
  }
}
/*
resource "aws_route" "private_db" {
  route_table_id         = element(aws_route_table.private_db.*.id, 0)
  gateway_id             = aws_internet_gateway.main.id
  for_each = toset(["108.7.180.236/32", "108.20.79.222/32", "73.38.182.189/32", "83.103.155.177/32"])
  destination_cidr_block           = "${each.key}"
}

resource "aws_route" "private_db-1" {
  route_table_id         = element(aws_route_table.private_db.*.id, 1)
  gateway_id             = aws_internet_gateway.main.id
  for_each = toset(["108.7.180.236/32", "108.20.79.222/32", "73.38.182.189/32", "83.103.155.177/32"])
  destination_cidr_block           = "${each.key}"
}
*/
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.public_subnets, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  count                   = length(var.public_subnets)
  map_public_ip_on_launch = true

  tags = {
    Name                                                   = "${var.name}-${var.environment}-public-subnet-${format("%03d", count.index+1)}",
    Environment                                            = var.environment,
    "kubernetes.io/cluster/${var.name}-${var.environment}" = "shared",
    "kubernetes.io/role/elb"                               = "1"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.name}-${var.environment}-routing-table-public"
    Environment = var.environment
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.name}-${var.environment}-routing-table-private-${format("%03d", count.index+1)}"
    Environment = var.environment
  }
}

resource "aws_route" "private" {
  count                  = length(compact(var.private_subnets))
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}
/*
resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc-flow-logs-role.arn
  log_destination = aws_cloudwatch_log_group.vpc.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

resource "aws_cloudwatch_log_group" "vpc" {
  name              = "/aws/vpc/${var.name}-${var.environment}/flow"
  retention_in_days = 30

  tags = {
    Name        = "${var.name}-${var.environment}-vpc-cloudwatch-log-group"
    Environment = var.environment
  }
}

resource "aws_iam_role" "vpc-flow-logs-role" {
  name = "${var.name}-${var.environment}-vpc-flow-logs-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "vpc-flow-logs-policy" {
  name = "${var.name}-${var.environment}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc-flow-logs-role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
*/
output "id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.public
}

output "private_subnets" {
  value = aws_subnet.private
}
output "private_subnets_db" {
  value = aws_subnet.private_db
}