-------------------------------------------------------------------------------
-- sarAutoConfirmOptions.lua
-------------------------------------------------------------------------------

local function EnsureTables()
    if not sarAutoConfirmDB       then sarAutoConfirmDB       = {} end
    if not sarAutoConfirmCharDB   then sarAutoConfirmCharDB   = {} end
end

local function GetSetting(key, default)
    EnsureTables()
    if sarAutoConfirmCharDB[key] ~= nil then return sarAutoConfirmCharDB[key] end
    if sarAutoConfirmDB[key]     ~= nil then return sarAutoConfirmDB[key]     end
    return default
end

local function SetSetting(key, value)
    EnsureTables()
    sarAutoConfirmCharDB[key] = value
    sarAutoConfirmDB[key]     = value
end

local panel = CreateFrame("Frame")
panel.name  = "sarAutoConfirm"

panel.refresh = function()
    if panel.chatBox  then panel.chatBox:SetChecked(GetSetting("showChatMessages",1)==1) end
    if panel.emailBox then panel.emailBox:SetText(GetSetting("email","")) end
    if panel.currentEmailLabel then
        local email = GetSetting("email", "")
        panel.currentEmailLabel:SetText("Текущий e-mail: " .. (email ~= "" and email or "<не задан>"))
    end
end

panel:SetScript("OnShow", function(self)
    if self.inited then return end
    self.inited = true

    local title = self:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
    title:SetPoint("TOPLEFT",16,-16)
    title:SetText("sarAutoConfirm")

    local chatBox = CreateFrame("CheckButton",nil,self,"UICheckButtonTemplate")
    chatBox:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-20)
    chatBox:SetChecked(GetSetting("showChatMessages",1)==1)
    self.chatBox = chatBox

    local chatLabel = self:CreateFontString(nil,"ARTWORK","GameFontNormal")
    chatLabel:SetPoint("LEFT",chatBox,"RIGHT",6,0)
    chatLabel:SetText("Показывать сообщения в чате")

    chatBox:SetScript("OnClick",function(btn)
        local v = btn:GetChecked() and 1 or 0
        SetSetting("showChatMessages",v)
        print("sarAutoConfirm: вывод сообщений: "..(v==1 and "включён" or "выключен"))
    end)

    local emailLabel = self:CreateFontString(nil,"ARTWORK","GameFontNormal")
    emailLabel:SetPoint("TOPLEFT",chatBox,"BOTTOMLEFT",0,-24)
    emailLabel:SetText("E-mail для подтверждения:")

    local emailBox = CreateFrame("EditBox",nil,self,"InputBoxTemplate")
    emailBox:SetPoint("TOPLEFT",emailLabel,"BOTTOMLEFT",0,-6)
    emailBox:SetSize(220,20)
    emailBox:SetAutoFocus(false)
    emailBox:SetText(GetSetting("email",""))
    self.emailBox = emailBox

    local saveBtn = CreateFrame("Button",nil,self,"UIPanelButtonTemplate")
    saveBtn:SetSize(80,22)
    saveBtn:SetPoint("LEFT",emailBox,"RIGHT",8,0)
    saveBtn:SetText("Сохранить")

    local currentEmailLabel = self:CreateFontString(nil,"ARTWORK","GameFontNormalSmall")
    currentEmailLabel:SetPoint("TOPLEFT",emailBox,"BOTTOMLEFT",0,-8)
    currentEmailLabel:SetTextColor(0.75, 0.75, 0.75)
    self.currentEmailLabel = currentEmailLabel

    local function SaveEmail()
        local txt = emailBox:GetText():trim()
        SetSetting("email", txt)
        currentEmailLabel:SetText("Текущий e-mail: " .. (txt ~= "" and txt or "<не задан>"))
    end

    saveBtn:SetScript("OnClick", SaveEmail)
    emailBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); SaveEmail() end)

    -- Подпись внизу
    local footerLabel = self:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    footerLabel:SetPoint("BOTTOMLEFT", 16, 10)
    footerLabel:SetText("Автор: Сарыч    WoWCircle 3.3.5")

    -- Обновим текущий e-mail сразу
    panel.refresh()
end)

InterfaceOptions_AddCategory(panel)

SLASH_SARAUTOCONFIRM1 = "/sac"
SlashCmdList["SARAUTOCONFIRM"] = function(msg)
    msg = (msg or ""):lower():trim()

    if msg == "status" then
        print("== sarAutoConfirm ==")
        print("  e-mail: "..(GetSetting("email","")~="" and GetSetting("email") or "<не задан>"))
        print("  вывод в чат: "..(GetSetting("showChatMessages",1)==1 and "вкл" or "выкл"))

    elseif msg:match("^email ") then
        local v = msg:gsub("^email%s+","")
        SetSetting("email",v)
        print("e-mail сохранён: "..v)

    elseif msg == "chat on"  then SetSetting("showChatMessages",1); print("вывод сообщений включён")
    elseif msg == "chat off" then SetSetting("showChatMessages",0); print("вывод сообщений выключен")
    else
        print("/sac status  – текущие настройки")
        print("/sac email <адрес>  – задать e-mail")
        print("/sac chat on|off    – включить / выключить вывод сообщений")
    end
end
