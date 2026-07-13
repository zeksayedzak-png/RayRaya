-- =====================================================
-- إضافة واجهة حماية البوتات (فوق السكريبت الأصلي)
-- =====================================================

-- إنشاء ScreenGui منفصل للبوتات
local botGui = Instance.new("ScreenGui")
botGui.Name = "BotProtectionUI"
botGui.Parent = LocalPlayer.PlayerGui
botGui.ResetOnSpawn = false

-- الإطار الرئيسي (مربع صغير)
local botFrame = Instance.new("Frame")
botFrame.Size = UDim2.new(0, 120, 0, 60)
botFrame.Position = UDim2.new(0.8, -140, 0.5, -30)
botFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
botFrame.BackgroundTransparency = 0.2
botFrame.BorderSizePixel = 0
botFrame.Parent = botGui
Instance.new("UICorner", botFrame).CornerRadius = UDim.new(0, 10)

-- زر الفريق الأحمر
local redTeamBtn = Instance.new("TextButton")
redTeamBtn.Size = UDim2.new(0, 45, 0, 25)
redTeamBtn.Position = UDim2.new(0.05, 0, 0.1, 0)
redTeamBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
redTeamBtn.Text = "🔴"
redTeamBtn.TextColor3 = Color3.new(1, 1, 1)
redTeamBtn.Font = Enum.Font.GothamBold
redTeamBtn.TextSize = 14
redTeamBtn.Parent = botFrame
Instance.new("UICorner", redTeamBtn).CornerRadius = UDim.new(0, 6)

-- زر الفريق الأزرق
local blueTeamBtn = Instance.new("TextButton")
blueTeamBtn.Size = UDim2.new(0, 45, 0, 25)
blueTeamBtn.Position = UDim2.new(0.55, 0, 0.1, 0)
blueTeamBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 150)
blueTeamBtn.Text = "🔵"
blueTeamBtn.TextColor3 = Color3.new(1, 1, 1)
blueTeamBtn.Font = Enum.Font.GothamBold
blueTeamBtn.TextSize = 14
blueTeamBtn.Parent = botFrame
Instance.new("UICorner", blueTeamBtn).CornerRadius = UDim.new(0, 6)

-- ==================== منطق الحماية ====================
local botProtectionMode = "None" -- "Red", "Blue", "None"

-- التعرف على البوتات
local function getBots()
    local bots = {}
    for _, obj in pairs(workspace.ActiveBots:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            table.insert(bots, obj)
        end
    end
    return bots
end

-- معرفة لون البوت (من SpawnProtectionActive)
local function getBotColor(bot)
    if workspace.SpawnProtectionActive:FindFirstChild("Red") and bot:IsDescendantOf(workspace.SpawnProtectionActive.Red) then
        return "Red"
    elseif workspace.SpawnProtectionActive:FindFirstChild("Blue") and bot:IsDescendantOf(workspace.SpawnProtectionActive.Blue) then
        return "Blue"
    end
    return "Unknown"
end

-- X-Ray للبوتات
local function applyBotXray(bot)
    if not bot then return end
    local highlight = bot:FindFirstChild("BotXray")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "BotXray"
        highlight.Parent = bot
    end
    highlight.FillColor = Color3.fromRGB(255, 200, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

-- تفعيل X-Ray للبوتات
local function initBotXray()
    for _, bot in pairs(getBots()) do
        applyBotXray(bot)
    end
end

-- مراقبة البوتات الجديدة
workspace.ActiveBots.DescendantAdded:Connect(function(obj)
    if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
        applyBotXray(obj)
    end
end)

-- تشغيل X-Ray عند بدء السكريبت
task.spawn(function()
    wait(1)
    initBotXray()
end)

-- وظائف الأزرار
redTeamBtn.MouseButton1Click:Connect(function()
    if botProtectionMode == "Red" then
        botProtectionMode = "None"
        redTeamBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        botProtectionMode = "Red"
        redTeamBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        blueTeamBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 150)
    end
end)

blueTeamBtn.MouseButton1Click:Connect(function()
    if botProtectionMode == "Blue" then
        botProtectionMode = "None"
        blueTeamBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 150)
    else
        botProtectionMode = "Blue"
        blueTeamBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        redTeamBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    end
end)

-- ==================== تعديل دالة البحث عن الهدف في Aimbot ====================
-- (نضيف استثناء البوتات المحمية في findClosestTarget و findVisibleTarget)
local oldFindClosest = findClosestTarget
local oldFindVisible = findVisibleTarget

findClosestTarget = function()
    local bestTarget = oldFindClosest()
    -- إذا كان الهدف بوت محمي، نتجاهله
    if bestTarget and bestTarget.Parent and bestTarget.Parent:IsA("Model") then
        local bot = bestTarget.Parent
        local botColor = getBotColor(bot)
        if (botProtectionMode == "Red" and botColor == "Red") or (botProtectionMode == "Blue" and botColor == "Blue") then
            return nil
        end
    end
    return bestTarget
end

findVisibleTarget = function()
    local bestTarget = oldFindVisible()
    if bestTarget and bestTarget.Parent and bestTarget.Parent:IsA("Model") then
        local bot = bestTarget.Parent
        local botColor = getBotColor(bot)
        if (botProtectionMode == "Red" and botColor == "Red") or (botProtectionMode == "Blue" and botColor == "Blue") then
            return nil
        end
    end
    return bestTarget
end

-- ==================== جعل الواجهة قابلة للسحب ====================
local function makeDraggable(frame)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

makeDraggable(botFrame)
