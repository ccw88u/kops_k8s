
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


### (待補)安裝 ingress-nginx-controller load balancer 
   - ingress-nginx-controller-v1.6.4.yaml


### (待補)Router 53 綁定 sub domain:  ml-dev.k8s.wenwen999.com
   - namespace
  

### (待補) ml-dev.k8s.wenwen999.com 下安裝多個 docker 服務及定義多個serviuce
   - https://ml-dev.k8s.wenwen999.com/my_service1/predict
   - https://ml-dev.k8s.wenwen999.com/my_service2/predict


### (待補) 設定橫向擴展 hpa


### 刪除cluster: master / node
   - 如果沒有使用 ==建議先刪除==
 ```bash=
 kops delete cluster --name=k8s.wenwen999.link --state=s3://k8s.wenwen999.link --yes

 kops delete cluster --name=k8s.wenwen999.link --state=s3://kops.wenwen999.link --yes
 ```

