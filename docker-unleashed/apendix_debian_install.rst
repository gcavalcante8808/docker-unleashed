.. _apendix_debian_install:

.. toctree::

=====================
Debian 9 - Instalação
=====================

O passo a passo a seguir identifica as informações e escolhas necessárias para instalar o Debian 9 de forma simples. Para a execução desta tarefa será necessário o acesso ao menu de **boot** do computador no qual o SO será instalado.


Após a inserção do CD na unidade de leitura e escolha no menu de boot, escolha a opção "Graphical Install":

.. image:: ../debian-install-data/1-menu.png

Na tela a seguir, selecione o Idioma desejado (para esta conteúdo foi selecionado o idioma Inglês):

.. image:: ../debian-install-data/2-idioma.png

Na tela de seleção de localização escolha o país desejado:

.. image:: ../debian-install-data/3-location.png

Na tela de seleção do mapeamento de teclado escolha a opção "Brazilian" e então clique em "Continuar:

.. image:: ../debian-install-data/4-keyboard.png

Na tela de configuração do *hostname* insira o o valor "alunoXX" onde "XX" é o número da máquina no laboratório:

.. image:: ../debian-install-data/5-hostname.png

Na tela de configuração do *domínio* do host insira o valor "oficina.org":

.. image:: ../debian-install-data/6-domain.png

Na tela de configuração da senha do usuário root deixe os valores em branco e prossiga:

.. image:: ../debian-install-data/7-rootpass.png

Nas telas de configuração do Nome usuário comum, do *username* e *password*, insira o valor "vagrant" e prossiga:

.. image:: ../debian-install-data/8-user.png

.. image:: ../debian-install-data/9-username.png

.. image:: ../debian-install-data/10-userpass.png

Na tela de configuração de *timezone* deixa na opção padrão e prossiga:

.. image:: ../debian-install-data/11-clock.png

Na tela seguinte, "Particionamento de discos" escolha a opção "Guiada - Usar o disco inteiro e configurar LVM":

.. image:: ../debian-install-data/12-partitioning.png

Na tela das opções de diferentes esquemas de particionamento escolha a opção "" e confirme a execução nas duas telas seguintes:

.. image:: ../debian-install-data/15-newparts.png

.. image:: ../debian-install-data/16-confirm.png

.. image:: ../debian-install-data/17-finishpart.png

.. image:: ../debian-install-data/18-confirmagain.png

Na tela que se apresenta, "Configuração do Gerenciador de Pacotes" verifique se a opção "Yes" está marcada e clica em continuar:

.. image:: ../debian-install-data/19-mirrorquestion.png

Na tela de seleção de qual país os mirrors devem ser procurados selecione o opção: "Brasil":

.. image:: ../debian-install-data/20-mirrorcountry.png

Após a escolha do país escolha o mirror "linorg.usp.br":

.. image:: ../debian-install-data/21-mirrorchoice.png

Na tela relacionado ao *popularity-contest* deixe a opção "Não" marcada e prossiga:

.. image:: ../debian-install-data/22-popcontest.png

Na tela de configuração de proxy HTTP deixe o valor em branco e prossiga:

.. image:: ../debian-install-data/23-proxy.png

Na tela de seleção de software, verifique se **somente** os seguintes itens estão marcados: "Debian Desktop Environment", "Xfce" e "standard system utilities":

.. image:: ../debian-install-data/23-packages.png

Nesse ponto alguns pacotes precisarão ser instalados a partir da internet; aproveite e vá tomar um bom café, o tempo de instalação varia de 5 a 10 minutos a depender da conexão com a internet.

Na tela de confirmação da instalação do gerenciador de boot verifique se a opção "Sim" está marcada e prossiga:

.. image:: ../debian-install-data/24-grubinstall.png

Na tela de configuração do alvo da instalação, marque o disco rígido *primário*:

.. image:: ../debian-install-data/25-grubtarget.png

Após os passos supracitados serem executados a instalação está pronta para ser utilizada; reinicie o computador e aproveite seu novo SO :D
