# 🚀 OpenSlice (Domain Orchestrator) Kubernetes Deployment --- Jenkins Pipeline

> CI/CD pipeline to **deploy**, **configure**, and **validate** a pinned
> release of the ETSI **OpenSlice** platform on a Kubernetes cluster using Helm.

---

## 🧭 Overview

This Jenkins pipeline (`Jenkinsfile.openslice-k8s-deploy`) deploys a fully
functional **OpenSlice** stack on Kubernetes, including:

- 🐳 All OpenSlice microservices (TMF API, Portal, Keycloak, MySQL, Artemis, etc.)
- 📌 A **pinned release** (`OSL_VERSION`, e.g. `2025Q4`): both the Helm chart and the
  OpenSlice container images are taken from that release
- 🌐 NGINX Ingress Controller configured as **NodePort** over **HTTP** (installed only if missing)
- 🔓 Keycloak **SSL disable** for HTTP environments
- 🧱 CRIDGE component for Kubernetes Custom Resource management
- 🩺 Smoke test against the Web UI, Keycloak, and the TMF API

The target cluster is reached through a **kubeconfig stored in Jenkins
credentials**; nothing is deployed on the Jenkins agent itself.

To move a running instance to a newer release, use
[`Jenkinsfile.openslice-k8s-update`](README-openslice-k8s-update.md).

Based on the official [OpenSlice Kubernetes Deployment Guide](https://osl.etsi.org/documentation/develop/getting_started/deployment/kubernetes/).

---

## 📁 Repository Layout

    domain-orchestrator-pipelines/
    ├─ Jenkinsfile.openslice-k8s-deploy    # OpenSlice K8s deployment pipeline
    ├─ README-openslice-k8s-deploy.md      # You are here
    ├─ Jenkinsfile.openslice-k8s-update    # OpenSlice K8s update pipeline
    └─ README-openslice-k8s-update.md      # Update pipeline documentation

---

## ✅ Prerequisites

**Jenkins**

- A **Secret file** credential containing the kubeconfig of the target
  cluster (default ID: `staging-kubeconfig`)
- An agent (label `NODE_LABEL`) with `kubectl`, `helm` (v3+), `git`, and `curl`
- Network access from the agent to:
  - `https://labs.etsi.org` (to clone the chart)
  - the Kubernetes API server
  - the OpenSlice root URL (for the smoke test)

**Cluster**

- Able to pull images from `labs.etsi.org:5050`
- Minimum resources: **4 CPU cores** (8 recommended), **8 GB RAM** (16 recommended),
  **30 GB storage** (50 recommended)
- Storage for MySQL: by default the chart creates a `hostPath` PV
  (`/dockerdata-nfs/osmysql`), which only fits single-node clusters.
  On multi-node or managed clusters (AKS, EKS, ...) set `STORAGE_CLASS`.

---

## ⚙️ Pipeline Parameters

### Deployment Target

| Parameter                   | Default                | Description                                                                 |
| --------------------------- | ---------------------- | --------------------------------------------------------------------------- |
| `NODE_LABEL`                | `cop-pilot-staging-cluster`       | Jenkins agent label where the pipeline runs                                 |
| `KUBECONFIG_CREDENTIALS_ID` | `staging-kubeconfig` | Jenkins **Secret file** credential with the target cluster's kubeconfig     |
| `OSL_VERSION`               | `2025Q4`               | OpenSlice release: tag/branch of `org.etsi.osl.main` (`2025Q4`, `2026Q2`, `main`, `develop`) |
| `IMAGE_TAG`                 | *(derived)*            | Image tag override. Empty: `main` → `latest`, `develop` → `develop`, otherwise `OSL_VERSION` |
| `NAMESPACE`                 | `openslice`            | Kubernetes namespace for OpenSlice                                          |
| `HELM_RELEASE`              | `openslice`            | Helm release name                                                           |
| `ROOT_URL`                  | *(auto-detected)*      | Public root URL (e.g. `http://<node-ip>:<nodeport>`)                        |
| `STORAGE_CLASS`             | *(chart default)*      | StorageClass for the MySQL PVC                                              |
| `HELM_TIMEOUT`              | `20m`                  | Timeout of `helm upgrade --install --wait`                                  |

### Credentials

| Parameter                 | Default    | Description             |
| ------------------------- | ---------- | ----------------------- |
| `MYSQL_ROOT_PASSWORD`     | `letmein`  | MySQL root password     |
| `KEYCLOAK_ADMIN_PASSWORD` | `Pa55w0rd` | Keycloak admin password |

> Both are applied only on the **first** installation: MySQL and Keycloak
> keep the passwords stored in their database afterwards.

### Ingress & Networking

| Parameter               | Default           | Description               |
| ----------------------- | ----------------- | ------------------------- |
| `INGRESS_NODEPORT_HTTP` | *(auto-detected)* | NodePort for HTTP ingress |

### CRIDGE (Kubernetes CR Management)

| Parameter                          | Default   | Description                                                                 |
| ---------------------------------- | --------- | --------------------------------------------------------------------------- |
| `ENABLE_CRIDGE`                    | `true`    | Deploy CRIDGE component                                                     |
| `CRIDGE_KUBECONFIG_CREDENTIALS_ID` | *(empty)* | Secret file credential with the kubeconfig CRIDGE manages. Empty = same as `KUBECONFIG_CREDENTIALS_ID` |

> The chart refuses to render CRIDGE without a kubeconfig, so one is always passed when CRIDGE is enabled.

### Keycloak Configuration

| Parameter              | Default | Description                                  |
| ---------------------- | ------- | -------------------------------------------- |
| `DISABLE_KEYCLOAK_SSL` | `true`  | Disable SSL requirement for HTTP deployments |

---

## 🧱 Pipeline Stages

### 1️⃣ Validate environment

Checks that `kubectl`, `helm`, `git`, and `curl` are available and that the
cluster from the Jenkins kubeconfig credential is reachable.

### 2️⃣ Clone OpenSlice repository

Clones `org.etsi.osl.main` at `OSL_VERSION` and prints the chart version / appVersion.

### 3️⃣ Configure Web UIs

Creates the configuration files the chart requires from the release defaults:

- `config.js` (Web Portal)
- `config.prod.json`, `config.theming.json`, `theming.scss` (TMF Web UI)

### 4️⃣ Ensure NGINX Ingress Controller

If no `nginx` IngressClass exists, installs the NGINX Ingress Controller as a
**NodePort** service in namespace `ingress`, with TCP forwarding for Artemis (port 61616).
An existing controller is reused as is.

### 5️⃣ Configure Helm values

Generates a values override file (the chart's `values.yaml` is not edited) with:

- `rooturl`: `ROOT_URL`, or auto-detected as `http://<node ExternalIP|InternalIP>:<ingress http NodePort>`
- MySQL root and Keycloak admin passwords
- the image tag of all OpenSlice images (`labs.etsi.org:5050/osl/...`)
- `cridge.enabled` and, if set, `storageClass`

The file is created with `0600` permissions and deleted at the end of the build.

### 6️⃣ Deploy OpenSlice

Runs `helm upgrade --install --wait` with the override file and the CRIDGE kubeconfig.

### 7️⃣ Wait for workloads

Waits for the rollout of every Deployment/StatefulSet of the release, then
prints pods, services, and ingress.

### 8️⃣ Disable Keycloak SSL (optional)

When `DISABLE_KEYCLOAK_SSL` is enabled, runs `kcadm.sh` inside the Keycloak pod
(retrying until Keycloak is up) to set `sslRequired=NONE` on the `master` and
`openslice` realms. The build fails if this does not succeed.

### 9️⃣ Smoke test

Fails the build unless the following respond within ~5 minutes each:

| Check           | Path                                                   | Expected    |
| --------------- | ------------------------------------------------------ | ----------- |
| TMF Web UI      | `/`                                                    | `200`       |
| Keycloak realm  | `/auth/realms/openslice`                               | `200`       |
| TMF Service API | `/tmf-api/serviceCatalogManagement/v4/serviceCatalog`  | `200`/`401` |

---

## 🔗 Access Points

After a successful deployment:

| Purpose            | URL                         |
| ------------------ | --------------------------- |
| TMF Web UI         | `<ROOT_URL>/`               |
| NFV Portal         | `<ROOT_URL>/nfvportal`      |
| TMF APIs           | `<ROOT_URL>/tmf-api/...`    |
| Keycloak Admin     | `<ROOT_URL>/auth`           |

---

## 🛠️ Troubleshooting

- **`A kubeconfig file is required`** – CRIDGE is enabled but no kubeconfig
  reached Helm; check the credential IDs.
- **MySQL pod `Pending`** – the PVC cannot bind; set `STORAGE_CLASS` (managed
  clusters) or make sure `/dockerdata-nfs/osmysql` exists on the node.
- **Smoke test fails but pods are running** – the agent cannot reach `ROOT_URL`,
  or the auto-detected node IP is not reachable; set `ROOT_URL` explicitly.

---

## 📬 Documentation

- [OpenSlice Kubernetes Deployment Guide](https://osl.etsi.org/documentation/develop/getting_started/deployment/kubernetes/)
- [OpenSlice Documentation](https://osl.etsi.org/documentation/develop/)
- [ETSI OSL GitLab](https://labs.etsi.org/rep/osl)
