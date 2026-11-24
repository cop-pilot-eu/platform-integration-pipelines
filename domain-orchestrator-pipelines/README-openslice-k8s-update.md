# 🔄 OpenSlice (Domain Orchestrator) Kubernetes Update --- Jenkins Pipeline

> CI/CD pipeline to **update** a running ETSI **OpenSlice** instance on
> Kubernetes to a newer release (e.g. `2025Q4` → `2026Q2`), keeping its
> configuration and data.

---

## 🧭 Overview

`Jenkinsfile.openslice-k8s-update` upgrades an existing OpenSlice Helm release
that was installed with [`Jenkinsfile.openslice-k8s-deploy`](README-openslice-k8s-deploy.md):

- 📌 Chart **and** OpenSlice images move to `TARGET_VERSION`
- ♻️ The release's existing values (root URL, passwords, CRIDGE kubeconfig,
  storage class, ...) are kept (`--reset-then-reuse-values`), and the new chart's defaults are applied
- 💾 MySQL dump before the upgrade, archived as a build artifact
- 🧪 Server-side dry-run, rollout check, image tag check, and smoke test
- ⏪ Automatic `helm rollback` to the previous revision on failure
- 🟰 No-op when the release already runs `TARGET_VERSION` (unless `FORCE_UPDATE`)

MySQL data (PVC) is not touched by the upgrade.

---

## ✅ Prerequisites

- A Helm release of OpenSlice in `NAMESPACE`, in `deployed` state
- Jenkins **Secret file** credential with the target cluster's kubeconfig (default ID: `staging-kubeconfig`)
- Agent with `kubectl`, **`helm` ≥ 3.14**, `git`, `curl`, `gzip`

---

## ⚙️ Pipeline Parameters

| Parameter                   | Default                | Description                                                                         |
| --------------------------- | ---------------------- | ----------------------------------------------------------------------------------- |
| `NODE_LABEL`                | `cop-pilot-staging-cluster`       | Jenkins agent label                                                                 |
| `KUBECONFIG_CREDENTIALS_ID` | `staging-kubeconfig` | Jenkins **Secret file** credential with the kubeconfig                              |
| `TARGET_VERSION`            | `2026Q2`               | Release to update to: tag/branch of `org.etsi.osl.main`                             |
| `IMAGE_TAG`                 | *(derived)*            | Image tag override. Empty: `main` → `latest`, `develop` → `develop`, otherwise `TARGET_VERSION` |
| `NAMESPACE`                 | `openslice`            | Namespace of the running instance                                                   |
| `HELM_RELEASE`              | `openslice`            | Helm release of the running instance                                                |
| `ROOT_URL`                  | *(keep current)*       | Override the root URL; empty keeps the release's current one                        |
| `HELM_TIMEOUT`              | `20m`                  | Timeout of `helm upgrade --wait` and `helm rollback --wait`                         |
| `BACKUP_DB`                 | `true`                 | Dump all MySQL databases before the upgrade and archive the dump                    |
| `AUTO_ROLLBACK`             | `true`                 | Roll back to the previous Helm revision if the upgrade/verification fails           |
| `DRY_RUN`                   | `false`                | Only validate the upgrade with `helm upgrade --dry-run=server`                      |
| `FORCE_UPDATE`              | `false`                | Upgrade even if the release already runs `TARGET_VERSION`                           |

---

## 🧱 Pipeline Stages

### 1️⃣ Validate environment

Checks tools and Helm version, cluster access, that the release exists and is
`deployed`, records the current Helm revision (for rollback), and compares the
running `appVersion` with `TARGET_VERSION`.

### 2️⃣ Clone OpenSlice repository

Clones `org.etsi.osl.main` at `TARGET_VERSION`.

### 3️⃣ Configure Web UIs

Generates the Web UI config files from the **target** release's defaults
(they carry version-specific settings such as `PORTALVERSION`).

### 4️⃣ Prepare Helm values

Writes an override file with the target image tag for all OpenSlice images
(and `rooturl` when `ROOT_URL` is set, or when the old release had it only in
the chart's `values.yaml`), then validates the upgrade with
`helm upgrade --dry-run=server`. With `DRY_RUN` the pipeline stops here.

### 5️⃣ Backup MySQL

`mysqldump --all-databases --single-transaction` from the MySQL pod, gzipped,
checked for completeness, and archived as a build artifact.

### 6️⃣ Upgrade OpenSlice

`helm upgrade --reset-then-reuse-values -f <override> --wait`.

### 7️⃣ Verify rollout

Waits for every Deployment/StatefulSet of the release and checks that every
`labs.etsi.org:5050/osl/*` container runs the target tag.

### 8️⃣ Smoke test

Same checks as the deploy pipeline (Web UI, Keycloak realm, TMF API) against
the release's `rooturl`, plus a non-blocking check of the Web UI's `PORTALVERSION`.

---

## ⏪ Rollback & Restore

If any stage fails **after** the upgrade started and `AUTO_ROLLBACK` is on, the
pipeline runs `helm rollback <release> <previous revision> --wait`. This restores
the previous chart, values, and image tags.

`helm rollback` does not undo database schema changes that the new version may
have applied on startup. If the old version misbehaves after a rollback,
restore the archived dump:

```bash
gunzip -c openslice-mysql-<timestamp>.sql.gz | \
  kubectl exec -i -n openslice <mysql-pod> -- sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD"'
```

The dump contains all OpenSlice data. Restrict access to the job's artifacts.

---

## 🧪 Example: 2025Q4 → 2026Q2

1. Deploy: `Jenkinsfile.openslice-k8s-deploy` with `OSL_VERSION=2025Q4`
2. Validate: `Jenkinsfile.openslice-k8s-update` with `TARGET_VERSION=2026Q2`, `DRY_RUN=true`
3. Update: same job with `DRY_RUN=false`
4. Check the build log for `OK   TMF Web UI reports PORTALVERSION 2026Q2`

Chart changes 2025Q4 (chart 3.0.0) → 2026Q2 (chart 4.1.0): new
`osom.secretsController.enable` value (default `false`), updated `PORTALVERSION`
in the TMF Web UI config.

---

## 📬 Documentation

- [OpenSlice Kubernetes Deployment Guide](https://osl.etsi.org/documentation/develop/getting_started/deployment/kubernetes/)
- [ETSI OSL GitLab](https://labs.etsi.org/rep/osl)
