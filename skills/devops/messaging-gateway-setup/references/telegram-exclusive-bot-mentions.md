# Telegram `exclusive_bot_mentions` — Multi-Bot Group Routing

## What It Does

`exclusive_bot_mentions` (default `true`) makes Hermes profiles in the same
Telegram group **route by explicit `@botname` mention**. When a user message
contains one or more `@botusernames`, only the mentioned bot profiles process it
— other Hermes bots ignore it entirely. This prevents every bot from answering
when the user only intended to talk to one of them.

It is enabled by default and applies BEFORE `require_mention` and
`mention_patterns` (wake-word) fallbacks run.

## Three Independent Gating Settings

These stack — all three can be active simultaneously:

| Setting | Scope | What It Does |
|---|---|---|
| `exclusive_bot_mentions` | Multi-bot group routing | Only the explicitly @mentioned bot profile(s) process the message |
| `require_mention` | Single-bot dispatch | Ignores messages not replying-to, @-mentioning, or /command@mentioning THIS bot |
| `mention_patterns` | Wake-word fallback | Regex patterns that count as a "mention" even without an @username |

Recommended multi-bot config:

```yaml
telegram:
  require_mention: true
  exclusive_bot_mentions: true
  mention_patterns: []
```

## Per-Bot `mention_patterns`

Each profile can set regex patterns specific to its bot identity:

```yaml
# Reviewer profile
telegram:
  mention_patterns:
    - '@ShinoReviewBot'
    - '@ShinoReview'

# Designer profile
telegram:
  mention_patterns:
    - '@ShinoDesignBot'
    - '@ShinoDesign'
```

These are wake words — mentioning `@ShinoReview` in a regular message (not a
Telegram @-mention) still triggers the reviewer bot.

## Telegram API Limitation: Bot-to-Bot Messages

**Telegram bots CANNOT read messages sent by other bots.** This is a Telegram
API restriction, not a Hermes config issue. No amount of `exclusive_bot_mentions`
or `mention_patterns` tuning will make it work.

When DesignerBot sends `@ShinoReviewBot review this`, Telegram API drops the
message before any Hermes gateway sees it. The reviewer gateway never receives
the mention.

### Bot API 10.0 `allow_bot_to_bot` (May 2026)

BotFather added a `allow_bot_to_bot` toggle in Bot Settings. In theory this
should let bots read messages from other bots. In practice (tested 2026-05-29
with PTB 22.6, bot-to-bot ON, kick/re-add done):

- Main gateway (ShinoBot): sent `/model@ShinoReviewBot` via `send_message`
- Reviewer gateway (ShinoReviewBot): **zero inbound messages** after the test
- The message was visible in the group UI but the Telegram API never delivered
  it to the reviewer bot

This may be a PTB 22.6 compatibility issue (Bot API 10.0 needs ≥ 22.7) or
the feature may not work as documented. Until proven otherwise, assume
bot-to-bot message delivery does NOT work.

### Testing Methodology: Prove Bot-to-Bot Delivery

To test whether the other bot's gateway receives messages from this bot:

```bash
# 1. Send a test message from bot A via send_message tool
#    (e.g. "/model@ShinoReviewBot" to the shared group)

# 2. Wait 8-10 seconds, then check bot B's gateway log:
grep "inbound message" ~/.hermes/profiles/reviewer/logs/gateway.log | tail -5

# 3. If the test message appears → bot-to-bot works
#    If only user messages appear → Telegram API is still filtering
```

The test message must be recent enough to appear in `tail -5`. If the log shows
zero inbound messages from the bot but normal messages from the human user,
bot-to-bot delivery is confirmed broken (not a Hermes config issue).

**Workarounds:**

1. **Bridge via the default (free-response) bot.** The main ShinoBot (no mention
   gating) can read ANY group message and forward/trigger other bots using
   `send_message`. This acts as a human-in-the-loop bridge.

2. **Use platform that allows it.** Discord allows bots to read messages from
   other bots — multi-bot auto-collaboration works natively there.

3. **Cron-based polling.** Designer writes output to a known location → cronjob
   picks it up → reviewer processes it → delivers result when score ≥ threshold.

## Config Verification

Check all profiles at once:

```bash
python3 - <<'PY'
import yaml
profiles = {
    'default': '~/.hermes/config.yaml',
    'designer': '~/.hermes/profiles/designer/config.yaml',
    'reviewer': '~/.hermes/profiles/reviewer/config.yaml',
}
for name, path in profiles.items():
    with open(os.path.expanduser(path)) as f:
        tg = yaml.safe_load(f).get('telegram', {})
    print(f"{name}: require_mention={tg.get('require_mention')}, "
          f"exclusive_bot_mentions={tg.get('exclusive_bot_mentions', 'default(true)')}, "
          f"mention_patterns={tg.get('mention_patterns')}")
PY
```

## Pitfall: Fallback Crash Masks as Mention Bug

When a profile gateway crashes on startup (e.g. `fallback_model.provider:
custom:commandcode` hitting 404 on `/responses`), the crash-restart cycle
produces stale join state. The symptom is identical to "all bots answer
everything" — check `ps aux | grep gateway` for uptime and grep logs for
`NotFoundError` before concluding mention gating is broken.
