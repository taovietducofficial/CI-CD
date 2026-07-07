# CI/CD Template — Node.js/TypeScript → Docker (GitHub Actions)

Template CI/CD chuẩn production để copy sang dự án Node.js khác. App mẫu là một Fastify
service tối giản; điều đáng giá là **pipeline** xung quanh nó.

## Có gì trong này

| Thành phần          | Công cụ                                                                           |
| ------------------- | --------------------------------------------------------------------------------- |
| App                 | TypeScript + Fastify (`/health`, `/ready`)                                        |
| Quality             | ESLint (flat config), Prettier, `tsc --noEmit`, Vitest + coverage (threshold 80%) |
| SAST                | GitHub CodeQL                                                                     |
| Dependency/CVE scan | Trivy (fs) + `dependency-review-action`                                           |
| Container           | Dockerfile multi-stage, non-root, `HEALTHCHECK`                                   |
| Image scan          | Trivy (image)                                                                     |
| Supply-chain        | SBOM + SLSA provenance (buildx) + chữ ký **cosign keyless**                       |
| Registry            | GHCR (`ghcr.io`) qua `GITHUB_TOKEN`                                               |
| Deploy              | staging (auto) → production (approval gate) qua GitHub Environments               |
| Bảo trì             | Dependabot (npm + actions + docker), CODEOWNERS, PR template                      |

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

- **`ci.yml`** — chạy trên PR & push nhánh non-main: quality gate + CodeQL + dependency
  review + Trivy fs scan.
- **`cd.yml`** — chạy trên push `main` và tag `v*`: quality gate → build image (buildx,
  cache, SBOM, provenance) → push GHCR → Trivy image scan (advisory, không block) → cosign
  sign → deploy staging (auto) → deploy production (chờ approval).
- **`reusable-node-ci.yml`** — quality gate dùng chung (`workflow_call`). Repo khác có thể
  tái dùng: `uses: <owner>/ci-cd/.github/workflows/reusable-node-ci.yml@main`.

## Thiết lập trên GitHub (bắt buộc cho phần deploy)

1. **Environments** — Settings → Environments, tạo `staging` và `production`.
2. **Approval gate** — ở environment `production`, bật **Required reviewers** để pipeline
   dừng chờ duyệt trước khi deploy prod.
3. **GHCR** — không cần secret; `GITHUB_TOKEN` đã đủ quyền push (đã khai báo
   `packages: write`). Package tạo lần đầu ở chế độ private — chỉnh visibility nếu cần.
4. **Deploy thật** — thay bước placeholder trong `cd.yml` (đánh dấu `ponytail:`) bằng lệnh
   thật (`kubectl` / `helm` / `ssh`) và thêm secret tương ứng (vd `KUBE_CONFIG`) vào từng
   environment.

## Verify chữ ký image

```bash
cosign verify \
  --certificate-identity-regexp "https://github.com/<owner>/ci-cd/.github/workflows/cd.yml@.*" \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/<owner>/ci-cd@<digest>
```

## Dùng cho project mới

Repo này được thiết kế để tái dùng. Cách nhanh nhất là dùng nó như **template repository**:

1. **Settings → General → tick ☑ Template repository** (làm 1 lần).
2. Project mới: bấm **"Use this template" → Create a new repository** → GitHub copy toàn bộ
   (`.github/`, `Dockerfile`, config, app mẫu) sang repo mới.

> Không có nút "Use this template"? Cứ copy tay 3 phần: thư mục **`.github/`**, **`Dockerfile`**,
> và các **npm script** mà workflow gọi (xem bên dưới).

### 2 điều kiện bắt buộc (không tự đi theo folder)

- **`package.json` phải có đủ script** workflow gọi: `lint`, `format:check`, `typecheck`,
  `test`, `build`. Thiếu bất kỳ cái nào → CI đỏ. (Stack khác Node.js thì phải viết lại phần
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
