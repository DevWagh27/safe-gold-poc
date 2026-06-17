# SG-POC: Secure Jump Server Access Using OpenVPN

## Overview

This Proof of Concept (POC) demonstrates how to secure an Azure Jump Server by restricting SSH access to authenticated users connected through an OpenVPN server.

Instead of exposing SSH (Port 22) directly to the Internet, administrators must first establish a VPN connection. The Jump Server only accepts SSH traffic originating from the OpenVPN server.

---

## Existing Architecture

```text
Internet
    |
SSH (Port 22)
    |
Jump Server
    |
Application VM(s)
```

### Issues

* SSH was publicly accessible over the Internet.
* Anyone could attempt to connect to the Jump Server.
* Increased attack surface and exposure to brute-force attacks.

---

## Target Architecture

```text
                   Internet
                       |
                 OpenVPN (1194/UDP)
                       |
                +----------------+
                | OpenVPN Server |
                +----------------+
                       |
                 Azure Virtual Network
                       |
        +-----------------------------+
        |                             |
   Jump Server                  Application VM(s)
```

---

## Objective

* Remove public SSH access to the Jump Server.
* Require VPN authentication before SSH access.
* Continue using the Jump Server as the administrative entry point for internal Azure VMs.

---

## Implementation

### 1. Deploy OpenVPN Server

* OpenVPN server deployed as a separate Azure VM.
* OpenVPN Server and Jump Server are located in the same Azure VNet.

---

### 2. Configure Azure NSG

Update the **Jump Server Network Security Group**.

**Allow SSH only from the OpenVPN Server Private IP.**

Example:

| Setting          | Value                     |
| ---------------- | ------------------------- |
| Source           | IP Addresses              |
| Source IP        | `<OpenVPN-Private-IP>/32` |
| Destination Port | `22`                      |
| Protocol         | TCP                       |
| Action           | Allow                     |

Remove or disable the existing rule:

| Source | Port |
| ------ | ---- |
| Any    | 22   |

---

## Connection Flow

```text
Administrator Laptop
        |
Connect to OpenVPN
        |
OpenVPN Server
        |
SSH
        |
Jump Server
        |
SSH
        |
Application VM
```

---

## Why Only the OpenVPN Server Private IP Is Allowed

Initially, it was expected that the Jump Server NSG would need to allow the VPN client network (for example, `172.27.240.0/20`).

During testing, it was observed that allowing only the **private IP address of the OpenVPN Server** was sufficient.

This indicates that the existing OpenVPN deployment performs **Source Network Address Translation (SNAT/MASQUERADE)**.

Traffic flow:

```text
VPN Client
172.27.x.x
      |
      |
OpenVPN Server
10.x.x.x
      |
      | SNAT
      |
Jump Server
```

From the Jump Server's perspective, every SSH connection originates from the **OpenVPN Server Private IP** rather than the individual VPN client's IP address.

As a result, the NSG only needs to trust the OpenVPN Server.

---

## Benefits

* SSH is no longer exposed to the Internet.
* Only authenticated VPN users can access the Jump Server.
* Reduced attack surface.
* Existing SSH workflow from the Jump Server to Application VMs remains unchanged.
* No changes required on Application VMs.

---

## Validation

1. Connect to the OpenVPN server.
2. Verify VPN connectivity.
3. SSH to the Jump Server.
4. SSH from the Jump Server to the Application VM.
5. Confirm that direct SSH access from the Internet is blocked.

---

## Final Architecture

```text
                   Internet
                       |
                 OpenVPN (1194/UDP)
                       |
                +----------------+
                | OpenVPN Server |
                | (Public + Private IP)
                +----------------+
                       |
                Azure Virtual Network
                       |
                +----------------+
                |  Jump Server   |
                +----------------+
                       |
                +----------------+
                | Application VM |
                +----------------+
```

---

## Notes

* The OpenVPN server is deployed as a dedicated VM.
* The OpenVPN server and Jump Server reside in the same Azure Virtual Network.
* The OpenVPN server performs Source NAT (SNAT), therefore the Jump Server only sees the OpenVPN Server's private IP.
* Azure NSG is configured to allow SSH only from the OpenVPN Server's private IP.
* No routing or configuration changes were required for the Application VMs.
