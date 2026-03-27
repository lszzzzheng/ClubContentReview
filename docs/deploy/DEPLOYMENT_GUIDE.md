# Discourse + 阿里云图文审核：运维部署手册（可直接执行）

本文档目标：让运维同事在拿到仓库后，按步骤完成
1) 审核网关部署
2) Discourse 插件安装
3) 帖子+资料审核联调验收
4) 回滚

---

## A. 交付目录说明

如果运维拿到的是整个仓库，直接使用下面两个目录即可：
- `deliverables/moderation-gateway`
- `deliverables/discourse-aliyun-moderation`

如果只单独发文件，也至少要带上：
- `deliverables/README_HANDOFF.md`
- `docs/deploy/DEPLOYMENT_GUIDE.md`

---

## B. 服务器前提

1. Discourse 已按官方 Docker 方式部署（`/var/discourse`）
2. 有一台可运行 Docker 的服务器部署网关（可与 Discourse 同机）
3. 推荐：Discourse 与网关在同一 VPC 内网互通
4. 已准备新的 AK/SK（旧泄露密钥必须已删除）

### B1. 上线前 5 分钟检查清单
1. Git 仓库分支是最新 `main`
2. `.env` 已填写 AK/SK，且没有把 `.env` 提交到仓库
3. 网关地址可从 Discourse 主机内网访问
4. Discourse 后台管理员账号可登录
5. 已准备回滚方案（可随时关闭 2 个站点开关）

---

## C. 部署审核网关（moderation-gateway）

### C1. 上传网关目录
将 `deliverables/moderation-gateway` 上传到服务器，例如：
- `/opt/moderation-gateway`

### C2. 配置环境变量
```bash
cd /opt/moderation-gateway
cp .env.example .env
```
编辑 `.env`：
- `ALIBABA_CLOUD_ACCESS_KEY_ID`
- `ALIBABA_CLOUD_ACCESS_KEY_SECRET`
- `ALIBABA_CLOUD_REGION_ID=cn-shanghai`
- `ALIBABA_CLOUD_ENDPOINT=green-cip-vpc.cn-shanghai.aliyuncs.com`（优先内网）
- `MODERATION_SERVICE=post_text_image_detection`
- `MODERATION_PROFILE_SERVICE=profile_text_image_detection`

### C3. 启动网关
```bash
cd /opt/moderation-gateway
docker compose up -d --build
```

### C4. 验证网关
```bash
curl -sS http://127.0.0.1:8080/healthz
```
期望返回：`{"ok": true, ...}`。

### C5. 连通性验证（从 Discourse 机器）
帖子场景：
```bash
curl -sS -X POST 'http://<网关内网IP>:8080/moderate' \
  -H 'Content-Type: application/json' \
  -d '{"scene":"post","title":"test","text":"hello","images":[]}'
```

资料场景（昵称+头像）：
```bash
curl -sS -X POST 'http://<网关内网IP>:8080/moderate' \
  -H 'Content-Type: application/json' \
  -d '{"scene":"profile","text":"normal nickname","images":["https://example.com/avatar.jpg"]}'
```
期望返回 JSON，包含 `decision` 字段。

### C6. 决策映射确认
1. `risk_level=none` -> `PASS`
2. `risk_level=low|medium` -> `REVIEW`
3. `risk_level=high` -> `REJECT`

---

## D. 安装 Discourse 插件（discourse-aliyun-moderation）

### D1. 上传插件目录
将 `deliverables/discourse-aliyun-moderation` 上传到 Discourse 主机并放到：
- `/var/discourse/plugins/discourse-aliyun-moderation`

目录必须包含 `plugin.rb`。

### D2. 重建 Discourse
```bash
cd /var/discourse
./launcher rebuild app
```

### D3. 后台检查
进入：`https://你的论坛/admin/plugins`
- 确认看到 `discourse-aliyun-moderation`

### D4. 配置插件设置
进入：`Admin -> Settings -> Plugins`，搜索 `aliyun moderation`，配置：
1. `aliyun_moderation_enabled = true`
2. `aliyun_moderation_profile_enabled = true`
3. `aliyun_moderation_gateway_url = http://<网关内网IP>:8080/moderate`
4. `aliyun_moderation_timeout_ms = 2000`
5. `aliyun_moderation_fail_safe_mode = review`
6. `aliyun_moderation_include_context_posts = 2`

---

## E. 联调验收步骤（帖子 + 资料）

### E1. 正常内容
发一条普通帖子，期望：直接发布（PASS）。

### E2. 可疑内容
发一条轻度风险内容，期望：进入 Review Queue（REVIEW）。

### E3. 明确违规
发一条明显违规内容，期望：被拒绝（REJECT）。

### E4. 故障兜底
临时停止网关：
```bash
cd /opt/moderation-gateway
docker compose stop
```
再发帖子，期望：进入审核队列（fail-safe=review）。

### E5. 注册与资料审核
1. 注册新用户（使用正常昵称），期望：可注册成功。
2. 修改昵称为明显违规内容，期望：保存被阻断并提示审核策略。
3. 上传明显违规头像，期望：更新被阻断并提示审核策略。

---

## F. 安全与权限建议

1. 网关仅开放内网访问，不暴露公网
2. AK/SK 只放服务器环境变量，不写代码仓库
3. 使用 RAM 子账号最小权限
4. 开启网关日志轮转，避免日志盘满

---

## G. 常见故障排查

1. `gateway_http_502`
- 网关访问阿里云失败，检查 AK/SK、Region、Endpoint

2. `Missing ALIBABA_CLOUD_ACCESS_KEY_ID`
- 网关 `.env` 未配置或未生效，重启容器

3. 插件不显示
- 插件目录层级错误或 `plugin.rb` 不在根目录
- 未执行 `./launcher rebuild app`

4. 发帖直接报错
- `aliyun_moderation_gateway_url` 不可达
- 查看容器日志：
```bash
cd /opt/moderation-gateway
docker compose logs -f
```

---

## H. 回滚流程（必须预案）

1. 先在 Discourse 后台关闭：`aliyun_moderation_enabled = false`
2. 再关闭：`aliyun_moderation_profile_enabled = false`
3. 若需彻底卸载插件：
- 删除 `/var/discourse/plugins/discourse-aliyun-moderation`
- 执行 `./launcher rebuild app`
4. 网关可保留或停止：
```bash
cd /opt/moderation-gateway
docker compose down
```

---

## I. 上线建议（风险控制）

1. 第 1 周：仅启用 PASS/REVIEW（业务侧不执行硬 REJECT）
2. 第 2 周：观察误杀率后再启用 REJECT
3. 每日抽样 20 条审核结果做人工复核

---

## J. 常见误配（优先排查）

1. `scene` 没传，导致 profile 流量走了帖子模型
2. `aliyun_moderation_profile_enabled` 没开，资料更新不会触发审核
3. 网关用公网地址但安全组没放通，表现为超时
4. 头像 URL 无法公网下载，阿里云侧会返回下载失败或超时
