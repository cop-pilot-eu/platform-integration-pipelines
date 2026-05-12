# 🚀 Jenkins Pipeline: Expose Orion-LD (NGSI-LD) via OpenZiti (NetFoundry)

This Jenkins pipeline provisions all required **OpenZiti Edge objects**
to expose an **Orion-LD Context Broker** endpoint **securely and privately** through
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

| Ziti Object      | Generated Name                 |
| ---------------- | ------------------------------ |
| Service          | `<BASE_NAME>`                  |
| Intercept Config | `<BASE_NAME>-intercept-config` |
| Host Config      | `<BASE_NAME>-host-config`      |
| Dial Policy      | `<BASE_NAME>-dial-policy`      |
| Bind Policy      | `<BASE_NAME>-bind-policy`      |

### 🔎 Traffic Flow

**Client side (Intercept):**

```
SERVICE_IP:SERVICE_PORT
```

**Backend forwarding (Host):**

```
SERVICE_IP:SERVICE_PORT
```

------------------------------------------------------------------------

## ⚙️ Pipeline Parameters

| Parameter            | Description                    | Example                          |
| -------------------- | ------------------------------ | -------------------------------- |
| `BASE_NAME`          | Base name for all Ziti objects | `orionld-context-broker-ngsi-ld` |
| `SERVICE_IP`         | Backend IP to expose via Ziti  | `49.13.48.36`                    |
| `SERVICE_PORT`       | Orion-LD port to expose        | `1026`                           |
| `HOST_IDENTITY_NAME` | Ziti identity **name** that    | `data-management-host`           |
|                      | binds/hosts the service        |                                  |
| `PROTOCOLS`          | Intercept protocols            | `tcp` or `tcp,udp`               |

------------------------------------------------------------------------

## 🔐 Fixed Dial Identities

The pipeline always assigns the same **dial identities**:

```
FIXED_DIAL_IDENTITIES='@PsugFlXf6,@IFi2o73f63,@SKR9uIjfx3'
```

🚨 Only these identities will be able to **see and access** the service.

------------------------------------------------------------------------

## 🛠️ How It Works

### 1️⃣ Validate Parameters

-   Ensures `SERVICE_PORT` is numeric and between **1--65535**

-   Validates `BASE_NAME` format:

```
^[a-zA-Z0-9][a-zA-Z0-9._-]*$
```

-   Confirms:

    -   `ziti` CLI is available
    -   `ZITI_ID_FILE` is readable

------------------------------------------------------------------------

### 2️⃣ Ziti Login

Authenticates to the Ziti controller using:

```bash
ziti edge login "${ZITI_CTRL}" --file "${ZITI_ID_FILE}" -y
```

------------------------------------------------------------------------

### 3️⃣ Create Configs, Service & Policies

#### 📌 Intercept Config (`intercept.v1`)

-   `addresses`: `[SERVICE_IP]`
-   `portRanges`: `[SERVICE_PORT]`
-   `protocols`: from `PROTOCOLS`
    -   e.g. `["tcp"]` or `["tcp","udp"]`

#### 📌 Host Config (`host.v1`)

-   `address`: `SERVICE_IP`
-   `port`: `SERVICE_PORT`

#### 📡 Service

-   Created with **both configs attached**

#### 🔐 Policies

-   **Dial Policy** → `FIXED_DIAL_IDENTITIES`
-   **Bind Policy** → `@HOST_IDENTITY_NAME`

------------------------------------------------------------------------

## 📋 Prerequisites

Before running this pipeline, ensure:

1. **Ziti CLI is installed** on the Jenkins node running the pipeline
2. **Ziti identity file** exists at `ZITI_ID_FILE` path (default: `/home/coppilot-admin/ziti/doc-vm.json`)
3. **Network connectivity** to the Ziti controller endpoint
4. **Orion-LD Context Broker** is running and accessible at `SERVICE_IP:SERVICE_PORT`

------------------------------------------------------------------------

## 🚀 Running the Pipeline

1. Navigate to the Jenkins job for this pipeline
2. Click **"Build with Parameters"**
3. Fill in the parameters:
   - `BASE_NAME`: Name for the Ziti service (e.g., `orionld-central-domain-1`)
   - `SERVICE_IP`: IP address of your Orion-LD host (e.g., `49.13.48.36`)
   - `SERVICE_PORT`: Port Orion-LD is running on (default: `1026`)
   - `HOST_IDENTITY_NAME`: Ziti identity that will host/bind the service (e.g., `data-management-host`)
   - `PROTOCOLS`: Choose `tcp` or `tcp,udp`

4. Click **"Build"**

------------------------------------------------------------------------

## ✅ Expected Output

Once completed successfully, you should see:

```
✅ Done
Client intercept: 49.13.48.36:1026
Backend target  : 49.13.48.36:1026
Host identity   : data-management-host
```

------------------------------------------------------------------------

## 🔒 Security Notes

✨ Once completed, the **Orion-LD Context Broker** endpoint is securely exposed **only**
to authorized Ziti identities --- no public networking required.

**Key security benefits:**

-   🔐 Zero-trust network access via OpenZiti
-   🚫 No direct internet exposure of the service
-   👥 Access controlled by Ziti identity policies
-   🔄 Traffic encrypted end-to-end
-   📊 Full audit trail through Ziti controller

------------------------------------------------------------------------

## 🔧 Troubleshooting

### "ERROR: ziti CLI not found"

-   Ensure `ziti` is installed in `/opt/openziti/bin` or in `PATH`
-   Update `PATH` environment variable in the pipeline if using a different location

### "ERROR: Ziti identity file not readable"

-   Check that `ZITI_ID_FILE` path exists and is readable by the Jenkins user
-   Default path: `/home/coppilot-admin/ziti/doc-vm.json`

### Service creation fails

-   Verify Ziti controller connectivity
-   Ensure the identity file is valid and authenticated
-   Check that `BASE_NAME` follows the naming convention: `^[a-zA-Z0-9][a-zA-Z0-9._-]*$`

------------------------------------------------------------------------

## 📚 Related Documentation

-   [Orion-LD Context Broker Deployment](README-orionld_context_broker_deploy.md)
-   [OpenZiti Service Creation](../../sif-layer-pipelines/OpenSlice-service-creation.md)
-   [Ziti Enrollment & Tunneling](../../sif-layer-pipelines/identity-script/README.md)

