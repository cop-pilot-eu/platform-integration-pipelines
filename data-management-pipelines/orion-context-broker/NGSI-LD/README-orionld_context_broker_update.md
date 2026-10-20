# 🔄 Orion-LD (NGSI-LD) Context Broker Update --- Jenkins Pipeline

> Pipeline that **updates** a running FIWARE **Orion-LD** container to
> the latest image, without touching **MongoDB** or its data.

------------------------------------------------------------------------

## 🧭 Overview

`Jenkinsfile.orionld-context-broker-update` works on a stack that was
already deployed by `Jenkinsfile.orionld-context-broker-deploy`
(compose project `cop-pilot-orionld`). It:

-   🔍 Finds the running `orion-ld` container and the compose file it
    was started from (via the Docker Compose container labels, so it
    works even though the deploy job has a different workspace)
-   ⬇️ Pulls the image the container is configured with (for example
    `fiware/orion-ld:latest`)
-   ⏭️ Does nothing if the pulled image is the one already running
    (unless `FORCE_RECREATE` is set)
-   ♻️ Recreates **only** the `orion-ld` service (`--no-deps`). MongoDB
    and the `mongo-data` volume are not restarted or modified
-   🩺 Runs the `/version` smoke test
-   ⏪ Rolls back to the previous image if the smoke test fails

------------------------------------------------------------------------

## ✅ Prerequisites

-   The stack was deployed with the deploy pipeline on the same node
-   The deploy job's compose file
    (`<deploy-workspace>/orionld-stack/docker-compose.orionld.yml`)
    still exists. If the deploy workspace was wiped, re-run the deploy
    pipeline instead
-   Docker and `docker compose` / `docker-compose` on the node

------------------------------------------------------------------------

## 🔧 Pipeline Parameters

  Name                    Default          Description
  ----------------------- ---------------- --------------------------------------------------------------
  `NODE_LABEL`            `orionld-node`   Jenkins agent where the stack is running
  `ORION_LD_PORT`         `1026`           Host port of Orion-LD, used for the smoke test
  `FORCE_RECREATE`        `false`          Recreate the container even if the image is unchanged
  `ROLLBACK_ON_FAILURE`   `true`           Roll back to the previous image if the smoke test fails
  `PRUNE_OLD_IMAGE`       `false`          Delete the previous image after a successful update

> The pipeline updates the **tag the stack is already using**. To move
> to a different tag (for example a pinned version), re-run the deploy
> pipeline with a new `ORION_LD_DOCKER_IMAGE`.

------------------------------------------------------------------------

## 🧱 Stages

1.  **Docker sanity check**: checks Docker and the Compose CLI.
2.  **Inspect running Orion-LD**: finds the container by the labels
    `com.docker.compose.project=cop-pilot-orionld` and
    `com.docker.compose.service=orion-ld`. Records the image reference,
    current image ID and compose file location, and prints the current
    `/version`.
3.  **Pull latest image**: `docker pull <image>` and compares the image
    IDs. If they match and `FORCE_RECREATE` is off, the remaining stages
    are skipped.
4.  **Recreate Orion-LD**:
    `docker compose -p cop-pilot-orionld -f <file> up -d --no-deps --force-recreate orion-ld`
5.  **Smoke test**: polls `http://localhost:<ORION_LD_PORT>/version`
    (30 × 2s). On failure with `ROLLBACK_ON_FAILURE=true`, it prints the
    container logs, re-tags the previous image ID to the original tag,
    recreates the container, smoke-tests again, and fails the build.
6.  **Prune previous image** (optional): removes the old image.

------------------------------------------------------------------------

## ▶️ How to Run

1.  Create a Jenkins pipeline job pointing to
    `Jenkinsfile.orionld-context-broker-update`.
2.  Set `NODE_LABEL` to the node where Orion-LD runs.
3.  Run it manually, or add a cron trigger to the job to keep Orion-LD
    up to date automatically.

------------------------------------------------------------------------

## 🛠️ Troubleshooting

### "No 'orion-ld' container found"

The stack is not running on that node, or it was deployed with a
different project name. Check:

    docker ps -a --filter label=com.docker.compose.project=cop-pilot-orionld

### "Compose file ... no longer exists"

The deploy job's workspace was cleaned. Re-run
`Jenkinsfile.orionld-context-broker-deploy`. It pulls the latest image
anyway.

### Manual rollback

If `PRUNE_OLD_IMAGE` was left off, the previous image is still present
as a `<none>` image:

    docker images fiware/orion-ld --digests
    docker tag <old-image-id> fiware/orion-ld:latest
    docker compose -p cop-pilot-orionld -f <compose-file> up -d --no-deps --force-recreate orion-ld
