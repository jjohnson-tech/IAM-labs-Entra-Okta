# Lab 02: RBAC, Dynamic Groups and Least-Privilege Admin Roles

**Platform:** Microsoft Entra ID + Azure | **Concepts:** RBAC, least privilege, attribute-based access, scoped administration, Azure RBAC | **Status:** Done

## Summary

I built role-based access control at three levels in Microsoft Entra ID and Azure:

1. **Least-privilege admin roles.** The helpdesk user got Helpdesk Administrator instead of Global Admin, and I proved what she could and couldn't do.
2. **Attribute-driven access.** Dynamic groups put users in the right group based on their department. I proved that a department change (a "mover") adds **and removes** access automatically.
3. **Scoped administration.** An administrative unit fenced a local Password Administrator to one department, and an Azure Reader role on one resource group was granted through a dynamic group.

**The chain I built:** Department attribute → dynamic group → Azure role → resource access

## Business problem

| Risk | What it looks like | Control in this lab |
|---|---|---|
| Over-privileged admins | Help desk staff given Global Admin "to make things easier" | Helpdesk Administrator role |
| Access creep | Movers keep old department access after changing jobs | Dynamic groups based on the department attribute |
| Wide blast radius | One phished admin can reset passwords for every user | Administrative unit scoping |
| Identity roles mixed up with resource roles | Assuming Entra admins can manage cloud resources | Separate Azure RBAC assignment on one resource group |

## Lab environment

- **Tenant:** standalone Entra ID project tenant with an Entra ID P2 trial
- **Admin accounts:** cloud-only `labadmin` (Global Admin); the subscription owner account for Azure
- **Test users** (cloud-only, tagged `companyName = JJ IAM Lab`):

| User | Department | Role in this lab |
|---|---|---|
| Ava Lee | IT | Helpdesk Administrator |
| Ben Cruz | Finance | Regular user, inside AU, Azure Reader through his group |
| Cara Diaz | Finance | Regular user, inside AU |
| Dan Moss | HR | Mover test; Password Administrator scoped to AU |
| Eve Park | IT | User Administrator (the "higher" admin) |
| Finn Ray | Sales | Regular user, outside AU |

---

## Part A: Least-privilege Entra admin roles

**Goal:** give Ava only the access a help desk technician needs, then prove where her limits are.

### Steps
1. Reviewed the **Helpdesk Administrator** role's permissions in **Roles & admins**.
2. Assigned Ava **Helpdesk Administrator** as **Active + Permanent**. With P2, PIM defaults to *Eligible*, which would have made the tests fail for the wrong reason.
3. Assigned Eve **User Administrator** (Active + Permanent).
4. Signed in as Ava in a private window and tested three actions.

<img width="1131" height="656" alt="Screenshot 2026-11-23 191422" src="https://github.com/user-attachments/assets/e7bb6e49-68c0-4fd2-8e45-a4416fdad396" />

<img width="1166" height="412" alt="image" src="https://github.com/user-attachments/assets/b8db4810-1da4-4899-819c-837634cc6b3b" />


<img width="1146" height="526" alt="Screenshot 2026-11-23 192141" src="https://github.com/user-attachments/assets/b90566a0-eff1-4776-9dfa-b112e6e1343a" />

### Results

| Test (as Ava) | Expected | Result |
|---|---|---|
| Reset Ben's password (regular user) | Allowed | ✅ Allowed |
| Reset Eve's password (User Administrator) | Blocked | ✅ Blocked |
| Create a Conditional Access policy | Blocked | ✅ Blocked |

<img width="1130" height="268" alt="Screenshot 2026-11-23 194136" src="https://github.com/user-attachments/assets/2dbc8391-48b1-4e32-a2a0-a2feef997e03" />

<img width="1128" height="387" alt="Screenshot 2026-11-23 194817" src="https://github.com/user-attachments/assets/0faab148-023e-4774-9efb-0f50194b35ce" />

<img width="1095" height="587" alt="Screenshot 2026-11-23 194917" src="https://github.com/user-attachments/assets/ec824e0f-8acd-498a-a494-c83a4877e60b" />

### Role comparison

| Role | Can do | Can't do |
|---|---|---|
| Helpdesk Administrator | Reset passwords for regular users and some low-level admins; sign users out of their sessions | Reset passwords for higher admins; create or delete users; manage groups or policies |
| User Administrator | Everything Helpdesk can, plus create/delete users, edit user details, manage groups and licenses, and reset passwords for more admin roles (including Helpdesk Admins) | Reset Global Admin passwords; manage Conditional Access |
| Global Administrator | Everything | Nothing is off-limits, which is why it should be rare |

### Why the Eve reset is blocked

If a Helpdesk Admin could reset a User Admin's password, she could sign in as that person and take over their higher powers. This is **privilege escalation**. Entra blocks it with one rule: **you can't reset the password of someone with more power than you.**

---

## Part B: Dynamic groups and the mover test

**Goal:** make group membership follow the user's department automatically, so access is granted **and removed** without a ticket.

### Steps
1. Created the security group `SG-Lab-Finance` with membership type **Dynamic User** and this rule:
   ```
   (user.department -eq "Finance") -and (user.companyName -eq "JJ IAM Lab")
   ```
2. Created `SG-Lab-IT` the same way, with `department -eq "IT"`.
3. Confirmed that Ben and Cara joined `SG-Lab-Finance`, and Ava and Eve joined `SG-Lab-IT`.

<img width="1143" height="562" alt="Screenshot 2026-11-23 195604" src="https://github.com/user-attachments/assets/701da649-98d0-4480-ba82-f810302aecf8" />

<img width="1127" height="517" alt="Screenshot 2026-11-23 200947" src="https://github.com/user-attachments/assets/75896110-abed-4a66-8780-76c9633bb3ab" />

<img width="1150" height="586" alt="Screenshot 2026-11-23 201444" src="https://github.com/user-attachments/assets/ad9cbfd8-13ad-4d21-b51f-d816413b5125" />

### Why the rule has two conditions

The tenant already had other Finance and IT users from an earlier project. A rule on `department` alone would have pulled them in and changed real access. Adding `companyName -eq "JJ IAM Lab"` makes the rule match **only** the 6 lab users. **Scope a rule before you build it.**

### Mover test

| Step | Action | Result |
|---|---|---|
| 1 | Changed Dan's department from HR to Finance | Dan joined `SG-Lab-Finance` in about ** 5 minutes** |
| 2 | Changed Dan's department back to HR | Dan left `SG-Lab-Finance` automatically |
| 3 | Checked the audit logs | "Add member to group" and "Remove member from group" entries, made by the system, not an admin |

<img width="1137" height="717" alt="Screenshot 2026-11-23 205200" src="https://github.com/user-attachments/assets/313ddc17-c907-4ae4-83c5-fb520c79855c" />

<img width="1172" height="793" alt="Screenshot 2026-11-23 205359" src="https://github.com/user-attachments/assets/4dc6ce84-31f4-4096-8e4b-e3fb9814ef24" />

<img width="1165" height="330" alt="Screenshot 2026-11-23 205758" src="https://github.com/user-attachments/assets/22ace0fb-f623-4935-8825-c4c194222ae5" />

<img width="1161" height="367" alt="Screenshot 2026-11-23 205823" src="https://github.com/user-attachments/assets/2ab48112-580e-4224-ad82-fc4476b49230" />


### What this proves

**Movers are the riskiest part of the joiner-mover-leaver cycle.** With hand-assigned groups, people gain new access but rarely lose old access. This is called **access creep**. It causes two problems:
- **A bigger target:** one phished account opens several departments.
- **Separation of duties failures:** for example, one person who can both change payroll (HR) and approve payments (Finance).

### Known weakness

A dynamic group is only as accurate as the attribute behind it. A typo like `Finanace` fails **silently**: there's no error, and the user just doesn't get access. A wrong department value gives the *wrong* access. The real controls are pick-lists in the HR system, data validation before sync, and regular access reviews.

---

## Part C: Administrative units (scoped admin)

**Goal:** let Dan reset passwords for Finance users only, not the whole tenant.

### Steps
1. Created the administrative unit `AU-Lab-Finance` and added Ben and Cara.
2. Inside the AU, assigned Dan **Password Administrator** (Active + Permanent). I confirmed the scope showed `AU-Lab-Finance`, not "Directory."
3. Signed in as Dan and tested.

<img width="1148" height="472" alt="Screenshot 2026-11-23 210313" src="https://github.com/user-attachments/assets/9c176116-f76a-4228-b0f0-e0e85e74596b" />

<img width="1166" height="412" alt="image" src="https://github.com/user-attachments/assets/5c19081f-52ad-4c11-b297-341d956f88c2" />


### Results

| Test (as Dan) | Expected | Result |
|---|---|---|
| Reset Ben's password (inside the AU) | Allowed | ✅ Allowed |
| Reset Finn's password (outside the AU) | Blocked | ✅ Blocked |

<img width="1192" height="245" alt="Screenshot 2026-11-24 195625" src="https://github.com/user-attachments/assets/0eba6f4b-0f24-4bd0-a5c5-bf4146888211" />

<img width="1147" height="382" alt="Screenshot 2026-11-24 195643" src="https://github.com/user-attachments/assets/97884246-e051-4b9a-aabe-2326ccc620c7" />

**Test design:** I tested against Finn (a regular user) instead of Ava (an admin). A failed reset on Ava could have two causes: the AU fence, or the "can't reset a higher admin" rule. With Finn, the only possible cause is the fence. **Test one thing at a time.**

### Why scoping matters

A tenant-wide Password Administrator can reset the password of **every regular user**, including executives and payroll staff. A phished account with that role could take over a CFO's mailbox and send fake wire requests (**business email compromise**) without ever touching an admin account. The AU limits the **blast radius** to two accounts.

---

## Part D: Azure RBAC

**Goal:** show the difference between Entra roles (which manage identities) and Azure roles (which manage resources), and connect Azure access to a dynamic group.

| | Entra roles | Azure roles |
|---|---|---|
| Control | Identities: users, groups, passwords | Cloud resources: VMs, storage, networks |
| Examples | Helpdesk Admin, User Admin | Owner, Contributor, Reader |
| Assigned in | Entra admin center | Azure portal, under **Access control (IAM)** |

### Steps
1. Created the resource group `rg-iam-lab` as the subscription owner.
2. Assigned **Reader** on `rg-iam-lab` **only** to the group `SG-Lab-Finance`, as **Active + Permanent**.
3. Signed in as Ben and tested.

<img width="833" height="392" alt="Screenshot 2026-11-24 191759" src="https://github.com/user-attachments/assets/e1b77e80-7a7e-45b5-af6c-8cb5ca2e0ec9" />

### Results

| Test (as Ben) | Expected | Result |
|---|---|---|
| See `rg-iam-lab` under **Resource groups** | Visible | ✅ Visible 
| Add the tag `owner = ben` | Blocked (Reader is view-only) | ✅ Authorization error |


<img width="857" height="545" alt="Screenshot 2026-11-24 193431" src="https://github.com/user-attachments/assets/46187499-4792-4158-b637-acb053d8f2bd" />

### The four parts of an Azure role assignment

| Part | In this lab |
|---|---|
| **Who** (security principal) | `SG-Lab-Finance` |
| **What** (role definition) | Reader |
| **Where** (scope) | Resource group `rg-iam-lab` |
| **Assignment** | Links all three together |

**Dan can't see `rg-iam-lab`**, for two reasons: his Password Administrator role is an Entra role with no Azure permissions, and he isn't in `SG-Lab-Finance`. If HR moved him to Finance, he would get Reader automatically.

---

## Problems I hit

| # | Symptom | Root cause | Fix | Lesson |
|---|---|---|---|---|
| 1 | Department rules would match users outside the lab | The tenant already had Finance and IT users from Project 1 | Tagged lab users with `companyName = JJ IAM Lab` and added it to every rule | Scope a rule before you build it |
| 2 | Couldn't save the new group `SG-Dept-Finance` | A group with that name already existed from Project 1, and automation depended on it | Left the existing group alone and named the lab groups `SG-Lab-Finance` and `SG-Lab-IT` | Never repurpose a group other processes depend on |
| 3 | Ben saw "no subscriptions" and couldn't see `rg-iam-lab` | With P2, PIM made the Azure Reader assignment **Eligible**, so it wasn't active | Removed it and reassigned it as **Active + Permanent** | PIM covers **both** Entra roles and Azure resource roles |
| 4 | Couldn't find the **Check access** button in the portal | The portal layout differs from the documentation | Confirmed access from the **Role assignments** tab instead | Know more than one way to verify access |

---

## Security takeaways

- Choose the **smallest role** that covers the job. Most help desk work needs Helpdesk Administrator, not Global Admin.
- Power only flows **downward**. A lower admin can never reset the password of a higher one.
- **Attribute-driven groups** stop access creep, but they depend on clean HR data.
- **Administrative units** limit the blast radius of a compromised admin.
- **Entra roles and Azure roles are separate systems.** Global Admin doesn't automatically grant access to Azure resources.
- **Denials are the best evidence.** A success shows that someone *can* do something. A denial proves the limits work.

