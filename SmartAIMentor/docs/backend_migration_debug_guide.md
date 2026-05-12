# SmartAIMentor 后端接口迁移调试指南

本文面向“把当前后端服务挪到主仓库继续联调”的场景，目标是用最少步骤复现当前可工作的接口能力。

## 1. 迁移目标

迁移后需要确保以下能力不变：

1. 健康检查可用：`GET /api/health`
2. Chat 接口可用：`POST /api/chat`
3. 直接发布接口可用：`POST /api/publish`
4. 任务查询接口可用：`GET /api/tasks`、`GET /api/tasks/{task_id}`
5. 前端契约接口可用：`/api/v1/*`

## 2. 必迁文件与目录

建议按下面的“最小可运行集合”迁移。

### 2.1 后端代码（必须）

- `backend/app/`（全部）
- `backend/requirements.txt`
- `backend/run.sh`

### 2.2 运行时数据目录（必须保留结构）

- `backend/data/tasks.json`（任务状态持久化）
- `backend/data/uploads/`（上传文件目录）

说明：

- `tasks.json` 不存在时可自动创建，但建议迁移时显式保留目录结构。
- `uploads/` 为空也可以，启动后会自动创建。

### 2.3 对接文档（建议同步到主仓库）

- `docs/frontend_backend_api.md`（前后端字段与示例）
- 本文档 `docs/backend_migration_debug_guide.md`

## 3. 环境变量配置

后端通过 `backend/app/config.py` 读取项目根目录 `.env`。可基于根目录 `.env.example` 生成。

### 3.1 必填变量

```env
GEMINI_API_KEY=
POST_BRIDGE_API_KEY=
```

### 3.2 推荐保留默认值

```env
POST_BRIDGE_BASE_URL=https://api.post-bridge.com

POST_BRIDGE_VIDEO_COVER_TIMESTAMP_MS=3000
POST_BRIDGE_TIKTOK_DRAFT=false
POST_BRIDGE_TIKTOK_IS_AIGC=false
POST_BRIDGE_INSTAGRAM_IS_TRIAL_REEL=false
```

### 3.3 可选代理

```env
HTTPS_PROXY=
HTTP_PROXY=
ALL_PROXY=
```

### 3.4 前端侧变量（仅前端使用）

```env
MENTORAIX_API_BASE_URL=http://localhost:58888
```

## 4. 安装与启动

在主仓库中保持与当前仓库一致的相对路径最省事（推荐保留 `backend/` 目录名）。

```bash
python3 -m venv .venv
.venv/bin/pip install -r backend/requirements.txt
backend/run.sh
```

启动后默认地址：`http://localhost:58888`

## 5. 快速联调验证

### 5.1 健康检查

```bash
curl http://localhost:58888/api/health
```

预期：

```json
{"status":"ok"}
```

### 5.2 v1 合同接口

```bash
curl http://localhost:58888/api/v1/mentor/header-card
curl http://localhost:58888/api/v1/holding-today/lana
curl http://localhost:58888/api/v1/persona/lana
```

### 5.3 发布链路（图片）

```bash
curl -X POST http://localhost:58888/api/publish \
  -F "platform=x" \
  -F "creator_id=lana" \
  -F "caption=publish smoke test" \
  -F "hashtags=ai,mentor" \
  -F "file=@./demo.png"
```

然后查询任务状态：

```bash
curl "http://localhost:58888/api/tasks?creator_id=lana&limit=10"
```

### 5.4 发布链路（多平台视频）

```bash
curl -X POST http://localhost:58888/api/publish \
  -F "platforms=x,instagram,tiktok" \
  -F "creator_id=lana" \
  -F "caption=video smoke test" \
  -F "hashtags=ai,workflow" \
  -F "video_cover_timestamp_ms=3000" \
  -F "tiktok_draft=false" \
  -F "tiktok_is_aigc=false" \
  -F "instagram_is_trial_reel=false" \
  -F "processing_enabled=true" \
  -F "is_draft=true" \
  -F "file=@./demo.mp4"
```

## 6. 回归测试（推荐）

在项目根目录执行：

```bash
PYTHONPATH=backend .venv/bin/pytest backend/tests -q
```

覆盖点：

- 路由是否暴露完整
- `/api/v1/*` 返回结构是否稳定
- 视频多平台发布参数是否正确透传到 Post Bridge payload

## 7. 关键实现说明（迁移时最容易漏）

1. 任务状态是异步写入：
   - `POST /api/publish` 和发布型 `POST /api/chat` 会先返回 `publishing`
   - 真实发布结果需要再查 `/api/tasks` 或 `/api/tasks/{task_id}`

2. 上传和任务文件路径默认在 `backend/data`：
   - `upload_dir` 默认 `backend/data/uploads`
   - `tasks_file` 默认 `backend/data/tasks.json`

3. CORS 当前是全开放（开发模式）：
   - `allow_origins=["*"]`

4. Chat 走 Gemini，发布走 Post Bridge：
   - 没配 `GEMINI_API_KEY` 会影响 `/api/chat` 的意图识别
   - 没配 `POST_BRIDGE_API_KEY` 会影响 `/api/publish` 和发布型 chat

5. 视频联调建议安装工具链：
   - `ffmpeg`
   - `ffprobe`

## 8. 主仓库落地清单（可打勾）

- [ ] 已迁移 `backend/app`、`backend/requirements.txt`、`backend/run.sh`
- [ ] 已创建主仓库根目录 `.env` 并填入密钥
- [ ] 已确认 `backend/data/tasks.json` 与 `backend/data/uploads/` 可写
- [ ] 健康检查 `/api/health` 返回 `{"status":"ok"}`
- [ ] 前端可通过 `MENTORAIX_API_BASE_URL` 访问后端
- [ ] `pytest backend/tests -q` 通过

## 9. 推荐同步到主仓库的说明文档

1. 对前端同学：保留 `docs/frontend_backend_api.md`
2. 对后端同学：保留本文档，作为迁移和联调 runbook
