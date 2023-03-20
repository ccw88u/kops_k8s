echo "========================kubernetes-dashboard==============================="
echo "------------------------------------------------------------"
echo "              pod"
echo "------------------------------------------------------------"
kubectl get pods -n kubernetes-dashboard -o wide
echo "------------------------------------------------------------"
echo "              services"
echo "------------------------------------------------------------"
kubectl get svc -n kubernetes-dashboard -o wide

echo "------------------------------------------------------------"
echo "              ingress description"
echo "------------------------------------------------------------"
kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
