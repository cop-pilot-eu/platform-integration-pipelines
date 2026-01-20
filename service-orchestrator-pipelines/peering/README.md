# 🚀 Maestro TMF Organization & Peering Jenkins Pipeline

## 📌 Overview

This Jenkins pipeline automates the **creation of a TMF Organization in
Maestro** and the **initialization of the peering process** between
Maestro and an external OpenSlice domain.\
It also enriches Maestro with **service specifications**, **service
catalogs**, and **service categories** derived from the peering
response.

The pipeline is designed for the **COP-PILOT platform integration** and
runs on the Jenkins agent labeled **`doc-vm`**.

------------------------------------------------------------------------

## 🔄 High-Level Flow

1.  🔐 Authenticate against Maestro (OAuth2)
2.  🧩 Render TMF Organization payload
3.  🏢 Create Organization in Maestro
4.  🔍 Validate Peering API access
5.  🔗 Start Peering process
6.  📦 Import Service Specs & Catalogs
7.  🧹 Clean up temporary artifacts

------------------------------------------------------------------------

## 🖥️ Jenkins Agent

-   **Agent label:** `doc-vm`
-   **Required tools:**
    -   `curl`
    -   `python3`
    -   `jq`
    -   🌐 Internet access (OpenStreetMap Nominatim)

------------------------------------------------------------------------

## ⚙️ Pipeline Parameters

### 🔐 Maestro / Keycloak Authentication

  **Parameter**   **Description**
  --------------- ----------------------------------------
  `KC_USERNAME`   Maestro (Keycloak) username
  `KC_PASSWORD`   Maestro (Keycloak) password *(masked)*

------------------------------------------------------------------------

### 🏢 Organization & Catalog Metadata

  **Parameter**             **Description**
  ------------------------- --------------------------------------------
  `TMF_PARTY_ORG`           Organization name to be created in Maestro
  `SERVICE_CATALOG_NAME`    Name of the Service Catalog to create
  `SERVICE_CATEGORY_NAME`   Name of the Service Category
  `CITY`                    Organization city
  `COUNTRY`                 Organization country
  `POST_CODE`               Postal code
  `STATE_OR_PROVINCE`       State or province
  `STREET`                  Street address

------------------------------------------------------------------------

### 📍 Geolocation

  -----------------------------------------------------------------------
  **Parameter**                    **Description**
  -------------------------------- --------------------------------------
  `LATLON`                         Optional `"LAT, LON"` pair *(skips
                                   geocoding if provided)*

  -----------------------------------------------------------------------

------------------------------------------------------------------------

### 🔗 OpenSlice Integration

  **Parameter**             **Description**
  ------------------------- -----------------------------------
  `OPENSLICE_TMF_API_URL`   Base URL of the OpenSlice TMF API
  `OS_USERNAME`             OpenSlice username
  `OS_PASSWORD`             OpenSlice password *(masked)*

------------------------------------------------------------------------

## 🧪 Environment Variables

These values are defined directly in the pipeline and normally **do not
need to be changed** unless endpoints change.

-   🔑 `TOKEN_URL` -- OAuth2 token endpoint\
-   🆔 `CLIENT_ID` -- OAuth2 client ID (`tmf-api`)\
-   🧩 `MAESTRO_TMF_BASE` -- Maestro TMF API base URL\
-   🏗️ `CREATE_ORG_PATH` -- TMF Organization creation path\
-   🔗 `PEERING_API_BASE` -- Maestro Peering API base URL\
-   ▶️ `PEERING_PATH` -- Start peering endpoint\
-   ➕ `PEERING_ADD_PATH` -- Add peering details endpoint\
-   📁 `PEERING_DIR` -- Repository-relative pipeline directory\
-   📄 `TEMPLATE_JSON` -- Organization JSON template

------------------------------------------------------------------------

## 🧱 Pipeline Stages

### 1️⃣ Get OAuth Token

-   Authenticates using **Resource Owner Password Grant**
-   Retrieves OAuth2 access token
-   Stores token temporarily in `access_token.txt`

------------------------------------------------------------------------

### 2️⃣ Render Organization JSON

-   Loads `tmf_party_organization.json`
-   Resolves latitude & longitude
-   Injects OpenSlice credentials and endpoints
-   Produces `organization_payload.json`

------------------------------------------------------------------------

### 3️⃣ Create Organization in Maestro TMF

-   Sends `POST` request to Maestro TMF API
-   Accepts HTTP `200` or `201`

------------------------------------------------------------------------

### 4️⃣ Debug Peering Auth

-   Executes `GET` against Peering API
-   Dumps headers & body for troubleshooting

------------------------------------------------------------------------

### 5️⃣ Start Peering Process

**Sub-steps:**

-   **Start Peering**
-   **Enrich Peering Payload**
-   **Add Peering Details**

------------------------------------------------------------------------

## 🧹 Post Actions (Cleanup)

-   Removes OAuth tokens
-   Deletes temporary JSON files
-   Ensures no sensitive data remains on disk

------------------------------------------------------------------------

## ✅ Expected Outcome

-   Organization exists in Maestro
-   Peering with OpenSlice is established
-   Service Specifications imported
-   Service Catalog & Category created

------------------------------------------------------------------------

## 📝 Notes & Best Practices

-   Prefer `LATLON` if geocoding is unreliable
-   Store secrets in Jenkins credentials
-   Pipeline is **not fully idempotent**

------------------------------------------------------------------------

## 🔗 Related Components

-   Maestro TMF APIs
-   Maestro Peering APIs
-   OpenSlice TMF APIs
-   COP-PILOT Platform Integration Pipelines
