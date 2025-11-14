# MLflow Tracking Server on Google Cloud

[![Docs](https://img.shields.io/badge/Architecture-Drawio-red.svg)](https://raw.githubusercontent.com/rasmushaa/mlflow-server-gcp/refs/heads/main/doc/arc.drawio)

## 📑 Table of Contents
- [Description](#description)
- [The setup includes](#the-setup-includes)
- [How to develop](#how-to-develop)
- [Run Locally (Fast Track)](#run-locally-fast-track)
- [Project overview (Slow Track)](#project-overview-slow-track)
- [1. Repository Files](#1-repository-files)
- [2. Nginx Reverse Proxy](#2-nginx-reverse-proxy)
- [3. MLflow on Google Cloud](#3-mlflow-on-google-cloud)
- [4. Google Cloud Components](#4-google-cloud-components)
    - [4.1 Cloud Run](#41-cloud-run)
    - [4.2 Artifact Registry](#42-artifact-registry)
    - [4.3 Cloud Storage (GCS)](#43-cloud-storage-gcs)
    - [4.4 Cloud SQL (PostgreSQL)](#44-cloud-sql-postgresql)

---

## Description
This repository contains a plain MLflow server packaged as a Docker image.  
It can be deployed locally or on Google Cloud Run (recommended for a low-maintenance, low-cost setup).

## The setup includes
- MLflow tracking backend
- Nginx reverse proxy for basic authentication
- Support for Cloud SQL + Cloud Storage on GCP
- GitHub Actions CI/CD pipeline for automatic deployments


## How to develop
There are no branches, or environments.  
Each commit to remote on main will build and deploy a new latest server.  
You should validate your changes with local docker before pushing anything.  
In theory, this repo is only the `mlflow` server deployment tool,  
and all of the existing data is still secured on `GCS` and `CloudSQL`,  
no matter if the server itself works or not.


## Run Locally (Fast Track)
If you just want to spin up the MLflow server on your machine, you can build and run the container directly.
Run:
```
bash run_local_docker.sh
```
This script:
- Builds the Docker image with the `latest` tag
- Stops and removes any previous MLflow container
- Starts a new container mapped to `http://localhost:8080`
- Loads configuration from your local `.env` file

### Local `.env` Example
Create a `.env` file in the repo root with:
```
BACKEND_STORE_URI=sqlite:///mlflow.db
ARTIFACT_ROOT=./artifacts
MLFLOW_TRACKING_PASSWORD=user
MLFLOW_TRACKING_USERNAME=user
MLFLOW_SERVER_ALLOWED_HOSTS=127.0.0.1,localhost
```
These settings emulate the Cloud Run environment but use local storage and SQLite.  
The reverse proxy (Nginx) starts inside the container; once its logs show "running",   
you can open the UI or run an example experiment using the `run_experiment.ipynb` notebook.


## Project Overview (Slow Track)
## 1. Repository Files
| File                    | Purpose                                                                |
| ----------------------- | ---------------------------------------------------------------------- |
| `server.sh`             | Main entrypoint: starts Nginx + MLflow server                          |
| `nginx.conf`            | Reverse proxy config: listens on a fixed port and forwards to MLflow   |
| `Dockerfile`            | Builds the MLflow + Nginx image                                        |
| `build_and_deploy.yaml` | GitHub Actions workflow that builds the image and deploys to Cloud Run |

## 2. Nginx Reverse Proxy
This setup uses Nginx as a lightweight reverse proxy that **enforces basic authentication**.  
It sits *in front* of the MLflow server, so MLflow can’t be accessed without credentials.  
Key points:
- Credentials are generated at runtime from environment variables
- They are written into `/etc/nginx/.htpasswd` inside the container
- Only ports declared in `MLFLOW_SERVER_ALLOWED_HOSTS` can reach MLflow
- Nginx protects all MLflow endpoints; nothing bypasses it
- This keeps the container self-contained and easy to deploy.


## 3. MLflow on Google Cloud
When deployed on GCP, MLflow requires:
- Cloud Storage (GCS) → to store artifacts (models, images, metrics, etc.)
- Cloud SQL (PostgreSQL) → to store metadata and tracking tables
- Cloud Run → to host the server in a secure and scalable environment.  

All external backend/paths are controlled by environment variables passed to the container at runtime.


# 4. Google Cloud Components
## 4.1 Cloud Run
Cloud Run hosts the MLflow server as a serverless container. Key things to understand:
- Cloud Run only bills when requests are handled (very cost-efficient).
- MLflow needs ~1.6 GB memory to run reliably, so don’t choose the smallest memory tier.
- Deployment is handled through GitHub Actions, and each deployment automatically updates the container.
- The service uses a **dedicated service account**, passed in at deploy time.  
This account should **not** have broad permissions—only the minimum needed to access your GCS bucket and Cloud SQL instance.

Authentication access:
- MLflow behind Nginx uses username/password (from env vars).
- Cloud Run itself must allow “unauthenticated” visitors unless you choose to enable IAM login as well.
- You may switch Cloud Run to “Require Authentication” when not actively using the server to protect it.

Important:
Add the Cloud Run URL to `MLFLOW_SERVER_ALLOWED_HOSTS`.
This must be done after the first deployment, because you don’t know the URL beforehand.


## 4.2 Artifact Registry
The GitHub Actions workflow pushes the latest Docker image to Artifact Registry.
To save costs:
- Enable automatic deletion of untagged images
- Keep only the latest version

The cost for a single latest image is usually around $0.01/month


## 4.3 Cloud Storage (GCS)
MLflow needs a bucket for storing:
- model files
- artifacts
- metrics
- anything not written to SQL

You can:
- Create a dedicated new bucket
- Or use a folder inside an existing bucket

If the bucket is in a US region, GCS has a free storage tier—so you mainly pay only for data transfer.


## 4.4 Cloud SQL (PostgreSQL)
Create a Cloud SQL instance with PostgreSQL. Tips:
- You can use the smallest shared-core instance (“the potato CPU”), which is enough for MLflow.
- You only pay for allocated storage (≈ $0.05/day for 10 GB) plus network egress.
- You may turn the instance off when not using it, but note:
    - Storage charges still apply
    - Public IP reservation costs ~ $0.25/day (unless removed when turned off)

### Public IP vs Private IP
| Option         | Pros                                       | Cons                                               |
| -------------- | ------------------------------------------ | -------------------------------------------------- |
| **Public IP**  | No VPC connector needed, cheaper to run    | Slightly less secure; need to store DB credentials |
| **Private IP** | Most secure; Cloud Run connects internally | Requires Serverless VPC Connector (~$12/month)     |

### Important details:
With public IP, Cloud Run’s service account needs Cloud SQL Client/Admin permissions.
With private IP, Cloud Run must be configured with a VPC connector, and the SQL instance must be attached as a resource.
You can toggle public IP on/off to save costs when the instance is idle.


