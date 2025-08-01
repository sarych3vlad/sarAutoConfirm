-------------------------------------------------------------------------------
-- sarAutoConfirm.lua
-------------------------------------------------------------------------------

local f = CreateFrame("Frame", "sarAutoConfirmCore")

-------------------------------------------------
-- SavedVariables utils
-------------------------------------------------
local function GetSetting(key, default)
    if sarAutoConfirmCharDB and sarAutoConfirmCharDB[key] ~= nil then
        return sarAutoConfirmCharDB[key]
    end
    if sarAutoConfirmDB and sarAutoConfirmDB[key] ~= nil then
        return sarAutoConfirmDB[key]
    end
    return default
end

local function IsDebug()
    local v = GetSetting("showChatMessages", 1)
    return v == 1 or v == true
end

local EMAIL = ""
local function LoadEmail() EMAIL = GetSetting("email", "") end

local function DebugPrint(msg)
    if IsDebug() then
        print("sarAutoConfirm: " .. msg)
    end
end

-------------------------------------------------
-- Chain logic
-------------------------------------------------
local active, step, timer = false, 0, 0
local TIMEOUT = 15
local function Reset() active, step, timer = false, 0, 0 end

-------------------------------------------------
-- Events
-------------------------------------------------
f:RegisterEvent("VARIABLES_LOADED")
f:RegisterEvent("CHAT_MSG_SYSTEM")
f:RegisterEvent("GOSSIP_SHOW")
f:RegisterEvent("PLAYER_ENTERING_WORLD")

-------------------------------------------------
-- Следим за GMChatStatusFrame
-------------------------------------------------
local gmSeen = false      -- true, пока окно показано и мы уже реагировали

local watcher = CreateFrame("Frame")
watcher:SetScript("OnUpdate", function()
    if GMChatStatusFrame then
        if GMChatStatusFrame:IsShown() then
            if not gmSeen then
            gmSeen = true
            if not active then
                DebugPrint("обнаружено окно GM-чата, запускаю цепочку")
                if GMChatStatusFrame and GMChatStatusFrame:IsShown() then
                    GMChatStatusFrame:Hide()
                    DebugPrint("окно GM-чата скрыто")
                end
                active, step, timer = true, 0, 0
                SendChatMessage(".menu", "SAY")
                DebugPrint("команда .menu отправлена")
            end
        end
        else
            gmSeen = false                -- окно закрыли -> готово к новому появлению
        end
    end
end)

-------------------------------------------------
-- Основной обработчик
-------------------------------------------------
f:SetScript("OnEvent", function(self, event, ...)
    if event == "VARIABLES_LOADED" then
        LoadEmail()
        DebugPrint(EMAIL == "" and "загружен; e-mail не задан" or "загружен")

    elseif event == "CHAT_MSG_SYSTEM" then
        local msg = ...
        if msg and (msg:find("изменение подсети") or msg:find("В целях безопасности некоторые действия временно недоступны")) then
            DebugPrint("обнаружено сообщение-триггер, запускаю цепочку")
            active, step, timer = true, 0, 0
            SendChatMessage(".menu", "SAY")
            DebugPrint("команда .menu отправлена")
        end

    elseif event == "GOSSIP_SHOW" and active then
        if step == 0 then
            for i = 1, 32 do
                local b = _G["GossipTitleButton"..i]
                if b and b:IsShown() and b:GetText() == "Действия с персонажем" then
                    DebugPrint("нажимаю «Действия с персонажем»")
                    b:Click(); step, timer = 1, 0; return
                end
            end
            DebugPrint("«Действия с персонажем» не найдено, стоп"); Reset()

        elseif step == 1 then
            for i = 1, 32 do
                local b = _G["GossipTitleButton"..i]
                if b and b:IsShown() and b:GetText() == "Проверка эл. почты" then
                    DebugPrint("нажимаю «Проверка эл. почты»")
                    b:Click(); step, timer = 2, 0; return
                end
            end
            DebugPrint("«Проверка эл. почты» не найдено, закрываю окно")
            if GossipFrame and GossipFrame:IsShown() then CloseGossip() end
            Reset()
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        LoadEmail()
        Reset()
        gmSeen = false                     -- чтобы не застрять при перезаходе с открытым UI
    end
end)

-------------------------------------------------
-- OnUpdate: StaticPopup шаги
-------------------------------------------------
f:SetScript("OnUpdate", function(_, elapsed)
    if not active then return end
    timer = timer + elapsed
    if timer > TIMEOUT then
        DebugPrint("превышено время ожидания, стоп"); Reset(); return
    end

    if step == 2 then
        if StaticPopup1 and StaticPopup1:IsShown()
           and StaticPopup1Button1 and StaticPopup1Button1:IsShown() then
            DebugPrint("подтверждаю первое окно")
            StaticPopup1Button1:Click(); step, timer = 3, 0
        end

    elseif step == 3 then
        if StaticPopup1 and StaticPopup1:IsShown()
           and StaticPopup1EditBox and StaticPopup1EditBox:IsShown() then
            DebugPrint("ввожу e-mail («"..EMAIL.."») и подтверждаю")
            StaticPopup1EditBox:SetText(EMAIL)
            StaticPopup1Button1:Click()
            DebugPrint("подтверждение завершено")
            Reset()
        end
    end
end)
