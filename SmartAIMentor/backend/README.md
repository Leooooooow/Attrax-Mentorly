# SmartAIMentor 后端

这是Attrax - Mentorly 的 FastAPI 后端服务，负责 Chat 驱动的自动发布流程，以及前端 UI 所需的数据接口。

## 启动

```bash
python3 -m venv .venv
.venv/bin/pip install -r backend/requirements.txt
backend/run.sh
```

本地服务地址：`http://localhost:58888`

健康检查：

```bash
curl http://localhost:58888/api/health
```

## 已暴露接口

Chat 与发布：

- `POST /api/chat`
- `POST /api/publish`
- `GET /api/tasks`
- `GET /api/tasks/{task_id}`

前端 UI 数据契约：

- `GET /api/v1/mentor/header-card`
- `GET /api/v1/holding-today/{creator_id}`
- `GET /api/v1/persona/{creator_id}`
- `POST /api/v1/trends/recommend`
- `POST /api/v1/posts/recommend`

前端对接细节见 `docs/frontend_backend_api.md`。

## 运行环境变量

真实值写入项目根目录 `.env`，不要提交，也不要发给前端。

```env
GEMINI_API_KEY=...
POST_BRIDGE_API_KEY=...
POST_BRIDGE_BASE_URL=https://api.post-bridge.com
POST_BRIDGE_VIDEO_COVER_TIMESTAMP_MS=3000
POST_BRIDGE_TIKTOK_DRAFT=false
POST_BRIDGE_TIKTOK_IS_AIGC=false
POST_BRIDGE_INSTAGRAM_IS_TRIAL_REEL=false
```

可选代理配置：

```env
HTTPS_PROXY=
HTTP_PROXY=
ALL_PROXY=
```

前端只需要配置：

```env
MENTORAIX_API_BASE_URL=http://localhost:58888

# Optional: 覆盖后端启动端口（默认 58888）
MENTORAIX_API_PORT=58888
```

## 验证

```bash
PYTHONPATH=backend .venv/bin/pytest backend/tests -q
python3 -m compileall -q backend/app
ffmpeg -version
ffprobe -version
```

多平台视频发布使用 `POST /api/publish` 的 `platforms` 字段，例如 `platforms=x,instagram,tiktok`。视频相关表单字段见 `docs/frontend_backend_api.md`。
