.. _aula2:

.. toctree::

*********************************************
Aula 2: Docker: Funcionamento e Gerenciamento
*********************************************

Rede
----

Historicamente, o Docker possui três redes previamente configuradas que podem ser utilizadas por futuros contêineres:

 * "docker0": Rede bridge padrão configurada para utilizar a subrede 172.17.0.0/16;
 * "none": Para casos em que se deseja que um contêiner não possua suporte a Rede (os contêineres ainda terão o suporte a interface de loopback);
 * "host": Espelha as mesmas conexões presentes no host para o contêiner.
 
Durante a criação de um contêiner este é automaticamente atrelado a interface "docker0": uma regra de NAT é criada no firewall do host e o contêiner recebe um IP randômico dentro da faixa 172.17.0.0/16 e quaisquer portas expostas (diretiva "EXPOSE" no Dockerfile) são acessíveis na forma IP:PORTA.

.. note::

    Os Endereços IP recebidos por um contêiner não possuem nenhuma garantia de continuidade; em verdade, os IP's são atribuídos na ordem em que os contêineres são iniciados, começando por 172.17.0.2, sendo que o endereço 172.17.0.1 é o gateway de acesso para a interface 'docker0'.

.. warning::

    É importante frisar que todos os contêineres que forem colocados sob a interface "docker0" terão plena conectividade entre si, mas não haverá suporte a resolução de nomes: apenas através de um **link** entre os contêineres ou em uma nova rede criada esse suporte estará disponível.

Para se descobrir o Ip de um contêiner pode-se utilizar as seguintes formas:

.. code-block:: bash

    # docker inspect --format=" {{ .NetworkSettings }} " <CONTAINER>
    # docker exec -it <CONTAINER> ip a

Na primeira forma, utiliza-se o parâmetro inspect para retornar todos os metadados do contêiner enquanto que no segundo caso envia-se um comando em modo interativo para o contêiner "ip a", que irá retornar o endereço do contêiner.

Para o caso em que dois ou mais contêineres que dependem entre si e estão conectados a rede 'docker0' (e também considerando a volatilidade da recepção dos endereços IP dos contêineres) é necessário fazer o uso de links entre os contêineres de forma que estes passem a referenciar um nome específico (mas que não precisa ser um FQDN); dessa forma, cada contêiner passa a 'conhecer' o endereçamento do outro contêiner, informação essa que pode ser usada em uma aplicação na forma "CONTAINER:NOME". Exemplo:

.. code-block:: bash

    # docker run -d --name postgres-principal postgres
    # docker run -d --name app --link postgres-principal:db httpd
    
No caso acima, o contêiner "app" reconhece o nome "db" e consegue resolver esse nome para o IP do contêiner "postgres-principal", mesmo que a ordem de inicialização e subsequentemente os IP's mudem.


.. warning::
    
    Fazer um link entre dois contêineres não impede que o primeiro contêiner seja parado ou reiniciado; em verdade, caso o primeiro contêiner seja reiniciado o segundo também precisará ser para que o endereço do primeiro seja 'atualizado' para o segundo.

Para os casos em que um determinado contêiner precisa ser acessível a outros computadores em uma rede pode-se utilizar o espelhamento de portas entre o contêiner e o host. Exemplo:

.. code-block:: bash

    # docker run -d --name postgres-default -p 5432:5432 postgres-default
    
No caso acima, espelhar-se-á a porta 5432 do host atual para a porta 5432 do contêiner; pode-se ainda realizar o espelhamento de forma dinâmica, através do parâmetro -P (maiúsculo):

.. code-block:: bash

    # docker run -d --name postgres-default -P postgres

Os mapeamentos entre portas podem ser visualizados através do comando de listagem de contêineres ativos:

.. code-block:: bash

    # docker ps -a

.. note::    

    No caso do espelhamento dinâmico de portas, as portas começam a ser alocadas a partir da 32768 e seguem conforme a ordem de inicialização dos contêineres.


Definição de redes pelo usuário
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Ao contrário da rede legada 'docker0', as redes criadas por um usuário possuem um número maior de recursos disponíveis; os principais são o suporte a resolução de nomes e a possibilidade de definir uma rede com range específico que poderá ser adicionada na criação e durante o funcionamento dos contêineres. Para tanto, utilize o seguinte comando:

.. code-block:: bash

    # docker network create --driver bridge --subnet 172.100.0.0/16 user_network
    
Após a criação da rede, é possível visualizar as informações gerais de quais redes estão definidas através do seguinte comando:

.. code-block:: bash

    # docker network ls

E informações específicas sobre a rede criada através do seguinte comando:

.. code-block:: bash

    # docker network inspect user_network
    
A partir desse ponto, a criação de contêineres passa a receber o parâmetro "--network" conforme o exemplo abaixo:

.. code-block:: bash

    # docker run -d --name db --network=user_network postgres
    # docker run -d --name app --network=user_network myapp
    
Para testar a resolução de nomes utilize o seguinte comando:

.. code-block:: bash

    # docker exec -it app ping db

Para adicionar a rede a um contêiner em funcionamento, utilize o seguinte comando:

.. code-block:: bash

    # docker network connect <NETWORK> <CONTAINER>
    
Analogamente é possível desconectar uma interface de um contêiner em funcionamento:

.. code-block:: bash

    # docker network disconnect <NETWORK> <CONTAINER>

    Por fim, para remover uma rede utilize o seguinte comando:
    
.. code-block:: bash

    # docker network rm <NETWORK>
    
.. note::

    Antes de se realizar a remoção de uma rede é necessário desconectar a interface dos contêineres conectados a mesma.

Log-Drivers
===========

A partir do momento em que uma aplicação é encapsulada em forma de um contêiner espera-se que seus logs estejam disponíveis na saída padrão (/dev/stdout), pois o próprio docker inclui os recursos necessários para a guarda e leitura dos logs através de **drivers/plugins**; assim, uma série de **backends** são suportados, sendo os principais:

 * Json-File: padrão, envia todos os logs para um arquivo Json no sistema de arquivos do host;
 * Syslog: envia todas as mensagens para um servidor SysLog;
 * GELF: formato de dados compatível com o GrayLog 2;
 * FluentD: formato de dados compatível com o FluentD.
 
A configuração de *log forwarding* pode ser definida em dois níveis: contêiner e do próprio Docker (o que inclui todos os contêineres que foram criados como padrão).

Json-File
^^^^^^^^^

"Json-File" é o driver de loggin padrão do Docker, onde um arquivo json passa a receber toda a saída advinda do contêiner. Inicialmente, para visualizar os logs de um contêiner utiliza-se o seguinte comando:

.. code-block:: bash

    # docker logs <CONTAINER>
    # docker logs -f <CONTAINER>
    
Em sua configuração padrão, este driver simplesmente recolhe e mantém toda a informação disponível no arquivo de log; para evitar o crescimento desenfreado de logs é recomendável adicionar o parâmetro "--log-opt max-size" ao serviço:

.. code-block:: bash

    # systemctl edit --full docker

Na linha que se inicia com "ExecStart" adicione os seguintes parâmetros:

``
    --log-driver=json-file --log-opt max-size=100m``
``

.. warning::

    Arquivos que chegarem ao limite especificado de tamanho do log terão suas informações sobrescritas.


FluentD
^^^^^^^

O fluentD é um coletor de dados capaz de receber dados de diferentes níveis de infraestrutura e repassá-los a soluções específicas como o Apache Lucene/Elastic Search.

Para iniciar um novo contêiner com o fluentD, utilize o comando abaixo:

.. code-block:: bash

    # docker run -d -p 24224:24224 --name fluentd-server --restart=always -v /data:/fluentd/log fluent/fluentd


Após o download e inicialização do fluentD, atualize a configuração do docker adicionando as seguintes diretivas:

.. code-block:: bash

    # systemctl edit --full docker

Na linha que se inicia com "ExecStart" adicione os seguintes parâmetros:

``
    --log-driver=fluentd --log-opt fluentd-address=localhost:24224 --log-opt tag="docker.{{.Name}}"
``


Para visualizar a recepção dos logs, podemos utilizar o seguinte comando:

.. code-block:: bash

    # ls -la /data/docker*
    # tail -f /data/docker<ID>.log

Onde o nome do arquivo a ser visualizado é gerado automaticamente quando da primeira recepção dos logs.

Abaixo um exemplo relativamente comum de funcionamento do fluentD e elastisearch em uma infraestrutura:

 .. image:: ../data/fluentd-elasticsearch-kibana.png


.. note::

    Informações acerca do FluentD podem ser obtidas na página do projeto: http://docs.fluentd.org/articles/quickstart


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
