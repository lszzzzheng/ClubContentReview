# ClubContentReview

这个仓库是给运维直接部署用的交付仓库，只保留正式交付物和部署说明。

## 先看哪里

1. `docs/deploy/DEPLOYMENT_GUIDE.md`
2. `deliverables/discourse-aliyun-moderation`
3. `deliverables/moderation-gateway`

## 目录说明

- `deliverables/discourse-aliyun-moderation`：可直接安装到 Discourse 的插件目录
- `deliverables/moderation-gateway`：可直接部署的审核网关
- `deliverables/README_HANDOFF.md`：交接说明
- `docs/deploy/DEPLOYMENT_GUIDE.md`：完整部署教程

## 审核逻辑

- `PASS`：直接发布
- `REVIEW`：进入 Discourse Review Queue
- `REJECT`：直接拦截
- 网关异常：按 `REVIEW` 兜底
