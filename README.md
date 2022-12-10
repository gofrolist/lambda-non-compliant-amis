# Task description

Our security team releases hardened AMIs on a weekly basis. These AMIs are hardened to
patch upstream vulnerabilities and are tested to ensure that the AMIs comply with
industry standards that we are required to adhere to.
As part of compliance, we are required to ensure that we do not have any instances
that are running with non-compliant AMIs.
We need to continually scan a given region in our AWS account and find any instances
running non-compliant AMIs, generate a list of these instances, send an email out and
shut these down (if possible).
We have elected to perform this compliance task by way of running a Lambda in AWS that
runs hourly.


# Deploy

Setup your AWS profile

	export AWS_PROFILE=dev

Deploy Lambda function using terraform

	terraform init
	terraform plan
	terraform apply -var='compliant_amis=["ami-0fc15bc5cb6f1dbd6","ami-0b2698dd30af10d0a"]' -var="email=report@example.com"

You will get a verification email after terraform apply.

If you will run this Lambda function for the first time with a new email it will do nothing but sent a verification email.
To avoid that you can initially create your email address in AWS SES.
https://docs.aws.amazon.com/ses/latest/dg/verify-addresses-and-domains.html


# Contributing

Install Docker Desktop
https://docs.docker.com/desktop/install/mac-install/

Install AWS SAM Cli
https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html

	brew tap aws/tap
	brew install aws-sam-cli

Setup your AWS profile

	export AWS_PROFILE=dev

Build local docker with your lambda and invoke it

	sam build
	sam local invoke NonCompliantAMI -e events.json
