User runs Hermes/Codex on an Ubuntu VPS, using OpenRouter/9router, and has aaPanel installed. They are interested in browser/GUI-style VPS monitoring/management (desktop/noVNC/XRDP style), not just command-line management.
§
Superpowers skills from https://github.com/obra/superpowers are installed under ~/.hermes/skills/superpowers and discovered in category 'superpowers'. For coding/build/debug tasks, load relevant skills (especially using-superpowers, brainstorming, systematic-debugging, writing-plans, test-driven-development) before acting.
§
Browser 3-tier: (1) CDP 9222 basic, (2) CloakBrowser via /usr/bin/python3 (reCAPTCHA 0.9, headless=True; Turnstile needs humanize=True; ouo.io: click "I'M A HUMAN"→/go/→extract meta redirect), (3) Browserbase cloud. Shopee expired.
§
9router at github.com/shaanieel/9router (public). gh CLI + GitHub PAT configured for shaanieel.
§
3 bot Telegram/systemd: Shino (default, cmc/deepseek/deepseek-v4-pro via 9router fallback CODEX combo, token=88776642...r1hY), Designer (CODEX combo via 9router, fallback deepseek-v4-flash, 87388419...O5Zo), Reviewer (gemini-2.5-flash NATIVE via Gemini provider — NOT 9router, fallback deepseek-v4-flash via 9router, 87046789...8or0). All 3 use different providers intentionally: Shino+Designer via router9, Reviewer via native gemini.
§
Design workflow: @ShinoDesignBot builds → auto-mentions @ShinoReviewBot → loop fix until score ≥ 90 → only then share with group.
§
TG: After ANY Telegram permission change (privacy mode, bot2bot toggle), MUST kick+re-add bot to group — Telegram caches join-state and changes don't apply until re-join.
§
User runs Shopee store. Has ZAEINSTORE Poster Generator at uploadshopee.zaeinstore.workers.dev (TMDB search, poster gen, TikTok downloader via RapidAPI, Shopee bot upload). Plans to automate uploads using data from this tool.
§
layar.asia (WP+Cloudflare, no challenge): WP REST API, 5954 posts. HTML pattern: <strong>Q</strong><a>HOST</a>. Direct: Terabox/FileMoon/Filekeeper/Upfiles/Krakenfiles. Shortlink/ouo.io: BuzzHeavier/Gofile/Akirabox. 1736 posts w/ 1080p. Scraped to /tmp/layarasia_links.json (44103 links).