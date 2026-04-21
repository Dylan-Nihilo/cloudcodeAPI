# GitHub Image Deployment Flow

目标：本地只负责改代码和排查；GitHub Actions 负责构建 `sub2api` 镜像；服务器只 `git pull` 配置并运行 GHCR 镜像。

## 1. GitHub 仓库

- 仓库：`https://github.com/Dylan-Nihilo/cloudcodeAPI.git`
- 生产镜像：`ghcr.io/dylan-nihilo/cloudcodeapi:main`
- Actions workflow：`.github/workflows/build-sub2api-image.yml`

## 2. 日常发布

1. 本地修复并验证
2. `git push origin main`
3. 等 GitHub Actions 完成镜像构建
4. 服务器执行：

```bash
cd /opt/proxy-api
git pull
./scripts/deploy.sh
```

## 3. 服务器要求

- `.env` 里必须有：
  - `SUB2API_IMAGE=ghcr.io/dylan-nihilo/cloudcodeapi:main`
  - `DOMAIN`
  - `ACME_EMAIL`
  - `POSTGRES_PASSWORD`
  - `JWT_SECRET`
  - `TOTP_ENCRYPTION_KEY`
  - `ADMIN_EMAIL`
  - `ADMIN_PASSWORD`
- 如果 GHCR package 是 private，再额外配置：
  - `GHCR_USERNAME`
  - `GHCR_TOKEN`

## 4. 故障定位

- 看应用日志：

```bash
docker logs --since 20m sub2api
```

- 看反代日志：

```bash
docker logs --since 20m caddy
```

- 看当前运行镜像：

```bash
docker inspect -f '{{.Config.Image}}' sub2api
```

## 5. 说明

- 服务器不再本地 `docker build`
- 发布时 `scripts/deploy.sh` 会先拉取 `SUB2API_IMAGE`，再重建 `sub2api`
- `postgres`、`redis`、`caddy` 仍由 `docker-compose.prod.yml` 管理
