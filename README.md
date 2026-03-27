# ClubContentReview

深求社区内容审核器 - 由阿里云内容审核提供支持

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

覆盖范围：帖子、回复、用户注册、昵称/用户名修改、头像修改。

- `PASS`：直接发布
- `REVIEW`：进入 Discourse Review Queue
- `REJECT`：直接拦截
- 网关异常：按 `REVIEW` 兜底

## 运维最短路径

1. 先读 `docs/deploy/DEPLOYMENT_GUIDE.md`
2. 部署 `deliverables/moderation-gateway`
3. 安装 `deliverables/discourse-aliyun-moderation`
4. 在后台开启：
- `aliyun_moderation_enabled = true`
- `aliyun_moderation_profile_enabled = true`
