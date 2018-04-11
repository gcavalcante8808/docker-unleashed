.. _aula3_exercises_3:

.. toctree::

***************************************************************************
Cap. 3 - Exercício 3: Centralização e Visualização dos Logs dos Contêineres
***************************************************************************

Para aplicar os conhecimentos explanados nesta aula, será necessário implementar um conjunto de soluções e integrações para guarda de logs de um contêiner de teste plenamente funcional. Para tanto, as ações abaixo balizam a implantação de um *stack* utilizando fluentd (coleta/recepção), elasticsearch (guarda) e Kibana (Visualização):

1. Remove o contêiner do fluentd previamente criado através do comando ``docker-compose down``;
2. Como root, rode o comando ``sysctl -w vm.max_map_count=262144`` necessário para funcionamento do ElasticSearch;
3. Crie uma nova pasta e insira o seguinte conteúdo para o arquivo docker-compose.yml:

.. literalinclude::  app/docker-compose.yml

4. Crie um arquivo chamado "fluentd.es.conf" na mesma pasta, contendo as seguintes configurações:

.. literalinclude:: app/fluent.conf

5. Crie um arquivo chamado "nginx.conf" na mesma pasta, contendo as seguintes configurações:

.. literalinclude:: app/nginx.conf

5. Inicialize os contêineres através do comando ``docker-compose up -d``. Nesse ponto, o elasticsearch e o Kibana podem demorar de 1 a 2 minutos para serem inicializalidos a depender da configuração de hardware do host;
6. Realize algumas requisições HTTP para o endereço ``http://localhost:8082`` afim de que logs sejam gerados e enviados ao fluentd e elasticsearch;
7. Acesse o Kibana através de um browser no endereço ``http://localhost5601`` e clique no item "Patterns", conforme figura abaixo:

.. image:: pattern_1.png

8. No campo index pattern inclua o valor "docker-web*" e em seguinte clique no botão "Next Step";
9. Na tela seguinte, no campo "Time Filter field name" escolha a opção "@timestamp", conforme figura abaixo:

.. image:: pattern_2.png

10. Por fim, visualize os logs gerados clicando no item de menu "Discover" no painel lateral. A visualização há de ocorrer de forma parecida com a da figura abaixo:

.. image:: discover_docker_web.png

Salvando os trabalhos
---------------------

Após a realização das atividades, salve o resultado do trabalho no github, através dos seguintes comandos (a partir da pasta onde os trabalhos se encontram):

.. code-block:: bash

    # Adicionar os arquivos atuais ao repositório
    git add .
    # Realizar o 'Commit' das mudanças no repositório local.
    git commit -m "Aula 3 - Exercicio 3"
    # Criar uma etiqueta para esta aula.
    git tag -a aula3_3 -m "Aula 3 - Exercicio 3"
    # Enviar as mudanças para o repositório remoto.
    git push -u origin master aula3_3

