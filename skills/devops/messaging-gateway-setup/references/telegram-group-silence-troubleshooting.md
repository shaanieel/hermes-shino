# Telegram group silence troubleshooting

Use this reference when a Hermes Telegram bot answers in private chat but does not answer after being added to a group.

## Delivery gates

Telegram BotFather privacy mode is enabled by default. With privacy mode ON, Telegram does not deliver normal group messages to the bot. It delivers slash commands, replies to the bot, service messages, and messages in contexts where the bot is an admin/channel handler. With privacy mode OFF, the bot receives every group message.

To disable privacy mode: `@BotFather` -> `/mybots` -> select bot -> `Bot Settings` -> `Group Privacy` -> `Turn off`. After changing it, remove the bot from the group and add it again because Telegram caches the privacy state at join time. Alternatively, promote the bot to group admin so it receives all messages without changing global privacy.

## Hermes gates

Hermes applies its own group rules after Telegram delivers an update:

- `telegram.allowed_chats` / `TELEGRAM_ALLOWED_CHATS`: optional response allowlist for group chat IDs.
- `telegram.group_allowed_chats` / `TELEGRAM_GROUP_ALLOWED_CHATS`: authorizes shared group/session context for observed chatter.
- `telegram.allowed_topics` / `TELEGRAM_ALLOWED_TOPICS`: restricts forum topics; General can be treated as topic `1`.
- `telegram.ignored_threads` / `TELEGRAM_IGNORED_THREADS`: hard silence in specific topic IDs.
- `telegram.require_mention` / `TELEGRAM_REQUIRE_MENTION`: when true, group messages must be direct triggers.
- `telegram.exclusive_bot_mentions`: default true; explicit `@...bot` mentions route only to the mentioned bot usernames in multi-bot groups.

With `require_mention: true`, accepted triggers are replies to the bot, `@botusername`, `/command@botusername`, or a match in `telegram.mention_patterns`.

## Safe observed-context group config

```yaml
telegram:
  allowed_chats:
    - "-1001234567890"
  group_allowed_chats:
    - "-1001234567890"
  require_mention: true
  observe_unmentioned_group_messages: true
  exclusive_bot_mentions: true
  mention_patterns:
    - "^\\s*shino\\b"
```

This lets Hermes store ordinary group messages as observed context without dispatching the agent. A later reply, mention, command-with-botname, or wake word can use the observed context.

## Fast diagnosis

1. Send `@botusername halo` in the group.
2. Reply directly to an existing bot message.
3. Send `/help@botusername`.
4. If all fail but DMs work, fix Telegram delivery/privacy or group membership.
5. If direct triggers work but normal chatter does not, inspect `telegram.require_mention`, `allowed_chats`, topic filters, and wake-word patterns.
6. If context is not remembered from unmentioned chatter, confirm privacy/admin delivery plus `observe_unmentioned_group_messages` and `group_allowed_chats`.
