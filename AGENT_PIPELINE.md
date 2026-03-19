# FixMyShit Agent Pipeline
> AUTO_GUM automation: From rage to revenue

## Pipeline Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  PAIN SCOUT     │────▶│  PRODUCT FORGE  │────▶│  LISTING SMITH  │
│  (Discovery)    │     │  (Building)     │     │  (Gumroad)      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                                               │
        │                                               ▼
        │                                       ┌─────────────────┐
        │                                       │  TRAFFIC SNIPER │
        │                                       │  (Guerrilla)    │
        │                                       └─────────────────┘
        │                                               │
        ▼                                               ▼
┌─────────────────┐                             ┌─────────────────┐
│  RAGE MONITOR   │◀────────────────────────────│  SALES TRACKER  │
│  (Continuous)   │                             │  (Analytics)    │
└─────────────────┘                             └─────────────────┘
```

---

## The 6 Agents

### 1. PAIN SCOUT (Discovery)
**Job:** Find developer rage on Reddit/Twitter/HN

**Input:** Keywords ("hate", "can't", "broken", "stuck", "annoying")
**Output:** Scored pain points with suggested fixes
**Schedule:** Every 4 hours

```json
{
  "pain_text": "Why the fuck does port 3000 stay occupied...",
  "source": "reddit/r/webdev",
  "upvotes": 847,
  "solvability_score": 9,
  "suggested_fix": "CLI tool to kill process on port"
}
```

---

### 2. PRODUCT FORGE (Building)
**Job:** Turn pain points into shippable $3 products

**For CLI tools:** Scaffold Rust → Build → Package zip
**For docs:** Generate content → Format → Export PDF

**Output:**
```
~/recovery/fixmyshit/products/{name}/
├── src/main.rs
├── README.md
└── releases/{name}-linux.zip
```

---

### 3. LISTING SMITH (Gumroad)
**Job:** Create listings that convert

**Process:**
1. Generate rage-click title
2. Write blunt AUTO_GUM description
3. Generate cover image (enraged user + tool)
4. Upload via Gumroad API

**Listing Template:**
```
[PRODUCT]: [One-line fix]

The problem:
"[Quote the rage post]"

The fix:
[2-3 sentences]

$3. If it sucks, refund's 1 click.
```

---

### 4. TRAFFIC SNIPER (Guerrilla Marketing)
**Job:** Get eyeballs without ads

**Twitter Sniper:**
- Find viral tweets about the pain
- Reply: "Made a $3 fix for this. DM if you want it."

**Reddit Guerrilla:**
- Answer questions helpfully
- Add: "Made a tool for this, link in bio"

**All replies queued for human approval before posting.**

---

### 5. SALES TRACKER (Analytics)
**Job:** Monitor revenue and optimize

**Daily Report:**
```
Sales today: 7 ($21)
Top product: port-yeet (4 sales)
Source: Reddit (3), Twitter (2), Direct (2)

💡 Bundle suggestion: Starter Pack for $9
```

---

### 6. RAGE MONITOR (Continuous)
**Job:** Always-on intelligence

**Weekly Brief:**
```
🔥 Trending Pain:
1. "WSL networking broken" (+340%)
2. "Docker eating disk" (+180%)

📈 Converting:
- port-yeet: 12% from r/webdev

💡 New Product Opportunity:
- WSL network fixer (high rage, no solution)
```

---

## Implementation Phases

### Phase 1: Manual (This Week)
- [x] Package existing products
- [ ] Create Gumroad "FixMyShit" account
- [ ] List 3 products manually
- [ ] Manual Reddit/Twitter posting

### Phase 2: Semi-Auto (Week 2-3)
- [ ] Build pain-scout.py scraper
- [ ] Automate Gumroad uploads
- [ ] Discord approval queue for replies
- [ ] Webhook → sales alerts

### Phase 3: Full Pipeline (Month 2)
- [ ] n8n orchestration
- [ ] Auto product scaffolding
- [ ] Traffic sniper with approval flow
- [ ] Analytics dashboard

---

## Quick Commands

```bash
# List a product
python3 scripts/upload-gumroad.py \
  --name "port-yeet" \
  --price 300 \
  --file products/port-yeet/releases/port-yeet-linux.zip

# Run pain scout
python3 scripts/pain-scout.py --subreddit webdev --hours 24

# Check sales
python3 scripts/sales-tracker.py --today
```

---

## Required APIs

| Service | Purpose | Cost |
|---------|---------|------|
| Gumroad | Sales | Free (10% cut) |
| Reddit API | Discovery | Free |
| Twitter API | Discovery | Free tier |
| Replicate | Cover images | ~$0.01/image |
| Discord | Notifications | Free |

---

## Brand Voice (from Brand Guardian)

**Tagline:** "Micro-tools for maximum rage."

**Colors:** Rage Red (#E63946), Terminal Black (#1A1A1D), Warning Yellow (#FFD166)

**Logo:** Enraged stick figure at computer, meltdown mode

**Copy style:**
> "Port 3000 is being held hostage again. Pay the $3 ransom and yeet it into oblivion."

---

*"Weaponized empathy in a monetized format."* — AUTO_GUM
