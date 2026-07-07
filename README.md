# CI/CD Template — Node.js/TypeScript -> Docker (GitHub Actions)

Template CI/CD chuẩn production để copy sang dự án Node.js khác. App mẫu là một Fastify
service tối giản; điều đáng giá là **pipeline** xung quanh nó.

## Có gì trong này

| Thành phần          | Công cụ                                                                           |
| ------------------- | --------------------------------------------------------------------------------- |
| App                 | TypeScript + Fastify (`/health`, `/ready`)                                        |
| Quality             | ESLint, Prettier, `tsc --noEmit`, Vitest + coverage (80%), test matrix Node 22/24 |
| SAST                | GitHub CodeQL                                                                     |
| Dependency/CVE scan | Trivy (fs) + `dependency-review-action`                                           |
| Container           | Dockerfile multi-stage, non-root, `HEALTHCHECK`, build **multi-arch** amd64+arm64 |
| Image scan          | Trivy (image, advisory)                                                           |
| Supply-chain        | SBOM + SLSA provenance + **GitHub attestation** + **cosign** sign & verify        |
| Registry            | GHCR (`ghcr.io`) qua `GITHUB_TOKEN`                                               |
| Release             | **release-please** — tự version + CHANGELOG + GitHub Release + tag semver         |
| Deploy              | staging (auto) -> production (approval gate), verify chữ ký trước khi deploy      |
| Governance          | Ruleset bảo vệ `main` (PR + CI xanh + CODEOWNERS)                                 |
| Bảo trì             | Dependabot (npm + actions + docker), CODEOWNERS, PR title lint                    |

## Chạy local

```bash
npm ci
npm run lint && npm run typecheck && npm test   # quality gate
npm run build && npm start                       # chạy service
curl localhost:3000/health                        # -> {"status":"ok"}
```

## Docker local

```bash
docker build -t ci-cd .
docker run -p 3000:3000 ci-cd
curl localhost:3000/health
```

## Pipeline

- **`ci.yml`** — trên PR & push nhánh non-main: quality gate (matrix Node 22/24) + lint tiêu
  đề PR + CodeQL + dependency review + Trivy fs scan + comment coverage lên PR.
- **`cd.yml`** — trên push `main` và tag `v*`: quality gate -> build **multi-arch** (amd64 +
  arm64, buildx cache, SBOM, provenance) -> push GHCR -> GitHub attestation -> Trivy image scan
  (advisory) -> cosign sign -> **verify chữ ký** -> deploy staging (auto) -> deploy production
  (chờ approval).
- **`release.yml`** — release-please: gộp các commit `feat:`/`fix:` thành một Release PR; merge
  PR đó thì tự tạo tag `vX.Y.Z` + CHANGELOG + GitHub Release, và tag đó kích hoạt `cd.yml` build
  image gắn version semver.
- **`reusable-node-ci.yml`** — quality gate dùng chung (`workflow_call`).

## Thiết lập trên GitHub (bắt buộc cho phần deploy)

1. **Environments** — Settings -> Environments, tạo `staging` và `production`.
2. **Approval gate** — ở environment `production`, bật **Required reviewers**.
3. **GHCR** — không cần secret; `GITHUB_TOKEN` đã đủ quyền push. Package lần đầu ở chế độ
   private — chỉnh visibility nếu cần.
4. **Branch protection** — Settings -> Rules -> Rulesets -> **New ruleset -> Import** ->
   chọn `.github/rulesets/main-branch-protection.json`. Nó chặn push thẳng `main`, bắt buộc
   PR + CI xanh + linear history mới được merge. Mặc định `required_approving_review_count: 0`
   để chạy được **solo**; team thì tăng lên `1` và bật `require_code_owner_review`. Sau khi mở
   PR đầu tiên, đối chiếu tên status check thật (tab Checks) với ruleset và sửa nếu lệch.
5. **Release tự động** — bật **Settings -> General -> Pull Requests -> Allow squash merging**
   và đặt commit message của squash theo tiêu đề PR. release-please đọc các commit theo chuẩn
   Conventional Commits (`feat:`, `fix:`...) để quyết định version.
6. **Deploy thật** — thay bước `echo` placeholder trong `cd.yml` bằng lệnh thật (`kubectl` /
   `helm` / `ssh`) và thêm secret (vd `KUBE_CONFIG`) vào từng environment.

## Verify chữ ký image

```bash
cosign verify \
  --certificate-identity-regexp "https://github.com/<owner>/ci-cd/.github/workflows/cd.yml@.*" \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/<owner>/ci-cd@<digest>
```

## Dùng cho project mới

Repo này được thiết kế để tái dùng. Cách nhanh nhất là dùng nó như **template repository**:

1. **Settings -> General -> bật Template repository** (làm 1 lần).
2. Project mới: bấm **"Use this template" -> Create a new repository** -> GitHub copy toàn bộ
   (`.github/`, `Dockerfile`, config, app mẫu) sang repo mới.

> Không có nút "Use this template"? Cứ copy tay 3 phần: thư mục **`.github/`**, **`Dockerfile`**,
> và các **npm script** mà workflow gọi (xem bên dưới).

### 2 điều kiện bắt buộc (không tự đi theo folder)

- **`package.json` phải có đủ script** workflow gọi: `lint`, `format:check`, `typecheck`,
  `test`, `build`. Thiếu bất kỳ cái nào -> CI đỏ. (Stack khác Node.js thì phải viết lại phần
  build/test trong `reusable-node-ci.yml` + `Dockerfile`.)
- **Tạo lại GitHub Environments** `staging` + `production` (và Required reviewers cho
  `production`) trong repo mới — đây là **cấu hình trên GitHub, không nằm trong code**. Xem
  mục [Thiết lập trên GitHub](#thiết-lập-trên-github-bắt-buộc-cho-phần-deploy).

### Mỗi project mới cần đổi

- Thay thư mục **`src/`** bằng app thật (giữ nguyên tên các npm script, hoặc sửa `Dockerfile`
  nếu output khác `dist/server.js`).
- Sửa **`.github/CODEOWNERS`** (đang là placeholder `@your-org/your-team`).
- `IMAGE_NAME` **không cần đổi** — tự lấy theo `github.repository` (đã tự hạ chữ thường cho
  hợp lệ với GHCR).

### Tái dùng phần CI mà không copy

Repo khác có thể gọi từ xa reusable workflow, sửa 1 lần ở đây là mọi repo con hưởng theo:

```yaml
jobs:
  ci:
    uses: <owner>/CI-CD/.github/workflows/reusable-node-ci.yml@main
```

(Nhưng `ci.yml` / `cd.yml` vẫn phải nằm ở mỗi repo.)

## Thêm

- Quy trình đóng góp & chuẩn commit: [CONTRIBUTING.md](CONTRIBUTING.md)
- Chính sách bảo mật & supply-chain: [SECURITY.md](SECURITY.md)
- Giấy phép: [MIT](LICENSE)
