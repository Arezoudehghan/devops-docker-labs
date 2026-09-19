# Session 58 — Secret Scanning with Gitleaks

Chapter 9 — Docker Security

This lab demonstrates how to find hardcoded credentials with Gitleaks, why deleting a secret from the current file does not remove it from Git history, and how to use secret scanning as a GitLab CI security gate.

## Execution host

Run the lab on DEV-1.

## Repository files

- `app.py`: reads `API_KEY` from an environment variable instead of hardcoding it.
- `.env.example`: safe template with no credential value.
- `.gitleaks.toml`: extends the default Gitleaks rules.
- `.gitlab-ci.yml`: runs a full-history Gitleaks scan before the build stage.
- `docs/DevOps_Gitleaks_Secret_Scanning_Session_58_Commands_CheatSheet.txt`: command cheat sheet for this lesson.

## Important lab safety

This GitHub repository intentionally does not contain a real credential or a committed `.env` file.

To reproduce the accidental-secret history scenario, copy this session directory to a disposable standalone directory and initialize a separate Git repository there. Do not use real credentials.

~~~bash
mkdir -p /opt/docker-labs/session58-gitleaks
cp -a . /opt/docker-labs/session58-gitleaks/
cd /opt/docker-labs/session58-gitleaks
git init
git config user.name "DevOps Lab"
git config user.email "devops-lab@example.local"
~~~

## 1. Create a local fake secret

Create a fake GitHub-style token locally. The value is randomly generated and is not a real credential.

~~~bash
printf 'APP_ENV=lab\nAPI_KEY="ghp_%s"\n' "$(openssl rand -hex 18)" > .env
~~~

Scan the current files:

~~~bash
gitleaks dir \
  --verbose \
  --redact \
  --report-format json \
  --report-path /tmp/session58-dir-report.json \
  .
~~~

Check the exit code:

~~~bash
echo $?
~~~

## 2. Commit the fake secret in the disposable repository

~~~bash
git add app.py .env
git commit -m "lab: accidentally commit fake secret"
git log --oneline
~~~

## 3. Remove the secret from the current tree

~~~bash
cat > .env <<'EOF'
APP_ENV=lab
EOF

printf '.env\n' > .gitignore
git rm --cached .env
git add .gitignore
git commit -m "security: remove env file from repository"
~~~

Scan the current files again:

~~~bash
gitleaks dir \
  --verbose \
  --redact \
  --report-format json \
  --report-path /tmp/session58-current-report.json \
  .
~~~

Then scan Git history:

~~~bash
gitleaks git \
  --verbose \
  --redact \
  --report-format json \
  --report-path /tmp/session58-history-report.json \
  .
~~~

The current tree can be clean while the old commit still contains the fake secret.

## 4. GitLab CI security gate

The included `.gitlab-ci.yml` runs Gitleaks before the build stage.

`GIT_DEPTH: "0"` disables shallow cloning for this job so the repository history is available to the scanner.

The Gitleaks job stores `gitleaks-report.json` as an artifact with `when: always`, so the report remains available when the secret scan fails.

## 5. Custom Gitleaks configuration

The included `.gitleaks.toml` keeps the default Gitleaks rule set enabled:

~~~toml
title = "Company Gitleaks Configuration"

[extend]
useDefault = true
~~~

## Security rules demonstrated

- Never commit real passwords, tokens, API keys, private keys, or other credentials.
- Removing a secret from the current file does not remove it from old Git commits.
- A real leaked credential should be revoked or rotated immediately.
- Use `gitleaks dir` for current files and `gitleaks git` for Git repository history.
- Use `--redact` in CI to reduce the risk of exposing findings in logs and reports.
- Run secret scanning before build and deploy stages.
- Review false positives before adding allowlist entries.

## Commands cheat sheet

See:

`docs/DevOps_Gitleaks_Secret_Scanning_Session_58_Commands_CheatSheet.txt`
