-- ========================================================
-- AML CORE MODULE (Database, State, Logic, Event Handler)
-- ========================================================
AML = AML or {}
AML.Core = {}

-- Database Initialization
function AML.Core:InitDB()
    if not AutoMasterLootDB then
        AutoMasterLootDB = {
            enabled = true,
            lockedUI = false,
            lockedFilters = false,
            [2] = true, [3] = true, [4] = true, [5] = true,
            msChanges = {},
            sessions = {}
        }
    end

    if AutoMasterLootDB.enabled == nil then AutoMasterLootDB.enabled = true end
    if AutoMasterLootDB.lockedUI == nil then AutoMasterLootDB.lockedUI = false end
    if AutoMasterLootDB.lockedFilters == nil then AutoMasterLootDB.lockedFilters = false end
    if not AutoMasterLootDB.msChanges then AutoMasterLootDB.msChanges = {} end
    if not AutoMasterLootDB.sessions then AutoMasterLootDB.sessions = {} end
end

-- State Variables
AML.Core.currentItemRolling = ""
AML.Core.currentItemLink = ""
AML.Core.activeRolls = {}
AML.Core.winnerName = nil
AML.Core.winnerRoll = 0
AML.Core.isTimerRunning = false
AML.Core.timerDuration = 10
AML.Core.timerRemaining = 0
AML.Core.selectedRollType = "MS"
AML.Core.currentPageIndex = 1

AML.Core.QUALITY_OPTIONS = {
    { text = "|cff1eff00Uncommon|r", val = 2 },
    { text = "|cff0070ddRare|r",     val = 3 },
    { text = "|cffa335eeEpic|r",     val = 4 },
    { text = "|cffff8000Legendary|r",val = 5 },
}

-- Utility Functions
function AML.Core:SendMessage(msg, isRW)
    if isRW and GetNumRaidMembers() > 0 then
        SendChatMessage(msg, "RAID_WARNING")
    elseif GetNumRaidMembers() > 0 then
        SendChatMessage(msg, "RAID")
    elseif GetNumPartyMembers() > 0 then
        SendChatMessage(msg, "PARTY")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[AML]|r " .. msg)
    end
end

function AML.Core:GetClassColorHex(className)
    if not className then return "ffffffff" end
    local color = RAID_CLASS_COLORS[string.upper(className)]
    if color then
        return string.format("ff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
    end
    return "ffffffff"
end

function AML.Core:GetPlayerClass(name)
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local rName, _, _, _, _, fileName = GetRaidRosterInfo(i)
            if rName == name then return fileName end
        end
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            if UnitName("party"..i) == name then
                local _, fileName = UnitClass("party"..i)
                return fileName
            end
        end
    end
    if name == UnitName("player") then
        local _, fileName = UnitClass("player")
        return fileName
    end
    return nil
end

-- Timer Control Logic
local timerFrame = CreateFrame("Frame")

function AML.Core:StopRollTimer()
    AML.Core.isTimerRunning = false
    timerFrame:SetScript("OnUpdate", nil)
    if AML.UI and AML.UI.timerText then
        AML.UI.timerText:SetText("|cffff0000Timer: 0s|r")
    end
end

function AML.Core:SaveCurrentSessionToHistory()
    if AML.Core.currentItemLink ~= "" then
        local sessionData = {
            item = AML.Core.currentItemLink,
            mode = AML.Core.selectedRollType,
            winner = AML.Core.winnerName or "No Winner",
            winnerRoll = AML.Core.winnerRoll,
            rolls = AML.Core.activeRolls
        }
        table.insert(AutoMasterLootDB.sessions, sessionData)
        AML.Core.currentPageIndex = #AutoMasterLootDB.sessions + 1
    end
end

function AML.Core:ResetRollSession(isCanceled)
    if AML.Core.isTimerRunning and isCanceled and AML.Core.currentItemLink ~= "" then
        AML.Core:SendMessage("=== ROLL CANCELED FOR " .. AML.Core.currentItemLink .. " [" .. AML.Core.selectedRollType .. "] ===", true)
    end
    AML.Core:StopRollTimer()
    AML.Core.activeRolls = {}
    AML.Core.winnerName = nil
    AML.Core.winnerRoll = 0
    AML.UI:ClearSlotItem()
    AML.UI:RefreshRollList()
end

function AML.Core:AnnounceWinner()
    if AML.Core.winnerName then
        AML.Core:SendMessage("Winner for " .. AML.Core.currentItemLink .. " [" .. AML.Core.selectedRollType .. "] is " .. AML.Core.winnerName .. " with roll (" .. AML.Core.winnerRoll .. ")!", true)
    else
        AML.Core:SendMessage("No rolls recorded for " .. AML.Core.currentItemLink .. " [" .. AML.Core.selectedRollType .. "].", true)
    end
end

function AML.Core:StartRollTimer(category)
    if AML.Core.currentItemLink == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[AML]|r Please drag an item into the slot first!")
        return
    end

    AML.Core.selectedRollType = category
    AML.Core:StopRollTimer()
    AML.Core.activeRolls = {}
    AML.Core.winnerName = nil
    AML.Core.winnerRoll = 0
    AML.UI:RefreshRollList()

    AML.Core:SendMessage("Roll " .. AML.Core.currentItemLink .. " [" .. AML.Core.selectedRollType .. "] - 10 Seconds!", true)
    
    AML.Core.isTimerRunning = true
    AML.Core.timerRemaining = AML.Core.timerDuration
    local lastAnnouncedSecond = 10
    
    if AML.UI.timerText then AML.UI.timerText:SetText("|cff00ff00Timer: 10s|r") end

    timerFrame:SetScript("OnUpdate", function(self, elapsed)
        if not AML.Core.isTimerRunning then return end
        AML.Core.timerRemaining = AML.Core.timerRemaining - elapsed
        
        local currentSec = math.ceil(AML.Core.timerRemaining)
        if currentSec < 0 then currentSec = 0 end
        
        if AML.UI.timerText then AML.UI.timerText:SetText("|cff00ff00Timer: " .. currentSec .. "s|r") end

        if currentSec ~= lastAnnouncedSecond then
            if currentSec == 5 or currentSec == 3 or currentSec == 2 or currentSec == 1 then
                AML.Core:SendMessage("Roll " .. AML.Core.currentItemLink .. " [" .. AML.Core.selectedRollType .. "] - " .. currentSec .. "s remaining!", true)
            end
            lastAnnouncedSecond = currentSec
        end

        if AML.Core.timerRemaining <= 0 then
            AML.Core:StopRollTimer()
            AML.Core:SendMessage("=== ROLL CLOSED FOR " .. AML.Core.currentItemLink .. " [" .. AML.Core.selectedRollType .. "] ===", true)
            AML.Core:AnnounceWinner()
            AML.Core:SaveCurrentSessionToHistory()
        end
    end)
end

-- Global Event Manager Frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("LOOT_OPENED")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
eventFrame:RegisterEvent("TRADE_SHOW")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "AutoMasterLoot" then
        AML.Core:InitDB()
        AML.UI:BuildGUI()
        AML.UI:UpdateButtonState()
        for val, cb in pairs(AML.UI.checkboxes) do
            local isChecked = (AutoMasterLootDB[val] == nil) and true or AutoMasterLootDB[val]
            cb:SetChecked(isChecked)
        end
        AML.UI:UpdateFilterLockState()
        AML.UI:UpdateMainCounter()
        AML.UI:LoadPage(#AutoMasterLootDB.sessions + 1)

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

    elseif event == "CHAT_MSG_SYSTEM" then
        if AML.Core.currentItemRolling ~= "" and AML.Core.isTimerRunning then
            local pName, roll, minR, maxR = string.match(arg1, "^(%S+) rolls (%d+) %((%d+)%-(%d+)%)$")
            if pName and tonumber(minR) == 1 and tonumber(maxR) == 100 then
                local numRoll = tonumber(roll)
                local alreadyRolled = false
                for _, rData in ipairs(AML.Core.activeRolls) do
                    if rData.name == pName then alreadyRolled = true break end
                end

                if not alreadyRolled then
                    local pClass = AML.Core:GetPlayerClass(pName)
                    table.insert(AML.Core.activeRolls, { name = pName, roll = numRoll, class = pClass })
                    table.sort(AML.Core.activeRolls, function(a, b) return a.roll > b.roll end)
                    
                    if numRoll > AML.Core.winnerRoll then
                        AML.Core.winnerRoll = numRoll
                        AML.Core.winnerName = pName
                    end
                    AML.UI:RefreshRollList()
                end
            end
        end

    elseif event == "TRADE_SHOW" then
        if AML.Core.winnerName and AML.Core.currentItemRolling ~= "" then
            local targetName = UnitName("NPC") or UnitName("target")
            if targetName == AML.Core.winnerName then
                for b = 0, 4 do
                    for s = 1, GetContainerNumSlots(b) do
                        local link = GetContainerItemLink(b, s)
                        if link and string.find(link, AML.Core.currentItemRolling, 1, true) then
                            UseContainerItem(b, s)
                            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[AML]|r Auto-placed " .. AML.Core.currentItemRolling .. " into trade window for " .. AML.Core.winnerName)
                            return
                        end
                    end
                end
            end
        end
    end
end)

SLASH_AUTOMASTERLOOT1 = "/aml"
SlashCmdList["AUTOMASTERLOOT"] = function()
    if AML.UI and AML.UI.gui then
        if AML.UI.gui:IsShown() then AML.UI.gui:Hide() else AML.UI.gui:Show() end
    end
end