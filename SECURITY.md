# Security Policy

## Supported versions

The latest release on `main` is supported. Older versions are not patched.

## Reporting a vulnerability

Please do **not** open a public issue for security problems.

Report privately via GitHub Security Advisories:
**Security -> Report a vulnerability** on this repository, or email the maintainer.

Include a description, reproduction steps, and impact. You will get an
acknowledgement within a few days and a fix or mitigation timeline after triage.

## Supply-chain guarantees

Every image published by the CD pipeline ships with:

- an **SBOM** and **SLSA provenance** (BuildKit) attestation,
- a **GitHub build-provenance** attestation,
- a **keyless Cosign signature** (Sigstore),

which are **verified** before any deployment. See `README.md` for how to verify
a published image yourself.
