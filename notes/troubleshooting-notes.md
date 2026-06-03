# Troubleshooting Notes

| Issue | Likely Cause | Fix |
|---|---|---|
| Cannot RDP into VM | RDP not allowed in NSG or VM firewall | Confirm TCP 3389 is allowed from trusted source IP |
| Copy/paste does not work in RDP | Clipboard redirection disabled | Enable Clipboard under Local Resources in the RDP client |
| ADUC not visible | AD DS management tools not installed | Install AD DS with `-IncludeManagementTools` |
| Group Policy Management missing | GPMC not installed | Run `Install-WindowsFeature -Name GPMC` |
| Domain promotion fails | DNS or prerequisite issue | Review prerequisite check results and event logs |
| PowerShell AD commands fail | Active Directory module not loaded or not installed | Run commands on the domain controller or install RSAT tools |
| User creation script prompts unexpectedly | Password variable was not defined first | Run the full script block together |
| GPO does not apply | Object is not in linked OU or policy has not refreshed | Move object to correct OU and run `gpupdate /force` |
| Password policy does not behave as expected | Domain password policy behavior differs from OU-linked policy expectations | Review Default Domain Policy and fine-grained password policy concepts |

---
