.. _aula4:

.. toctree::

*************************************
Aula4: Escalabilidade & Monitoramento
*************************************

===============
Storage Drivers
===============

"Storage Drivers" são os drivers de acesso utilizados pelo Docker para **espelhar** os arquivos
do sistema de arquivos do Host para os contêineres. Atualmente, podem ser de 5 tipos:

 * Aufs
 * OverlayFS
 * DeviceMapper/LVM
 * ZFS
 * Btrfs

AuFs
====

AuFS (Advanced Multi-Layered Unification Filesystem) é o sistema de arquivos utilizado há mais tempo pelo Docker. Sua versão mais recente é suportada a partir do Kernel 4.1 e é uma evolução do antigo **UnionFS**. A sua estrutura de funcionamento pode ser visualizada na imagem abaixo:

.. image:: ../data/aufs_layers.jpg

Em sistema de arquivos AuFS, os vários níveis de camadas correspondentes às camadas das imagens são trabalhados de forma a serem espelhados como um único diretório para o contêiner alvo.

Arquivos removidos em sistema de arquivos AuFS não retornam o espaço em disco utilizado, pois no último nível de camada, o próprio sistema de arquivo utiliza-se de um **whitefile** que bloqueia o acesso dessa camada ao arquivo das camadas anteriores.

.. image:: ../data/aufs_delete.jpg


Da mesma forma, durante a atualização de um arquivo existe, o mesmo é copiado a partir das camadas 
mais baixas para a camada mais alta onde é, então, atualizado.

O AuFS já vem configurado por padrão nas Distribuições não RedHat. Antes de ativá-lo, porém, é recomendável
verificar se o kernel em funcionamento possui suporte para o mesmo:

.. code-block:: bash

    $ grep aufs /proc/filesystems

.. note::

    Nas distribuições baseada em RedHat, o suporte AuFS não está disponível. Deve-se utilizar o *devicemapper/lvm* como opção padrão.
    
.. note::
    Usualmente, as camadas e arquivos do AuFS ficarão disponíveis em "/var/lib/docker/aufs".


OverLay(FS)
===========

O Overlay(anteriormente OverlayFS) é tido como uma atualização da arquitetura do AuFS, com uma arquitetura
mais simples, suportado no Kernel Linux a partir da versão 3.18 e potencialmente mais rápido.

Em sua versão 1 somente há suporte duas camadas: o **lowerdir** (imagem) e o **topdir** (contêiner). O suporte ao FS pode ser checado através do seguinte comando:

.. code-block:: bash

    # modprobe overlay
    # lsmod | grep overlay

Para ativar o suporte ao OverLay no Docker, execute o seguinte comando:

.. code-block:: bash

    # systemctl edit --full docker.service
    
Na linha que se inicia com "ExecStart", adicione a seguinte configuração:

``
    ExecStart=[...] --storage-driver=overlay
``

E reinicie o docker afim de ativar o uso do novo driver:

.. code-block:: bash

    # systemctl restart docker
    
.. note::
    
    Quando da ativação de um novo Storage Driver as imagens anteriores e seus contêineres não ficam acessíveis.
    Antes de se iniciar o processo é necessário exportar as imagens e contêineres para então reimportá-los.

.. note::

    Mudanças realizadas enquanto o sistema de arquivos está **off-line** são plenamente suportadas. Contudo, realizar
    mudanças nos níveis mais baixos do sistema de arquivos enquanto o mesmo está funcionamento pode resultar
    em um comportamento erroneo, como **crashs** ou **deadlocks**.


Devicemapper
============


O storage Backend "Devicemapper" utiliza-se da estrutura de acesso a disco do LVM, sendo a configuração padrão para a instalação 
do docker em RedHat/CentOS uma vez que por padrão o Kernel do SO não suporta o AuFS.

O Devicemapper possui dois modos de funcionamento:

 * loop-lvm: Esse modo utiliza-se de um arquivo esparso que será utilizado para as imagens e contêineres, que é montado e gerido pelo LVM;
 * direct-lvm: Esse modo utiliza-se da estrutura de volumes lógicos do LVM e recursos de **snapshoting** para o acesso a nível de bloco para cada *partição*. Este é o modo indicado para produção.


Devicemapper - LoopLVM
----------------------


A configuração para a utilização do modo **loop-lvm** pode ser realizada 
 
Para ativar o suporte ao **Loop-LVM**  no Docker, execute o seguinte comando:

.. code-block:: bash

    # systemctl edit --full docker.service
    
Na linha que se inicia com "ExecStart", adicione a seguinte configuração:

.. code-block:: bash

    # ExecStart=[...] --storage-opt dm.loopdatasize=500GB --storage-opt dm.loopmetadatasize=10GB

E reinicie o docker afim de ativar o uso do novo driver:

.. code-block:: bash

    # systemctl restart docker


DeviceMapper - Direct-LVM
-------------------------


Ao contrário do modo Loop-LVM, no modo **DirectLVM** os arquivos de cada um dos contêineres serão
alocados em diversos níveis de volumes lógicos e snapshots. Portanto, para utilizar esse modo será necessário
alocar ao menos uma partição do Sistema Operacional para trabalhar com a mesma.

Usualmente, o processo envolve 3 passos:

 1. Inicilizar um disco ou partição para ser usada pelo LVM;
 2. Criar um **VolumeGroup**;
 3. Criar um **LogicalVolume** que será utilizado pelo Docker.

A inicialiação de um disco para utilização pelo LVM pode ser realizada através do seguinte comando:

.. code-block:: bash

    # pvcreate /dev/hdb1
    # pvscan

No exemplo acima, a partidção /dev/hdb1 é inicializada para uso com LVM.

.. warning::

    A inicialização da partição pode fazer com que os dados da partição sejam perdidos, uma vez que reescreve a informação sobre a mesma na MBR/EFI.

Após a inicialização, é possível visualizar as informações sobre o mesmo através do seguinte comando:

.. code-block:: bash

    # pvdisplay
    
Cria-se agora um **VolumeGroup** que conterá um ou mais discos já inicializados:

.. code-block:: bash

    # vgcreate docker /dev/sdd1 /dev/sde1
    # vgscan

No exemplo acima, as partições ou discos lógicos /dev/sdd1 e /dev/sde1 foram adicionados ao *VolumeGroup* 'VG1', que por não ter nenhuma configuração adicional resultará em um *pool* de discos com o tamanho combinado de ambos para uso.

Para visualizar as informações sobre os **VolumeGroups** utilize o seguinte comando:

.. code-block:: bash

    # vgdisplay
    
A seguir, é necessário criar o volume lógico que será utilizado pelo docker e um volume lógico com metadados:

.. code-block:: bash

    # lvcreate --wipesignatures y -n thinpool docker -l 95%VG
    # lvcreate --wipesignatures y -n thinpoolmeta docker -l 1%VG
    # lvconvert -y --zero n -c 512K --thinpool docker/thinpool --poolmetadata docker/thinpoolmeta
    # lvscan

Por fim, configure o docker para utilizar o Storage Driver 
No exemplo acima, um volume lógico com o tamanho de 100G será criado no **VolumeGroup** 'VG1', com o nome 'docker-volume'.
Para visualizar os volumes lógicos basta utilizar o seguinte comando:

.. code-block:: bash

    # lvdisplay

Para ativar o suporte ao **Loop-LVM**  no Docker, execute o seguinte comando:

.. code-block:: bash

    # systemctl edit --full docker.service
    
Na linha que se inicia com "ExecStart", adicione a seguinte configuração:

.. code-block:: rst

    # ExecStart=[...] --storage-driver=devicemapper --storage-opt=dm.thinpooldev=/dev/mapper/docker-thinpool --storage-opt=dm.use_deferred_removal=true --storage-opt=dm.use_deferred_deletion=true


E reinicie o docker afim de ativar o uso do novo driver:

.. code-block:: bash

    # systemctl restart docker
    # docker info
    
.. warning::

    Em distribuições que utilizam o SELINUX, é recomendável deixar o mesmo em modo **permissive** e tratar
    a necessidade de acesso aos snapshots e volumes criados pelo LVM tempestivamente. Deixar o SELINUX em modo **enforcing**
    poderá fazer com que um contêiner não possa ser inicializado por falha de acesso ao disco LVM.

==============================
Utilização de Volumes Externos
==============================

A utilização de volumes externos visa permitir o compartilhamento de dados entre os serviços e contêineres. O compartilhamento dos dados pode ocorrer de duas formas: através de um volume que se utiliza do driver "local" e recursos do host para fazer a "montagem" do endereço compartilhado e através de plugins.

Para utilizar um volume externo que se utiliza do NFS podemos fazer a criação de um serviço do tipo *mount* no sistema operacional, serviço esse que será responsável por realizar a montagem do volume NFS de forma automática durante a inicialização. Para tanto, crie um arquivo chamado *media-docker.mount* com o seguintes comando e conteúdo:

.. code-block:: bash

    # systemctl edit --full media-docker.mount
    
.. high lightning:: ini

    [Unit]
    Before=convoy-nfs.service
    [Mount]
    What=<SERVER>:/media/data
    Where=/media/docker
    Type=nfs
    Options=vers=3,nolock
            
    [Install]
    WantedBy=multi-user.target

Após a criação do serviço de montagem, habilte-o e inicie-o através dos seguintes comandos:

.. code-block:: bash
    
    # systemctl enable media-docker.mount
    # systemctl start media-docker.mount
    
Por outro lado, utilizar um plugin externo permite que muitas vezes se faça o compartilhamento de uma área comum para todos os volumes (algo análogo o /var/lib/docker/volumes); comumente soluções desse tipo contém os controles necessários para gerenciar efetivamente o gerenciamento de volumes. Para este curso utilizar-se-á o driver "convoy". A instalação do mesmo pode ser feita através dos seguintes passos:

.. code-block:: bash

    # wget https://github.com/rancher/convoy/releases/download/v0.5.0/convoy.tar.gz
    # tar xvzf convoy.tar.gz
    # sudo cp convoy/convoy convoy/convoy-pdata_tools /usr/local/bin/
    # sudo mkdir -p /etc/docker/plugins/
    # sudo bash -c 'echo "unix:///var/run/convoy/convoy.sock" > /etc/docker/plugins/convoy.spec'

Após a configuração do plugin e reinício do *daemon* do Docker, podemos testar o novo plugin através da criação de uma pasta (ou montagem de um volume nfs com o comando anterior) através dos seguintes comandos:

.. code-block:: bash

    # convoy daemon --drivers vfs --drivers-opts vfs.path=/mountpoint
    # docker volume create --driver convoy --name myvolume
    
Adicionalmente, é interessante criar um serviço do Sistema Operacional para que o serviço do convoy possa iniciar em conjunto com o sistema operacional; para tanto:

.. code-block:: bash

    # systemctl edit --full --force convoy.service

Na tela de edição inclua as seguintes configurações para o serviço:

.. high light:: ini

    [Unit]
    Description=Convoy NFS Plugin for Docker
    Before=docker.service
            
    [Service]
    ExecStart=/opt/bin/convoy daemon --drivers vfs --driver-opts vfs.path=/media/docker

Salve o arquivo e, em seguida, ative o serviço para ser acionado durante a inicialização:

..code-block:: bash

    # systemctl start convoy
    # systemctl enable convoy

.. warning::

    O systemd presente no CentOS 7 ainda não possuía suporte a criação do arquivo através do sytemctl edit na ocasião do lançamento da distribuição. Para esse caso deve-se criar o arquivo em uma pasta do sistema de arquivos, copiar para o arquivo para /etc/systemd/system, rodar o comando systemctl daemon-reload e prosseguir com os passos descritos nesse capítulo.

========================================
Visualização de Recursos & Monitoramento
========================================

A visualização de uso de Recursos do docker pode ser realizado através do seguinte comando:

.. code-block:: bash

    # docker stats
    # docker stats --no-stream
    # docker stats <CONTAINER>

Atualmente, algumas soluções do mercado já provêem suporte a estatísticas de funcionamento do docker, mas o CAdvisor destaca-se por ser Aplicação criada pelo Google, simplista, que retorna as estatísticas de uso de recurso dos contêineres e do host.
Para iniciar o Cadvisor em um Host com o docker utilize o seguinte comando:

.. code-block:: bash

    docker run \
      --volume=/:/rootfs:ro \
      --volume=/var/run:/var/run:rw \
      --volume=/sys:/sys:ro \
      --volume=/var/lib/docker/:/var/lib/docker:ro \
      --publish=8080:8080 \
      --detach=true \
      --name=cadvisor \
      google/cadvisor:latest

Por outro lado, o monitoramento do contêiner pode ocorrer através do uso de Recursos e do Status do Contêiner: para o segundo caso, um recurso muito útil é de **HealthCheck**, onde o próprio contêiner passa a conter uma instrução de checagem, que é automaticamente executada em segundo plano e que, a depender do resultado, irá mudar a chave "{{ Status.Health }}" e até mesmo parar o contêiner.

Um exemplo de instrução de checagem pode ser visto abaixo:

``HEALTHCHECK --interval=5m --timeout=3s CMD curl -f http://localhost/ || exit 1``
