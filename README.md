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
  đề PR + CodeQL + dependency review + Trivy fs scan + **zizmor** (lint chính workflow) +
  comment coverage lên PR.
- **`cd.yml`** — trên push `main`: release-please -> quality gate -> `reusable-docker.yml` ->
  verify-reproducible -> deploy staging (auto) -> deploy production (chờ approval).
  **Một workflow duy nhất build image.** Trước đây release-please nằm ở file riêng và cũng
  build; vì commit release-please rơi vào `main`, cả hai file cùng chạy trên một commit và
  tạo **hai digest khác nhau** — một cái được deploy, cái kia nhận tag `vX.Y.Z` + `latest`,
  ai xong sau thì thắng. Gộp lại thì tag, chữ ký, và thứ được deploy luôn là cùng một digest.
  Trigger `tags: ['v*']` chỉ dành cho tag đẩy tay.
- **`reusable-node-ci.yml`** — quality gate dùng chung (`workflow_call`).
- **`reusable-docker.yml`** — toàn bộ phần supply-chain: build **multi-arch** (amd64 + arm64,
  buildx cache, SBOM, provenance `mode=max`, `SOURCE_DATE_EPOCH`) -> push GHCR -> **smoke test
  trên cả hai kiến trúc** -> GitHub attestation -> Trivy image scan (advisory, đẩy lên tab
  Security) -> cosign sign. Image không boot được thì job fail **trước khi ký**, nên cổng
  deploy từ chối nó. Cổng tự đóng, không cần logic thêm.
- **`scripts/verify-image.sh`** — cổng deploy, một bản dùng chung cho staging lẫn production
  (hai bản sao của một cổng bảo mật sẽ trôi xa nhau). Kiểm ba thứ: chữ ký đến từ đúng workflow
  **tại đúng ref**, provenance trỏ về đúng repo này, và SBOM có tồn tại.

### Reproducible build để làm gì

`SOURCE_DATE_EPOCH` + `rewrite-timestamp` khiến layer bit-for-bit giống nhau giữa các lần
build. Nó **không** làm digest của image index ổn định — SLSA provenance nhúng
`buildStartedOn` / `buildInvocationId`, đổi mỗi lần chạy. Digest ổn định chỉ có nếu tắt
`provenance` và `sbom`, tức phá hủy toàn bộ mục đích của repo này.

Lợi ích thật là **verifiable rebuild**: job `verify-reproducible` clone lại source, build lại
amd64 **không dùng cache**, rồi so digest của per-platform manifest với cái đã publish. Khớp
⇒ image trên registry đúng là thứ sinh ra từ source này, không có gì được chèn vào. Đó là lý
do job này tồn tại — reproducible build mà không ai kiểm chứng thì chỉ là một dòng config.

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
6. **Secret scanning** — Settings -> Code security, bật **Secret scanning** + **Push protection**.
   Miễn phí với repo **public**; repo private cần GitHub Advanced Security. Không có nó thì thêm
   một job `gitleaks` vào `ci.yml` — nhưng nó chỉ báo _sau khi_ secret đã vào history, còn push
   protection chặn ngay lúc `git push`. Đừng thêm cả hai.
7. **Deploy thật** — thay bước `echo` placeholder trong `cd.yml` bằng lệnh thật (`kubectl` /
   `helm` / `ssh`) và thêm secret (vd `KUBE_CONFIG`) vào từng environment.

## Verify image

Chạy đúng thứ cổng deploy chạy:

```bash
GITHUB_REPOSITORY=<owner>/ci-cd GH_TOKEN=$(gh auth token) \
  bash scripts/verify-image.sh ghcr.io/<owner>/ci-cd@<digest>
```

Identity là **`reusable-docker.yml`** (nơi `cosign sign` chạy), không phải workflow gọi nó. Và
nó bị ghim vào `refs/heads/main` hoặc `refs/tags/v*` — nếu chỉ ghim tên file mà để ref tự do
(`@.+$`), bất kỳ ai có quyền write cũng đẩy được một nhánh có workflow gọi
`reusable-docker.yml`, mint chữ ký hợp lệ, và đi thẳng qua cổng production.

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
- Sửa **`.github/CODEOWNERS`** — đang trỏ về owner của repo này, đổi sang team của bạn.
- Ruleset để `required_approving_review_count: 0` cho repo solo. Có team thì **tăng lên `1`** và
  bật `require_code_owner_review`, nếu không cổng PR chỉ enforce _CI xanh_, không enforce _review_.
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

## Giấy phép & ghi công

[Apache-2.0](LICENSE) — Copyright 2026 Tào Việt Đức.

Bạn được tự do dùng, sửa, và dùng trong sản phẩm thương mại. Ba nghĩa vụ:

- Giữ nguyên các thông báo copyright, patent, trademark, attribution trong source (§4c).
- Bản phái sinh bạn phân phối **phải mang theo nội dung** của [NOTICE](NOTICE) (§4d).
- Ghi rõ những file bạn đã sửa (§4b).
- Không được dùng tên tác giả để quảng bá bản fork của bạn (§6).

Image publish từ repo này được cosign ký và có SLSA provenance trỏ về repo gốc. Fork rồi
build lại thì provenance ghi repo của bạn — đó là cách đúng. Phát tán lại image của repo
này thì chữ ký chứng minh nguồn gốc, và không xoá được.

## Thêm

- Quy trình đóng góp & chuẩn commit: [CONTRIBUTING.md](CONTRIBUTING.md)
- Chính sách bảo mật & supply-chain: [SECURITY.md](SECURITY.md)
