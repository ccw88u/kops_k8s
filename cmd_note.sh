
ponddy kops readme ponddy.org


#############################
######### kops
#############################

## kops
  - 建立 cluster
kops create cluster \
 --name=k8s.wenwen999.link \
 --state=s3://kops.wenwen999.link \
 --zones=us-west-2a \
 --master-size=t2.medium \
 --node-size=t2.medium \
 --node-count=2 \
 --dns-zone=k8s.wenwen999.link


  - 設定kops環境變數
建議設定以下指令，避免每次都要下 --state=s3://kops.wenwen999.link
export DOMAIN=k8s.wenwen999.link
export NAME=$DOMAIN
export KOPS_STATE_NAME=kops.wenwen999.link 
export KOPS_STATE_STORE=s3://$KOPS_STATE_NAME
# 切換aws profile
export AWS_PROFILE=kops
# 使用環境變數方式 避免錯誤
export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)


# 驗證cluster 是否正常
kops validate cluster


kops 輸出新的k8s登入設定檔案(~/.kube/config)
當發生: error: You must be logged in to the server (Unauthorized) 代表認證已經到期，需要下以下指令輸出最新的 ~/.kube/config
需要先啟用kops環境變數
–admin 參數需要輸入時間: 4320h (半年)
Reference
kops export kubecfg --name=$NAME --admin=4320h0m0s


看目前cluster的master / node 分布
$ kops get ig
NAME                    ROLE            MACHINETYPE     MIN     MAX     ZONES
master-us-west-2a       ControlPlane    t2.medium       1       1       us-west-2a
nodes-us-west-2a        Node            t2.medium       2       2       us-west-2a

看目前cluster的master / node 分布 by kubectl
$ kubectl get nodes -o wide


編輯nodes : us-west-2a
$ kops edit ig nodes-us-west-2a


如果要更改最大服務總數，可以將 maxSize: 7 -> maxSize: 8，修改儲存後就可以更新node 台數最大為: 8
如果要更改 node: EC2 type : 可以調整: machineType: m5.xlarge

```
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: kops.k8s.io/v1alpha2
kind: InstanceGroup
metadata:
  creationTimestamp: "2023-03-16T10:32:55Z"
  labels:
    kops.k8s.io/cluster: k8s.wenwen999.link
  name: nodes-us-west-2a
spec:
  image: 099720109477/ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20230302
  machineType: t2.medium
  maxSize: 2
  minSize: 2
  nodeLabels:
    kops.k8s.io/instancegroup: nodes-us-west-2a
  role: Node
  subnets:
  - us-west-2a
```

儲存後執行: kops update cluster 設定
儲存後執行: kops update cluster --yes 進行設定更新
準備根據狀態更新: kops rolling-update cluster --yes
執行更新需要一段時間，kops 也會將master 進行更新


#############################
######### kubectl
#############################

# 建立name space
% kubectl create namespace ml-prd

kubectl get svc

kubectl get deployment

kubectl delete -f XXX.yaml

% 看namespace: kube-system 目前 service 服務
kubectl get svc -n kube-system

% 看 ingress pods
$ kubectl get pods -n ingress-nginx
$ kubectl get pods --all-namespaces -l app.kubernetes.io/name=ingress-nginx

# 查看所有namespace
kubectl get namespaces

# 看目前 ml-dev regcred 格式是否正常
kubectl get secret regcred --output=yaml -n ml-prd


# 抓取目前Addon
kubectl get all -n kube-system

# Kubernetes系统运行了metrics-server，用以下方法检查。如果没有运行，需要安装metrics-server
kubectl get pod -A | grep metrics-server


設定 pods 於特定 node 上面跑
Reference
#k8s 指定pod 運行 node
https://tachingchen.com/tw/blog/kubernetes-assigning-pod-to-nodes/


將某個服務由 load balancer 改成 nodeport 方式
kubectl patch -p '{"spec":{"type": "NodePort"}}' services -n monitoring prometheus-k8s
http://api.k8s.wenwen999.link:31548/


# 看 nodes 的 labels 
$ kubectl get nodes --show-labels

    spec:
      containers:
      - name: nginx
        image: nginx
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
      nodeSelector:
        networkSpeed: "high"
		
   nodeSelector:
    node.kubernetes.io/instance-type: "c6i.xlarge"

設定 pods 盡量於符合條件的 node 上面跑 – affinity
參考網址
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gop-eng
  template:
    metadata:
      labels:
        app: gop-eng
    spec:
      containers:
        - image: ponddy/gop_eng_flask:v1.5
          resources:
            requests:
              memory: "1024Mi"
              cpu: "1000m"
          name: gop-eng
      imagePullSecrets:
        - name: regcred
      affinity:
        nodeAffinity:
          # 設定軟條件，若找不到符合條件的 node，依然會指派
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1    # 符合條件則給予權重，選擇權重分數最高的 node 指派
            preference:
              matchExpressions:
              - key: node.kubernetes.io/instance-type
                operator: In    # 在 values 列表中
                values:
                - c6i.xlarge