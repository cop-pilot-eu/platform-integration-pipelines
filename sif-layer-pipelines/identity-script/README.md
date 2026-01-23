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
./ziti_install_enroll_and_tunnel.sh OpenSlice-central-domain.jwt 
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
