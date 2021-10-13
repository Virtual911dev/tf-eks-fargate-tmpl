aws eks --region us-east-2 update-kubeconfig --name lynx-dev --profile AWSAdministratorAccess-661199018908

kubectl  patch deployment/coredns  --kubeconfig ~/.kube/config --namespace kube-system   --type=json   -p='[{"op": "remove", "path": "/spec/template/metadata/annotations", "value": "eks.amazonaws.com/compute-type"}]'
kubectl  patch deployment/alb-ingress-controller --kubeconfig ~/.kube/config  --namespace kube-system   --type=json   -p='[{"op": "remove", "path": "/spec/template/metadata/annotations", "value": "eks.amazonaws.com/compute-type"}]'


kubectl scale deployment coredns --kubeconfig ~/.kube/config  --replicas=1 -n kube-system
kubectl scale deployment alb-ingress-controller --kubeconfig ~/.kube/config --replicas=1 -n kube-system

kubectl rollout restart -n kube-system --kubeconfig ~/.kube/config deployment/coredns
kubectl rollout restart -n kube-system --kubeconfig ~/.kube/config deployment/alb-ingress-controller
