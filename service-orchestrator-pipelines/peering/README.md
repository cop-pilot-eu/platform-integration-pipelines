# 🚀 HypO TMF Organization & Peering Jenkins Pipeline

## 📌 Overview

This Jenkins pipeline automates the **creation of a TMF Organization in
HypO** and the **initialization of the peering process** between
HypO and an external OpenSlice domain.\
It also enriches HypO with **service specifications**, **service
catalogs**, and **service categories** derived from the peering
response.

The pipeline is designed for the **COP-PILOT platform integration** and
runs on the Jenkins agent labeled **`doc-vm`**.

> 📡 This folder also contains **`Jenkinsfile-peering-monitor`**, a
> separate pipeline that checks whether the expected OpenSlice domains
> are still peered with HypO. See
> [Peering Monitor Pipeline](#-peering-monitor-pipeline) below.

------------------------------------------------------------------------

## 🔄 High-Level Flow

1.  🔐 Authenticate against HypO (OAuth2)
2.  🧩 Render TMF Organization payload
3.  🏢 Create Organization in HypO
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

### 🔐 HypO / Keycloak Authentication

The HypO credentials are **not build parameters**. They are read from
Jenkins credentials:

  **Credential ID**         **Type**            **Used for**
  ------------------------- ------------------- ----------------------------------------------
  `hypo_kc_credentials`     Username/Password   HypO (Keycloak) user (`KC_USERNAME` / `KC_PASSWORD`)
  `tmf_api_client_secret`   Secret text         OAuth2 client secret of `tmf-api`

------------------------------------------------------------------------

### 🏢 Organization & Catalog Metadata

  **Parameter**             **Description**
  ------------------------- --------------------------------------------
  `TMF_PARTY_ORG`           Organization name to be created in HypO  
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
-   🧩 `HypO_TMF_BASE` -- HypO TMF API base URL\
-   🏗️ `CREATE_ORG_PATH` -- TMF Organization creation path\
-   🔗 `PEERING_API_BASE` -- HypO Peering API base URL\
-   ▶️ `PEERING_PATH` -- Start peering endpoint\
-   ➕ `PEERING_ADD_PATH` -- Add peering details endpoint\
-   📁 `PEERING_DIR` -- Repository-relative pipeline directory\
-   📄 `TEMPLATE_JSON` -- Organization JSON template

------------------------------------------------------------------------

## 🧱 Pipeline Stages

### 1️⃣ Get OAuth Token

-   Authenticates using **Resource Owner Password Grant**
-   Retrieves OAuth2 access token

------------------------------------------------------------------------

### 2️⃣ Render Organization JSON

-   Loads `tmf_party_organization.json`
-   Resolves latitude & longitude
-   Injects OpenSlice credentials and endpoints
-   Produces `organization_payload.json`

------------------------------------------------------------------------

### 3️⃣ Create Organization in HypO TMF

-   Sends `POST` request to HypO TMF API
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

-   Deletes temporary JSON files
------------------------------------------------------------------------

## ✅ Expected Outcome

-   Organization exists in HypO
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

-   HypO TMF APIs
-   HypO Peering APIs
-   OpenSlice TMF APIs
-   COP-PILOT Platform Integration Pipelines

------------------------------------------------------------------------
------------------------------------------------------------------------

# 📡 Peering Monitor Pipeline

**File:** `Jenkinsfile-peering-monitor`

## 📌 Overview

This pipeline checks that every expected OpenSlice domain is still
**peered with HypO**. It gets the list of active peerings from the HypO
Peering API and compares it with a hardcoded list of expected
organizations. For each organization that is missing, it emails that
domain's contacts with troubleshooting steps.

It only reads from HypO and never creates or changes a peering. To
restore a missing peering, rerun the peering pipeline (`Jenkinsfile` or
`Jenkinsfile-pnet`) for that domain.

------------------------------------------------------------------------

## 🔄 High-Level Flow

1.  🔐 Authenticate against HypO (OAuth2)
2.  📋 Get the list of active peerings
3.  ✅ Compare it with the expected organizations
4.  📧 Email the contacts of each missing organization
5.  🧹 Clean up temporary files

------------------------------------------------------------------------

## 🖥️ Jenkins Agent

-   **Agent label:** `doc-vm`
-   **Required tools:**
    -   `curl`
    -   `python3` (standard library only: `json`, `smtplib`)
    -   🌐 Outbound access to `smtp.gmail.com:587`

------------------------------------------------------------------------

## ⏰ Scheduling

The Jenkinsfile has **no `triggers {}` block**. To run the monitor
periodically, set a schedule in the Jenkins job configuration
(*Build periodically*, e.g. `H * * * *` for once an hour), or add a
`triggers { cron('...') }` block to the pipeline.

------------------------------------------------------------------------

## ⚙️ Pipeline Parameters

  **Parameter**   **Default**   **Description**
  --------------- ------------- ------------------------------------------------
  `DRY_RUN`       `false`       If checked, print who would be emailed but do not send any email

------------------------------------------------------------------------

## 🔐 Jenkins Credentials

  **Credential ID**                 **Type**            **Used for**
  --------------------------------- ------------------- ------------------------------------------
  `hypo_kc_credentials`             Username/Password   HypO (Keycloak) user for the token request
  `tmf_api_client_secret`           Secret text         OAuth2 client secret of `tmf-api`
  `peering_alert_sender_password`   Secret text         SMTP (Gmail app) password of the sender

Unlike the peering pipeline, the HypO username and password come from a
Jenkins credential instead of build parameters, so the job can run
unattended.

------------------------------------------------------------------------

## 🧪 Environment Variables

These values are defined in the pipeline:

-   🔑 `TOKEN_URL` -- OAuth2 token endpoint
-   🆔 `CLIENT_ID` -- OAuth2 client ID (`tmf-api`)
-   🔗 `PEERING_API_BASE` -- HypO Peering API base URL
-   📋 `PEERING_PATH` -- Peering list endpoint (`/peering-api/peering`)
-   📧 `SMTP_HOST` / `SMTP_PORT` -- SMTP server (`smtp.gmail.com:587`,
    STARTTLS)
-   ✉️ `SENDER_EMAIL` -- Address the alerts are sent from

------------------------------------------------------------------------

## 🧱 Pipeline Stages

### 1️⃣ Get OAuth Token

-   Gets an access token with a **Resource Owner Password Grant**, the
    same way as the peering pipeline
-   Saves the token to `access_token.txt`

------------------------------------------------------------------------

### 2️⃣ Get Active Peerings

-   Sends `GET ${PEERING_API_BASE}/peering-api/peering`
-   Expects HTTP `200` and a JSON array of peerings
-   Logs each peering (`name`, `id`, `baseUrl`)
-   Writes the sorted, de-duplicated names to `peered_names.txt`, which
    is **archived as a build artifact**

------------------------------------------------------------------------

### 3️⃣ Check Expected Peerings

-   Compares `peered_names.txt` with the `EXPECTED_PEERS` map
    (organization name → email recipients)
-   Logs `UP` or `MISSING` for each expected organization
-   Logs peerings that are not in the expected list, without acting
    on them
-   If any organization is missing:
    -   the build is marked **`UNSTABLE`**
    -   the build description is set to `Missing: <org1>, <org2>, ...`
-   Otherwise the description is set to `All expected peerings are up`

------------------------------------------------------------------------

### 4️⃣ Notify Missing Peerings

Runs only when at least one organization is missing.

-   Sends **one email per missing organization**
    -   **To:** the recipients listed for that organization in
        `EXPECTED_PEERS`
    -   **Cc:** a fixed list of NETC and HypO contacts (the `CC` list in
        the pipeline)
    -   **Subject:** `[COP-PILOT] Openslice–HypO Peering Disconnected`
-   The email asks the domain owner to:
    1.  check that their OpenSlice instance is running
    2.  check that their OpenSlice identity is online in CloudZiti, and
        re-enable the service if it is offline
    3.  contact the NETC team to rerun the peering pipeline
-   With `DRY_RUN=true`, only the emails that would be sent are printed

------------------------------------------------------------------------

## 🧹 Post Actions (Cleanup)

-   Deletes `access_token.txt`, `token_body.json`, `peerings.json`,
    `missing_peers.json`, and `missing_orgs.txt`
-   `peered_names.txt` is kept because it is archived

------------------------------------------------------------------------

## 🛠️ Maintaining the Expected Peers List

The expected organizations and their contacts are in the
`EXPECTED_PEERS` map in the **Check Expected Peerings** stage:

``` python
EXPECTED_PEERS = {
    "openslice-central": ["owner@example.com", ...],
    ...
}
```

-   **Add a domain:** add an entry once its peering is established, or
    the monitor will report it as missing straight away
-   **Remove a domain:** delete its entry when the domain is
    decommissioned
-   Keys must match the peering `name` returned by HypO exactly (the
    `TMF_PARTY_ORG` used when the domain was peered)
-   To change the shared Cc recipients, edit the `CC` list in the
    **Notify Missing Peerings** stage

------------------------------------------------------------------------

## ✅ Expected Outcome

  **Result**   **Meaning**
  ------------ --------------------------------------------------------------
  `SUCCESS`    All expected peerings are up, and no emails were sent
  `UNSTABLE`   One or more peerings are missing, and alert emails were sent (unless `DRY_RUN`)
  `FAILURE`    Token request, peering API call, or SMTP delivery failed
