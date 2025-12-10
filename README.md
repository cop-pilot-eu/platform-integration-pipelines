# 🚀 Platform Integration Pipelines

> A curated set of **CI/CD pipelines** for integrating, deploying, and validating the platform architecture components.  
> Automate installs, configuration, and end‑to‑end checks for **seamless interoperability** across the stack.

---

## 🗂️ Repository Structure

The repository is organized by component layers. Each folder contains pipelines specific to that part of the architecture.

---

### **`sif-layer-pipelines/ziti-router-deploy/`** ✳️  
Pipelines responsible for deploying, configuring, and validating the **SIF Layer**.

Contents:
- `Jenkinsfile.ziti-router-deploy` — Deploy & validate an OpenZiti Edge Router  
- `README.md` — Component-level documentation & usage guide

---

### **`data-management-pipelines/orion-context-broker/`** 🟦  
Pipelines responsible for deploying and validating the **FIWARE Orion family** of context brokers.

This directory now contains **two separate implementations**, one for NGSI-LD and one for NGSI-V2.

---

### **📁 NGSI-LD (Orion-LD)**  
**Location:**  
`data-management-pipelines/orion-context-broker/NGSI-LD/`

Contains pipelines and documentation for deploying the **Orion-LD (NGSI-LD)** semantic context broker:

- **`Jenkinsfile.orionld-context-broker-deploy`**  
  CI/CD pipeline deploying **Orion-LD + MongoDB**, including health checks and `/version` validation.

- **`README-orionld_context_broker_deploy.md`**  
  Full documentation covering parameters, workflow stages, endpoints, testing instructions, and troubleshooting.

---

### **📁 NGSI-V2 (Orion)**  
**Location:**  
`data-management-pipelines/orion-context-broker/NGSI-V2/`

Contains pipelines and documentation for deploying the **classic Orion (NGSI-V2)** context broker:

- **`Jenkinsfile.orion-context-broker-deploy`**  
  CI/CD pipeline deploying **Orion NGSI-V2 + MongoDB**, including `/version` smoke tests and validation steps.

- **`README-orion_context_broker_deploy.md`**  
  Detailed guide for NGSI-V2 deployments, parameters, stages, and health checks.

---

### **`cop-pilot-portal-pipelines/`** 🟩  
Pipelines dedicated to deploying the **COP-PILOT Portal** 

**Contents:**
- `Jenkinsfile.cop-pilot-portal-deploy` — Pulls Harbor image, deploys the Portal, and performs smoke tests  
- `README-cop-pilot-portal-deploy.md` — Full component-level documentation with parameter descriptions  
- `docker-compose.yml` — Compose file used by the deployment pipeline

---

## 📘 Documentation

This **global README** gives an overview of the repository and its structure.  
Every component folder ships its own **README.md** describing:

- 🎯 **Purpose** of the pipeline  
- ⚙️ **Steps** it executes  
- ▶️ **How to run** and **test** it

---

## 🤝 Contribution Guidelines

When adding a new pipeline:

1. 📁 **Create** a folder for the component (if it doesn’t already exist).  
2. 🧩 **Add** your pipeline file(s), e.g. `Jenkinsfile.<name>`.  
3. 📝 **Document** the pipeline in a `README.md` inside that folder.  
4. 🧭 **Update** this global README with a short entry describing the new folder.

> Tip: Keep docs concise and consistent—small examples and copy‑paste snippets help reviewers and users.

---

## 🧭 Why this structure?

- 🧱 **Scalable** – add new layers/components without reworking the repo.  
- 🧼 **Clear** – each component is self‑contained and documented.  
- 🧰 **Maintainable** – standard layout simplifies reviews and automation.

---


## 📌 Conventions

- ✅ Use `Jenkinsfile.<pipeline-name>` for pipeline files.  
- ✅ Keep secrets out of source—use Jenkins credentials and withCredentials blocks.  
- ✅ Prefer idempotent tasks so reruns are safe.  
- ✅ Add health checks and clear failure messages at the end of pipelines.

---

<p align="center">
  <sub>Built with ❤️ to make platform integration smooth and predictable.</sub>
</p>







