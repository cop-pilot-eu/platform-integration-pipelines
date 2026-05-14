# 🚀 CloudZiti VM Identity Enrollment Guide (Script-Based)

This guide explains how to enroll a Linux VM as a **CloudZiti identity** using an automated script.
---

## 1️⃣ Create an Identity in CloudZiti

1. Log in to the **CloudZiti Console**
2. Navigate to **Identities**
3. Create a new identity
4. Download the **JWT enrollment token** (`*.jwt`)

Example:

```text
identity.jwt
```

---

## 2️⃣ Prepare the Target VM

On the VM you want to enroll:

1. Copy the downloaded **JWT file** to the VM
2. Copy the script **`ziti_install_enroll_and_tunnel.sh`** to the **same directory**

Your directory should look like this:

```text
identity.jwt
ziti_install_enroll_and_tunnel.sh
```

---

## 3️⃣ Execute the Enrollment Script

Make the script executable:

```bash
chmod +x ziti_install_enroll_and_tunnel.sh
```

Run the script, passing the JWT filename as input:

```bash
./ziti_install_enroll_and_tunnel.sh OpenSlice-central-domain.jwt --nohup
```

---

## 4️⃣ What the Script Does

The script automatically:

- Installs required system dependencies
- Downloads and installs the **OpenZiti CLI**
- Downloads and installs **ziti-edge-tunnel**
- Enrolls the identity (`.jwt → .json`)
- Starts the Ziti tunnel in the background (`nohup` mode)

Output files created:

```text
identity.json
ziti-identity.log
```

---

## 5️⃣ Verify the Identity Is Online

### In CloudZiti Console

- Go back to **Identities**
- The identity should now appear **online (green)**

---

## 6️⃣ Restarting the Tunnel

If the tunnel stops for any reason, you can restart it manually:

```bash
sudo nohup /usr/local/bin/ziti-edge-tunnel run -i <identity.json> > ziti-<identity>.log 2>&1 &
```

Replace `<identity.json>` with the name of your enrolled identity file (e.g., `OpenSlice-central-domain.json`).

---

## 7️⃣ Re-enabling the Tunnel (if not started with --nohup)

If you ran the script without the `--nohup` flag, the tunnel will not run in the background. To re-enable it:

1. Locate the identity JSON file created by the script (e.g., `OpenSlice-central-domain.json`).
2. Use the following command to start the tunnel in the background:

```bash
sudo nohup /usr/local/bin/ziti-edge-tunnel run -i <identity.json> > ziti-<identity>.log 2>&1 &
```

Replace `<identity.json>` with the name of your enrolled identity file (e.g., `OpenSlice-central-domain.json`).
