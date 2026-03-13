# discourse-aliyun-moderation

Discourse 插件：在创建帖子/回复前调用外部审核网关，按 `PASS/REVIEW/REJECT` 分流。

## 依赖
- Discourse 3.2+
- 可访问的审核网关（本仓库 `moderation-gateway`）

## 站点设置
安装后在 Admin -> Settings -> Plugins 搜索 `aliyun moderation`：
- `aliyun_moderation_enabled`
- `aliyun_moderation_gateway_url`
- `aliyun_moderation_timeout_ms`
- `aliyun_moderation_fail_safe_mode`
- `aliyun_moderation_include_context_posts`

## 行为
- PASS: 放行发布
- REVIEW: 写入 Review Queue（`ReviewableQueuedPost`）并阻断即时发布
- REJECT: 拒绝发布

网关失败时默认走 REVIEW（可通过设置改为 pass）。
