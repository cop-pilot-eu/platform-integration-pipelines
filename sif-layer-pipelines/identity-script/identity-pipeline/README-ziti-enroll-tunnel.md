# 🚀 SIF (OpenZiti) VM Enrollment & Tunnel --- Jenkins Pipeline

> CI/CD pipeline to **install**, **enroll**, and **connect** a Linux VM
> to the **SIF (OpenZiti)** zero-trust network.

---

## 🧭 Overview

This Jenkins pipeline (`Jenkinsfile.ziti-enroll-tunnel`) automates the
full process of connecting a VM to the COP-PILOT Secure Integration
Fabric (SIF) powered by OpenZiti:

- 📦 Installs system dependencies (`curl`, `jq`, `unzip`, `tar`)
- 🔧 Downloads and installs the latest **Ziti CLI**
- 🔧 Downloads and installs the latest **ziti-edge-tunnel**
- 🔐 Enrolls the VM identity from a **JWT token** (`.jwt → .json`)
- 🚇 Starts the Ziti tunnel (systemd service or nohup)
- ✅ Verifies the tunnel process is running

Once complete, the VM identity appears **online (green)** in the
CloudZiti Console and can securely communicate with other SIF-connected
services.

---

## ✅ Prerequisites

- A **JWT enrollment token** (`.jwt`) downloaded from the CloudZiti Console
- The JWT file must be present in the Jenkins workspace
- Target VM running **Linux** (amd64 or arm64)
- `sudo` access on the target VM

---

## ⚙️ Pipeline Parameters

| Parameter      | Default      | Description                                           |
| -------------- | ------------ | ----------------------------------------------------- |
| `NODE_LABEL`   | `target-vm`  | Jenkins node label of the VM to enroll                |
| `JWT_FILENAME` | *(required)* | Name of the JWT enrollment token file                 |
| `TUNNEL_MODE`  | `systemd`    | How to run the tunnel: `systemd` (default) or `nohup` |

---

## 🧱 Pipeline Stages

### 1️⃣ Validate parameters

Checks that `JWT_FILENAME` is provided and the file exists in the workspace.

---

### 2️⃣ Install dependencies

Installs `curl`, `jq`, `unzip`, `tar` via the available package manager
(apt/dnf/yum).

---

### 3️⃣ Install Ziti CLI

Downloads the latest `ziti` CLI binary from
[openziti/ziti](https://github.com/openziti/ziti) GitHub releases.

---

### 4️⃣ Install ziti-edge-tunnel

Downloads the latest `ziti-edge-tunnel` binary from
[openziti/ziti-tunnel-sdk-c](https://github.com/openziti/ziti-tunnel-sdk-c)
GitHub releases.

---

### 5️⃣ Enroll identity

Converts the JWT enrollment token into a JSON identity file:

```bash
ziti edge enroll <identity>.jwt -o <identity>.json
```

Skips enrollment if the JSON already exists (idempotent).

---

### 6️⃣ Start ziti-edge-tunnel

Starts the tunnel in one of two modes:

- **systemd** (default): Creates and enables a persistent systemd service
- **nohup**: Starts as a background process with log output

---

### 7️⃣ Verify tunnel connectivity

Confirms the `ziti-edge-tunnel` process is running. Once connected, the
identity appears **online** in the CloudZiti Console.

---

## 📤 Outputs

| File                  | Description                   |
| --------------------- | ----------------------------- |
| `<identity>.json`     | Enrolled identity credentials |
| `ziti-<identity>.log` | Tunnel log (nohup mode only)  |

---

## 📬 Documentation

- [OpenZiti Documentation](https://openziti.io/docs/learn/introduction/)
- [OpenZiti GitHub](https://github.com/openziti)
