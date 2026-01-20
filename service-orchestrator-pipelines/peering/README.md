# Maestro TMF Organization & Peering Jenkins Pipeline

## Overview

This Jenkins pipeline automates the **creation of a TMF Organization in
Maestro** and the **initialization of the peering process** between
Maestro and an external OpenSlice domain.\
It also enriches Maestro with **service specifications**, **service
catalogs**, and **service categories** derived from the peering
response.

The pipeline is designed for the **COP-PILOT platform integration** and
runs on the Jenkins agent labeled **`doc-vm`**.

------------------------------------------------------------------------

## High-Level Flow

1.  Authenticate against Maestro (OAuth2) and obtain an access token\
2.  Render a TMF Organization payload from a JSON template\
3.  Create the Organization in Maestro TMF API\
4.  Debug and validate access to the Peering API\
5.  Start the Peering process\
6.  Enrich Maestro with Service Specs and Catalogs\
7.  Clean up sensitive and temporary files

------------------------------------------------------------------------

## Jenkins Agent

-   **Agent label:** `doc-vm`
-   **Requirements on agent:**
    -   `curl`
    -   `python3`
    -   `jq`
    -   Internet access (for OpenStreetMap Nominatim geocoding)

------------------------------------------------------------------------

## Pipeline Parameters

### Maestro / Keycloak Authentication

  Parameter       Description
  --------------- --------------------------------------
  `KC_USERNAME`   Maestro (Keycloak) username
  `KC_PASSWORD`   Maestro (Keycloak) password (masked)

### Organization & Catalog Metadata

  Parameter                 Description
  ------------------------- --------------------------------------------
  `TMF_PARTY_ORG`           Organization name to be created in Maestro
  `SERVICE_CATALOG_NAME`    Name of the Service Catalog to create
  `SERVICE_CATEGORY_NAME`   Name of the Service Category
  `CITY`                    Organization city
  `COUNTRY`                 Organization country
  `POST_CODE`               Postal code
  `STATE_OR_PROVINCE`       State or province
  `STREET`                  Street address

### Geolocation

  Parameter   Description
  ----------- ----------------------------------------------------------
  `LATLON`    Optional `"LAT, LON"` pair (skips geocoding if provided)

### OpenSlice Integration

  Parameter                 Description
  ------------------------- -----------------------------------
  `OPENSLICE_TMF_API_URL`   Base URL of the OpenSlice TMF API
  `OS_USERNAME`             OpenSlice username
  `OS_PASSWORD`             OpenSlice password (masked)

------------------------------------------------------------------------

## Environment Variables

These values are defined directly in the pipeline and normally **do not
need to be changed** unless endpoints change.

-   `TOKEN_URL` -- OAuth2 token endpoint
-   `CLIENT_ID` -- OAuth2 client ID (`tmf-api`)
-   `MAESTRO_TMF_BASE` -- Maestro TMF API base URL
-   `CREATE_ORG_PATH` -- TMF Organization creation path
-   `PEERING_API_BASE` -- Maestro Peering API base URL
-   `PEERING_PATH` -- Start peering endpoint
-   `PEERING_ADD_PATH` -- Add peering details endpoint
-   `PEERING_DIR` -- Repository-relative pipeline directory
-   `TEMPLATE_JSON` -- Organization JSON template

------------------------------------------------------------------------

## Pipeline Stages

### 1. Get OAuth Token

-   Authenticates against Keycloak using **Resource Owner Password
    Grant**
-   Retrieves an OAuth2 access token
-   Stores token temporarily in `access_token.txt`
-   Fails fast if credentials are missing or authentication fails

------------------------------------------------------------------------

### 2. Render Organization JSON

-   Loads `tmf_party_organization.json` template
-   Resolves latitude & longitude:
    -   Uses `LATLON` if provided
    -   Otherwise geocodes the address via **OpenStreetMap Nominatim**
-   Injects:
    -   Address information
    -   OpenSlice credentials
    -   OpenSlice TMF API URLs
-   Produces `organization_payload.json`

------------------------------------------------------------------------

### 3. Create Organization in Maestro TMF

-   Sends a `POST` request to Maestro TMF API
-   Creates the Organization entity
-   Stores response in `create_org_resp.json`
-   Accepts HTTP `200` or `201` as success

------------------------------------------------------------------------

### 4. Debug Peering Auth

-   Executes a `GET` request to the Peering API
-   Dumps headers and body for troubleshooting
-   Useful for validating token scope and permissions

------------------------------------------------------------------------

### 5. Start Peering Process

This stage consists of **three sub-steps**:

#### a) Start Peering

-   Wraps the organization response into `peering_payload.json`
-   Sends payload to `/peering-api/peering`
-   Stores response in `peering_resp.json`

#### b) Enrich Peering Payload

-   Parses peering response (list of service specifications)
-   Filters out:
    -   `A GST(NEST) Service Example`
    -   `ResourceFacingServiceSpecification`
-   Builds:
    -   Service Specification map
    -   Service Catalog
    -   Service Category with linked specs
-   Produces `peering_payload_enriched.json`

#### c) Add Peering Details

-   Posts enriched payload to `/peering-api/peering/add`
-   Finalizes catalog & specification onboarding
-   Accepts HTTP `200`, `201`, or `202` as success

------------------------------------------------------------------------

## Post Actions (Cleanup)

Regardless of pipeline result:

-   Removes:
    -   OAuth tokens
    -   Temporary JSON payloads
    -   Debug output files
-   Ensures no sensitive data remains on disk

------------------------------------------------------------------------

## Expected Outcome

After a successful run:

-   Organization exists in Maestro
-   Peering with OpenSlice is established
-   Service Specifications are imported
-   Service Catalog and Category are created and populated

------------------------------------------------------------------------

## Notes & Best Practices

-   Use `LATLON` when geocoding is unreliable or restricted
-   Ensure Keycloak client secret is stored securely in Jenkins
    credentials
-   This pipeline is **idempotent only at API level** --- re-running may
    create duplicates if APIs allow it

------------------------------------------------------------------------

## Related Components

-   Maestro TMF APIs
-   Maestro Peering APIs
-   OpenSlice TMF APIs
-   COP-PILOT Platform Integration Pipelines
