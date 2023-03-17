echo "========================ml-dev==============================="
echo "------------------------------------------------------------"
echo "              pod"
echo "------------------------------------------------------------"
kubectl get pods -n ml-dev -o wide
echo "------------------------------------------------------------"
echo "              deployments"
echo "------------------------------------------------------------"
kubectl get deployments -n ml-dev -o wide
echo "------------------------------------------------------------"
echo "              autoscaling status"
echo "------------------------------------------------------------"
kubectl get hpa -n ml-dev
echo "------------------------------------------------------------"
echo "              ingress description"
echo "------------------------------------------------------------"
kubectl describe ingress ml-dev-ingress -n ml-dev


echo "------------------------------------------------------------"
