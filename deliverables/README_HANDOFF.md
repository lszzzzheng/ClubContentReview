# 交付说明

## 给运维的最小交付集合

1. `deliverables/moderation-gateway`
2. `deliverables/discourse-aliyun-moderation`
3. `docs/deploy/DEPLOYMENT_GUIDE.md`

## 10 分钟验收目标

1. 网关健康检查通过：`GET /healthz`
2. 帖子场景调用返回 `decision`
3. profile 场景调用返回 `decision`
4. Discourse 后台看到插件并可配置
5. 开启以下开关：
- `aliyun_moderation_enabled = true`
- `aliyun_moderation_profile_enabled = true`

按 `DEPLOYMENT_GUIDE.md` 从上到下执行即可。
