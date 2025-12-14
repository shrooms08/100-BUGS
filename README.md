# 100 Bugs You Must Exploit

![Game Banner](assets/banner.png)

> **What if bugs weren't mistakes, but the entire game?**

A puzzle-platformer that flips game development on its head. Instead of fixing bugs, players must master and exploit them to progress. Every bug conquered mints an NFT on Solana.

🎮 **[Play Live Demo](https://shroomsgotsol.itch.io/100bugs)** | 📺 **[Watch Demo Video](https://x.com/100bugsonsol/status/1999610849585971615)** | 🐦 **[Follow Development](#x.com/100bugsonsol)**

---

## 🎯 Overview

**100 Bugs You Must Exploit** is a puzzle-platformer where *deliberate* game-breaking mechanics are the core gameplay. **Season 1 ships with 20 handcrafted bugs**, each built around a unique broken mechanic—gravity reversal, invisible platforms, control swaps, and more.

Built for the **Hackathon 2025**, the project demonstrates *meaningful blockchain integration*: NFTs act as permanent proof-of-skill badges earned only through gameplay.

---

## ✨ Features

### 🎮 Core Gameplay

* **20 Intentional Bugs (Season 1)** — One broken mechanic per level
* **Progressive Difficulty** — Tutorial → Legendary
* **Campaign Mode** — Master all bugs to complete the season
* **Pure Skill** — No grinding, no pay-to-win

### 🏆 Daily Challenges

* **New Bug Daily** — Rotating 24-hour challenges
* **Speedrun Focus** — Beat the clock for better tiers
* **Tier System**

  * 🥇 Gold: < 30 seconds
  * 🥈 Silver: < 60 seconds
  * 🥉 Bronze: < 120 seconds
  * 🎖️ Participant: Everyone else

### ⚡ Solana Integration

* **NFT Rewards** — Each bug completion mints a unique NFT
* **Proof of Skill** — On-chain achievement verification
* **Metaplex Core** — Efficient NFT standard
* **IPFS Storage** — Decentralized metadata & artwork
* **Seamless UX** — No manual transaction pop-ups

### 🎨 Polish

* **Custom Pixel Art** — Distinct visual identity
* **Sound Design** — Music & SFX for immersion
* **Web Build** — Play directly in the browser
* **Wallet Support** — Phantom & Solflare

---

## 🐛 The 20 Bugs (Season 1)

| #  | Bug Name             | Mechanic                      | Difficulty |
| -- | -------------------- | ----------------------------- | ---------- |
| 1  | Plain and Simple     | Tutorial level                | Tutorial   |
| 2  | Ghost Wall           | Walk through walls            | Easy       |
| 3  | Low Gravity          | Reduced gravity               | Easy       |
| 4  | Slippery Floor       | Ice physics                   | Easy       |
| 5  | Invisible Button     | Hidden interaction            | Easy       |
| 6  | Play with Gravity    | Gravity reversal on command   | Medium     |
| 7  | Hitbox Offset        | Misaligned collision          | Medium     |
| 8  | Stay on It           | Hold position for 5 seconds   | Medium     |
| 9  | Save Jumps           | Only 3 jumps allowed          | Medium     |
| 10 | Floor Flicker        | Platforms disappear/reappear  | Medium     |
| 11 | Just Give Up         | Wait 10 seconds doing nothing | Hard       |
| 12 | Gravity Fails        | Gravity switches on collision | Hard       |
| 13 | Swapped Controls     | Reversed input                | Hard       |
| 14 | Time Delay           | Input lag mechanic            | Hard       |
| 15 | Velocity Chaos       | Constantly changing speed     | Hard       |
| 16 | Chaos Shuffle        | Platforms move randomly       | Legendary  |
| 17 | Alternative Controls | New control scheme            | Legendary  |
| 18 | Blind Camera         | Limited vision                | Legendary  |
| 19 | Don't Touch It       | Resist the obvious button     | Legendary  |
| 20 | Upside Down          | Entire world inverted         | Legendary  |

---

## 🛠️ Tech Stack

### Game

* **Engine:** Godot 4.x
* **Language:** GDScript
* **Export:** Web (HTML5 / WebAssembly)

### Blockchain

* **Network:** Solana (Devnet)
* **Framework:** Anchor (Rust)
* **Program ID:** `AuXF95nT7WS865AzQpuj3os9r6DjTYY9ekh4mGgG6gfL`
* **NFT Standard:** Metaplex Core
* **Storage:** IPFS

### Backend

* **API:** Node.js + Express
* **Libraries:**

  * `@coral-xyz/anchor`
  * `@solana/web3.js`
  * Metaplex SDK

---

## 🚀 Getting Started

### Prerequisites

* Node.js 16+
* Python 3 (for local web server)
* Solana wallet (Phantom or Solflare)

### Installation

#### 1. Clone Repository

```bash
git clone https://github.com/shrooms08/100-BUGS.git
cd 100-BUGS
```

#### 2. Setup API Server

```bash
cd 100bugs-api-READY
npm install
cp .env.example .env
npm start
```

#### 3. Run Game (Web Build)

```bash
cd 100Bugs/export/web
python3 -m http.server 8000
```

#### 4. Play

Open `http://localhost:8000`

---

## 🎮 How to Play

### Controls

* **Arrow Keys / WASD** — Move
* **Space / Up Arrow** — Jump
* **ESC** — Pause

### Objective

1. Reach the button to unlock the door
2. Enter the door to complete the bug
3. Exploit the broken mechanic
4. Mint your achievement NFT

### Tips

* Don’t fight the bug — exploit it
* Every level teaches a new way to think
* Daily challenges reset at midnight UTC
* Wallet connection is required to mint NFTs

---

## 🏗️ Project Structure

```
100-BUGS/
├── 100Bugs/            # Godot project
│   ├── Scene/
│   ├── Scripts/
│   ├── Sounds/
│   ├── Sprites/
│   └── export/web/
│
├── 100bugs-api-READY/  # Backend API
│   ├── server.js
│   ├── idl.json
│   └── package.json
│
├── solana-contracts/   # Anchor programs (separate repo)
│   └── programs/cmpgn/
│
└── docs/
```

---

## 🔗 Smart Contract

* **Network:** Solana Devnet
* **Program ID:** `AuXF95nT7WS865AzQpuj3os9r6DjTYY9ekh4mGgG6gfL`
* **Explorer:** [View on Solscan](https://solscan.io/account/AuXF95nT7WS865AzQpuj3os9r6DjTYY9ekh4mGgG6gfL?cluster=devnet)

### Key Instructions

* `initialize`
* `start_campaign`
* `record_campaign_completion`
* `mint_nft`
* `get_daily_bug`

---

## 🎨 Design Philosophy

### Bugs as Features

Every bug is:

* **Intentional** — Designed, not accidental
* **Exploit-able** — Often with multiple solutions
* **Skill-Based** — Mastery feels rewarding

### Meaningful NFTs

* Earned only through gameplay
* Represent real achievement
* Proof-of-skill, not speculation

---

## 🛣️ Roadmap

### ✅ Phase 1 — MVP

* [x] 20 bugs (Season 1)
* [x] Campaign mode
* [x] Daily challenges
* [x] Solana integration
* [x] Web build

### 🔄 Phase 2 — Polish

* [ ] UI/UX improvements
* [ ] Performance optimization
* [ ] Mobile-friendly controls

### 📋 Phase 3 — Community

* [ ] Leaderboards
* [ ] Level editor
* [ ] Community-created bugs

### 🚀 Phase 4 — Expansion

* [ ] Bug Pack 2 (20 new bugs)
* [ ] Mainnet deployment
* [ ] Mobile ports

---

## 👨‍💻 Developer

**Oghenerukevwe (Minos)**
Benin City, Nigeria
Solana Hackathon 2024

* Twitter: [@shroomsgotsol](#)

---

## 📺 Media

![Main Menu](assets/screenshots/main-menu.png)
![Gameplay](assets/screenshots/gameplay.png)
![NFT Minting](assets/screenshots/nft-minting.png)

---

<div align="center">

### 🐛 Where bugs aren’t mistakes — they’re the game

**Built with ❤️ for Solana Hackathon 2024**

[⭐ Star this repo](https://github.com/shrooms08/100-BUGS) | [🐦 Follow on Twitter: @100bugsonsol](#)

</div>
