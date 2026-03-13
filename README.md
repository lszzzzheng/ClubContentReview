# ClubContentReview

Discourse + 阿里云图文混合审核的落地骨架工程。

## 目录
- `test_multimodal.py`：阿里云图文混合 API 直连测试脚本
- `gateway/app.py`：审核网关（对外提供 `/moderate`）
- `docs/IMPLEMENTATION.md`：给你自己的实施说明
- `ops/OPS_TODO.md`：给运维的分步骤清单
- `plugin_sample/aliyun_moderation_service.rb`：Discourse 插件调用网关示例
- `scripts/run_gateway.sh`：本地启动网关
- `scripts/test_gateway.sh`：本地调用网关测试

## 快速开始
```bash
cd /Users/lsz/工作/有智时代/ClubContentReview
source .venv/bin/activate
export ALIBABA_CLOUD_ACCESS_KEY_ID='你的AK'
export ALIBABA_CLOUD_ACCESS_KEY_SECRET='你的SK'
export ALIBABA_CLOUD_REGION_ID='cn-shanghai'
export ALIBABA_CLOUD_ENDPOINT='green-cip.cn-shanghai.aliyuncs.com'
./scripts/run_gateway.sh
```

另开终端测试：
```bash
cd /Users/lsz/工作/有智时代/ClubContentReview
./scripts/test_gateway.sh
```

## 三态决策
- `risk_level=none` -> `PASS`
- `risk_level=low|medium` -> `REVIEW`
- `risk_level=high` -> `REJECT`
- 接口异常 -> `REVIEW`（保守兜底）
