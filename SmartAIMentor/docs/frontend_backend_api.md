# SmartAIMentor 后端接口对接文档

本文档用于前端团队对接当前 `SmartAIMentor` 后端服务。当前阶段我们把这个仓库作为独立后端服务运行，统一对外暴露 Chat、自动发布、任务查询和 UI 数据接口。

## 基础地址

本地默认地址：

```env
MENTORAIX_API_BASE_URL=http://localhost:58888
```

前端只需要配置这个变量，并通过该基础地址调用下面所有接口。真实密钥只放在后端 `.env`，不要发给前端。

## 后端启动

```bash
python3 -m venv .venv
.venv/bin/pip install -r backend/requirements.txt
backend/run.sh
```

健康检查：

```bash
curl http://localhost:58888/api/health
```

预期返回：

```json
{"status":"ok"}
```

## Chat 与自动发布

### `POST /api/chat`

自动发布后端的主要 Chat 接口。它既支持普通对话，也支持从对话中识别发布意图。

请求使用 `multipart/form-data`，因为发布动作可能需要上传图片或视频文件。

请求字段：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `message` | string | 是 | 用户消息；后端会从文本中识别是否要发布、发到哪个平台等意图。 |
| `creator_id` | string | 否 | 创作者 ID，默认 `default`。 |
| `conversation_id` | string | 否 | 不传则后端创建新的会话 ID。 |
| `file` | file | 否 | 当用户希望后端发布媒体内容时传入。 |

示例：

```bash
curl -X POST http://localhost:58888/api/chat \
  -F "message=帮我把这个发到 X，语气自然一点" \
  -F "creator_id=lana" \
  -F "file=@./demo-cover.png"
```

发布类回复示例：

```json
{
  "reply": "好的！正在帮你发到 X，文案：...",
  "conversation_id": "conv_xxx",
  "action_taken": {
    "type": "publish",
    "platform": "x",
    "task_id": "pub_xxx"
  }
}
```

普通聊天时，`action_taken` 为 `null` 或不返回。

## 直接发布

### `POST /api/publish`

直接发布接口。适合前端已经拿到平台、文案和媒体文件的固定流程，例如 Create 页面的一键发布。

请求使用 `multipart/form-data`。

请求字段：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `file` | file | 是 | 图片或视频文件。 |
| `platform` | string | 否 | 默认 `x`；支持值包括 `x`、`twitter`、`instagram`、`tiktok`。 |
| `platforms` | string | 否 | 多平台发布时使用，逗号分隔，例如 `x,instagram,tiktok`；传了它会覆盖 `platform`。 |
| `creator_id` | string | 否 | 创作者 ID，默认 `default`。 |
| `caption` | string | 否 | 发布文案。 |
| `hashtags` | string | 否 | 逗号分隔的标签，例如 `ai,mentor,workflow`。 |
| `video_cover_timestamp_ms` | number | 否 | 视频封面帧时间，单位毫秒；默认走后端环境配置。 |
| `tiktok_draft` | boolean | 否 | TikTok 是否保存为草稿，默认走后端环境配置。 |
| `tiktok_is_aigc` | boolean | 否 | TikTok 是否标记为 AI 生成内容，默认走后端环境配置。 |
| `instagram_is_trial_reel` | boolean | 否 | Instagram 是否使用 Trial Reel，默认走后端环境配置。 |
| `processing_enabled` | boolean | 否 | 是否允许 Post Bridge 处理视频，默认 `true`。 |
| `is_draft` | boolean | 否 | 传 `true` 时只创建 Post Bridge 草稿，不直接处理发布；适合端到端联调。 |

示例：

```bash
curl -X POST http://localhost:58888/api/publish \
  -F "platform=instagram" \
  -F "creator_id=lana" \
  -F "caption=今天的内容发布测试" \
  -F "hashtags=ai,creator,workflow" \
  -F "file=@./demo-cover.png"
```

返回示例：

```json
{
  "task_id": "pub_xxx",
  "status": "publishing",
  "platform": "instagram",
  "platforms": ["instagram"],
  "skill_used": "post-bridge",
  "message": "发布任务已提交"
}
```

多平台视频发布示例：

```bash
curl -X POST http://localhost:58888/api/publish \
  -F "platforms=x,instagram,tiktok" \
  -F "creator_id=lana" \
  -F "caption=Mentoraix 多平台视频发布测试" \
  -F "hashtags=ai,creator,workflow" \
  -F "video_cover_timestamp_ms=3000" \
  -F "tiktok_draft=false" \
  -F "tiktok_is_aigc=false" \
  -F "instagram_is_trial_reel=false" \
  -F "processing_enabled=true" \
  -F "is_draft=false" \
  -F "file=@./demo-video.mp4"
```

返回示例：

```json
{
  "task_id": "pub_xxx",
  "status": "publishing",
  "platform": "x,instagram,tiktok",
  "platforms": ["x", "instagram", "tiktok"],
  "skill_used": "post-bridge",
  "message": "发布任务已提交"
}
```

### `GET /api/tasks`

查询最近的发布任务列表。

查询参数：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `creator_id` | string | 否 | 按创作者过滤。 |
| `limit` | number | 否 | 默认 `20`，最大 `100`。 |

示例：

```bash
curl "http://localhost:58888/api/tasks?creator_id=lana&limit=10"
```

### `GET /api/tasks/{task_id}`

按任务 ID 查询单个发布任务。

示例：

```bash
curl http://localhost:58888/api/tasks/pub_xxx
```

## UI 数据接口

下面这些接口是给当前前端 UI 用的 `/api/v1/*` 数据契约，避免前端继续依赖 Next.js 仓库里的 mock 层。

### `GET /api/v1/mentor/header-card`

返回导师顶部卡片数据。

返回示例：

```json
{
  "mentor_name": "Mentor M",
  "status": "listening",
  "last_listening_at": "2026-04-25T00:00:00Z",
  "hint": "Ready to turn creator signals into one focused next move."
}
```

### `GET /api/v1/holding-today/{creator_id}`

返回某个创作者今天应该关注的优先事项。

顶层字段：

- `creator_id`
- `generated_at`
- `headline`
- `action_hint`
- `priorities`

### `GET /api/v1/persona/{creator_id}`

返回创作者画像摘要。

顶层字段：

- `creator_id`
- `username`
- `display_name`
- `category`
- `primary_regions`
- `language_hint`
- `audience_signals`
- `content_pillars`
- `biography`
- `keyword_bag`
- `stats`

### `POST /api/v1/trends/recommend`

根据创作者和筛选条件返回趋势建议。

请求示例：

```json
{
  "creator_id": "lana",
  "limit": 3,
  "region": "Shenzhen",
  "categories": ["travel", "technology"]
}
```

返回示例：

```json
{
  "creator_id": "lana",
  "generated_at": "2026-04-25T00:00:00Z",
  "recommendations": []
}
```

### `POST /api/v1/posts/recommend`

根据候选创作者返回可参考的帖子建议。

请求示例：

```json
{
  "creator_id": "lana",
  "limit": 3,
  "candidate_creator_id": "holycathaha"
}
```

返回示例：

```json
{
  "creator_id": "lana",
  "candidate_creator_id": "holycathaha",
  "generated_at": "2026-04-25T00:00:00Z",
  "recommendations": []
}
```

## 后端运行配置

真实值写在后端 `.env` 中，不要把真实密钥交给前端。

```env
GEMINI_API_KEY=...
POST_BRIDGE_API_KEY=...
POST_BRIDGE_BASE_URL=https://api.post-bridge.com

# 视频发布默认配置
POST_BRIDGE_VIDEO_COVER_TIMESTAMP_MS=3000
POST_BRIDGE_TIKTOK_DRAFT=false
POST_BRIDGE_TIKTOK_IS_AIGC=false
POST_BRIDGE_INSTAGRAM_IS_TRIAL_REEL=false

# 可选：本地代理
HTTPS_PROXY=
HTTP_PROXY=
ALL_PROXY=
```

说明：

- `POST /api/chat` 使用 `GEMINI_API_KEY` 做意图识别和回复生成。
- 发布相关接口使用 `POST_BRIDGE_API_KEY` 调用 Post Bridge。
- 多平台视频发布会上传一次媒体，并在 Post Bridge 里创建一个绑定多个社交账号的发布任务。
- 前端只需要知道 `MENTORAIX_API_BASE_URL`。

## Skill 配置

后端工作区使用 ClawHub 的 `post-bridge-social-manager` skill：

```json
{
  "version": 1,
  "skills": {
    "post-bridge-social-manager": {
      "version": "1.0.7"
    }
  }
}
```

该 skill 声明的运行要求：

- 必需环境变量：`POST_BRIDGE_API_KEY`
- 必需二进制：`ffmpeg`

图片发布流程不依赖 `ffmpeg`；视频发布完整验证需要 `ffmpeg` 和 `ffprobe`，用于生成/检查测试视频以及满足 skill 声明的运行依赖。

如本机缺失：

```bash
brew install ffmpeg
```
