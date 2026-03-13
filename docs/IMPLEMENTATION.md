# 图文混合审核实现手册（给你自己）

## 目标
把阿里云图文混合审核接到 Discourse 发帖/回复链路，输出三态：
- PASS：直接发布
- REVIEW：进入 Review Queue
- REJECT：直接拦截

## 当前仓库里已有内容
- `gateway/app.py`：审核网关（调用阿里云 + 三态映射）
- `gateway/requirements.txt`：网关依赖
- `test_multimodal.py`：你已跑通的阿里云直连验证脚本

## 第一步：本地跑网关
在当前目录执行：

```bash
source .venv/bin/activate
pip install -r gateway/requirements.txt
export ALIBABA_CLOUD_ACCESS_KEY_ID='你的AK'
export ALIBABA_CLOUD_ACCESS_KEY_SECRET='你的SK'
export ALIBABA_CLOUD_REGION_ID='cn-shanghai'
export ALIBABA_CLOUD_ENDPOINT='green-cip.cn-shanghai.aliyuncs.com'
python gateway/app.py
```

启动后会监听 `http://127.0.0.1:8080`。

## 第二步：调用网关测试
另开一个终端：

```bash
curl -sS -X POST 'http://127.0.0.1:8080/moderate' \
  -H 'Content-Type: application/json' \
  -d '{
    "title": "测试标题",
    "text": "这是一条论坛测试内容",
    "images": [
      "https://aliyun.com/240308/test001.jpg"
    ],
    "comments": []
  }' | jq
```

返回示例（关键字段）：
- `decision`: PASS / REVIEW / REJECT
- `risk_level`: none / low / medium / high
- `labels`: 命中标签

## 第三步：对接 Discourse 插件（由运维/开发执行）
Discourse 提交帖子/回复时，把内容 POST 到网关 `/moderate`，然后按返回 `decision` 分流。

分流规则：
- PASS -> 正常创建帖子
- REVIEW -> 创建待审核对象（Review Queue）
- REJECT -> 拦截提交，提示用户修改

## 建议策略
- API 异常（超时、限流、5xx）统一视为 `REVIEW`（保守兜底）
- 记录 `req_id`、`risk_level`、`labels` 到应用日志，方便排查
- 先灰度：1 周只做 REVIEW，不直接 REJECT；稳定后再开启 REJECT
