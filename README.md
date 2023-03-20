
# Kops 、 K8s、 AWS setting Sub domain
  - kops : 1.26.2

```bash=
$ curl -LO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
$ chmod +x kops-linux-amd64
$ sudo mv kops-linux-amd64 /usr/local/bin/kops
$ kops version
```
  - k8s  : v1.26.2 
  - kubectl : 
```
Client Version: version.Info{Major:"1", Minor:"26", GitVersion:"v1.26.2", GitCommit:"fc04e732bb3e7198d2fa44efa5457c7c6f8c0f5b", GitTreeState:"clean", BuildDate:"2023-02-22T13:39:03Z", GoVersion:"go1.19.6", Compiler:"gc", Platform:"linux/amd64"}
Kustomize Version: v4.5.7
Server Version: version.Info{Major:"1", Minor:"26", GitVersion:"v1.26.2", GitCommit:"fc04e732bb3e7198d2fa44efa5457c7c6f8c0f5b", GitTreeState:"clean", BuildDate:"2023-02-22T13:32:22Z", GoVersion:"go1.19.6", Compiler:"gc", Platform:"linux/amd64"}

```
  - NGINX Ingress Controller: ingress-nginx-controller-v1.6.4.yaml


## Linux install AWS CLI

```bash=
# awscli 套件
$ sudo apt install awscli
$ aws --version
aws-cli/1.18.69 Python/3.6.9 Linux/4.15.0-147-generic botocore/1.16.19
```

## Domain:
   - 這是在 AWS Router 53 上購買的Domain: wenwen999.link
   - reference:https://kops.sigs.k8s.io/getting_started/aws/#testing-your-dns-setup
 
## k8s sub domain
   - Final sub domain: k8s.wenwen999.link

## 設定 AWS IAM 
   - aws account : kops
   - The kops user will require the following IAM permissions to function properly:
```
AmazonEC2FullAccess
AmazonRoute53FullAccess
AmazonS3FullAccess
IAMFullAccess
AmazonVPCFullAccess
AmazonSQSFullAccess
AmazonEventBridgeFullAccess
```
   - You can create the kOps IAM user from the command line using the following:
```
aws iam create-group --group-name kops

aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/IAMFullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonSQSFullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess --group-name kops

aws iam create-user --user-name kops

aws iam add-user-to-group --user-name kops --group-name kops

aws iam create-access-key --user-name kops
```
   - You should record the SecretAccessKey and AccessKeyID in the returned JSON output, and then use them below:
```
# configure the aws client to use your new IAM user
aws configure           # Use your new access and secret key here
aws iam list-users      # you should see a list of all your IAM users here

# Because "aws configure" doesn't export these vars for kops to use, we export them now
export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
```


## 設定 AWS S3
  - [reference](https://kops.sigs.k8s.io/getting_started/aws/#using-s3-default-bucket-encryption)
  - 本次測試路徑為: 


## Kops 安裝
  - name: cluster name
  - dns-zone -> sub domain
  - Master node 於新版 k8s 建議 Mem: 2G -> ==t2.medium==，選擇 t2.micro 可能會造成無法正常
  - dns-zone : Rounter 53 上的註冊domain k8s.wenwen999.link
  
### 初始設定 kops & AWS 設定 
   - 費用初估: us-west-2 奧勒岡
   - t2.medium: 0.0464 USD per Hour 
   - 一天: 0.0464 * 24 * 30 * 3(台) = 100
   - 一個月:  100 * 30 = 3000 元
   - 如果經費不足，可以將改成 node-count=1，或將 node-size=t2.small

```bash=
kops create cluster \
 --name=k8s.wenwen999.link \
 --state=s3://kops.wenwen999.link \
 --zones=us-west-2a \
 --master-size=t2.medium \
 --node-size=t2.medium \
 --node-count=2 \
 --dns-zone=k8s.wenwen999.link
``` 
  - <output>
Must specify --yes to apply changes
Cluster configuration has been created.
Suggestions:
 * list clusters with: kops get cluster
 * edit this cluster with: kops edit cluster k8s.wenwen999.link
 * edit your node instance group: kops edit ig --name=k8s.wenwen999.link nodes-us-west-2a
 * edit your control-plane instance group: kops edit ig --name=k8s.wenwen999.link control-plane-us-west-2a


### 確認無誤後，執行 create cluster
  -  Finally configure your cluster with: kops update cluster --name k8s.wenwen999.link --yes --admin

```
%根據最後 kops update cluster 建議補上 --state=s3://kops.wenwen999.link
kops update cluster --name k8s.wenwen999.link --yes --admin  --state=s3://kops.wenwen999.link
```

  - **<output>**

```
Cluster is starting.  It should be ready in a few minutes.

Suggestions:
 * validate cluster: kops validate cluster --wait 10m
 * list nodes: kubectl get nodes --show-labels
 * ssh to a control-plane node: ssh -i ~/.ssh/id_rsa ubuntu@api.k8s.wenwen999.link
 * the ubuntu user is specific to Ubuntu. If not using Ubuntu please use the appropriate user based on your OS.
 * read about installing addons at: https://kops.sigs.k8s.io/addons.
```

### 確認node節點

 ```bash=
$ kubectl get nodes
NAME                  STATUS   ROLES           AGE   VERSION
i-021a843d3dbb610d6   Ready    node            11h   v1.26.2
i-094237e11d2e888a3   Ready    node            11h   v1.26.2
i-0c6e797d63bec4382   Ready    control-plane   11h   v1.26.2
 ```


![](https://imgur.com/epwFtra.png)


### 安裝 ingress-nginx-controller load balancer 
   - 說明
```
ingress-nginx-controller 是一個 Kubernetes 上的 Ingress 控制器，它的作用是將外部請求路由到 Kubernetes 集群中的服務。具體來說，它會監聽 Kubernetes 集群中的 Ingress 資源，並根據這些資源配置 Nginx 的反向代理規則，將外部流量轉發到對應的服務中。
通過 ingress-nginx-controller，您可以實現諸如 HTTP/HTTPS 路由、SSL 終止、負載均衡、URL 重新寫入等功能。它還支持基於主機名、路徑、HTTP 方法等條件進行路由，並且具有高度的可配置性和擴展性。
總之，ingress-nginx-controller 可以讓您更輕鬆地管理和控制 Kubernetes 集群中的流量，提高服務的可用性和彈性。

% ingress-nginx 網站
https://github.com/kubernetes/ingress-nginx
```
   - 由於本次 K8S 版本為 1.26 版，故需要 V1.6.4 版 : ingress-nginx-controller-v1.6.4.yaml

```bash=
$  kubectl apply -f ingress-nginx-controller-v1.6.4.yaml
```
   

### Router 53 綁定 sub domain:  ml-dev.k8s.wenwen999.com
   - 建立 namespace: kubectl create namespace ml-dev
   - ingress_ML-dev.yaml
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ml-dev-ingress
  namespace: ml-dev
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/proxy-body-size: "7m"
    #ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/use-regex: "true"    
spec:
  rules:
  # ml-dev.ponddy.org & ml-dev.ponddy.com 都要設定  
  - host: ml-dev.k8s.wenwen999.link
    http:
      paths:
      - path: /gop_eng(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: gop-eng
            port:
              name: http
      - path: /gop_chi(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: gop-chi
            port:
              name: http              
```

```bash=
kubectl apply -f ingress_ML-dev.yaml
```
   - 根據 ingress 生成 load balancer, 並於 route 53上綁定 domain
   - $kubectl describe ingress ml-dev-ingress -n ml-dev
   - ![](https://imgur.com/bvGOhVH.png)
   - ![](https://imgur.com/HIA7jSx.png)


### ml-dev.k8s.wenwen999.com 下安裝多個 docker 服務及定義多個serviuce
   - https://ml-dev.k8s.wenwen999.com/my_service1/predict
   - https://ml-dev.k8s.wenwen999.com/my_service2/predict


### 設定橫向擴展 hpa
   - hpa for ml-dev
   - 安裝addon 
   - note
```
如果在 Kubernetes 中使用 Horizontal Pod Autoscaler (HPA) 時出現 "Targets unknown" 的狀態，通常是因為 HPA 無法確定目標應用程序的度量值。這可能是由於應用程序沒有公開任何用於度量的端點，或者端點的度量值未與 HPA 配置匹配造成的。
通常，HPA 通過將度量值與指定的目標進行比較來決定是否應增加或減少副本數。如果 HPA 無法獲取度量值，則無法判斷當前副本數是否已達到目標值。
要解決此問題，可以確保您的應用程序公開了與 HPA 配置匹配的度量值端點。例如，如果您正在使用 CPU 利用率作為度量值，則應確保應用程序公開了 CPU 利用率的度量值端點。此外，還可以檢查 HPA 配置是否正確，並確保它與應用程序的度量值匹配。
您可以使用 kubectl describe hpa [HPA 名稱] 命令檢查 HPA 的詳細信息，以了解更多關於 "Targets unknown" 狀態的信息。
```
   - 設定其中一個 gop-eng 綁定 HPA (Horizontal Pod Autoscaler)
     - $kubectl get hpa -n ml-prd
```
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: hpa-gop-eng
  namespace: ml-dev
spec:
  maxReplicas: 3  # define max replica count
  minReplicas: 1  # define min replica count
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: gop-eng
  targetCPUUtilizationPercentage: 70 # target CPU utilization

``` 
![](https://imgur.com/oiBMz3J.png)

### 刪除cluster: master / node
   - 如果沒有使用 ==建議先刪除==
 ```bash=
 kops delete cluster --name=k8s.wenwen999.link --state=s3://k8s.wenwen999.link --yes

 kops delete cluster --name=k8s.wenwen999.link --state=s3://kops.wenwen999.link --yes
 ```

### 如果不想刪除暫停處理方式
   - 可以透過kops 將master / node : minsize / maxsize 改成:0 並佈署上cluster即可 
   - 注意移除如 promethus / grafana 裡面有儲存帳密的pod 重新安裝時，密碼不會保留
```
$ kops edit ig master-us-west-2a
  minsize / maxsize 改成:0
$ kops edit ig node-us-west-2a
  minsize / maxsize 改成:0

$ kops update cluster

$ kops update cluster --yes

# 跑完後，master / node 都會移除
$ kops rolling-update cluster
```