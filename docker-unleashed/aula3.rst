.. _aula3:

.. toctree::

***************************************************************
Aula 3: Repositório de Imagens, Conectividade Interna e Logging
***************************************************************


===============
Docker Registry
===============

O Docker Registry provê um serviço para hospedagem de imagens do Docker análogo ao que está disponível no hub.docker.com, porém com a possibilidade de uso e hospedagem em uma rede interna.

Para iniciar um novo contêiner com o registry utilize o seguinte comando:

.. code-block:: bash

    # mkdir /root/registry && cd /root/registry
    # docker run -d -p 5000:5000 --restart=always -v /root/registry/data:/var/lib/registry --name registry registry:2


Antes de enviar ou receber imagens a partir do novo registry, será necessário configurar o docker para permitir a interação entre o cliente e o registry. Nesse caso, inicie a edição da configuração do docker com o seguinte comando:

.. code-block:: bash

    # systemctl edit --full docker

Na linha que se inicia com **ExecStart** adicione os seguintes parâmetros:

    ``--insecure-registry=myregistry.com:5000``

E por fim reinicie o docker para aplicar as configurações:

.. code-block:: bash

    # systemctl restart docker
    
Para verificar quais *insecure registries* são aceitos pelo daemon do docker, utilize o comando "docker info"; a informação desejada estará ao final do comando, abaixo da linha que se inicia com "Insecure Registries:".

Uma vez que o docker está preparado, realizar o envio de uma imagem requer que **você defina tags nas imagens atuais que contenham o nome do repositório no formato registry:porta/imagem:tag** e faça o *push*, conforme o exemplo abaixo:

.. code-block:: bash

    # docker tag ubuntu myregistry:5000/ubuntu:yak
    # docker push myregistry:5000/ubuntu:yak

Realizar o download de imagens a partir do registry é igualmente fácil:

.. code-block:: bash

    # docker pull myregistry:5000/ubuntu:yak
    
No entanto, até então, toda a comunicação com o registry vem sendo realizada através de HTTP, ou seja, sem a criptografia da comunicação. Para ativar o suporte a TLS/HTTPS no acesso a aplicação, crie um certificado, remova o contêiner antigo e proceda da seguinte maneira:

.. code-block:: bash

    # mkdir -p /root/registry/certs
    # cp domain.* /root/registry/certs
    # docker run -d -p 5000:5000 --restart=always \
      -v /root/registry/data:/var/lib/registry \
      -v /root/registry/certs:/certs \
      -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
      -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
      --name registry registry:2

.. note::

    Para fins de aprendizado, o certificado pode ser gerado através do site http://www.selfsignedcertificate.com/. Para o ambiente de produção, solicite os certificados junto a área de infraestrutura.
    

É possível ainda fazer a restrição de acesso ao registry através da utilização de credenciais no estilo htpasswd. Para tanto, procesa da seguinte maneira:

.. code-block:: bash

    # cd /root/registry && mkdir auth
    # docker run --entrypoint htpasswd registry:2 -Bbn testuser testpassword > auth/htpasswd
    # docker run -d -p 5000:5000 --restart=always \
      -v /root/registry/data:/var/lib/registry \
      -v /root/registry/certs:/certs \
      -v /root/registry/auth:/auth \
      -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
      -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
      -e "REGISTRY_AUTH=htpasswd" \
      -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
      -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
      --name registry registry:2

Para realizar o login na registry, utilize o "docker login", conforme abaixo:

.. code-block:: bash

    # docker login myregistry.enterprise.com:5000

.. note::

    As informações de login são guardadas como *base64* no arquivo ~/.docker/config.json.
    

Por fim, a criação do contêiner do registry pode ser refletida com o seguinte *compose file*:

 .. literalinclude:: ../data/docker-compose-registry.yml

.. note::

    Mais informações acerca do registry podem ser encontradas em: https://docs.docker.com/registry/configuration/

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

