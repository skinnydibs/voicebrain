# CLAUDE.md — VoiceBrain

## Project
Voice-first personal note-taking app. Deployed via GitHub to Netlify and Cloudflare Pages.
Stack: OpenAI Whisper (transcription), GPT-4o mini (AI organisation), vanilla JS + HTML/CSS — single file, no build tooling.
Personal use only. API key stored in localStorage.

## Architecture
- Single file: `index.html` (~2,350 lines — CSS, HTML, JS all inline, as of 2026-04-08 v2 push)
- No backend, no server, no framework
- Data storage: `localStorage` (`vb_notes`, `vb_settings`)
- Fonts: Fraunces (serif headings) + DM Sans (body), loaded from Google Fonts
- API calls go directly from browser to OpenAI — key is stored client-side

## Screens (5 total)
| Screen | ID | Purpose |
|---|---|---|
| Capture | `#screen-capture` | Hold-to-record mic input or type a note; shows recent 5 notes below |
| Dashboard | `#screen-dashboard` | Card grid of all notes; filter by category, search, export to JSON |
| Timeline | `#screen-timeline` | Notes grouped by day/week/month with category stats; navigate by period |
| Mind Map | `#screen-mindmap` | Force-directed canvas graph; nodes = notes, edges = shared `linkedThemes` |
| Note Detail | `#screen-detail` | Edit title/body, view original transcript, see linked notes, delete |

## Categories
`todo`, `reminder`, `inspiration`, `book`, `general`
Each has its own colour token in CSS (e.g. `--todo`, `--todo-bg`).

## Note Data Shape
```js
{
  id, text, source,       // source: 'voice' | 'text'
  category, title, summary,
  tags,                   // string[]
  linkedThemes,           // string[] — used for mind map edges + linked notes
  reminderTime,           // ISO string | null
  body, done,
  createdAt               // ISO string
}
```

## AI Flow
1. Voice → Whisper API (`/v1/audio/transcriptions`, `whisper-1`) → transcript
2. Text or transcript → GPT-4o mini (`/v1/chat/completions`) → JSON with `{category, title, summary, tags, reminderTime, linkedThemes}`
3. On AI failure: graceful fallback (saves raw text with no AI enrichment, shows toast)

## Mind Map (canvas)
- Built on HTML5 Canvas, no external library
- Force-directed simulation: 200 iterations of repulsion + edge attraction
- Edges drawn between notes that share at least one `linkedTheme`
- Supports drag-to-pan, scroll-to-zoom, pinch-to-zoom (touch), click node to open detail
- Tooltip on hover shows title, category, themes

## Reminders
- `reminderTime` parsed from AI output (ISO datetime)
- Browser Notification API used if permission granted; falls back to toast
- Checked every 60s via `setInterval`

## Mobile
- Bottom nav bar replaces top nav links at ≤640px
- Responsive grid and font sizes

## Git / Deploy
- Remote: `https://github.com/skinnydibs/voicebrain` → auto-deploys to both Netlify and Cloudflare Pages on push to `main`
- Cloudflare Pages: https://voicebrain.pages.dev/
- Push from Ubuntu (WSL): `cd /mnt/c/Users/lynnl/Projects/voicebrain && git push origin main`

## Upcoming: iPhone Push Notifications
- Plan: add PWA layer (manifest.json + service worker) + Cloudflare Worker for Web Push
- Build alongside current app — do NOT touch index.html until layer is ready
- iOS 16.4+ supports Web Push from home screen PWAs
- Reminder data is in localStorage; service worker needs a relay strategy

## Edit Rules
- NEVER regenerate full files. Edit only what's requested.
- Whisper and GPT-4o mini are the AI dependencies — do not swap models without flagging.
- Netlify + Cloudflare Pages — both go live on push to main.
- All state is in the `notes` array and `settings` object; both persisted to localStorage.
- CSS variables are the single source of truth for colours — edit tokens, not inline colours.
