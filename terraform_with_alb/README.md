
```sh
# Build Container
aws ecr get-login-password --region <REGION> | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com

docker build -t nginx-hello-world .
docker tag nginx-hello-world:latest <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/nginx-hello-world:latest
docker push <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/nginx-hello-world:latest
```

```sh
# Deploy on AWS ECS lightweight
terraform apply -var="ecr_image_uri=DEINE_ACCOUNT_://amazonaws.com"```