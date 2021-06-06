
## tfgo
This is a simple proof of concept project. A SNS Topic that publishes to an SQS Queue with a Lambda function that consumes the messages.

The Lambda is written in Go and the AWS resources are managed with Terraform.

### Stages

Stage specific variables are set in `./variables` folder with .tfvars files.

A deploy pipeline would use the branch as the stage (prod would have to change to main in this case).

For example `env/dev` would parse to `terraform.dev.tfvars`.

### Code

Lambda code is managed with Go modules and a Makefile for compiling and zipping the Lambda deployment package.

### Deploy
```
go get -d -v ./...
make
terraform apply --var-file ./variables/terraform.${stage}.tfvars
```