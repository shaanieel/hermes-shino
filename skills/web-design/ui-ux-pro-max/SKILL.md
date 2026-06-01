---
name: ui-ux-pro-max
description: AI-powered design intelligence with 67 UI styles, 161 color palettes, 57 font pairings, 25 chart types, 99 UX guidelines across 15 tech stacks. Searchable databases for styles, colors, typography, products, landing patterns, and UX best practices.
version: 2.5.0
author: NextLevelBuilder
license: MIT
---

# UI/UX Pro Max — Design Intelligence

Searchable design database for building professional UI/UX. Use BEFORE generating any frontend code to pick the right style, colors, typography, and UX patterns.

## Quick Search

```bash
cd ~/.hermes/skills/web-design/ui-ux-pro-max
python3 scripts/search.py "<query>" --domain <domain> [-n <max_results>]
```

### Domains:
| Domain | What it searches |
|--------|-----------------|
| `product` | Product type → style/pattern recommendations (161 categories) |
| `style` | 67 UI styles with CSS keywords and AI prompts |
| `color` | 161 color palettes by product/industry type |
| `typography` | 57 font pairings with Google Fonts imports |
| `landing` | Page structure and CTA strategies |
| `chart` | Chart types and library recommendations |
| `ux` | 99 best practices and anti-patterns |

### Stack filter:
```bash
# Add --stack for stack-specific guidelines
python3 scripts/search.py "<query>" --stack html-tailwind
```

Available stacks: `html-tailwind`, `react`, `nextjs`, `astro`, `vue`, `nuxtjs`, `nuxt-ui`, `svelte`, `swiftui`, `react-native`, `flutter`, `shadcn`, `jetpack-compose`

## Design System Generator

For complete design system generation:
```bash
python3 scripts/design_system.py "<project description>"
```

## Workflow

1. **Before designing** → search `product`, `style`, `color`, `typography` for the project type
2. **Match product type** → get industry-specific recommendations + anti-patterns
3. **Pick style** → choose from 67 styles (glassmorphism, brutalism, bento grid, etc.)
4. **Choose colors** → industry-appropriate palette with hex values
5. **Select typography** → curated font pairings with Google Fonts imports
6. **Check UX** → validate against 99 UX guidelines and anti-patterns
7. **Then build** → implement with `claude-design`, `frontend-design`, and `popular-web-designs` skills

## Available Styles (67 total)

Key styles: Minimalism, Glassmorphism, Brutalism, Claymorphism, Neumorphism, Bento Box Grid, Dark Mode (OLED), Aurora UI, Cyberpunk UI, AI-Native UI, Soft UI Evolution, Neubrutalism, Y2K Aesthetic, Organic Biophilic, Kinetic Typography, Parallax Storytelling, HUD/Sci-Fi FUI, and 50+ more.

## Anti-Pattern Detection

Every product type includes "AVOID" rules — anti-patterns specific to that industry (e.g., "no AI purple/pink gradients for banking", "no dark mode for wellness spa").

## Pre-Delivery Checklist (auto-included)

- No emojis as icons (use SVG: Heroicons/Lucide)
- cursor-pointer on all clickable elements
- Hover states with smooth transitions (150-300ms)
- Light mode: text contrast 4.5:1 minimum
- Focus states visible for keyboard nav
- prefers-reduced-motion respected
- Responsive: 375px, 768px, 1024px, 1440px