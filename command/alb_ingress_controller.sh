#!/bin/bash

REGION="ap-northeast-2"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

CLUSTER_NAME=$(aws eks list-clusters --region $REGION --query "clusters[0]" --output text)

EKS_ROLE_NAME=$(aws iam list-roles --query "Roles[?contains(RoleName, 'eks')].RoleName | [0]" --output text)

VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query "cluster.resourcesVpcConfig.vpcId" --output text)

echo "Using CLUSTER_NAME=$CLUSTER_NAME"
echo "Using EKS_ROLE_NAME=$EKS_ROLE_NAME"
echo "Using VPC_ID=$VPC_ID"
echo "Using ACCOUNT_ID=$ACCOUNT_ID"

aws eks update-kubeconfig --name "$CLUSTER_NAME" --region $REGION

eksctl utils associate-iam-oidc-provider --cluster="$CLUSTER_NAME" --approve

curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json

aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json 2>/dev/null || echo "Policy already exists."

aws iam attach-role-policy \
  --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --role-name "$EKS_ROLE_NAME"

eksctl create iamserviceaccount \
  --cluster="$CLUSTER_NAME" \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::$ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName="$CLUSTER_NAME" \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set image.repository=602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/amazon/aws-load-balancer-controller \
  --set region=$REGION \
  --set vpcId="$VPC_ID"
