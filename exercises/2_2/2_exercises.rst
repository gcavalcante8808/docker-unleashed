.. _aula2_exercises_2:

.. toctree::

*******************************************
Persistência das configurações do contêiner
*******************************************

Para aplicar os conhecimentos explanados nesta aula, será necessário criar um arquivo `docker-compose.yml` que contenha todas as definições necessárias para que a aplicação possa ser construída e iniciada a partir do mesmo conforme especificações abaixo:

1. Crie um arquivo chamado docker-compose.yml dentro da pasta da aplicação;
2. Na declaração da versão do arquivo, utilize a versão '2';
3. A seguir, declare um volume chamado 'aula2-logs' que será um volume local, sem detalhes adicionais;
4. Na declaração dos serviços, crie um serviço chamado 'aula2';
5. Na declaração da imagem do serviço utilize a imagem `oficina-docker:aula2-volumes`;
6. Na declaração de volumes, mapeie o volume `aula2-logs` para `/tmp`;
7. Salve e feche o arquivo; em seguida, utilize o comando `docker-compose up -d` para criar o contêiner e o volume previamente declarados;
8. Através do comando `docker ps` verifique se o seu contêiner foi iniciado e se as informações dele são condizentes com o contêiner anterior;
9. Abra novamente o arquivo `docker-compose.yml` e insira a definição `container_name: aula-2` no escopo principal do serviço 'aula-2';
10. Repita o passo 7 e verifique as diferenças no novo contêiner criado.

Informações e/ou questões adicionais
####################################

Lembre-se que arquivos YAML utilizam a indentação para reconhecer os diferentes níveis de funcionalidades.

As várias formas de realizar a declaração do arquivo 'docker-compose.yml' afim de se realizar o mapeamento dos recursos do Docker estão disponíveis em https://docs.docker.com/compose/compose-file/compose-file-v2/.

É possível utilizar o comando docker-compose config para verificar se um arquivo docker-compose.yml é valido.
