"""Architektur-Diagramm für terraform_with_alb (ECS Fargate hinter einem ALB)."""
from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import ECS, ECR, Fargate
from diagrams.aws.network import ALB, VPC, InternetGateway
from diagrams.aws.security import IAMRole
from diagrams.aws.general import Users
from diagrams.onprem.client import Users as DevUser

graph_attr = {
    "fontsize": "20",
    "pad": "0.5",
}

with Diagram(
    "terraform_with_alb Architektur",
    filename="architecture",
    outformat="pdf",
    show=False,
    graph_attr=graph_attr,
):
    browser = Users("Browser")
    developer = DevUser("Developer")

    with Cluster("AWS Account (eu-central-1)"):
        ecr = ECR("ECR Repository\nnginx-hello-world")

        with Cluster("Default VPC"):
            igw = InternetGateway("Internet Gateway")
            alb = ALB("Application\nLoad Balancer")

            with Cluster("ECS Cluster (Fargate)"):
                task_role = IAMRole("ecs-task-execution-role")
                service = ECS("ECS Service")
                task = Fargate("Task\n(nginx:80)")

                service >> task
                task_role >> Edge(style="dashed", label="assume role") >> task

            igw >> alb >> Edge(label="HTTP :80") >> service
            ecr >> Edge(style="dashed", label="pull image") >> task

    developer >> Edge(label="docker push") >> ecr
    browser >> Edge(label="HTTP :80") >> igw
