# 📦 COP-PILOT Portal Deployment Pipeline
### `Jenkinsfile.cop-pilot-portal-deploy`

> CI/CD pipeline for partners to **pull**, **deploy**, and **seed** the COP-PILOT Portal using images hosted on **Harbor**.

This pipeline is designed for partners who need to deploy the portal on their own VM.
It pulls the correct Harbor image, deploys the container via Docker Compose, and optionally seeds an initial admin user.

---

## 🧭 Overview

This Jenkins pipeline automates the portal deployment workflow:

- 🐳 Authenticates to **Harbor**
- 📥 Pulls the selected portal image tag
- 🚀 Deploys using **docker compose** with environment variables from parameters
- 👤 Optionally seeds an admin user via the Better Auth API

---

## ⚙️ Pipeline Parameters

| Parameter | Default | Description |
|----------|---------|-------------|
| **AGENT_LABEL** | `dev00` | The Jenkins node (VM) where deployment runs. |
| **DOCKER_TAG** | `latest` | Harbor image tag to deploy, e.g. `0.1.15`. |
| **SEED_ADMIN** | `true` | Seed an initial admin user after deployment. |
| **ADMIN_EMAIL** | `admin@example.com` | Email for the seeded admin user. |
| **ADMIN_PASSWORD** | `ChangeMe123!` | Password for the seeded admin user. |
| **TMF_BASE_URL** | *(empty)* | Base URL of the TM Forum API gateway (optional). |
| **TMF_API_KEY** | *(empty)* | Bearer token for TMF requests (optional). |
| **LLM_ASSISTANT_ENDPOINT** | *(empty)* | External LLM assistant endpoint (optional). |
| **LLM_ASSISTANT_API_KEY** | *(empty)* | Bearer token for the assistant endpoint (optional). |

Partners select their VM by choosing the correct **Jenkins node label**.

---

## 🔑 Jenkins Credentials (Required)

| Credential ID | Type | Purpose |
|---|---|---|
| `harbor-creds` | Username/Password | Harbor registry login. |
| `cop-pilot-portal-auth-secret` | Secret text | `BETTER_AUTH_SECRET` for Better Auth session tokens. |

These must be configured in Jenkins before running the pipeline.

---

## 🌐 Environment Variables (Internal)

| Variable | Description |
|----------|-------------|
| `APP_NAME` | Portal service name (`cop-pilot-portal`). |
| `DOCKER_REG` | Harbor registry hostname. |
| `DOCKER_REPO` | Harbor project/repo path. |
| `DOCKER_REG_CREDS` | Jenkins credentials ID for Harbor login. |
| `BETTER_AUTH_SECRET` | Pulled from Jenkins credentials automatically. |
| `BETTER_AUTH_URL` | Auto-computed from the host IP at deploy time. |

These are pre-configured inside the pipeline and **should not be modified by partners**.

---

## 🔄 Pipeline Stages

### 1️⃣ Pull_Image

Logs into Harbor using Jenkins credentials and pulls the requested image tag:

```bash
docker pull harbor.cop-pilot.rid-intrasoft.eu/cop-pilot-portal/cop-pilot-portal:<DOCKER_TAG>
```

---

### 2️⃣ Deployment

Starts or updates the portal stack via:

```bash
docker compose up -d
```

All environment variables (`BETTER_AUTH_SECRET`, `BETTER_AUTH_URL`, TMF and LLM settings) are injected from Jenkins into the container. No `.env` file is required.

Then displays running containers with:

```bash
docker ps
```

---

### 3️⃣ Seed_Admin_User (optional)

When `SEED_ADMIN` is enabled, the pipeline waits for the portal to become healthy and then registers an initial admin user via:

```bash
POST http://localhost:3000/api/auth/sign-up/email
```

If the user already exists (HTTP 409), it continues without error.

---

## 🧯 Failure Handling

If any stage fails, Jenkins automatically runs `docker compose down` to clean up.

---

## 📁 Repository Requirements

Place these files in the pipeline workspace:

```text
docker-compose.yml
jenkins/Jenkinsfile.deploy
```

The docker-compose must reference the Harbor image using environment variables:

```yaml
image: ${DOCKER_REG}${DOCKER_REPO}${APP_NAME}:${DOCKER_TAG}
```

This allows the pipeline to inject the correct values.

---

## 🚀 Typical Usage Flow

1. Partner configures VM and Jenkins agent label
2. Creates `harbor-creds` and `cop-pilot-portal-auth-secret` credentials in Jenkins
3. Opens the pipeline in Jenkins
4. Chooses:
   - `AGENT_LABEL` → their VM
   - `DOCKER_TAG` → desired Harbor tag
   - `ADMIN_EMAIL` / `ADMIN_PASSWORD` → their admin credentials
5. Clicks **Build**
6. Pipeline pulls, deploys, and seeds the portal

---

## 📬 Support

If you need help troubleshooting deployments or onboarding your VM into the COP-PILOT CI/CD infrastructure, contact the core DevOps team.

