-- ====================================================================
-- Project: aero_MuscleLegends_AutoRebirthUpdate.luau
-- Target: Muscle Legends (Roblox)
-- Description: Smart Strength-based Auto Rebirth Engine & Updated UI
-- ====================================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")

-- [Anti-AFK Protection]
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end)

-- [State Management]
local State = {
    WalkSpeed = 50, EnableWalkSpeed = false,
    InfiniteJump = false,
    AutoFarmWeight = false, AutoFarmPushups = false, AutoFarmSitups = false, AutoFarmPunch = false,
    FastMode = false,
    
    -- Rebirth Settings
    AutoRebirth = false,
    SmartAutoRebirth = true, -- Авто-расчет порога силы
    RequiredStrength = 10000, -- Ручной порог силы
    AntiTeleportIfRebirthed = true,
    
    AutoJoinBrawl = false,
    AutoClaimGift = false,
    
    -- Target System State
    SelectedPlayer = "",
    HighlightTarget = false,
    TargetAutoKill = false
}

local TargetHighlightInstance = nil

-- [Network Resolvers]
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
-- Smart Auto-Rebirth Core (Отслеживание силы)

local previousCFrame = nil

task.spawn(function()
while true do
task.wait(0.3)
pcall(function()
if not State.AutoRebirth then return end

        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if not leaderstats then return end

        local strengthObj = leaderstats:FindFirstChild("Strength")
        local rebirthsObj = leaderstats:FindFirstChild("Rebirths")

        if strengthObj then
            local currentStrength = strengthObj.Value
            local currentRebirths = rebirthsObj and rebirthsObj.Value or 0

            -- Расчет необходимой силы (стандартная формула игры или уставка)
            local targetNeeded = State.RequiredStrength
            if State.SmartAutoRebirth then
                targetNeeded = 10000 + (currentRebirths * 5000)
            end

            -- Если сила достигла нужного порога — делаем перерождение
            if currentStrength >= targetNeeded then
                if State.AntiTeleportIfRebirthed and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    previousCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                end

                FireRemote("rebirthEvent", "rebirthRequest")

                -- Возврат на место фарминга после реберса
                if State.AntiTeleportIfRebirthed and previousCFrame then
                    task.wait(0.25)
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = previousCFrame
                    end
                end
            end
        end
    end)
end
end)

-- Highlight & Target Auto-Kill Loops

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
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
            highlight.FillTransparency = 0.5
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

-- General Farming Loops

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
-- TABBED GUI GENERATOR (WITH REBIRTH CONTROL)
-- ====================================================================
local guiParent = pcall(function() return gethui() end) and gethui() or pcall(function() return CoreGui end) and CoreGui or LocalPlayer:WaitForChild("PlayerGui")

for _, v in pairs(guiParent:GetChildren()) do
if v.Name == "aero_TabbedUI" then v:Destroy() end
end

local Screen = Instance.new("ScreenGui")
Screen.Name = "aero_TabbedUI"
Screen.ResetOnSpawn = false
Screen.Parent = guiParent

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 380, 0, 380)
Main.Position = UDim2.new(0.05, 0, 0.25, 0)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
Main.BorderSizePixel = 1
Main.BorderColor3 = Color3.fromRGB(0, 255, 128)
Main.Active = true
Main.Draggable = true
Main.Parent = Screen

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 0, 30)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "AERO // MUSCLE SUITE v2.1"
Title.TextColor3 = Color3.fromRGB(0, 255, 128)
Title.Font = Enum.Font.Code
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

local TabHeader = Instance.new("Frame")
TabHeader.Size = UDim2.new(1, -20, 0, 30)
TabHeader.Position = UDim2.new(0, 10, 0, 35)
TabHeader.BackgroundTransparency = 1
TabHeader.Parent = Main

local TabHeaderLayout = Instance.new("UIListLayout")
TabHeaderLayout.FillDirection = Enum.FillDirection.Horizontal
TabHeaderLayout.Padding = UDim.new(0, 5)
TabHeaderLayout.Parent = TabHeader

local Containers = Instance.new("Frame")
Containers.Size = UDim2.new(1, -20, 1, -80)
Containers.Position = UDim2.new(0, 10, 0, 70)
Containers.BackgroundTransparency = 1
Containers.Parent = Main

local Tabs = {}

local function CreateTab(tabName)
local TabButton = Instance.new("TextButton")
TabButton.Size = UDim2.new(0.31, 0, 1, 0)
TabButton.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
TabButton.Text = tabName
TabButton.TextColor3 = Color3.fromRGB(180, 180, 180)
TabButton.Font = Enum.Font.Code
TabButton.TextSize = 12
TabButton.BorderSizePixel = 0
TabButton.Parent = TabHeader

local TabScroll = Instance.new("ScrollingFrame")
TabScroll.Size = UDim2.new(1, 0, 1, 0)
TabScroll.BackgroundTransparency = 1
TabScroll.ScrollBarThickness = 2
TabScroll.Visible = false
TabScroll.CanvasSize = UDim2.new(0, 0, 0, 320)
TabScroll.Parent = Containers

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 5)
Layout.Parent = TabScroll

Tabs[tabName] = {Button = TabButton, Container = TabScroll}

TabButton.MouseButton1Click:Connect(function()
    for name, data in pairs(Tabs) do
        data.Container.Visible = false
        data.Button.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        data.Button.TextColor3 = Color3.fromRGB(180, 180, 180)
    end
    TabScroll.Visible = true
    TabButton.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    TabButton.TextColor3 = Color3.fromRGB(0, 255, 128)
end)

return TabScroll
end

local FarmTab = CreateTab("FARM")
local TargetTab = CreateTab("TARGETING")
local MiscTab = CreateTab("MISC")

Tabs["FARM"].Container.Visible = true
Tabs["FARM"].Button.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Tabs["FARM"].Button.TextColor3 = Color3.fromRGB(0, 255, 128)

local function AddToggle(parentContainer, text, stateKey, callback)
local Btn = Instance.new("TextButton")
Btn.Size = UDim2.new(1, 0, 0, 28)
Btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Btn.Text = "  " .. text .. ": " .. (State[stateKey] and "[ON]" or "[OFF]")
Btn.TextColor3 = State[stateKey] and Color3.fromRGB(0, 255, 128) or Color3.fromRGB(200, 80, 80)
Btn.Font = Enum.Font.Code
Btn.TextSize = 13
Btn.TextXAlignment = Enum.TextXAlignment.Left
Btn.BorderSizePixel = 0
Btn.Parent = parentContainer

Btn.MouseButton1Click:Connect(function()
    State[stateKey] = not State[stateKey]
    Btn.Text = "  " .. text .. ": " .. (State[stateKey] and "[ON]" or "[OFF]")
    Btn.TextColor3 = State[stateKey] and Color3.fromRGB(0, 255, 128) or Color3.fromRGB(200, 80, 80)
    if callback then callback() end
end)
end

-- Populate Farm Tab
AddToggle(FarmTab, "Auto Farm Weight", "AutoFarmWeight")
AddToggle(FarmTab, "Auto Farm Pushups", "AutoFarmPushups")
AddToggle(FarmTab, "Auto Farm Situps", "AutoFarmSitups")
AddToggle(FarmTab, "Auto Farm Punch", "AutoFarmPunch")
AddToggle(FarmTab, "Fast Speed Mode", "FastMode")

-- Rebirth Section in FARM
AddToggle(FarmTab, "AUTO REBIRTH (BY STRENGTH)", "AutoRebirth")
AddToggle(FarmTab, "Smart Auto-Calculate Cost", "SmartAutoRebirth")
AddToggle(FarmTab, "Anti-Teleport Spawn On Rebirth", "AntiTeleportIfRebirthed")

-- Target Tab
local SelectedLabel = Instance.new("TextLabel")
SelectedLabel.Size = UDim2.new(1, 0, 0, 25)
SelectedLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
SelectedLabel.Text = " TARGET: NONE"
SelectedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SelectedLabel.Font = Enum.Font.Code
SelectedLabel.TextSize = 12
SelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectedLabel.BorderSizePixel = 0
SelectedLabel.Parent = TargetTab

local PlayerScrollFrame = Instance.new("ScrollingFrame")
PlayerScrollFrame.Size = UDim2.new(1, 0, 0, 100)
PlayerScrollFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
PlayerScrollFrame.BorderSizePixel = 0
PlayerScrollFrame.ScrollBarThickness = 2
PlayerScrollFrame.Parent = TargetTab

local PlayerListLayout = Instance.new("UIListLayout")
PlayerListLayout.Padding = UDim.new(0, 2)
PlayerListLayout.Parent = PlayerScrollFrame

local function RefreshPlayerList()
for _, v in pairs(PlayerScrollFrame:GetChildren()) do
if v:IsA("TextButton") then v:Destroy() end
end

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        local PBtn = Instance.new("TextButton")
        PBtn.Size = UDim2.new(1, -5, 0, 22)
        PBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
        PBtn.Text = " " .. p.Name
        PBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
        PBtn.Font = Enum.Font.Code
        PBtn.TextSize = 12
        PBtn.TextXAlignment = Enum.TextXAlignment.Left
        PBtn.BorderSizePixel = 0
        PBtn.Parent = PlayerScrollFrame

        PBtn.MouseButton1Click:Connect(function()
            State.SelectedPlayer = p.Name
            SelectedLabel.Text = " TARGET: " .. p.Name
            SelectedLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            UpdateTargetHighlight()
        end)
    end
end
PlayerScrollFrame.CanvasSize = UDim2.new(0, 0, 0, #Players:GetPlayers() * 24)
end

local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(1, 0, 0, 25)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
RefreshBtn.Text = "[ REFRESH PLAYER LIST ]"
RefreshBtn.TextColor3 = Color3.fromRGB(0, 255, 180)
RefreshBtn.Font = Enum.Font.Code
RefreshBtn.TextSize = 12
RefreshBtn.BorderSizePixel = 0
RefreshBtn.Parent = TargetTab
RefreshBtn.MouseButton1Click:Connect(RefreshPlayerList)

RefreshPlayerList()

AddToggle(TargetTab, "Red Target Highlight (ESP)", "HighlightTarget", function()
UpdateTargetHighlight()
end)

AddToggle(TargetTab, "AUTO KILL & TELEPORT TO TARGET", "TargetAutoKill")

-- Misc Tab
AddToggle(MiscTab, "Enable WalkSpeed (50)", "EnableWalkSpeed")
AddToggle(MiscTab, "Infinite Jump", "InfiniteJump")
AddToggle(MiscTab, "Auto Join Brawl", "AutoJoinBrawl")
AddToggle(MiscTab, "Auto Claim Gifts", "AutoClaimGift")

print("[aero] Updated Auto-Rebirth Module Loaded.")
