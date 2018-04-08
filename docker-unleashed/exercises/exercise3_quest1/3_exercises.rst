.. _aula2_exercises_2:

.. toctree::

**********************************************
Persistências de Imagens em um Docker Registry
**********************************************

Para aplicar os conhecimentos explanados nesta aula, será necessário aplicar uma *tag* a imagem criada na aula anterior, de forma que seja possível enviar esta imagem para o registry central. As ações realizadas devem balizar o conjunto de especificações abaixo:

1. Com base na imagem "oficina-docker:aula2-volumes" atribua uma nova tag através do comando ``docker tag oficina-docker:aula2-volumes <IP_REGISTRY_CENTRAL:5000>/<USUARIO_GITHUB>/oficina-docker:aula2-volumes``;
2. Realize o login para o registry "<IP_REGISTRY_CENTRAL:5000>" através do comando ``docker login <IP_REGISTRY_CENTRAL:5000>`` utilizando como credenciais (usuário/senha) o seu nome de usuário do github;
3. Envie a imagem ao registry central através do comando ``docker push <IP_REGISTRY_CENTRAL:5000>/<USUARIO_GITHUB>/oficina-docker:aula2-volumes``;
4. Exclua a sua imagem "oficina-docker:aula2-volumes" local através do comando ``docker rmi oficina-docker:aula2-volumes``;
5. Realize o download da imagem novamente, mas a partir do registry central através do comando ``docker pull oficina-docker:aula2-volumes``.

Informações e/ou questões adicionais
####################################

Se uma determinada imagem estiver sendo utilizada por um contêiner, será necessário remover este contêiner antes de remover a imagem.

Que tipo de recursos seriam desejáveis caso fosse desejado ter um registry que atendesse a um ambiente corporativo?

Salvando os trabalhos
---------------------

Após a realização das atividades, salve o resultado do trabalho no github, através dos seguintes comandos (a partir da pasta onde os trabalhos se encontram):

.. code-block:: bash

    # Adicionar os arquivos atuais ao repositório
    git add .
    # Realizar o 'Commit' das mudanças no repositório local.
    git commit -m "Aula 3 - Exercicio 1"
    # Criar uma etiqueta para esta aula.
    git tag -a aula3_1 -m "Aula 3 - Exercicio 1"
    # Enviar as mudanças para o reposítório remoto.
    git push -u origin master aula3_1
    
