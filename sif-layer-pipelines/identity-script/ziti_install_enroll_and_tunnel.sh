#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# OpenZiti bootstrap + tunneler
#
#  - Installs deps (curl, jq, unzip, tar)
#  - Downloads latest ziti CLI (robust asset selection)
#  - Downloads latest ziti-edge-tunnel (robust asset selection)
#  - Enrolls identity from JWT in same dir
#  - Starts ziti-edge-tunnel via systemd (default) or nohup (--nohup)
#
# Usage:
#   ./ziti_install_enroll_and_tunnel.sh <jwt-file-name> [--nohup]
#
# Example:
#   ./ziti_install_enroll_and_tunnel.sh OpenSlice-central-domain.jwt
#   ./ziti_install_enroll_and_tunnel.sh OpenSlice-central-domain.jwt --nohup
#
# Output:
#   ./OpenSlice-central-domain.json
# ------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

JWT_NAME="${1:-}"
MODE="${2:-}" # optional: --nohup

if [[ -z "${JWT_NAME}" ]]; then
  echo "Usage: $0 <jwt-file-name> [--nohup]"
  echo "Example: $0 OpenSlice-central-domain.jwt"
  exit 1
fi

JWT_PATH="${SCRIPT_DIR}/${JWT_NAME}"
if [[ ! -f "${JWT_PATH}" ]]; then
  echo "ERROR: JWT file not found: ${JWT_PATH}"
  exit 1
fi

BASENAME="${JWT_NAME%.jwt}"
OUT_JSON="${SCRIPT_DIR}/${BASENAME}.json"
LOG_FILE="${SCRIPT_DIR}/ziti-${BASENAME}.log"

echo "[*] Using JWT   : ${JWT_PATH}"
echo "[*] Output JSON : ${OUT_JSON}"

# ------------------------------------------------------------
# OS / ARCH detection
# ------------------------------------------------------------
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

if [[ "${OS}" != "linux" ]]; then
  echo "ERROR: Only Linux is supported"
  exit 1
fi

case "${ARCH}" in
  x86_64|amd64) ZITI_ARCH="amd64"; SDK_ARCH_RE="(amd64|x86_64)" ;;
  aarch64|arm64) ZITI_ARCH="arm64"; SDK_ARCH_RE="(arm64|aarch64)" ;;
  *)
    echo "ERROR: Unsupported architecture: ${ARCH}"
    exit 1
    ;;
esac

# ------------------------------------------------------------
# Dependency installation
# ------------------------------------------------------------
install_deps_apt() {
  sudo apt-get update -y
  sudo apt-get install -y curl jq unzip tar
}

install_deps_yum() {
  sudo yum install -y curl jq unzip tar
}

install_deps_dnf() {
  sudo dnf install -y curl jq unzip tar
}

need_any=0
command -v curl  >/dev/null || need_any=1
command -v jq    >/dev/null || need_any=1
command -v unzip >/dev/null || need_any=1
command -v tar   >/dev/null || need_any=1

if [[ "${need_any}" == "1" ]]; then
  echo "[*] Installing dependencies..."
  if command -v apt-get >/dev/null; then
    install_deps_apt
  elif command -v dnf >/dev/null; then
    install_deps_dnf
  elif command -v yum >/dev/null; then
    install_deps_yum
  else
    echo "ERROR: Unsupported package manager. Install: curl jq unzip tar"
    exit 1
  fi
else
  echo "[*] Dependencies already installed"
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

# ------------------------------------------------------------
# Helper: download latest release asset that matches patterns
# ------------------------------------------------------------
download_latest_asset() {
  local repo="$1"        # e.g. openziti/ziti
  local outdir="$2"      # where to download/extract
  local name_regex="$3"  # jq regex on asset.name
  local exedir="$4"      # extraction dir

  mkdir -p "${outdir}"
  mkdir -p "${exedir}"

  local release_json="${TMP_DIR}/$(echo "${repo}" | tr '/' '_')_release.json"
  curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" -o "${release_json}"

  local tag
  tag="$(jq -r '.tag_name' "${release_json}")"
  echo "[*] ${repo} latest tag: ${tag}"

  local asset_url asset_name
  asset_url="$(jq -r --arg re "${name_regex}" '
    .assets[] | select(.name | test($re)) | .browser_download_url
  ' "${release_json}" | head -n 1)"

  asset_name="$(jq -r --arg re "${name_regex}" '
    .assets[] | select(.name | test($re)) | .name
  ' "${release_json}" | head -n 1)"

  if [[ -z "${asset_url}" || "${asset_url}" == "null" ]]; then
    echo "ERROR: Could not find a matching asset for ${repo} with regex: ${name_regex}"
    exit 1
  fi

  echo "[*] Downloading asset: ${asset_name}"
  curl -fL "${asset_url}" -o "${outdir}/${asset_name}"

  echo "[*] Extracting: ${asset_name}"
  if [[ "${asset_name}" == *.zip ]]; then
    unzip -q "${outdir}/${asset_name}" -d "${exedir}"
  elif [[ "${asset_name}" == *.tar.gz ]]; then
    tar -xzf "${outdir}/${asset_name}" -C "${exedir}"
  else
    # If it’s a raw binary, just keep it
    :
  fi
}

# ------------------------------------------------------------
# Install ziti CLI
# ------------------------------------------------------------
echo "[*] Installing ziti CLI..."
ZITI_OUT="${TMP_DIR}/ziti_dl"
ZITI_EX="${TMP_DIR}/ziti_ex"
rm -rf "${ZITI_OUT}" "${ZITI_EX}"
mkdir -p "${ZITI_OUT}" "${ZITI_EX}"

# match linux + arch + zip or tar.gz
ZITI_NAME_RE="(?i)linux.*${ZITI_ARCH}.*(\\.zip|\\.tar\\.gz)$"
download_latest_asset "openziti/ziti" "${ZITI_OUT}" "${ZITI_NAME_RE}" "${ZITI_EX}"

ZITI_BIN="$(find "${ZITI_EX}" -type f -name ziti -perm -u+x | head -n 1 || true)"
if [[ -z "${ZITI_BIN}" ]]; then
  echo "ERROR: ziti binary not found after extraction"
  exit 1
fi

sudo install -m 0755 "${ZITI_BIN}" /usr/local/bin/ziti
echo "[*] ziti installed: $(ziti version 2>/dev/null || true)"

# ------------------------------------------------------------
# Install ziti-edge-tunnel
# Repo is openziti/ziti-tunnel-sdk-c (Linux tunneler binary is released there)
# Asset naming varies, so we match:
#   - contains "ziti-edge-tunnel"
#   - contains "linux"
#   - contains arch (amd64/x86_64 OR arm64/aarch64)
#   - zip or tar.gz
# ------------------------------------------------------------
echo "[*] Installing ziti-edge-tunnel..."
TUN_OUT="${TMP_DIR}/tunnel_dl"
TUN_EX="${TMP_DIR}/tunnel_ex"
rm -rf "${TUN_OUT}" "${TUN_EX}"
mkdir -p "${TUN_OUT}" "${TUN_EX}"

TUN_NAME_RE="(?i)ziti-edge-tunnel.*linux.*${SDK_ARCH_RE}.*(\\.zip|\\.tar\\.gz)$"
download_latest_asset "openziti/ziti-tunnel-sdk-c" "${TUN_OUT}" "${TUN_NAME_RE}" "${TUN_EX}"

TUN_BIN="$(find "${TUN_EX}" -type f -name ziti-edge-tunnel -perm -u+x | head -n 1 || true)"
if [[ -z "${TUN_BIN}" ]]; then
  echo "ERROR: ziti-edge-tunnel binary not found after extraction"
  exit 1
fi

sudo install -m 0755 "${TUN_BIN}" /usr/local/bin/ziti-edge-tunnel
echo "[*] ziti-edge-tunnel installed: $(ziti-edge-tunnel version 2>/dev/null || true)"

# ------------------------------------------------------------
# Enroll identity (JWT -> JSON)
# ------------------------------------------------------------
if [[ -f "${OUT_JSON}" ]]; then
  echo "[*] Identity JSON already exists: ${OUT_JSON}"
  echo "[*] Skipping enroll."
else
  echo "[*] Enrolling identity..."
  ziti edge enroll "${JWT_PATH}" -o "${OUT_JSON}"
fi

# ------------------------------------------------------------
# Start tunnel (systemd default; nohup optional)
# ------------------------------------------------------------
if [[ "${MODE}" == "--nohup" ]]; then
  echo "[*] Starting ziti-edge-tunnel with nohup..."
  sudo nohup /usr/local/bin/ziti-edge-tunnel run -i "${OUT_JSON}" > "${LOG_FILE}" 2>&1 &
  echo "[✓] Started. Log: ${LOG_FILE}"
  echo "    Check: ps aux | grep ziti-edge-tunnel | grep -v grep"
else
  echo "[*] Starting ziti-edge-tunnel as a systemd service..."

  UNIT_NAME="ziti-edge-tunnel-${BASENAME}.service"
  UNIT_PATH="/etc/systemd/system/${UNIT_NAME}"

  sudo bash -c "cat > '${UNIT_PATH}'" <<EOF
[Unit]
Description=OpenZiti Edge Tunnel (${BASENAME})
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/ziti-edge-tunnel run -i ${OUT_JSON}
Restart=always
RestartSec=5
# (Optional) write logs to journal; use: journalctl -u ${UNIT_NAME} -f

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable --now "${UNIT_NAME}"

  echo "[✓] Service started: ${UNIT_NAME}"
  echo "    Status : sudo systemctl status ${UNIT_NAME} --no-pager"
  echo "    Logs   : sudo journalctl -u ${UNIT_NAME} -f"
fi

echo
echo "✅ Done"
echo "   JWT  : ${JWT_PATH}"
echo "   JSON : ${OUT_JSON}"
echo
echo "Note: CloudZiti identity should turn green once the tunnel connects successfully."
