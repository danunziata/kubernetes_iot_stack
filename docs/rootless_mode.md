# Modo Rootless

Un contenedor root es un contenedor que se ejecuta con privilegios de root, lo que significa que tiene acceso a todos los recursos del sistema y puede realizar cambios en el sistema host subyacente. Estos contenedores tienen control total sobre el sistema operativo y pueden realizar cualquier operación sin restricciones, lo que los hace muy versátiles pero también potencialmente peligrosos. Son comúnmente utilizados en entornos de desarrollo donde los desarrolladores necesitan acceso sin restricciones al sistema para depurar o probar sus aplicaciones.

Por otro lado, un contenedor sin root (rootless) se ejecuta sin privilegios de root, lo que significa que tiene acceso limitado a los recursos del sistema y no puede hacer cambios en el sistema host subyacente. Estos contenedores están diseñados para ser más seguros y aislados, ya que operan dentro de un espacio de nombres de usuario y no tienen acceso a recursos del sistema fuera de su propio espacio de nombres. Son comúnmente utilizados en entornos de producción donde la seguridad es una prioridad y es necesario prevenir el acceso no autorizado a los recursos del sistema.

Ambos tipos de contenedores tienen sus ventajas y desventajas. Los contenedores root ofrecen más flexibilidad y control, pero conllevan más riesgos, mientras que los contenedores rootless proporcionan mayor seguridad y aislamiento, aunque son más limitados en sus capacidades.

El modo rootless en kubernetes permite ejecutar servidores como un usuario sin privilegios, con el fin de proteger al root real en el host de posibles ataques de escape de contenedores. Esta implementacion realizada con k3s cuenta con algunas limitaciones conocidas.

## Limitaciones

- Puertos

Cuando se ejecuta en modo rootless, se crea un nuevo espacio de nombres de red. Esto significa que la instancia de K3s se ejecuta con una red bastante separada del host. La única forma de acceder a los Servicios que se ejecutan en K3s desde el host es configurar reenvíos de puertos al espacio de nombres de red de K3s. K3s rootless incluye un controlador que enlazará automáticamente el puerto 6443 y los puertos de servicios por debajo de 1024 al host con un desplazamiento de 10000.

Por ejemplo, un Servicio en el puerto 80 se convertirá en 10080 en el host, pero 8080 se mantendrá en 8080 sin ningún desplazamiento. Actualmente, solo los Servicios LoadBalancer se enlazan automáticamente.

- Cgroup

Cgroup v1 y el modo híbrido v1/v2 no son compatibles; solo se admite Cgroup v2 puro. Si K3s no logra iniciarse debido a la falta de cgroups cuando se ejecuta en modo rootless, es probable que tu nodo esté en modo híbrido, y los cgroups "faltantes" aún estén enlazados a un controlador v1.

- Cluster Multinodo

Actualmente, los clústeres rootless multinodo o múltiples procesos rootless de K3s en el mismo nodo no son compatibles hasta el momento de escribir esta documentación.

## Implementación

Empezaremos descargando los scripts necesarios para instalar k3s y su servicio en modo rootless

```sh
$ curl https://get.k3s.io --output install.sh
$ sudo chmod +x install.sh
$ wget https://raw.githubusercontent.com/k3s-io/k3s/master/k3s-rootless.service
$ mkdir -p ~/.config/systemd/user/
$ cp k3s-rootless.service ~/.config/systemd/user/k3s-rootless.service
```

Para poder permitir el intercambio de paquetes desde el namespace del host y el namespace del servidor root, colocaremos las siguientes variables de entorno que nos habilita el uso de slirp4netns

```
[Service]
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=K3S_ROOTLESS_CIDR="10.41.0.0/16"
Environment=K3S_ROOTLESS_PORT_DRIVER=slirp4netns
Environment=K3S_ROOTLESS_DISABLE_HOST_LOOPBACK=true
Environment=K3S_ROOTLESS_MTU=1500
```

Colocaremos un par de variables que nos habilitara el forwarding de puertos

```sh
$ sudo vi /etc/sysctl.conf
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
```

Instalamos la libreria uidmap que se encarga de la separacion de namespace como asi tambien el cgroupv2

```sh
$ sudo apt update
$ sudo apt install uidmap
$ sudo cat /etc/default/grub
---
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=1"
---

$ sudo update-grub
$ sudo mkdir -p /etc/systemd/system/user@.service.d
$ cat <<EOF | sudo tee /etc/systemd/system/user@.service.d/delegate.conf
[Service]
Delegate=cpu cpuset io memory pids
EOF

$ sudo systemctl daemon-reload
```

Ejecutaremos la instalacion de k3s y reiniciaremos el host para que se apliquen los cambios

```sh
$ sudo INSTALL_K3S_COMMIT=2eddfe6cf4e67b7d6aab0fe8311d72372030459e INSTALL_K3S_SKIP_ENABLE=true ./install.sh
$ sudo reboot
```

Cuando el equipo este listo, arrancamos el servicio y observamos el buen funcionamiento

```sh
$ sudo sysctl -p
$ systemctl --user enable --now k3s-rootless
$ systemctl --user status k3s-rootless
```

Con todo esto seria suficiente para tener un servidor k3s en modo rootless corriendo, acordarse de declarar el KUBECONFIG de este cluster con

```sh
export KUBECONFIG= ~/.kube/k3s.yaml
```

