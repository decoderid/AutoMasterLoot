-- ========================================================
-- AML UI MODULE (Frames, Buttons, Slots, Inputs & Render)
-- REVISED: Fixed DK color override & widened class text column
-- ========================================================
AML = AML or {}
AML.UI = AML.UI or {}

AML.UI.checkboxes = {}
AML.UI.modeButtons = {}
AML.UI.rollRows = {}
AML.UI.entryRows = {}

-- Variable temporary untuk menyimpan data yang dipilih
AML.UI.selectedPlayerName = ""
AML.UI.selectedClass = "Death Knight"
AML.UI.selectedSpec = "Blood"

-- Daftar Class & Spec Options
AML.UI.SPEC_OPTIONS = {
    {
        class = "Death Knight",
        specs = { "Blood", "Frost", "Unholy" }
    },
    {
        class = "Druid",
        specs = { "Bear (Tank)", "Cat", "Boomy", "Resto" }
    },
    {
        class = "Paladin",
        specs = { "Prot", "Holy", "Ret" }
    },
    {
        class = "Warrior",
        specs = { "Prot", "Arms", "Fury" }
    },
    {
        class = "Shaman",
        specs = { "Ele", "Enhan", "Resto" }
    },
    {
        class = "Hunter",
        specs = { "BM", "MM", "Surv" }
    },
    {
        class = "Rogue",
        specs = { "Assa", "Combat", "Sub" }
    },
    {
        class = "Priest",
        specs = { "Disc", "Holy", "Shadow" }
    },
    {
        class = "Mage",
        specs = { "Arcane", "Fire", "Frost" }
    },
    {
        class = "Warlock",
        specs = { "Affli", "Demo", "Destro" }
    }
}

-- Helper function untuk scan member Raid / Party
function AML.UI:GetGroupMembers()
    local members = {}
    local numRaid = GetNumRaidMembers()
    local numParty = GetNumPartyMembers()

    if numRaid > 0 then
        for i = 1, numRaid do
            local name, _, _, _, _, fileName = GetRaidRosterInfo(i)
            if name then
                table.insert(members, { name = name, class = fileName })
            end
        end
    elseif numParty > 0 then
        local pName, pClass = UnitName("player"), select(2, UnitClass("player"))
        table.insert(members, { name = pName, class = pClass })

        for i = 1, numParty do
            local unit = "party" .. i
            if UnitExists(unit) then
                local name = UnitName(unit)
                local _, className = UnitClass(unit)
                table.insert(members, { name = name, class = className })
            end
        end
    else
        -- Solo Mode
        local pName, pClass = UnitName("player"), select(2, UnitClass("player"))
        table.insert(members, { name = pName, class = pClass })
    end

    table.sort(members, function(a, b) return a.name < b.name end)
    return members
end

-- Helper Map Class File Name ke Display Name
local CLASS_MAP = {
    ["DEATHKNIGHT"] = "Death Knight",
    ["DRUID"]       = "Druid",
    ["PALADIN"]     = "Paladin",
    ["WARRIOR"]     = "Warrior",
    ["SHAMAN"]      = "Shaman",
    ["HUNTER"]      = "Hunter",
    ["ROGUE"]       = "Rogue",
    ["PRIEST"]      = "Priest",
    ["MAGE"]        = "Mage",
    ["WARLOCK"]     = "Warlock",
}

-- Memastikan Death Knight konsisten berwarna merah (C41F3B) dan mengabaikan override bawaan core yang biru
local function GetForcedClassColorHex(className)
    if className == "Death Knight" or className == "DEATHKNIGHT" then
        return "FFC41E3A"
    end
    if AML.Core and AML.Core.GetClassColorHex then
        return AML.Core:GetClassColorHex(className)
    end
    return "FFFFFF"
end

local function SetButtonEnabledState(btn, enable)
    if enable then
        btn:Enable()
    else
        btn:Disable()
    end
    btn:SetNormalFontObject("GameFontNormalSmall")
    btn:SetHighlightFontObject("GameFontNormalSmall")
    btn:SetDisabledFontObject("GameFontDisableSmall")
end

function AML.UI:BuildGUI()
    local gui = CreateFrame("Frame", "AutoMasterLootFrame", UIParent)
    gui:SetSize(140, 240)
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
    gui:SetScript("OnDragStart", function(self)
        if not AutoMasterLootDB.lockedUI then self:StartMoving() end
    end)
    gui:SetScript("OnDragStop", gui.StopMovingOrSizing)
    AML.UI.gui = gui

    local title = gui:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", 0, -8)
    title:SetText("Auto Master Loot")

    local toggleBtn = CreateFrame("Button", "AML_ToggleBtn", gui, "UIPanelButtonTemplate")
    toggleBtn:SetSize(115, 18)
    toggleBtn:SetPoint("TOP", 0, -22)
    toggleBtn:SetNormalFontObject("GameFontNormalSmall")
    toggleBtn:SetHighlightFontObject("GameFontNormalSmall")
    toggleBtn:SetDisabledFontObject("GameFontDisableSmall")
    toggleBtn:SetScript("OnClick", function()
        AutoMasterLootDB.enabled = not AutoMasterLootDB.enabled
        AML.UI:UpdateButtonState()
    end)
    AML.UI.toggleBtn = toggleBtn

    local line1 = gui:CreateTexture(nil, "ARTWORK")
    line1:SetSize(120, 1)
    line1:SetPoint("TOP", 0, -43)
    line1:SetTexture("Interface\\Buttons\\WHITE8X8")
    line1:SetVertexColor(0.4, 0.4, 0.4, 0.5)

    for i, opt in ipairs(AML.Core.QUALITY_OPTIONS) do
        local cb = CreateFrame("CheckButton", "AML_CB_"..opt.val, gui, "UICheckButtonTemplate")
        cb:SetSize(18, 18)
        cb:SetPoint("TOPLEFT", 12, -30 - (i * 18))
        
        local cbText = _G[cb:GetName() .. "Text"]
        cbText:SetText(opt.text)
        cbText:SetFontObject("GameFontHighlightSmall")

        cb:SetScript("OnClick", function(self) AutoMasterLootDB[opt.val] = self:GetChecked() and true or false end)
        AML.UI.checkboxes[opt.val] = cb
    end

    local line2 = gui:CreateTexture(nil, "ARTWORK")
    line2:SetSize(120, 1)
    line2:SetPoint("TOP", 0, -125)
    line2:SetTexture("Interface\\Buttons\\WHITE8X8")
    line2:SetVertexColor(0.4, 0.4, 0.4, 0.5)

    local mainMsCounter = gui:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    mainMsCounter:SetPoint("TOP", 0, -133)
    AML.UI.mainMsCounter = mainMsCounter

    local announceBtn = CreateFrame("Button", "AML_AnnounceBtn", gui, "UIPanelButtonTemplate")
    announceBtn:SetSize(115, 18)
    announceBtn:SetPoint("TOP", 0, -152)
    announceBtn:SetText("Announce MS")
    announceBtn:SetNormalFontObject("GameFontNormalSmall")
    announceBtn:SetHighlightFontObject("GameFontNormalSmall")
    announceBtn:SetDisabledFontObject("GameFontDisableSmall")
    announceBtn:SetScript("OnClick", function()
        if #AutoMasterLootDB.msChanges == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[AML]|r No MS changes recorded.")
            return
        end
        AML.Core:SendMessage("=== MS CHANGE LIST ===")
        for i, entry in ipairs(AutoMasterLootDB.msChanges) do
            local cls = entry.class or "Unknown"
            AML.Core:SendMessage(i .. ". " .. entry.name .. " - " .. cls .. " (" .. entry.spec .. ")")
        end
    end)
    AML.UI.announceBtn = announceBtn

    local addMsBtn = CreateFrame("Button", "AML_AddMsBtn", gui, "UIPanelButtonTemplate")
    addMsBtn:SetSize(115, 18)
    addMsBtn:SetPoint("TOP", 0, -174)
    addMsBtn:SetText("+ Add / List MS")
    addMsBtn:SetNormalFontObject("GameFontNormalSmall")
    addMsBtn:SetHighlightFontObject("GameFontNormalSmall")
    addMsBtn:SetDisabledFontObject("GameFontDisableSmall")
    AML.UI.addMsBtn = addMsBtn

    local rollTrackerBtn = CreateFrame("Button", "AML_RollTrackerBtn", gui, "UIPanelButtonTemplate")
    rollTrackerBtn:SetSize(115, 18)
    rollTrackerBtn:SetPoint("TOP", 0, -196)
    rollTrackerBtn:SetText("Roll Tracker")
    rollTrackerBtn:SetNormalFontObject("GameFontNormalSmall")
    rollTrackerBtn:SetHighlightFontObject("GameFontNormalSmall")
    rollTrackerBtn:SetDisabledFontObject("GameFontDisableSmall")
    AML.UI.rollTrackerBtn = rollTrackerBtn

    local gearBtn = CreateFrame("Button", "AML_GearBtn", gui)
    gearBtn:SetSize(14, 14)
    gearBtn:SetPoint("BOTTOMRIGHT", -8, 8)

    local gearTex = gearBtn:CreateTexture(nil, "ARTWORK")
    gearTex:SetAllPoints()
    gearTex:SetTexture("Interface\\WorldMap\\Gear_64")
    gearTex:SetTexCoord(0, 0.5, 0, 0.5)
    gearBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

    local menuFrame = CreateFrame("Frame", "AML_DropDownMenu", gui, "UIDropDownMenuTemplate")
    gearBtn:SetScript("OnClick", function(self)
        UIDropDownMenu_Initialize(menuFrame, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            info.text = "Lock Position"
            info.checked = AutoMasterLootDB.lockedUI
            info.isNotRadio = true
            info.func = function() AutoMasterLootDB.lockedUI = not AutoMasterLootDB.lockedUI end
            UIDropDownMenu_AddButton(info, level)

            info.text = "Lock Filters"
            info.checked = AutoMasterLootDB.lockedFilters
            info.isNotRadio = true
            info.func = function()
                AutoMasterLootDB.lockedFilters = not AutoMasterLootDB.lockedFilters
                AML.UI:UpdateFilterLockState()
            end
            UIDropDownMenu_AddButton(info, level)
            
            info.text = "Clear All Saved Sessions"
            info.checked = false
            info.isNotRadio = true
            info.func = function()
                AutoMasterLootDB.sessions = {}
                AML.UI:LoadPage(1)
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[AML]|r Cleared all roll sessions.")
            end
            UIDropDownMenu_AddButton(info, level)
        end, "MENU")
        ToggleDropDownMenu(1, nil, menuFrame, self:GetName(), 0, 0)
    end)

    AML.UI:BuildRollTrackerFrame()
    AML.UI:BuildMSManagerFrame()

    rollTrackerBtn:SetScript("OnClick", function()
        if AML.UI.rollFrame:IsShown() then 
            AML.UI.rollFrame:Hide() 
        else 
            AML.UI:LoadPage(#AutoMasterLootDB.sessions + 1)
            AML.UI.rollFrame:Show() 
        end
    end)

    addMsBtn:SetScript("OnClick", function()
        if AML.UI.inputFrame:IsShown() then 
            AML.UI.inputFrame:Hide() 
        else 
            AML.UI:RefreshMSList() 
            AML.UI.inputFrame:Show() 
        end
    end)
end

function AML.UI:BuildRollTrackerFrame()
    local rollFrame = CreateFrame("Frame", "AML_RollFrame", UIParent)
    rollFrame:SetSize(310, 310)
    rollFrame:SetPoint("CENTER", 150, 0)
    rollFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    rollFrame:EnableMouse(true)
    rollFrame:SetMovable(true)
    rollFrame:RegisterForDrag("LeftButton")
    rollFrame:SetScript("OnDragStart", rollFrame.StartMoving)
    rollFrame:SetScript("OnDragStop", rollFrame.StopMovingOrSizing)
    rollFrame:Hide()
    AML.UI.rollFrame = rollFrame

    local rollTitle = rollFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rollTitle:SetPoint("TOPLEFT", 12, -8)
    rollTitle:SetText("Item Roll Tracker")

    local timerText = rollFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    timerText:SetPoint("TOPRIGHT", -12, -8)
    timerText:SetText("|cffff0000Timer: 0s|r")
    AML.UI.timerText = timerText

    local itemSlot = CreateFrame("Button", "AML_ItemSlotBtn", rollFrame, "ItemButtonTemplate")
    itemSlot:SetSize(30, 30)
    itemSlot:SetPoint("TOPLEFT", 12, -24)
    itemSlot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    itemSlot:RegisterForDrag("LeftButton")
    AML.UI.itemSlot = itemSlot

    local slotText = rollFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    slotText:SetPoint("LEFT", itemSlot, "RIGHT", 8, 0)
    slotText:SetWidth(240)
    slotText:SetJustifyH("LEFT")
    slotText:SetText("|cff808080Drag item here|r")
    AML.UI.slotText = slotText

    local pageIndicator = rollFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pageIndicator:SetPoint("TOPRIGHT", -12, -58)
    pageIndicator:SetText("Page 1/1")
    AML.UI.pageIndicator = pageIndicator

    local function CatchAndSetCursorItem()
        local infoType, id, link = GetCursorInfo()
        if infoType == "item" then
            local targetLink = link
            if not targetLink and id then
                _, targetLink = GetItemInfo(id)
            end
            if targetLink then
                AML.UI:SetSlotItem(targetLink)
                ClearCursor()
                return true
            end
        end
        return false
    end

    itemSlot:SetScript("OnReceiveDrag", function()
        local totalPages = #AutoMasterLootDB.sessions + 1
        if AML.Core.currentPageIndex < totalPages then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[AML]|r Switch to the last page (Page " .. totalPages .. ") to place a new item.")
            return
        end
        CatchAndSetCursorItem()
    end)

    itemSlot:SetScript("OnDragStart", function()
        local totalPages = #AutoMasterLootDB.sessions + 1
        if AML.Core.currentPageIndex < totalPages then return end
        CatchAndSetCursorItem()
    end)

    itemSlot:SetScript("OnClick", function(self, button)
        local totalPages = #AutoMasterLootDB.sessions + 1
        if AML.Core.currentPageIndex < totalPages then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[AML]|r Switch to the last page (Page " .. totalPages .. ") to place a new item.")
            return
        end

        if button == "RightButton" then
            AML.UI:ClearSlotItem()
        else
            CatchAndSetCursorItem()
        end
    end)

    itemSlot:SetScript("OnEnter", function(self)
        if AML.Core.currentItemLink ~= "" then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(AML.Core.currentItemLink)
            GameTooltip:Show()
        end
    end)
    itemSlot:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local prevBtn = CreateFrame("Button", nil, rollFrame, "UIPanelButtonTemplate")
    prevBtn:SetSize(20, 20)
    prevBtn:SetPoint("TOPLEFT", 12, -78)
    prevBtn:SetText("<")
    prevBtn:SetNormalFontObject("GameFontNormalSmall")
    prevBtn:SetHighlightFontObject("GameFontNormalSmall")
    prevBtn:SetDisabledFontObject("GameFontDisableSmall")
    prevBtn:SetScript("OnClick", function() 
        AML.UI:LoadPage(AML.Core.currentPageIndex - 1) 
    end)

    local nextBtn = CreateFrame("Button", nil, rollFrame, "UIPanelButtonTemplate")
    nextBtn:SetSize(20, 20)
    nextBtn:SetPoint("LEFT", prevBtn, "RIGHT", 2, 0)
    nextBtn:SetText(">")
    nextBtn:SetNormalFontObject("GameFontNormalSmall")
    nextBtn:SetHighlightFontObject("GameFontNormalSmall")
    nextBtn:SetDisabledFontObject("GameFontDisableSmall")
    nextBtn:SetScript("OnClick", function() 
        AML.UI:LoadPage(AML.Core.currentPageIndex + 1) 
    end)

    local modeCategories = { "MS", "OS", "DE", "FREE" }
    local btnXOffset = 60

    for _, cat in ipairs(modeCategories) do
        local btn = CreateFrame("Button", nil, rollFrame, "UIPanelButtonTemplate")
        btn:SetSize(38, 20)
        btn:SetPoint("TOPLEFT", btnXOffset, -78)
        btn:SetText(cat)
        btn:SetNormalFontObject("GameFontNormalSmall")
        btn:SetHighlightFontObject("GameFontNormalSmall")
        btn:SetDisabledFontObject("GameFontDisableSmall")
        btn:SetScript("OnClick", function() AML.Core:StartRollTimer(cat) end)
        
        table.insert(AML.UI.modeButtons, btn)
        btnXOffset = btnXOffset + 40
    end

    local cancelRollBtn = CreateFrame("Button", "AML_CancelRollBtn", rollFrame, "UIPanelButtonTemplate")
    cancelRollBtn:SetSize(46, 20)
    cancelRollBtn:SetPoint("TOPLEFT", btnXOffset, -78)
    cancelRollBtn:SetText("Cancel")
    cancelRollBtn:SetNormalFontObject("GameFontNormalSmall")
    cancelRollBtn:SetHighlightFontObject("GameFontNormalSmall")
    cancelRollBtn:SetDisabledFontObject("GameFontDisableSmall")
    cancelRollBtn:SetScript("OnClick", function() AML.Core:ResetRollSession(true) end)

    local lblNo = rollFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblNo:SetPoint("TOPLEFT", 12, -108)
    lblNo:SetText("No.")

    local lblName = rollFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblName:SetPoint("TOPLEFT", 42, -108)
    lblName:SetText("Player Name")

    local lblRoll = rollFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblRoll:SetPoint("TOPRIGHT", -32, -108)
    lblRoll:SetText("Roll")

    local rollScroll = CreateFrame("ScrollFrame", "AML_RollScroll", rollFrame, "UIPanelScrollFrameTemplate")
    rollScroll:SetSize(270, 130)
    rollScroll:SetPoint("TOPLEFT", 12, -124)

    local rollContent = CreateFrame("Frame", nil, rollScroll)
    rollContent:SetSize(270, 1)
    rollScroll:SetScrollChild(rollContent)
    AML.UI.rollContent = rollContent

    local announceWinnerBtn = CreateFrame("Button", nil, rollFrame, "UIPanelButtonTemplate")
    announceWinnerBtn:SetSize(130, 20)
    announceWinnerBtn:SetPoint("BOTTOMLEFT", 12, 10)
    announceWinnerBtn:SetText("Announce Winner")
    announceWinnerBtn:SetNormalFontObject("GameFontNormalSmall")
    announceWinnerBtn:SetHighlightFontObject("GameFontNormalSmall")
    announceWinnerBtn:SetDisabledFontObject("GameFontDisableSmall")
    announceWinnerBtn:SetScript("OnClick", function()
        AML.Core:AnnounceWinner()
        if AML.Core.isTimerRunning then
            AML.Core:StopRollTimer()
            AML.Core:SaveCurrentSessionToHistory()
        end
    end)

    local rollCloseBtn = CreateFrame("Button", nil, rollFrame, "UIPanelButtonTemplate")
    rollCloseBtn:SetSize(130, 20)
    rollCloseBtn:SetPoint("BOTTOMRIGHT", -12, 10)
    rollCloseBtn:SetText("Close")
    rollCloseBtn:SetNormalFontObject("GameFontNormalSmall")
    rollCloseBtn:SetHighlightFontObject("GameFontNormalSmall")
    rollCloseBtn:SetDisabledFontObject("GameFontDisableSmall")
    rollCloseBtn:SetScript("OnClick", function() rollFrame:Hide() end)
end

function AML.UI:BuildMSManagerFrame()
    local inputFrame = CreateFrame("Frame", "AML_InputFrame", UIParent)
    inputFrame:SetSize(335, 270)
    inputFrame:SetPoint("CENTER", 0, 0)
    inputFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    inputFrame:EnableMouse(true)
    inputFrame:SetMovable(true)
    inputFrame:RegisterForDrag("LeftButton")
    inputFrame:SetScript("OnDragStart", inputFrame.StartMoving)
    inputFrame:SetScript("OnDragStop", inputFrame.StopMovingOrSizing)
    inputFrame:Hide()
    AML.UI.inputFrame = inputFrame

    local popupTitle = inputFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    popupTitle:SetPoint("TOPLEFT", 10, -8)
    popupTitle:SetText("MS Change Manager")

    local popupCount = inputFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    popupCount:SetPoint("TOPRIGHT", -10, -8)
    AML.UI.popupCount = popupCount

    -- DYNAMIC PLAYER NAME DROPDOWN
    local playerDropDown = CreateFrame("Frame", "AML_PlayerDropDown", inputFrame, "UIDropDownMenuTemplate")
    playerDropDown:SetPoint("TOPLEFT", -2, -26)
    UIDropDownMenu_SetWidth(playerDropDown, 110)
    UIDropDownMenu_SetText(playerDropDown, "Select Player")

    local specDropDown = CreateFrame("Frame", "AML_SpecDropDown", inputFrame, "UIDropDownMenuTemplate")
    specDropDown:SetPoint("LEFT", playerDropDown, "RIGHT", -25, 0)
    UIDropDownMenu_SetWidth(specDropDown, 120)
    UIDropDownMenu_SetText(specDropDown, AML.UI.selectedClass .. " - " .. AML.UI.selectedSpec)

    UIDropDownMenu_Initialize(playerDropDown, function(self, level)
        local members = AML.UI:GetGroupMembers()
        for _, member in ipairs(members) do
            local info = UIDropDownMenu_CreateInfo()
            local mappedClass = CLASS_MAP[member.class] or member.class
            local hex = GetForcedClassColorHex(mappedClass)
            info.text = "|c" .. hex .. member.name .. "|r"
            info.checked = (AML.UI.selectedPlayerName == member.name)
            info.func = function()
                AML.UI.selectedPlayerName = member.name
                UIDropDownMenu_SetText(playerDropDown, member.name)

                if mappedClass then
                    AML.UI.selectedClass = mappedClass
                    for _, cg in ipairs(AML.UI.SPEC_OPTIONS) do
                        if cg.class == mappedClass then
                            AML.UI.selectedSpec = cg.specs[1]
                            break
                        end
                    end
                    UIDropDownMenu_SetText(specDropDown, AML.UI.selectedClass .. " - " .. AML.UI.selectedSpec)
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    -- CLASS & SPEC DROPDOWN
    UIDropDownMenu_Initialize(specDropDown, function(self, level)
        level = level or 1
        if level == 1 then
            for _, classGroup in ipairs(AML.UI.SPEC_OPTIONS) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = classGroup.class
                info.hasArrow = true
                info.notCheckable = true
                info.value = classGroup
                UIDropDownMenu_AddButton(info, level)
            end
        elseif level == 2 then
            local classData = UIDROPDOWNMENU_MENU_VALUE
            if classData then
                for _, specName in ipairs(classData.specs) do
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = specName
                    info.checked = (AML.UI.selectedClass == classData.class and AML.UI.selectedSpec == specName)
                    info.func = function()
                        AML.UI.selectedClass = classData.class
                        AML.UI.selectedSpec = specName
                        UIDropDownMenu_SetText(specDropDown, classData.class .. " - " .. specName)
                        CloseDropDownMenus()
                    end
                    UIDropDownMenu_AddButton(info, level)
                end
            end
        end
    end)

    -- Add Button (+)
    local saveBtn = CreateFrame("Button", nil, inputFrame, "UIPanelButtonTemplate")
    saveBtn:SetSize(26, 18)
    saveBtn:SetPoint("LEFT", specDropDown, "RIGHT", -10, 2)
    saveBtn:SetText("+")
    saveBtn:SetNormalFontObject("GameFontNormalSmall")
    saveBtn:SetHighlightFontObject("GameFontNormalSmall")
    saveBtn:SetDisabledFontObject("GameFontDisableSmall")
    saveBtn:SetScript("OnClick", function()
        local name = AML.UI.selectedPlayerName
        if name and name ~= "" then
            local existingIndex = nil
            for i, entry in ipairs(AutoMasterLootDB.msChanges) do
                if entry.name:lower() == name:lower() then
                    existingIndex = i
                    break
                end
            end

            if existingIndex then
                AutoMasterLootDB.msChanges[existingIndex].class = AML.UI.selectedClass
                AutoMasterLootDB.msChanges[existingIndex].spec = AML.UI.selectedSpec
            else
                table.insert(AutoMasterLootDB.msChanges, {
                    name = name,
                    class = AML.UI.selectedClass,
                    spec = AML.UI.selectedSpec
                })
            end
            AML.UI:RefreshMSList()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[AML]|r Please select a player from the dropdown first.")
        end
    end)

    -- Table Header Labels
    local hdrNo = inputFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdrNo:SetPoint("TOPLEFT", 12, -58)
    hdrNo:SetText("No.")

    local hdrNama = inputFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdrNama:SetPoint("TOPLEFT", 38, -58)
    hdrNama:SetText("Name")

    local hdrClass = inputFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdrClass:SetPoint("TOPLEFT", 135, -58)
    hdrClass:SetText("Class")

    local hdrSpec = inputFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdrSpec:SetPoint("TOPLEFT", 225, -58)
    hdrSpec:SetText("Spec")

    -- Scroll Area MS List
    local scrollFrame = CreateFrame("ScrollFrame", "AML_ScrollFrame", inputFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(295, 160)
    scrollFrame:SetPoint("TOPLEFT", 10, -74)

    local contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame:SetSize(295, 1)
    scrollFrame:SetScrollChild(contentFrame)
    AML.UI.msContentFrame = contentFrame

    -- Footer Buttons
    local clearAllBtn = CreateFrame("Button", nil, inputFrame, "UIPanelButtonTemplate")
    clearAllBtn:SetSize(80, 20)
    clearAllBtn:SetPoint("BOTTOMLEFT", 10, 8)
    clearAllBtn:SetText("Clear All")
    clearAllBtn:SetNormalFontObject("GameFontNormalSmall")
    clearAllBtn:SetHighlightFontObject("GameFontNormalSmall")
    clearAllBtn:SetDisabledFontObject("GameFontDisableSmall")
    clearAllBtn:SetScript("OnClick", function()
        AutoMasterLootDB.msChanges = {}
        AML.UI:RefreshMSList()
    end)

    local closeBtn = CreateFrame("Button", nil, inputFrame, "UIPanelButtonTemplate")
    closeBtn:SetSize(60, 20)
    closeBtn:SetPoint("BOTTOMRIGHT", -10, 8)
    closeBtn:SetText("Close")
    closeBtn:SetNormalFontObject("GameFontNormalSmall")
    closeBtn:SetHighlightFontObject("GameFontNormalSmall")
    closeBtn:SetDisabledFontObject("GameFontDisableSmall")
    closeBtn:SetScript("OnClick", function() inputFrame:Hide() end)
end

-- Render & View Helpers
function AML.UI:UpdateButtonState()
    if AutoMasterLootDB.enabled then
        AML.UI.toggleBtn:SetText("Status: |cff00ff00ON|r")
    else
        AML.UI.toggleBtn:SetText("Status: |cffff0000OFF|r")
    end
end

function AML.UI:UpdateMainCounter()
    if AML.UI.mainMsCounter then
        AML.UI.mainMsCounter:SetText("MS Changes: |cff00ff00" .. #AutoMasterLootDB.msChanges .. "|r")
    end
end

function AML.UI:UpdateFilterLockState()
    local isLocked = AutoMasterLootDB.lockedFilters
    for _, cb in pairs(AML.UI.checkboxes) do
        if isLocked then cb:Disable() else cb:Enable() end
    end
    
    SetButtonEnabledState(AML.UI.announceBtn, not isLocked)
    SetButtonEnabledState(AML.UI.addMsBtn, not isLocked)
    SetButtonEnabledState(AML.UI.rollTrackerBtn, not isLocked)
end

function AML.UI:ClearSlotItem()
    AML.Core.currentItemRolling = ""
    AML.Core.currentItemLink = ""
    SetItemButtonTexture(AML.UI.itemSlot, nil)
    AML.UI.slotText:SetText("|cff808080Drag item here|r")
end

function AML.UI:SetSlotItem(itemLink)
    if not itemLink or itemLink == "" then return end
    local name, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemLink)
    if name then
        AML.Core.currentItemRolling = name
        AML.Core.currentItemLink = itemLink
        SetItemButtonTexture(AML.UI.itemSlot, texture)
        AML.UI.slotText:SetText(itemLink)
    else
        AML.Core.currentItemRolling = itemLink
        AML.Core.currentItemLink = itemLink
        SetItemButtonTexture(AML.UI.itemSlot, "Interface\\Icons\\INV_Misc_QuestionMark")
        AML.UI.slotText:SetText(itemLink)
    end
end

function AML.UI:RefreshRollList()
    for _, r in ipairs(AML.UI.rollRows) do r:Hide() end
    for i, rData in ipairs(AML.Core.activeRolls) do
        if not AML.UI.rollRows[i] then
            local r = CreateFrame("Frame", nil, AML.UI.rollContent)
            r:SetSize(270, 16)
            
            local numTxt = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            numTxt:SetPoint("LEFT", 0, 0)
            numTxt:SetWidth(25)
            numTxt:SetJustifyH("LEFT")
            r.numTxt = numTxt

            local nameTxt = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            nameTxt:SetPoint("LEFT", 30, 0)
            nameTxt:SetWidth(170)
            nameTxt:SetJustifyH("LEFT")
            r.nameTxt = nameTxt

            local rollValTxt = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            rollValTxt:SetPoint("RIGHT", -5, 0)
            rollValTxt:SetWidth(45)
            rollValTxt:SetJustifyH("RIGHT")
            r.rollValTxt = rollValTxt

            AML.UI.rollRows[i] = r
        end
        local r = AML.UI.rollRows[i]
        r:SetPoint("TOPLEFT", 0, -(i - 1) * 16)
        
        local hex = GetForcedClassColorHex(rData.class)
        r.numTxt:SetText("|cff808080" .. i .. ".|r")
        r.nameTxt:SetText("|c" .. hex .. rData.name .. "|r")
        r.rollValTxt:SetText("|cff00ff00" .. rData.roll .. "|r")
        r:Show()
    end
    AML.UI.rollContent:SetHeight(math.max(1, #AML.Core.activeRolls * 16))
end

function AML.UI:RefreshMSList()
    for _, row in ipairs(AML.UI.entryRows) do row:Hide() end
    AML.UI.popupCount:SetText("Total: |cff00ff00" .. #AutoMasterLootDB.msChanges .. "|r")
    AML.UI:UpdateMainCounter()

    for i, entry in ipairs(AutoMasterLootDB.msChanges) do
        if not AML.UI.entryRows[i] then
            local row = CreateFrame("Frame", nil, AML.UI.msContentFrame)
            row:SetSize(295, 18)
            
            local numTxt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            numTxt:SetPoint("LEFT", 2, 0)
            numTxt:SetWidth(24)
            numTxt:SetJustifyH("LEFT")
            row.numTxt = numTxt

            local nameTxt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            nameTxt:SetPoint("LEFT", 28, 0)
            nameTxt:SetWidth(95)
            nameTxt:SetJustifyH("LEFT")
            row.nameTxt = nameTxt

            -- Lebar kolom class diperlebar dari 75/85 menjadi 90 agar "Death Knight" tidak terpotong
            local classTxt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            classTxt:SetPoint("LEFT", 125, 0)
            classTxt:SetWidth(90)
            classTxt:SetJustifyH("LEFT")
            row.classTxt = classTxt

            local specTxt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            specTxt:SetPoint("LEFT", 220, 0)
            specTxt:SetWidth(55)
            specTxt:SetJustifyH("LEFT")
            row.specTxt = specTxt

            local delBtn = CreateFrame("Button", nil, row)
            delBtn:SetSize(14, 14)
            delBtn:SetPoint("RIGHT", 0, 0)
            delBtn:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
            row.delBtn = delBtn
            
            AML.UI.entryRows[i] = row
        end

        local row = AML.UI.entryRows[i]
        row:SetPoint("TOPLEFT", 0, -(i - 1) * 18)
        
        local hex = GetForcedClassColorHex(entry.class or "")
        
        row.numTxt:SetText("|cff808080" .. i .. ".|r")
        row.nameTxt:SetText("|cffffffff" .. entry.name .. "|r")
        row.classTxt:SetText("|c" .. hex .. (entry.class or "-") .. "|r")
        row.specTxt:SetText("|cff00ff00" .. entry.spec .. "|r")
        
        row.delBtn:SetScript("OnClick", function()
            table.remove(AutoMasterLootDB.msChanges, i)
            AML.UI:RefreshMSList()
        end)
        row:Show()
    end
    AML.UI.msContentFrame:SetHeight(math.max(1, #AutoMasterLootDB.msChanges * 18))
end

function AML.UI:LoadPage(pageIndex)
    local totalSessions = #AutoMasterLootDB.sessions
    local totalPages = totalSessions + 1
    
    if pageIndex < 1 then 
        pageIndex = 1 
    elseif pageIndex > totalPages then 
        pageIndex = totalPages 
    end
    
    AML.Core.currentPageIndex = pageIndex
    AML.UI.pageIndicator:SetText("Page " .. AML.Core.currentPageIndex .. "/" .. totalPages)

    local isHistoryPage = (AML.Core.currentPageIndex <= totalSessions)
    
    for _, btn in pairs(AML.UI.modeButtons) do
        SetButtonEnabledState(btn, not isHistoryPage)
    end

    if isHistoryPage then
        local data = AutoMasterLootDB.sessions[AML.Core.currentPageIndex]
        if data then
            AML.UI:SetSlotItem(data.item)
            AML.Core.selectedRollType = data.mode
            AML.Core.winnerName = data.winner
            AML.Core.winnerRoll = data.winnerRoll
            AML.Core.activeRolls = data.rolls or {}
            AML.UI:RefreshRollList()
        end
    else
        AML.Core:StopRollTimer()
        AML.Core.activeRolls = {}
        AML.Core.winnerName = nil
        AML.Core.winnerRoll = 0
        AML.UI:ClearSlotItem()
        AML.UI:RefreshRollList()
    end
end