# Session 01 — GitLab CI/CD Basics

This lab introduces the core GitLab CI/CD concepts used throughout the course:

- Pipeline
- Stage
- Job
- GitLab Runner
- Shell Executor
- Predefined CI/CD variables
- Artifact
- CI Lint / Pipeline validation
- Basic pipeline troubleshooting

## Lab architecture

### DEV-1
- IP: `192.168.94.90`
- GitLab CE
- GitLab Runner
- Shell executor
- Runner tag: `dev-shell`
- Docker
- Nexus

### DEV-2
- IP: `192.168.94.91`
- Docker deployment server
- Monitoring services used in later sessions

## Files

- `app.sh` — simple Bash application used by the pipeline.
- `.gitlab-ci.yml` — three-stage Validate → Test → Package pipeline.
- `DevOps_GitLab_CICD_Pipeline_Session_01_Commands_CheatSheet.txt` — commands from this lesson with beginner-friendly English explanations.

## Pipeline flow

```text
Git Push
   |
   v
GitLab
   |
   v
GitLab Runner (dev-shell)
   |
   +--> validate_script
   |
   +--> test_script
   |
   +--> package_script
             |
             v
          Artifact
```

## Predefined variables practiced in this session

- `CI_PROJECT_NAME`
- `CI_COMMIT_BRANCH`
- `CI_COMMIT_SHORT_SHA`
- `CI_PIPELINE_ID`

## Validation

Before pushing pipeline changes, validate `.gitlab-ci.yml` with GitLab Pipeline Editor / CI Lint.
