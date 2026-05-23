# Lab 1 — Active Directory 
*Windows Server 2025 · Azure · Identity & Access Management*

[![Certification](https://img.shields.io/badge/Cert%20Alignment-CompTIA%20Network%2B%20%7C%20Security%2B%20%7C%20Azure%20Administrator-blue)](https://www.comptia.org)
[![Cost](https://img.shields.io/badge/Estimated%20Cost-%240-brightgreen)](https://azure.microsoft.com/free)
[![Time](https://img.shields.io/badge/Time%20to%20Complete-3--5%20hours-orange)]()
[![Platform](https://img.shields.io/badge/Platform-Azure%20%7C%20VirtualBox-informational)]()



---

## Overview

Every enterprise running Windows infrastructure depends on Active Directory (AD) as the foundation of its identity and access management (IAM) strategy — controlling authentication, authorization, and access governance across the entire environment.

Active Directory is the identity backbone of on-premises and hybrid cloud architectures. It enforces role-based access control (RBAC), manages privileged access, and applies security policies across users, endpoints, and resources — defining who authenticates to which systems, which security groups control access to file shares and applications, and which Group Policy Objects (GPOs) govern compliance configurations across the domain.

From a zero trust security perspective, AD is where identity verification begins. When a user is provisioned, group membership automatically grants least-privilege access to email, shared drives, and business-critical applications. When a user is offboarded, a single account disable revokes all access simultaneously — reducing the attack surface and eliminating orphaned credentials that threat actors exploit.

This is not legacy technology. Modern hybrid cloud environments synchronize on-premises Active Directory with Microsoft Entra ID (Azure AD) via Azure AD Connect, extending identity management into the cloud. The same core competencies — user lifecycle management, group policy administration, OU structure design, and privileged identity governance — underpin enterprise Azure, Microsoft 365, and cloud security deployments.

Hands-on Active Directory experience is directly applicable to roles in cloud infrastructure, IAM engineering, SOC analysis, and endpoint security — and remains the most targeted system in ransomware and Active Directory attacks such as Pass-the-Hash, Kerberoasting, and DCSync.

> **Career relevance:** IT Support · Sysadmin · Cloud Engineer · Security Analyst

---

## Architecture
<img width="1472" height="1240" alt="image" src="https://github.com/user-attachments/assets/9a4f0fc6-4807-426d-b92d-b7378c6b9957" />


## Trust boundary summary:

| Zone | Components | Access |
|---|---|---|
| Public internet | Admin workstation | RDP to DC (port 3389) only |
| Domain (lab.local) | DC, OUs, workstations | Authenticated domain users |
| Privileged | IT_Admins group, Domain Admin account | Full AD management |

---

## What This Lab Builds

| Component | Details |
|---|---|
| **Domain** | `lab.local` — one forest, one domain |
| **Domain Controller** | Windows Server 2025 Datacenter — Standard_B2s (Azure) |
| **Organisational Units** | IT, Finance, HR, Sales, Computers |
| **Security Groups** | IT_Admins, Finance_Users, HR_Users, Sales_Users |
| **User Accounts** | alice.chen (IT), bob.patel (Finance), carol.jones (HR), david.smith (Sales) |
| **Group Policy Object** | IT Security Policy — password length, complexity, screen lock, USB block |
| **Help Desk Tasks** | Password reset, account unlock, offboarding, inactive account audit |

---

## Skills Developed

| Skill | Real-World Application |
|---|---|
| Promote a server to Domain Controller | Foundation of every enterprise Windows environment |
| Create and structure Organisational Units | Apply policies per department without touching individual machines |
| Create users, groups, and memberships | Role-based access at scale — add one person to a group, inherit all access |
| Configure Group Policy Objects (GPOs) | Centrally enforce security settings across all domain machines |
| Join a machine to the domain | Turn a standalone workstation into a managed, policy-enforced resource |
| Reset passwords and manage account lifecycle | Top-three help desk task in any enterprise |

---

## Prerequisites

| Requirement | Notes |
|---|---|
| **Azure free account** | [azure.microsoft.com/free](https://azure.microsoft.com/free) — includes $200 credit |
| **Remote Desktop client** | Windows built-in or [Microsoft Remote Desktop](https://apps.apple.com/app/microsoft-remote-desktop/id1295203466) for macOS |
| **Basic Windows familiarity** | Navigating Server Manager, PowerShell basics |

> **No Azure account?** VirtualBox (free) + Windows Server 2025 Evaluation ISO (180-day, free) can replace Azure entirely. Minimum host hardware: 8 GB RAM, quad-core CPU with virtualisation enabled in BIOS, 60 GB free disk.

---

## Step-by-Step Instructions

### Step 1 — Provision the Virtual Machine

**Option A — Azure (Recommended)**

1. Go to [azure.microsoft.com/free](https://azure.microsoft.com/free) and create a free account.
2. Sign in to [portal.azure.com](https://portal.azure.com).
3. Search for **Virtual machines** → **Create**.
4. Use these settings:

| Setting | Value |
|---|---|
| Region | East US |
| Image | Windows Server 2025 Datacenter — Gen2 |
| Size | Standard_B2s (2 vCPU, 4 GB RAM) |
| Authentication | Password (set a strong one — used for RDP) |
| Public inbound ports | Allow RDP (3389) |
| OS disk | Standard SSD |

5. Click **Review + Create** → **Create**.

> ⚠️ **Stop the VM when not in use.** A B2s VM costs ~$0.05/hour. Stopping (not deleting) pauses compute billing. Your $200 credit lasts significantly longer with disciplined stop/start hygiene.

**Enable clipboard between your machine and the VM:**

1. Open the Remote Desktop application on your local machine.
2. Enter the VM's public IP address.
3. Click **Show Options** → **Local Resources** tab.
4. Ensure **Clipboard** is checked under *Local devices and resources*.
5. Click **Connect**.

> Download the RDP file from the Azure portal (**Connect → Download RDP File**) and open it with the native Remote Desktop app rather than the browser-based console. The browser console has very limited clipboard support.

---

**Option B — VirtualBox (Local)**

1. Download [VirtualBox](https://www.virtualbox.org) — free, no account required.
2. Download the [Windows Server 2025 Evaluation ISO](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2025) from Microsoft Evaluation Center (180-day free licence).
3. Create a new VM: 4 GB RAM minimum, 60 GB disk, type = Windows Server 2022.
4. Mount the ISO and boot. Select **Windows Server 2025 Datacenter with Desktop Experience** during setup.

---

### Step 2 — Install Active Directory Domain Services

RDP into the VM. Server Manager opens automatically on login.

1. Click **Manage → Add Roles and Features**.
2. Click **Next** until **Server Roles**.
3. Check **Active Directory Domain Services**.
4. When prompted, click **Add Features**.
5. Click **Next** through remaining pages → **Install**.
6. Wait for completion (2–3 minutes) → **Close**. Do not restart yet.

```powershell
# PowerShell alternative
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
```

**Install Group Policy Management Console (GPMC) now** — required for Step 5. Without it, the GPO tools will not appear in Server Manager.

```powershell
Install-WindowsFeature -Name GPMC
```

---

### Step 3 — Promote the Server to a Domain Controller

Installing the AD DS role does not create a domain. Promotion creates your forest, domain, and makes this server the authoritative DNS and identity server.

1. In Server Manager, click the **yellow warning flag** (top right).
2. Click **Promote this server to a domain controller**.
3. Select **Add a new forest**.
4. Set Root domain name to: `lab.local`
5. Click **Next** — set a DSRM password (write it down — for disaster recovery only).
6. Accept defaults through DNS Options and NetBIOS pages.
7. Click **Install** — the server restarts automatically when complete.

```powershell
# PowerShell alternative
Import-Module ADDSDeployment
Install-ADDSForest `
  -DomainName 'lab.local' `
  -DomainNetBiosName 'LAB' `
  -InstallDns:$true `
  -SafeModeAdministratorPassword (ConvertTo-SecureString 'YourDSRMPassword!' -AsPlainText -Force) `
  -Force:$true
```

> After restart, log in as `LAB\Administrator` (not just `Administrator`).

---

### Step 4 — Build the Organisational Structure

Open **Active Directory Users and Computers (ADUC)** from **Tools** in Server Manager.

**Create Organisational Units**

Right-click your domain (`lab.local`) → **New → Organizational Unit**. Create one OU per department plus one for computers.

```powershell
New-ADOrganizationalUnit -Name "IT"        -Path "DC=lab,DC=local"
New-ADOrganizationalUnit -Name "Finance"   -Path "DC=lab,DC=local"
New-ADOrganizationalUnit -Name "HR"        -Path "DC=lab,DC=local"
New-ADOrganizationalUnit -Name "Sales"     -Path "DC=lab,DC=local"
New-ADOrganizationalUnit -Name "Computers" -Path "DC=lab,DC=local"
```

**Create Security Groups**

Right-click each OU → **New → Group**. Set Group scope to **Global**, Group type to **Security**.

```powershell
New-ADGroup -Name "IT_Admins"     -GroupScope Global -GroupCategory Security -Path "OU=IT,DC=lab,DC=local"
New-ADGroup -Name "Finance_Users" -GroupScope Global -GroupCategory Security -Path "OU=Finance,DC=lab,DC=local"
New-ADGroup -Name "HR_Users"      -GroupScope Global -GroupCategory Security -Path "OU=HR,DC=lab,DC=local"
New-ADGroup -Name "Sales_Users"   -GroupScope Global -GroupCategory Security -Path "OU=Sales,DC=lab,DC=local"
```

**Create User Accounts and Group Memberships**

> ⚠️ **Run the entire block at once** — not line by line. The `$password` variable must be defined before the `New-ADUser` commands execute. Select all, then paste the full block into PowerShell and press Enter.

```powershell
# Run this entire block together

# Step 1 — define the password variable first
$password = ConvertTo-SecureString "Welcome@2026!" -AsPlainText -Force

# Step 2 — create users
New-ADUser -Name "alice.chen" -GivenName "Alice" -Surname "Chen" `
  -SamAccountName "alice.chen" -UserPrincipalName "alice.chen@lab.local" `
  -Path "OU=IT,DC=lab,DC=local" -AccountPassword $password -Enabled $true

New-ADUser -Name "bob.patel" -GivenName "Bob" -Surname "Patel" `
  -SamAccountName "bob.patel" -UserPrincipalName "bob.patel@lab.local" `
  -Path "OU=Finance,DC=lab,DC=local" -AccountPassword $password -Enabled $true

New-ADUser -Name "carol.jones" -GivenName "Carol" -Surname "Jones" `
  -SamAccountName "carol.jones" -UserPrincipalName "carol.jones@lab.local" `
  -Path "OU=HR,DC=lab,DC=local" -AccountPassword $password -Enabled $true

New-ADUser -Name "david.smith" -GivenName "David" -Surname "Smith" `
  -SamAccountName "david.smith" -UserPrincipalName "david.smith@lab.local" `
  -Path "OU=Sales,DC=lab,DC=local" -AccountPassword $password -Enabled $true

# Step 3 — assign group memberships
Add-ADGroupMember -Identity "IT_Admins"     -Members "alice.chen"
Add-ADGroupMember -Identity "Finance_Users" -Members "bob.patel"
Add-ADGroupMember -Identity "HR_Users"      -Members "carol.jones"
Add-ADGroupMember -Identity "Sales_Users"   -Members "david.smith"
```

---

### Step 5 — Configure Group Policy

Open **Group Policy Management** from **Tools** in Server Manager.

1. Expand **Forest: lab.local → Domains → lab.local**.
2. Right-click the **IT** OU → **Create a GPO in this domain and link it here**.
3. Name it: `IT Security Policy`
4. Right-click the new GPO → **Edit**.
5. Apply the following settings:

| Policy Path | Setting | Value |
|---|---|---|
| Computer Config → Windows Settings → Security → Account Policies → Password Policy | Minimum password length | 12 |
| Computer Config → Windows Settings → Security → Account Policies → Password Policy | Password must meet complexity requirements | Enabled |
| Computer Config → Windows Settings → Security → Local Policies → Security Options | Interactive logon: Machine inactivity limit | 900 seconds |
| Computer Config → Administrative Templates → System → Removable Storage Access | All removable storage classes: Deny all access | Enabled |

**Test the GPO:** Join a second VM to `lab.local`, move its computer account to the Computers OU, run `gpupdate /force`, log in as `alice.chen`, and verify the screen lock takes effect after 15 minutes of inactivity.

---

### Step 6 — Common Help Desk Tasks

Practice each task on the test accounts created in Step 4.

**Reset a password**
```powershell
Set-ADAccountPassword -Identity "bob.patel" -Reset `
  -NewPassword (ConvertTo-SecureString "NewPass@2026!" -AsPlainText -Force)
Set-ADUser -Identity "bob.patel" -ChangePasswordAtLogon $true
```

**Unlock a locked account**
```powershell
Unlock-ADAccount -Identity "carol.jones"
```

**Disable an account (offboarding)**
```powershell
# Disable — preserves account history and group memberships for audit
Disable-ADAccount -Identity "david.smith"

# Find all currently disabled accounts
Search-ADAccount -AccountDisabled | Select-Object Name, SamAccountName
```

**Audit inactive accounts**
```powershell
# Accounts not logged in for 90+ days
$cutoff = (Get-Date).AddDays(-90)
Get-ADUser -Filter {LastLogonDate -lt $cutoff -and Enabled -eq $true} `
  -Properties LastLogonDate | Select-Object Name, LastLogonDate

# Check a specific user's group memberships
Get-ADPrincipalGroupMembership -Identity "alice.chen" | Select-Object Name
```

---

## Verification Checklist

Run these commands after completing the lab to confirm everything is working correctly.

| Check | Command | Expected Result |
|---|---|---|
| Domain controller is running | `Get-ADDomainController` | Returns DC info including forest `lab.local` |
| All OUs exist | `Get-ADOrganizationalUnit -Filter *` | Lists all 5 OUs |
| Users exist and are enabled | `Get-ADUser -Filter {Enabled -eq $true}` | Returns 4 test accounts |
| Group membership is correct | `Get-ADGroupMember -Identity IT_Admins` | Returns `alice.chen` |
| GPO is linked | `Get-GPInheritance -Target 'OU=IT,DC=lab,DC=local'` | Shows `IT Security Policy` as linked |

---

## Troubleshooting

| Problem | Fix |
|---|---|
| PowerShell prompts for `Name:` when creating users | You ran `New-ADUser` before defining `$password`. Run the **entire block from Step 4** at once — the variable must be defined first. |
| Cannot copy and paste into the VM | Open the RDP client → **Show Options → Local Resources** → check **Clipboard**. Reconnect. Alternatively, download the RDP file from the Azure portal and open it with the native Remote Desktop app. |
| Promotion fails — DNS conflict | Set the NIC's preferred DNS to `127.0.0.1` before promoting, or use the VM's static IP. |
| Cannot RDP after domain join | Log in as `LAB\Administrator`, not just `Administrator`. |
| GPO not applying | Run `gpupdate /force` on the target machine. Then run `gpresult /r` to confirm which policies are applied. |
| User cannot log in after creation | Confirm the account is **Enabled** and `ChangePasswordAtLogon` is not set if you want the first login to work without a prompt. |
| AD Users and Computers not showing | Run `dsa.msc` from the Run dialog. Or install RSAT: `Add-WindowsFeature RSAT-ADDS` |

---

## Key Concepts

<details>
<summary><strong>What is a Domain Controller?</strong></summary>

A Domain Controller (DC) is the brain of the entire identity system. It runs Active Directory, handles authentication for every domain-joined machine, and is the single source of truth for all user accounts, group memberships, and policies. When a user logs in anywhere on the domain, their credentials are verified against the DC.

</details>

<details>
<summary><strong>What is a Forest and Domain?</strong></summary>

A **Forest** is the top-level container of your entire Active Directory structure — think of it as the organisation itself. A **Domain** is a boundary inside the forest with a DNS-style name (`lab.local`). Everything inside a domain is managed together. Most SMBs have one domain in one forest. Large enterprises may have multiple.

</details>

<details>
<summary><strong>What is an Organisational Unit (OU)?</strong></summary>

An OU is a folder inside Active Directory. You use OUs to organise users, computers, and groups by department or function. The real power of an OU is that you can link a Group Policy to it — every user or computer inside that OU automatically receives that policy.

</details>

<details>
<summary><strong>What is a Security Group?</strong></summary>

A Security Group is a container of user accounts. Instead of granting access to a resource (file share, application, etc.) to individual users one at a time, you grant access to the group. This is role-based access control: add a user to the group and they instantly inherit all group access. Remove them and all access is revoked simultaneously.

</details>

<details>
<summary><strong>What is a Group Policy Object (GPO)?</strong></summary>

A GPO is a collection of settings that Windows enforces automatically on every user or computer inside an OU. You create one GPO, link it to an OU, and every machine in that OU gets those rules on next login or after `gpupdate /force`. Password policies, screen lock timers, USB restrictions — all enforced centrally without touching individual machines.

</details>

---

## Why This Matters for Cloud Roles

Active Directory is not legacy technology. Hybrid environments sync on-premises AD identities to **Microsoft Entra ID** (formerly Azure AD). The core concepts — users, groups, roles, conditional access — are identical. Every enterprise cloud environment you'll work in assumes this knowledge.

Active Directory is also the **most targeted system in ransomware attacks**. Understanding how it is built is the foundation of understanding how it is attacked and defended.

---

## Portfolio Note

Document everything you build. Record what commands you ran, what each step does, and what you learned. This lab is a direct answer to the interview question: *"Tell me about your Active Directory experience."*

---

## Resources

- [Microsoft Docs — Active Directory Domain Services](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview)
- [Microsoft Docs — Group Policy Overview](https://learn.microsoft.com/en-us/windows-server/networking/technologies/dhcp/dhcp-top)
- [Azure Free Account](https://azure.microsoft.com/free)
- [Windows Server 2025 Evaluation](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2025)
- [VirtualBox](https://www.virtualbox.org)

---

*Lab 01 of the Identity & Access Management series.*
