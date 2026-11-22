Lab 00: Environment Setup (Entra ID + Okta)
Goal

Build a clean, repeatable lab base for the rest of the IAM series: a dedicated lab admin, two break-glass emergency accounts, and the same six test users in both Microsoft Entra ID and Okta.

Environment
Platform	Details
Microsoft Entra ID	Project tenant (jjiamlaboutlook.onmicrosoft.com), Entra ID Free (P2 trial saved for later labs)
Okta	Okta Integrator Free Plan org
Tools	PowerShell 7, Microsoft Graph PowerShell SDK
What I built
Item	Purpose
labadmin	Cloud-only work account for day-to-day lab admin (not my personal Microsoft account)
bg-admin1, bg-admin2	Break-glass emergency Global Admins
SG-BreakGlass-Exclude	Group that every Conditional Access policy will exclude
6 test users	Same "cast" in Entra and Okta so every lab is comparable
Test users
User	Department	Job title	Role in later labs
Ava Lee	IT	Helpdesk Technician	Scoped helpdesk admin
Ben Cruz	Finance	Accountant	Regular user
Cara Diaz	Finance	Finance Manager	Approver and reviewer
Dan Moss	HR	HR Specialist	Regular user, mover tests
Eve Park	IT	Cloud Engineer	Privileged user (PIM)
Finn Ray	Sales	Contractor	Temporary access
Steps
1. Lab admin and tenant check

Created labadmin as a cloud-only Global Admin and confirmed the tenant details and license tier.

<img width="1060" height="472" alt="tenant_overview" src="https://github.com/user-attachments/assets/3bb44bc3-e79e-4948-b306-ea200b4d02d0" />


2. Break-glass accounts

Created two break-glass accounts with these design choices:

Cloud-only: an on-prem AD outage or compromise can't break or take over them.
onmicrosoft.com domain: no dependency on custom domains or federation.
Permanent Global Admin (not PIM): still works if PIM or approvals break.
Strong MFA (passkey): Microsoft now enforces MFA for admin portals, and excluding an account from Conditional Access does not bypass that.
Added to SG-BreakGlass-Exclude: so every Conditional Access policy can exclude them in one place.

<img width="1156" height="372" alt="breakglass-roles" src="https://github.com/user-attachments/assets/3661ee67-857d-40bf-9964-4a806b81ccf6" />


<img width="1017" height="467" alt="breakglass-sggroup" src="https://github.com/user-attachments/assets/231d616d-2918-4897-92c0-3fa0cd7a3f81" />


3. Test users created with Microsoft Graph PowerShell

I created the six users with a script (create-test-users.ps1) instead of clicking through the portal.

Delegated auth: I signed in as labadmin, so the script could only do what that account's role and the requested scope allow.
Least-privilege scope: only User.ReadWrite.All.
No secrets in code: the temporary password is entered at runtime with Read-Host.
Force password change at first sign-in: the temp password only works once, and every later sign-in is tied to the real user.
Usage location set to US: required before licenses can be assigned in later labs.

<img width="908" height="161" alt="graph-connect-mg-context" src="https://github.com/user-attachments/assets/5a41c735-193f-4f9a-8fa0-3664b17a7a47" />

I checked the data before changing anything, then created one user first (Ava), verified her, and only then ran the loop for the other five.

<img width="782" height="342" alt="user-list-check" src="https://github.com/user-attachments/assets/23d5f48d-c7e5-4487-81a4-76c8147fe861" />

<img width="862" height="276" alt="createduserscommand_output " src="https://github.com/user-attachments/assets/31e58854-ea64-4b01-bea8-ad100cfbeb9e" />


4. Okta users

Created the same six users in Okta with the same usernames as Entra (first.last@jjiamlaboutlook.onmicrosoft.com). This is deliberate: in the federation lab, Okta matches users to Entra by username.

<img width="1046" height="677" alt="okta_people" src="https://github.com/user-attachments/assets/4ebc31ec-39f2-4905-85bc-1b4d5082a7e9" />


<img width="1030" height="682" alt="ben-okta-profile1" src="https://github.com/user-attachments/assets/83dcd448-6bb4-405e-a526-191bcf359ef9" />

<img width="972" height="482" alt="ben-okta-profile2" src="https://github.com/user-attachments/assets/7185acb3-fde5-412e-ab32-7105957b2bd0" />



Problem I hit and how I fixed it

Problem: My tenant already had users in the Finance and IT departments. My verification showed extra users, and later department-based rules (dynamic groups, Okta group rules) would have pulled in accounts that aren't part of the lab.

Fix: I tagged the six lab users with a unique marker and added it to my checks:

Entra: CompanyName = "JJ IAM Lab" (set with Update-MgUser)
Okta: Organization = "JJ IAM Lab"

Future rules use both conditions, for example:

(user.department -eq "Finance") -and (user.companyName -eq "JJ IAM Lab")

<img width="1172" height="197" alt="users-verified_ps" src="https://github.com/user-attachments/assets/442547c8-9c99-49c5-9cd7-ef7b043308b3" />


<img width="1112" height="465" alt="users_in_entra" src="https://github.com/user-attachments/assets/7ac422c4-aafe-4942-9cc1-6f2599b71851" />


Lesson: scope every change. Before building a rule or policy, make sure you can target exactly the users you mean and no one else.

Results
[x] Lab admin working; personal Microsoft account not used for admin work
[x] Two break-glass accounts with permanent Global Admin and passkeys
[x] SG-BreakGlass-Exclude ready for Conditional Access
[x] Six tagged test users in Entra, created and verified by script
[x] Six matching tagged users in Okta
What I'd do differently in production
Store break-glass credentials split between two people or in a physical safe, with FIDO2 hardware keys instead of phone passkeys.
Set an alert on every break-glass sign-in, since they should never be used on a normal day.
Create users from an HR system (source of truth) instead of a hard-coded list.
Run scheduled automation with app-only certificate auth, and keep delegated auth for one-off admin work.
Key concepts
Concept	One-line meaning
Tenant	An organization's own private instance of Entra ID
Delegated vs app-only	A person signs in (delegated) vs an app signs in with a cert or secret (app-only)
Scope	The permission a token carries; delegated access = scope and the user's role
Break-glass account	Emergency admin that doesn't depend on anything that could break
Staged (Okta)	Account exists but can't sign in until activated
