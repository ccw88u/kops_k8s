echo "========================ml-dev==============================="
echo "---pods"
kubectl get pods -n ml-dev -o wide
echo "---deployments"
kubectl get deployments -n ml-dev -o wide
echo "---autoscaling status"
kubectl get hpa -n ml-dev
echo "---ingress description"
kubectl describe ingress ml-dev-ingress -n ml-dev
