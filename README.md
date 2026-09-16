# Auto Master Loot (v1.1)

Automated Master Loot and Item Roll Tracker for **World of Warcraft: Wrath of the Lich King (Client 3.3.5a / Build 30300)**.

## Architecture

The codebase is refactored into modular components:
- **`AML_Core.lua`**: Database initialization, state management, timer logic, chat notification handling, roll parsing, and automatic loot/trade execution.
- **`AML_UI.lua`**: Frame construction, drag-and-drop item slots, roll tracker list UI, MS change manager modal, dropdown menus, and custom button state styling.
- **`AutoMasterLoot.toc`**: Manifest file defining load sequence.

## Key Features

1. **Auto Master Looting:** Automatically assigns looted items based on quality filters (Uncommon, Rare, Epic, Legendary).
2. **Roll Tracker & Timer:** Drag-and-drop items directly into the tracker slot, run 10-second roll countdown timers, track player rolls, and announce winners.
3. **Manual Paging System:** Keeps historical logs of previous item roll sessions with manual `<` and `>` navigation.
4. **MS Change Manager:** Track main-spec change requests and broadcast them to group/raid chat.
5. **Trade Automation:** Automatically inserts won items into the trade window when trading with the winner.

## Installation

1. Copy the folder `AutoMasterLoot` into your AddOns directory:
   `World of Warcraft/Interface/AddOns/AutoMasterLoot/`
2. Verify that all 4 files (`AutoMasterLoot.toc`, `AML_Core.lua`, `AML_UI.lua`, `README.md`) are present inside.
3. Restart WoW or type `/reload` in-game.

## Commands

- `/aml` — Toggle main GUI interface.