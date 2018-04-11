.. _aula2_exercises_2:

.. toctree::

************************************************************************
Cap. 3 - Exercício2: Uso e Comunicação entre contêineres em redes docker
************************************************************************

Para aplicar os conhecimentos explanados nesta aula, será necessário atualizar a aplicação afim de que a mesma passe a utilizar um cache Redis. Para tanto, as ações abaixo balizam as mudanças necessárias:

1. Atualize o arquivo "app.py" da aplicação em python para que possua o seguinte conteúdo:

.. code-block:: python

    from flask import Flask, request
    from logging.handlers import RotatingFileHandler
        
    from flask.ext.redis import FlaskRedis

    import logging
    import datetime

    #Create the App
    app = Flask(__name__)

    #Redis Connection URL
    app.config['REDIS_URL'] = "redis://redis:6379/0"

    #Bind Redis Connection to app
    redis_store = FlaskRedis(app)

    #Create logs
    handler = RotatingFileHandler('/tmp/foo.log', maxBytes=10000, backupCount=1)
    handler.setLevel(logging.INFO)
    app.logger.addHandler(handler)

    #Send Values to Redis.
    redis_store.set('Start Time', datetime.datetime.now())

    @app.route("/")
    def hello():
        app.logger.error(('The referrer was {}'.format(request.referrer)))
        return "Hello World!"
        
2. A seguir, inclua a dependência "flask-redis" no arquivo requirements.txt relativo a aplicação;
3. Crie um arquivo docker-compose.yml com o seguinte conteúdo:

.. literalinclude:: app/docker-compose.yml

4. Inicialize os novos contêineres através do comando ``docker-compose up -d``;
5. Verifique se a chave 'Start Time' foi criada no redis através do comando ``docker-compose exec redis redis-cli keys '*'``.

Informações e/ou questões adicionais
####################################

O que acontecerá caso a declaração do serviço 'redis' mude de nome?

É possível refatorar a aplicação para que ela funcione com outros servidores redis?

Salvando os trabalhos
---------------------

Após a realização das atividades, salve o resultado do trabalho no github, através dos seguintes comandos (a partir da pasta onde os trabalhos se encontram):

.. code-block:: bash

    # Adicionar os arquivos atuais ao repositório
    git add .
    # Realizar o 'Commit' das mudanças no repositório local.
    git commit -m "Aula 3 - Exercicio 2"
    # Criar uma etiqueta para esta aula.
    git tag -a aula3_2 -m "Aula 3 - Exercicio 2"
    # Enviar as mudanças para o repositório remoto.
    git push -u origin master aula3_2

