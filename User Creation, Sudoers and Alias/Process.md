# Jump Server User Access Management

## Overview

This document describes the implementation of a secure access mechanism on the Azure Jump Server. The solution allows only authorized users to execute predefined SSH wrapper scripts while preventing direct access to the script contents. Access control is enforced using **Linux users**, **sudoers**, **root-owned scripts**, and **global aliases**.

---

# Architecture

```
                   Azure Jump Server
                          │
        ┌─────────────────┴─────────────────┐
        │                                   │
   Linux Users                         Root User
(deven, amit, etc.)                        │
        │                                  │
        │                          /root/scripts/
        │                                  │
        │                        Production SSH Scripts
        │                                  │
        └────────────── sudo ───────────────┘
                          │
                    SSH to Target VM
```

---

# Directory Structure

```
/root/scripts/
├── prod_ssh/
│   ├── admin_prod.sh
│   ├── api_prod.sh
│   ├── logistics_prod.sh
│   ├── partner_prod.sh
│   ├── superset_prod.sh
│   ├── superset_old_prod.sh
│   └── ui_prod.sh
```

Global alias file:

```
/etc/profile.d/prod_vm_alias.sh
```

---

# 1. Create Linux Users

Create the required users on the jump server.

```bash
sudo adduser deven
sudo adduser amit
```

Verify user creation.

```bash
id deven
id amit
```

Example output:

```text
uid=1001(deven) gid=1001(deven)
uid=1002(amit) gid=1002(amit)
```

---

# 2. Create SSH Wrapper Scripts

Store all SSH wrapper scripts under the root-owned directory.

```
/root/scripts/prod_ssh/
```

Example:

```bash
sudo mkdir -p /root/scripts/prod_ssh

sudo vi /root/scripts/prod_ssh/admin_prod.sh
```

Example script:

```bash
#!/bin/bash

HOST="xxx.xxx.xxx.xxx"
USER="username"
PASS="password"

sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no "$USER@$HOST"
```

Repeat the same process for all required Production servers.

---

# 3. Secure the Scripts

Assign ownership to the root user.

```bash
sudo chown root:root /root/scripts/prod_ssh/*.sh
```

Restrict permissions so that only root can read, modify, or execute the scripts.

```bash
sudo chmod 700 /root/scripts/prod_ssh/*.sh
```

Verify the permissions.

```bash
ls -l /root/scripts/prod_ssh
```

Expected output:

```text
-rwx------ 1 root root admin_prod.sh
-rwx------ 1 root root api_prod.sh
-rwx------ 1 root root logistics_prod.sh
-rwx------ 1 root root partner_prod.sh
-rwx------ 1 root root superset_prod.sh
-rwx------ 1 root root superset_old_prod.sh
-rwx------ 1 root root ui_prod.sh
```

---

# 4. Configure sudoers

Edit the sudoers file using the safe editor.

```bash
sudo visudo
```

Grant execution permission only for the required scripts.

```text
# Grant Production SSH access to user 'deven'

deven ALL=(root) NOPASSWD: \
/root/scripts/prod_ssh/admin_prod.sh, \
/root/scripts/prod_ssh/api_prod.sh, \
/root/scripts/prod_ssh/logistics_prod.sh, \
/root/scripts/prod_ssh/partner_prod.sh, \
/root/scripts/prod_ssh/ui_prod.sh, \
/root/scripts/prod_ssh/superset_prod.sh, \
/root/scripts/prod_ssh/superset_old_prod.sh
```

Only the listed scripts can be executed by the specified user.

---

# 5. Verify sudo Permissions

Switch to the user.

```bash
su - deven
```

Verify the permitted commands.

```bash
sudo -l
```

Expected output:

```text
(root) NOPASSWD:
/root/scripts/prod_ssh/admin_prod.sh
/root/scripts/prod_ssh/api_prod.sh
/root/scripts/prod_ssh/logistics_prod.sh
/root/scripts/prod_ssh/partner_prod.sh
/root/scripts/prod_ssh/ui_prod.sh
/root/scripts/prod_ssh/superset_prod.sh
/root/scripts/prod_ssh/superset_old_prod.sh
```

---

# 6. Configure Global Aliases

Instead of configuring aliases for individual users, maintain a central alias file.

Location:

```
/etc/profile.d/prod_vm_alias.sh
```

Create or edit the file.

```bash
sudo vi /etc/profile.d/prod_vm_alias.sh
```

Add the following aliases.

```bash
alias prod_admin='sudo /root/scripts/prod_ssh/admin_prod.sh'
alias prod_api='sudo /root/scripts/prod_ssh/api_prod.sh'
alias prod_logistics='sudo /root/scripts/prod_ssh/logistics_prod.sh'
alias prod_partner='sudo /root/scripts/prod_ssh/partner_prod.sh'
alias prod_ui='sudo /root/scripts/prod_ssh/ui_prod.sh'
alias prod_superset='sudo /root/scripts/prod_ssh/superset_prod.sh'
alias prod_superset_old='sudo /root/scripts/prod_ssh/superset_old_prod.sh'
```

Set appropriate permissions.

```bash
sudo chown root:root /etc/profile.d/prod_vm_alias.sh
sudo chmod 644 /etc/profile.d/prod_vm_alias.sh
```

---

# 7. Load the Aliases

Reload the shell profile.

```bash
source /etc/profile
```

Alternatively, log out and log back in.

Verify the aliases.

```bash
alias
```

Expected output:

```text
prod_admin='sudo /root/scripts/prod_ssh/admin_prod.sh'
prod_api='sudo /root/scripts/prod_ssh/api_prod.sh'
prod_logistics='sudo /root/scripts/prod_ssh/logistics_prod.sh'
prod_partner='sudo /root/scripts/prod_ssh/partner_prod.sh'
prod_ui='sudo /root/scripts/prod_ssh/ui_prod.sh'
prod_superset='sudo /root/scripts/prod_ssh/superset_prod.sh'
prod_superset_old='sudo /root/scripts/prod_ssh/superset_old_prod.sh'
```

---

# 8. Validate Access

Execute any alias.

```bash
prod_admin
```

```bash
prod_api
```

```bash
prod_partner
```

```bash
prod_ui
```

```bash
prod_logistics
```

```bash
prod_superset
```

```bash
prod_superset_old
```

Each alias invokes its corresponding SSH wrapper script using `sudo`.

---

# Security Considerations

* SSH wrapper scripts are owned by the **root** user.
* Script permissions are restricted to **700**, preventing unauthorized users from viewing or modifying script contents.
* User access is controlled exclusively through the **sudoers** configuration.
* Global aliases are managed centrally under `/etc/profile.d`, eliminating the need to configure aliases individually for each user.
* Users can execute only the scripts explicitly listed in the `sudoers` file.
* Embedded credentials remain protected because users cannot read the script files.

---

# Validation Checklist

| Task                               | Status |
| ---------------------------------- | ------ |
| Create Linux users                 | ✅      |
| Create SSH wrapper scripts         | ✅      |
| Secure scripts with root ownership | ✅      |
| Restrict permissions (700)         | ✅      |
| Configure sudoers                  | ✅      |
| Verify sudo permissions            | ✅      |
| Configure global aliases           | ✅      |
| Reload shell profile               | ✅      |
| Validate alias execution           | ✅      |

---

# Conclusion

This implementation provides a secure, centralized, and scalable mechanism for managing production server access through an Azure Jump Server. By combining **root-owned SSH wrapper scripts**, **sudoers-based authorization**, and **global aliases**, administrators can enforce least-privilege access while providing users with a simple and consistent interface for connecting to approved production servers.
