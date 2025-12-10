# 🚀 Orion-LD (NGSI-LD) Context Broker Deploy --- Jenkins Pipeline

> CI/CD pipeline to **deploy**, **test**, and **validate** the FIWARE\
> **Orion-LD (NGSI-LD) Context Broker** together with **MongoDB** on a
> target Linux host.

------------------------------------------------------------------------

## 🧭 Overview

This Jenkins pipeline (`Jenkinsfile.orionld-deploy`) automatically
deploys\
a fully functional **Orion-LD + MongoDB** stack using Docker Compose on
a selected Jenkins agent.

It is designed to:

-   🐳 Deploy **Orion-LD** (NGSI-LD) and **MongoDB** with parameterized
    Docker Compose\
-   🧱 Generate the compose file dynamically\
-   ▶️ Launch both services and verify health\
-   🩺 Perform a **live smoke test** using the `/version` NGSI-LD API\
-   ♻️ Be **idempotent** and safe to re-run

------------------------------------------------------------------------

## 📁 Repository Layout

    cop-pilot-pipelines/
    ├─ Jenkinsfile.orionld-context-broker-deploy    # Orion-LD deployment pipeline
    └─ README.md                      # You are here

------------------------------------------------------------------------

## ✅ Prerequisites

Before running this pipeline, ensure the Jenkins node has:

-   Docker installed\
-   `docker compose` or `docker-compose`\
-   Permission to run containers\
-   Open ports:
    -   **1026** → Orion-LD\
    -   **27017** → MongoDB

The pipeline dynamically generates `docker-compose.orionld.yml`.

------------------------------------------------------------------------

## 🔧 Pipeline Parameters

  -----------------------------------------------------------------------
  Name                      Default                         Description
  ------------------------- ------------------------------- -------------
  `NODE_LABEL`              `orionld-node`                  Jenkins agent
                                                            where stack
                                                            runs

  `ORION_LD_DOCKER_IMAGE`   `fiware/orion-ld:latest`        Orion-LD
                                                            image

  `MONGO_DOCKER_IMAGE`      `mongo:4.4`                     Mongo image

  `ORION_LD_PORT`           `1026`                          Orion-LD port

  `MONGO_PORT`              `27017`                         MongoDB port
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 🧱 Stages (What the Pipeline Does)

### **1. Prepare Workspace**

Creates deployment directory (`orionld-stack/`).

------------------------------------------------------------------------

### **2. Docker Sanity Check**

Ensures Docker and Compose are installed and functional.

------------------------------------------------------------------------

### **3. Generate Docker Compose**

Creates a fully parameterized `docker-compose.orionld.yml`.

------------------------------------------------------------------------

### **4. Deploy Orion-LD + Mongo**

Runs:

    docker compose pull
    docker compose up -d

Then prints running containers.

------------------------------------------------------------------------

### **5. Smoke Test --- Orion-LD /version**

Queries repeatedly:

    http://localhost:<ORION_LD_PORT>/version

Confirms NGSI-LD is running (expects `"orionld version"`).

------------------------------------------------------------------------

## ▶️ How to Run

1.  Create a Jenkins pipeline job using this
    `Jenkinsfile.orionld-deploy`.\
2.  Select the execution node via `NODE_LABEL`.\
3.  Run the build.

------------------------------------------------------------------------

## 📤 Outputs & Artifacts

### **Containers**

-   `cop-pilot-orionld-orion-ld-1`\
-   `cop-pilot-orionld-mongo-1`

### **Volumes**

-   `mongo-data` → persistent MongoDB storage

### **Endpoints**

  Purpose             URL
  ------------------- ----------------------------------
  Orion-LD API base   `http://<node>:1026/ngsi-ld/v1/`
  Version check       `http://<node>:1026/version`

------------------------------------------------------------------------

## 🔗 Documentation

-   FIWARE Orion-LD Docs\
    https://fiware-orion.readthedocs.io/en/latest/

-   NGSI-LD ETSI Spec\
    https://www.etsi.org/committee/cim

-   Orion-LD Docker Hub\
    https://hub.docker.com/r/fiware/orion-ld

------------------------------------------------------------------------

## 🛠️ Troubleshooting

### Logs

    docker logs -f cop-pilot-orionld-orion-ld-1
    docker logs -f cop-pilot-orionld-mongo-1

### Status

    docker ps

### Test manually

    curl http://localhost:1026/version
    curl http://localhost:1026/ngsi-ld/v1/entities

### Remove stack

    docker compose -p cop-pilot-orionld -f docker-compose.orionld.yml down -v

------------------------------------------------------------------------

## 🤝 Contributing

-   Keep the pipeline idempotent\
-   Validate NGSI-LD with `/version` and entity creation\
-   Update docs when adding features\
-   Use unique entity IDs in pipeline tests
