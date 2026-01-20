# 🚀 Jenkins Pipeline: Expose OpenSlice via OpenZiti (NetFoundry)

This Jenkins pipeline provisions all required **OpenZiti Edge objects**
to expose an **OpenSlice** endpoint **securely and privately** through
OpenZiti.

It automates the creation of:

-   🔌 **Intercept Config** -- what clients *dial*
-   🧭 **Host Config** -- what the host identity *binds to* and forwards
    traffic to
-   📡 **Service**
-   🔐 **Service Policies**
    -   **Dial Policy** -- controls *who can access* the service
    -   **Bind Policy** -- controls *who can host* the service

------------------------------------------------------------------------

## 🧱 What This Pipeline Creates

All objects are derived from the provided `BASE_NAME`.

  Ziti Object        Generated Name
  ------------------ --------------------------------
  Service            `<BASE_NAME>`
  Intercept Config   `<BASE_NAME>-intercept-config`
  Host Config        `<BASE_NAME>-host-config`
  Dial Policy        `<BASE_NAME>-dial-policy`
  Bind Policy        `<BASE_NAME>-bind-policy`

### 🔎 Traffic Flow

**Client side (Intercept):**

    SERVICE_IP:SERVICE_PORT

**Backend forwarding (Host):**

    SERVICE_IP:SERVICE_PORT

------------------------------------------------------------------------

## ⚙️ Pipeline Parameters

  -----------------------------------------------------------------------------------------
  Parameter              Description                         Example
  ---------------------- ----------------------------------- ------------------------------
  `BASE_NAME`            Base name for all Ziti objects      `openslice-central-domain-2`

  `SERVICE_IP`           Backend IP to expose via Ziti       `49.13.48.36`

  `SERVICE_PORT`         Backend port to expose              `30735`

  `HOST_IDENTITY_NAME`   Ziti identity **name** that         `maestro-host`
                         binds/hosts the service             

  `PROTOCOLS`            Intercept protocols                 `tcp` or `tcp,udp`
  -----------------------------------------------------------------------------------------

------------------------------------------------------------------------

## 🔐 Fixed Dial Identities

The pipeline always assigns the same **dial identities**:

    FIXED_DIAL_IDENTITIES='@PsugFlXf6,@IFi2o73f63,@SKR9uIjfx3'

🚨 Only these identities will be able to **see and access** the service.

------------------------------------------------------------------------

## 🛠️ How It Works

### 1️⃣ Validate Parameters

-   Ensures `SERVICE_PORT` is numeric and between **1--65535**

-   Validates `BASE_NAME` format:

        ^[a-zA-Z0-9][a-zA-Z0-9._-]*$

-   Confirms:

    -   `ziti` CLI is available
    -   `ZITI_ID_FILE` is readable

------------------------------------------------------------------------

### 2️⃣ Ziti Login

Authenticates to the Ziti controller using:

    ziti edge login "${ZITI_CTRL}" --file "${ZITI_ID_FILE}" -y

------------------------------------------------------------------------

### 3️⃣ Create Configs, Service & Policies

#### 📌 Intercept Config (`intercept.v1`)

-   `addresses`: `[SERVICE_IP]`
-   `portRanges`: `[SERVICE_PORT]`
-   `protocols`: from `PROTOCOLS`
    -   e.g. `["tcp"]` or `["tcp","udp"]`

#### 📌 Host Config (`host.v1`)

-   `address`: `SERVICE_IP`
-   `port`: `SERVICE_PORT`

#### 📡 Service

-   Created with **both configs attached**

#### 🔐 Policies

-   **Dial Policy** → `FIXED_DIAL_IDENTITIES`
-   **Bind Policy** → `@HOST_IDENTITY_NAME`

------------------------------------------------------------------------

✨ Once completed, the OpenSlice endpoint is securely exposed **only**
to authorized Ziti identities --- no public networking required.
