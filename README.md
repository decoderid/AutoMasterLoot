# Auto Master Loot (v1.0)

A lightweight, compact, and automated Master Loot solution for World of Warcraft: Wrath of the Lich King (3.3.5a).

**Auto Master Loot** is designed to speed up looting during raids and dungeons. When you are the Master Looter, it automatically distributes items matching your selected quality filters directly to yourself upon opening the loot window—saving precious raid time!

## Features

- **Automatic Distribution:** Instantly assigns targeted loot to the Master Looter upon opening the loot window.
- **Custom Quality Filters:** Toggle loot auto-assignment for **Uncommon**, **Rare**, **Epic**, and **Legendary** items.
- **Clean & Compact GUI:** Minimalist frame interface that fits seamlessly into your WoW UI.
- **Lock Options (Gear Menu):** Built-in dropdown menu at the bottom-right corner to lock window movement or disable checkbox filters against accidental clicks.
- **Low Footprint:** Zero external dependencies, clean Lua code, and zero performance impact.

## Commands

- `/aml` — Toggle the main GUI interface on or off.

## Installation

1. Download the latest release `.zip` archive.
2. Extract the contents and ensure the folder is named exactly `AutoMasterLoot` (remove any `-main` or version suffixes).
3. Move the `AutoMasterLoot` folder into your WoW directory:
   `World of Warcraft/Interface/AddOns/`
4. Confirm the file path looks like:
   `World of Warcraft/Interface/AddOns/AutoMasterLoot/AutoMasterLoot.lua`
5. Launch World of Warcraft (3.3.5a) and verify the AddOn is enabled in the character selection screen.

## Compatibility

- World of Warcraft: Wrath of the Lich King (**Client 3.3.5a / Build 30300**)

## License

This project is open-source and available under the [MIT License](LICENSE).