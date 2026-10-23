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

------------------------------------------------------------------------
------------------------------------------------------------------------

# ✂️ Unpeering Pipeline

**File:** `Jenkinsfile-unpeering`

## 📌 Overview

This pipeline **removes a peered organization from HypO**. It looks up
the organization by name in the HypO TMF Party API and deletes it by
its `id`.

It is the reverse of the peering pipeline. Because the peering pipeline
creates a new organization on every run, use this pipeline to clean up
a domain before peering it again, or when a domain is decommissioned.

------------------------------------------------------------------------

## 🔄 High-Level Flow

1.  🔐 Authenticate against HypO (OAuth2)
2.  🔍 Find the organization `id` by name
3.  🗑️ Delete the organization
4.  🧹 Clean up temporary files

------------------------------------------------------------------------

## 🖥️ Jenkins Agent

-   **Agent label:** `doc-vm`
-   **Required tools:** `curl`, `python3`

------------------------------------------------------------------------

## ⚙️ Pipeline Parameters

  **Parameter**     **Description**
  ----------------- ------------------------------------------------------------
  `TMF_PARTY_ORG`   Name of the organization to remove (e.g. `openslice-cl4-jig`)

------------------------------------------------------------------------

## 🔐 Jenkins Credentials

  **Credential ID**         **Type**            **Used for**
  ------------------------- ------------------- ------------------------------------------
  `hypo_kc_credentials`     Username/Password   HypO (Keycloak) user for the token request
  `tmf_api_client_secret`   Secret text         OAuth2 client secret of `tmf-api`

------------------------------------------------------------------------

## 🧪 Environment Variables

-   🔑 `TOKEN_URL` -- OAuth2 token endpoint
-   🆔 `CLIENT_ID` -- OAuth2 client ID (`tmf-api`)
-   🧩 `MAESTRO_TMF_BASE` -- HypO TMF API base URL
-   🏢 `ORG_PATH` -- TMF Organization path
    (`/tmf-api/party/v4/organization`)

------------------------------------------------------------------------

## 🧱 Pipeline Stages

### 1️⃣ Get OAuth Token

-   Fails early if `TMF_PARTY_ORG` is empty
-   Gets an access token with a **Resource Owner Password Grant**, the
    same way as the peering pipeline

------------------------------------------------------------------------

### 2️⃣ Find Organization ID

-   Sends `GET ${MAESTRO_TMF_BASE}/tmf-api/party/v4/organization`
-   Matches `TMF_PARTY_ORG` against each organization's `name`, ignoring
    leading and trailing whitespace (HypO may store names like
    `" openslice-cl4-jig"`)
-   Fails if **no** organization matches, and lists the existing ones
-   Fails if **more than one** organization matches, and lists their
    ids. Nothing is deleted in that case (see Troubleshooting)

------------------------------------------------------------------------

### 3️⃣ Delete Organization in Maestro TMF

-   Sends `DELETE ${MAESTRO_TMF_BASE}/tmf-api/party/v4/organization/<id>`
-   Accepts HTTP `200`, `202` or `204`
-   Sets the build description to `Removed: <org>`

------------------------------------------------------------------------

## 🧹 Post Actions (Cleanup)

-   Deletes `access_token.txt`, `token_body.json`, `organizations.json`,
    `org_id.txt`, and `delete_org_resp.json`

------------------------------------------------------------------------

## 🛠️ Troubleshooting & Notes

-   **Several organizations with the same name:** this happens when the
    peering pipeline was run more than once for a domain. The log lists
    every matching `id`. Delete the extra ones by hand with
    `DELETE .../tmf-api/party/v4/organization/<id>`, then rerun this
    pipeline for the remaining one.
-   **Peering monitor:** if the domain is removed for good, also remove
    it from `EXPECTED_PEERS` in `Jenkinsfile-peering-monitor`, or the
    monitor will report it as missing.

------------------------------------------------------------------------
------------------------------------------------------------------------

# 🧨 Unpeering All Pipeline

**File:** `Jenkinsfile-unpeering-all`

## 📌 Overview

This pipeline **removes every organization from HypO except
`UBITECH`**. Use it to clean up HypO completely before running the
peering procedure again for all domains.

> ⚠️ This is destructive. It runs as a **dry run by default** and only
> lists what it would delete. Uncheck `DRY_RUN` to actually delete.

------------------------------------------------------------------------

## 🔄 High-Level Flow

1.  🔐 Authenticate against HypO (OAuth2)
2.  📋 List all organizations and pick the ones to delete
3.  🗑️ Delete them one by one (skipped when `DRY_RUN` is checked)
4.  🧹 Clean up temporary files

------------------------------------------------------------------------

## 🖥️ Jenkins Agent

-   **Agent label:** `doc-vm`
-   **Required tools:** `curl`, `python3`

------------------------------------------------------------------------

## ⚙️ Pipeline Parameters

  **Parameter**   **Default**   **Description**
  --------------- ------------- --------------------------------------------------------------
  `DRY_RUN`       `true`        If checked, only list the organizations that would be deleted

------------------------------------------------------------------------

## 🔐 Jenkins Credentials

Same as the unpeering pipeline: `hypo_kc_credentials` and
`tmf_api_client_secret`.

------------------------------------------------------------------------

## 🧱 Pipeline Stages

### 1️⃣ Get OAuth Token

-   Gets an access token with a **Resource Owner Password Grant**, the
    same way as the peering pipeline

------------------------------------------------------------------------

### 2️⃣ List Organizations to Delete

-   Sends `GET ${MAESTRO_TMF_BASE}/tmf-api/party/v4/organization`
-   Logs every organization as `KEEP`, `DELETE`, or `SKIP` (no `id`)
-   Organizations whose name is in `KEEP_ORGS` are kept. The comparison
    ignores case and leading/trailing whitespace. By default
    `KEEP_ORGS = {"UBITECH"}`

------------------------------------------------------------------------

### 3️⃣ Delete Organizations in Maestro TMF

-   With `DRY_RUN=true`, prints how many organizations would be deleted
    and stops
-   Otherwise sends `DELETE .../tmf-api/party/v4/organization/<id>` for
    each one, accepting HTTP `200`, `202` or `204`
-   Keeps going if one delete fails, then fails the build at the end
    with the number of failures

------------------------------------------------------------------------

## 🧹 Post Actions (Cleanup)

-   Deletes `access_token.txt`, `token_body.json`, `organizations.json`,
    `orgs_to_delete.json`, `orgs_to_delete.tsv`, and
    `delete_org_resp.json`

------------------------------------------------------------------------

## 🛠️ Notes

-   **Keeping more organizations:** add their names to the `KEEP_ORGS`
    set in the **List Organizations to Delete** stage
-   **Peering monitor:** until the domains are peered again, the peering
    monitor will report all of them as missing and email their
    contacts. Disable the monitor job while you clean up and re-peer
-   **Re-peering:** run `Jenkinsfile` (or `Jenkinsfile-pnet`) once for
    each domain afterwards
