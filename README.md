# Atividade-AWS-Docker

## Descrição 

Nesta atividade, o objetivo é realizar a instalação e configuração do Docker ou Containerd em um host EC2 na AWS, utilizando um script de inicialização (user_data.sh) para automatizar o processo e obter um ponto adicional no trabalho. Em seguida, será realizado o deploy de uma aplicação WordPress, utilizando um container para a aplicação e um banco de dados MySQL hospedado no RDS da AWS. Além disso, será configurada a utilização do serviço EFS da AWS para armazenamento de arquivos estáticos do container de aplicação WordPress. Por fim, será configurado o serviço de Load Balancer da AWS para garantir a disponibilidade e escalabilidade da aplicação WordPress.

- - - 

# Pontos de Atenção

1. **Não utilizar IP público para saída dos serviços WP**

2. **Sugestão para o tráfego de internet sair pelo Load Balancer Classic**

3. **Sugestão de utilizar o EFS (Elastic File System) para pastas públicas e estáticos do WordPress**

4. **Utilização de Dockerfile ou Docker Compose**

5. **Demonstrar a aplicação WordPress funcionando (tela de login)**

6. **Aplicação WordPress precisa estar rodando na porta 80 ou 8080**

7. **Utilizar repositório Git para versionamento**

   - - -

   # Configurando Arquitetura

   Nessa atividade, toda a configuração da arquitetura será feita utilizando o Terraform, uma ferramenta de infraestrutura como código (IaC) amplamente reconhecida e utilizada pela sua capacidade de gerenciar de forma eficiente e escalável a infraestrutura em diversos provedores de nuvem, como AWS, Azure e Google Cloud Platform. A escolha pelo Terraform se deve à sua facilidade de uso, declaração de recursos em formato de código, controle de versionamento e automação de provisionamento, o que proporciona maior agilidade, consistência e controle no gerenciamento da infraestrutura como um todo.

   ## Parte 1: Terraform 

    Primeiro instale o Terraform [a partir daqui](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

    Depois de instalar o Terraform, você pode configurá-lo para usar sua conta da AWS definindo as variáveis e ambientais em seu terminal. A CLI do Terraform detectará a presença dessas variáveis e as usará para autenticar com sua conta 
    da `AWS.AWS_ACCESS_KEY_ID` `AWS_SECRET_ACCESS_KEY`

   Agora, crie uma pasta com o nome que desejar. Vamos nomeá-lo. Dentro da pasta, crie um arquivo chamado `main.tf`.

    Para o provedor da AWS, copie e cole o código abaixo em: `main.tf`

```hcl
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.58.0"
    }
  }

  backend "s3" {
    bucket = "nome-do-seu-bucket-s3"
    key    = "web-auto/terraform.tfstate"
    region = "us-east-1"
  }
}
```

- Este trecho de código Terraform configura o ambiente para uso do provedor AWS e define o backend S3 para armazenar o estado do Terraform na AWS.

### Variáveis para AWS

```hcl
variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"

}

variable "ami_id" {
  description = "AMI ID"
  type        = string
  default     = "ami-07761f3ae34c4478d"

}

variable "keyname" {
  default = "teste"
}
```
- Este código Terraform define variáveis para configurar informações sensíveis em um ambiente AWS. A variável "region" especifica a região AWS na qual os recursos serão implantados, com um valor padrão definido como "us-east-1". A variável "ami_id" armazena o ID da AMI a ser utilizada, com um valor padrão configurado para "ami-07761f3ae34c4478d". A variável "keyname" define o nome da chave de acesso para instâncias EC2, com um valor padrão de "teste".

- 💡 NOTA: Não se esqueça de alterar o valor no bloco conforme seu uso! 

### Para criar VPC e sub-redes públicas e privadas:

```hcl
# VPC
resource "aws_vpc" "this" {
  cidr_block = "10.100.0.0/16"
  tags = {
    Name = "upgrad-vpc"
  }
}

# Sub-redes públicas
resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.100.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "upgrad-public-1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.100.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "upgrad-public-2"
  }
}

# Sub-redes privadas
resource "aws_subnet" "private1" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.100.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "upgrad-private-1"
  }
}

resource "aws_subnet" "private2" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.100.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "upgrad-private-2"
  }
}
```
- Este código Terraform define uma VPC na AWS com o CIDR `10.100.0.0/16` e cria sub-redes públicas e privadas em diferentes zonas de disponibilidade (us-east-1a e us-east-1b) dentro dessa VPC. As sub-redes são configuradas com os CIDRs especificados e têm tags para identificação.

### Configurando o Internet Gateway, Elastic IP, NAT Gateway e rotas para redes públicas e privadas:

```hcl
# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "upgrad-igw"
  }
}

# Elastic IP
resource "aws_eip" "eip" {
  domain = "vpc"
}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public1.id

  tags = {
    Name = "upgrad-nat"
  }
}

# Tabela de rota pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# Tabela de rota privada
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-rt"
  }
}
```
- Cria um Internet Gateway para a VPC.
- Aloca um Elastic IP.
- Estabelece um NAT Gateway para sub-redes públicas.
- Define tabelas de rota pública e privada para roteamento de tráfego.


### Para criar a associação da tabela de rotas e o grupo de segurança:

```hcl
# Associação de Tabela de Rota Pública 1
resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

# Associação de Tabela de Rota Pública 2
resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

# Associação de Tabela de Rota Privada 1
resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}

# Associação de Tabela de Rota Privada 2
resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
}
```
- - - 
- Este código Terraform realiza a associação das sub-redes às tabelas de rota pública e privada na infraestrutura da AWS. Essa associação é crucial para o correto direcionamento do tráfego dentro da VPC. As sub-redes públicas são direcionadas para a tabela de rota pública, enquanto as sub-redes privadas são associadas à tabela de rota privada. Isso permite que o tráfego seja roteado adequadamente entre as sub-redes e garante o funcionamento correto das instâncias e serviços na VPC, mantendo a segregação entre as redes públicas e privadas conforme necessário para a segurança e o desempenho da infraestrutura.

### Criando Banco de dados AWS RDS: 

```hcl
#rds subnet

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [SUAS-SUBNETS PRIVADAS]

}
#RDS INSTANCE

resource "aws_db_instance" "rds_instance" {
  engine                    = "mysql"
  engine_version            = "8.0.35"
  skip_final_snapshot       = true
  final_snapshot_identifier = "my-final-snapshot"
  allocated_storage         = 20
  instance_class            = "db.t3.micro"
  identifier                = "my-rds-instance"
  db_name                   = "wordpress"
  username                  = "USUARIO"
  password                  = "SENHA"
  db_subnet_group_name      = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids    = [aws_security_group.rds_sg.id]

  tags = {
    Name = "rds-project-docker"
  }

}
# RDS security group

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg-project-docker"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.110.0.0/16"]
  }

  tags = {
    Name = "rds-sg-project-docker"
  }
}
```
Este código configura uma instância RDS MySQL juntamente com um grupo de sub-redes do DB e um grupo de segurança para o RDS. Ele cria os recursos necessários para a instância RDS, incluindo a definição do motor, versão, armazenamento alocado, classe de instância, nome do banco de dados e configurações de segurança.

O Grupo de Sub-redes do DB `(aws_db_subnet_group)` associa a instância RDS às sub-redes privadas A e B. A instância RDS `(aws_db_instance)` especifica o motor MySQL, versão, armazenamento alocado, classe de instância, nome do banco de dados e outras configurações. Ela também faz referência ao grupo de sub-redes do DB e IDs do grupo de segurança.

O Grupo de Segurança do RDS `(aws_security_group)` define regras de ingresso para permitir o tráfego na porta 3306 (MySQL) apenas a partir do intervalo de blocos CIDR especificado.

_ _ _ 

### Configurando os Grupos de Segurança:
Nesta seção, vamos configurar dois grupos de segurança, um para o balanceador de carga (load balancer) e outro para o bastion host. Esses grupos de segurança serão utilizados posteriormente.

```hcl
# Grupo de Segurança para o Balanceador de Carga (ALB)

resource "aws_security_group" "sg_alb" {
  name        = "sg_alb"
  description = "Grupo de segurança para o balanceador de carga (ALB)"
  vpc_id      = aws_vpc.vpc.id

  # Regras de Entrada (Ingress)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Permite acesso HTTP de qualquer lugar"
  }

  # Regras de Saída (Egress)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_alb"
  }
}
```
Este grupo de segurança `(sg_alb)` é utilizado para configurar as regras de acesso ao balanceador de carga (ALB - Application Load Balancer) na AWS. Ele permite o tráfego de entrada na porta 80 (HTTP) de qualquer lugar `(0.0.0.0/0)`, o que significa que qualquer endereço IP pode acessar o ALB através do protocolo TCP na porta 80 para acessar aplicativos web hospedados no ALB. Além disso, ele permite o tráfego de saída para qualquer destino e porta, pois a regra de egresso permite todo o tráfego `(0.0.0.0/0)` com qualquer protocolo `(-1)`. 

```hcl
# bastion_sg

resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access from anywhere"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "bastion_sg"
  }

}
# private_ssh_sg:

resource "aws_security_group" "private_ssh_sg" {
  name        = "private_ssh_sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
    description     = "Allow SSH access from bastion host"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NFS"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "private_ssh_sg"
  }

}
```
- Regras de entrada (Ingress):
   - Permite acesso SSH (porta 22) de qualquer lugar (`0.0.0.0/0`), o que significa que qualquer endereço IP pode acessar o bastion host via SSH.
- Regra de saída (Egress):
   - Permite todo o tráfego de saída para qualquer destino e porta.
- private_ssh_sg:
- Regras de entrada (Ingress):
   - Permite acesso SSH (porta 22) apenas a partir do grupo de segurança `bastion_sg`, restringindo o acesso SSH ao bastion host.
   - Permite acesso HTTP (porta 80) de qualquer lugar (`0.0.0.0/0`).
   - Permite acesso NFS (porta 2049) de qualquer lugar (`0.0.0.0/0`).
   - Permite acesso HTTPS (porta 443) de qualquer lugar (`0.0.0.0/0`).
- Regra de saída (Egress):
   - Permite todo o tráfego de saída para qualquer destino e porta.
     
Esses grupos de segurança são utilizados para controlar o acesso ao bastion host e aos serviços que ele pode acessar dentro da VPC (Virtual Private Cloud). O `bastion_sg` permite acesso SSH de qualquer lugar, enquanto o `private_ssh_sg` restringe o acesso SSH ao bastion host apenas a partir do próprio grupo de segurança, adicionando também permissões para outros serviços como HTTP, NFS e HTTPS de qualquer lugar.

_ _ _ 

### Conclusão da Primeira parte 

Nesta etapa, concluímos a configuração inicial dos recursos necessários para nossa infraestrutura. Agora estamos prontos para realizar o provisionamento dos recursos no ambiente AWS.

A seguir, serão executados os seguintes passos para garantir a consistência e a correta configuração do código:

1. Validação do Código Terraform:
   - Antes de aplicar as alterações, é recomendável executar o comando `terraform validate` para validar a sintaxe e a estrutura do código Terraform. Isso ajuda a identificar erros ou problemas antes da aplicação das alterações.
  
2. Inicialização do Repositório Terraform:
   - Utilize o comando `terraform init` para inicializar o repositório do Terraform. Isso garantirá que todos os plugins e módulos necessários sejam baixados e configurados corretamente.

3. Formatação do Código:
   - Em seguida, execute o comando `terraform fmt` para formatar o código de acordo com as diretrizes de estilo e organização do Terraform. Isso garante a legibilidade e a consistência do código.
  
4. Planejamento da Infraestrutura:
   - Execute o comando `terraform plan` para criar um plano de execução detalhado das alterações propostas na infraestrutura. Isso permitirá revisar as alterações antes da aplicação, garantindo que tudo esteja configurado conforme o esperado.
  
5. Aplicação das Alterações:
   - Por fim, utilize o comando `terraform apply` para aplicar as alterações planejadas na infraestrutura. Este passo deve ser realizado com cuidado, pois resultará na criação, atualização ou remoção de recursos na AWS de acordo com o plano gerado.

Com esses passos, estaremos prontos para avançar para a próxima etapa do projeto e realizar o provisionamento dos recursos na AWS de forma segura e controlada.
___ 
















     









   
   


   

