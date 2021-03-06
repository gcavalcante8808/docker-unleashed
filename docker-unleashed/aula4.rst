.. _aula4:

.. toctree::

*************************************
Aula4: Gerenciamento de Recursos
*************************************


==================================================
CGROUPS: Gerenciamento de Recursos dos Containeres
==================================================

É possível definir o uso de recursos do ambiente por contêineres durante a sua criação ou funcionamento.

Para tanto, o próprio recurso de CGroups contém descritores para cada tipo de recurso: CPU, Memória, *Throughput* de Disco e Rede. O número desses descritores atribui um peso/prioridade para cada contêiner, sendo que por padrão, todos os contêineres dividem os recursos disponíveis igualmente.

A definição da limitação de recursos pode acontecer durante a criação do contêiner, com parâmetros em conjunto com o comando "docker run" (também via declaração em um arquivo docker-compose.yml) ou após a criação do contêiner (inclusive durante seu funcionamento) utilizando-se o comando "docker update".

.. note ::

    O gerenciamento/escalonamento da pilha de rede de um contêiner não é suportado pelo docker.
    Informações completas acerca  do docker update disponíveis em: https://docs.docker.com/engine/reference/commandline/update.
    

CPU
---

O controle de uso de CPU por contêiner pode ocorrer em 3 níveis:

 * Peso Relativo;
 * Afinidade;
 * Porcentagem de Uso do Recurso.
 
Para o caso de peso relativo, leva-se em conta que cada contêiner possui até 1024 descritores, o que define o uso mínimo do recurso de CPU. O exemplo abaixo ilustra a criação de um contêiner que possui acesso a pelo menos a 25% da CPU:

.. code-block:: bash
    
    $ docker run -it --rm --cpu-shares 256 stress --cpu 1

Para uso via docker-compose, pode-se dispor o arquivo docker-compose.yml da seguinte maneira:

.. code-block:: yaml

    version: '2.2'
    services:
      stress:
        image: stress
        entrypoint: stress
        command: --cpu 1
        cpu_shares: 256

Dessa forma, em um cenário em que haja forte concorrência por uso da CPU, o contêiner acima terá resguardado pelo menos 25%.

No caso da definição da afinidade de um contêiner basta indicar as CPU's alvo através do parâmetro "--cpuset-cpus", conforme abaixo:

.. code-block:: bash

    $ docker run -it --rm --cpuset-cpus=0,1 stress --cpu 2

Para uso via docker-compose, pode-se dispor o arquivo docker-compose.yml da seguinte maneira:

.. code-block:: yaml

    version: '2.2'
    services:
      gateway:
        image: stress
        entrypoint: stress
        command: --cpu 2
        cpuset: 0,1


Por fim, para definir um limite de uso em termos o uso de ciclos de cpu de um contêiner, deve-se utilizar o parâmetro "--cpuset-quota":

.. code-block:: bash

    $ docker run -it --rm --cpu-quota=50000 stress --cpu 4

Para uso via docker-compose, pode-se dispor o arquivo docker-compose.yml da seguinte maneira:

.. code-block:: yaml

    version: '2.2'
    services:
      stress:
        image: stress
        entrypoint: stress
        command: --cpu 4
        cpu_quota: 50000

No caso acima, o contêiner estará limitado a utilizar até 50% do total de processamento do sistema em ciclos; como nesse caso não houve a definição de afinidade, o provável comportamento será o aparecimento de 4 processos, com ~13% de uso de cpu cada.

.. note ::

    Demais informações acerca do controle de uso via quota para a CPU disponíveis em: https://www.kernel.org/doc/Documentation/scheduler/sched-bwc.txt
    
Memória
-------

O gerenciamento de uso do recurso de memória para um contêiner pode se dar em três níveis:

 * Quantidade de Memória RAM;
 * Quantidade de Uso de Swap;
 * **Reserva de Memória**.

Para definir a quantidade de memória RAM que um determinado contêiner pode utilizar, adiciona-se o parâmetro "--memory" seguido da quantidade e unidade:

.. code-block:: bash

    $ docker run -d --memory=1G --name httpd httpd
    $ docker update --memory=512M httpd

Para uso via docker-compose, pode-se dispor o arquivo docker-compose.yml da seguinte maneira:

.. code-block:: yaml

    version: '2.2'
    services:
      gateway:
        image: httpd
        mem_limit: 512M

A **reserva de memória** (que funciona na prática como um **soft limit**) funciona de forma que, quando o ambiente estiver saturado, o docker tentará fazer com que contêiner alvo utilize o valor de memória definido. Vide o exemplo abaixo:

.. code-block:: bash

    $ docker run -d --memory 1G --memory-reservation 100M --name httpd httpd

Para uso via docker-compose, pode-se dispor o arquivo docker-compose.yml da seguinte maneira:

.. code-block:: yaml

    version: '2.2'
    services:
      gateway:
        image: httpd
        mem_limit: 1g
        mem_reservation: 100mb


É interessante notar que, por padrão, o próprio Docker interromperá o funcionamento de um contêiner caso ele chegue ao topo de uso definido ou utilize toda a memória do sistema. A sintaxe para desabilitar o **oom-killer** para um determinado contêiner é:

.. code-block::  bash

    $ docker run -it --rm -m 200M --oom-kill-disable ubuntu:16:04

.. warning::

    É possível desabilitar esse comportamento para um contêiner, porém isso só é recomendável para o caso em que ele possua um limite de RAM; desabilitar o **OOM-KILLER** para um contêiner que não possui um limite definido poderá fazer com que o Administrador do servidor precise matar os processos do host manualmente para liberar memória.

Uso de Disco - **Throughput**
-----------------------------

O gerenciamento de uso do Disco para um contêiner pode se dar em três níveis:

 * Peso Relativo (Ver https://github.com/moby/moby/issues/16173);
 * Escrita e Leitura em bps (incluindo múltiplos);
 * Escrita e Leitura em Operações por segundo (IOPS).
 
A gerenciamento de recursos de disco através do docker somente funcionará de facto caso o *Scheduler* de IO do Kernel seja o CFQ. Para descobrir o *scheduler* em uso, utilize o seguinte comando:

.. code-block:: bash

    $ cat /sys/block/sda/queue/scheduler
    
Caso o scheduler não esteja definodo como CQF, utilize o seguinte comando para realizar a mudança:

.. code-block:: bash

    # echo cfq > /sys/block/sda/queue/scheduler


Para a definição de uso de recursos através do peso relativo, deve-se levar em conta os valores de 100 (mínimo, maior restrição) a 1000 (máximo, sem restrições). Para visualizar os resultados do teste a seguir será necessário abrir dois terminais; o primeiro conterá um contêiner cujo parâmetro **--blkio-weight** será 100 e o segundo 600. Os comandos a serem inseridos em cada terminal são:

.. code-block:: bash

    $ docker run -it --rm --blkio-weight 600 fedora sh -c 'time dd if=/dev/zero of=test.out bs=1M count=512 oflag=direct'
    $ docker run -it --rm --blkio-weight 100 fedora sh -c 'time dd if=/dev/zero of=test.out bs=1M count=512 oflag=direct'

Para uso via docker-compose, pode-se dispor o arquivo docker-compose.yml da seguinte maneira:

.. code-block:: yaml

    version: '2.2'
    services:
      fedora1:
        image: fedora
        command: sh -c 'time dd if=/dev/zero of=test.out bs=1M count=512 oflag=direct'
        blkio_config:
          weight: 600
          
      fedora2:
        image: fedora
        command: sh -c 'time dd if=/dev/zero of=test.out bs=1M count=512 oflag=direct'
        blkio_config:
          weight: 100

É possível ainda realizar a configuração do peso relativo para dispositivos presentes no sistema operacional, que sejam indiretamente ou diretamente utilizados pelo contêiner. Exemplo:

.. code-block:: bash

    $ docker run -it --rm --mount type=bind,source=/media/sdb,target=/mnt/rede --blkio-weight-device "/dev/sdb:500" fedora sh -c 'time dd if=/dev/zero of=/mnt/rede/test.out bs=1M count=512 oflag=direct'

Para uso via docker-compose, pode-se dispor o arquivo docker-compose.yml da seguinte maneira:

.. code-block:: yaml

    version: '2.2'
    services:
      fedora1:
        image: fedora
        command: sh -c 'time dd if=/dev/zero of=test.out bs=1M count=512 oflag=direct'
        blkio_config:
          weight_device:
           - path: /dev/sdb
             weight: 500


.. note::

    Assim como no caso do peso relativo da CPU, a "limitação" do uso somente ocorrerá caso outro processo ou contêiner não esteja a fazer uso intensivo do I/O.
    

.. warning::

    Mudar o **IO Scheduler** do Sistema Operacional pode ter consequências indesejáveis em algumas aplicações ou contêineres. Verifique junto ao fabricante da solução alvo possíveis problemas que podem ser causados quando do uso do CFQ como **IO Scheduler**.

A seguir, quando da utilização do gerenciamento via  **Escrita e Leitura em bps**, torna-se possível definir valores tanto para escrita quanto para a leitura. Os parâmetros utilizados para tanto são, respectivamente, "--device-read-bps" e "device-write-bps", que são utilizados em conjunto com o dispositivo ao quais os contêiner possuem acesso. Veja os exemplos abaixo:

.. code-block:: bash

    $ docker run -it --rm --device-write-bps /dev/sda:10mb fedora sh -c 'time dd if=/dev/zero of=test.out bs=1M count=512 oflag=direct'
    $ docker run -it --rm --device-read-bps /dev/sda:10mb fedora sh -c 'time dd if=/dev/zero of=test.out bs=1M count=512 oflag=direct'

Para uso via docker-compose, pode-se dispor o arquivo docker-compose.yml da seguinte maneira:

.. code-block:: yaml

    version: '2.2'
    services:
      fedora1:
        image: fedora
        command: sh -c 'time dd if=/dev/zero of=test.out bs=1M count=512 oflag=direct'
        blkio_config:
          device_write_bps:
           - path: /dev/sda
             rate: '10mb'
          device_read_bps:
           - path: /dev/sda
             rate: '10mb'
      fedora2:
        image: fedora
        command: sh -c 'time dd if=/dev/zero of=test.out bs=1M count=512 oflag=direct'
        blkio_config:
          device_write_bps:
           - path: /dev/sda
             rate: '5mb'
          device_read_bps:
           - path: /dev/sda
             rate: '5mb'

Por fim, é possível também realizar o gerenciamento de recursos baseados em operações por segundo (leitura ou escrita):

.. code-block:: bash

    $ docker run -it --rm --device-write-iops /dev/sda:20 fedora sh -c 'time dd if=/dev/zero of=test.out bs=1M count=512 oflag=direct'

Para uso via docker-compose, pode-se dispor o arquivo docker-compose.yml da seguinte maneira:

.. code-block:: yaml

    version: '2.2'
    services:
      fedora1:
        image: fedora
        command: sh -c 'time dd if=/dev/zero of=test.out bs=1M count=512 oflag=direct'
        blkio_config:
          device_write_iops:
           - path: /dev/sda
             rate: 20
      fedora2:
        image: fedora
        command: sh -c 'time dd if=/dev/zero of=test.out bs=1M count=512 oflag=direct'
        blkio_config:
          device_write_iops:
           - path: /dev/sda
             rate: 40

======================================================
Visualização de Recursos, Monitoramento & HealthChecks
======================================================

A visualização de uso de Recursos do docker pode ser realizado através do seguinte comando:

.. code-block:: bash

    $ docker stats
    $ docker stats --no-stream
    $ docker stats <CONTAINER>

Atualmente, algumas soluções do mercado já provêem suporte a estatísticas de funcionamento do docker, mas o CAdvisor destaca-se por ser uma aplicação criada pelo Google, simplista, que retorna as estatísticas de uso de recurso dos contêineres e do host.
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

Por outro lado, o monitoramento do contêiner pode ocorrer através : para o segundo caso, um recurso muito útil é de **HealthCheck**, onde o próprio contêiner passa a conter uma instrução de checagem, que é automaticamente executada em segundo plano e que, a depender do resultado, irá mudar a chave "{{ Status.Health }}" e até mesmo parar o contêiner.

Um exemplo de instrução de checagem pode ser visto abaixo:

``HEALTHCHECK --interval=5m --timeout=3s CMD curl -f http://localhost/ || exit 1``

=========
Segurança
=========

Além do fato dos processos serem isolados através de *CGROUPS*, o docker dispõe ainda do uso de outros mecanismos disponíveis em um kernel Linux tais como:

 * Posix Caps: disponível a partir da versão 2.2 do Kernel Linux, Posix Capabilities são divisões unitárias de permissões que um superusuário possui, que sendo atreladas a um binário, evitam a necessidade de uso do root ou bit de execução como outro usuário(setuid e setgid) . Ex: Utiliza-se apenas CAP_SYS_CHROOT para usar um chroot e CAP_SYS_NICE para mudar o prioridade de um processo ao invés de dar acesso como 'root' via setuid;
 * Seccomp: *Securing Compute Mode* é um recurso do kernel linux que permite restringir as chamadas do Kernel que podem ser executadas por um processo;
 * Apparmor: Módulo de segurança que tem por objetivo proteger o sistema operacional das aplicações. Comumente, o AppArmor possui um *profile* relacionada a cada aplicação a ser rodada com ações permitidas e proibidas. Padrão para o sistema Ubuntu e possui suporte disponível no Debian através da instalação do pacote de mesmo nome;
 * Selinux: *Secure Enhanced linux* ou *Selinux* é um módulo de segurança do Kernel que possui o mesmo objetivo do AppArmor: proteger o sistema operacional de ações danosas das aplicações. Padrão nas distribuições RedHat e seus derivados.

**O Docker já trabalha com configurações de PCAPS, SecComp e AppArmor/Selinux por padrão em todas as imagens, pois já trás vários desses *profiles* junto com sua instalação padrão.**

Posix Capabilities
------------------

O docker, por padrão, permite apenas uma pequena fatia de capabilities por padrão, como pode ser visto abaixo:

.. image:: ../data/default_pcaps.png

Capabilities são adicionadas ou removidas de um contêiner no momento de sua criação:

.. code-block:: bash

    $ docker run --cap-drop=NET_RAW --rm fedora bash

No exemplo acima, mesmo como root, não é possível utilizar o comando 'ping', pois o contêiner não possui a capability CAP_NET_RAW.

.. note::

    Uma lista completa de *capabilities* pode ser vista em ``man capabilities``.

