# Threat Model - Azure DevSecOps Platform

**Author:** Austin Mundy  
**Date:** August 2026  
**Methodology:** STRIDE

---

## System Overview

A Kubernetes-based application platform on Azure with continuous security validation, policy-as-code enforcement, and compliance evidence generation.

**Trust Boundaries:**

1. Internet → GitHub (public repo)
2. GitHub → Azure (OIDC federation)
3. Azure control plane → AKS cluster
4. AKS cluster → Key Vault (workload identity)
5. Pod → Pod (network policies)

---

## Assets

| Asset                   | Sensitivity | Location                  |
| ----------------------- | ----------- | ------------------------- |
| Application source code | Medium      | GitHub                    |
| Container images        | High        | ACR                       |
| Database credentials    | Critical    | Key Vault                 |
| Postgres data           | High        | AKS PVC                   |
| Terraform state         | High        | Bootstrap storage account |
| OIDC federation config  | Critical    | Entra ID                  |
| Cosign signatures       | High        | ACR (attached)            |
| SBOM attestations       | Medium      | ACR (attached)            |

---

## STRIDE Analysis

### Spoofing

| Threat                               | Target              | Mitigation                                                                        | Status         |
| ------------------------------------ | ------------------- | --------------------------------------------------------------------------------- | -------------- |
| Attacker impersonates GitHub Actions | Azure OIDC endpoint | Federated credential with exact subject match (`repo:owner/repo:environment:lab`) | ✅ Implemented |
| Attacker pushes unsigned image       | ACR → AKS           | Kyverno policy verifies Cosign signatures at admission                            | ✅ Implemented |
| Compromised pod accesses Key Vault   | Key Vault           | Workload Identity binds specific ServiceAccount to specific managed identity      | ✅ Implemented |
| Stolen kubeconfig                    | AKS API             | Azure AD integration required for kubectl auth, no static creds                   | ✅ Implemented |

### Tampering

| Threat                               | Target            | Mitigation                                                     | Status         |
| ------------------------------------ | ----------------- | -------------------------------------------------------------- | -------------- |
| Modified image after push            | ACR               | Cosign signature verification; images referenced by digest     | ✅ Implemented |
| Terraform state manipulation         | Bootstrap storage | Blob versioning + soft delete enabled                          | ✅ Implemented |
| Pod spec modified to bypass security | AKS               | Kyverno + Gatekeeper admission control, ArgoCD drift detection | ✅ Implemented |
| Malicious dependency injected        | App container     | Syft SBOM generation, Grype/Trivy scan gates in CI             | ✅ Implemented |

### Repudiation

| Threat                                      | Target    | Mitigation                                                  | Status         |
| ------------------------------------------- | --------- | ----------------------------------------------------------- | -------------- |
| Unauthorized deployment without audit trail | AKS       | ArgoCD Git history, GitHub Actions logs, Azure Activity Log | ✅ Implemented |
| Secret access without logging               | Key Vault | Key Vault diagnostic logs to Log Analytics                  | ✅ Implemented |
| Policy bypass undetected                    | Cluster   | Kyverno PolicyReports, Defender for Cloud alerts            | ✅ Implemented |

### Information Disclosure

| Threat                                | Target     | Mitigation                                                                            | Status                                    |
| ------------------------------------- | ---------- | ------------------------------------------------------------------------------------- | ----------------------------------------- |
| Secrets in Git history                | Codebase   | gitleaks pre-commit and CI gate                                                       | ✅ Implemented                            |
| Pod reads another pod's secrets       | Cluster    | Workload Identity scopes secrets to specific ServiceAccounts                          | ✅ Implemented                            |
| Terraform state exposes secrets       | State file | Sensitive values stored in Key Vault, not TF state; state storage uses private access | ⚠️ Partial (private endpoint recommended) |
| Container image layers expose secrets | ACR        | Multi-stage Dockerfile, secrets injected at runtime via CSI driver                    | ✅ Implemented                            |

### Denial of Service

| Threat                           | Target    | Mitigation                                                            | Status             |
| -------------------------------- | --------- | --------------------------------------------------------------------- | ------------------ |
| Resource exhaustion in cluster   | AKS nodes | Kyverno policy enforces resource limits on all pods                   | ✅ Implemented     |
| Noisy neighbor in namespace      | App pods  | Resource quotas per namespace                                         | ⚠️ Not implemented |
| Crypto mining container deployed | Cluster   | Pod Security Standards (restricted profile), no privileged containers | ✅ Implemented     |

### Elevation of Privilege

| Threat                      | Target       | Mitigation                                                                             | Status              |
| --------------------------- | ------------ | -------------------------------------------------------------------------------------- | ------------------- |
| Container escape            | Node         | Pod Security Standards baseline/restricted, no hostPID/hostNetwork except kube-bench   | ✅ Implemented      |
| Service account token abuse | Cluster RBAC | Minimal RBAC bindings, no cluster-admin to workloads                                   | ✅ Implemented      |
| Privileged pod deployment   | Cluster      | Kyverno disallow-privileged-containers policy                                          | ✅ Implemented      |
| Azure role escalation       | Subscription | OIDC service principal scoped to specific resource groups (Contributor on rg-dev only) | ⚠️ Could be tighter |

---

## Risk Summary

| Category               | Critical | High | Medium | Low |
| ---------------------- | -------- | ---- | ------ | --- |
| Spoofing               | 0        | 0    | 0      | 0   |
| Tampering              | 0        | 0    | 0      | 0   |
| Repudiation            | 0        | 0    | 0      | 0   |
| Information Disclosure | 0        | 1    | 0      | 0   |
| Denial of Service      | 0        | 0    | 1      | 0   |
| Elevation of Privilege | 0        | 0    | 1      | 0   |

**Residual Risks:**

1. Terraform state storage lacks private endpoint (low effort to fix)
2. No namespace resource quotas (medium effort)
3. OIDC SP has Contributor on full subscription (should scope to RG)

---

## Compliance Mapping

| Threat Category        | Related NIST 800-53 Controls                 |
| ---------------------- | -------------------------------------------- |
| Spoofing               | IA-2, IA-8 (Identification & Authentication) |
| Tampering              | SI-7 (Software & Information Integrity)      |
| Repudiation            | AU-2, AU-3 (Audit Events)                    |
| Information Disclosure | SC-8, SC-28 (Data Protection)                |
| Denial of Service      | SC-5 (DoS Protection)                        |
| Elevation of Privilege | AC-6 (Least Privilege)                       |

---

## Diagram

See `docs/architecture-diagram.png`
