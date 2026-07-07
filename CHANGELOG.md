# Changelog

## [1.1.0](https://github.com/taovietducofficial/CI-CD/compare/v1.0.2...v1.1.0) (2026-07-07)


### Features

* **release:** publish versioned image from release workflow (no PAT needed) ([6852023](https://github.com/taovietducofficial/CI-CD/commit/685202344cf26336ac7e3ad706be1f3e204cde7d))

## [1.0.2](https://github.com/taovietducofficial/CI-CD/compare/v1.0.1...v1.0.2) (2026-07-07)


### Bug Fixes

* **cd:** image scan reports to Security tab instead of blocking release ([5d3e90d](https://github.com/taovietducofficial/CI-CD/commit/5d3e90d0a3eab7072d33ceaeb2d5b307eaf2f414))
* **cd:** lowercase image ref for cosign/scan/deploy ([5e88a4b](https://github.com/taovietducofficial/CI-CD/commit/5e88a4b87a2b6d690b8f46c7d0521fe5d2479418))
* **cd:** make image scan advisory (non-blocking), drop flaky SARIF upload ([e16fb40](https://github.com/taovietducofficial/CI-CD/commit/e16fb409ac37e29ae3e3fd79827eb3a281f6539a))
* **ci:** pin trivy-action to valid tag v0.36.0 ([1f8282d](https://github.com/taovietducofficial/CI-CD/commit/1f8282d5d79dae94534d7a599d420b2c876239f8))
* **ci:** reusable workflow inherits caller permissions to fix CD startup_failure ([d9526ab](https://github.com/taovietducofficial/CI-CD/commit/d9526abc76f957f39ac8c6b4fb3b84e6e0ba0c6a))
* **docker:** base image node:20-alpine -&gt; node:22-alpine (LTS) ([8ccd44b](https://github.com/taovietducofficial/CI-CD/commit/8ccd44be927f4958110ce0cd248942514ba2e0aa))
* **release:** drop component prefix so release tag matches cd.yml v* trigger ([55f349c](https://github.com/taovietducofficial/CI-CD/commit/55f349c132bac2b3cb3b912b720d7bbe7862a4a1))


### Documentation

* add "Dùng cho project mới" guide (template repo + checklist) ([0d4345e](https://github.com/taovietducofficial/CI-CD/commit/0d4345e15dc0b8ad30f2284e7911cafc2577555f))

## [1.0.1](https://github.com/taovietducofficial/CI-CD/compare/ci-cd-v1.0.0...ci-cd-v1.0.1) (2026-07-07)


### Bug Fixes

* **cd:** image scan reports to Security tab instead of blocking release ([5d3e90d](https://github.com/taovietducofficial/CI-CD/commit/5d3e90d0a3eab7072d33ceaeb2d5b307eaf2f414))
* **cd:** lowercase image ref for cosign/scan/deploy ([5e88a4b](https://github.com/taovietducofficial/CI-CD/commit/5e88a4b87a2b6d690b8f46c7d0521fe5d2479418))
* **cd:** make image scan advisory (non-blocking), drop flaky SARIF upload ([e16fb40](https://github.com/taovietducofficial/CI-CD/commit/e16fb409ac37e29ae3e3fd79827eb3a281f6539a))
* **ci:** pin trivy-action to valid tag v0.36.0 ([1f8282d](https://github.com/taovietducofficial/CI-CD/commit/1f8282d5d79dae94534d7a599d420b2c876239f8))
* **ci:** reusable workflow inherits caller permissions to fix CD startup_failure ([d9526ab](https://github.com/taovietducofficial/CI-CD/commit/d9526abc76f957f39ac8c6b4fb3b84e6e0ba0c6a))
* **docker:** base image node:20-alpine -&gt; node:22-alpine (LTS) ([8ccd44b](https://github.com/taovietducofficial/CI-CD/commit/8ccd44be927f4958110ce0cd248942514ba2e0aa))


### Documentation

* add "Dùng cho project mới" guide (template repo + checklist) ([0d4345e](https://github.com/taovietducofficial/CI-CD/commit/0d4345e15dc0b8ad30f2284e7911cafc2577555f))
