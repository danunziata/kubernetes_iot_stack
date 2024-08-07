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

## Vault

HashiCorp Vault es una herramienta de gestión de secretos que se utiliza para controlar el acceso a secretos sensibles, como tokens de API, contraseñas, certificados y claves de cifrado. Aquí hay una breve descripción de cómo funciona Vault:

1. **Almacenamiento Seguro de Secretos**: Vault permite almacenar secretos en un almacenamiento seguro y centralizado. Los secretos pueden ser estáticos (como contraseñas) o dinámicos (como tokens de acceso que expiran después de un tiempo).

2. **Autenticación**: Los usuarios y aplicaciones deben autenticarse antes de acceder a los secretos. Vault admite múltiples métodos de autenticación, como LDAP, GitHub, tokens, y métodos de autenticación de nube como AWS IAM.

3. **Control de Acceso**: Vault utiliza políticas para controlar quién puede acceder a qué secretos. Las políticas definen qué operaciones (lectura, escritura, borrado) están permitidas en qué caminos dentro del almacenamiento de secretos.

4. **Rotación de Secretos**: Vault puede rotar automáticamente los secretos, como contraseñas de bases de datos, a intervalos regulares para mejorar la seguridad. Esto ayuda a minimizar el riesgo de exposición a largo plazo.

5. **Auditoría**: Vault mantiene un registro de auditoría detallado de todas las operaciones que se realizan, proporcionando visibilidad y rastreo de acceso a los secretos.

6. **Cifrado**: Todos los datos almacenados en Vault están cifrados tanto en tránsito como en reposo. Vault utiliza algoritmos de cifrado fuertes para proteger los datos sensibles.

7. **Almacenamiento Dinámico de Credenciales**: Vault puede generar credenciales temporales bajo demanda para servicios como bases de datos y nubes. Esto reduce la necesidad de gestionar credenciales estáticas.

8. **API**: Vault proporciona una API RESTful que permite a las aplicaciones interactuar con Vault para gestionar secretos de manera programática.

### Implementación

El clúster de servidores Vault se puede implementar directamente en Kubernetes mediante Helm Charts (recomendado). Además de los pods Stateful de Vault, el inyectador de agentes de Vault también se ejecuta como un pod que aprovecha el webhook de admisión mutable de Kubernetes para interceptar pods que definen anotaciones específicas e inyectar un contenedor del agente Vault para gestionar estos secretos. Esto puede ser utilizado por aplicaciones que se ejecutan dentro de Kubernetes, así como por aplicaciones externas a Kubernetes.

Un token de cuenta de servicio (token JWT) del pod se pasa al servidor Vault. El servidor Vault se autentica contra Kubernetes a través de la API TokenReview para obtener la cuenta de servicio y el namespace asociados al token JWT. El servidor de la API de Kubernetes devuelve los detalles de la cuenta y, a partir de ahí, el servidor Vault valida si la cuenta de servicio está autorizada para leer secretos utilizando las políticas adjuntas. Después de una validación exitosa, el servidor Vault devuelve un token. En una llamada de API posterior, se incluye el token de Vault para recuperar los secretos.

Comenzamos instalando Vault a traves del Helm Chart oficial

```sh
$ helm repo add hashicorp https://helm.releases.hashicorp.com
"hashicorp" has been added to your repositories
$ helm repo update
Hang tight while we grab the latest from your chart repositories......Successfully got an update from the "hashicorp" chart repositoryUpdate Complete. ⎈Happy Helming!⎈
$ helm install vault hashicorp/vault --set "server.dev.enabled=true"
```

La opción `server.dev.enabled=true` configura Vault en modo de desarrollo para mayor simplicidad. Para implementaciones en producción, necesitarás configurar Vault según tus requisitos de seguridad y operativos.

De esta manera, El pod Vault y el agente de inyeccion de Vault se ejecutaran en nuestro cluster.

```
$ kubectl get pods
NAME                                    READY   STATUS    RESTARTS   AGE
vault-0                                 1/1     Running   0          18s
vault-agent-injector-5989b47887-x86dd   1/1     Running   0          19s
```

Vamos a crear un secreto de ejemplo para una conexión a una base de datos Postgres.

Activaremos el motor de secretos kv-2 y pondremos un usuario y contraseña en el path `demo/database/config`.

```sh
$ kubectl exec -it vault-0 -- sh
$ vault secrets enable -path=demo kv-v2
$ vault kv put demo/database/config username=postgres
```

Las políticas de acceso en Vault determinan qué secretos puede acceder una entidad autenticada y qué operaciones pueden realizar en esos secretos. Creamos una política que especifique el nivel de acceso a los secretos.

```sh
$ vault policy write demo-policy - <<EOF
path "demo/data/database/config" {
  capabilities = ["read"]
}
EOF
```

El método de autenticación de Kubernetes de Vault permite a los pods autenticarse utilizando sus tokens de Cuenta de Servicio de Kubernetes, habilitando el acceso seguro a los secretos almacenados en Vault.

Por eso, habilitamos el método de autenticación de Kubernetes dentro de Vault. Este paso activa el backend de autenticación necesario para que los pods de Kubernetes se autentiquen con Vault.

```sh
$ vault auth enable kubernetes
```

Vault necesita detalles sobre tu clúster de Kubernetes para verificar los tokens de Cuenta de Servicio utilizados para la autenticación. Esto incluye el token JWT de una cuenta de servicio que tenga permisos para verificar otros tokens, el host de la API de Kubernetes y el certificado CA del clúster.

```sh
$ vault write auth/kubernetes/config \    
 token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \    kubernetes_host=https://${KUBERNETES_PORT_443_TCP_ADDR}:443 \    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```

Después de crear las políticas de acceso, debes vincularlas a entidades específicas de Kubernetes, como cuentas de servicio o namespaces. Esta vinculación asegura que solo las aplicaciones autorizadas puedan acceder a los secretos especificados.

```sh
$ vault write auth/kubernetes/role/demo-auth \
    bound_service_account_names=demo-user \
    bound_service_account_namespaces=default \
    policies=demo-policy \
    ttl=24h
```

El rol conecta la cuenta de servicio de Kubernetes, demo-user, y el namespace, default, con la política de Vault, demo-policy. Los tokens devueltos después de la autenticación son válidos por 24 horas.

Claro, aquí tienes la traducción al español:

Vamos a crear una cuenta de servicio de Kubernetes llamada demo-user en el namespace default, como se indica en la política de Vault:

```sh
$ kubectl create serviceaccount demo-user
```

Y por ultimo, para fines demostrativos, desplegamos PostgreSQL como un StatefulSet e inyectamos el secreto.

```yaml
# postgres.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: psql-svc
  replicas: 1
  updateStrategy:
    type: RollingUpdate
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "demo-auth"
        vault.hashicorp.com/agent-inject-secret-pgpass: "demo/data/database/config"
        vault.hashicorp.com/agent-inject-template-pgpass: |
          {{- with secret "demo/data/database/config" -}}
          localhost:5432:postgres:{{ .Data.data.username }}:{{ .Data.data.password }}
          {{- end -}}
    spec:
      terminationGracePeriodSeconds: 10
      serviceAccountName: demo-user
      initContainers:
      containers:
        - name: postgres
          image: postgres:10.1
          imagePullPolicy: Always
          ports:
            - containerPort: 5432
          env:
            - name: PGDATA
              value: /var/lib/postgresql/data/pgdata
          volumeMounts:
            - name: postgredb
              mountPath: /var/lib/postgresql/data
              readOnly: false
      volumeClaimTemplates:
        - metadata:
            name: postgredb
          spec:
            accessModes: [ "ReadWriteOnce" ]
            storageClassName: gp2
            resources:
              requests:
                storage: 3Gi
```



Explicación:

**agent-inject** habilita el servicio Vault Agent Injector.
**role** es el rol de autenticación de Kubernetes de Vault.
**agent-inject-secret-FILEPATH** define la ruta del archivo pgpass escrito en el directorio /vault/secrets. El valor es la ruta al secreto definido en Vault.
**agent-inject-template-FILEPATH** define el archivo y la plantilla del agente Vault que se aplica a los datos del secreto.

Lo que ocurre en realidad es que las anotaciones precedentes (prefijadas con vault.hashicorp.com) indican al pod vault-agent-injector, a través de una configuración de webhook mutable predefinida, que inyecte un contenedor init llamado vault-agent-init y un contenedor sidecar llamado vault-agent, así como un volumen de tipo emptyDir llamado vault-secrets. Además, el volumen vault-secrets se monta en el contenedor init, el contenedor sidecar y el contenedor de la aplicación con el directorio /vault/secrets/. El secreto se almacena en el volumen vault-secrets.

Aplicamos el manifiesto y esperamos a que este corriendo con los 2/2 pods listos para poder asi obtener los secrets dentro de la base de datos

```sh
$ kubectl apply -f postgres.yaml
$ kubectl exec -it postgres-0 -c postgres -- sh
$ cat /vault/secrets/pgpass
localhost:5432:postgres:postgres:pass123
```

# Referencias

https://medium.com/@pratyush.mathur/secrets-management-using-vault-in-k8s-272462c37fd8

https://overcast.blog/managing-secrets-in-kubernetes-with-hashicorp-vault-39de290d3c46