# Secretos

En las aplicaciones, un 'secret' es un dato sensible que se utiliza en la aplicación y que requiere un 'nivel implícito de seguridad' para proteger dichos secretos, por ejemplo: contraseñas, claves y tokens, entre otros. 

Desde la perspectiva del desarrollo de aplicaciones, normalmente se sigue algún principio de diseño; el principio de diseño más defendido es "Mantener un bajo grado de acoplamiento y un alto grado de cohesión", lo que significa reducir las dependencias al escribir código entre componentes. Para adoptar este principio de diseño, las configuraciones se externalizan del código y se guardan en archivos planos separados llamados 'archivos de configuración', como: YAML, properties, archivos conf, etc. Esta externalización de la configuración también trae consigo la idea de almacenar los secretos aparte del código.

Al igual que los Vaults, Kubernetes (también llamado K8s) proporciona un objeto para almacenar secretos opacos, certificados y claves privadas. Sin embargo, no se considera tan seguro en comparación con los vaults especializados porque los secretos de Kubernetes se almacenan por defecto sin cifrar en el almacén de datos subyacente del servidor API (etcd). Cualquier persona con acceso a la API puede recuperar y modificar un secreto de Kubernetes. Además, estos secretos pueden ser utilizados por diferentes objetos como Pods (montándolos en rutas similares a Kubernetes ConfigMap).

En Kubernetes, los objetos (objetos de K8s como ConfigMap, Secrets, Deployment, Pod, etc.) se crean mediante configuraciones declarativas basadas en YAML. Y las herramientas de gestión de código fuente (SCM) como Git, SVN, etc., se utilizan para almacenar el código fuente y las configuraciones declarativas (por ejemplo, YAMLs de K8s) del código fuente de la aplicación para mantener el control de versiones, el intercambio de código, la liberación y el etiquetado. En este caso, la configuración declarativa (YAML de K8s) para crear secretos de Kubernetes también necesita ser almacenada en el SCM. Esto expondrá el 'secreto' a todos los usuarios que tengan acceso al código en el SCM.

Para resolver este requisito, Bitnami Lab proporciona una utilidad llamada 'SealedSecret y Kubeseal'. SealedSecret / Kubeseal y su caso de uso se discuten en la siguiente sección.

## KubeSeal

SealedSecret y Kubeseal son una extensión de Kubernetes Secret creada por Bitnami Labs como parte del componente Sealed-Secret. Añade una capa adicional de cifrado a la configuración declarativa YAML del secreto, que luego puede almacenarse en cualquier herramienta de gestión de código fuente (SCM). El acceso inmediato no obtendrá el valor real del secreto al leerlo.

El Sealed-Secret se instala en el clúster de Kubernetes y gestiona el flujo de cifrado de secretos. El flujo es muy sencillo: cifra el secreto y crea un nuevo objeto de Kubernetes llamado SealedSecret.

**SealedSecret:** Un SealedSecret es un objeto en Kubernetes (disponible una vez que se instala Bitnami Labs Sealed-Secret) que es una extensión de K8s Secret y que almacena secretos cifrados.

#### Implementación

instalar la utilidad kubeseal desde donde deseas conectarte al clúster de Kubernetes, idealmente en la misma máquina donde está instalado kubectl

```sh
KUBESEAL_VERSION='0.26.0'
curl -OL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION:?}/kubeseal-${KUBESEAL_VERSION:?}-linux-amd64.tar.gz"
tar -xvzf kubeseal-${KUBESEAL_VERSION:?}-linux-amd64.tar.gz kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```

Bitnami Labs ha proporcionado un paquete Helm para instalar **SealedSecret**. Para instalar SealedSecret en el clúster de K8s, utilizaremos el gestor de paquetes Helm.

```sh
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update
helm install sealed-secrets -n kube-system --set-string fullnameOverride=sealed-secrets-controller sealed-secrets/sealed-secrets
```

Con los componentes instalados, creamos un secret de ejemplo con el nombre `ejemplo.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  creationTimestamp: null
  name: ejemplo
data:
  ejemplo: ZWplbXBsbw==
```

Convertimos nuestro secret a un SealedSecret

```sh
kubeseal --controller-name=sealed-secrets-controller --controller-namespace=kube-system --format yaml --secret-file ejemplo.yaml > mysealedsecret-ejemplo.yaml
```

Creará un archivo llamado `mysealedsecret-ejemplo.yaml` con el siguiente contenido (el YAML declarativo para SealedSecret):

```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  creationTimestamp: null
  name: ejemplo
  namespace: default
spec:
  encryptedData:
    ejemplo: AgBNeeDOIJGmS6j49Mw0PYLsPh2jjiFKLlIVGc0j6l7aNrA6K0K+MJYTAlf1QZHNAmfG9h/wSzbRbBwSbnoewO6v9uPtiF/E1VWuIIN7yh6FJCykQcd+Yfk2Tw/ToQz7YnNq6tBG0melnE0itBn1PrBFFCfYMMldc0vq8u9iHEAe0bIlfQIvZV17ZrskzQgOBnGV03bNlI+VWGtxNT+he+98tZNW9wujEhlF0X66OWuqIvZpH7eJMeumYVBjBJmbltD1bozpJFJM8mu8+ZoUtxLVMwNOdwOGjMdTB8UFOhHh/ByG0ups15EAADCIOTaal+BNOKYXWbvYTUGhPBeanTYO9Z0Skv+prPhNNDAhBuNQGIX6+kXp+O+rdqOmnejnKFdpgWR4cdsFpguW8HplgmvyTVc+snkihV+nStqLXBxLpbTuVASfFSe9Om47/Mv7/Slf1wb+/+7kP9Sh7O+zIEDLzBuXdLy62IYiI6upGOCVOVenK1CNV1I/dwDWFR5mk82mVHT1dwUmYXQibtlfUVlQmrWgseeDIC9zbmc5Y6Xp2zuzJPWZMmmfjUscUbuojnBKTeJw7weDeoiM5eL4QaQyPvqqX5m0WvrWopYU7obAhF/UfMVwl9IwhygZSVEvRfIFQPAg7XNBwyqgGh5qyuh95P3RE0wOW+xvdfUjeb8y1txdT09b6u/7bcAzXbV9GK2WopUrGvuq
  template:
    metadata:
      creationTimestamp: null
      name: ejemplo
      namespace: default
```

Ahora, tenemos el archivo YAML declarativo de SealedSecret que se puede usar para crear un SealedSecret en K8s.

```sh
kubectl apply -f mysealedsecret-ejemplo.yaml
```

De esta forma el cluster desencripta el secret y lo coloca en el cluster de Kubernetes