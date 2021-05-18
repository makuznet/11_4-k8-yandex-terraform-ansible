

# K8 cluster with Kubeadm

> This repo creates a K8 cluster.    

## Usage 
### Get Yandex VPS images list
```bash
yc compute image list --folder-id standard-images | grep debian
```
Copy id from the ID column starting with `fd`.    

### Get Yandex VPS image info
```bash
yc compute image get fd8ac3cvmm5lk2l7ac4f
```
### Adding user credentials securely in Terraform
Create user and its RSA key records in main.auto.tfvars.  
Add main.auto.tfvars in the .gitignore file.  
Create main.auto.tfvars.sample to instruct others about types of sensitive data.
See main.auto.tfvars.sample for details.  
Describe your records as vars in the variable.tf (look inside this file for details).  
Use your vars in the `metadata` section of "yandex_compute_instance" resource (see main.tf):
```bash
metadata = {
    user-data = "#cloud-config\nusers:\n  - name: ${var.login_user}\n    groups: sudo\n    shell: /bin/bash\n    sudo: ['ALL=(ALL) NOPASSWD:ALL']\n    ssh-authorized-keys:\n      - ${var.my_ssh_key}"
  }
```   
This syntax was described in Yandex.Cloud [docs](https://cloud.yandex.com/en-ru/docs/compute/concepts/vm-metadata).    

### Terraform
```bash
terraform plan # see if main.tf scenario flies
terraform apply --auto-approve # create your virtual empire
terraform destroy --auto-approve # bite your virtual empire to dust
```
### Ansible
#### Check Ansible inventory correctness manually
```bash
ansible-inventory -i inventory.yml --graph --vars
```
You should see alike output:  
```bash
@all:
  |--@k8:
  |  |--178.154.228.29
  |  |  |--{ansible_user = user }
  |  |--178.154.229.44
  |  |  |--{ansible_user = user }
  |--@ungrouped:
```

#### Check Ansible connectivity manually
```bash
ansible all -m ping -i inventory.yml 
```
#### Run Ansible manually
```bash
ansible-playbook -i inventory.yml main.yml #--tags=drive # role tags can be used see main.yml.
```
#### Ansible-Vault
Sensitive RSA key files are encrypted.  
Decrypt them before use if you know the password:  
```bash
ansible-vault decrypt id_rsa/id_rsa*
```
or amend Ansible command in main.tf file and then provide the password:
```bash
ansible-playbook -i inventory.yml main.yml --ask-vault-pass
```
or change to your own.   

### Kubernetes 
When creating K8 cluster with kubeadm I have defined these stages:
1. Installing docker.io, kubelet, and kubeadm on both master and worker nodes.  
    - see Ansible `common` role for details;  
2. Installing kubectl on a master node.  
    - see Ansible `master` role for details;  
3. Initializing the cluster on the master node.  
    - see Ansible `master` role for details;  
    - flannel docs [says](https://github.com/flannel-io/flannel/blob/master/Documentation/kubernetes.md) there should be --pod-network-cidr parameter added to init command;  
4. Copying a cluster config file to the user home dir on master node.  
    - see Ansible `master` role for details;  
    - you won't be able to run kubectl commands without copying cluster config file;
    - you will see `The connection to the server localhost:8080 was refused` error;  
5. Installing a pod network (flannel) on the master node.
    - see Ansible `master` role for details;
    - I guess this is a sort of L3 SDN for K8 cluster;
6. Generating credentials for connecting worker nodes to the cluster on the master node.
    - see Ansible `join_master` role for details;
    - credentials are copied to a variable and then the first line of this object variable is printed and stored to a j2 template file (added to .gitignore);  
7. Applying credentials to worker nodes.
    - j2 template is copied as a .txt file to a worker node, and run when being echoed. 
8. Monitoring installation results.
    - Check whether K8 cluster operates:
    ```bash
    kubectl get nodes
    ```
    The answer is supposed to be:
    ```bash
    NAME     STATUS   ROLES                  AGE     VERSION
    master   Ready    control-plane,master   7h11m   v1.21.1
    worker   Ready    <none>                 7h9m    v1.21.1
    ```
    - as Yandex.Cloud VPSes, both master and worker, have got only private ip eth interface that are used by a K8 cluster, so the third VPS serving as openvpn server is created to allow your local PC become a part of this private subnet and run K8 Dashboard.
    - openvpn server was created [manually](https://cloud.yandex.ru/docs/solutions/routing/openvpn).   
    - you can log in, but you won't see anything in Dashboard using existing K8 cluster tokens obtained by one of these commands:
    ```bash
    kubectl -n kube-system describe secret default # default token
    kubectl -n kube-system describe secret # all tokens
    kubectl -n kube-system get secrets # all tokens ( '-n kube-system' at the beginning)
    kubectl get secrets -n kube-system # token list ( '-n kube-system' at the end)
    ```
    as such an authentication token is NOT linked to an account with sufficient privileges;  
    - so you must know how to provide privileges to existing user or to add one more user;
    - I followed this [Dashboard docs](https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md) and created a new one;
    - Dashboard has got a timeout. Token should be provided every time it is locked due to timeout; 

#### Run Dashboard
This command links IP:6443 from `~/.kube/config` with your localhost:8001 (your laptop should be connected to a K8 cluster via openvpn as IP address in config is a private one).       
```bash
kubectl proxy
```
This command requests a K8 cluster master concerning information to display in Dashboard.  
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml
```
This command opens a K8 Dashboard.  
```bash
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/overview?namespace=default
```
#### Some commands
```bash
kubectl get pods --all-namespaces
kubectl get namespaces
kubectl -n kube-system get pods
```
> If you run this, you will destroy your K8 cluster !!!
> ```bash
> kubeadm reset
> ```

## Installation
### Yandex OAuth token
[Yandex.OAuth](https://oauth.yandex.com)

### Yandex CLI (MacOS)
```bash
curl https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
brew install bash-completion
echo 'source /Users/makuznet/yandex-cloud/completion.zsh.inc' >>  ~/.zshrc
source "/Users/makuznet/.bash_profile"
yc init # provide your yandex token
yc config profile get <your_profile_name> 
```
### Terraform (MacOS)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install terraform
```
### Ansible (MacOS)
```bash
https://www.python.org/ftp/python/3.9.5/python-3.9.5-macosx10.9.pkg
python get-pip.py
pip install ansible
```

## Acknowledgments

This repo was inspired by [skillfactory.ru](https://skillfactory.ru/devops#syllabus) team

## See Also
- [Yandex CLI](https://cloud.yandex.com/en-ru/docs/cli/quickstart)
- [Terraform Yandex.Cloud Provider](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs)
- [Yandex Getting started with Terraform](https://cloud.yandex.com/en-ru/docs/solutions/infrastructure-management/terraform-quickstart)
- [Yandex VM instance metadata](https://cloud.yandex.com/en-ru/docs/compute/concepts/vm-metadata)
- [Kubernetes Creating a cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Digital Ocean How To Create a Kubernetes Cluster Using Kubeadm](https://www.digitalocean.com/community/tutorials/how-to-create-a-kubernetes-cluster-using-kubeadm-on-ubuntu-18-04)
- [podnetwork flannel](https://github.com/flannel-io/flannel#flannel)
- [openvpn client for MacOS](https://openvpn.net/vpn-server-resources/connecting-to-access-server-with-macos/)
- [Kubernetes Dashboard docs](https://github.com/kubernetes/dashboard/tree/master/docs)
- [Kubernetes Dashboard docs Creating sample user](https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md)
- [Not enough data to create auth info structure](https://stackoverflow.com/questions/48228534/kubernetes-dashboard-access-using-config-file-not-enough-data-to-create-auth-inf)


## License
Follow all involved parties licenses terms and conditions.