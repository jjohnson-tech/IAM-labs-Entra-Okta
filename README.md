# IAM Labs: Microsoft Entra ID + Okta

Hands-on identity and access management labs built in Microsoft Entra ID and Okta free/trial environments. Each lab maps an IAM concept to a working build, a test that proves it, and screenshots.

**Author:** Javier "Jay" Johnson · [LinkedIn](https://linkedin.com/in/javier-johnson-it)

## Labs

| # | Lab | IAM concept | Platform | Status |
| --- | --- | --- | --- | --- |
| 00 | [Environment setup](lab00/) | Foundations | Entra + Okta | Done |
| 01 | Hybrid sync with Cloud Sync | Directory services | Entra + AD | Planned |
| 02 | Groups and least-privilege roles | RBAC | Entra + Azure | Planned |
| 03 | Auth methods, passkeys, SSPR | Authentication, MFA | Entra | Planned |
| 04 | Conditional Access | Authorization, Zero Trust | Entra | Planned |
| 05 | Privileged Identity Management | Least privilege | Entra | Planned |
| 06 | SAML and OIDC SSO | SSO | Entra | Planned |
| 07 | Access packages and access reviews | Lifecycle, governance | Entra | Planned |
| 08 | Universal Directory and group rules | Directory, RBAC | Okta | Planned |
| 09 | MFA, network zones, auth policies | Authentication, MFA | Okta | Planned |
| 10 | Entra as identity provider for Okta | Federation | Entra + Okta | Planned |
| 11 | Lifecycle automation via API | JML automation | Okta + PowerShell | Planned |
| -- | Capstone: one employee, start to finish | End-to-end JML | All | Planned |

## Each lab folder contains

- `README.md`: goal, steps, proof, problems hit, production notes
- `screenshots/`: evidence, with secrets and tenant IDs redacted
- Scripts (where used), with no credentials stored in code
