-- ====================================================================
-- Project: Aero Suite // Muscle Legends (Ruby Edition)
-- Description: Ультра-быстрый фарм, моментальное перерождение и Premium UI
-- Version: 4.0 (Redesign + Turbo)
-- ====================================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- [Защита от AFK]
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end)

-- [Состояние функций]
local State = {
    WalkSpeed = 50, EnableWalkSpeed = false,
    InfiniteJump = false,
    AutoFarmWeight = false, AutoFarmPushups = false, AutoFarmSitups = false, AutoFarmPunch = false,
    FastMode = false,
    
    AutoRebirth = false, SmartAutoRebirth = true, RequiredStrength = 10000, AntiTeleportIfRebirthed = true,
    
    AutoJoinBrawl = false, AutoClaimGift = false,
    
    SelectedPlayer = "", HighlightTarget = false, TargetAutoKill = false
}

local TargetHighlightInstance = nil

-- [Сетевой слой]
local function FireMuscleEvent(action, hand)
    pcall(function()
        local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
        local event = (LocalPlayer:FindFirstChild("muscleEvent") or (rEvents and rEvents:FindFirstChild("muscleEvent")))
        if event then
            if hand then event:FireServer(action, hand) else event:FireServer(action) end
        end
    end)
end

local function TryRebirth()
    pcall(function()
        local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
        if not rEvents then return end
        for _, rName in ipairs({"rebirthRemote", "rebirthEvent", "reberthRemote"}) do
            local remote = rEvents:FindFirstChild(rName)
            if remote then
                if remote:IsA("RemoteEvent") then remote:FireServer("rebirthRequest")
                elseif remote:IsA("RemoteFunction") then remote:InvokeServer("rebirthRequest") end
            end
        end
    end)
end

local function FireRemote(remoteName, ...)
    local args = {...}
    pcall(function()
        local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
        if rEvents and rEvents:FindFirstChild(remoteName) then
            if rEvents[remoteName]:IsA("RemoteEvent") then rEvents[remoteName]:FireServer(unpack(args))
            elseif rEvents[remoteName]:IsA("RemoteFunction") then rEvents[remoteName]:InvokeServer(unpack(args)) end
        end
    end)
end
-- ЛОГИКА: ТУРБО-ФАРМ, ПЕРЕРОЖДЕНИЕ, СКОРОСТЬ (Heartbeat)

RunService.Heartbeat:Connect(function()
pcall(function()
-- 1. Турбо-Фарм
local spamMultiplier = State.FastMode and 3 or 1
for i = 1, spamMultiplier do
if State.AutoFarmWeight then FireMuscleEvent("rep") end
if State.AutoFarmPushups then FireMuscleEvent("rep") end
if State.AutoFarmSitups then FireMuscleEvent("rep") end
if State.AutoFarmPunch and not State.TargetAutoKill then
FireMuscleEvent("punch", "RightHand")
FireMuscleEvent("punch", "LeftHand")
end
end

    -- 2. Моментальное Авто-Перерождение
    if State.AutoRebirth then
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats then
            local currentStrength = leaderstats:FindFirstChild("Strength") and leaderstats.Strength.Value or 0
            local currentRebirths = leaderstats:FindFirstChild("Rebirths") and leaderstats.Rebirths.Value or 0
            local targetNeeded = State.SmartAutoRebirth and (10000 + (currentRebirths * 5000)) or State.RequiredStrength

            if currentStrength >= targetNeeded then
                local myChar = LocalPlayer.Character
                local rootPart = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local savedCFrame = rootPart and rootPart.CFrame or nil

                TryRebirth()

                if State.AntiTeleportIfRebirthed and savedCFrame then
                    task.spawn(function()
                        for _ = 1, 5 do
                            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                LocalPlayer.Character.HumanoidRootPart.CFrame = savedCFrame
                            end
                            task.wait()
                        end
                    end)
                end
            end
        end
    end

    -- 3. Скорость бега
    if State.EnableWalkSpeed then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = State.WalkSpeed
        end
    end
end)
end)

-- Экипировка инструментов (Медленный цикл, чтобы не ломать анимации)
task.spawn(function()
while true do
task.wait(0.5)
pcall(function()
local char = LocalPlayer.Character
if not char then return end
local function Equip(tName)
local tool = char:FindFirstChild(tName) or LocalPlayer.Backpack:FindFirstChild(tName)
if tool and tool.Parent ~= char then char.Humanoid:EquipTool(tool) end
end
if State.AutoFarmWeight then Equip("Weight") end
if State.AutoFarmPushups then Equip("Pushups") end
if State.AutoFarmSitups then Equip("Situps") end
if State.AutoFarmPunch and not State.TargetAutoKill then Equip("Punch") end
end)
end
end)

-- ЛОГИКА: ОХОТА И РАЗНОЕ

local function UpdateTargetHighlight()
pcall(function()
if TargetHighlightInstance then TargetHighlightInstance:Destroy(); TargetHighlightInstance = nil end
if State.HighlightTarget and State.SelectedPlayer ~= "" then
local targetObj = Players:FindFirstChild(State.SelectedPlayer)
if targetObj and targetObj.Character then
local highlight = Instance.new("Highlight")
highlight.Name = "aero_RedTargetOutline"
highlight.FillColor = Color3.fromRGB(220, 20, 60)
highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
highlight.FillTransparency = 0.5
highlight.Adornee = targetObj.Character
highlight.Parent = targetObj.Character
TargetHighlightInstance = highlight
end
end
end)
end

task.spawn(function()
while true do
task.wait(0.02)
pcall(function()
if State.TargetAutoKill and State.SelectedPlayer ~= "" then
local target = Players:FindFirstChild(State.SelectedPlayer)
if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health > 0 then
local myChar = LocalPlayer.Character
if myChar and myChar:FindFirstChild("HumanoidRootPart") and myChar:FindFirstChild("Humanoid") then
local punchTool = myChar:FindFirstChild("Punch") or LocalPlayer.Backpack:FindFirstChild("Punch")
if punchTool and punchTool.Parent ~= myChar then myChar.Humanoid:EquipTool(punchTool) end
myChar.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2.5)
FireMuscleEvent("punch", "RightHand")
FireMuscleEvent("punch", "LeftHand")
end
end
end
end)
end
end)

task.spawn(function()
while true do
task.wait(1)
if State.AutoJoinBrawl then FireRemote("joinBrawlRemote", "joinBrawl") end
if State.AutoClaimGift then
for i = 1, 10 do FireRemote("claimGiftRemote", i); FireRemote("freeGiftEvent", i) end
end
end
end)

UserInputService.JumpRequest:Connect(function()
pcall(function()
if State.InfiniteJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end
end)
end)

-- ====================================================================
-- PREMIUM UI: AERO RUBY THEME
-- ====================================================================
local guiParent = pcall(function() return gethui() end) and gethui() or pcall(function() return CoreGui end) and CoreGui or LocalPlayer:WaitForChild("PlayerGui")
for _, v in pairs(guiParent:GetChildren()) do if v.Name == "AeroPremiumUI" then v:Destroy() end end

local Screen = Instance.new("ScreenGui")
Screen.Name = "AeroPremiumUI"
Screen.ResetOnSpawn = false
Screen.Parent = guiParent

-- Главное окно
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 500, 0, 360)
Main.Position = UDim2.new(0.5, -250, 0.5, -180)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = Screen

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local Shadow = Instance.new("UIStroke")
Shadow.Color = Color3.fromRGB(220, 20, 60)
Shadow.Thickness = 1.5
Shadow.Transparency = 0.4
Shadow.Parent = Main

-- Левая панель (Сайдбар)
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 140, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 10)
SidebarCorner.Parent = Sidebar

-- Фикс скругления сайдбара (чтобы сливался с основным окном справа)
local SidebarBlock = Instance.new("Frame")
SidebarBlock.Size = UDim2.new(0, 10, 1, 0)
SidebarBlock.Position = UDim2.new(1, -10, 0, 0)
SidebarBlock.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
SidebarBlock.BorderSizePixel = 0
SidebarBlock.Parent = Sidebar

local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(1, 0, 0, 50)
Logo.BackgroundTransparency = 1
Logo.Text = "AERO RUBY"
Logo.TextColor3 = Color3.fromRGB(220, 20, 60)
Logo.Font = Enum.Font.GothamBlack
Logo.TextSize = 16
Logo.Parent = Sidebar

local LogoGlow = Instance.new("UIStroke")
LogoGlow.Color = Color3.fromRGB(220, 20, 60)
LogoGlow.Thickness = 0.5
LogoGlow.Transparency = 0.5
LogoGlow.Parent = Logo

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, 5)
SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarLayout.Parent = Sidebar

local LogoPadding = Instance.new("UIPadding")
LogoPadding.PaddingTop = UDim.new(0, 10)
LogoPadding.Parent = Sidebar

-- Контейнер контента
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -140, 1, 0)
ContentArea.Position = UDim2.new(0, 140, 0, 0)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = Main

local Tabs = {}

local function CreateTab(name, icon)
local TabBtn = Instance.new("TextButton")
TabBtn.Size = UDim2.new(0.85, 0, 0, 32)
TabBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 33)
TabBtn.Text = "  " .. icon .. " " .. name
TabBtn.TextColor3 = Color3.fromRGB(150, 150, 165)
TabBtn.Font = Enum.Font.GothamBold
TabBtn.TextSize = 12
TabBtn.TextXAlignment = Enum.TextXAlignment.Left
TabBtn.AutoButtonColor = false
TabBtn.Parent = Sidebar

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = TabBtn

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -20)
Scroll.Position = UDim2.new(0, 10, 0, 10)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 2
Scroll.ScrollBarImageColor3 = Color3.fromRGB(220, 20, 60)
Scroll.Visible = false
Scroll.Parent = ContentArea

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 8)
Layout.Parent = Scroll

Tabs[name] = {Btn = TabBtn, Content = Scroll}

TabBtn.MouseButton1Click:Connect(function()
    for tName, data in pairs(Tabs) do
        data.Content.Visible = false
        TweenService:Create(data.Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(25, 25, 33), TextColor3 = Color3.fromRGB(150, 150, 165)}):Play()
    end
    Scroll.Visible = true
    TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 20, 60), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
end)

return Scroll
end

-- Система красивых тумблеров (Toggles)
local function CreateToggle(parent, text, stateKey, callback)
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(1, -10, 0, 36)
Frame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
Frame.Parent = parent

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 6)
Corner.Parent = Frame

local Label = Instance.new("TextLabel")
Label.Size = UDim2.new(1, -60, 1, 0)
Label.Position = UDim2.new(0, 12, 0, 0)
Label.BackgroundTransparency = 1
Label.Text = text
Label.TextColor3 = Color3.fromRGB(220, 225, 230)
Label.Font = Enum.Font.GothamMedium
Label.TextSize = 13
Label.TextXAlignment = Enum.TextXAlignment.Left
Label.Parent = Frame

local SwitchBg = Instance.new("Frame")
SwitchBg.Size = UDim2.new(0, 36, 0, 20)
SwitchBg.Position = UDim2.new(1, -46, 0.5, -10)
SwitchBg.BackgroundColor3 = State[stateKey] and Color3.fromRGB(220, 20, 60) or Color3.fromRGB(40, 40, 50)
SwitchBg.Parent = Frame

local SwitchCorner = Instance.new("UICorner")
SwitchCorner.CornerRadius = UDim.new(1, 0)
SwitchCorner.Parent = SwitchBg

local Indicator = Instance.new("Frame")
Indicator.Size = UDim2.new(0, 14, 0, 14)
Indicator.Position = State[stateKey] and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Indicator.Parent = SwitchBg

local IndicatorCorner = Instance.new("UICorner")
IndicatorCorner.CornerRadius = UDim.new(1, 0)
IndicatorCorner.Parent = Indicator

local Btn = Instance.new("TextButton")
Btn.Size = UDim2.new(1, 0, 1, 0)
Btn.BackgroundTransparency = 1
Btn.Text = ""
Btn.Parent = Frame

Btn.MouseButton1Click:Connect(function()
    State[stateKey] = not State[stateKey]
    local isON = State[stateKey]
    
    TweenService:Create(SwitchBg, TweenInfo.new(0.25), {BackgroundColor3 = isON and Color3.fromRGB(220, 20, 60) or Color3.fromRGB(40, 40, 50)}):Play()
    TweenService:Create(Indicator, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Position = isON and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)}):Play()
    
    if callback then callback(isON) end
end)
end

-- Вкладки
local FarmTab = CreateTab("ПРОКАЧКА", "⚡")
local TargetTab = CreateTab("ОХОТА", "🎯")
local MiscTab = CreateTab("РАЗНОЕ", "🛠")

-- Инициализация первой вкладки
Tabs["ПРОКАЧКА"].Content.Visible = true
Tabs["ПРОКАЧКА"].Btn.BackgroundColor3 = Color3.fromRGB(220, 20, 60)
Tabs["ПРОКАЧКА"].Btn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Наполнение: ПРОКАЧКА
CreateToggle(FarmTab, "Фарм: Гантели", "AutoFarmWeight")
CreateToggle(FarmTab, "Фарм: Отжимания", "AutoFarmPushups")
CreateToggle(FarmTab, "Фарм: Пресс", "AutoFarmSitups")
CreateToggle(FarmTab, "Фарм: Удары", "AutoFarmPunch")
CreateToggle(FarmTab, "Турбо-Режим (x3 Скорость)", "FastMode")
CreateToggle(FarmTab, "Авто-Перерождение", "AutoRebirth")
CreateToggle(FarmTab, "Умный расчет стоимости", "SmartAutoRebirth")
CreateToggle(FarmTab, "Агрессивный Анти-Телепорт", "AntiTeleportIfRebirthed")

FarmTab.CanvasSize = UDim2.new(0, 0, 0, 370)

-- Наполнение: ОХОТА
local SelectedLabel = Instance.new("TextLabel")
SelectedLabel.Size = UDim2.new(1, -10, 0, 28)
SelectedLabel.BackgroundColor3 = Color3.fromRGB(30, 20, 25)
SelectedLabel.Text = " ЦЕЛЬ: НЕ ВЫБРАНА"
SelectedLabel.TextColor3 = Color3.fromRGB(220, 20, 60)
SelectedLabel.Font = Enum.Font.GothamBold
SelectedLabel.TextSize = 12
SelectedLabel.TextXAlignment = Enum.TextXAlignment.Center
SelectedLabel.Parent = TargetTab

local LabelCorner = Instance.new("UICorner")
LabelCorner.CornerRadius = UDim.new(0, 6)
LabelCorner.Parent = SelectedLabel

local PlayerList = Instance.new("ScrollingFrame")
PlayerList.Size = UDim2.new(1, -10, 0, 130)
PlayerList.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
PlayerList.BorderSizePixel = 0
PlayerList.ScrollBarThickness = 2
PlayerList.ScrollBarImageColor3 = Color3.fromRGB(220, 20, 60)
PlayerList.Parent = TargetTab

local ListCorner = Instance.new("UICorner")
ListCorner.CornerRadius = UDim.new(0, 6)
ListCorner.Parent = PlayerList

local PlayerLayout = Instance.new("UIListLayout")
PlayerLayout.Padding = UDim.new(0, 2)
PlayerLayout.Parent = PlayerList

local function RefreshPlayers()
for _, v in pairs(PlayerList:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
for _, p in pairs(Players:GetPlayers()) do
if p ~= LocalPlayer then
local PBtn = Instance.new("TextButton")
PBtn.Size = UDim2.new(1, -5, 0, 26)
PBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 33)
PBtn.Text = "  " .. p.Name
PBtn.TextColor3 = Color3.fromRGB(200, 200, 215)
PBtn.Font = Enum.Font.Gotham
PBtn.TextSize = 12
PBtn.TextXAlignment = Enum.TextXAlignment.Left
PBtn.AutoButtonColor = false
PBtn.Parent = PlayerList

        local PCorner = Instance.new("UICorner")
        PCorner.CornerRadius = UDim.new(0, 4)
        PCorner.Parent = PBtn

        PBtn.MouseButton1Click:Connect(function()
            State.SelectedPlayer = p.Name
            SelectedLabel.Text = " ЦЕЛЬ: " .. string.upper(p.Name)
            UpdateTargetHighlight()
        end)
    end
end
PlayerList.CanvasSize = UDim2.new(0, 0, 0, #Players:GetPlayers() * 28)
end

local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(1, -10, 0, 32)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(220, 20, 60)
RefreshBtn.Text = "ОБНОВИТЬ СПИСОК"
RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.TextSize = 12
RefreshBtn.Parent = TargetTab

local RefCorner = Instance.new("UICorner")
RefCorner.CornerRadius = UDim.new(0, 6)
RefCorner.Parent = RefreshBtn

RefreshBtn.MouseButton1Click:Connect(RefreshPlayers)
RefreshPlayers()

CreateToggle(TargetTab, "Рубиновый ESP (Подсветка)", "HighlightTarget", function() UpdateTargetHighlight() end)
CreateToggle(TargetTab, "АВТО-УБИЙСТВО (Телепорт)", "TargetAutoKill")
TargetTab.CanvasSize = UDim2.new(0, 0, 0, 330)

-- Наполнение: РАЗНОЕ
CreateToggle(MiscTab, "Скорость бега (50)", "EnableWalkSpeed")
CreateToggle(MiscTab, "Бесконечный прыжок", "InfiniteJump")
CreateToggle(MiscTab, "Авто-Участие в Brawl", "AutoJoinBrawl")
CreateToggle(MiscTab, "Авто-Сбор Подарков", "AutoClaimGift")
MiscTab.CanvasSize = UDim2.new(0, 0, 0, 200)

print("[AERO RUBY] Скрипт версии 4.0 успешно загружен!")
