# DevOps Capstone 1 — Voting App: Ship It

A containerized, CI/CD-deployed, Kubernetes-hosted version of the dockersamples/example-voting-app.

## What it does

Users vote for Cats or Dogs. The vote is queued in Redis, written to PostgreSQL by a background worker, and displayed live on a results page.

    browser -> vote (Python/Flask) -> Redis (queue) -> worker (.NET) -> PostgreSQL -> result (Node.js) -> browser

## Architecture

```mermaid
flowchart LR
    U[User] --> V[vote Python Flask]
    V --> R[(Redis queue)]
    R --> W[worker .NET]
    W --> D[(PostgreSQL)]
    D --> S[result Node.js]
    S --> U

## Tools and why

| Tool | Role | Why this choice |
|---|---|---|
| Docker / Compose | Build images, run locally | Matches how the app is packaged upstream |
| Terraform (tehcyx/kind) | Create the Kubernetes cluster from code | Infrastructure-as-code: apply, destroy, apply reproduces the cluster |
| kind | Local Kubernetes cluster | Deliberate substitution: the brief describes a cloud VPC, but no payment card was available. kind runs a real Kubernetes control plane, and Helm, kubectl and rollbacks behave identically. Moving to EKS later means changing the Terraform provider, not the workflow. |
| GitHub Actions | CI/CD | Builds, scans and pushes all three images on every push to main |
| Trivy | Container vulnerability scan | Fails the pipeline on fixable HIGH/CRITICAL CVEs |
| GHCR | Image registry | Free, no card, authenticates with the automatic GITHUB_TOKEN, so no long-lived secret is stored |
| Helm | Package and deploy | One chart, one values file, and a reversible release history |

## Repository layout


## Running locally

```bash
docker compose up -d
# vote page:   http://localhost:8080
# result page: http://localhost:8081

## Deploying to Kubernetes

Run terraform init and terraform apply in the terraform folder to create the cluster. Then install the chart with helm install voting-app helm/voting-app, passing the current commit SHA as the image tag for vote, result and worker. Verify with kubectl get pods.

## CI/CD pipeline

On every push to main, a matrix job runs once per service (vote, result, worker):

1. Build the image with Buildx and load true, so it exists in the runner's Docker daemon for scanning.
2. Scan with Trivy at severity CRITICAL and HIGH with exit-code 1. The build fails if a fixable vulnerability is found.
3. Push to ghcr.io/OWNER/SERVICE:FULL_COMMIT_SHA.

Images are tagged with the commit SHA, so every deployed artifact maps to an exact commit.

## Security decisions

- Non-root containers. All three app images run as appuser uid 10001, verified at runtime with docker compose exec SERVICE id.
- Digest-pinned base images. The Dockerfiles pin python 3.11 slim, node 18 slim and the .NET images by sha256, so a rebuild cannot silently pick up a different base.
- No secrets in Git. The gitignore excludes Terraform state, the .terraform provider cache and the generated kubeconfig.
- Scan is a gate, not a report. Trivy failures block the push, so a vulnerable image never reaches GHCR.

### About the trivyignore file

Suppressions are deliberate and documented, not blanket:

- CVE-2026-23949 and CVE-2026-24049 are vendored inside setuptools in the Python base image and are not independently upgradable.
- npm-bundled CVEs live in npm's own dependency tree, not the application's package.json.
- Worker base-image CVEs: the dotnet runtime 7.0 image runs Debian 11, which is end-of-life and no longer receives patches. Migrating the worker to Debian 12 is tracked as future work.
- CVE-2021-24112 in System.Drawing.Common is a known false positive here; the vulnerable native path is not exercised by the worker on Linux.

The ignore-unfixed setting is also enabled, so the pipeline only fails on CVEs that have a fix.

## Known limitations

- Single-node kind cluster: no high availability and no cloud load balancer.
- Ephemeral data: PostgreSQL and Redis have no PersistentVolumeClaim, so data is lost when pods are recreated.
- No Ingress: services are reached with kubectl port-forward. Ingress is an optional stretch goal in the brief.
- No remote Terraform state: state is local and git-ignored. A real team would use a remote backend with locking.

## Author

Ajayi Dolapo - DevOps Capstone, Beginner Edition.
