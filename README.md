<img width="355" alt="Terraform-Azure-Diagram(1)" src="https://user-images.githubusercontent.com/17272827/154813262-15335026-7c96-4a93-8613-cd7bb1e9e896.png">

My test environment within Azure.
1. authenticate to azure with azure cli (az login command)
2. fill out variables on tfvars file
3. Run terraform apply - a private key will appear in the directory - use this to access all VMs.
4. access management VM to push out configurations via ansible.

I am running this on  windows, but I have the Windows Subsystem for Linux (WSL) installed therefore I am connecting to my Azure VM through WSL instead of puTTy.

After running the terraform file, I copy the private key (created in the directory) into the WSL environment using

cp path/to/file ~

then connect to the Azure management VM with that private key using ssh -i <admin_name>@<vm_ip>

This management VM can then run ansible configurations against other VMs to install web and database servers, etc...

In my terraform environment i created the private key in the terraform runtime so it's visible in the code, but ideally in a production environment you would manually create the key in the AWS console and reference it here as a best practice, so the key can't be seen at all.

I have hardened this setup by:
* allowing SSH from my public IP only (adding a variable for it)
* accepting only encrypted web traffic (443) as opposed to 80 for my web subnets
* blocking internet access for my internal database subnets
