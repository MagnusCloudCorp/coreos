# CoreOS node Deployment on vSphere
This is the third installment of the [The DevOps journey with Gitlab and Kubernetes](https://www.linosteenkamp.com/staging-environment-ubuntu-18-04/) series.

We are going to use Terraform to deploy CoreOS nodes to a vSphere environment.

The work in this post is based on the [Terraform vSphere Provider](https://github.com/terraform-providers/terraform-provider-vsphere) and especially the [vSphere OVF Template Deploy Example](https://github.com/terraform-providers/terraform-provider-vsphere/tree/master/examples/ovf-template).

### Add CoreOS ova template to vSphere

I'm running these commands on a vCenter against a ESXi 6.5 host, so it might be diffrent from your environment.

Login to your vSphere environment, right click on the host and select "Deploy OVF Template". In the Dialog presented, select URL and use the following URL 
```
https://stable.release.core-os.net/amd64-usr/current/coreos_production_vmware_ova.ova
```

Make sure to select Thin provision for your virtual disk format on the Select Storage page.

Don't change any values in the Customize Template page.

Finally deploy the template. **Don't** power on the virtual machine, but make snapshot and then convert the machine to a template by right clicking on the machine, select Template and then Convert to Template.

### Clone Terraform scripts  
Clone the terraform scripts we're going to use to deploy the CoreOS hosts from my github repositry.

```
$ cd ~/DevOps
$ git clone git@github.com:linosteenkamp/coreos.git
$ cd coreos/
```
Now copy the terraform.tfvars.example file to terraform.tfvars and change the values in the file to suit your environment.

```
$ cp terraform.tfvars.example terraform.tfvars
$ vim terraform.tfvars
```

The values that you need to change in the terraform.tfvars is self explanatory but take note about the following:
* resource_pool - I'm not using a resource pools so I will use "Resources" as the value. If you however are using a resourcpool your value need to be in the form "cluster1/Resources"
* template_name - Use the name of the template you created on vSphere.
* virtual_machine_ip_address_start - The last octect that serves as the start of the IP addresses for the virtual nodes. Given the default value here of 100, if the network address is 10.0.0.0/24, the 3 virtual machines will be assigned addresses 10.0.0.100, 10.0.0.101, and 10.0.0.102.
* virtual_machine_count - the number of nodes to create

### Deploy the CoreOS nodes to your vSphere environment.
Initialize the Terraform Environment

```
$ terraform init
```

Deploy the CoreOS nodes to vSphere
```
$ terraform apply
```

If everything went according to plan you should now have the number of CoreOS nodes you specified in the terraform.tfvars running on your vSphere environment.

### Enable UUID on all CoreOS nodes
We are going to make use of [vSphere Storage for Kubernetes](https://vmware.github.io/vsphere-storage-for-kubernetes/documentation/) to provide persistent storage for Gitlab. For this to work properly we need to enable UUID on every node to presents a consistent UUID to the VM.

To make this task easier, clone my github utils repository into the DevOps folder.
```
$ cd ~/DevOps
$ git clone git@gitlab.cicd.aax.co.za:devops/utils.git
$ cd utils
$ chmod +x enableUUID.sh
```
Execute the enableUUID.sh script with the same value you used in the terraform.tfvars for the virtual_machine_name_prefix item.
```
$ ./enableUUID.sh k8s-cicd-node
```

### Finally
You should now have some CoreOS nodes running on your vSphere environment.

