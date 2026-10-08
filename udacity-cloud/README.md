# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, you will write a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started
1. Clone this repository

2. Create your infrastructure as code

3. Update this README to reflect how someone would use your code.

### Dependencies
1. Create an [Azure Account](https://portal.azure.com)
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
After you have either cloned this repo or copied over the files listed below you can run the following commands to build the infrastructure.
All commands below assume you are using the Bash shell in Azure.

First you need to get your subscription id
`az account show --query id --output tsv`
Then you can make this an environment variable for the rest of the run
`export SUBSCRIPTION_ID=<value-from-command>`

Now we want to enable the a policy that denys the creation of the resources without tags. This is an existing policy that you can use in Azure. The critical thing you need to do is create the policy with the name `environment`. If you do not do this, your packer and terraform commands will fail because the tag name is not put on the resource.

Now we can do a packer build with [server.json](./server.json)
`packer build server.json`

Next we can run our terraform to build out our infastructure. The files for this are [main.tf](./tf/main.tf) and [vars.tf](./tf/vars.tf) in the tf directory of this repository.
`terraform plan -out solution.plan`
The plan from the project is in [solution.plan](./solution.plan)

If the plan is good you are ready to apply.
`terraform apply solution.plan`

### Output
An output of my policy is in a [screen shot](./Screenshot%202026-10-08%20at%201.44.06 PM.png). You will notice in the tagName section of the screen shot that it says the value is "tagging-policy". I took the screen shot before I fixed the name to be `environment` to line up with my terraform and packer files. I was easily able to rename the policy in the Azure UI to correct the issue.

The final output will be the built out infrastructure. For my own run I captured the terraform in [tf_run_output.txt](./tf_run_output.txt).
