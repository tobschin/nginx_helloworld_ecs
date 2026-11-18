# nginx Hello World Docker Container

Ein minimaler nginx-Container, der eine statische "Hello World"-Seite ausliefert.

## Projektstruktur

```
.
├── Dockerfile
├── html/
│   └── index.html
└── README.md
```

## Lokal bauen und ausführen

1. Docker Image bauen (im Projektverzeichnis ausführen):

   ```bash
   docker build -t nginx-hello-world .
   ```

2. Container starten (Port 80 im Container wird auf Port 8080 lokal gemappt):

   ```bash
   docker run -d --name nginx-hello-world -p 8080:80 nginx-hello-world
   ```

3. Im Browser aufrufen:

   ```
   http://localhost:8080
   ```

4. Container stoppen und entfernen:

   ```bash
   docker stop nginx-hello-world
   docker rm nginx-hello-world
   ```

## Deployment nach AWS ECS (Fargate) über die AWS-Konsole – "Express"-Methode

Mit der vereinfachten Deploy-Methode in der ECS-Konsole ("Create" / "Deploy a container") kannst du mit wenigen Klicks Cluster, Task-Definition, Service und Load Balancer in einem Schritt erstellen und den Container öffentlich im Internet erreichbar machen.

### Voraussetzungen

- Ein AWS-Konto mit Zugriff auf die Services ECS, ECR und EC2 (für VPC/ALB).
- Das Docker-Image muss in einer Registry liegen, auf die ECS zugreifen kann (z. B. Amazon ECR). Docker Hub-Images funktionieren ebenfalls, sofern sie öffentlich sind.

### Schritt 1: Image in Amazon ECR veröffentlichen

1. In der AWS-Konsole zu **Amazon ECR** → **Repositories** → **Create repository** gehen und z. B. `nginx-hello-world` als Namen vergeben (Private Repository reicht aus).
2. Nach dem Erstellen auf das Repository klicken und **View push commands** öffnen. Dort stehen die exakten Befehle für dein System, sinngemäß:

   ```bash
   aws ecr get-login-password --region <REGION> | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com

   docker build -t nginx-hello-world .
   docker tag nginx-hello-world:latest <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/nginx-hello-world:latest
   docker push <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/nginx-hello-world:latest
   ```

3. Die Image-URI (`<ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/nginx-hello-world:latest`) notieren – sie wird im nächsten Schritt benötigt.

### Schritt 2: Container über die ECS-Konsole deployen

1. In der AWS-Konsole zu **Amazon ECS** navigieren.
2. Im linken Menü **Clusters** auswählen und auf **Create cluster** klicken.
3. Cluster-Namen vergeben (z. B. `hello-world-cluster`) und als Infrastruktur **AWS Fargate (serverless)** auswählen. Mit **Create** bestätigen.
4. Im Cluster auf **Services** → **Create** klicken (dies ist die "Express"-Methode, da Task-Definition, Service und optional Load Balancer in einem Formular erstellt werden):
   - **Compute options**: Launch type → **FARGATE**.
   - **Container details**:
     - Name: z. B. `nginx-hello-world`
     - Image URI: die zuvor notierte ECR-Image-URI einfügen
     - Container port: `80`
   - **Networking**: eine bestehende VPC mit öffentlichen Subnetzen auswählen (oder die Standard-VPC verwenden). **Public IP** auf **Turned on** setzen, damit der Task eine öffentliche IP erhält.
   - **Load balancing** (für eine im Internet erreichbare, stabile URL): **Application Load Balancer** auswählen, einen neuen ALB erstellen lassen (z. B. `hello-world-alb`) und Port `80` → Container-Port `80` mappen.
   - **Service name**: z. B. `nginx-hello-world-service`, **Desired tasks**: `1`.
5. Mit **Create** bestätigen. ECS erstellt automatisch Task-Definition, Service, Target Group und Security Groups.

### Schritt 3: Security Group prüfen

- Sicherstellen, dass die vom Load Balancer bzw. vom Task verwendete Security Group eingehenden Traffic auf Port 80 aus dem Internet (`0.0.0.0/0`) erlaubt. Die Express-Methode legt dies in der Regel automatisch an, sollte aber unter **EC2 → Security Groups** kontrolliert werden.

### Schritt 4: Aufrufen im Internet

1. Im ECS-Cluster unter **Services** den erstellten Service öffnen.
2. Im Tab **Networking** bzw. unter dem verknüpften Load Balancer (EC2 → Load Balancers) den **DNS name** des Application Load Balancers kopieren (z. B. `hello-world-alb-123456789.<region>.elb.amazonaws.com`).
3. Diese URL im Browser aufrufen:

   ```
   http://hello-world-alb-123456789.<region>.elb.amazonaws.com
   ```

   Die "Hello World"-Seite sollte nun im Browser angezeigt werden.

### Aufräumen (um Kosten zu vermeiden)

- Service löschen: **ECS → Cluster → Services → Service auswählen → Delete**.
- Cluster löschen: **ECS → Clusters → Cluster auswählen → Delete Cluster**.
- Load Balancer löschen: **EC2 → Load Balancers → Load Balancer auswählen → Delete**.
- ECR-Repository löschen: **ECR → Repositories → Repository auswählen → Delete**.
# nginx_helloworld_ecs
