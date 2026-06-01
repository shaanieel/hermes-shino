# Multi-Bot Mention Failure Diagnostics

Session transcript: three Hermes profiles running as separate Telegram bots in the same group. Despite `require_mention: true` in all three configs, all three bots answered every message — effectively acting as `require_mention: false`.

## The Bug

BotFather Privacy Mode acts as a pre-filter. With privacy **ON** (the default), Telegram only delivers to the bot:
- Messages that @mention the bot
- Replies to the bot
- Slash commands directed at the bot
- Service messages (bot added/removed)

So every message that reaches Hermes has already been classified by Telegram as "addressed to this bot." Hermes' `require_mention: true` filter then sees every incoming message as a mention and answers all of them — defeating the point of the filter.

## Diagnostic Path

1. **Check BotFather privacy state**: In BotFather → My Bots → @BotName → Bot Settings → Group Privacy. If it says "Turn On" (meaning it's currently OFF), that's correct. If it says "Turn Off" (meaning it's currently ON), that's the bug.

2. **Check Hermes config**: Both designer and reviewer profiles had `require_mention: true` and correct `allowed_chats`/`group_allowed_chats`. Config was not the problem.

3. **Check gateway processes**: Verified all three gateways running:
   ```
   PID 3096644 → ShinoBot (default profile, --replace)
   PID 3098299 → ShinoDesignBot (designer profile)
   PID 3098311 → ShinoReviewBot (reviewer profile)
   ```

4. **Restart gateways**: Killed designer + reviewer gateways, restarted both. This didn't fix the issue on its own because the Telegram join state was cached from before the privacy toggle.

## Fix (Three Steps)

1. **BotFather**: Turn Group Privacy OFF for every bot that should use `require_mention: true`.
2. **Telegram UI**: Kick and re-add each bot to the group. This forces Telegram to re-negotiate the privacy mode for the bot in that specific group chat.
   - **Same rule applies for ANY BotFather toggle change** — `allow_bot_to_bot`, Group Privacy, inline mode, etc. Telegram caches join-state at add time; toggles don't take effect until kick + re-add.
3. **Hermes**: Restart each bot's gateway so it picks up the new join state.

After these three steps, Hermes receives ALL group messages (not just mentions) and `require_mention: true` can filter properly.

## Verification

Test by sending a plain message without any mention. Only the bot with `require_mention: false` should respond. Bots with `require_mention: true` should stay silent.
