## Building / Contributing

### Install prerequisites

#### Golang

```bash
wget https://golang.org/dl/go1.17.1.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.17.1.linux-amd64.tar.gz
rm go1.17.1.linux-amd64.tar.gz
```

#### Terraform

```bash
LATEST_URL=$(curl https://releases.hashicorp.com/terraform/index.json | jq -r '.versions[].builds[].url | select(.|test("alpha|beta|rc")|not) | select(.|contains("linux_amd64"))' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | tail -1)
curl ${LATEST_URL} > /tmp/terraform.zip
(cd /tmp && unzip /tmp/terraform.zip && chmod +x /tmp/terraform && sudo mv /tmp/terraform /usr/local/bin/)
```


#### Pre-commit and tools


Follow: https://github.com/antonbabenko/pre-commit-terraform#how-to-install

### Run tests

Default tests will run through various validation steps .
```bash
make
```

To test actual deployment to AWS.
```bash
make test_aws
```

> :warning: **Warning**: This will spin up EKS and other services in AWS which will cost you some money.
