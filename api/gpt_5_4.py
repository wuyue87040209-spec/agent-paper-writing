"""
GPT-5.4 chat completions API 函数（通过 TiMi CC 中转网关）。

用法（作为模块导入）：
    from api.gpt_5_4 import chat

    # 1) 普通对话
    resp = chat([{"role": "user", "content": "你好"}])
    print(resp["choices"][0]["message"]["content"])

    # 2) Function Calling
    resp = chat(
        messages=[{"role": "user", "content": "上海今天天气？"}],
        tools=[{
            "type": "function",
            "function": {
                "name": "get_weather",
                "description": "获取指定城市的当前天气",
                "parameters": {
                    "type": "object",
                    "properties": {"city": {"type": "string"}},
                    "required": ["city"],
                },
            },
        }],
        tool_choice="auto",
    )

    # 3) 多轮对话（含 tool 角色与 assistant.tool_calls）
    resp = chat(messages=[
        {"role": "user", "content": "上海今天天气？"},
        {"role": "assistant", "content": None,
         "tool_calls": [{"id": "call_1", "type": "function",
                         "function": {"name": "get_weather",
                                      "arguments": '{"city": "上海"}'}}]},
        {"role": "tool", "tool_call_id": "call_1",
         "content": '{"city": "上海", "temp": 22, "weather": "晴"}'},
    ])

测试：
    python api/gpt_5_4.py
"""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

# 把项目根加入 sys.path，以便 import scripts.call_gpt_chat
ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.call_gpt_chat import (  # noqa: E402
    DEFAULT_CONFIG_PATH,
    LLMClient,
    LLMConfig,
    load_config,
)

# 接口约定的固定模型名（按需求钉死为 gpt-5.4）
PINNED_MODEL = "gpt-5.4"


# ---------------------------------------------------------------------------
# 内部：单例客户端（复用 yaml 配置 + 钉死 model）
# ---------------------------------------------------------------------------

def _build_pinned_config() -> LLMConfig:
    """读取 yaml 配置并强制覆盖 model=gpt-5.4。"""
    cfg = load_config(DEFAULT_CONFIG_PATH)
    return LLMConfig(**{**cfg.__dict__, "model": PINNED_MODEL})


_client: LLMClient | None = None


def _get_client() -> LLMClient:
    global _client
    if _client is None:
        _client = LLMClient(config=_build_pinned_config())
    return _client


# ---------------------------------------------------------------------------
# 公开 API
# ---------------------------------------------------------------------------

def chat(
    messages: list[dict[str, Any]],
    *,
    tools: list[dict[str, Any]] | None = None,
    tool_choice: Any = None,
    temperature: float | None = None,
    max_completion_tokens: int | None = None,
    top_p: float | None = None,
    reasoning_effort: str | None = None,
    **extra: Any,
) -> dict[str, Any]:
    """调用 GPT-5.4 chat completions，返回完整 OpenAI 格式响应。

    Parameters
    ----------
    messages : list[dict]
        标准 OpenAI messages 数组。支持以下 role：
        - system / user / assistant
        - assistant 带 ``tool_calls`` 字段（function calling 回包）
        - tool 带 ``tool_call_id`` 字段（工具执行结果回传）
    tools : list[dict], optional
        OpenAI tools 定义数组（用于 function calling / tool use）
    tool_choice : optional
        ``"auto"`` / ``"none"`` / ``"required"`` 或
        ``{"type": "function", "function": {"name": "..."}}``
    temperature / top_p / max_completion_tokens : optional
        标准采样参数
    reasoning_effort : {"low", "medium", "high"}, optional
        GPT-5 推理强度（TiMi CC 使用嵌套格式 ``reasoning.effort``）
    **extra
        其他任意 OpenAI 参数透传（例如 ``response_format``、``seed`` 等）

    Returns
    -------
    dict
        OpenAI ``chat.completion`` 完整响应 JSON

    Raises
    ------
    RuntimeError
        网关或上游返回 4xx/5xx 时抛出
    ValueError / FileNotFoundError
        yaml 配置缺失或 API Key 未配置时抛出
    """
    client = _get_client()
    # 通过 LLMClient.build_payload 组装请求，tools/tool_choice 走 **extra 透传
    payload = client.config.build_payload(
        messages,
        temperature=temperature,
        max_completion_tokens=max_completion_tokens,
        top_p=top_p,
        reasoning_effort=reasoning_effort,
        stream=False,
        tools=tools,
        tool_choice=tool_choice,
        **extra,
    )

    resp = client._post(payload)  # 复用 5xx 重试逻辑
    if resp.status_code >= 400:
        raise RuntimeError(
            f"LLM 接口返回错误 {resp.status_code}: {resp.text[:500]}"
        )
    return resp.json()


# ---------------------------------------------------------------------------
# 测试入口
# ---------------------------------------------------------------------------

def main() -> None:
    """演示 chat() 的三种典型用法：普通对话、Function Calling、多轮 tool。"""
    import json

    print("=" * 60)
    print("Test 1 · 普通对话")
    print("=" * 60)
    resp = chat(
        [{"role": "user", "content": "用一句话介绍你自己"}],
        max_completion_tokens=80,
    )
    print("model :", resp["model"])
    print("reply :", resp["choices"][0]["message"]["content"])
    print("usage :", resp["usage"])
    print()

    print("=" * 60)
    print("Test 2 · Function Calling（让模型自行决定是否调用工具）")
    print("=" * 60)
    weather_tool = {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "获取指定城市的当前天气",
            "parameters": {
                "type": "object",
                "properties": {
                    "city": {"type": "string", "description": "城市名称，如上海"},
                },
                "required": ["city"],
            },
        },
    }
    calc_tool = {
        "type": "function",
        "function": {
            "name": "calculate",
            "description": "计算数学表达式",
            "parameters": {
                "type": "object",
                "properties": {
                    "expression": {"type": "string"},
                },
                "required": ["expression"],
            },
        },
    }
    resp = chat(
        [{"role": "user", "content": "上海今天天气怎么样？"}],
        tools=[weather_tool, calc_tool],
        tool_choice="auto",
        max_completion_tokens=300,
    )
    msg = resp["choices"][0]["message"]
    print("model        :", resp["model"])
    print("content      :", msg.get("content"))
    print("tool_calls   :", json.dumps(msg.get("tool_calls"), ensure_ascii=False, indent=2))
    print("finish_reason:", resp["choices"][0].get("finish_reason"))
    print()

    print("=" * 60)
    print("Test 3 · 多轮对话（assistant.tool_calls + tool 角色回传结果）")
    print("=" * 60)
    tool_call_id = "call_demo_001"
    messages = [
        {"role": "user", "content": "上海今天天气怎么样？顺便帮我算一下 (15 + 27) * 2"},
        {
            "role": "assistant",
            "content": None,
            "tool_calls": [
                {
                    "id": tool_call_id,
                    "type": "function",
                    "function": {
                        "name": "get_weather",
                        "arguments": json.dumps({"city": "上海"}, ensure_ascii=False),
                    },
                },
            ],
        },
        {
            "role": "tool",
            "tool_call_id": tool_call_id,
            "content": json.dumps(
                {"city": "上海", "temperature": 23, "weather": "多云转晴"},
                ensure_ascii=False,
            ),
        },
    ]
    resp = chat(messages, max_completion_tokens=200)
    print("model :", resp["model"])
    print("reply :", resp["choices"][0]["message"]["content"])


if __name__ == "__main__":
    main()