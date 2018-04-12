.. _aula3:

.. toctree::

***************************************************************
Aula 3: Repositório de Imagens, Conectividade Interna e Logging
***************************************************************


===============
Docker Registry
===============

O Docker Registry provê um serviço para hospedagem de imagens do Docker análogo ao que está disponível no hub.docker.com, porém com a possibilidade de uso e hospedagem em uma rede interna.

Para criar um novo registry, crie uma nova pasta chamada 'registry' e então insira o seguinte conteúdo no arquivo docker-compose.yml:

.. literalinclude:: ../data/docker-compose.registry.1.yml

Crie o contêiner através do comando ``docker-compose up -d``. O registry criado até esse momento utiliza a porta 5000 para comunicação, mas ainda não trabalha via TLS/HTTPS; Por padrão, o Docker não permite a comunicação sem TLS/HTTPS com um registry, a não ser que (por padrão) a url seja '127.0.0.1'.

Para verificar quais *insecure registries* são aceitos pelo daemon do docker, utilize o comando "docker info"; a informação desejada estará ao final do comando, abaixo da linha que se inicia com "Insecure Registries:".

Para registries externos, mesmo que estes utilizem um certificado auto assinado ou mesmo não suportem HTTPS, é possível configurar o Docker para aceitar *registries* adicionais. Para tanto, crie ou edite o arquivo "/etc/docker/daemon.json" inserindo as seguintes diretivas:

.. literalinclude:: ../data/daemon.1.json


E por fim reinicie o docker para aplicar as configurações:

.. code-block:: bash

    $ sudo systemctl restart docker


Uma vez que o docker está preparado, realizar o envio de uma imagem requer que **você defina tags nas imagens atuais que contenham o nome do repositório no formato registry:porta/imagem:tag** e faça o *push*, conforme o exemplo abaixo:

.. code-block:: bash

    $ docker tag ubuntu 127.0.0.1:5000/ubuntu:yak
    $ docker push 127.0.0.1:5000/ubuntu:yak

Realizar o download de imagens a partir do registry é igualmente fácil:

.. code-block:: bash

    $ docker pull 127.0.0.1:5000/ubuntu:yak

No entanto, até então, toda a comunicação com o registry vem sendo realizada através de HTTP, ou seja, sem a criptografia. Para ativar o suporte a TLS/HTTPS no acesso a aplicação, será necessário criar uma certificado, atualizar o docker-compose.yml para que fique da seguinte maneira:

.. literalinclude:: ../data/docker-compose.registry.2.yml

Antes de inicializar a nova versão do contêiner, será necessário criar um volume para receber os certificados e criá-los através dos seguintes comandos:

.. code-block:: bash

    $ docker volume create --driver local registry_certs
    $ docker run --rm -e COMMON_NAME=localhost -e KEY_NAME=domain --mount type=volume,source=registry_certs,target=/certs centurylink/openssl
    
Com os certificados já criados no volume, resta apenas inicializar a nova versão do contêiner através do comando:

.. code-block:: bash

    $ docker-compose up -d

.. note::

    Para o ambiente de produção, solicite os certificados junto a área de infraestrutura.
    

Por fim, é desejável fazer a restrição de acesso ao registry através da utilização de credenciais no estilo htpasswd/*basic auth*. Para tanto, atualize o docker-compose.yml relativo ao registry para que fique com a seguinte conteúdo:

.. literalinclude:: ../data/docker-compose.registry.3.yml

Antes de inicializar a nova versão do contêiner, será necessário criar um volume para receber o arquivo com as credenciais. Utilize os seguintes comandos para iniciá-los:

.. code-block:: bash

    $ docker volume create --driver local registry_auth
    $ docker run --entrypoint htpasswd --mount type=volume,source=auth,target=/auth registry:2 -Bbn testuser testpassword > /auth/htpasswd

Com o arquivo htpasswd já criado no volume auth, resta apenas inicializar a nova versão do contêiner através do comando:

.. code-block:: bash

    $ docker-compose up -d

Por conta da adição do suporte a credenciais, será necessário agora realizar o "login" para operar com o novo registry, que pode ser feito da seuginte maneira:

.. code-block:: bash

    $ docker login 127.0.0.1:5000

.. note::

    As informações de login são guardadas como *base64* no arquivo ~/.docker/config.json.
    
.. note::

    Mais informações acerca do registry, incluindo melhores práticas para seu uso em produção, podem ser encontradas em: https://docs.docker.com/registry/configuration/.

============================
Redes definidas por Software
============================

Historicamente, o Docker possui três redes previamente configuradas que podem ser utilizadas:

 * "docker0": Rede bridge padrão configurada para utilizar a subrede 172.17.0.0/16;
 * "none": Para casos em que se deseja que um contêiner não possua suporte a Rede (os contêineres ainda terão o suporte a interface de loopback);
 * "host": Espelha as mesmas conexões presentes no host para o contêiner.

Durante a criação de um contêiner este é automaticamente atrelado a interface "docker0" caso seja criado através do comando ``docker run`` sem configurações adicionais; para esse caso, uma regra de NAT é criada no firewall do host e o contêiner recebe um IP randômico dentro da faixa 172.17.0.0/16 e quaisquer portas expostas são acessíveis na forma IP:PORTA.

.. note::

    Os Endereços IP recebidos por um contêiner não possuem nenhuma garantia de continuidade; em verdade, os IP's são atribuídos na ordem em que os contêineres são iniciados, começando por 172.17.0.2, sendo que o endereço 172.17.0.1 é o gateway de acesso para a interface 'docker0'.


Para descobrir o Ip de um contêiner pode-se utilizar as seguintes formas:

.. code-block:: bash

    $ docker inspect --format=" {{ .NetworkSettings }} " <CONTAINER>
    $ docker exec -it <CONTAINER> ip a

Na primeira forma, utiliza-se o parâmetro inspect para retornar os metadados do contêiner enquanto que no segundo caso envia-se um comando em modo interativo para o contêiner "ip a", que irá retornar o endereço do contêiner, se esse tiver o pacote iputils instalado.

Para o caso em que dois ou mais contêineres estão conectados a rede 'docker0' (e também considerando a volatilidade da recepção dos endereços IP dos contêineres) é necessário fazer o uso de links entre os contêineres de forma que estes passem a referenciar um nome específico (mas que não precisa ser um FQDN); dessa forma, cada contêiner passa a 'conhecer' o endereçamento do outro contêiner, informação essa que pode ser usada em uma aplicação na forma "CONTAINER:NOME". Exemplo:

.. code-block:: bash

    $ docker run -d --name postgres-principal postgres
    $ docker run -d --name app --link postgres-principal:db httpd
   
No caso acima, o contêiner "app" reconhece o nome "db" e consegue resolver esse nome para o IP do contêiner "postgres-principal", mesmo que a ordem de inicialização e subsequentemente os IP's mudem.


.. warning::
    
    Fazer um link entre dois contêineres não impede que o primeiro contêiner seja parado ou reiniciado; em verdade, caso o primeiro contêiner seja reiniciado o segundo também precisará ser para que o endereço do primeiro seja 'atualizado' para o segundo.

Para os casos em que um determinado contêiner precisa ser acessível a outros computadores em uma rede pode-se utilizar o espelhamento de portas entre o contêiner e o host. Exemplo:

.. code-block:: bash

    $ docker run -d --name postgres-default -p 5432:5432 postgres:alpine
    
No caso acima, a porta 5432 do host atual será vinculada na porta 5432 do contêiner via firewall(iptables); pode-se ainda realizar o vínculo de forma dinâmica, através do parâmetro -P (maiúsculo):

.. code-block:: bash

    $ docker run -d --name postgres-default -P postgres:alpine

Os mapeamentos entre portas podem ser visualizados tanto através do comando ``docker ports`` quanto através do comando de listagem de contêineres ativos:

.. code-block:: bash

    $ docker ps -a
    $ docker ports <CONTAINER>

.. note::    

    No caso do espelhamento dinâmico de portas, as portas começam a ser alocadas a partir da 32768 e seguem conforme a ordem de inicialização dos contêineres.


Definição de redes pelo usuário
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Ao contrário da rede legada 'docker0', as redes criadas por um usuário possuem um número maior de recursos disponíveis; os principais são o suporte a resolução de nomes e a possibilidade de definir uma rede com range específico que poderá ser adicionada na criação e durante o funcionamento dos contêineres. Para tanto, utilize o seguinte comando:

.. code-block:: bash

    $ docker network create --driver bridge --subnet 172.100.0.0/16 user_network
    
Após a criação da rede, é possível visualizar as informações gerais de quais redes estão definidas através do seguinte comando:

.. code-block:: bash

    $ docker network ls

E informações específicas sobre a rede criada através do seguinte comando:

.. code-block:: bash

    $ docker network inspect user_network
    
A partir desse ponto, a criação de contêineres passa a receber o parâmetro "--network" conforme o exemplo abaixo:

.. code-block:: bash

    $ docker run -d --name db --network=user_network postgres
    $ docker run -d --name app --network=user_network myapp
    
Para testar a resolução de nomes utilize o seguinte comando:

.. code-block:: bash

    $ docker exec -it app ping db

Para adicionar a rede a um contêiner em funcionamento, utilize o seguinte comando:

.. code-block:: bash

    $ docker network connect <NETWORK> <CONTAINER>
    
Analogamente é possível desconectar uma interface de um contêiner em funcionamento:

.. code-block:: bash

    $ docker network disconnect <NETWORK> <CONTAINER>

    Por fim, para remover uma rede utilize o seguinte comando:
    
.. code-block:: bash

    $ docker network rm <NETWORK>
    
.. note::

    Antes de se realizar a remoção de uma rede é necessário desconectar a interface dos contêineres conectados a mesma.

Para o caso da utilização do docker-compose para gerenciamento dos contêineres, quando da inicialização dos contêineres, este cria uma rede automaticamente, normalmente com o padrão <PASTA>_default; da mesma forma, se nenhum contêiner estiver conectado a esta rede, remover os contêineres via ``docker-compose down`` fará com que essa rede também seja removida.

===============
Logging Drivers
===============


A partir do momento em que uma aplicação é encapsulada em forma de um contêiner espera-se que seus logs estejam disponíveis na saída padrão (/dev/stdout), pois o próprio docker inclui os recursos necessários para a guarda e leitura dos logs através de **drivers/plugins**; assim, uma série de **backends** são suportados, sendo os principais:

 * Json-File: padrão, envia todos os logs para um arquivo Json no sistema de arquivos do host;
 * Syslog: envia todas as mensagens para um servidor SysLog;
 * GELF: formato de dados compatível com o GrayLog 2;
 * FluentD: formato de dados compatível com o FluentD.
 
A configuração de *log forwarding* pode ser definida em dois níveis: contêiner e do próprio Docker (o que inclui todos os contêineres que foram criados como padrão), mas mantendo a capilaridade ao ponto de que cada contêiner pode ter seu próprio método de logging.

Para o Docker, esta configuração é feita no arquivo "/etc/docker/daemon.json" ao passo que para um contêiner ela pode ser feita no "docker run" ou via docker-compose:

.. literalinclude:: ../data/docker-compose.logging.yml

.. warning::

    A utilização do comando ``docker logs`` ou ``docker-compose logs`` somente é possível quando da utilização dos logging drivers "json-file" ou "journald". Para os demais, os logs ficam indisponíveis pois são diretamente enviados às soluções conforme configuração.

Json-File
^^^^^^^^^

"Json-File" é o driver de logging padrão do Docker, onde um arquivo json passa a receber toda a saída advinda do contêiner. Inicialmente, para visualizar os logs de um contêiner utiliza-se o seguinte comando:

.. code-block:: bash

    $ docker logs <CONTAINER>
    $ docker logs -f <CONTAINER>
    
Em sua configuração padrão, este driver simplesmente recolhe e mantém toda a informação disponível no arquivo de log; para evitar o crescimento desenfreado de logs é recomendável adicionar o parâmetro "--log-opt max-size" à configuração do docker, no arquivo daemon.json:


.. literalinclude:: ../data/daemon.jsonfile.json

Após fazer a mudança da configuração, reinicie o daemon do docker para aplicar as configurações:

.. code-block:: bash

    $ sudo systemctl restart docker

.. warning::

    Arquivos que chegarem ao limite especificado de tamanho do log terão suas informações sobrescritas.

FluentD
^^^^^^^

O fluentD é um coletor de dados capaz de receber dados de diferentes níveis de infraestrutura e repassá-los a soluções específicas como o Apache Lucene/Elastic Search.

Para iniciar um novo contêiner com o fluentD, crie uma pasta com a seguinte declaração do arquivo docker-compose.yml:

.. literalinclude:: ../data/docker-compose.fluentd.yml

A seguir, crie o arquivo "stdout.conf" no mesmo diretório em que o arquivo docker-compose.yml se encontra, com o seguinte conteúdo:

.. literalinclude:: ../data/fluentd.stdout.conf

Por fim, inicialize o contêiner do fluentd através do comando ``docker-compose up -d`` a partir da pasta onde o arquivo docker-compose.yml reside.

Uma vez que o fluentd já está disponível, crie um novo contêiner através do seguinte comando:

.. code-block:: bash

    $ docker run -d --name web-fluentd -p 8080:80 --log-driver=fluentd --log-opt fluentd-address=localhost:24224 --log-opt tag="docker-web.{{.ImageName}}/{{.Name}}/{{.ID}}" nginx:alpine

Após a criação do contêiner, realize algumas requisições http para o endereço 'http://localhost:8080' para que logs sejam gerados e, por fim, visualize a recepção destes através dos logs do próprio fluentd:

.. code-block:: bash
    
    $ docker-compose logs -f

.. note::

    Informações acerca do FluentD podem ser obtidas na página do projeto: http://docs.fluentd.org/articles/quickstart, assim como informações acerca das opções de integração do mesmo com o docker: https://docs.docker.com/config/containers/logging/fluentd.

