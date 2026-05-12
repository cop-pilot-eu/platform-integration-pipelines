# 🚀 Platform Integration Pipelines

> A curated set of **CI/CD pipelines** for integrating, deploying, and
> validating platform architecture components.\
> The repository automates installation, configuration, and end‑to‑end
> checks to ensure **seamless interoperability** across the COP‑PILOT
> stack.

------------------------------------------------------------------------

## 🗂️ Repository Structure

The repository is organized by **platform layers and components**.\
Each folder is self‑contained and includes its own pipelines and
documentation.

------------------------------------------------------------------------

## 🟩 COP‑PILOT Portal Pipelines

**Path:** `cop-pilot-portal-pipelines/`

Pipelines responsible for deploying and validating the **COP‑PILOT
Portal**.

**Contents:** - `Jenkinsfile.cop-pilot-portal-deploy` --- Pulls the
Portal image from Harbor, deploys it, and performs smoke tests -
`README-cop-pilot-portal-deploy.md` --- Pipeline parameters, stages, and
validation steps - `docker-compose.yml` --- Docker Compose file used by
the deployment pipeline

------------------------------------------------------------------------

## 🟦 Data Management Pipelines -- Orion Context Broker

**Path:** `data-management-pipelines/orion-context-broker/`

Pipelines responsible for deploying and validating **FIWARE Orion
Context Brokers**.\
This directory contains **two distinct implementations**:

------------------------------------------------------------------------

### 📁 NGSI‑LD (Orion‑LD)

**Path:** `data-management-pipelines/orion-context-broker/NGSI-LD/`

Pipelines and documentation for deploying the **Orion‑LD (NGSI‑LD)**
semantic context broker.

**Contents:** - `Jenkinsfile.orionld-context-broker-deploy` --- Deploys
Orion‑LD and MongoDB with health checks -
`README-orionld_context_broker_deploy.md` --- Parameters, pipeline
stages, endpoints, and troubleshooting

------------------------------------------------------------------------

### 📁 NGSI‑V2 (Classic Orion)

**Path:** `data-management-pipelines/orion-context-broker/NGSI-V2/`

Pipelines and documentation for deploying the **classic Orion
(NGSI‑V2)** context broker.

**Contents:** - `Jenkinsfile.orion-context-broker-deploy` --- Deploys
Orion NGSI‑V2 and MongoDB with smoke tests -
`README-orion_context_broker_deploy.md` --- Deployment guide,
parameters, and validation steps

------------------------------------------------------------------------

## 🟨 Service Orchestrator Pipelines -- Peering

**Path:** `service-orchestrator-pipelines/peering/`

Pipelines responsible for **TMF organization onboarding and service
peering** between Maestro and OpenSlice.

**Contents:** - `Jenkinsfile` --- Main peering pipeline (organization
creation, peering initiation, catalog enrichment) - `Jenkinsfile-v1` ---
Legacy / previous version of the peering pipeline - `templates/` --- TMF
JSON templates used by the pipeline - `README.md` --- Detailed
documentation of the peering workflow, parameters, and API interactions

------------------------------------------------------------------------

## 🟪 SIF Layer Pipelines

**Path:** `sif-layer-pipelines/`

Pipelines related to the **Secure Interconnection Fabric (SIF)** layer,
based on OpenZiti.

------------------------------------------------------------------------

### 📁 Ziti Identity & Utilities

**Path:** `sif-layer-pipelines/identity-script/`

Utility scripts and documentation for Ziti identity management.

**Contents:** - `README.md` --- Usage instructions -
`ziti_install_error_and_tunnel.sh` --- Helper script for Ziti
installation and tunneling issues

------------------------------------------------------------------------

### 📁 Ziti Service Creation Pipelines

**Path:** `sif-layer-pipelines/`

Pipelines for creating and exposing platform services securely through **OpenZiti**.

**Contents:**

#### Ziti Edge Router Deployment
- `Jenkinsfile.ziti-router-deploy` --- Deploys and validates an OpenZiti Edge Router
- `Edge-Router-README.md` --- Edge Router deployment and operational notes

#### Service Exposure via Ziti

- `Jenkinsfile.ziti-OS-service-create` --- Creates OpenZiti services for OpenSlice
- `OpenSlice-service-creation.md` --- Documentation for OpenSlice service onboarding via Ziti
- `Jenkinsfile.orionld-ziti-service-create` --- Creates OpenZiti services for Orion-LD (NGSI-LD)
- `README-orionld-ziti-service-creation.md` --- Documentation for Orion-LD service onboarding via Ziti

#### Documentation & License
- `README.md` --- SIF layer overview and usage
- `LICENSE` --- Repository license

------------------------------------------------------------------------

## 🟥 Domain Orchestrator (DO) Layer Pipelines

**Path:** `domain-orchestrator-pipelines/`

Pipelines responsible for deploying and validating the **Domain Orchestrator (OpenSlice)** layer.

**Contents:**
- `Jenkinsfile.openslice-k8s-deploy` --- Deploys and validates OpenSlice on Kubernetes
- `README-openslice-k8s-deploy.md` --- Deployment guide, parameters, prerequisites, and troubleshooting

------------------------------------------------------------------------

## 📘 Documentation Philosophy

-   This **global README** provides a structural overview of the
    repository
-   Each component directory contains its own **README.md** describing:
    -   🎯 Pipeline purpose
    -   ⚙️ Parameters and configuration
    -   ▶️ Execution flow
    -   🧪 Validation and testing steps

------------------------------------------------------------------------

## 🤝 Contribution Guidelines

When adding a new pipeline:

1.  📁 Create a folder for the component (if not already present)
2.  🧩 Add pipeline files (`Jenkinsfile.<name>`)
3.  📝 Document the pipeline in a local `README.md`
4.  🧭 Update this global README with a short description

> Keep documentation concise, consistent, and focused on
> reproducibility.

------------------------------------------------------------------------

## 📌 Conventions

-   ✅ Use `Jenkinsfile.<pipeline-name>` naming
-   ✅ Never commit secrets --- use Jenkins credentials
-   ✅ Prefer idempotent pipelines
-   ✅ Always include health checks and clear failure messages

