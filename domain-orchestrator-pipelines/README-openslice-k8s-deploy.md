# 🚀 OpenSlice (Domain Orchestrator) Kubernetes Deployment --- Jenkins Pipeline

> CI/CD pipeline to **deploy**, **configure**, and **validate** the ETSI
> **OpenSlice** platform on a Kubernetes cluster using Helm.

---

## 🧭 Overview

This Jenkins pipeline (`Jenkinsfile.openslice-k8s-deploy`) automatically
deploys a fully functional **OpenSlice** stack on Kubernetes, including:

- 🐳 All OpenSlice microservices (TMF API, Portal, Keycloak, MySQL, Artemis, etc.)
- 🌐 NGINX Ingress Controller configured as **NodePort** over **HTTP**
- 🔓 Keycloak **SSL disable** for HTTP environments
- 🧱 CRIDGE component for Kubernetes Custom Resource management
- 🩺 Smoke test against the TMF API endpoint

Based on the official [OpenSlice Kubernetes Deployment Guide](https://osl.etsi.org/documentation/develop/getting_started/deployment/kubernetes/).

---

## 📁 Repository Layout

    cop-pilot-pipelines/
    ├─ Jenkinsfile.openslice-k8s-deploy    # OpenSlice K8s deployment pipeline
    └─ README-openslice-k8s-deploy.md      # You are here

---

## ✅ Prerequisites

Before running this pipeline, ensure the Jenkins node has:

- `kubectl` configured with cluster access
- `helm` installed (v3+)
- `git` installed
- Network access to `https://labs.etsi.org` (to clone the repo)
- Kubernetes cluster meeting minimum requirements:
  - **4 CPU cores** (8 recommended)
  - **8 GB RAM** (16 recommended)
  - **30 GB storage** (50 recommended)

---

## ⚙️ Pipeline Parameters

### Deployment Target

| Parameter      | Default           | Description                                            |
| -------------- | ----------------- | ------------------------------------------------------ |
| `NODE_LABEL`   | `openslice-node`  | Jenkins node label where the pipeline runs             |
| `GIT_BRANCH`   | `main`            | Branch to deploy (`main` = stable, `develop` = latest) |
| `NAMESPACE`    | `openslice`       | Kubernetes namespace for OpenSlice                     |
| `HELM_RELEASE` | `openslice`       | Helm release name                                      |
| `ROOT_URL`     | *(auto-detected)* | Root URL (e.g. `http://<master-ip>:<nodeport>`)        |

### Database & Keycloak

| Parameter                 | Default    | Description             |
| ------------------------- | ---------- | ----------------------- |
| `MYSQL_ROOT_PASSWORD`     | `letmein`  | MySQL root password     |
| `MYSQL_OPENSLICE_DB`      | `osdb`     | OpenSlice database name |
| `KEYCLOAK_ADMIN_PASSWORD` | `Pa55w0rd` | Keycloak admin password |

### Ingress & Networking

| Parameter               | Default           | Description               |
| ----------------------- | ----------------- | ------------------------- |
| `INGRESS_NODEPORT_HTTP` | *(auto-detected)* | NodePort for HTTP ingress |

### CRIDGE (Kubernetes CR Management)

| Parameter         | Default   | Description                              |
| ----------------- | --------- | ---------------------------------------- |
| `ENABLE_CRIDGE`   | `true`    | Deploy CRIDGE component                  |
| `KUBECONFIG_PATH` | *(empty)* | Path to kubeconfig for CRIDGE (optional) |

### Keycloak Configuration

| Parameter              | Default | Description                                  |
| ---------------------- | ------- | -------------------------------------------- |
| `DISABLE_KEYCLOAK_SSL` | `true`  | Disable SSL requirement for HTTP deployments |

---

## 🧱 Pipeline Stages

### 1️⃣ Validate environment

Checks that `kubectl`, `helm`, and `git` are available and the Kubernetes cluster is reachable.

---

### 2️⃣ Clone OpenSlice repository

Clones `org.etsi.osl.main` from ETSI GitLab (selected branch).

---

### 3️⃣ Configure Web UIs

Creates mandatory configuration files from defaults:

- `config.js` (Web Portal)
- `config.prod.json` (TMF Web UI)
- `theming.scss` (TMF Web UI theming)

---

### 4️⃣ Configure Helm values

Updates `values.yaml` with:

- Root URL (auto-detected from master IP + Ingress NodePort, or manually provided)
- MySQL credentials
- Keycloak admin password
- CRIDGE enable/disable

---

### 5️⃣ Ensure NGINX Ingress Controller

Installs NGINX Ingress Controller as a **NodePort** service if not already present. Configures TCP forwarding for Artemis (port 61616).

---

### 6️⃣ Deploy OpenSlice

Runs `helm upgrade --install` with the configured chart and values.

---

### 7️⃣ Wait for pods

Polls until all pods in the OpenSlice namespace are in `Running` state. Prints pod, deployment, and service status.

---

### 8️⃣ Disable Keycloak SSL (optional)

When `DISABLE_KEYCLOAK_SSL` is enabled, executes `kcadm.sh` inside the Keycloak pod to set `sslRequired=NONE` on both `master` and `openslice` realms.

---

### 9️⃣ Smoke test

Queries the TMF Service Catalog API to verify OpenSlice is responding.

---

## 🔗 Access Points

After successful deployment:

| Purpose          | URL                                     |
| ---------------- | --------------------------------------- |
| OpenSlice Portal | `http://<master-ip>:<nodeport>`         |
| TMF Web UI       | `http://<master-ip>:<nodeport>/tmf-api` |
| Keycloak Admin   | `http://<master-ip>:<nodeport>/auth`    |

---

## 📬 Documentation

- [OpenSlice Kubernetes Deployment Guide](https://osl.etsi.org/documentation/develop/getting_started/deployment/kubernetes/)
- [OpenSlice Documentation](https://osl.etsi.org/documentation/develop/)
- [ETSI OSL GitLab](https://labs.etsi.org/rep/osl)
