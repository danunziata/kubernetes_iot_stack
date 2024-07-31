## Vulnerabilidades en la Cadena de Aprovisionamiento

Los contenedores adoptan muchas formas en diferentes fases del ciclo de vida de la cadena de suministro del desarrollo; cada una de ellas presenta desafíos de seguridad únicos. Un solo contenedor puede depender de cientos de componentes y dependencias de terceros, lo que hace que la confianza en el origen en cada fase sea extremadamente difícil. Estos desafíos incluyen, pero no se limitan a, la integridad de la imagen, la composición de la imagen y las vulnerabilidades de software conocidas.

### Aspectos a tener en cuenta

- Integridad de la Imagen: La procedencia del software ha atraído recientemente una atención significativa en los medios debido a eventos como la brecha de SolarWinds y una variedad de paquetes de terceros comprometidos. Estos riesgos de la cadena de suministro pueden surgir en varias etapas del ciclo de construcción del contenedor, así como en tiempo de ejecución dentro de Kubernetes. Cuando no existen sistemas de registro respecto a los contenidos de una imagen de contenedor, es posible que un contenedor inesperado se ejecute en un clúster.
- Composición de la Imagen: Una imagen de contenedor consta de capas, cada una de las cuales puede presentar implicaciones de seguridad. Una imagen de contenedor bien construida no solo reduce la superficie de ataque, sino que también puede aumentar la eficiencia de la implementación. Las imágenes con software innecesario pueden ser utilizadas para elevar privilegios o explotar vulnerabilidades conocidas.
- Vulnerabilidades de Software Conocidas: Debido a su uso extensivo de paquetes de terceros, muchas imágenes de contenedores son inherentemente peligrosas para ser incorporadas en un entorno de confianza y ejecutadas. Por ejemplo, si una capa en una imagen contiene una versión de OpenSSL susceptible a una explotación conocida, esta puede propagarse a varias cargas de trabajo y, sin saberlo, poner en riesgo todo un clúster.

### Grype

Existen muchas herramientas en el mercado (tanto comerciales como de código abierto) que ofrecen escaneo de vulnerabilidades. Recientemente, encontré una herramienta de escaneo de vulnerabilidades muy ligera y ordenada, llamada Grype, gestionada por Anchore.

Grype permite identificar y reportar vulnerabilidades conocidas en imágenes de contenedores, directorios y archivos individuales. Es particularmente útil para desarrolladores y equipos de seguridad que buscan asegurar sus aplicaciones y entornos de despliegue.

#### Instalación

Para instalar grype, alcanza con ejecutar y descargar el binario

```sh
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sudo sh -s -- -b /usr/local/bin
```

#### Uso

Grype puede escanear imagenes provenientes de multiples fuentes ademas de Docker

```sh
# Escanea un archivo de imagen de contenedor(proveniente de `docker image save ...`, `podman save ...`)
grype path/to/image.tar

# Escanea un directorio
grype dir:path/to/dir

# Ejemplo: Escanea la ultima imagen de Grafana disponible
grype docker:grafana/grafana:latest  
```

## 