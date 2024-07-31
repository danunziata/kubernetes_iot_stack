## Control de Acceso

El Control de Acceso Basado en Roles (RBAC, por sus siglas en inglés) es el mecanismo de autorización principal en Kubernetes y se encarga de los permisos sobre los recursos. Estos permisos combinan verbos (get, create, delete, etc.) con recursos (pods, services, nodes, etc.) y pueden estar limitados a un namespace o ser a nivel de clúster. Se proporcionan una serie de roles predeterminados que ofrecen una separación razonable de responsabilidades dependiendo de las acciones que un cliente pueda querer realizar. Configurar RBAC con la aplicación del principio de privilegio mínimo es un desafío por las razones que exploraremos a continuación.

Cuando un sujeto como una ServiceAccount, Usuario o Grupo tiene acceso al "superusuario" integrado de Kubernetes llamado cluster-admin, pueden realizar cualquier acción sobre cualquier recurso dentro de un clúster. Este nivel de permiso es especialmente peligroso cuando se utiliza en un ClusterRoleBinding, ya que otorga control total sobre todos los recursos en todo el clúster. cluster-admin también puede ser utilizado como RoleBinding, lo cual también puede representar un riesgo significativo.

Para reducir el riesgo de que un atacante abuse de las configuraciones de RBAC (Control de Acceso Basado en Roles), es importante analizar continuamente las configuraciones y asegurarse de que siempre se aplique el principio de privilegio mínimo. A continuación, se presentan algunas recomendaciones:

- Reducir el acceso directo al clúster por parte de los usuarios finales cuando sea posible.
- No utilizar tokens de Cuenta de Servicio fuera del clúster.
- Evitar montar automáticamente el token de la cuenta de servicio por defecto.
- Auditir el RBAC incluido con los componentes de terceros instalados.
- Implementar políticas centralizadas para detectar y bloquear permisos de RBAC riesgosos.
- Utilizar RoleBindings para limitar el alcance de los permisos a espacios de nombres específicos en lugar de políticas RBAC para todo el clúster.

Estas prácticas ayudarán a fortalecer la seguridad y mitigar los riesgos asociados con la configuración de RBAC en entornos Kubernetes.

### Creación de Usuarios

Como ejemplo vamos a crear un usuario viewer que solamente tenga acceso a los recursos pods y services de nuestro cluster, pero solamente para usar get, list o watch.

Empezamos creando un certificado de usuario con openssl ```

```bash
openssl genrsa -out viewer.key 2048
```

Seguimos creando una solicitud de firma del certificado de usuario

```sh
openssl req -new -key viewer.key -out viewer.csr -subj "/CN=viewer/O=rbac"
```

Hasta ahora, el usuario ha generado un certificado que lo identifica y ha creado el fichero con la solicitud de firma del certificado.

Para realizar las siguientes acciones es necesario tener acceso a la clave privada de la entidad certificadora (*CA*) de Kubernetes, por lo que debe realizarlos un administrador del clúster. En K3s los certificados de la entidad certificadora del clúster se encuentran en `/var/lib/rancher/k3s/server/tls/`. A diferencia de lo que sucede en Kubernetes, en K3s tenemos un par de claves para la firma de certificados de usuario `client-ca.crt` y `client-ca.key` 

Para realizar la firma del certificado de usuario, usamos el par de claves `client-ca.*`:

```sh
openssl x509 -req -in viewer.csr -out viewer.crt -CA client-ca.crt -CAkey client-ca.key -CAcreateserial -days 365
```

Para que el usuario pueda acceder al clúster usando un cliente como `kubectl`, generamos un fichero `kubeconfig` (aunque podemos añadir la misma información a un fichero `kubeconfig` existente)

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: <cat server-ca.crt | base64 -w0>
    server: https://<ip del cluster>:6443
  name: default
contexts:
- context:
    cluster: default
    user: viewer
    namespace: default
  name: viewer-rbac
current-context: viewer-rbac
kind: Config
preferences: {}
users:
- name: viewer
  user:
    client-certificate-data: <cat fede.crt | base64 -w0>
    client-key-data: <cat fede.key | base64 -w0>
```

Creamos un role que especifica qué acciones (verbs) se pueden realizar sobre los elementos de la API (los recursos).

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: tcp-ip
  name: viewer
rules:
- apiGroups: [''] # '' indicates the core API group
  resources: ['pods', 'services']
  verbs: ['get', 'watch', 'list']
```

Para asignar los permisos especificados en el *Role* a un usuario, usamos un *RoleBinding* (o un *ClusterRoleBinding*):

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: tcp-ip
  name: viewer
subjects:
- kind: User
  name: viewer
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: viewer
  apiGroup: rbac.authorization.k8s.io
```

Con todas las configuraciones hechas, aplicamos los cambios

```sh
kubectl apply -f role.yaml
kubectl apply -f role-binding.yaml
export KUBECONFIG=kubeconfig
```
