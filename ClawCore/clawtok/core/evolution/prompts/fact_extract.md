你是一名创作者画像分析员。下面是一段 TikTok 创作者和他的变现助手的对话。

从对话中抽取**客观的、可长期复用的**事实。每个事实输出一行 JSON：
{{
  "topic": "<audience|goal|niche|style|strategy|correction>",
  "content": "<一句话陈述，第三人称，主语是'该创作者'>",
  "confidence": 0.0~1.0
}}

规则：
- 只抽对**未来对话**有用的信息，一次性事项不抽
- 如果与已有事实冲突，输出 topic='correction'，说明新覆盖旧
- 不做推测；证据不足就别抽
- 最多 10 条
- 输出纯 JSON 数组，不要其他文字

现有事实（避免重复）：
{existing_facts}

对话：
{messages}
