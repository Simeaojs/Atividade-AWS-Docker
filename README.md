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
   
    Para facilitar, é altamente recomendável utilizar o VS Code. [Você pode baixá-lo](https://code.visualstudio.com/download)
   
    Além disso, para referências detalhadas, consulte a documentação oficial do Terraform  [clicando aqui](https://registry.terraform.io/providers/hashicorp/aws/latest/docs). Esta documentação é uma fonte valiosa de informações sobre os recursos, atributos e possibilidades 
    disponíveis ao utilizar o Terraform em conjunto com os serviços da AWS.
   
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
_ _ _ 
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
_ _ _ 
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
_ _ _ 

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
- Este código Terraform realiza a associação das sub-redes às tabelas de rota pública e privada na infraestrutura da AWS. Essa associação é crucial para o correto direcionamento do tráfego dentro da VPC. As sub-redes públicas são direcionadas para a tabela de rota pública, enquanto as sub-redes privadas são associadas à tabela de rota privada. Isso permite que o tráfego seja roteado adequadamente entre as sub-redes e garante o funcionamento correto das instâncias e serviços na VPC, mantendo a segregação entre as redes públicas e privadas conforme necessário para a segurança e o desempenho da infraestrutura.
_ _ _ 
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
Este grupo de segurança (`sg_alb`) é utilizado para configurar as regras de acesso ao balanceador de carga (ALB - Application Load Balancer) na AWS. Ele permite o tráfego de entrada na porta 80 (HTTP) de qualquer lugar (`0.0.0.0/0`), o que significa que qualquer endereço IP pode acessar o ALB através do protocolo TCP na porta 80 para acessar aplicativos web hospedados no ALB. Além disso, ele permite o tráfego de saída para qualquer destino e porta, pois a regra de egresso permite todo o tráfego (`0.0.0.0/0`) com qualquer protocolo (`-1`). 

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

 ## Parte 2: Configurando o EFS, EC2 Bastion Host, Launch Template, Load Balancer, Auto Scaling

###  Configurando o EFS:

```hcl
# Criação do Sistema de Arquivos EFS

resource "aws_efs_file_system" "efs" {                        
  creation_token = "efs-project-docker"                           # Token de criação para garantir unicidade do sistema de arquivos
  encrypted = true                                                # Define se o sistema de arquivos deve ser criptografado

  tags = {
    Name = "efs-project-docker"                                   # Tags para identificação do sistema de arquivos
  }
}

# Criação dos Pontos de Montagem EFS

resource "aws_efs_mount_target" "efs-mt-a" {
  file_system_id = aws_efs_file_system.efs.id                     # ID do sistema de arquivos EFS ao qual este ponto de montagem está associado
  subnet_id = aws_subnet.subnet-private-a.id                      # ID da sub-rede onde o ponto de montagem será criado
  security_groups = [aws_security_group.private_ssh_sg.id]        # Grupo de segurança que controla o acesso ao ponto de montagem
}

resource "aws_efs_mount_target" "efs-mt-b" {
  file_system_id = aws_efs_file_system.efs.id                    # ID do sistema de arquivos EFS ao qual este ponto de montagem está associado
  subnet_id = aws_subnet.subnet-private-b.id                     # ID da sub-rede onde o ponto de montagem será criado
  security_groups = [aws_security_group.private_ssh_sg.id]       # Grupo de segurança que controla o acesso ao ponto de montagem
}
```
- Elastic File System (EFS) criado: Este código utiliza o Terraform para criar um sistema de arquivos EFS criptografado na AWS, nomeado "efs-project-docker". Ele também configura dois pontos de montagem em diferentes sub-redes, todos associados ao mesmo grupo de segurança. Essa infraestrutura facilita o compartilhamento de arquivos entre instâncias EC2 em um ambiente distribuído na nuvem da AWS.

___ 

### EC2 Bastion Host:

```hcl
# Resource para criar uma instância EC2 (bastion host)
resource "aws_instance" "bastion" {
  ami                         = var.ami_id              # ID da AMI (Amazon Machine Image) para a instância
  instance_type               = "t3.micro"              # Tipo de instância EC2
  security_groups             = [aws_security_group.bastion_sg.id]  # Grupo de segurança para a instância
  subnet_id                   = aws_subnet.subnet-public-a.id     # ID da sub-rede pública onde a instância será lançada
  key_name                    = var.keyname             # Nome da chave SSH para acesso à instância
  associate_public_ip_address = true                    # Associar endereço IP público à instância
  tags = {
    Name       = "bastion"                              # Nome da instância
    
  }

  volume_tags = {
    Name       = "bastion"                              # Nome do volume associado à instância
     
  }
}

```
- Este código cria uma instância EC2 do tipo `t3.micro` usando a AMI especificada por `var.ami_id`. A instância será lançada na sub-rede pública especificada por `aws_subnet.subnet-public-a.id`, e seu acesso será controlado pelo grupo de segurança `aws_security_group.bastion_sg.id`. A instância será associada a um endereço IP público, permitindo acesso externo.
- As tags são utilizadas para identificar e categorizar a instância e o volume associado a ela com informações como nome, ou o que você precisar para seu projeto.
- Certifique-se de substituir `var.ami_id` e `var.keyname` com os valores corretos de acordo com o seu ambiente.

___ 

### Load Balancer:

```hcl
# Create ALB
resource "aws_lb" "alb-tf" {
  name                             = "alb-project-docker"
  internal                         = false
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.sg_alb.id]
  enable_cross_zone_load_balancing = true
  subnets                          = [aws_subnet.subnet-public-a.id, aws_subnet.subnet-public-b.id]

  tags = {
    name = "alb-project-docker"
  }
}

# Create Target group
resource "aws_lb_target_group" "target_group" {
  name        = "target-group-project-docker"
  depends_on  = [aws_vpc.vpc]
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "instance"

  health_check {
    interval            = 70
    path                = "/"
    port                = 80
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 60
    protocol            = "HTTP"
    matcher             = "200,202"
  }
}

# Create ALB Listener
resource "aws_lb_listener" "alb-listener" {
  load_balancer_arn = aws_lb.alb-tf.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

output "elb_dns" {
  value = aws_lb.alb-tf.dns_name
}


```
- Este código cria um Application Load Balancer (ALB) na AWS com o nome "alb-project-docker". O ALB é configurado para ser externo (`internal = false`), utilizando o tipo "application", habilitando o balanceamento de carga entre zonas (enable_cross_zone_load_balancing = true) e associando-se a um grupo de segurança específico (`security_groups`).

- Além disso, o código define um listener para encaminhar o tráfego HTTP na porta 80 para um Target Group específico (`aws_lb_target_group.target_group.arn`). O Target Group tem a configuração para verificação de saúde, intervalo de verificação, caminho de verificação, limiares saudáveis e não saudáveis, tempo limite, protocolo de verificação e matcher definidos. Isso garante o funcionamento adequado do ALB ao direcionar o tráfego para as instâncias EC2 associadas ao Target Group.

- Também cria uma saída chamada "elb_dns" que contém o DNS name do Application Load Balancer (ALB). Essa saída pode ser utilizada para obter o endereço do ALB após a execução do Terraform, por exemplo, para acessar a aplicação hospedada no ALB.

_ _ _ 

### Launch Template:

```hcl
# Criação do Launch Template
resource "aws_launch_template" "wp-launch-template" {
  name          = "wp-launch-template"                                    # Nome do Launch Template
  image_id      = var.ami_id                                              # ID da AMI a ser usada para as instâncias
  instance_type = "t3.small"                                              # Tipo de instância (tamanho)
  key_name      = var.keyname                                             # Nome da chave SSH para acesso às instâncias

  # Configuração da interface de rede das instâncias
  network_interfaces {
    associate_public_ip_address = false                                   # Desabilita IP público para instâncias
    security_groups             = [aws_security_group.private_ssh_sg.id]  # Grupo de segurança para instâncias
  }

  # Tags para as instâncias e volumes associados
  tag_specifications {
    resource_type = "instance"                                            # Tipo de recurso (instância)
    tags = {
      Name       = "wp-launch-template"                                   # Tag de nome para instâncias
      CostCenter = " "                                                    # Tag de centro de custo
      project    = " "                                                    # Tag de projeto
    }
  }

  tag_specifications {
    resource_type = "volume"                                              # Tipo de recurso (volume)
    tags = {
      Name       = "wp-launch-template"                                   # Tag de nome para volumes
      CostCenter = " "                                                    # Tag de centro de custo
      project    = " "                                                    # Tag de projeto
    }
  }

  # Script de inicialização das instâncias (UserData)
 user_data = base64encode(<<EOF
#!/bin/bash

yum update -y                                                             # Atualiza pacotes do sistema
yum install docker -y                                                     # Instala o Docker
systemctl start docker                                                    # Inicia o serviço do Docker
systemctl enable docker                                                   # Habilita o Docker para iniciar na inicialização
usermod -a -G docker ec2-user                                             # Adiciona o usuário ec2-user ao grupo docker

sudo yum install -y amazon-efs-utils                                      # Instala utilitários EFS da AWS
mkdir -p /mnt/nfs/wordpress                                               # Cria diretório para montagem do EFS
echo "\${aws_efs_file_system.efs.dns_name}:/ /mnt/nfs/wordpress nfs defaults,_netdev 0 0" >> /etc/fstab   # Configura montagem automática do EFS
mount -a                                                                  # Monta o sistema de arquivos

curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose  # Baixa e instala Docker Compose
chmod +x /usr/local/bin/docker-compose                                    # Torna o Docker Compose executável

cat <<EOL > /home/ec2-user/docker-compose.yml # Cria arquivo de configuração do Docker Compose
version: '3.8'
services:
  wp-web:
    image: wordpress:latest                                               # Imagem do WordPress
    restart: always                                                       # Reiniciar sempre
    ports:
      - 80:80                                                             # Mapeamento de portas (host:container)
    environment: 
      TZ: America/Sao_Paulo                                               # Configuração de fuso horário
      WORDPRESS_DB_HOST: ${aws_db_instance.rds_instance.endpoint}         # Endpoint do banco de dados RDS
      WORDPRESS_DB_USER: admin                                            # Usuário do banco de dados
      WORDPRESS_DB_PASSWORD: *********                                    # Senha do banco de dados
      WORDPRESS_DB_NAME: wordpress                                        # Nome do banco de dados WordPress
    volumes:
      - /mnt/nfs/wordpress:/var/www/html                                  # Mapeamento de volume para armazenamento persistente
EOL

docker-compose -f /home/ec2-user/docker-compose.yml up -d                 # Inicia o serviço do Docker Compose
EOF
)

}


```
- O código cria um Launch Template na AWS com o nome "wp-launch-template". Esse Launch Template é uma especificação para lançar instâncias EC2 com configurações predefinidas, incluindo a imagem da AMI a ser usada, o tipo de instância, a chave SSH para acesso, configurações de rede, tags e um script de inicialização (UserData).

- Em resumo, o Launch Template criado por este código é uma especificação para lançar instâncias EC2 com um ambiente configurado para executar um serviço WordPress usando Docker Compose, montar automaticamente um sistema de arquivos EFS e garantir a integração com um banco de dados RDS.

_ _ _ 

### Auto Scaling: 

```hcl
# Configuração do Grupo de Auto Scaling
resource "aws_autoscaling_group" "asg" {
  name                      = "project-docker"                                 # Nome do Grupo de Auto Scaling
  desired_capacity          = 2                                                # Capacidade desejada de instâncias
  max_size                  = 4                                                # Número máximo de instâncias
  min_size                  = 2                                                # Número mínimo de instâncias
  force_delete              = true                                             # Exclui instâncias sem notificações
  depends_on                = [aws_lb.alb-tf]                                  # Dependência do Load Balancer
  target_group_arns         = [aws_lb_target_group.target_group.arn]           # ARN do Target Group
  health_check_grace_period = 300                                              # Período de espera após início da instância
  health_check_type         = "EC2"                                            # Tipo de verificação de saúde
  launch_configuration      = aws_launch_configuration.wp-launch-config.name   # Configuração de lançamento
  vpc_zone_identifier       = [aws_subnet.subnet-private-a.id, aws_subnet.subnet-private-b.id]  # Identificador da zona da VPC

  tag {
    key                 = "Name"                                               # Chave da tag
    value               = "project-docker"                                     # Valor da tag
    propagate_at_launch = true                                                 # Propagação da tag ao lançar
  }
}

# Política de Dimensionamento de Rastreamento de Alvo
resource "aws_autoscaling_policy" "asg_cpu_policy" {
  name                   = "asg_cpu_policy"                                     # Nome da política de dimensionamento
  autoscaling_group_name = aws_autoscaling_group.asg.name                       # Nome do Grupo de Auto Scaling
  adjustment_type        = "ChangeInCapacity"                                   # Tipo de ajuste (mudança na capacidade)
  policy_type            = "TargetTrackingScaling"                              # Tipo de política de dimensionamento

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"                        # Tipo de métrica pré-definida (Utilização de CPU média do ASG)
    }
    target_value = 70.0                                                          # Valor alvo (70% de utilização de CPU)
  }
}
```
- Este código configura um Grupo de Auto Scaling (ASG) para gerenciar instâncias EC2, e uma política de dimensionamento automático com base na utilização média da CPU. Ele garante que as instâncias EC2 sejam gerenciadas de forma automática, escalando de acordo com a demanda e mantendo a saúde do sistema.

_ _ _ 

### Conclusão da Segunda parte

Após a conclusão de toda a configuração da segunda parte, estamos prontos para provisionar o restante da infraestrutura.

- Repita os passos realizados na [primeira parte](https://github.com/Simeaojs/Atividade-AWS-Docker#conclus%C3%A3o-da-primeira-parte)
 para inicializar o repositório Terraform, formatar o código, planejar e aplicar as configurações.

Isso garantirá que a infraestrutura esteja totalmente configurada e pronta para ser utilizada conforme planejado.

_ _ _ 

## 🌱Contribuição

Contribuições são bem-vindas! Se você identificar problemas ou melhorias, sinta-se à vontade para abrir um pull request.



















     









   
   


   

