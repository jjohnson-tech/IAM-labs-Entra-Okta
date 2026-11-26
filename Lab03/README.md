# Lab 03: Authentication Methods, Passkeys, TAP and Self-Service Password Reset

**Platform:** Microsoft Entra ID | **Concepts:** authentication, MFA, phishing-resistant MFA, passwordless onboarding, self-service password reset | **Status:** Done

## Summary

I configured how users prove who they are in Microsoft Entra ID, from the method "menu" to a full passwordless joiner flow:

1. **Authentication methods policy.** Enabled strong methods (Microsoft Authenticator with number matching, passkeys, Temporary Access Pass) and disabled weak ones (SMS and voice).
2. **Passwordless onboarding.** A new user signed in for the first time with a one-hour, single-use **Temporary Access Pass (TAP)**, registered a **passkey**, and from then on signed in with **no password at all**.
3. **Self-service password reset (SSPR).** Finance users can reset their own password after proving their identity with **two** methods, with registration enforced and every reset logged.

## Business problem

| Risk | What it looks like | Control in this lab |
|---|---|---|
| Phishable MFA | Users type SMS codes into fake login pages; attackers take over phone numbers by SIM swap | SMS and voice disabled; passkeys for IT |
| Insecure onboarding | Temp passwords sent by email or read out over the phone | Temporary Access Pass straight into a passkey |
| Password reset ticket load | Help desk time spent on routine resets | SSPR for a pilot group |
| Weak self-service proof | One compromised personal email is enough to reset a work password | SSPR requires 2 methods |

## Lab environment

- **Tenant:** standalone Entra ID project tenant with an Entra ID P2 trial
- **Admin:** cloud-only `labadmin` (Global Admin)
- **Groups (from Lab 02):** `SG-Lab-IT` (Ava, Eve) and `SG-Lab-Finance` (Ben, Cara), both dynamic, based on department
- **Test users:** Eve Park (IT, a "new hire" who had never signed in) and Ben Cruz (Finance)

### Design decision: security defaults left on

The original plan was to turn off security defaults at the start of this lab. I left them **on**, because everything in this lab works with them enabled. Turning them off now would leave the tenant with no MFA requirement until Conditional Access is built in Lab 04. **Never leave a gap in protection.** Security defaults will be switched off and replaced in the same session in Lab 04.

---

## Part A: The authentication methods policy

**Goal:** decide which sign-in methods are allowed, and for whom. This policy is the single "menu" for both sign-in and password reset.

| Method | Setting | Target | Why |
|---|---|---|---|
| Microsoft Authenticator | Enabled, number matching on | All users | Strong, widely usable second factor |
| Passkey (FIDO2) | Enabled (default passkey profile) | `SG-Lab-IT` | Phishing-resistant; pilot with IT first |
| Temporary Access Pass | Enabled, 1-hour lifetime, one-time use | All users | Secure onboarding and recovery |
| SMS / Voice call | Disabled | — | Vulnerable to SIM swap and phishing relay |

<img width="1137" height="485" alt="Screenshot 2026-11-26 102635" src="https://github.com/user-attachments/assets/eacf0470-7ce0-483b-b5e4-9de938428292" />

<img width="1140" height="575" alt="Screenshot 2026-11-26 102913" src="https://github.com/user-attachments/assets/c17b7826-3daa-487e-a258-95c156cbbadc" />

<img width="1136" height="641" alt="Screenshot 2026-11-26 103309" src="https://github.com/user-attachments/assets/4c95f171-3cd1-4740-8549-665e09100598" />

<img width="1142" height="572" alt="Screenshot 2026-11-26 103352" src="https://github.com/user-attachments/assets/3478d50e-06ce-4509-a054-719a46084c7b" />

<img width="1157" height="597" alt="Screenshot 2026-11-26 103405" src="https://github.com/user-attachments/assets/465b78b6-6193-4066-bbbc-c312f0d6eba2" />


### Why SMS is weak

| Method | SIM swap | Fake login page (phishing relay) |
|---|---|---|
| SMS code | ❌ The code goes to the attacker's SIM | ❌ The user types it into the fake page, and the attacker relays it |
| Authenticator + number matching | ✅ Tied to the device, not the phone number | ⚠️ Harder, but a rushed user can still approve it |
| **Passkey** | ✅ Tied to the device | ✅ **Only answers the real site.** A fake page gets nothing |

**Phishing-resistant** means the passkey checks the website's real address before it responds, so it never answers a look-alike page.

### Passkey profiles

Microsoft moved passkey settings into **passkey profiles** (bundles of passkey rules, up to 10 per tenant). My existing settings were moved into the **Default passkey profile**, targeted at `SG-Lab-IT`. I checked that key restrictions don't block Microsoft Authenticator, whose passkeys are **device-bound**.

---

## Part B: Passwordless onboarding with a Temporary Access Pass

**Goal:** onboard a new hire without ever giving them a password.

### Steps
1. As `labadmin`, created a **Temporary Access Pass** for Eve (1 hour, one-time use).
2. In a private window, Eve signed in for the first time **with the TAP** instead of a password.
3. At **mysignins.microsoft.com/security-info**, Eve registered **Microsoft Authenticator**, then a **passkey in Authenticator**.
4. Eve signed out and back in with the **passkey**. No password was used.

<img width="577" height="705" alt="Screenshot 2026-11-26 103739" src="https://github.com/user-attachments/assets/b9b823a1-6eed-4601-b47d-fa0b14119ba6" />

<img width="1242" height="657" alt="Screenshot 2026-11-26 104252" src="https://github.com/user-attachments/assets/bbf71003-75a3-4d64-9134-48f9ac4ea678" />

<img width="1427" height="623" alt="Screenshot 2026-11-26 105349" src="https://github.com/user-attachments/assets/6dea897e-f308-4853-a223-e07d3a3f396c" />

<img width="1115" height="737" alt="Screenshot 2026-11-26 105455" src="https://github.com/user-attachments/assets/e2c18bde-11bb-402c-b40f-cfd356833200" />

### Why the TAP is short-lived and single-use

If a TAP lasted a week and could be reused, anyone who saw it (in an email, a chat message or ticket notes) could sign in as the user and **register their own MFA method**. That creates a backdoor that keeps working after the TAP expires.
- **1 hour:** a leaked code quickly becomes useless.
- **One-time use:** once the real user signs in, nobody else can use it.

**Operational rule:** never paste a TAP or temp password into ticket notes. Record "TAP issued to user by phone" instead.

---

## Part C: Self-service password reset (SSPR)

**Goal:** let Finance users reset their own password, with proof strong enough to replace a help desk identity check.

### Configuration

| Setting | Location | Value |
|---|---|---|
| SSPR enabled | Password reset > Properties | **Selected:** `SG-Lab-Finance` |
| Methods required to reset | Password reset > Authentication methods | **2** |
| Allowed methods | **Authentication methods policy** | Microsoft Authenticator (all users) + **Email OTP** (`SG-Lab-Finance`) |
| Require registration at sign-in | Password reset > Registration | Yes, re-confirm every **180 days** |
| Notifications | Password reset > Notifications | Notify users on reset; notify all admins when other admins reset |

<img width="1152" height="645" alt="Screenshot 2026-11-26 111843" src="https://github.com/user-attachments/assets/323964d2-a63d-4603-acdf-e9fd7ee574be" />

<img width="1218" height="685" alt="Screenshot 2026-11-26 114547" src="https://github.com/user-attachments/assets/b535e35e-542d-494d-9563-a909f55f845e" />

<img width="1157" height="618" alt="Screenshot 2026-11-26 114801" src="https://github.com/user-attachments/assets/b90ea890-7253-4785-8e95-3c5ba6848030" />

### Test
1. Ben signed in and registered an email address as his second method.
2. At **aka.ms/sspr**, Ben proved his identity with **Authenticator + email** and set a new password himself.
3. The reset appears in the audit logs under **Self-service Password Management**.

<img width="816" height="691" alt="Screenshot 2026-11-26 121247" src="https://github.com/user-attachments/assets/5e4e1d62-3406-4f29-93c9-aa250d6b84d8" />

<img width="1251" height="542" alt="Screenshot 2026-11-26 121657" src="https://github.com/user-attachments/assets/c40bf580-e260-41e6-acad-398d68977594" />

<img width="1121" height="372" alt="Screenshot 2026-11-26 121824" src="https://github.com/user-attachments/assets/0b1c8030-eb98-454d-9350-4da3e2861288" />

### Why two methods

When a help desk agent resets a password, a **person** is in the loop and can verify the caller. In SSPR, **nobody checks**: the methods are the only barrier. With one method, an attacker who compromised Ben's personal email could take over his work account. With two, they'd also need his phone.

**Note:** passkeys can't be used in the SSPR flow, which the passkey policy page says directly. That's one reason Authenticator and email are the SSPR methods here.

---

## Proof

### Sign-in logs
Eve's passkey sign-in shows **Passkey** under **Authentication details**, with no password step. Her first sign-in shows **Temporary Access Pass**.

<img width="1097" height="761" alt="Screenshot 2026-11-26 133814" src="https://github.com/user-attachments/assets/44b3a2a9-06ea-4ce5-8820-b4969996c9ec" />

<img width="827" height="778" alt="Screenshot 2026-11-26 134545" src="https://github.com/user-attachments/assets/910f3624-e0c1-413b-b64a-8e08fd24f7ac" />

A later entry showed **"Previously satisfied"** (MFA requirement satisfied by a claim in the token). That sign-in **reused an existing session** instead of proving identity again. This is why revoking sessions is part of a proper leaver process.

### Authentication methods activity

<img width="995" height="742" alt="Screenshot 2026-11-26 134726" src="https://github.com/user-attachments/assets/ecef4881-f05d-4444-a1da-3b1d4641806f" />

| Method | Uses (last 7 days) | What it shows |
|---|---|---|
| Passkey (device-bound) | ~8 | Eve's passwordless sign-ins |
| TAP | 1 | Single onboarding sign-in, as designed |
| SMS / Voice / Mobile | 0 | The policy blocking weak methods works |

**Finding for Lab 04:** the same report showed **15 single-factor (password-only) sign-ins** in the last 7 days. Security defaults only asks for MFA when Microsoft decides it's needed, so password-only sign-ins still get through. This is the **"before" picture**. Lab 04 replaces security defaults with Conditional Access policies that require MFA on every sign-in.

---

## Problems I hit

| # | Symptom | Root cause | Fix | Lesson |
|---|---|---|---|---|
| 1 | The passkey settings page didn't match the guide | Microsoft moved passkey settings into **passkey profiles** | Used the Default passkey profile, targeted at `SG-Lab-IT`, and checked key restrictions | Work from the current product, not old tutorials |
| 2 | No "allowed methods" option on the SSPR Authentication methods page | Microsoft retired legacy SSPR method settings on Sept 30, 2025; methods now come from the unified Authentication methods policy | Set the method **count** in Password reset, and enabled **Email OTP** in the Authentication methods policy | Know where a setting lives after a platform migration |
| 3 | Couldn't find the SSPR Registration and Notifications settings | They're separate pages in the **Password reset** left menu, not on the Authentication methods page | Opened them from the Password reset menu | — |
| 4 | Eve's sign-in log showed "Previously satisfied" instead of Passkey | That entry reused an existing session token; the passkey sign-in was an earlier entry | Filtered to interactive sign-ins, last 24 hours, and found the right time | Read the log entry, not just the user name |
| 5 | Ben's reset wasn't in the Activity report yet | The Activity report lags by hours | Used the audit log as proof instead | Know which reports are near real time and which aren't |

---

## Security takeaways

- **Not all MFA is equal.** SMS can be intercepted; passkeys are phishing-resistant.
- **Onboarding is an attack surface.** A TAP into a passkey removes the "temp password in an email" risk.
- **Short-lived, single-use credentials** limit the damage if they leak.
- **Self-service needs stronger proof** than help desk resets, because no human is checking.
- **Pilot with a group first** (IT for passkeys, Finance for SSPR) before rolling out to everyone.
- **Never leave a gap in protection** when changing baseline security settings.
