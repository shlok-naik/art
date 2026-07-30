# Handoff: Unfinished App — Visual Polish Pass

## Overview
A visual refresh of the Unfinished (art-sharing/progress-tracking social app) UI: Home, Feed, Profile, Followed, League, Projects, and Go Pro screens. Keeps the app's existing comic/hand-drawn identity (black-outline cards, deep-orange accent, Chewy display font, mascot "Bud") but tightens spacing, adds a consistent hard-shadow card system, introduces Nunito for body/stat text so Chewy is reserved for headlines and buttons, and uses the mascot more (nav bar, empty states, celebration and onboarding moments).

## About the Design Files
The HTML file in this bundle (`Unfinished-Redesign.dc.html`) is a **design reference**, not production code — a static, non-interactive mockup built to show layout, spacing, color, and typography inside iPhone-shaped frames. Do not copy the HTML/CSS directly into the app. The task is to **recreate these screens in the existing Flutter codebase**, using its existing widgets, providers, and navigation (`MainShell`, `AppBottomNav`, `app_styles.dart`, Riverpod providers already wired to Supabase/backend data) — swap in real data where the mockup uses placeholder text/numbers.

## Fidelity
**High-fidelity.** Colors, typography, spacing, radii, and shadows below are final — implement them pixel-close using Flutter equivalents (Container/BoxDecoration, TextStyle, etc.), not the raw HTML.

## Design Tokens

**Colors**
- Accent / primary: `#FF5722` (Flutter's `Colors.deepOrange`)
- Accent tint (banners): `#FFF1EA`
- Ink / borders / primary text: `#111111` (black)
- Body secondary text: `#555555` / `#666666` / `#888888`
- Success tag (Finished status): text `#2E9E4E` on `#E8F7EC`
- Page/canvas background (this mockup only, not app bg): `#F7F2EA`
- App background: white `#FFFFFF`

**Typography** (Google Fonts)
- Chewy — headlines, nav labels, buttons, card titles (weight 400 is the only weight; use font-size for hierarchy)
- Fredoka (700/800/900) — big display moments only: "WELCOME" hero, League theme title, "PRO" headline (replaces the old hard-to-read Sedgwick Ave Display script)
- Rubik Mono One — @usernames only
- Nunito (600/700/800/900) — all body copy, stats, numbers, meta text (new addition for legibility; previously everything was Chewy)

**Shape & elevation**
- Border: 2px solid #111 on virtually every card/button/chip (unchanged from existing app_styles.dart)
- Radius: 14–20px depending on component size (chips 14, cards 16–18, pills/buttons 20–24)
- Shadow: cards/buttons use a flat "hard shadow" — `box-shadow: 3px 3px 0 #111` (small chips) or `4px 4px 0 #111` (primary cards) — no blur, offset only. This replaces plain unshadowed borders and is the single biggest "polish" change.

**Bottom nav**
- Height ~84–104px, white background, 2px black top border
- 4 tabs: Home / Feed / Followed / Profile, simple black line-icon SVGs (house, doc/article, two overlapping circles, person), active tab icon + label turn accent orange
- Mascot ("Bud") image centered, peeking up from the bottom, ~96–128px tall, unchanged from the current app's `AppBottomNav`

## Screens

### Home
- Header: logo (left) + "Buy Pro" filled pill button with 👑, hard shadow
- Quick actions row: 4 equal chips (League/Analytics/My Posts/Projects), icon on top, label below, each its own hard-shadow card
- Hero: "WELCOME" in Fredoka 900 orange, "@username" in Rubik Mono One, tagline in Nunito below
- "Continue Last Project" card: play-icon circle + title/subtitle + progress bar + "X% complete" label
- "Most Recent Post" card: photo area (striped placeholder in mockup — real photo/session thumbnail in app) with a heart+count badge bottom-right, title, then a views/date meta row

### Feed
- Full-bleed dark, vertical swipe between posts (existing behavior unchanged)
- Top: 3-segment progress bar (for multi-photo posts) + circular back button
- Bottom-left: SESSION/SLIDESHOW chip, @artist, project title, over a bottom gradient scrim (new — improves legibility vs. plain text-shadow)
- Bottom-right: thumbs up/down circles (56px, up from 42px) + counts, "more" button
- Bottom bar: translucent glass pill row of 4 emoji reactions with counts (26px emoji, up from 18px)

### Profile
- Header: "Profile" title + outlined "Log out" pill (top-right)
- Profile card: avatar circle, display name (Chewy), @username (Rubik Mono One, orange), 3-way stat row (Posts / Followers / League rank) separated by thin dividers
- Streak/celebration banner: accent-tinted card with mascot + "X-day streak! 🔥" copy — new, uses the mascot for a celebration moment
- Achievements: horizontal row of badge chips (earned + one greyed "locked" placeholder)
- "Edit Profile" outlined button

### Followed
- Empty state card: mascot + "Nobody here yet" + subtext (mascot used for empty state, per request)
- "Suggested artists" list: avatar + handle + post count + outlined "Follow" pill — new addition to make the empty tab useful, not just a dead end

### League
- "THIS SESSION'S THEME" label + theme title in Fredoka + description + countdown timer row, in an accent-tinted card
- "Last Season's Champion" card
- 2-column submissions grid: photo placeholder, @artist, heart+vote-count pill

### Projects
- New-project input row + circular orange "+" button
- Project list cards: title, created date + session count, status chip (In progress / Finished), delete action — **delete icon is a plain black X (not a trash can/emoji)**, per explicit request

### Go Pro
- "UPGRADE TO / PRO" headline in Fredoka
- Feature cards (Multiple leagues, Deeper analytics)
- "Art Wrapped" card with a "NEW" corner badge and placeholder hero art area
- Price card ($4.99/mo, cancel anytime)
- Filled "Upgrade to Pro" CTA button

## Interactions & Behavior
This is a static mockup — no interactions are implemented. Existing app behavior (documented in the current codebase) should be preserved:
- Bottom nav switches tabs via `mainTabIndexProvider` / `goToMainTab`, shared across Home/Feed/Followed/Profile
- Feed: vertical PageView between posts, horizontal PageView through a post's slide photos; reactions call the existing `reactionsRepositoryProvider`
- Projects: create/delete project flows already call `projectsRepositoryProvider`; keep the existing delete confirmation dialog, just restyle its trigger icon to the X shown here
- League/Projects/Go Pro are pushed routes with `currentIndex: -1` on the bottom nav (no tab highlighted), as today

## Assets
- `assets/logo.png` — "Unfinished" wordmark, copied from `assets/branding/logo.png` in the app repo
- `assets/mascot.png` — "Bud" the mascot, copied from `assets/branding/mascot.png` in the app repo
- All photo/thumbnail areas are striped placeholders labeled "photo" — replace with real `Image.network`/session data

## Files
- `Unfinished-Redesign.dc.html` — the full mockup (all 7 screens + supporting "mascot moments" panel), open in a browser to view
- `ios-frame.jsx` — device-frame component used only to present the mockup; not part of the deliverable
