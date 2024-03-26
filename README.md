# Atividade-AWS-Docker

## Descrição 

Nesta atividade, o objetivo é realizar a instalação e configuração do Docker ou Containerd em um host EC2 na AWS, utilizando um script de inicialização (user_data.sh) para automatizar o processo e obter um ponto adicional no trabalho. Em seguida, será realizado o deploy de uma aplicação WordPress, utilizando um container para a aplicação e um banco de dados MySQL hospedado no RDS da AWS. Além disso, será configurada a utilização do serviço EFS da AWS para armazenamento de arquivos estáticos do container de aplicação WordPress. Por fim, será configurado o serviço de Load Balancer da AWS para garantir a disponibilidade e escalabilidade da aplicação WordPress.

- - - 

# Pontos de Atenção

1. **Não utilizar IP público para saída dos serviços WP:**
   
   Evitar publicar o serviço WordPress diretamente via IP público para garantir a segurança e a organização da infraestrutura. Sugere-se utilizar o Load Balancer Classic para o tráfego de 
   internet.

3. **Sugestão para o tráfego de internet sair pelo Load Balancer Classic:**
   
   Utilizar o Load Balancer Classic da AWS como ponto de saída para o tráfego de internet, garantindo uma distribuição equitativa das requisições e melhorando a escalabilidade e disponibilidade 
   da aplicação.

4. **Sugestão de utilizar o EFS (Elastic File System) para pastas públicas e estáticos do WordPress:**
   
   O uso do EFS da AWS é recomendado para armazenar pastas públicas e arquivos estáticos do WordPress, proporcionando escalabilidade, disponibilidade e facilidade de compartilhamento entre 
   múltiplos containers.

5. **Utilização de Dockerfile ou Docker Compose:**
   
   Fica a critério de cada integrante escolher entre usar um Dockerfile ou um Docker Compose para a configuração e execução dos containers do WordPress. Ambas as opções são válidas e 
   devem ser demonstradas na entrega do trabalho.

6. **Demonstrar a aplicação WordPress funcionando (tela de login):**
   
   É necessário demonstrar que a aplicação WordPress está funcionando corretamente, incluindo a tela de login acessível e funcional.

7. **Aplicação WordPress precisa estar rodando na porta 80 ou 8080:**
    
   A aplicação WordPress deve ser configurada para rodar em uma das portas padrão, como a porta 80 ou a porta 8080, para facilitar o acesso e a integração com o Load Balancer e outros serviços.

8. **Utilizar repositório Git para versionamento:**
    
   Todos os arquivos de configuração, scripts e códigos relacionados ao projeto devem ser versionados em um repositório Git para facilitar o controle de versão, colaboração e revisão do código.

   - - -

   # Configurando Arquitetura

   Nessa atividade, toda a configuração da arquitetura será feita utilizando o Terraform, uma ferramenta de infraestrutura como código (IaC) amplamente reconhecida e utilizada pela sua capacidade de gerenciar de forma eficiente e escalável a infraestrutura em diversos provedores de nuvem, como AWS, Azure e Google Cloud Platform. A escolha pelo Terraform se deve à sua facilidade de uso, declaração de recursos em formato de código, controle de versionamento e automação de provisionamento, o que proporciona maior agilidade, consistência e controle no gerenciamento da infraestrutura como um todo.

   ## Tarefa 1: Terraform 

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

### Para criar tabelas IGW (Internet GateWay), EIP (Elastic IP), NAT Gateway (Network Address Translation gateway) e Route para públicas e privadas:

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














   
   


   

