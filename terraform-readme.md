# Terraform Deployment – nginx Hello World auf AWS ECS

Dieses Verzeichnis (`terraform/`) erstellt die komplette Infrastruktur, um den nginx-Hello-World-Container
kostenoptimiert und öffentlich erreichbar auf **Amazon ECS (Fargate)** laufen zu lassen.

## Was wird erstellt?

- **VPC** mit 2 öffentlichen Subnetzen (in unterschiedlichen Availability Zones) und einem Internet Gateway
- **Amazon ECR**-Repository für das Docker-Image (inkl. Lifecycle-Policy, die nur die letzten 5 Images behält)
- **ECS-Cluster** mit **Fargate**-Task-Definition und -Service
- **Security Group**, die Port 80 aus dem Internet erlaubt
- **IAM-Rolle** für die ECS Task Execution (Image-Pull von ECR, Logs an CloudWatch)
- **CloudWatch Log Group** für die Container-Logs

## Kostenoptimierungen

Damit das Ganze so günstig wie möglich bleibt, wurden bewusst folgende Entscheidungen getroffen:

| Entscheidung | Ersparnis |
|---|---|
| **Kein NAT Gateway** – die Tasks laufen in öffentlichen Subnetzen und bekommen direkt eine öffentliche IP, dadurch ist kein NAT Gateway für ausgehenden Traffic (Image-Pull etc.) nötig | ca. 30+ USD/Monat |
| **Kein Application Load Balancer** – die Task-IP wird direkt angesprochen, statt über einen ALB | ca. 20+ USD/Monat Grundgebühr |
| **FARGATE_SPOT** statt regulärem Fargate | bis zu ~70 % günstiger |
| Kleinste Fargate-Größe (0.25 vCPU / 0.5 GB) | minimale Compute-Kosten |
| ECR-Lifecycle-Policy (max. 5 Images) | minimale Storage-Kosten |
| CloudWatch Log Retention von 3 Tagen | minimale Log-Kosten |

**Einschränkung:** Da kein Load Balancer verwendet wird, ändert sich die öffentliche IP-Adresse bei jedem Neustart
der Task (z. B. nach einem Deployment oder Spot-Interruption). Für eine Hello-World-Demo ist das ausreichend; für
eine produktive Anwendung mit stabiler URL sollte stattdessen ein Application Load Balancer bzw. Route 53 verwendet werden.

## Voraussetzungen

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- AWS CLI, lokal mit einem Benutzer/einer Rolle mit ausreichenden Rechten konfiguriert (`aws configure`)
- Docker (siehe [README.md](README.md) für den Build des Images)

## Deployment-Ablauf

### 1. Infrastruktur erstellen

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Terraform erstellt VPC, ECR-Repository, ECS-Cluster, Task-Definition und Service. Da das ECR-Repository zu diesem
Zeitpunkt noch leer ist, kann die ECS-Task noch nicht erfolgreich starten (`CannotPullContainerError`) – das ist
normal und wird im nächsten Schritt behoben. ECS versucht automatisch erneut, sobald ein Image vorhanden ist.

Am Ende gibt `terraform apply` die wichtigsten Werte aus, u. a.:

```
ecr_repository_url = "<ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/nginx-hello-world"
ecs_cluster_name    = "nginx-hello-world-cluster"
ecs_service_name    = "nginx-hello-world-service"
```

### 2. Docker-Image bauen und nach ECR pushen

Im Projekt-Wurzelverzeichnis (wo das `Dockerfile` liegt):

```bash
aws ecr get-login-password --region <REGION> \
  | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com

docker build -t nginx-hello-world .
docker tag nginx-hello-world:latest <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/nginx-hello-world:latest
docker push <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/nginx-hello-world:latest
```

`<ACCOUNT_ID>` und `<REGION>` entsprechen dem Terraform-Output `ecr_repository_url` bzw. `aws_region`.

Innerhalb weniger Minuten startet ECS die Task automatisch neu und zieht nun erfolgreich das Image.

### 3. Öffentliche IP-Adresse ermitteln und aufrufen (ohne Load Balancer)

Gilt, solange `enable_load_balancer = false` (Standard) ist. Soll die URL stabil bleiben, siehe Abschnitt
[„Feste URL (Application Load Balancer)“](#feste-url-application-load-balancer) weiter unten.

**Per AWS-Konsole:** ECS → Cluster → `nginx-hello-world-cluster` → Service → Tab **Tasks** → laufende Task öffnen →
Abschnitt **Network** zeigt die **Public IP**.

**Per AWS CLI:**

```bash
TASK_ARN=$(aws ecs list-tasks --cluster nginx-hello-world-cluster \
  --service-name nginx-hello-world-service --query "taskArns[0]" --output text)

ENI_ID=$(aws ecs describe-tasks --cluster nginx-hello-world-cluster --tasks "$TASK_ARN" \
  --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value" --output text)

aws ec2 describe-network-interfaces --network-interface-ids "$ENI_ID" \
  --query "NetworkInterfaces[0].Association.PublicIp" --output text
```

Die ausgegebene IP im Browser aufrufen:

```
http://<PUBLIC_IP>
```

### 4. Neues Image deployen (Update)

```bash
docker build -t nginx-hello-world .
docker tag nginx-hello-world:latest <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/nginx-hello-world:latest
docker push <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/nginx-hello-world:latest

aws ecs update-service --cluster nginx-hello-world-cluster \
  --service nginx-hello-world-service --force-new-deployment
```

(Die öffentliche IP ändert sich dabei, siehe Einschränkung oben.)

### 5. Aufräumen

```bash
cd terraform
terraform destroy
```

Entfernt alle erstellten Ressourcen (VPC, ECS, ECR inkl. Images durch `force_delete`, IAM-Rolle, Logs) und stoppt
damit sämtliche laufenden Kosten.

## Anpassen

Wichtige Parameter lassen sich über Variablen überschreiben, z. B. in einer `terraform.tfvars`-Datei
(wird durch `.gitignore` nicht versioniert) oder per CLI-Flag:

```bash
terraform apply -var="aws_region=eu-west-1" -var="project_name=mein-projekt"
```

Siehe [terraform/variables.tf](terraform/variables.tf) für alle verfügbaren Variablen.

## Bestehende VPC verwenden

Standardmäßig legt Terraform eine neue VPC mit öffentlichen Subnetzen an. Soll stattdessen eine bereits
vorhandene VPC genutzt werden, einfach `vpc_id` und `public_subnet_ids` setzen – in dem Fall werden
`aws_vpc`, `aws_internet_gateway`, `aws_subnet` und die Route-Table **nicht** erstellt:

```bash
terraform apply \
  -var="vpc_id=vpc-0123456789abcdef0" \
  -var='public_subnet_ids=["subnet-0111111111111111", "subnet-0222222222222222"]'
```

Oder in einer `terraform.tfvars`-Datei:

```hcl
vpc_id            = "vpc-0123456789abcdef0"
public_subnet_ids = ["subnet-0111111111111111", "subnet-0222222222222222"]
```

**Voraussetzungen an die angegebenen Subnetze** (sonst ist die Task nicht aus dem Internet erreichbar):

- Sie müssen in der angegebenen VPC liegen.
- Sie müssen "öffentlich" sein, d. h. ihre Route Table benötigt eine Route `0.0.0.0/0` auf ein Internet Gateway.
- Idealerweise mindestens 2 Subnetze in unterschiedlichen Availability Zones für Ausfallsicherheit.

`public_subnet_cidrs` und `vpc_cidr` werden in diesem Fall ignoriert.

## Feste URL (Application Load Balancer)

Ohne Load Balancer ändert sich die öffentliche IP bei jedem Neustart der Task (siehe Einschränkung oben). Für eine
dauerhaft gleichbleibende URL kann ein Application Load Balancer (ALB) vorgeschaltet werden:

```bash
terraform apply -var="enable_load_balancer=true"
```

Das schaltet um:

- Ein ALB mit eigener Security Group wird erstellt und nimmt den Traffic auf Port 80 aus dem Internet entgegen.
- Die Container-Security-Group erlaubt eingehenden Traffic **nur noch vom ALB**, nicht mehr direkt aus dem Internet
  (zusätzlicher Sicherheitsgewinn).
- Der ECS-Service registriert seine Tasks automatisch an einer Target Group, die vom ALB per Health-Check (`GET /`)
  überwacht wird.
- Terraform gibt im Output `alb_dns_name` die feste DNS-URL aus, z. B.:

  ```
  alb_dns_name = "nginx-hello-world-alb-123456789.eu-central-1.elb.amazonaws.com"
  ```

  Diese URL bleibt auch nach Neustarts, Deployments oder Spot-Interruptions der Task gleich und kann im Browser
  aufgerufen werden: `http://<alb_dns_name>`.

**Voraussetzung:** mindestens 2 Subnetze in unterschiedlichen Availability Zones (Standard bei neu erstellter VPC;
bei einer bestehenden VPC über `public_subnet_ids` sicherstellen).

**Kosten:** Ein ALB kostet eine Grundgebühr von ca. 16–20 USD/Monat zzgl. LCU-Nutzung – für eine reine Demo ohne
feste URL kann diese Option daher auch deaktiviert bleiben (Standard: `enable_load_balancer = false`).

