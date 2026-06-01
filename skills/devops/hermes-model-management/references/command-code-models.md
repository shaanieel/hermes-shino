# Command Code Provider API — Models & Endpoints

Source: https://commandcode.ai/docs/provider-api (verified 2026-05-26)

## Endpoints

| Endpoint | Method | Format |
|---|---|---|
| `https://api.commandcode.ai/provider/v1/chat/completions` | POST | OpenAI Chat Completions |
| `https://api.commandcode.ai/provider/v1/messages` | POST | Anthropic Messages |
| `https://api.commandcode.ai/provider/v1/models` | GET | Models list |

Auth: `Authorization: Bearer <token>` (all routes) or `x-api-key: <token>` (Anthropic SDK on /messages).
Requires Pro plan or higher.

## Model catalog (live, as of 2026-05-26)

| ID | Name | Context |
|---|---|---|
| `claude-sonnet-4-6` | Claude Sonnet 4.6 | 1M |
| `claude-opus-4-7` | Claude Opus 4.7 | 1M |
| `claude-haiku-4-5-20251001` | Claude Haiku 4.5 | 200K |
| `gpt-5.5` | GPT-5.5 | 200K |
| `gpt-5.4` | GPT-5.4 | 400K |
| `gpt-5.3-codex` | GPT-5.3 Codex | 400K |
| `gpt-5.4-mini` | GPT-5.4 Mini | 400K |
| `moonshotai/Kimi-K2.6` | Kimi K2.6 | 256K |
| `moonshotai/Kimi-K2.5` | Kimi K2.5 | 256K |
| `zai-org/GLM-5.1` | GLM-5.1 | 200K |
| `zai-org/GLM-5` | GLM-5 | 200K |
| `MiniMaxAI/MiniMax-M2.7` | MiniMax M2.7 | 200K |
| `MiniMaxAI/MiniMax-M2.5` | MiniMax M2.5 | 200K |
| `deepseek/deepseek-v4-pro` | DeepSeek V4 Pro | 1M |
| `deepseek/deepseek-v4-flash` | DeepSeek V4 Flash | 1M |
| `Qwen/Qwen3.6-Max-Preview` | Qwen 3.6 Max Preview | 200K |
| `Qwen/Qwen3.6-Plus` | Qwen 3.6 Plus | 200K |
| `Qwen/Qwen3.7-Max` | Qwen 3.7 Max | 1M |
| `stepfun/Step-3.5-Flash` | Step 3.5 Flash | 1M |
| `xiaomi/mimo-v2.5-pro` | MiMo V2.5 Pro | 1M |
| `xiaomi/mimo-v2.5` | MiMo V2.5 | 1M |
| `google/gemini-3.5-flash` | Gemini 3.5 Flash | 1M |
| `google/gemini-3.1-flash-lite` | Gemini 3.1 Flash Lite | 1M |

Claude models must use the `/v1/messages` Anthropic endpoint. All others use `/v1/chat/completions`.

## Streaming

Both endpoints support streaming (`stream: true`). Token usage emitted at end of every stream — OpenAI clients see final usage chunk, Anthropic see `message_delta` event.

## Error reference

| Status | Code/Type | When |
|---|---|---|
| 400 | `unsupported_model` | Model not in catalog (OpenAI shape only) |
| 400 | `invalid_request_error` | Wrong endpoint for model, bad body, malformed JSON |
| 401 | `authentication_error` | Missing/invalid auth |
| 403 | `upgrade_required` | Need Pro plan or higher |
| 429 | `rate_limit_error` | Upstream rate limited |
| 5xx | `server_error`/`api_error` | Upstream failure |
