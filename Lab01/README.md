# Lab 01: Hybrid Identity with Microsoft Entra Cloud Sync

## Goal

Build an on-prem Active Directory domain and sync a scoped set of users to Microsoft Entra ID with Entra Cloud Sync, then prove that AD stays the source of authority for joiner, mover and leaver changes.

## Environment

| Item | Details |
| --- | --- |
| Domain controller | `DC02` - Windows Server 2022 (Desktop Experience), VMware Workstation |
| Domain | `jjlab.local` (NetBIOS `JJLAB`) |
| Network | VMware NAT (VMnet8), static IP `192.168.40.10/24`, gateway `192.168.40.2` |
| Cloud tenant | `jjiamlaboutlook.onmicrosoft.com` |
| Sync tool | Microsoft Entra Cloud Sync agent with password hash sync (PHS) |

## Architecture

```
Active Directory (jjlab.local)
  └── OU=Cloud-Synced  ──►  Cloud Sync agent on DC02  ──(outbound HTTPS 443 only)──►  Microsoft Entra ID
  └── OU=Service-Accounts  ✗  (out of scope, never syncs)
```

## Key concepts

| Concept | One-line meaning |
| --- | --- |
| Source of authority | The "master copy" of an identity. For synced users it is AD, so changes must be made on-prem |
| Hybrid identity | One user, one account, existing in both AD and Entra ID |
| Password hash sync (PHS) | A scrambled hash of the AD password hash is synced, so Entra checks passwords itself and keeps working if on-prem is down |
| Pass-through auth / Federation | Alternatives where on-prem checks the password, so cloud sign-in depends on on-prem being up |
| Scoping filter | Limits sync to selected OUs so admins and service accounts stay on-prem |
| gMSA | Service account whose long, random password is generated and rotated by AD. No human knows it |
| Provision on demand | Syncs one user immediately and shows every step. Main sync troubleshooting tool |

## Steps

### 1. Build the domain controller

Built a new Windows Server 2022 VM (`DC02`) on VMware NAT, set a static IP, and confirmed outbound HTTPS to Microsoft before installing anything.

<img width="912" height="918" alt="Screenshot 2026-11-22 192650" src="https://github.com/user-attachments/assets/60521130-bd69-466e-b402-d31910badd35" />

<img width="1063" height="337" alt="Screenshot 2026-11-22 200617" src="https://github.com/user-attachments/assets/35821d67-bf61-4852-89e8-95899655efd9" />

### 2. Create the forest

Installed AD DS and promoted DC02 to a new forest, `jjlab.local`, with integrated DNS. Added DNS forwarders so the DC can resolve internet names.

```powershell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName "jjlab.local" -DomainNetbiosName "JJLAB" -InstallDns `
    -SafeModeAdministratorPassword (Read-Host -AsSecureString "Enter DSRM password")
Add-DnsServerForwarder -IPAddress 1.1.1.1, 8.8.8.8
```

<img width="1140" height="623" alt="Screenshot 2026-11-22 201547" src="https://github.com/user-attachments/assets/474a17c2-852a-40e4-9841-dbe5622eaf97" />

<img width="1212" height="452" alt="Screenshot 2026-11-22 201632" src="https://github.com/user-attachments/assets/f5fd8b7f-3a10-42a1-ae2d-e07ede3d760a" />

### 3. Create scoped OUs and users

Created two OUs: `Cloud-Synced` (to sync) and `Service-Accounts` (must never sync). Added three users to Cloud-Synced, testing one user first, and one service account (`svc-backup`) to Service-Accounts. Users were tagged `Company = JJ IAM Lab` so they match the same scoping rules as my cloud test users.

<img width="1015" height="367" alt="Screenshot 2026-11-22 202210" src="https://github.com/user-attachments/assets/73543c61-829a-4338-84c3-bbd7db9e8693" />

<img width="976" height="595" alt="Screenshot 2026-11-22 202301" src="https://github.com/user-attachments/assets/143d07e0-58fd-4634-8636-e64954d57fc9" />
### 4. Install the Cloud Sync agent

Installed the provisioning agent on DC02. Setup created a gMSA for the agent and registered it with the tenant. The agent only makes outbound HTTPS calls, so no inbound firewall ports were opened.

<img width="990" height="345" alt="Screenshot 2026-11-22 205131" src="https://github.com/user-attachments/assets/a4905a26-13f5-42d2-8ded-f525652f35ae" />

<img width="1531" height="581" alt="Screenshot 2026-11-22 205229" src="https://github.com/user-attachments/assets/aaa19ede-fc9f-4ee0-b69b-222add98d3c0" />

### 5. Configure sync

- Created an **AD to Microsoft Entra ID sync** configuration for `jjlab.local` with password hash sync on.
- Scoped it to `OU=Cloud-Synced,DC=jjlab,DC=local`.
- Turned on **accidental deletion prevention** with a low threshold, so a mistaken OU delete can't wipe cloud accounts.
- Tested with **Provision on demand** for one user before enabling the configuration.

<img width="1517" height="612" alt="Screenshot 2026-11-22 210513" src="https://github.com/user-attachments/assets/f34c172c-b1c2-438b-8fee-5bc354322e44" />

<img width="1582" height="583" alt="Screenshot 2026-11-22 210916" src="https://github.com/user-attachments/assets/8440c171-78f1-433a-ad96-b06954b8850b" />

<img width="1550" height="578" alt="Screenshot 2026-11-22 211105" src="https://github.com/user-attachments/assets/70e84caf-7eed-4a7a-9ddc-1a503f422ee9" />

<img width="1148" height="598" alt="Screenshot 2026-11-22 211859" src="https://github.com/user-attachments/assets/58e5642b-be2e-480e-8cd8-92c8db3e39aa" />

## Proof it works

| Test | Expected | Result |
| --- | --- | --- |
| Scoping: search Entra for `svc-backup` | Not found | Pass |
| Source of authority: edit a synced user's job title in Entra | Field locked | Pass |
| Password hash sync: sign in to My Apps as Gia with her AD password | Sign-in succeeds | Pass |
| Mover: change Hal's title in AD | Entra updates automatically | Pass (about [X] minutes on first cycle) |
| Leaver: disable Ivy in AD | Entra shows Account enabled = No | Pass |
| Leaver: revoke Ivy's sessions | Existing sign-ins cancelled | Pass |

<img width="1523" height="542" alt="Screenshot 2026-11-22 211955" src="https://github.com/user-attachments/assets/bdcaa5b9-de14-4558-8661-f240eea48b59" />

<img width="1605" height="661" alt="Screenshot 2026-11-22 212220" src="https://github.com/user-attachments/assets/2f255800-b639-439b-a92e-becd9f8ec508" />

<img width="1717" height="612" alt="Screenshot 2026-11-22 212657" src="https://github.com/user-attachments/assets/879c61b0-1207-4c2e-baf5-eca1ca90ee67" />

<img width="1432" height="493" alt="Screenshot 2026-11-22 212912" src="https://github.com/user-attachments/assets/b9000d51-2140-4fcc-8fde-9e636146eda4" />

<img width="1450" height="642" alt="Screenshot 2026-11-22 214135" src="https://github.com/user-attachments/assets/a9f0e3a3-9b7e-4703-beff-5ecf80e99524" />

<img width="1582" height="463" alt="Screenshot 2026-11-22 214259" src="https://github.com/user-attachments/assets/0536da32-51ad-4a41-bf55-8cd91c0f323b" />

<img width="1347" height="608" alt="Screenshot 2026-11-22 214535" src="https://github.com/user-attachments/assets/e6348750-898b-4bb8-89bc-358bdc7a5d28" />

### Why revoke sessions?

Disabling an account stops **new** sign-ins, but apps the user is already signed in to can keep working until the access token expires (up to about an hour). A complete leaver process also revokes sessions:

```powershell
Connect-MgGraph -Scopes "User.RevokeSessions.All"
Revoke-MgUserSignInSession -UserId "ivy.chen@jjiamlaboutlook.onmicrosoft.com"
Disconnect-MgGraph
```

<img width="1036" height="220" alt="Screenshot 2026-11-22 214908" src="https://github.com/user-attachments/assets/e3b6063c-e512-4cea-b947-7234d498af64" />

## Problems I hit and how I fixed them

| Problem | Cause | Fix |
| --- | --- | --- |
| Locked out of my old DC (DC01) | Forgot the admin password; recovery boot from ISO failed | Built a fresh DC (DC02) designed for this lab, and stored all passwords (including DSRM) in a password manager |
| Setup error: "Windows cannot find the Microsoft Software License Terms" | VMware Easy Install added a floppy with an unattended answer file | Removed the floppy drive from the VM. Next time: choose "I will install the operating system later" |
| No internet from the VM | Static IP was on the wrong subnet. VMnet8 was actually `192.168.40.0/24` | Checked VMnet8 in the Virtual Network Editor and used its real subnet and gateway (`.2`) |
| VMware NAT unreliable | VPN clients on the host (GlobalProtect, OpenVPN) interfere with VMware NAT | Disconnected the VPNs while labbing |
| Test results didn't make sense | Ran a command on the host PC instead of the VM | Confirmed the machine with `hostname` and the OS name before trusting output |
| Only one user synced at first | That user was synced manually with Provision on demand; the first scheduled cycle on a new configuration was slow | Checked the provisioning logs, confirmed the agent was healthy, and used Provision on demand to continue |

## UPN note

`jjlab.local` is not a routable domain, so Entra can't verify it. Synced users were given my tenant's `onmicrosoft.com` suffix. In production, I would add a UPN suffix in AD that matches a verified domain (for example `@company.com`) so users have the same sign-in name on-prem and in the cloud.

## What I'd do differently in production

- Install the agent on **member servers**, not a domain controller, and run **2-3 agents** for high availability.
- Use an account with only the **Hybrid Identity Administrator** role for setup instead of Global Admin.
- Add a **verified UPN suffix** so on-prem and cloud sign-in names match.
- Keep all privileged and break-glass accounts **cloud-only** and out of sync scope.
- Build session revocation into the automated leaver process.
- Never force-skip "change password at next logon" for real users. I skipped it here only to test password hash sync.
