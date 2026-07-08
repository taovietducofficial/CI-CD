#!/usr/bin/env bash
#
# Deploy gate. Refuses an image unless every claim the pipeline makes about it holds.
# Called by both deploy jobs in .github/workflows/cd.yml -- one copy, so staging and
# production can never drift apart.
#
# Usage: verify-image.sh ghcr.io/owner/repo@sha256:...
# Needs: cosign, gh (GH_TOKEN), docker, jq. Requires a digest ref, never a tag.

set -euo pipefail

IMAGE="${1:?usage: verify-image.sh <image@sha256:digest>}"
REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY must be set}"
SERVER="${GITHUB_SERVER_URL:-https://github.com}"
SIGNER_WORKFLOW=".github/workflows/reusable-docker.yml"
# Same path, dots escaped, for use inside the certificate-identity regexp. Spelled out
# rather than derived: `${SIGNER_WORKFLOW//./\.}` silently yields an unescaped dot, which
# turns `.yml` into "any character then yml".
SIGNER_WORKFLOW_RE='\.github/workflows/reusable-docker\.yml'

case "$IMAGE" in
  *@sha256:*) ;;
  *) echo "::error::refusing to verify a tag; pass an immutable digest ref" >&2; exit 1 ;;
esac

# 1. WHO signed it. The identity is pinned to the workflow that runs `cosign sign` AND to
#    a trusted ref. Without the ref anchor, anyone with write access could push a branch
#    whose workflow calls reusable-docker.yml, mint a signature as
#    `.../reusable-docker.yml@refs/heads/whatever`, and walk it through this gate.
echo "==> signature"
cosign verify \
  --certificate-identity-regexp "^${SERVER}/${REPO}/${SIGNER_WORKFLOW_RE}@refs/(heads/main|tags/v.+)\$" \
  --certificate-github-workflow-repository "$REPO" \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  "$IMAGE" >/dev/null

# 2. WHAT was signed. A valid signature only proves someone we trust signed *something*.
#    This proves the image carries SLSA provenance naming this repo and this workflow as
#    its builder. Note: NOT `cosign verify-attestation` -- nothing here runs `cosign
#    attest`, so no cosign-signed attestation exists. The provenance is the sigstore
#    bundle that actions/attest-build-provenance pushed to the registry.
echo "==> provenance"
gh attestation verify "oci://${IMAGE}" \
  --repo "$REPO" \
  --signer-workflow "${REPO}/${SIGNER_WORKFLOW}"

# 3. The SBOM buildkit attached actually exists. Cheap, and it catches a build that
#    silently dropped `sbom: true`.
echo "==> sbom"
docker buildx imagetools inspect "$IMAGE" --format '{{ json .SBOM }}' | grep -q 'SPDX' \
  || { echo "::error::no SPDX SBOM attached to $IMAGE" >&2; exit 1; }

echo "OK: $IMAGE is signed by ${SIGNER_WORKFLOW} on a trusted ref, with provenance and an SBOM."
