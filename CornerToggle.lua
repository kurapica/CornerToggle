--========================================================--
--                Corner Toggle                           --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2018/01/12                              --
--========================================================--

--========================================================--
Scorpio            "CornerToggle"                    "1.0.0"
--========================================================--

BIND_OFF    = 0
BIND_FRAME  = 1
BIND_CORNER = 2

----------------------------------------------
--------------- Choose Frame Mask ------------
----------------------------------------------
local _MaskMode = BIND_OFF
local _ChooseFrame
local _MouseFocusInitFrame
local _MouseFocusFrame

local _Mask = CreateFrame("Button", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
_Mask:Hide()
_Mask:SetToplevel(true)
_Mask:SetFrameStrata("TOOLTIP")
_Mask:EnableMouse(true)
_Mask:EnableMouseWheel(true)
_Mask:RegisterForClicks("AnyUp")
_Mask:SetBackdrop{
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
}
_Mask:SetBackdropColor(0, 1, 0, 0.8)

_Mask:SetScript("OnClick", function(self, btn)
    if btn == "LeftButton" then
        _ChooseFrame = _MouseFocusFrame
        _MaskMode    = BIND_CORNER
        Manager:GetAttribute("BINDMOD", BIND_CORNER)
    else
        _ChooseFrame = nil
        _MaskMode    = BIND_OFF
        Manager:GetAttribute("BINDMOD", nil)
    end
end)

_Mask:SetScript("OnMouseWheel", function(self, wheel)
    if wheel > 0 then
        if _MouseFocusFrame then
            local parent = _MouseFocusFrame:GetParent()
            if parent and parent ~= UIParent and parent ~= WorldFrame and parent:GetName() then
                _MouseFocusFrame = parent
                ShowGameTooltip()
            end
        end
    else
        if _MouseFocusInitFrame then
            _MouseFocusFrame = _MouseFocusInitFrame
            ShowGameTooltip()
        end
    end
end)

----------------------------------------------
---------------- Secure Manager --------------
----------------------------------------------
Manager = CreateFrame("Frame", "CornerToggle_Manager", UIParent, "SecureFrameTemplate")
Manager:Hide()
Manager.Execute     = SecureHandlerExecute
Manager.WrapScript  = function(self, frame, script, preBody, postBody) return SecureHandlerWrapScript(frame, script, self, preBody, postBody) end
Manager.SetFrameRef = SecureHandlerSetFrameRef

SecurePanel = {}

Manager:Execute[[
    _Manager = self
    _CornerButtons = newtable()
    _Corner = newtable()
]]

REGISTER_CORNER = [[
    local corner = %q
    _Corner[corner] = newtable()
    _CornerButtons[corner] = _Manager:GetFrameRef(corner)
]]

REGISTER_FRAME = [[
    local corner = %q
    local frame = _Manager:GetFrameRef(corner)
    for _, frm in ipairs(_Corner[corner]) do
        if frame == frm then return end
    end
    tinsert(_Corner[corner], frame)
    if _CornerButtons[corner]:GetAttribute("CornerShow") then
        frame:Show()
    else
        frame:Hide()
    end
]]

UNREGISTER_FRAME = [[
    local corner = %q
    local frame = _Manager:GetFrameRef(corner)
    for i, frm in ipairs(_Corner[corner]) do
        if frame == frm then return tremove(_Corner[corner], i):Show() end
    end
]]

ENTER_CORNER = [[
    local corner = %q
    if _Manager:GetAttribute("BINDMOD") then return end
    if not self:GetAttribute("CornerShow") then
        for _, frm in ipairs(_Corner[corner]) do
            frm:Show()
        end
    end
    return _Manager:CallMethod("OnEnter", corner)
]]

LEAVE_CORNER = [[
    local corner = %q
    if not self:GetAttribute("CornerShow") then
        for _, frm in ipairs(_Corner[corner]) do
            frm:Hide()
        end
    end
    return _Manager:CallMethod("OnLeave", corner)
]]

CLICK_CORNER = [[
    local corner = %q
    if not _Manager:GetAttribute("BINDMOD") then
        if button == "RightButton" then
            self:SetAttribute("CornerShow", true)
            for _, frm in ipairs(_Corner[corner]) do
                frm:Show()
            end
            wipe(_Corner[corner])
        else
            self:SetAttribute("CornerShow", not self:GetAttribute("CornerShow"))
            if self:GetAttribute("CornerShow") then
                for _, frm in ipairs(_Corner[corner]) do
                    frm:Show()
                end
            else
                for _, frm in ipairs(_Corner[corner]) do
                    frm:Hide()
                end
            end
        end
    end
    return _Manager:CallMethod("OnClick", corner, button)
]]

function Manager:Register(btn)
    local corner = btn.Corner
    self:SetFrameRef(corner, btn)
    self:Execute(REGISTER_CORNER:format(corner))

    self:WrapScript(btn, "OnEnter", ENTER_CORNER:format(corner))
    self:WrapScript(btn, "OnLeave", LEAVE_CORNER:format(corner))
    self:WrapScript(btn, "OnClick", CLICK_CORNER:format(corner))
end

function Manager:RegisterFrame(corner, frame)
    local _, protected = frame:IsProtected()
    if protected then
        SecurePanel[frame] = true
        self:SetFrameRef(corner, frame)
        self:Execute(REGISTER_FRAME:format(corner))
    end
end

function Manager:UnregisterFrame(corner, frame)
    local _, protected = frame:IsProtected()
    if protected then
        SecurePanel[frame] = nil
        self:SetFrameRef(corner, frame)
        self:Execute(UNREGISTER_FRAME:format(corner))
    end
end

function Manager:OnEnter(corner)
    if _MaskMode ~= BIND_OFF then return end

    ToggleCorner(corner, true)
end

function Manager:OnLeave(corner)
    ToggleCorner(corner)
end

function Manager:OnClick(corner, button)
    if _MaskMode == BIND_CORNER then
        if button == "LeftButton" then
            if _ChooseFrame then
                local name = _ChooseFrame:GetName(true)

                -- Remove if existed
                for corner in pairs(_CornerButtons) do
                    for i, n in ipairs(_SVDB[corner]) do
                        if n == name then
                            tremove(_SVDB[corner], i)
                            Manager:UnregisterFrame(corner, _ChooseFrame)
                            break
                        end
                    end
                end

                -- Add to the corner
                tinsert(_SVDB[corner], name)
                Manager:RegisterFrame(corner, _ChooseFrame)

                ToggleCorner(corner)
            end
        end

        HideGameTooltip()
        _MaskMode       = BIND_OFF
        Manager:SetAttribute("BINDMOD", nil)
        _ChooseFrame    = nil

        ToggleActive()
    else
        if button == "LeftButton" then
            ToggleCorner(corner)
        elseif button == "RightButton" then
            ToggleCorner(corner)
            wipe(_SVDB[corner])
        end
    end
end

----------------------------------------------
-------------- Addon Event Handler -----------
----------------------------------------------
_CornerButtons = { TOPLEFT = true , BOTTOMLEFT = true, TOPRIGHT = true, BOTTOMRIGHT = true }
_UnFoundFrames = {}

function OnLoad(self)
    _SVDB = SVManager.SVCharManager("CornerToggle_DB")
    _SVDB:SetDefault {
        CornerShow  = {
            TOPLEFT     = true,
            BOTTOMLEFT  = true,
            TOPRIGHT    = true,
            BOTTOMRIGHT = true,
        },
        TOPLEFT     = {},
        BOTTOMLEFT  = {},
        TOPRIGHT    = {},
        BOTTOMRIGHT = {},
    }
end

function OnEnable(self)
    for k in pairs(_CornerButtons) do
        local cb = CreateFrame("Button", "CornerToggle_" .. k, UIParent, _G.BackdropTemplateMixin and "SecureActionButtonTemplate, BackdropTemplate" or "SecureActionButtonTemplate")

        cb.Corner = k
        cb:SetAttribute("Corner", k)
        cb:SetAttribute("CornerShow", _SVDB.CornerShow[k])
        cb:SetPoint(k, k:match("LEFT") and -4 or 4, k:match("TOP") and 4 or -4)
        cb:SetSize(48, 48)
        cb:SetToplevel(true)
        cb:SetFrameStrata("TOOLTIP")
        cb:EnableMouse(true)
        cb:RegisterForClicks("AnyUp")
        cb:SetBackdrop{
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        }
        cb:SetBackdropColor(0, 1, 0, 0.8)
        cb:SetAlpha(0)

        _CornerButtons[k] = cb

        Manager:Register(cb)

        for _, name in ipairs(_SVDB[k]) do
            _UnFoundFrames[name] = k
        end
    end

    ScanFrames()

    ToggleActive()
    ToggleAllCorners()
end

function OnQuit(self)
    for k, btn in pairs(_CornerButtons) do
        if type(btn) == "table" then
            _SVDB.CornerShow[k] = btn:GetAttribute("CornerShow")
        end
    end

    ToggleAllCorners(true)
end

----------------------------------------------
-------------- Addon Slash Command -----------
----------------------------------------------
__SlashCmd__"corner" "bind" "- [name] Bind a frame to screen corner"
__Async__()
function CornerBind(name)
    if name and _G[name] and _G[name].GetName then
        _MaskMode = BIND_CORNER
        Manager:SetAttribute("BINDMOD", BIND_CORNER)
        _ChooseFrame = _G[name]
    else
        _MaskMode = BIND_FRAME
        Manager:SetAttribute("BINDMOD", BIND_FRAME)
        _ChooseFrame = nil
        _MouseFocusInitFrame = nil
        _MouseFocusFrame = nil

        ToggleActive("Hide")

        while _MaskMode == BIND_FRAME and not InCombatLockdown() do
            local frame = GetMouseFocus()

            if frame ~= _Mask then
                while frame and not frame:GetName() do
                    frame = frame:GetParent()
                end

                if _MouseFocusInitFrame ~= frame then
                    if frame == UIParent or frame == WorldFrame then
                        if _MouseFocusInitFrame then
                            _MouseFocusInitFrame = nil
                            _MouseFocusFrame = nil
                            _Mask:ClearAllPoints()
                            _Mask:Hide()
                            _Mask:SetParent(nil)
                            HideGameTooltip()
                        end
                    else
                        _MouseFocusInitFrame = frame
                        _MouseFocusFrame = frame
                        _Mask:SetParent(frame)
                        _Mask:SetAllPoints(frame)
                        _Mask:Show()
                        Next()
                        ShowGameTooltip()
                    end
                end
            end

            Next()
        end

        HideGameTooltip()

        _Mask:Hide()
        _Mask:ClearAllPoints()
        _Mask:SetParent(nil)

        ToggleActive()
    end

    if _MaskMode == BIND_CORNER and _ChooseFrame then
        ToggleActive("Show", 1)
    else
        ToggleActive()
    end
end

----------------------------------------------
------------------ Addon Helper --------------
----------------------------------------------
function ShowGameTooltip()
    if _Mask:IsVisible() and _MouseFocusFrame then
        GameTooltip:SetOwner(_Mask, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText(_MouseFocusFrame:GetName())
        GameTooltip:Show()
    end
end

function HideGameTooltip()
    GameTooltip:Hide()
end

__NoCombat__()
function ToggleActive(method, alpha)
    method = method or "Show"
    for _, v in pairs(_CornerButtons) do
        v[method](v)
        v:SetAlpha(alpha or 0)
    end
end

function ToggleAllCorners(show)
    for k, v in pairs(_CornerButtons) do
        ToggleCorner(k, show)
    end
end

__NoCombat__()
function ToggleCorner(corner, show)
    local method = (show or _CornerButtons[corner]:GetAttribute("CornerShow")) and "Show" or "Hide"

    for _, v in ipairs(_SVDB[corner]) do
        local frame = Scorpio.UI.UIObject.FromName(v)
        if frame and not SecurePanel[frame] then
            frame[method](frame)
        end
    end
end

__Async__()
function ScanFrames()
    while next(_UnFoundFrames) do
        NoCombat()

        for k, c in pairs(_UnFoundFrames) do
            if _G[k] then
                _UnFoundFrames[k] = nil
                Manager:RegisterFrame(c, _G[k])
            end
        end

        Next()
    end

    _UnFoundFrames = nil
end