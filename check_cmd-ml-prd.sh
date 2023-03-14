echo "========================ml-prd==============================="
echo "---pods"
kubectl get pods -n ml-prd -o wide
echo "---deployments"
kubectl get deployments -n ml-prd -o wide
echo "---autoscaling status"
kubectl get hpa -n ml-prd
echo "---ingress description"
kubectl describe ingress ml-prd-ingress -n ml-prd
