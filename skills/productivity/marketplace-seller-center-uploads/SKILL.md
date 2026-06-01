---
name: marketplace-seller-center-uploads
description: "Assist with marketplace seller-center uploads through a browser: login handoff, product data checklist, manual upload, and bulk template workflows."
version: 1.0.0
author: Hermes Agent
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [marketplace, seller-center, ecommerce, browser, upload, shopee]
    category: productivity
---

# Marketplace seller-center uploads

Use this skill when a user asks you to upload, post, update, or bulk-import products in a marketplace seller portal such as Shopee Seller Centre, Tokopedia Seller, Lazada Seller Center, Amazon Seller Central, or similar ecommerce admin sites.

## Core workflow

1. Confirm the marketplace and region if it is not obvious from the user's wording.
2. Open the seller portal in the browser and inspect the current state.
3. If login is required, stop at the login screen and hand off credentials, QR login, OTP, captcha, or 2FA to the user. Do not ask the user to send passwords or OTP codes in chat.
4. After the user says they are logged in, navigate to the product upload/add product/bulk import area.
5. Collect or locate the required product inputs before submitting anything.
6. Fill forms conservatively, pausing before final publish if the user has not explicitly approved the exact product details.
7. For bulk uploads, prefer the platform's official Excel/CSV template when available, then upload the completed template through the portal.
8. Verify the result by checking the product list, draft list, upload status page, or error report.

## Product data checklist

Before creating or updating listings, gather:

- Product name/title
- Category and subcategory
- Brand, attributes, and variation options
- Description and key selling points
- Photos or media assets
- Price, stock, SKU, and wholesale tiers if any
- Weight, dimensions, shipping options, and warehouse/origin
- Condition, preorder status, warranty, dangerous goods flags, and compliance fields

## Login and security handoff

Treat seller portals as sensitive commerce accounts.

- Let the user type passwords, scan QR codes, solve captchas, and complete OTP/2FA directly in the browser.
- If the user asks you to continue after login, use the existing browser session instead of requesting credentials.
- Avoid storing, repeating, or summarizing secrets.
- If a session times out, return to the login handoff rather than trying to bypass it.

## Publish safety

Uploading products can change a live storefront.

- Distinguish between saving a draft and publishing live.
- Ask for confirmation before clicking a final publish/submit button when product details were inferred or incomplete.
- If the user only wants navigation help, stop after reaching the relevant screen.
- If the user says to stop or close the browser, stop browser work immediately and do not continue navigation.

## Browser resource cleanup

Seller portals can leave headless Chromium processes running and consuming VPS RAM after browser automation stops.

- When a user complains about RAM, slowness, or asks whether the browser is closed, check for Chromium/browser processes before assuming the session is idle.
- If possible, close the browser session through the tool/session manager; if the process is owned outside the agent's permissions, explain that a host-level restart or privileged kill is needed.
- Provide safe cleanup commands with process verification, for example `ps aux | grep -Ei 'chromium|chrome' | grep -v grep`, then `sudo pkill -f 'chromium.*session-default'` or a targeted `sudo kill -9 <parent-pid>` only when the user wants to reclaim resources.
- Prefer restarting the agent/browser session when the environment owns the browser lifecycle and direct process termination is denied.

## Shopee-specific notes

For Shopee Seller Centre Indonesia, start at `https://seller.shopee.co.id/`. If the login page appears, the safe handoff options are username/password typed by the user or QR login. After login, continue to the product upload/add product area and use Shopee's required fields and validation messages to drive the checklist.

## Output style

Keep updates short and operational. Tell the user the current page/state, what you need from them, and the next action. For Indonesian users, it is fine to use a casual Indonesian tone if that matches the conversation.