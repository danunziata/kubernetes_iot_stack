# Stack de IoT para Kubernetes

En este proyecto, adaptaremos el [proyecto original](https://danunziata.github.io/Aplicaciones_TCP_IP/03-Proyecto_Final/proyecto_final/) desarrollado por los alumnos de Aplicaciones TCP/IP de la Universidad Nacional de Río Cuarto. Este proyecto consta de una plataforma del lado del servidor para gestionar y visualizar datos de series temporales en entornos IoT, enfocándose en la captura, almacenamiento y presentación eficiente de datos como temperatura, humedad, corriente y tensión, utilizando tecnologías específicas para asegurar su funcionamiento en tiempo real.

El stack original está implementado con Docker Compose. Nuestro trabajo consiste en adaptarlo a una tecnología de orquestador de contenedores llamada Kubernetes, lo cual permitirá una gestión más eficiente y escalable de los servicios y aplicaciones. Además, añadiremos reglas de automatización mediante CI/CD usando Jenkins.

También incorporaremos prácticas de seguridad en el desarrollo y despliegue para asegurar la integridad y confidencialidad de los datos gestionados por la plataforma. Estos avances permitirán una mayor resiliencia, escalabilidad y seguridad en la plataforma.

## Pre-Instalación

Para poder ejecutar la instalación debemos primero cargar ciertos programas

### Helm

```sh
$ curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
$ chmod 700 get_helm.sh
$ ./get_helm.sh
```

