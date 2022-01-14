**work in progress

My test environment within Azure.
1.) authenticate to azure with azure cli (login credentials)j
2.) after running a private key will appear in the directory - use this to access all VMs.
3.) access management VM to push out configurations via ansible.

I am running this on  windows, but I have the Windows Subsystem for Linux (WSL) installed therefore I am connecting to my Azure VM through WSL instead of puTTy.

After running the terraform file, I copy the private key (created in this directory) into the WSL environment using

cp path/to/file ~

then connect to the Azure management VM with that private key.

this same private key is also used to connect to the other (web and database) VMs ... bad security practice i know, but i was focusing on getting it working for the time being. so I have a terraofrm provisioner to copy the private key from this directory to the management VM when it is created.

realistically you would use a different private key.

In my terraform environment i created the private key in the terraform runtime, in a production environment you would ideally create the key befopre hand and reference it here as a best practice, so the key can't be seen.

again i was focusing on getting this gig working before hardening it.