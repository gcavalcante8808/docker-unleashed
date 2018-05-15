.. _aula2_exercise_1:

.. toctree::

**********************************************************
Cap. 2 - Exercício1: Gerenciamento e utilização de Volumes
**********************************************************

Para aplicar os conhecimentos explanados nesta aula, será necessário atualizar a aplicação criando uma nova imagem e verificando o impacto da (não) utilização de volumes em conjunto com um contêiner do docker. Siga as seguintes instruções:

1. Atualize o código da aplicação, para que inclua agora o suporte a criação de um arquivo de log, conforme abaixo:

.. code-block:: python

    import logging
    from flask import Flask, request
    from logging.handlers import RotatingFileHandler

    app = Flask(__name__)

    handler = RotatingFileHandler('/tmp/foo.log', maxBytes=10000, backupCount=1)
    handler.setLevel(logging.INFO)
    app.logger.addHandler(handler)

    @app.route("/")
    def hello():
        app.logger.error(('The referrer was {}'.format(request.referrer)))
        return "Hello World!"

2. Realize a criação de uma imagem, cuja nome será **oficina-docker** e etiqueta será **aula2-volumes** através do comando ``docker build -t oficina-docker:aula2-volumes . ``;

3. Crie um contêiner com o nome **aula-2** a partir da imagem com um vínculo da porta 5000 do host para a porta 5000 do contêiner para facilitar a visualização através do um browser, através do comando ``docker run -d --name aula-2 -p 5000:5000 oficina-docker:aula2-volumes``;

4. Acesse a aplicação a partir de um browser no endereço ``http://localhost:5000`` e realize algumas requisições para que estas possam ser inseridas pela aplicação em no arquivo 'foo.log' dentro do contêiner;

5. Visualize o conteúdo do arquivo através do comando ``docker exec -it aula-2 cat /usr/src/foo.log``;

6. Remova o contêiner através do comando ``docker rm -f aula-2``;

7. Repita os passos 3 e 5 (sem passar pelo passo 4) e tente visualizar possíveis diferenças no arquivo foo.log;

8. Crie um volume chamado ``aula2-logs`` através do comando: ``docker volume create aula2-logs``;

9. Remova o contêiner através do comando ``docker rm -f aula-2``;

10. Recrie o contêiner agora com suporte ao *named volume* 'aula2-logs' através do seguinte comando ``docker run -d --name aula-2 -p 5000:5000 -v aula2-logs:/tmp oficina-docker:aula2-volumes``;

11. Repita os passos 4, 5, 6 e tente visualizar as possíveis diferenças no uso dos volumes.

Informações e/ou questões adicionais
####################################

Que outros efeitos colaterais temos ao utilizar um arquivo com alto nível de mudança de conteúdo fora de um volume?

Considerando que o objetivo atual é auxiliar no desenvolvimento da aplicação, existe alguma maneira mais simples de manter o arquivo de log ativo e acessível para o desenvolvedor?

Se removermos o contêiner o que acontecerá com o volume?

Se removermos o volume o que acontecerá o arquivo foo.log?

Salvando os trabalhos
---------------------

Após a realização das atividades, salve o resultado do trabalho no github, através dos seguintes comandos (a partir da pasta onde os trabalhos se encontram):

.. code-block:: bash

    # Adicionar os arquivos atuais ao repositório
    git add .
    # Realizar o 'Commit' das mudanças no repositório local.
    git commit -m "Aula 2 - Exercicio 1"
    # Criar uma etiqueta para esta aula.
    git tag -a aula2_1 -m "Aula 2 - Exercicio 1"
    # Enviar as mudanças para o repositório remoto.
    git push -u origin master aula2_1
    
