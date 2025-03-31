aws eks update-kubeconfig --name event-driven-cluster --region ap-northeast-2

eksctl utils associate-iam-oidc-provider --cluster=event-driven --approve

curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json

aws iam create-policy     --policy-name AWSLoadBalancerControllerIAMPolicy     --policy-document file://iam_policy.json

aws iam attach-role-policy   --policy-arn arn:aws:iam::003150130236:policy/AWSLoadBalancerControllerIAMPolicy   --role-name eksctl-event-driven-cluster-cluster-ServiceRole-0Hs1Enb6qLxX

eksctl create iamserviceaccount --cluster=event-driven-cluster --namespace=kube-system --name=aws-load-balancer-controller --attach-policy-arn=arn:aws:iam::003150130236:policy/AWSLoadBalancerControllerIAMPolicy --approve 

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm repo add eks https://aws.github.io/eks-charts

helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=event-driven-cluster --set serviceAccount.create=false --set seviceAccount.name=aws-load-balancer-controller --set image.repository=602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/amazon/aws-load-balancer-controller --set region=ap-northeast-2 --set vpcId=vpc-0e10a5edb67c555ea
