.. _aula2:

.. toctree::

*****************************************************
Aula 2: Docker: Persistência de Dados e Configurações
*****************************************************

Sistema de Arquivos dos Contêiners 
----------------------------------

Os sistemas de arquivos utilizados pelos contêiners são, comumente, reflexos do sistema de arquivos do host organizado por uma tecnologia de **UnionFS** e que suporta o conceito de **COW - Copy On Write**, organizando o sistema de arquivos em várias camadas com diferentes versões de arquivos e se apresentando de forma consolidada ao contêiner. 

No caso das imagens, cada diretiva utilizada no momento de sua construção resulta em uma camada adicional no sistema de arquivos; isso permite que diferentes imagens que reutilizem os dados de diretiva em comum além de**compartilhar as camadas existentes e evitar o uso adicional/intensivo de disco**, conforme ilustrado na imagem abaixo:

.. image:: ../data/container-layers.jpg

Assim, as camadas relativas à imagem permanecem inalteradas ao passo que o uma camada relativa a um contêiner são plenamente alteráveis; no entanto, o conjunto excessivo de operações de escrita na camada relativa a um contêiner devem ser evitadas pois incorrem em diferentes níveis de perda de *throughput* a depender do *storage driver* utilizado. Maiores Inofrmações no capítulo "Storage Drivers" da Aula 4.

.. warning::

    Todos os arquivos editados e/ou salvos no sistema de arquivos de um contêiner são removidos (perdidos) quando da remoção do mesmo.

Volumes
-------

Ao contrário do sistema de arquivos do contêiner, que são removidos quando da exclusão do mesmo, os **volumes** são áreas de dados **persistentes**, normalmente diretórios do sistema de arquivos do *host* ou de um *storage* disponibilizados  para um contêiner algo análogo a montagem de volumes que ocorre nos sistemas operacionais Posix. Ao contrário dos sistemas de arquivos dos contêineres, volumes **não sofrem** *overheads* de escrita e também não são perdidos (a menos que se utilize o parâmetro -v na remoção do contêiner) com a exclusão/criação de contêineres.

Para realizar a montagem de um volume que se reflita em uma pasta do sistemas de arquivo local em um contêiner, pode-se utilizar o parâmetro "-v /diretorio:/pontodemontagem", como no exemplo abaixo:

.. code-block:: bash

    # docker run -d -v /data:/tmp/data httpd

No exemplo acima a pasta "/diretorio" será *montada* dentro do endereço "/pontodemontagem" do contêiner.

.. note::
    
    Caso a pasta a ser montada no contêiner não existe a mesma será criada no sistemas de arquivos. 
    

Adicionalmente também é possível realizar a montagem em modo somente-leitura adicionando a diretiva ":ro" ao final da declaração:

.. code-block:: bash

    # docker run -d -v /data:/tmp/data:ro httpd
    
Para os casos em que um mesmo volume precisa ser reutilizado, pode-se criar um contêiner de dados, para então reutilizá-lo nos demais contêineres:

.. code-block:: bash

    # docker run -d --name data-container -v /data:/tmp/data ubuntu bash
    # docker run -d --name app1 --volumes-from data-container myapp-image
    # docker run -d --name app2 --volumes-from data-container myapp-image

.. note::
    
    Note que o contêiner de dados não precisará estar iniciado para que as configurações de montagem sejam reaproveitadas pelos demais contêineres. 
    
.. note::

    Uma possível exclusão do contêiner de dados não causa impactos a contêineres já criados que tenham feito a utilização das configurações do volume; no entanto, novos contêineres não poderão
    fazer a importação da configuração de volume a partir do mesmo uma vez que este foi excluído.
    
Há ainda diversos plugins que permitem usar diferentes sistemas de arquivos que não o local como volumes. Mais informações no capítulo "Escalabilidade & Monitoramento: Storage Plugins".
    
Named Volumes
^^^^^^^^^^^^^

Além da montagem de volumes do sistema de arquivos para um contêiner, é possível ainda fazer a criação e montagem de um *named volume*, que é um volume inicializado durante a criação do contêiner e gerenciado pelo próprio Docker.

Um *named volume* é normalmente utilizado nas seguintes situações:

 1. Quando da utilização de plugins do docker para suporte a volumes (NetApp, Convoy, etc);
 2. Padronização dos volumes no ambiente.
 
A criação de um *named volume* normalmente ocorre através do seguinte comando:

.. code-block:: bash
    
    # docker volume create --driver local --name volume1

Após a criação de um volume, a lista com todos os volumes pode ser visualizada através do seguinte comando:

.. code-block:: bash

    # docker volume ls

A utilização do volume por um contêiner possui sintaxe parecida com a montagem de volumes do sistema de arquivos, conforme pode ser visualizado abaixo:

.. code-block:: bash

    # docker run -d postgres-default -v volume1:/var/lib/postgresql/data

A remoção de um *named volume* pode ser realizada através do seguinte comando:

.. code-block:: bash

    # docker volume rm volume1
    
.. note::

    A remoção de um volume só poderá se dar quando da não utilização do mesmo por um contêiner.

    
Docker Compose
==============

O *Docker Compose* é uma ferramenta para definição e inicialização de arquiteturas multi-container do docker. Com o compose, o administrador/desenvolvedor descreve a arquitetura e
configuração de cada um dos contêineres e a relação entre eles em um arquivo do tipo "YAML" chamado **docker-compose.yml**.

Antes de iniciar a utilização do docker-compose, é necessário realizar a instalação através dos seguintes comandos:

.. code-block:: bash

    # curl -L "https://github.com/docker/compose/releases/download/1.11.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    # chmod +x /usr/local/bin/docker-compose

A seguir, realizamos a criação de uma aplicação simples com o framework *Flask*, em um arquivo chamado "app.py" contendo as seguintes diretivas:

.. literalinclude:: ../data/flask-app.py

Na continuação, criamos o Dockerfile relacionado a essa nova aplicação:

.. literalinclude:: ../data/dockerfile-flask

Após a instalação do mesmo, é necessário criar o arquivo **docker-compose.yml** que conterá todas as instruções necessárias para levantamento dos contêineres. 

Perceba que o arquivo se inicia com a definição da versão do docker-compose; neste caso 2, pois pode incluir apenas os recursos necessários para funcionamento dos serviços/contêineres em modo *standalone*, ou seja, não se aplica aos recursos específicos de cluster do docker.

Um exemplo de declaração válido está disponível abaixo:

.. literalinclude:: ../data/docker-compose-django.yml

.. warning::

    Arquivos dos tipo YAML se baseam na **indentação** dos itens para leitura das definições de arquivos. Assim sendo, recomenda-se a utilização de espaços para indentação ao invés de tabulações.
    
    
O arquivo anteriormente disponibilizado representa de forma simples, a seguinte relação:

.. image:: ../data/simple_app.png

Após a criação do arquivo docker-compose.yml, basta iniciar o conjunto de contêineres com o seguinte comando:

.. code-block:: bash

    # docker-compose up -d

Perceba que o docker-compose utiliza automaticamente o nome da pasta "recipiente" para a geração dos nomes dos contêineres; assim, o contêiner relativo ao serviço "db" passaria a ser "django_db_1" caso o nome da pasta fosse "django" e o contêiner da aplicação se chamaria "django_web_1". O número após o nome do contêiner permite ao compose controlar a quantidade de contêineres a serem criados para o "serviço" (o que dá o suporte ao escalonamento).

Com os contêineres foram criados através do compose, é também possível gerenciá-los com um comando:

.. code-block:: bash

    # docker-compose stop
    # docker-compose start
    # docker-compose restart
    # docker-compose stop && docker-compose rm
    # docker-compose logs

Para realizar o "escalonamento" dos serviços, pode-se utilizar o comando "docker-compose scale" seguido do nome do serviço e número de "réplicas":

.. code-block:: bash

    # docker-compose scale web=3

Assim, após a execução do comando supracitado, seriam criados os contêineres "django_web_2" e "django_web_3".
    
.. note:: 

    Diferentemente dos recursos de cluster, o docker-compose scale apenas cria novos contêineres para os serviços definidos dentro do arquivo docker-compose.yml, sendo o escopo do docker-compose local, ou seja, a criação de contêineres sempre ocorre apenas no host atual. 
    
Definição de Redes, Volumes e uso de recursos já existentes
-----------------------------------------------------------

Além da definição de contêineres de forma propriamente dita, outros recursos como redes e volumes também podem ser definidos através de um arquivo do docker-compose. O exemplo abaixo contém exemplos de definição de redes e volumes:

.. literalinclude:: ../data/docker-compose.netvol.yml

No exemplo acima, temos um *named volume* chamado "data" e uma rede chamada "databases" que considerando a pasta recipiente "zabbix" resultará na criação da rede "zabbix_databases" e do volume "zabbix_data" respectivamente.

Para o caso em que se deseja utilizar recursos previamente existentes, desde contêineres a redes pode-se utilizar a diretiva "external: true" conforme exemplo abaixo:

``
  networks:
    management:
      external: true
``

A utilização de recursos de ambos os tipos (gerenciados e não gerenciados pelo compose) pode ser descrita da seguinte maneira:

``
    networks:
      management:
        external: true
      default:
        external: false
``


Docker Compose: Composição de configurações
-------------------------------------------

Por fim, o docker-compose suporte a composição de configurações ou *overrides*, de modo que um arquivo docker-compose.yml pode servir de base para a configuração de um seriço e demais arquivos podem conter as especificidades a serem implementadas; em verdade, esse tipo é configuração é comum para casos em que se possui múltiplos ambientes, tais como desenvolvimento, homologação e produção.

Os requisitos para a composição de configurações através dos arquivos do docker-compose são:

 * O arquivo de override ou definido pelo usuário precisa iniciar com o mesmo *version* do arquivo docker-compose.yml;
 * Os serviços a serem configurados precisam ser aqueles já definidos no arquivo docker-compose.yml.

Por padrão, todas as configurações presentes em um arquivo "docker-compose.override.yml" são automaticamente lidos e aplicados pelo docker-compose no momento de sua execução; é possível ainda definir arquivos com nomes específicos que poderão ser analisados e aplicados pelo docker-compose.

O exemplo abaixo denota dois arquivos: o docker-compose.yml padrão e o docker-compose.override.yml:

.. literalinclude:: ../data/docker-compose-django.yml

.. literalinclude:: ../data/docker-compose-django.override.yml

No exemplo acima, no momento da execução do comando "docker-compose up -d", seria criado um volume chamado "django_pgdata" que seria utilizado como volume para guardar os dados do serviço "db", exemplificando uma possível guarda dos dados do banco de dados em um volume do storage netapp (possivelmente essa seria uma configuração de produção), além da aplicação das demais definições do arquivo docker-compose original.

A utilização de arquivos com nomes definidos pelo usuário (usualmente congruente aos ambientes de execução dos serviços) é plenamente suportada, bastando para tanto especificar a *flag* -f no momento de execução do docker-compose:

.. code-block:: bash

    # docker-compose up -f docker-compose.devel.yml -d
    # docker-compose up -f docker-compose.homolog.yml -d
    # docker-compose up -f docker-compose.prod.yml -d

Sendo que no caso acima, cada arquivo conteria as configurações adequadas ao ambiente no qual estaria sendo executado.

.. note::

    O docker-compose sempre cria uma nova rede "default" e adiciona aos contêineres definidos no arquivo docker-compose.yml.

.. note::

    Mais informações acerca das diretivas do compose disponíveis em: https://docs.docker.com/compose/
