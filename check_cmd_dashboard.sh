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
kubectl describe ingress kubernetes-dashboard-ingress -n kubernetes-dashboard