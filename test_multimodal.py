import json
import os
import time
import uuid

from alibabacloud_green20220302 import models as green_models
from alibabacloud_green20220302.client import Client as GreenClient
from alibabacloud_tea_openapi.models import Config


def build_client() -> GreenClient:
    access_key_id = os.getenv("ALIBABA_CLOUD_ACCESS_KEY_ID")
    access_key_secret = os.getenv("ALIBABA_CLOUD_ACCESS_KEY_SECRET")
    region_id = os.getenv("ALIBABA_CLOUD_REGION_ID", "cn-shanghai")
    endpoint = os.getenv("ALIBABA_CLOUD_ENDPOINT", "green-cip.cn-shanghai.aliyuncs.com")

    if not access_key_id or not access_key_secret:
        raise RuntimeError(
            "Missing credentials. Set ALIBABA_CLOUD_ACCESS_KEY_ID and "
            "ALIBABA_CLOUD_ACCESS_KEY_SECRET first."
        )

    config = Config(
        access_key_id=access_key_id,
        access_key_secret=access_key_secret,
        region_id=region_id,
        endpoint=endpoint,
        connect_timeout=3000,
        read_timeout=10000,
    )
    return GreenClient(config)


def submit_multimodal_task(client: GreenClient) -> str:
    image_url = os.getenv(
        "MOD_TEST_IMAGE_URL",
        "https://img.alicdn.com/imgextra/i1/O1CN01R6Qf6n1vY6Bv6vP9i_!!6000000006182-2-tps-1125-633.png",
    )
    test_text = os.getenv("MOD_TEST_TEXT", "草泥马。")
    test_title = os.getenv("MOD_TEST_TITLE", "论坛帖子审核测试")

    service_parameters = {
        "dataId": str(uuid.uuid4()),
        "mainData": {
            "mainTitle": test_title,
            "mainContent": test_text,
            "mainImages": [{"imageUrl": image_url}],
            "mainPostTime": time.strftime("%Y-%m-%d %H:%M:%S"),
        },
        "commentDatas": [],
    }

    request = green_models.MultimodalAsyncModerationRequest(
        service="post_text_image_detection",
        service_parameters=json.dumps(service_parameters, ensure_ascii=False),
    )
    response = client.multimodal_async_moderation(request)
    body = response.body.to_map()
    print("=== submit response ===")
    print(json.dumps(body, ensure_ascii=False, indent=2))

    req_id = body.get("Data", {}).get("ReqId")
    if not req_id:
        raise RuntimeError("Submit succeeded but no Data.ReqId found in response.")
    return req_id


def poll_result(client: GreenClient, req_id: str) -> dict:
    request = green_models.DescribeMultimodalModerationResultRequest(req_id=req_id)

    for index in range(1, 13):
        time.sleep(5)
        response = client.describe_multimodal_moderation_result(request)
        body = response.body.to_map()
        print(f"=== query #{index} ===")
        print(json.dumps(body, ensure_ascii=False, indent=2))

        data = body.get("Data")
        if data:
            return body

    raise RuntimeError("Timeout waiting for moderation result.")


def main() -> None:
    client = build_client()
    req_id = submit_multimodal_task(client)
    print(f"req_id={req_id}")
    result = poll_result(client, req_id)
    print("=== final result ===")
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
