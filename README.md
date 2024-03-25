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
   
   Fica a critério de cada integrante escolher entre usar um Dockerfile ou um Docker Compose para a configuração e execução dos containers do WordPress e do MySQL. Ambas as opções são válidas e 
   devem ser demonstradas na entrega do trabalho.

6. **Demonstrar a aplicação WordPress funcionando (tela de login):**
   
   É necessário demonstrar que a aplicação WordPress está funcionando corretamente, incluindo a tela de login acessível e funcional.

7. **Aplicação WordPress precisa estar rodando na porta 80 ou 8080:**
    
   A aplicação WordPress deve ser configurada para rodar em uma das portas padrão, como a porta 80 ou a porta 8080, para facilitar o acesso e a integração com o Load Balancer e outros serviços.

8. **Utilizar repositório Git para versionamento:**
    
   Todos os arquivos de configuração, scripts e códigos relacionados ao projeto devem ser versionados em um repositório Git para facilitar o controle de versão, colaboração e revisão do código.


