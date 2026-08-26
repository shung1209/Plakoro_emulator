# PLAKORO Adventures v2.3 Hotfix

[English](#english) | [繁體中文](#繁體中文)

## English

**PLAKORO Adventures** is an unofficial, fan-made game inspired by Bandai's
Pokémon PLAKORO dice game. It builds on the stable **12.12k release-clean
Official V1 Base**, turning the original emulator and content tools into an
adventure-driven game with progression, collection building, save files, and
two ways to play.

Choose a Plakoro, build three Enerkoro, select four Moves, roll the dice, and
advance through the arena.

## What's in v2.3 Hotfix

- Story Mode with New Game, Continue, save deletion, a randomized encounter
  route unique to each save, battle rewards, collection unlocks, and Plakoro
  levels up to LV5.
- Free Mode with all playable content available for unrestricted battles and
  expanded Enerkoro rules.
- Phone Mode with dedicated portrait menus, simplified preparation and
  Loadout scenes, a vertical Enerkoro Builder, and a focused touch-first
  battle flow.
- 21 Pokémon, 126 Move cards, and 9 custom Kyokoro weight profiles.
- New Gengar, Lucario, and Metagross data, Moves, images, and default dice
  setups.
- Three editable Enerkoro built from the player's owned Energy inventory.
- Dynamic Move cards based on the PlakoroDB card background, including full
  Energy costs, Kyokoro faces, effects, damage, and success probability.
- Warm and Dark interface themes with distinct action-button colors.
- Battle presentation improvements, attack feedback, UI motion, clearer dice
  results, Kyokoro orientation effects, and an animated pre-battle coin toss
  that determines whether the player or opponent takes the first turn.
- Step-by-step battle resolution: Enerkoro is checked first, Charakoro is
  checked only after the Energy requirement succeeds, weakness is applied,
  and the final attack result is then presented.
- Icon-driven battle information for Pokémon types, weaknesses, Energy,
  Enerkoro results, and Charakoro orientations.
- Difficulty-aware AI Loadouts. Easy, Normal, and Hard AI use approximately
  3/6, 4/6, and 5/6 main-Energy faces per die respectively. Automatic AI
  Loadouts select four compatible Moves by success rate, damage, and effect
  synergy; Free Mode preserves manually selected AI Moves while generating
  difficulty-appropriate dice.
- Responsive Web layouts with portrait Phone Mode, landscape guidance for the
  full interface, fullscreen/orientation fallback handling, and scrollbars
  that remain hidden when scrolling is unnecessary.
- Consistent multilingual quit-confirmation dialogs whose dimensions no
  longer change with the interface language.
- Windows, Linux, and Web/itch.io export presets.
- English, Traditional Chinese, Spanish (Spain), and Japanese interfaces.
- Bundled Noto Sans TC and Noto Sans JP fonts for reliable CJK display.

## Game Modes

### Story Mode

Start a new adventure with Charmander, Squirtle, or Bulbasaur, or continue an
existing save. When a new save is created, the game randomly generates its
21-Pokémon encounter route. That route remains fixed for the lifetime of the
save while encounters unlock one at a time; deleting the save and starting
again generates a new route. The active Plakoro cannot battle itself. Victory
unlocks the defeated Plakoro, its Moves, and new Energy. Level rewards must be
selected before continuing.

Story Mode saves:

- completed encounters and career record;
- the save's randomized encounter route;
- unlocked Plakoro and Moves;
- Plakoro levels and Energy rewards;
- owned Energy and the active Enerkoro setup;
- the current player Loadout.

### Free Mode

Free Mode opens the full roster for immediate play. Choose the player and AI
Plakoro, configure four Moves, edit Enerkoro directly, and battle without Story
Mode progression restrictions. Free Mode also supports repeated Fixed Energy
when enabled in the Enerkoro Builder.

### Phone Mode

Phone Mode provides separate Story and Free Mode entry points in a portrait
layout. Its preparation flow focuses on choosing a Pokémon, selecting four
Moves, editing three vertically arranged Enerkoro, validating the Loadout, and
starting battle without desktop-only analysis panels.

During battle, the player selects a Move, views the dice roll, and then sees
staged Enerkoro, Charakoro, weakness, and attack confirmation before the
attack animation. If the Energy requirement fails, Charakoro resolution is
skipped.

### Content Studio

Content Studio remains hidden during normal play so the main menu stays
game-focused. From the main menu, enter:

```text
↑ ↑ ↓ ↓ ← → ← → B A
```

This reveals Content Studio for the current session. The same code is required
in both Story and Free Mode workflows.

## Interface Guide

### Main Menu

Start or continue Story Mode, enter Free Mode, switch between Warm and Dark
themes, delete a Story save, or quit. Content Studio appears only after the
unlock code is entered.

### Encounter Select

Shows Story Mode progress and the next opponent on the save's generated route.
Winning the current encounter unlocks the next battle in that route.

### Battle Preparation

Displays the player and opponent, the active three-Enerkoro setup, four selected
Move cards, and Loadout coverage. Configure the player Plakoro and Moves, edit
Enerkoro, then start the battle when the Loadout is valid. The opponent's
Loadout remains hidden before combat.

AI difficulty changes both its Enerkoro and selected Move combination. Easy AI
uses a lower main-Energy concentration, while Normal and Hard progressively
improve Energy consistency and prioritize Move sets with better coverage and
compatible effects.

### Enerkoro Builder

Select a face to remove or replace its Energy. The game checks every setup
against the available Energy inventory and prevents incomplete or over-budget
configurations. **Save & Use** applies the setup and returns to Battle
Preparation.

### Battle

The battle screen presents both combatants, HP, dice results, Charakoro
orientation icons, Move cards, action feedback, and an optional technical
timeline. Enerkoro and Charakoro results are revealed one step at a time; a
failed Energy check immediately stops Charakoro validation.
Before turn one, an animated coin toss chooses whether the player or opponent
acts first. Select a Move card to attack. Select the opponent Charakoro during
battle to inspect its revealed Moves in a separate window.

### Battle Report

Victory and defeat are resolved on the Battle Report screen. It records turns,
damage, remaining HP, milestones, collection rewards, unlocks, and level-up
Energy before enabling the next navigation action.

## Running the Project

The project currently targets **Godot 4.7.1** with the GL Compatibility
renderer.

1. Clone or download this repository.
2. Open `project.godot` in Godot 4.7.1 or a compatible Godot 4 release.
3. Allow Godot to import the bundled assets and fonts.
4. Run the project from the editor.

The included export presets provide:

- Windows Desktop: `Plakoro_Adventure_v2.3.exe`
- Linux: `Plakoro_Adventure_v2.3.application`
- Web: `web/index.html`

Web export helpers are available in `tools/export_web.sh` and
`tools/export_web.ps1`.

## User Data and Custom Content

On first launch, the game copies the editable starter database into Godot's
`user://user_database/` location. This writable database is separate from the
packaged files and stores custom Pokémon, Moves, Loadouts, Enerkoro setups,
Kyokoro profiles, localization overrides, and other user-created content.

Do not edit packaged database files solely to create personal content. Back up
the user database before replacing an installation or testing major changes.
The local `user_database_link` shortcut is intentionally ignored by Git because
its destination is machine-specific.

## Asset Conventions

- Plakoro portraits use PNG files under `assets/pokemon/images/`; names may use
  a Pokémon ID such as `pikachu_standard.png`.
- Optional 3D models belong under `assets/pokemon/models/`; the resolver accepts
  GLB, GLTF, FBX, a full Pokémon ID, or a species filename.
- Energy icons use the type filenames under `assets/ui/energy/`.
- Kyokoro orientation icons use `face_up`, `face_down`, `head_up`, `head_down`,
  `head_left`, and `head_right` under `assets/ui/kyokoro/`.

## Credits and Attribution

- **Jollto / PlakoroDB** — localization reference and the Move-card background
  template from
  [`database/cards/background.png`](https://github.com/Jollto/PlakoroDB/blob/main/database/cards/background.png).
  PlakoroDB describes its original contributions as licensed under
  [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/). The template
  is used here for non-commercial fan-project presentation; Move content is
  rendered dynamically by Godot.
- **InvestigatorFew7899** — permission to use their STL files for development
  and testing of the 3D model and dice systems.
- **PLAKORO Chinese website** — game information and reference material.
- The PLAKORO community — preservation, testing, and research.

## Disclaimer

PLAKORO Adventures is an unofficial, non-commercial fan project created for
experimentation, preservation, and enjoyment of the PLAKORO game system. It is
not affiliated with, endorsed by, or sponsored by Nintendo, The Pokémon
Company, Game Freak, Creatures Inc., Bandai, or their affiliates.

Pokémon, PLAKORO, the original artwork, logos, card layouts, characters,
trademarks, and related intellectual property belong to their respective
rights holders. No ownership of those properties is claimed by this project.

---

## 繁體中文

**PLAKORO Adventures** 是一款非官方粉絲遊戲，靈感來自 Bandai 推出的
Pokémon PLAKORO 骰子遊戲。本作以穩定的 **12.12k release-clean Official
V1 Base** 為基礎，把原本的模擬器與內容工具發展成具有冒險進度、收藏、
存檔及兩種遊玩方式的完整遊戲。

選擇一隻 Plakoro、配置三顆 Enerkoro、挑選四個招式、擲出骰子，然後在
競技場中一路前進。

## v2.3 Hotfix 收錄內容

- Story Mode 提供 New Game、Continue、刪除存檔、每份存檔獨立的隨機
  故事路線、戰鬥獎勵、收藏解鎖，以及最高 LV5 的 Plakoro 等級。
- Free Mode 開放所有可玩內容，讓玩家自由對戰，並提供較寬鬆的 Enerkoro
  規則。
- Phone Mode 提供專用直立主選單、簡化版對戰準備與 Loadout 場景、垂直排列
  的 Enerkoro Builder，以及適合觸控操作的精簡戰鬥流程。
- 收錄 21 隻 Pokémon、126 張招式卡及 9 組自訂 Kyokoro 權重設定。
- 新增 Gengar、Lucario 及 Metagross 的資料、招式、圖片與預設骰子配置。
- 可使用玩家目前擁有的 Energy 自由配置三顆 Enerkoro。
- 使用 PlakoroDB 卡片背景動態產生招式卡，完整顯示 Energy 需求、Kyokoro
  骰面、效果、傷害及成功率。
- 提供 Warm 與 Dark 兩種介面主題，並以不同按鈕色彩區分操作用途。
- 改善戰鬥演出、攻擊回饋、介面動態效果、擲骰結果及 Kyokoro 方位效果。
- 戰鬥採用逐步結算：先確認 Enerkoro，成功後才確認 Charakoro，接著套用
  弱點並顯示最終攻擊結果；Energy 不足時會直接略過 Charakoro 判定。
- Pokémon 屬性、弱點、Energy、Enerkoro 結果及 Charakoro 方位均以圖示為主，
  減少不同語言造成的版面擁擠。
- AI Loadout 會依難度產生不同的 Enerkoro 與招式組合。簡單、普通、困難
  AI 每顆骰子的主能量面約為 3/6、4/6、5/6，並依成功率、傷害及效果配合度
  自動挑選四個招式。Free Mode 手動指定 AI 招式時會保留選擇，只依難度
  重新配置骰子。
- Web 介面支援響應式版面、Phone Mode 直立顯示、完整介面的橫向提示、
  全螢幕／方向鎖定 fallback，以及只在需要時顯示的 scrollbar。
- 所有語言共用一致的離開遊戲確認視窗尺寸，切換語言時不再改變長寬。
- 戰鬥前會擲出具有翻面動畫的硬幣，依 HEADS／TAILS 決定玩家或
  對手先攻。
- 提供 Windows、Linux 與 Web／itch.io 匯出設定。
- 支援英文、繁體中文、西班牙文（西班牙）與日文介面。
- 內含 Noto Sans TC 與 Noto Sans JP 字型，確保中日文字正常顯示。

## 遊戲模式

### Story Mode（故事模式）

從 Charmander、Squirtle 或 Bulbasaur 中選擇第一隻夥伴開始冒險，也可以
繼續既有存檔。新建存檔時，系統會隨機產生一條包含 21 隻 Pokémon 的
故事路線，之後依該路線逐關解鎖。這個順序會在整份存檔期間保持不變；
只有刪除存檔並重新開始，才會產生新路線。目前使用中的 Plakoro 不能和
自己對戰。獲勝後可解鎖被擊敗的 Plakoro、其招式以及新的 Energy。升級時
必須先選擇 Energy 獎勵才能繼續。

Story Mode 會保存：

- 已完成的關卡與生涯戰績；
- 這份存檔專屬的隨機故事路線；
- 已解鎖的 Plakoro 與招式；
- Plakoro 等級與 Energy 獎勵；
- 已擁有的 Energy 與目前使用中的 Enerkoro 配置；
- 玩家目前的 Loadout。

### Free Mode（自由模式）

Free Mode 會立即開放完整角色陣容。玩家可以選擇自己與 AI 使用的 Plakoro、
設定四個招式、直接編輯 Enerkoro，並在不受 Story Mode 進度限制的情況下
進行對戰。啟用 Enerkoro Builder 中的選項後，Free Mode 也允許不同
Enerkoro 使用重複的固定 Energy。

### Phone Mode（手機模式）

Phone Mode 提供獨立的 Story Mode 與 Free Mode 入口，並以直立介面呈現。
對戰準備只保留選擇 Pokémon、挑選四個招式、編輯三顆垂直排列的 Enerkoro、
Loadout 驗證及開始對戰等必要功能，不顯示桌面版的分析資訊。

戰鬥時會依序呈現招式選擇、擲骰、Enerkoro 確認、Charakoro 確認、弱點與
最終攻擊結果，再進入攻擊動畫。Enerkoro 能量不足時會直接略過 Charakoro
判定。

### Content Studio（內容工作室）

Content Studio 在一般遊玩時會保持隱藏，讓主選單專注於遊戲體驗。在主選單
依序輸入：

```text
↑ ↑ ↓ ↓ ← → ← → B A
```

即可在本次執行期間解除 Content Studio 封印。無論 Story Mode 或 Free Mode
流程，都必須使用相同密技才能開啟。

## 介面導覽

### 主選單

開始或繼續 Story Mode、進入 Free Mode、切換 Warm／Dark 主題、刪除故事
存檔或離開遊戲。輸入解除密技後才會顯示 Content Studio。

### 關卡選擇

顯示 Story Mode 的完成進度，以及這份存檔故事路線上的下一位對手。
戰勝目前關卡後，即可解鎖路線中的下一場對戰。

### 對戰準備

顯示玩家與對手、目前的三顆 Enerkoro、四張已選招式卡及 Loadout 覆蓋率。
設定玩家 Plakoro 與招式、編輯 Enerkoro，並在 Loadout 通過檢查後開始
對戰。戰鬥開始前不會公開對手的 Loadout。

AI 難度會同時影響 Enerkoro 與招式組合。簡單 AI 的主能量集中度較低；
普通與困難 AI 會逐步提高能量穩定度，並優先選擇覆蓋率較高、效果能互相
配合的招式。

### Enerkoro Builder

選擇一個骰面即可移除或替換其中的 Energy。系統會依照玩家持有的 Energy
檢查整套配置，缺少骰面或超出庫存時將無法使用。按下 **Save & Use
（儲存並使用）** 後，系統會套用配置並返回對戰準備。

### 對戰

對戰畫面會顯示雙方 Plakoro、HP、擲骰結果、Charakoro 方位圖示、招式卡、
行動回饋及可選用的技術時間軸。Enerkoro 與 Charakoro 結果會逐步出現；
Energy 判定失敗時會立即停止 Charakoro 驗證。第一回合開始前，會擲硬幣
決定玩家或對手先攻。選擇招式卡即可發動攻擊；戰鬥中選擇對手的
Charakoro，可在獨立視窗
查看已公開的招式。

### 戰鬥報告

勝利與失敗統一由戰鬥報告畫面結算。畫面會記錄回合數、傷害、剩餘 HP、
里程碑、收藏獎勵、解鎖項目及升級 Energy；所有必要獎勵處理完成後，才會
開放下一步操作。

## 執行專案

本專案目前以 **Godot 4.7.1** 與 GL Compatibility renderer 為目標環境。

1. Clone 或下載此 repository。
2. 使用 Godot 4.7.1 或相容的 Godot 4 版本開啟 `project.godot`。
3. 等待 Godot 完成內附素材與字型的匯入。
4. 從編輯器執行專案。

專案內含以下匯出設定：

- Windows Desktop：`Plakoro_Adventure_v2.3.exe`
- Linux：`Plakoro_Adventure_v2.3.application`
- Web：`web/index.html`

Web 匯出輔助工具位於 `tools/export_web.sh` 與
`tools/export_web.ps1`。

## 使用者資料與自訂內容

第一次啟動時，遊戲會將可編輯的初始資料庫複製至 Godot 的
`user://user_database/`。此資料庫與封裝的遊戲檔案分開，可用來保存
自訂 Pokémon、招式、Loadout、Enerkoro 配置、Kyokoro profile、語系覆寫
及其他玩家建立的內容。

若只是建立個人內容，請勿直接修改封裝資料庫。更換安裝版本或測試大型更新
前，請先備份使用者資料庫。本機的 `user_database_link` 捷徑會被 Git
忽略，因為每台電腦的實際位置不同。

## 素材命名規則

- Plakoro 圖片使用 `assets/pokemon/images/` 內的 PNG；檔名可使用
  `pikachu_standard.png` 之類的 Pokémon ID。
- 選用的 3D 模型放在 `assets/pokemon/models/`；系統支援 GLB、GLTF、
  FBX，以及完整 Pokémon ID 或物種名稱檔名。
- Energy 圖示依屬性名稱存放在 `assets/ui/energy/`。
- Kyokoro 方位圖示使用 `face_up`、`face_down`、`head_up`、
  `head_down`、`head_left` 及 `head_right`，並存放在
  `assets/ui/kyokoro/`。

## 致謝與素材來源

- **Jollto / PlakoroDB**——提供語系參考及
  [`database/cards/background.png`](https://github.com/Jollto/PlakoroDB/blob/main/database/cards/background.png)
  招式卡背景模板。PlakoroDB 表示其原創貢獻採用
  [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) 授權。
  本專案僅將該模板用於非商業粉絲作品的介面呈現；實際招式內容由 Godot
  動態產生。
- **InvestigatorFew7899**——允許本專案使用其 STL 檔案進行 3D 模型與骰子
  系統的開發測試。
- **PLAKORO 中文資料站**——提供遊戲資訊與參考資料。
- **PLAKORO 社群**——協助保存資料、測試與研究。

## 免責聲明

PLAKORO Adventures 是一個非官方、非商業的粉絲專案，目的為實驗、保存及
體驗 PLAKORO 遊戲系統。本專案與 Nintendo、The Pokémon Company、
Game Freak、Creatures Inc.、Bandai 或其關係企業均無從屬、授權、背書或
贊助關係。

Pokémon、PLAKORO、原始美術、Logo、卡片版面、角色、商標及其他相關智慧
財產權均屬各自權利人所有。本專案不主張擁有上述內容。
