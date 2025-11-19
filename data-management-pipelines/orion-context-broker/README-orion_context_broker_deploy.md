# 🚀 Orion Context Broker Deploy --- Jenkins Pipeline

> CI/CD pipeline to **deploy**, **test**, and **validate** a FIWARE
> **Orion Context Broker** together with **MongoDB** on a target Linux
> host.

------------------------------------------------------------------------

## 🧭 Overview

This Jenkins pipeline (`Jenkinsfile.orion-deploy`) automatically deploys
a **fully functional Orion + MongoDB stack** using Docker Compose on a
selected Jenkins agent.

It is designed to:

-   🐳 Deploy **Orion** and **MongoDB** using parameterized Docker
    Compose\
-   🧱 Generate a fresh compose file dynamically (no need for one in the
    repo)\
-   ▶️ Start both services and validate they are healthy\
-   🩺 Perform a **live smoke test** using the `/version` API\
-   ♻️ Be **fully idempotent** --- safe to re-run without breaking
    existing deployments

------------------------------------------------------------------------

## 📁 Repository Layout

    cop-pilot-pipelines/
    ├─ Jenkinsfile.orion-deploy         # This pipeline
    └─ README.md                        # You are here

------------------------------------------------------------------------

## ✅ Prerequisites

Before running this pipeline, ensure you have:

-   A Jenkins node (VM) with:
    -   Docker installed\
    -   Either `docker compose` or `docker-compose`
    -   Sufficient privileges to start containers\
-   Network access to the following ports:
    -   **1026** → Orion
    -   **27017** → MongoDB

The pipeline will dynamically generate a new `docker-compose.orion.yml`.

------------------------------------------------------------------------

## 🔧 Parameters & Inputs

  -------------------------------------------------------------------------------
  Name                   Default                 Description
  ---------------------- ----------------------- --------------------------------
  `NODE_LABEL`           `orion-node`            Jenkins agent label where this
                                                 stack will run

  `ORION_DOCKER_IMAGE`   `fiware/orion:latest`   Orion image

  `MONGO_DOCKER_IMAGE`   `mongo:4.4`             MongoDB image

  `ORION_PORT`           `1026`                  Host port for Orion

  `MONGO_PORT`           `27017`                 Host port for MongoDB
  -------------------------------------------------------------------------------

------------------------------------------------------------------------

## 🧱 Stages (What the pipeline does)

### **1. Prepare Workspace**

Creates a clean working directory (`orion-stack/`) on the Jenkins node.

------------------------------------------------------------------------

### **2. Docker Sanity Check**

Validates Docker and Compose are available.

------------------------------------------------------------------------

### **3. Generate Docker Compose**

Creates a fully parameterized `docker-compose.orion.yml` on the target
node with correct quoting and indentation.

------------------------------------------------------------------------

### **4. Deploy Orion + Mongo**

Runs:

    docker compose pull
    docker compose up -d

And prints running containers.

------------------------------------------------------------------------

### **5. Smoke Test --- Orion Version Check**

Repeatedly queries:

    http://localhost:<ORION_PORT>/version

until Orion becomes healthy.

If the service does not respond in time → the pipeline fails.

------------------------------------------------------------------------

## ▶️ How to Run

1.  Create a Jenkins pipeline job using this `Jenkinsfile.orion-deploy`.
2.  Set the desired node label (e.g., `orion-node`).
3.  Run the build.

------------------------------------------------------------------------

## 📤 Outputs & Artifacts

### **Containers**

-   `cop-pilot-orion-orion-1`
-   `cop-pilot-orion-mongo-1`

### **Volumes**

-   `mongo-data` → persistent MongoDB storage

### **Endpoints**

  Purpose          URL
  ---------------- ------------------------------
  Orion API base   `http://<node>:1026/v2/`
  Version          `http://<node>:1026/version`

------------------------------------------------------------------------

## 🔗 Documentation

-   FIWARE Orion Docs\
    https://fiware-orion.readthedocs.io/en/latest/

-   FIWARE Tutorials\
    https://fiware-tutorials.readthedocs.io/en/latest/

-   Docker Hub Images\
    https://hub.docker.com/r/fiware/orion

------------------------------------------------------------------------

## 🛠️ Troubleshooting

### Logs

    docker logs -f cop-pilot-orion-orion-1
    docker logs -f cop-pilot-orion-mongo-1

### Status

    docker ps

### Test manually

    curl http://localhost:1026/version

### Remove stack

    docker compose -p cop-pilot-orion -f docker-compose.orion.yml down -v

------------------------------------------------------------------------

## 🤝 Contributing

-   Keep the pipeline idempotent\
-   Always quote YAML fields\
-   Update this README when adding features\
-   Use `/version` to confirm deployment health
