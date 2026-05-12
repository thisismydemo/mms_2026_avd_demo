# mms_2026_avd_demo — Claude Code Context

## What this repo is

> **Session Demo Repository**
> Midwest Management Summit (MMS) MOA 2026
> Topic: *Azure Virtual Desktop on Azure Local*

---

## ADO project details

- **ADO org:** https://dev.azure.com/hybridcloudsolutions
- **ADO project:** This Is My Demo
- **Area path:** Platform Engineering\Onboarding
- **Work item format:** `AB#<id>` in commit messages and PR descriptions

---

## Standards

This repo follows all HCS platform standards defined in the Platform Engineering repo:

| Standard | Reference |
|---|---|
| Governance | [docs/standards/governance.md](https://dev.azure.com/hybridcloudsolutions/Platform%20Engineering/_git/Platform%20Engineering?path=/docs/standards/governance.md) |
| Scripting (PowerShell 7) | [docs/standards/scripting.md](https://dev.azure.com/hybridcloudsolutions/Platform%20Engineering/_git/Platform%20Engineering?path=/docs/standards/scripting.md) |
| Automation | [docs/standards/automation.md](https://dev.azure.com/hybridcloudsolutions/Platform%20Engineering/_git/Platform%20Engineering?path=/docs/standards/automation.md) |
| Variables and naming | [docs/standards/variables.md](https://dev.azure.com/hybridcloudsolutions/Platform%20Engineering/_git/Platform%20Engineering?path=/docs/standards/variables.md) |
| Documentation | [docs/standards/documentation.md](https://dev.azure.com/hybridcloudsolutions/Platform%20Engineering/_git/Platform%20Engineering?path=/docs/standards/documentation.md) |
| Claude Code | [docs/standards/claude-code.md](https://dev.azure.com/hybridcloudsolutions/Platform%20Engineering/_git/Platform%20Engineering?path=/docs/standards/claude-code.md) |

Key rules:
- All scripts: PowerShell 7+ only. `#Requires -Version 7.0`, `Set-StrictMode -Version Latest`, ` $ErrorActionPreference = 'Stop'`.
- All docs: Markdown only. No Word documents in any repo.
- Commit format: `type(scope): short description` — types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`
- No secrets, tokens, or credentials committed to any file.

---

## Key facts

| Fact | Value |
|---|---|
| Primary language | Bicep / Terraform (HCL) |
| GitHub org | thisismydemo |
| Azure login | kris@hybridsolutions.cloud |
| Key Vault | kv-hcs-vault-01 |

### Environment variables expected

| Variable | Source | Purpose |
|---|---|---|
| `AZURE_SUBSCRIPTION_ID` | kv-hcs-vault-01 via Load-HCSEnvironment.ps1 | Azure CLI subscription context |
| `AZURE_DEVOPS_EXT_PAT` | kv-hcs-vault-01 via Load-HCSEnvironment.ps1 | ADO CLI (`az boards`, `az devops`) |
Load before starting a session:
```powershell
. E:\git\platform\scripts\Load-HCSEnvironment.ps1
```

### Build and test commands

```
az deployment group create --resource-group <rg> --template-file main.bicep --parameters @params.json
```

---

## Repo structure

```
mms_2026_avd_demo/
├── .claude/
    └── settings.json
├── .github/
    └── workflows/
├── assets/
    ├── diagrams/
    ├── recordings/
    ├── screenshots/
    └── README.md
├── bicep/
    ├── modules/
    ├── parameters/
    └── main.bicep
├── docs/
    ├── 01-prerequisites.md
    ├── 02-azure-local-setup.md
    ├── 03-avd-deployment.md
    ├── 03-image-pipeline.md
    └── 04-demo-walkthrough.md
├── presenter/
    ├── day-of-checklist.md
    ├── fallback-plan.md
    ├── run-of-show.md
    └── slide-map.md
├── queries/
    └── log-analytics/
├── scripts/
    ├── 00-load-demo-env.ps1
    ├── 01-prepare-azure-local.ps1
    ├── 02-deploy-avd-infrastructure.ps1
    ├── 03-configure-session-hosts.ps1
    └── 04-validate-deployment.ps1
├── sofs/
    ├── deploy-sofs.ps1
    └── README.md
├── .gitignore
├── CLAUDE.md
├── Demo-Guide-AVD-Azure-Local.md
├── env.sample.json
├── LICENSE
├── README.md
└── STANDARDS.md
```

---

## Claude Code actions

**Run autonomously:**
- Read, search, and grep any file in this repo
- Write and edit files in this repo
- `git add`, `git commit`, `git push`
- `gh issue`, `gh pr`, `gh run` CLI commands
- `az` CLI read operations: `az ... show`, `az ... list`
- `bicep build` and Terraform `init` + `plan` (read-only passes only)

**Always confirm before:**
- Creating or deleting Azure resources
- Any `az` CLI write operation that modifies Azure state
- Running destructive operations
- Making API calls to external services
- `az deployment` commands
- `terraform apply`
- Any write to Azure state

---

## Subagents available in this repo

- `mms_2026_avd_demo-engineer` (model: sonnet) — Expert in `mms_2026_avd_demo`: deep knowledge of this repo's structure, conventions, and development workflow.

User-level agents (available in every repo session): `triage-lookup`, `markdown-prose-editor`, `azurelocal-domain-expert`, `mkdocs-material-doctor`, `turner-module-scaffold-engineer`, `mms-2026-demo-presenter`.

---

## Owner

**Kristopher Turner**
kris@hybridsolutions.cloud
Senior Product Technology Architect, TierPoint | Microsoft MVP (Azure) | MCT
Owner, Hybrid Cloud Solutions LLC — hybridsolutions.cloud
Country Cloud Boy — thisismydemo.cloud