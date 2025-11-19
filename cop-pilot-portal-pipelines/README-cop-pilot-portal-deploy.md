# 📦 COP-PILOT Portal Deployment Pipeline  
### `Jenkinsfile.cop-pilot-portal-deploy`

> CI/CD pipeline for partners to **pull**, **deploy**, and **verify** the COP-PILOT Portal using images hosted on **Harbor**.

This pipeline is designed for external partners who need to deploy the portal on their own VM (connected to the COP-PILOT SIF Network).  
It performs environment validation, pulls the correct Harbor image, deploys the container via Docker Compose, and finally performs a health check.

---

## 🧭 Overview

This Jenkins pipeline automates the portal deployment workflow:

- ✔️ Validates repo layout (`docker-compose.yml`, `.env`)
- 🐳 Authenticates to **Harbor**
- 📥 Pulls the selected portal image tag
- 🚀 Deploys using **docker compose**
- 🔎 Performs health/smoke checks on port `3000`

---

## ⚙️ Pipeline Parameters

| Parameter | Default | Description |
|----------|---------|-------------|
| **AGENT_LABEL** | `partner-node` | The Jenkins node (VM) where deployment runs. |
| **DOCKER_TAG** | `latest` | Harbor image tag to deploy, e.g. `0.1.15`. |

Partners select their VM by choosing the correct **Jenkins node label**.

---

## 🌐 Environment Variables (Internal)

| Variable | Description |
|----------|-------------|
| `APP_NAME` | Portal service name (used in Docker Compose). |
| `DOCKER_REG` | Harbor registry hostname. |
| `DOCKER_REPO` | Harbor project/repo path. |
| `DOCKER_REG_CREDS` | Jenkins credentials ID for Harbor login. |

These are pre-configured inside Jenkins and **should not be modified by partners**.

---

## 🔄 Pipeline Stages

### 1️⃣ Check_Repo_Layout

Ensures required files exist:

- `docker-compose.yml` or equivalent  
- `.env` file (optional but recommended)

Aborts if compose file is missing.

---

### 2️⃣ Pull_Image_From_Harbor

Logs into Harbor using Jenkins credentials.  
Pulls the requested image tag using Docker Compose:

```bash
docker compose pull
```

This ensures the **exact** Harbor image is deployed.

---

### 3️⃣ Deployment

Starts or updates the portal stack via:

```bash
docker compose up -d
```

Then displays running containers with:

```bash
docker ps
```

---

### 4️⃣ Smoke_Test

Validates that the portal is reachable on:

```bash
http://localhost:3000
```

It retries for up to **60 seconds** (12 × 5s) before marking failure.

Success message:

```text
Smoke test OK: portal is responding.
```

---

## 🧯 Failure Handling

If any stage fails, Jenkins automatically:

- Shows `docker compose ps`
- Prints last **100 lines** of the portal service logs

This helps partners quickly troubleshoot.

---

## 📁 Repository Requirements

Place these files in the pipeline workspace:

```text
docker-compose.yml
.env (optional)
```

Your docker-compose must reference the Harbor image using environment variables:

```yaml
image: ${DOCKER_REG}${DOCKER_REPO}${APP_NAME}:${DOCKER_TAG}
```

This allows the pipeline to inject the correct values.

---

## 🚀 Typical Usage Flow

1. Partner configures VM and Jenkins agent label  
2. Opens the pipeline in Jenkins  
3. Chooses:
   - `AGENT_LABEL` → their VM  
   - `DOCKER_TAG` → desired Harbor tag  
4. Clicks **Build**  
5. Pipeline deploys & validates the portal

---

## 📬 Support

If you need help troubleshooting deployments or onboarding your VM into the COP-PILOT CI/CD infrastructure, contact the core DevOps team.
