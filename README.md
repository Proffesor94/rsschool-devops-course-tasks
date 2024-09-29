## **Infrastructure Setup and Usage with GitHub Actions and AWS**

### **0. Proof of work**

You may find all the screenshots in the Screensots folder

### **1. Overview**

This guide explains how to:
- Set up an AWS environment for Terraform infrastructure management.
- Configure a GitHub Actions workflow to deploy infrastructure to AWS using OpenID Connect (OIDC).
- Use an S3 bucket for Terraform state management and automate deployments using GitHub Actions.

### **2. Prerequisites**
Before starting, ensure that you have:
- An **AWS account** with administrative access.
- A **GitHub account** with a repository where Terraform configurations will reside.
- **AWS CLI** and **Terraform** installed locally for manual testing (optional but recommended).

### **3. AWS Account Configuration**

#### **3.1. Create an IAM Role for GitHub Actions**
1. **IAM Role**: Create an IAM role (`GithubActionsRole`) that GitHub Actions can assume for Terraform deployments.
   - **Policies**: Attach the following AWS managed policies:
     - `AmazonEC2FullAccess`
     - `AmazonRoute53FullAccess`
     - `AmazonS3FullAccess`
     - `IAMFullAccess`
     - `AmazonVPCFullAccess`
     - `AmazonSQSFullAccess`
     - `AmazonEventBridgeFullAccess`

2. **Trust Policy**: Update the IAM role trust policy to allow GitHub Actions to assume this role using OIDC. Example trust policy:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
             "token.actions.githubusercontent.com:sub": "repo:<GitHubOrg>/<RepoName>:ref:refs/heads/main"
           }
         }
       }
     ]
   }
   ```

3. **OIDC Provider**: Ensure that the OIDC provider `token.actions.githubusercontent.com` is registered in AWS IAM.

#### **3.2. Set Up S3 Bucket for Terraform State Management**
1. Create an **S3 bucket** that will store the Terraform state files. Example bucket name: `terraform-states-<your-unique-suffix>`.
2. Enable **versioning** on the S3 bucket to maintain a history of Terraform states.

### **4. GitHub Repository Setup**

#### **4.1. Create a GitHub Repository**
- Create a new GitHub repository where the Terraform configuration files will be stored. 
Example repository name: `rsschool-devops-course-tasks`.

#### **4.2. Add Secrets to GitHub Repository**
- Go to your repository **Settings** > **Secrets and Variables** > **Actions**, and add the following secrets:
  - `AWS_ROLE_ARN`: The ARN of the `GithubActionsRole` you created in AWS.
  - `AWS_REGION`: The region where you are deploying the infrastructure (e.g., `us-east-1`).

### **5. Terraform Configuration**

#### **5.1. Backend Configuration for S3**
In your Terraform configuration, configure the S3 bucket for state management:

```hcl
Please take a look at main.tf
```

### **6. GitHub Actions Workflow**

#### **6.1. Create a GitHub Actions Workflow**
In your repository, create a GitHub Actions workflow file (`.github/workflows/deploy.yml`) with the following content:

```yaml
Please take a look at .github/workflows/deploy.yml
```

### **7. How the Workflow Works**
1. **`terraform-check` job**: Runs `terraform fmt -check` to validate Terraform code formatting.
2. **`terraform-plan` job**: Runs `terraform plan` to generate an execution plan without making any changes.
3. **`terraform-apply` job**: On `push` events, runs `terraform apply -auto-approve` to automatically apply the changes if everything passes.

### **8. Using the Setup**
- **Pull Requests**: The workflow runs on pull requests to check formatting and generate a plan, allowing you to review changes before merging.
- **Push to Main Branch**: On a push to the `main` branch, the workflow will automatically apply the Terraform configuration and deploy the infrastructure to AWS.

### **9. Troubleshooting**
- **OIDC Authentication Issues**: Ensure that the IAM role has the correct trust policy and that the GitHub OIDC provider is registered in AWS.
- **State Locking Issues**: Check your DynamoDB table and S3 bucket for any conflicting locks if you encounter state locking issues.

---

This setup automates your infrastructure deployments, ensuring consistency and best practices by incorporating checks for Terraform formatting, planning, and applying changes directly from your GitHub repository.
