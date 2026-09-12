-- Inisialisasi Database
if not AutoMasterLootDB then
    AutoMasterLootDB = {
        enabled = true,
        lockedUI = false,
        lockedFilters = false,
        [2] = true, [3] = true, [4] = true, [5] = true
    }
end

if AutoMasterLootDB.enabled == nil then AutoMasterLootDB.enabled = true end
if AutoMasterLootDB.lockedUI == nil then AutoMasterLootDB.lockedUI = false end
if AutoMasterLootDB.lockedFilters == nil then AutoMasterLootDB.lockedFilters = false end

-- Opsi Kualitas Item dengan Warna Teks (WoW Quality Color Codes)
local QUALITY_OPTIONS = {
    { text = "|cff1eff00Uncommon|r", val = 2 },
    { text = "|cff0070ddRare|r",     val = 3 },
    { text = "|cffa335eeEpic|r",     val = 4 },
    { text = "|cffff8000Legendary|r",val = 5 },
}

-- Frame Utama (Ringkas: 140x155)
local gui = CreateFrame("Frame", "AutoMasterLootFrame", UIParent)
gui:SetSize(140, 155)
gui:SetPoint("CENTER", 0, 0)
gui:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
gui:EnableMouse(true)
gui:SetMovable(true)
gui:RegisterForDrag("LeftButton")

-- Handler Pergerakan UI
gui:SetScript("OnDragStart", function(self)
    if not AutoMasterLootDB.lockedUI then
        self:StartMoving()
    end
end)
gui:SetScript("OnDragStop", gui.StopMovingOrSizing)

-- Judul Ringkas (Tengah Atas)
local title = gui:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
title:SetPoint("TOP", 0, -8)
title:SetText("Auto Master Loot")

-- Tombol Toggle Status (ON/OFF)
local toggleBtn = CreateFrame("Button", "AML_ToggleBtn", gui, "UIPanelButtonTemplate")
toggleBtn:SetSize(115, 18)
toggleBtn:SetPoint("TOP", 0, -24)

local function UpdateButtonState()
    if AutoMasterLootDB.enabled then
        toggleBtn:SetText("Status: |cff00ff00ON|r")
    else
        toggleBtn:SetText("Status: |cffff0000OFF|r")
    end
end

toggleBtn:SetScript("OnClick", function(self)
    AutoMasterLootDB.enabled = not AutoMasterLootDB.enabled
    UpdateButtonState()
    if AutoMasterLootDB.enabled then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Auto Master Loot active|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Auto Master Loot inactive|r")
    end
end)

-- Garis Pemisah
local line = gui:CreateTexture(nil, "ARTWORK")
line:SetSize(120, 1)
line:SetPoint("TOP", 0, -45)
line:SetTexture("Interface\\Buttons\\WHITE8X8")
line:SetVertexColor(0.4, 0.4, 0.4, 0.5)

-- Checkbox Kualitas Item (Uncommon - Legendary)
gui.checkboxes = {}
for i, opt in ipairs(QUALITY_OPTIONS) do
    local cb = CreateFrame("CheckButton", "AML_CB_"..opt.val, gui, "UICheckButtonTemplate")
    cb:SetSize(18, 18)
    cb:SetPoint("TOPLEFT", 12, -32 - (i * 18))
    
    local cbText = _G[cb:GetName() .. "Text"]
    cbText:SetText(opt.text)
    cbText:SetFontObject("GameFontHighlightSmall")

    local isChecked = (AutoMasterLootDB[opt.val] == nil) and true or AutoMasterLootDB[opt.val]
    cb:SetChecked(isChecked)

    cb:SetScript("OnClick", function(self)
        AutoMasterLootDB[opt.val] = self:GetChecked() and true or false
    end)

    gui.checkboxes[opt.val] = cb
end

-- Create Gear Icon Button (14x14px Kanan Bawah)
local gearBtn = CreateFrame("Button", "AML_GearBtn", gui)
gearBtn:SetSize(14, 14)
gearBtn:SetPoint("BOTTOMRIGHT", -8, 8)

local gearTex = gearBtn:CreateTexture(nil, "ARTWORK")
gearTex:SetAllPoints()
gearTex:SetTexture("Interface\\WorldMap\\Gear_64")
gearTex:SetTexCoord(0, 0.5, 0, 0.5)

gearBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

-- Create Dropdown Menu Frame
local menuFrame = CreateFrame("Frame", "AML_DropDownMenu", gui, "UIDropDownMenuTemplate")

-- Generasi Menu Dropdown
local function InitializeDropDown(self, level)
    local info = UIDropDownMenu_CreateInfo()
    
    -- Option 1: Lock Window Position
    info.text = "Lock Position"
    info.checked = AutoMasterLootDB.lockedUI
    info.isNotRadio = true
    info.func = function()
        AutoMasterLootDB.lockedUI = not AutoMasterLootDB.lockedUI
    end
    UIDropDownMenu_AddButton(info, level)

    -- Option 2: Lock Filters
    info.text = "Lock Filters"
    info.checked = AutoMasterLootDB.lockedFilters
    info.isNotRadio = true
    info.func = function()
        AutoMasterLootDB.lockedFilters = not AutoMasterLootDB.lockedFilters
        gui:UpdateFilterLockState()
    end
    UIDropDownMenu_AddButton(info, level)
end

gearBtn:SetScript("OnClick", function(self)
    UIDropDownMenu_Initialize(menuFrame, InitializeDropDown, "MENU")
    ToggleDropDownMenu(1, nil, menuFrame, self:GetName(), 0, 0)
end)

function gui:UpdateFilterLockState()
    local isLocked = AutoMasterLootDB.lockedFilters
    for _, cb in pairs(gui.checkboxes) do
        if isLocked then
            cb:Disable()
        else
            cb:Enable()
        end
    end
end

-- Core Event Handling
gui:RegisterEvent("ADDON_LOADED")
gui:RegisterEvent("LOOT_OPENED")

gui:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "AutoMasterLoot" then
        UpdateButtonState()
        for val, cb in pairs(gui.checkboxes) do
            local isChecked = (AutoMasterLootDB[val] == nil) and true or AutoMasterLootDB[val]
            cb:SetChecked(isChecked)
        end
        gui:UpdateFilterLockState()
    elseif event == "LOOT_OPENED" then
        if not AutoMasterLootDB.enabled then return end

        local method, partyIdx, raidIdx = GetLootMethod()
        if method == "master" then
            local mlName = raidIdx and UnitName("raid"..raidIdx) 
                        or partyIdx and UnitName("party"..partyIdx) 
                        or UnitName("player")

            local mlCandidateIdx = nil
            for ci = 1, GetNumRaidMembers() do
                if GetMasterLootCandidate(ci) == mlName then
                    mlCandidateIdx = ci
                    break
                end
            end

            if mlCandidateIdx then
                for li = 1, GetNumLootItems() do
                    if GetLootSlotLink(li) then
                        local _, _, quality = GetItemInfo(GetLootSlotLink(li))
                        if quality and AutoMasterLootDB[quality] then
                            GiveMasterLoot(li, mlCandidateIdx)
                        end
                    end
                end
            end
        end
    end
end)

-- Slash Command (/aml)
SLASH_AUTOMASTERLOOT1 = "/aml"
SlashCmdList["AUTOMASTERLOOT"] = function()
    if gui:IsShown() then
        gui:Hide()
    else
        gui:Show()
    end
end