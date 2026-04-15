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

## AL-Go CI: Initialization / `$ProjectBuildInfo` error

1. **`.AL-Go/settings.json`** must exist at repo root (commit + push it).  
2. **`app.json` is at the repo root**, so **`appFolders`** uses **`["./"]`** (AL-Go expects `./` / `.\` style paths; plain `"."` can be skipped by folder resolution).  
3. Do **not** set **`projects`** to an empty array in `AL-Go-Settings.json` — that blocks auto-discovery. Omit **`projects`** so AL-Go adds **`"."`** when it finds **`.AL-Go/settings.json`** at root.

Confirm on GitHub: **Code** tab shows **`.AL-Go/settings.json`**. If that file is missing on the remote, Actions will always show **Found AL-Go Projects:** empty.

After fixes, **commit, push**, then **Re-run** the workflow.

## Git in Cursor / VS Code terminal

If `git` is “not recognized” only inside the editor terminal, this workspace adds Git to `Path` via `.vscode/settings.json`. **Close all terminals**, open a **new** terminal, or run **Developer: Reload Window**. Git lives at `C:\Program Files\Git\bin`.

## Build locally

Use Visual Studio Code: **AL: Package** — output `.app` matches `publisher_name_version` from `app.json`.

## Functional UX (no-code users)

- **Code Editor Workflow AL**: preview reads the full generated blob (multi-line), and character counting reflects the full text (not a single-line truncation).
- **Auto Deploy Scheduler**: uses a dialog-style page with footer actions (**Schedule**, **Deploy**, **Cancel**) so the buttons match the intended UX.
  - **Instant Deploy = On**: **Deploy** is enabled; scheduling fields are hidden; **Schedule** is disabled.
  - **Instant Deploy = Off**: **Schedule** is enabled; **Deploy** is disabled; scheduling fields are visible.
  - **Deploy** dispatches a GitHub Actions workflow via API (requires repo/branch/workflow/token setup on Custom Approval Workflow).
  - **Schedule** creates a Job Queue entry that dispatches the same GitHub workflow at the selected date/time.

## Deployment automation + monitoring

- Configure these fields on **Custom Approval Workflow**:
  - `Deploy Repo Owner`
  - `Deploy Repo Name`
  - `Deploy Branch`
  - `Deploy Workflow File` (default: `PublishToEnvironment.yaml`)
  - `Deploy PAT Token` (needs permission to run workflows)
- Monitoring fields update automatically after dispatch:
  - `Last Scheduled At`
  - `Last Deploy At`
  - `Last Deploy Status`
  - `Last Deploy Message`
  - `Last Deploy Run URL` (open with **Open Last Deploy Run** action)

## License

Your project — set license in `app.json` as needed.
