# CITS5503
## What?
Lab environment/playpen for [CITS5503](http://handbooks.uwa.edu.au/units/unitdetails?code=CITS5503).
## Requires
* Terraform
* AWS credentials (`terraform/secrets.tfvars`)
* Public/private key (`terraform/cits5503.pub`)

## Create
```
cd terraform
TF_VAR_home_ip=$(wget http://ipinfo.io/ip -qO -) terraform apply -var-file=secrets.tfvars
```

