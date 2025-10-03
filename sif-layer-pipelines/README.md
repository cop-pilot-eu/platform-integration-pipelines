# 🚀 Ziti Edge Router Deploy — Jenkins Pipeline

> CI/CD pipeline to **deploy**, **test**, and **validate** an OpenZiti Edge Router on a Linux host.

---
 deploying, testing, and validating
## 🧭 Overview

This Jenkins pipeline (`Jenkinsfile.ziti-router-deploy`) automates the lifecycle of an **Edge Router**:
- 📦 Installs the `openziti-router` package (idempotent; skips if present)
- ⚙️ Writes the **bootstrap.env** and places the **enrollment JWT**
- 🧰 Runs the OpenZiti **bootstrap** script to fetch config from the controller
- ▶️ Enables & starts `ziti-router.service`
- 🩺 Performs a lightweight health check and summarizes recent logs

> Designed to be **safe to re-run**: if the router is already installed & enrolled, the pipeline becomes a no-op for those steps and only (re)starts and checks the service.

---

## 📁 Repository Layout

```
sif-layer-pipelines/
├─ Jenkinsfile.ziti-router-deploy     # This pipeline
└─ README.md                          # You are here
```

---

## ✅ Prerequisites

- A reachable **OpenZiti Controller** (DNS/IP + port).
- A valid **router enrollment token (JWT)** generated from the controller.
- Jenkins node with `sudo` privileges and access to the JWT (stored as a secret credential).

---

## 🔧 Parameters & Inputs

These environment variables/credentials are consumed by the pipeline:

| Name | Type | Description |
|---|---|---|
| `JWT_FILE` | Jenkins Secret File | Enrollment token (JWT). Placed at `/opt/openziti/etc/router/enroll.jwt` |
| `ZITI_CTRL_ADVERTISED_ADDRESS` | String | Controller advertised DNS/IP (e.g. `ctrl.example.com`) |
| `ZITI_CTRL_ADVERTISED_PORT` | Number | Controller port (usually `443` or `1280`) |
| `ZITI_ROUTER_ADVERTISED_ADDRESS` | (Optional) String | Public address for the router edge listener |
| `ZITI_ROUTER_PORT` | (Optional) Number | Edge listener port (default `3022`) |

> The pipeline writes these into `/opt/openziti/etc/router/bootstrap.env` and then runs `/opt/openziti/etc/router/bootstrap.bash` non‑interactively.

---

## 🧱 Stages (What the pipeline does)

1. **Install_openziti_router**  
   Installs `openziti-router` via distro packages (idempotent).

2. **Configure_Bootstrap**  
   - Copies the JWT into `/opt/openziti/etc/router/enroll.jwt` (0600)  
   - Writes `/opt/openziti/etc/router/bootstrap.env`

3. **Bootstrap_Router**  
   Runs `/opt/openziti/etc/router/bootstrap.bash` once to generate config at `/var/lib/private/ziti-router/` (skips on subsequent runs).

4. **Start_Service**  
   `systemctl enable --now ziti-router.service` and prints a short status.

5. **Health_Check**  
   - Tails recent `journalctl -u ziti-router.service` entries  
   - Greps for critical errors while **ignoring known benign identity reload permission warnings**  
   - Fails only on real issues (panic/fatal/TLS failure/unreachable/timeout/etc.)

---

## ▶️ How to Run

1. Configure the Jenkins job to use this `Jenkinsfile.ziti-router-deploy` from `sif-layer-pipelines/`.
2. Add the **JWT** as a secret file credential and reference it as `JWT_FILE`.
3. Provide controller/router variables via Jenkins parameters or environment.
4. Run the build. 

---

## 📤 Outputs & Artifacts

- Router config & identity under: `/var/lib/private/ziti-router/`  
- Service unit: `ziti-router.service` (systemd)  
- Bootstrap answers: `/opt/openziti/etc/router/bootstrap.env`

---

## 🔗 Documentation

- **Official OpenZiti — Router Deployment (Linux, systemd)**  
  <https://netfoundry.io/docs/openziti/guides/deployments/linux/router/deploy/>

---

## 🛠️ Troubleshooting Tips

- Watch the live logs:  
  ```bash
  sudo journalctl -u ziti-router.service -f
  ```

- Check listener is up (default `3022`):  
  ```bash
  sudo ss -tlnp | grep ziti
  ```

- Restart after config changes:  
  ```bash
  sudo systemctl restart ziti-router.service
  ```

If the pipeline fails in **Health_Check**, re-run once to verify stability. Persistent failures usually indicate TLS/CA mismatch, controller reachability issues, or incorrect `bootstrap.env` values.

---

## 🤝 Contributing

- Keep the pipeline **idempotent** and **secure** (use Jenkins credentials & least‑privilege).
- Update this README when adding stages, parameters, or behavior changes.
- Prefer official docs for installation details; this pipeline is a thin automation wrapper.

