# 🚀 CloudZiti VM Identity Enrollment Guide (Script-Based)

This guide explains how to enroll a Linux VM as a **CloudZiti identity** using an automated script and run the Ziti tunneler as a **systemd service** in the background.

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

> Do not use `--nohup`.
> When the script is executed without `--nohup`, it starts the Ziti tunneler as a **systemd service**.

---

## 4️⃣ What the Script Does

The script automatically:

- Installs the required system dependencies
- Downloads and installs the **OpenZiti CLI**
- Downloads and installs **ziti-edge-tunnel**
- Enrolls the identity (`.jwt → .json`)
- Creates a **systemd service** for the Ziti tunneler
- Starts the Ziti tunnel in the background as a service
- Enables the service to start automatically after reboot

Output file created:

```text
identity.json
```

Example:

```text
OpenSlice-central-domain.json
```

The systemd service name is created based on the JWT filename.

Example:

```text
ziti-edge-tunnel-OpenSlice-central-domain.service
```

---

## 5️⃣ Verify the Identity Is Online

### In CloudZiti Console

- Go back to **Identities**
- The identity should now appear **online / green**

### On the VM

Check the service status:

```bash
sudo systemctl status ziti-edge-tunnel-OpenSlice-central-domain.service --no-pager
```

View the latest logs:

```bash
sudo journalctl -u ziti-edge-tunnel-OpenSlice-central-domain.service -n 100 --no-pager
```

Follow logs live:

```bash
sudo journalctl -u ziti-edge-tunnel-OpenSlice-central-domain.service -f
```

---

## 6️⃣ Restarting the Tunnel Service

If the tunnel stops for any reason, restart the systemd service:

```bash
sudo systemctl restart ziti-edge-tunnel-OpenSlice-central-domain.service
```

Check the service again:

```bash
sudo systemctl status ziti-edge-tunnel-OpenSlice-central-domain.service --no-pager
```

---

## 7️⃣ Stopping the Tunnel Service

To stop the tunnel:

```bash
sudo systemctl stop ziti-edge-tunnel-OpenSlice-central-domain.service
```

To verify that it stopped:

```bash
sudo systemctl status ziti-edge-tunnel-OpenSlice-central-domain.service --no-pager
```

---

## 8️⃣ Starting the Tunnel Service Manually

To start the tunnel again:

```bash
sudo systemctl start ziti-edge-tunnel-OpenSlice-central-domain.service
```

---

## 9️⃣ Enable or Disable Startup on Boot

The script enables the service automatically, but you can enable it manually with:

```bash
sudo systemctl enable ziti-edge-tunnel-OpenSlice-central-domain.service
```

To disable automatic startup:

```bash
sudo systemctl disable ziti-edge-tunnel-OpenSlice-central-domain.service
```

---

## 🔟 Useful Commands

Check if the tunneler process is running:

```bash
pgrep -af ziti-edge-tunnel
```

View service logs:

```bash
sudo journalctl -u ziti-edge-tunnel-OpenSlice-central-domain.service -n 100 --no-pager
```

Follow service logs:

```bash
sudo journalctl -u ziti-edge-tunnel-OpenSlice-central-domain.service -f
```

Restart the service:

```bash
sudo systemctl restart ziti-edge-tunnel-OpenSlice-central-domain.service
```

---

## Notes

Do not start the tunneler manually with `nohup` if it is already running as a systemd service.

Avoid running this command:

```bash
sudo nohup /usr/local/bin/ziti-edge-tunnel run -i <identity.json> > ziti-<identity>.log 2>&1 &
```

Using both `nohup` and `systemd` at the same time may start multiple tunnelers with the same identity.
