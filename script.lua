-- ====================================================================
-- Project: aero_MuscleLegends_RussianRedesign.luau
-- Target: Muscle Legends (Roblox)
-- Description: Beautiful UI with UICorner, Russian UI & Auto-Rebirth
-- Version: 3.0 (RU Edition)
-- ====================================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")

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
    
    -- Перерождение
    AutoRebirth = false,
    SmartAutoRebirth = true,
    RequiredStrength = 10000,
    AntiTeleportIfRebirthed = true,
    
    AutoJoinBrawl = false,
    AutoClaimGift = false,
    
    -- Система цели
    SelectedPlayer = "",
    HighlightTarget = false,
    TargetAutoKill = false
}

local TargetHighlightInstance = nil

-- [Сетевой слой]
local function FireMuscleEvent(action, hand)
    pcall(function()
        local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
        local event = (LocalPlayer:FindFirstChild("muscleEvent") or (rEvents and rEvents:FindFirstChild("muscleEvent")))
        if event then
            if hand then
                event:FireServer(action, hand)
            else
                event:FireServer(action)
            end
        end
    end)
end

local function TryRebirth()
    pcall(function()
        local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
        if not rEvents then return end

        local targetRemotes = {"rebirthRemote", "rebirthEvent", "reberthRemote"}
        for _, rName in ipairs(targetRemotes) do
            local remote = rEvents:FindFirstChild(rName)
            if remote then
                if remote:IsA("RemoteEvent") then
                    remote:FireServer("rebirthRequest")
                elseif remote:IsA("RemoteFunction") then
                    remote:InvokeServer("rebirthRequest")
                end
            end
        end
    end)
end

local function FireRemote(remoteName, ...)
    local args = {...}
    pcall(function()
        local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
        if rEvents and rEvents:FindFirstChild(remoteName) then
            if rEvents[remoteName]:IsA("RemoteEvent") then
                rEvents[remoteName]:FireServer(unpack(args))
            elseif rEvents[remoteName]:IsA("RemoteFunction") then
                rEvents[remoteName]:InvokeServer(unpack(args))
            end
        end
    end)
end

------------------------------------------------------------------------
-- Логика Авто-Перерождения
------------------------------------------------------------------------
local previousCFrame = nil

task.spawn(function()
    while true do
        task.wait(0.2)
        pcall(function()
            if not State.AutoRebirth then return end

            local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
            local strengthObj = leaderstats and leaderstats:FindFirstChild("Strength")
            local rebirthsObj = leaderstats and leaderstats:FindFirstChild("Rebirths")

            local currentStrength = strengthObj and strengthObj.Value or 0
            local currentRebirths = rebirthsObj and rebirthsObj.Value or 0

            local targetNeeded = State.RequiredStrength
            if State.SmartAutoRebirth then
                targetNeeded = 10000 + (currentRebirths * 5000)
            end

            if currentStrength >= targetNeeded then
                if State.AntiTeleportIfRebirthed and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    previousCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                end

                TryRebirth()

                if State.AntiTeleportIfRebirthed and previousCFrame then
                    task.wait(0.2)
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = previousCFrame
                    end
                end
            end
        end)
    end
end)

------------------------------------------------------------------------
-- Подсветка и Авто-Убийство
------------------------------------------------------------------------
local function UpdateTargetHighlight()
    pcall(function()
        if TargetHighlightInstance then
            TargetHighlightInstance:Destroy()
            TargetHighlightInstance = nil
        end

        if State.HighlightTarget and State.SelectedPlayer ~= "" then
            local targetObj = Players:FindFirstChild(State.SelectedPlayer)
            if targetObj and targetObj.Character then
                local highlight = Instance.new("Highlight")
                highlight.Name = "aero_RedTargetOutline"
                highlight.FillColor = Color3.fromRGB(255, 35, 35)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.4
                highlight.OutlineTransparency = 0
                highlight.Adornee = targetObj.Character
                highlight.Parent = targetObj.Character
                TargetHighlightInstance = highlight
            end
        end
    end)
end

task.spawn(function()
    while true do
        task.wait(0.03)
        pcall(function()
            if State.TargetAutoKill and State.SelectedPlayer ~= "" then
                local target = Players:FindFirstChild(State.SelectedPlayer)
                if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and target.Character:FindFirstChild("Humanoid") then
                    if target.Character.Humanoid.Health > 0 then
                        local myChar = LocalPlayer.Character
                        if myChar and myChar:FindFirstChild("HumanoidRootPart") and myChar:FindFirstChild("Humanoid") then
                            local punchTool = myChar:FindFirstChild("Punch") or LocalPlayer.Backpack:FindFirstChild("Punch")
                            if punchTool and punchTool.Parent ~= myChar then
                                myChar.Humanoid:EquipTool(punchTool)
                            end

                            myChar.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2)
                            FireMuscleEvent("punch", "RightHand")
                            FireMuscleEvent("punch", "LeftHand")
                        end
                    end
                end
            end
        end)
    end
end)

------------------------------------------------------------------------
-- Основные циклы фарма
------------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(State.FastMode and 0.01 or 0.15)
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end

            local function Equip(toolName)
                local tool = char:FindFirstChild(toolName) or LocalPlayer.Backpack:FindFirstChild(toolName)
                if tool and tool.Parent ~= char then
                    char.Humanoid:EquipTool(tool)
                end
            end

            if State.AutoFarmWeight then Equip("Weight"); FireMuscleEvent("rep") end
            if State.AutoFarmPushups then Equip("Pushups"); FireMuscleEvent("rep") end
            if State.AutoFarmSitups then Equip("Situps"); FireMuscleEvent("rep") end
            if State.AutoFarmPunch and not State.TargetAutoKill then 
                Equip("Punch")
                FireMuscleEvent("punch", "RightHand")
                FireMuscleEvent("punch", "LeftHand")
            end
        end)
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if State.AutoJoinBrawl then FireRemote("joinBrawlRemote", "joinBrawl") end
        if State.AutoClaimGift then
            for i = 1, 10 do FireRemote("claimGiftRemote", i) end
            for i = 1, 10 do FireRemote("freeGiftEvent", i) end
        end
    end
end)

RunService.Stepped:Connect(function()
    pcall(function()
        if State.EnableWalkSpeed and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = State.WalkSpeed
        end
    end)
end)

game:GetService("UserInputService").JumpRequest:Connect(function()
    pcall(function()
        if State.InfiniteJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end)

-- ====================================================================
-- КРАСИВЫЙ ИНТЕРФЕЙС С СКРУГЛЕНИЯМИ (UICORNER)
-- ====================================================================
local guiParent = pcall(function() return gethui() end) and gethui() or pcall(function() return CoreGui end) and CoreGui or LocalPlayer:WaitForChild("PlayerGui")

for _, v in pairs(guiParent:GetChildren()) do
    if v.Name == "aero_RussianUI" then v:Destroy() end
end

local Screen = Instance.new("ScreenGui")
Screen.Name = "aero_RussianUI"
Screen.ResetOnSpawn = false
Screen.Parent = guiParent

-- Главное окно
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 390, 0, 400)
Main.Position = UDim2.new(0.05, 0, 0.2, 0)
Main.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = Screen

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0, 255, 150)
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.3
MainStroke.Parent = Main

-- Заголовок
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 35)
Title.Position = UDim2.new(0, 15, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "AERO SUITE // MUSCLE LEGENDS v3.0"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

-- Панель вкладок
local TabHeader = Instance.new("Frame")
TabHeader.Size = UDim2.new(1, -24, 0, 32)
TabHeader.Position = UDim2.new(0, 12, 0, 42)
TabHeader.BackgroundTransparency = 1
TabHeader.Parent = Main

local TabHeaderLayout = Instance.new("UIListLayout")
TabHeaderLayout.FillDirection = Enum.FillDirection.Horizontal
TabHeaderLayout.Padding = UDim.new(0, 6)
TabHeaderLayout.Parent = TabHeader

-- Контейнер для содержимого
local Containers = Instance.new("Frame")
Containers.Size = UDim2.new(1, -24, 1, -88)
Containers.Position = UDim2.new(0, 12, 0, 80)
Containers.BackgroundTransparency = 1
Containers.Parent = Main

local Tabs = {}

local function CreateTab(tabName)
    local TabButton = Instance.new("TextButton")
    TabButton.Size = UDim2.new(0.315, 0, 1, 0)
    TabButton.BackgroundColor3 = Color3.fromRGB(24, 27, 36)
    TabButton.Text = tabName
    TabButton.TextColor3 = Color3.fromRGB(160, 165, 180)
    TabButton.Font = Enum.Font.GothamMedium
    TabButton.TextSize = 12
    TabButton.BorderSizePixel = 0
    TabButton.Parent = TabHeader

    local TabBtnCorner = Instance.new("UICorner")
    TabBtnCorner.CornerRadius = UDim.new(0, 8)
    TabBtnCorner.Parent = TabButton

    local TabScroll = Instance.new("ScrollingFrame")
    TabScroll.Size = UDim2.new(1, 0, 1, 0)
    TabScroll.BackgroundTransparency = 1
    TabScroll.ScrollBarThickness = 3
    TabScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 150)
    TabScroll.Visible = false
    TabScroll.CanvasSize = UDim2.new(0, 0, 0, 340)
    TabScroll.Parent = Containers

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 6)
    Layout.Parent = TabScroll

    Tabs[tabName] = {Button = TabButton, Container = TabScroll}

    TabButton.MouseButton1Click:Connect(function()
        for name, data in pairs(Tabs) do
            data.Container.Visible = false
            data.Button.BackgroundColor3 = Color3.fromRGB(24, 27, 36)
            data.Button.TextColor3 = Color3.fromRGB(160, 165, 180)
        end
        TabScroll.Visible = true
        TabButton.BackgroundColor3 = Color3.fromRGB(35, 42, 58)
        TabButton.TextColor3 = Color3.fromRGB(0, 255, 150)
    end)

    return TabScroll
end

-- Создание вкладок на русском
local FarmTab = CreateTab("ФАРМ")
local TargetTab = CreateTab("ОХОТА")
local MiscTab = CreateTab("РАЗНОЕ")

-- Вкладка по умолчанию
Tabs["ФАРМ"].Container.Visible = true
Tabs["ФАРМ"].Button.BackgroundColor3 = Color3.fromRGB(35, 42, 58)
Tabs["ФАРМ"].Button.TextColor3 = Color3.fromRGB(0, 255, 150)

-- Вспомогательная функция переключателей
local function AddToggle(parentContainer, text, stateKey, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -6, 0, 32)
    Btn.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
    Btn.Text = "   " .. text .. ": " .. (State[stateKey] and "ВКЛ" or "ВЫКЛ")
    Btn.TextColor3 = State[stateKey] and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(240, 90, 90)
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 12
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.BorderSizePixel = 0
    Btn.Parent = parentContainer

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = Btn

    Btn.MouseButton1Click:Connect(function()
        State[stateKey] = not State[stateKey]
        Btn.Text = "   " .. text .. ": " .. (State[stateKey] and "ВКЛ" or "ВЫКЛ")
        Btn.TextColor3 = State[stateKey] and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(240, 90, 90)
        if callback then callback() end
    end)
end

------------------------------------------------------------------------
-- Заполнение вкладки ФАРМ
------------------------------------------------------------------------
AddToggle(FarmTab, "Авто-Фарм: Гантели", "AutoFarmWeight")
AddToggle(FarmTab, "Авто-Фарм: Отжимания", "AutoFarmPushups")
AddToggle(FarmTab, "Auto-Фарм: Пресс", "AutoFarmSitups")
AddToggle(FarmTab, "Авто-Фарм: Удары", "AutoFarmPunch")
AddToggle(FarmTab, "Быстрый режим фарма", "FastMode")
AddToggle(FarmTab, "АВТО-ПЕРЕРОЖДЕНИЕ (СИЛА)", "AutoRebirth")
AddToggle(FarmTab, "Умный расчет стоимости", "SmartAutoRebirth")
AddToggle(FarmTab, "Возврат на место фарма", "AntiTeleportIfRebirthed")

------------------------------------------------------------------------
-- Заполнение вкладки ОХОТА
------------------------------------------------------------------------
local SelectedLabel = Instance.new("TextLabel")
SelectedLabel.Size = UDim2.new(1, -6, 0, 28)
SelectedLabel.BackgroundColor3 = Color3.fromRGB(28, 32, 45)
SelectedLabel.Text = "  ЦЕЛЬ: НЕ ВЫБРАНА"
SelectedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SelectedLabel.Font = Enum.Font.GothamBold
SelectedLabel.TextSize = 11
SelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectedLabel.BorderSizePixel = 0
SelectedLabel.Parent = TargetTab

local LabelCorner = Instance.new("UICorner")
LabelCorner.CornerRadius = UDim.new(0, 8)
LabelCorner.Parent = SelectedLabel

local PlayerScrollFrame = Instance.new("ScrollingFrame")
PlayerScrollFrame.Size = UDim2.new(1, -6, 0, 110)
PlayerScrollFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
PlayerScrollFrame.BorderSizePixel = 0
PlayerScrollFrame.ScrollBarThickness = 3
PlayerScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 150)
PlayerScrollFrame.Parent = TargetTab

local ScrollCorner = Instance.new("UICorner")
ScrollCorner.CornerRadius = UDim.new(0, 8)
ScrollCorner.Parent = PlayerScrollFrame

local PlayerListLayout = Instance.new("UIListLayout")
PlayerListLayout.Padding = UDim.new(0, 3)
PlayerListLayout.Parent = PlayerScrollFrame

local function RefreshPlayerList()
    for _, v in pairs(PlayerScrollFrame:GetChildren()) do
        if v:IsA("TextButton") then v:Destroy() end
    end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local PBtn = Instance.new("TextButton")
            PBtn.Size = UDim2.new(1, -6, 0, 24)
            PBtn.BackgroundColor3 = Color3.fromRGB(28, 31, 42)
            PBtn.Text = "  " .. p.Name
            PBtn.TextColor3 = Color3.fromRGB(220, 225, 240)
            PBtn.Font = Enum.Font.Gotham
            PBtn.TextSize = 11
            PBtn.TextXAlignment = Enum.TextXAlignment.Left
            PBtn.BorderSizePixel = 0
            PBtn.Parent = PlayerScrollFrame

            local PBtnCorner = Instance.new("UICorner")
            PBtnCorner.CornerRadius = UDim.new(0, 6)
            PBtnCorner.Parent = PBtn

            PBtn.MouseButton1Click:Connect(function()
                State.SelectedPlayer = p.Name
                SelectedLabel.Text = "  ЦЕЛЬ: " .. p.Name
                SelectedLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
                UpdateTargetHighlight()
            end)
        end
    end
    PlayerScrollFrame.CanvasSize = UDim2.new(0, 0, 0, #Players:GetPlayers() * 27)
end

local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(1, -6, 0, 28)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(35, 42, 58)
RefreshBtn.Text = "ОБНОВИТЬ СПИСОК ИГРОКОВ"
RefreshBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.TextSize = 11
RefreshBtn.BorderSizePixel = 0
RefreshBtn.Parent = TargetTab

local RefreshCorner = Instance.new("UICorner")
RefreshCorner.CornerRadius = UDim.new(0, 8)
RefreshCorner.Parent = RefreshBtn

RefreshBtn.MouseButton1Click:Connect(RefreshPlayerList)
RefreshPlayerList()

AddToggle(TargetTab, "Красный ESP (Подсветка)", "HighlightTarget", function()
    UpdateTargetHighlight()
end)

AddToggle(TargetTab, "АВТО-УБИЙСТВО И ТЕЛЕПОРТ", "TargetAutoKill")

------------------------------------------------------------------------
-- Заполнение вкладки РАЗНОЕ
------------------------------------------------------------------------
AddToggle(MiscTab, "Скорость бега (50)", "EnableWalkSpeed")
AddToggle(MiscTab, "Бесконечный прыжок", "InfiniteJump")
AddToggle(MiscTab, "Авто-Вход в Битвы (Brawl)", "AutoJoinBrawl")
AddToggle(MiscTab, "Авто-Забор всех Подарков", "AutoClaimGift")

print("[aero] Обновленный русский интерфейс v3.0 успешно загружен.")
