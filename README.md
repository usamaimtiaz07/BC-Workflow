# Workflow (Business Central AL)

Per-tenant extension: Custom Approval Workflow, Code Editor, AutoDeploy helper UI.

## GitHub (usamaimtiaz07)

1. On GitHub, create a **new empty repository** (no README):  
   `https://github.com/usamaimtiaz07/Workflow`  
   (Or another name; then change the remote URL below.)

2. In this folder on your PC:

```powershell
cd "C:\Users\TMRC\Documents\AL\Workflow"
git init
git branch -M main
git add .
git commit -m "Initial: Workflow extension + AL-Go CI"
git remote add origin https://github.com/usamaimtiaz07/Workflow.git
git push -u origin main
```

3. After the first push, open **Actions** on the repo. AL-Go **CI/CD** may require:

   - **Secrets** (only if you deploy to a tenant from GitHub): see [AL-Go secrets](https://github.com/microsoft/AL-Go/blob/main/Scenarios/DeployToExistingEnvironment.md).
   - For **build-only** and downloading `.app` artifacts, run the workflow and check the **Artifacts** on successful builds.

4. Optional: run **Update AL-Go system files** workflow if Microsoft updates the template.

## AL-Go CI: “Found AL-Go Projects” empty / Initialization fails

AL-Go only treats a folder as a project if it contains **`.AL-Go/settings.json`**. This repo includes that file at the **repository root** (next to `app.json`). After pulling latest, re-run the failed workflow.

## Git in Cursor / VS Code terminal

If `git` is “not recognized” only inside the editor terminal, this workspace adds Git to `Path` via `.vscode/settings.json`. **Close all terminals**, open a **new** terminal, or run **Developer: Reload Window**. Git lives at `C:\Program Files\Git\bin`.

## Build locally

Use Visual Studio Code: **AL: Package** — output `.app` matches `publisher_name_version` from `app.json`.

## License

Your project — set license in `app.json` as needed.
