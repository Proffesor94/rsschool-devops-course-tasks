# Jenkins Pipeline for Word Cloud Generator

## Table of Contents
1. [Introduction](#introduction)
2. [Pipeline Configuration](#pipeline-configuration)
    - [Checkout Dockerfile](#checkout-dockerfile)
    - [Checkout Application Code](#checkout-application-code)
    - [Prepare Docker](#prepare-docker)
    - [Unit Tests](#unit-tests)
    - [Application Build](#application-build)
    - [Push Docker Image to ECR](#push-docker-image-to-ecr)
    - [Create ECR Secret](#create-ecr-secret)
    - [Deploy to Kubernetes with Helm](#deploy-to-kubernetes-with-helm)
3. [Artifact Storage](#artifact-storage)
4. [Repository Submission](#repository-submission)
5. [Verification](#verification)
6. [Additional Tasks](#additional-tasks)
    - [Application Verification](#application-verification)
    - [Notification System](#notification-system)
7. [Documentation](#documentation)

## Introduction
This repository contains a Jenkins pipeline configuration for building, testing, securing, and deploying a Word Cloud Generator application using Kubernetes and Helm. The pipeline automates the process of building a Docker image, pushing it to AWS ECR, and deploying the application to a Kubernetes cluster.

## Pipeline Configuration

### Checkout Dockerfile
The pipeline starts with checking out the Dockerfile and related configurations from a specified GitHub repository.

### Checkout Application Code
Next, the pipeline checks out the main application source code from a different GitHub repository to ensure the latest code is used.

### Prepare Docker
In this stage, the pipeline:
- Starts the Docker daemon.
- Installs necessary tools including AWS CLI and kubectl.
- Verifies the installations.

### Unit Tests
The pipeline builds a test environment using a multi-stage Docker build and runs unit tests to verify the functionality of the application.

### Application Build
This stage involves building the Docker image for the application using the Dockerfile checked out earlier.

### Push Docker Image to ECR
If the pipeline is configured to push images to AWS ECR, this stage:
- Logs into ECR using AWS CLI.
- Pushes the built Docker image to the specified ECR repository.

### Create ECR Secret
A Kubernetes secret for ECR authentication is created, allowing Kubernetes to pull images from ECR.

### Deploy to Kubernetes with Helm
Using Helm, the pipeline deploys the application to a Kubernetes cluster, setting the image repository and tag based on the Docker image pushed to ECR.

### Post Actions
The pipeline performs cleanup actions and sends email notifications about the build result.

## Artifact Storage
The built artifacts, including the Dockerfile and Helm chart, are stored in the Git repository. The Docker image is stored in AWS ECR.

- [Helm Chart](https://github.com/Proffesor94/rsschool-devops-course-tasks/tree/task_6/helm/word-cloud-generator)
- [Jenkinsfile](https://github.com/Proffesor94/rsschool-devops-course-tasks/blob/task_6/Jenkinsfile)
- [Dockerfile](https://github.com/Proffesor94/rsschool-devops-course-tasks/blob/task_6/Dockerfile)

## Repository Submission
A repository is created containing the Dockerfile with application, Helm chart, and Jenkinsfile. This structure allows for easy access and management of the project components.

## Verification
The pipeline is verified by running it through Jenkins. It successfully builds, tests, secures, and deploys the application to the Kubernetes cluster.

## Additional Tasks

### Notification System
A notification system is set up within Jenkins to alert stakeholders on the status of the pipeline. Notifications are sent out on pipeline failures or successes, ensuring timely awareness of the application’s state.

### Documentation
The setup and deployment process are thoroughly documented in this README file. This documentation serves as a guide for understanding and replicating the pipeline setup.