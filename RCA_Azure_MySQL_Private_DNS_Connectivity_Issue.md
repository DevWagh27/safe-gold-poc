# RCA: Azure Database for MySQL Flexible Server Connectivity Issue

> **Document Type:** Root Cause Analysis (RCA)\
> **Environment:** Azure UAT\
> **Prepared By:** DevOps Team

------------------------------------------------------------------------

# Table of Contents

1.  Overview
2.  Environment
3.  Problem Statement
4.  Initial Investigation
5.  Root Cause Analysis
6.  Resolution
7.  Validation
8.  Lessons Learned
9.  Preventive Actions
10. Commands Used

------------------------------------------------------------------------

# 1. Overview

This document captures the investigation and resolution of a
connectivity issue between the Jump Server and an Azure Database for
MySQL Flexible Server deployed using **Private Access (VNet
Integration)**.

------------------------------------------------------------------------

# 2. Environment

``` text
Developer Laptop
        │
       VPN
        │
        ▼
Jump Server (tools-vnet)
        │
        │  VNet Peering
        ▼
UAT VNet
        │
        ▼
Azure Database for MySQL Flexible Server
(Private Access)
```

## Components

  Component      Details
  -------------- ------------------------------------------
  Database       Azure Database for MySQL Flexible Server
  Connectivity   Private Access (VNet Integration)
  Jump Host      Ubuntu VM
  Networking     VNet Peering
  DNS            Azure Private DNS Zone

------------------------------------------------------------------------

# 3. Problem Statement

The Jump Server was unable to establish a connection to the MySQL
Flexible Server over the private network.

Symptoms included:

-   `telnet <server>.mysql.database.azure.com 3306` failed.
-   MySQL client connection timed out.
-   Database hostname could not be resolved.

------------------------------------------------------------------------

# 4. Initial Investigation

The following components were verified:

  Component           Status
  ------------------- ----------
  VNet Peering        Verified
  NSG Rules           Verified
  Routing             Verified
  MySQL Port (3306)   Verified
  DNS Resolution      Failed

------------------------------------------------------------------------

# 5. Root Cause Analysis

## DNS Validation

Executed:

``` bash
nslookup uat-uae-safegold.mysql.database.azure.com
```

Result:

``` text
NXDOMAIN
```

Further investigation:

``` bash
dig uat-uae-safegold.mysql.database.azure.com
```

Output indicated that Azure correctly redirected the hostname to a
private endpoint:

``` text
uat-uae-safegold.mysql.database.azure.com
            │
            ▼
CNAME
uat-uae-safegold.uat-uae-safegold.private.mysql.database.azure.com
            │
            ▼
NXDOMAIN
```

### Findings

The MySQL Flexible Server was configured with **Private Access** and
depended on the Azure Private DNS Zone.

The Jump Server VNet (`tools-vnet`) was **not linked** to the Private
DNS Zone (`private.mysql.database.azure.com`).

As a result:

-   DNS resolution failed.
-   The database hostname could not resolve to its private IP.
-   Connectivity failed before TCP communication could be established.

------------------------------------------------------------------------

# 6. Resolution

## Implemented Fix

Navigated to:

``` text
Private DNS Zones
    └── private.mysql.database.azure.com
            └── Virtual Network Links
```

Added:

``` text
tools-vnet
```

Resulting configuration:

``` text
Private DNS Zone
(private.mysql.database.azure.com)

│
├── uat-uae-vnet
└── tools-vnet
```

------------------------------------------------------------------------

# 7. Validation

DNS resolution after the change:

``` bash
nslookup uat-uae-safegold.mysql.database.azure.com
```

Result:

-   Hostname successfully resolved to the private IP.

Connectivity verification:

``` bash
telnet uat-uae-safegold.mysql.database.azure.com 3306
```

``` bash
mysql -h uat-uae-safegold.mysql.database.azure.com \
      -u <username> \
      -p
```

Both tests completed successfully.

------------------------------------------------------------------------

# 8. Lessons Learned

-   VNet Peering alone does **not** provide Private DNS resolution.
-   Azure Database for MySQL Flexible Server with Private Access
    requires the consuming VNet to be linked to the appropriate Azure
    Private DNS Zone.
-   DNS validation should be one of the first troubleshooting steps for
    private endpoint connectivity.

------------------------------------------------------------------------

# 9. Preventive Actions

-   Maintain an inventory of required Azure Private DNS Zones.
-   Link every consumer VNet to the required Private DNS Zones during
    infrastructure deployment.
-   Validate DNS resolution as part of deployment verification.
-   Include connectivity tests (`nslookup`, `nc`, `mysql`) in
    post-deployment validation.

------------------------------------------------------------------------

# 10. Commands Used

``` bash
nslookup uat-uae-safegold.mysql.database.azure.com

dig uat-uae-safegold.mysql.database.azure.com

telnet uat-uae-safegold.mysql.database.azure.com 3306

nc -zv uat-uae-safegold.mysql.database.azure.com 3306

mysql -h uat-uae-safegold.mysql.database.azure.com \
      -u <username> \
      -p
```

------------------------------------------------------------------------

# Conclusion

The connectivity issue was caused by a missing Virtual Network Link
between the Jump Server VNet (`tools-vnet`) and the Azure Private DNS
Zone (`private.mysql.database.azure.com`). After linking the VNet to the
Private DNS Zone, DNS resolution succeeded and the Jump Server was able
to connect to the Azure Database for MySQL Flexible Server over the
private network.
