.. _aula1_exercises:

.. toctree::


********************
Cenário e Atividades
********************

Para aplicar os demais conhecimentos nas demais aulas, será necessário criar uma imagem da aplicação 'curso', cujos detalhes são os seguintes:

1. A aplicação é feita em Python;
3. O projeto possui um arquivo `requirements.txt` que contém as bibliotecas python que devem ser instaladas através do PIP, cuja instalação pode ser realizada da diretiva `RUN pip install -r requirements.txt`;
4. Objetivando um uso inicial em desenvolvimento, apenas utilizaremos um servidor Werkzeug mais simples para servir as páginas do projeto. Para isso, o flask requer que **variável de ambiente** `FLASK_APP` esteja definida com o nome do módulo da aplicação, nesse caso `app.py`, que pode ser expresso no Dockerfile através da diretiva `ENV FLASK_APP=app.py`;
5. O comando a ser utilizado para este contêiner é `flask run` que deve ser realizado a partir da pasta da aplicação;
6. Crie o módulo `app.py` com o código abaixo, salve-o e copie-o para a imagem (Diretiva `COPY`):

.. code-block:: python

    from flask import Flask
    app = Flask(__name__)

    @app.route("/")
    def hello():
        return "Hello World!"

7. Realiza a criação da imagem com a etiqueta *imagem-aula-1* através do comando `docker build -t imagem-aula-1 .`;
8. Crie um contêiner com o nome **aula-1** a partir da imagem com um vínculo da porta 5000 do host para a porta 5000 do contêiner para facilitar a visualização através do um browser, através do comando `docker run -d --name aula-1 -p 5000:5000 imagem-aula-1`.

Informações adicionais
######################

A imagem python disponibilizada pelo docker em suas diversas variantes (2, 3, 2-slim, 3-slim, 2-alpine, 3-alpine) já possui o PIP instalado, que pode ser utilizado para instalar bibliotecas a partir de um arquivo ou diretamente declarando o pacote a ser instalado, conforme os seguintes exemplos:

.. code-block:: bash
    #Instalando a partir de um arquivo
    pip install -r requirements.txt
    #Instalando uma biblioteca diretamente
    pip install Flask

**Item 1**: Se utilizar uma imagem mais simples como base (Debian, Centos, etc) e desejar instalar a última versão do PIP , usualmente a seguinte diretiva é suficiente para instalar o PIP (requer as bibliotecas mínimas do python já instaladas):

.. code-block:: bash
    
    curl https://bootstrap.pypa.io/get-pip.py | python

**Com base nos dados acima dispostos, realize o processo de encapsulamento da aplicação no modelo de contêineres.**

Como Verificar se todas as ações ocorreram conforme o esperado
##############################################################

Após a criação da imagem, faça a criação de um contêiner a partir da mesma e verifique através de seu browser se é possível acessar a página inicial disponível em: 'http://localhost:5000'.

Salvando os trabalhos
---------------------

Após a realização das atividades, salve o resultado do trabalho no github, através dos seguintes comandos (a partir da pasta onde os trabalhos se encontram):

.. code-block:: bash

    # Inicializar o suporte ao versionamento
    git init .
    # Adicionar os arquivos atuais ao repositório
    git add .
    # Realizar o 'Commit' das mudanças no repositório local.
    git commit -m "Aula 1"
    # Criar uma etiqueta para esta aula.
    git tag -a aula1 -m "Aula 1 - <ALUNO>"
    # Enviar as mudanças para o reposítório remoto.
    git remote add https://github.com/<USUARIO>/docker-unleashed
    git push -u origin master aula1
    ```
