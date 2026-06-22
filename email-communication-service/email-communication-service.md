# Azure Communication Services - Email Communication Service Setup with AWS Route 53

## Overview

This document explains the complete process of configuring **Azure Communication Services (ACS)** for email using a **custom domain** hosted in **AWS Route 53**.

The document covers:

* Creating an Email Communication Service
* Creating an Azure Communication Service
* Linking the Email Communication Service with Azure Communication Service
* Configuring a custom domain
* Validating the domain using SPF, DKIM1 and DKIM2
* Testing email delivery

---

# Architecture

```text
                    Azure
+--------------------------------------------+
|                                            |
|  Email Communication Service               |
|            │                               |
|            ▼                               |
|  Azure Communication Service               |
|            │                               |
|            ▼                               |
|     Send Email API                         |
+--------------------------------------------+

                ▲
                │
                │ DNS Validation
                │
+--------------------------------------------+
|          AWS Route 53                      |
|                                            |
| Custom Domain                              |
| uat-uae.safegold.com                       |
|                                            |
| SPF                                        |
| DKIM1                                      |
| DKIM2                                      |
+--------------------------------------------+
```

---

# Prerequisites

* Azure Subscription
* Azure Communication Service
* Email Communication Service
* AWS Route 53 Hosted Zone
* Custom Domain

Example:

```text
uat-uae.safegold.com
```

---

# Step 1 - Create Email Communication Service

1. Open Azure Portal.
2. Search for **Email Communication Service**.
3. Click **Create**.
4. Select:

   * Subscription
   * Resource Group
   * Region
5. Click **Review + Create**.
6. Click **Create**.

> **Screenshot**
>
> `docs/images/email-communication-service-create.png`

---

# Step 2 - Create Azure Communication Service

1. Open Azure Portal.
2. Search for **Communication Services**.
3. Click **Create**.
4. Select:

   * Subscription
   * Resource Group
   * Region
5. Click **Review + Create**.
6. Click **Create**.

> **Screenshot**
>
> `docs/images/communication-service-create.png`

---

# Step 3 - Connect Email Communication Service

Open the Azure Communication Service.

Navigate to:

```text
Email
→ Connect Email Communication Service
```

Select the Email Communication Service created in Step 1.

Click **Save**.

> **Screenshot**
>
> `docs/images/connect-email-service.png`

---

# Step 4 - Add Custom Domain

Navigate to:

```text
Email Communication Service
→ Domains
→ Add Domain
```

Choose

```text
Custom Managed Domain
```

Example:

```text
uat-uae.safegold.com
```

Azure will generate DNS validation records.

> **Screenshot**
>
> `docs/images/custom-domain.png`

---

# Step 5 - Configure DNS Records in AWS Route 53

Open

```text
AWS Console
→ Route 53
→ Hosted Zones
→ uat-uae.safegold.com
```

Create all records provided by Azure.

Typically:

* SPF (TXT)
* DKIM1 (CNAME)
* DKIM2 (CNAME)

---

## Important Note (AWS Route 53)

**When creating DNS records in Route 53, always use the FULL record name provided by Azure.**

### Incorrect

```text
selector1-azurecomm-prod-net._domainkey
```

### Correct

```text
selector1-azurecomm-prod-net._domainkey.uat-uae.safegold.com
```

Similarly,

### Incorrect

```text
selector2-azurecomm-prod-net._domainkey
```

### Correct

```text
selector2-azurecomm-prod-net._domainkey.uat-uae.safegold.com
```

Do **not** shorten the record name.

Use the complete hostname exactly as shown by Azure.

This is required because the hosted zone is managed in AWS Route 53.

> **Important**
>
> Always copy the complete hostname from Azure without removing the domain suffix.

---

# Step 6 - Validate the Domain

After creating the DNS records, return to Azure.

Navigate to:

```text
Email Communication Service
→ Domains
```

Click

```text
Verify
```

Azure validates:

* SPF
* DKIM1
* DKIM2

Status should become:

```text
Verified
```

> **Screenshot**
>
> `docs/images/domain-verified.png`

---

# Step 7 - Connect Domain with Azure Communication Service

Navigate to

```text
Azure Communication Service
→ Email
```

The verified domain should now be available.

Example:

```text
no-reply@uat-uae.safegold.com
```

Use this domain as the sender address for email operations.

---

# Validation

Verify the following:

* Email Communication Service is deployed.
* Azure Communication Service is deployed.
* Email Communication Service is linked.
* SPF record is validated.
* DKIM1 is validated.
* DKIM2 is validated.
* Domain status is **Verified**.
* Test email is delivered successfully.

---

# Troubleshooting

## SPF Not Verified

* Ensure the TXT record is copied exactly from Azure.
* Check for duplicate SPF records.

---

## DKIM Validation Failed

Verify that the CNAME record name is the **full hostname**.

Example:

Correct:

```text
selector1-azurecomm-prod-net._domainkey.uat-uae.safegold.com
```

Incorrect:

```text
selector1-azurecomm-prod-net._domainkey
```

---

## DNS Changes Not Reflected

DNS propagation may take several minutes depending on TTL.

Wait and retry verification.

---

# Recommended Repository Structure

```text
email-communication-service/
│
├── README.md
│
└── docs/
    └── images/
        ├── email-communication-service-create.png
        ├── communication-service-create.png
        ├── connect-email-service.png
        ├── custom-domain.png
        └── domain-verified.png
```
