Curso Docker Unleashed
----------------------

Este material encontra-se disponível sob a licença cc-by-sa-4.0(https://choosealicense.com/licenses/cc-by-sa-4.0/)e inicialmente foi pensado como apoio para um formato presencial de curso.

Conforme licença, seu uso é permitido para distribuição, modificação, uso privado e comercial, sem garantias de uso de nome, patentes ou funcionamento/aplicabilidade. 

Adicionalmente, contribuições são mais que bem vindas; para tanto, utilize o sistema de Forks e PR's do próprio github e, preferencialmente, abra uma *issue* descrevendo as mudanças necessárias ou a serem enviadas.

Informações acerca do material
------------------------------

O material foi escrito utilizando-se o framework [Sphinx](http://www.sphinx-doc.org/en/stable/), que promove a utilização da linguagem de marcação [ReST](https://en.wikipedia.org/wiki/ReStructuredText) para a criação do conteúdo.

Todos os conteúdos encontram-se em "docker-unleashed". Para a geração do material (recomenda-se o formato HTML, mas outros são suportados conforme documentação do Sphinx) é necessário:

1. A linguagem Python instalada no Sistema Operacional;
2. As bibliotecas listadas no arquivos `requirements.txt`;
3. Realizar a geração do material através do comando `make html`.

Em um sistema operativo Linux, que usualmente já possui o Python instalado, os seguintes comandos são suficientes (USE COM CUIDADO):

1. curl https://bootstrap.pypa.io/get-pip.py | python
2. pip install virtualenv
3. virtualenv ~/env
4. source ~/env/bin/activate
5. pip install -r requirements.txt

Após a instalação dos requerimentos, basta realizar as edições nos arquivos com extensões `.rst` e criar novas *builds* através dos comandos:

```
source ~/env/bin/activate
make html
```

Autor
-----

Autor: Gabriel Abdalla Cavalcante Silva
