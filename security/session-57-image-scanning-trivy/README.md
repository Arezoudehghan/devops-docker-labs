# Session 57 — Image Scanning with Trivy

Chapter 9 — Docker Security

This lab demonstrates how to scan Docker images with Trivy, filter vulnerability severity, create a JSON report, and turn the scan into a CI/CD security gate with a non-zero exit code.

## Execution host

Run this lab on `DEV-1`, where Docker, the GitLab Runner, and Trivy are available.

## Repository files

- `Dockerfile`: builds the small Python image used by the scan lab.
- `app.py`: minimal HTTP application for the test image.
- `requirements.txt`: dependency file used by the Dockerfile.
- `.gitlab-ci.yml`: builds the image, creates a Trivy JSON report, and blocks the pipeline for matching HIGH/CRITICAL vulnerabilities.
- `.dockerignore`: keeps Git metadata, reports, and documentation out of the image build context.
- `.gitignore`: keeps generated Trivy reports and Python cache files out of Git.
- `docs/DevOps_Image_Scanning_with_Trivy_Session_57_Commands_CheatSheet.txt`: complete command cheat sheet for this lesson.

## 1. Prepare the Trivy cache

Create the cache directory:

~~~bash
mkdir -p /opt/trivy-cache
~~~

Download or update the vulnerability database:

~~~bash
trivy \
  --cache-dir /opt/trivy-cache \
  image \
  --download-db-only
~~~

Verify the cache size:

~~~bash
du -sh /opt/trivy-cache
~~~

## 2. Build the lab image

Build the image from this directory:

~~~bash
docker build \
  --no-cache \
  -t cicd-session57-app:v2 \
  .
~~~

Verify that the image exists:

~~~bash
docker image ls
~~~

## 3. Run a vulnerability scan

Scan only for vulnerabilities:

~~~bash
trivy \
  --cache-dir /opt/trivy-cache \
  image \
  --scanners vuln \
  cicd-session57-app:v2
~~~

Filter the result to HIGH and CRITICAL findings:

~~~bash
trivy \
  --cache-dir /opt/trivy-cache \
  image \
  --scanners vuln \
  --severity HIGH,CRITICAL \
  cicd-session57-app:v2
~~~

## 4. Apply the security gate

The following command ignores findings without a currently available fix and returns exit code 1 when a matching HIGH or CRITICAL vulnerability is found:

~~~bash
trivy \
  --cache-dir /opt/trivy-cache \
  image \
  --scanners vuln \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --exit-code 1 \
  cicd-session57-app:v2
~~~

Check the exit status immediately after the scan:

~~~bash
echo $?
~~~

An exit status of 0 allows the next CI/CD stage to continue. An exit status of 1 blocks the pipeline according to this lab policy.

## 5. Generate a JSON report

Create a report that can be stored as a GitLab artifact:

~~~bash
trivy \
  --cache-dir /opt/trivy-cache \
  image \
  --scanners vuln \
  --format json \
  --output trivy-report.json \
  cicd-session57-app:v2
~~~

Verify the generated file:

~~~bash
ls -lh trivy-report.json
~~~

## 6. GitLab CI/CD flow

The included `.gitlab-ci.yml` implements this flow:

~~~text
Build image
    |
    v
Generate Trivy report
    |
    v
Security gate
    |
    +-- exit 0 --> continue
    |
    +-- exit 1 --> pipeline failed
~~~

The runner tag is `dev-shell`, matching the shell-runner lab used in the Docker CI/CD sessions.

The security job stores `trivy-report.json` as an artifact with `when: always`, so the report remains available even when the security gate fails.

## 7. Optional Nexus image scan

After authenticating to a private registry, Trivy can scan an image directly from the registry.

Login pattern:

~~~bash
trivy registry login \
  --username YOUR_NEXUS_USERNAME \
  --password-stdin \
  192.168.94.90:8085
~~~

Scan pattern used in this lesson:

~~~bash
trivy \
  --cache-dir /opt/trivy-cache \
  image \
  --scanners vuln \
  --severity HIGH,CRITICAL \
  192.168.94.90:8085/docker-hosted/myapp:1.0
~~~

Replace the repository path and image tag with the actual Nexus image you want to scan.

## Security policy demonstrated

- Build the image before the security scan.
- Scan before pushing or deploying an image when possible.
- Use `--severity HIGH,CRITICAL` to focus the gate on serious findings.
- Use `--exit-code 1` to make Trivy enforce the CI/CD gate.
- Treat `--ignore-unfixed` as a filtering policy, not proof that an unfixed vulnerability is safe.
- Keep the JSON report as an artifact for troubleshooting and remediation.
- Rebuild and rescan after updating a base image or dependency.

## Commands cheat sheet

See:

`docs/DevOps_Image_Scanning_with_Trivy_Session_57_Commands_CheatSheet.txt`
