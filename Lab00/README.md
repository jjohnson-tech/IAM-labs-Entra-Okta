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

[SCREENSHOT 01: Tenant overview (Tenant ID blurred). Delete this line and drag the image here]

2. Break-glass accounts

Created two break-glass accounts with these design choices:

Cloud-only: an on-prem AD outage or compromise can't break or take over them.
onmicrosoft.com domain: no dependency on custom domains or federation.
Permanent Global Admin (not PIM): still works if PIM or approvals break.
Strong MFA (passkey): Microsoft now enforces MFA for admin portals, and excluding an account from Conditional Access does not bypass that.
Added to SG-BreakGlass-Exclude: so every Conditional Access policy can exclude them in one place.

[SCREENSHOT 02: Break-glass account Assigned roles. Delete this line and drag the image here]

[SCREENSHOT 03: SG-BreakGlass-Exclude members. Delete this line and drag the image here]

3. Test users created with Microsoft Graph PowerShell

I created the six users with a script (create-test-users.ps1) instead of clicking through the portal.

Delegated auth: I signed in as labadmin, so the script could only do what that account's role and the requested scope allow.
Least-privilege scope: only User.ReadWrite.All.
No secrets in code: the temporary password is entered at runtime with Read-Host.
Force password change at first sign-in: the temp password only works once, and every later sign-in is tied to the real user.
Usage location set to US: required before licenses can be assigned in later labs.

[SCREENSHOT 05: Get-MgContext output (Tenant ID blurred). Delete this line and drag the image here]

I checked the data before changing anything, then created one user first (Ava), verified her, and only then ran the loop for the other five.

[SCREENSHOT 06: User list check in PowerShell. Delete this line and drag the image here]

[SCREENSHOT 07: Create users output. Delete this line and drag the image here]

4. Okta users

Created the same six users in Okta with the same usernames as Entra (first.last@jjiamlaboutlook.onmicrosoft.com). This is deliberate: in the federation lab, Okta matches users to Entra by username.

[SCREENSHOT 09: Okta People list. Delete this line and drag the image here]

[SCREENSHOT 10: Ben's Okta profile. Delete this line and drag the image here]

Problem I hit and how I fixed it

Problem: My tenant already had users in the Finance and IT departments. My verification showed extra users, and later department-based rules (dynamic groups, Okta group rules) would have pulled in accounts that aren't part of the lab.

Fix: I tagged the six lab users with a unique marker and added it to my checks:

Entra: CompanyName = "JJ IAM Lab" (set with Update-MgUser)
Okta: Organization = "JJ IAM Lab"

Future rules use both conditions, for example:

(user.department -eq "Finance") -and (user.companyName -eq "JJ IAM Lab")

[SCREENSHOT 08: Verified lab users only (PowerShell). Delete this line and drag the image here]

[SCREENSHOT 04: Lab users in the Entra portal. Delete this line and drag the image here]

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
