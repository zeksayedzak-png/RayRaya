-- =====================================================
-- إضافة أزرار حماية البوتات (أحمر / أزرق)
-- =====================================================

-- إضافة Frame للأزرار جنب قائمة اللاعبين (مش فوقها)
local botProtectionFrame = Instance.new("Frame")
botProtectionFrame.Size = UDim2.new(0.9, 0, 0, 30)
botProtectionFrame.Position = UDim2.new(0.05, 0, 1, -40) -- تحت القائمة مباشرة
botProtectionFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
botProtectionFrame.Parent = playerFrame
Instance.new("UICorner", botProtectionFrame).CornerRadius = UDim.new(0, 6)

-- زر أحمر
local redBtn = Instance.new("TextButton")
redBtn.Size = UDim2.new(0.4, 0, 0, 22)
redBtn.Position = UDim2.new(0.05, 0, 0.1, 0)
redBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
redBtn.Text = "🔴 Red"
redBtn.TextColor3 = Color3.new(1, 1, 1)
redBtn.Font = Enum.Font.GothamBold
redBtn.TextSize = 11
redBtn.Parent = botProtectionFrame
Instance.new("UICorner", redBtn).CornerRadius = UDim.new(0, 6)

-- زر أزرق
local blueBtn = Instance.new("TextButton")
blueBtn.Size = UDim2.new(0.4, 0, 0, 22)
blueBtn.Position = UDim2.new(0.55, 0, 0.1, 0)
blueBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 150)
blueBtn.Text = "🔵 Blue"
blueBtn.TextColor3 = Color3.new(1, 1, 1)
blueBtn.Font = Enum.Font.GothamBold
blueBtn.TextSize = 11
blueBtn.Parent = botProtectionFrame
Instance.new("UICorner", blueBtn).CornerRadius = UDim.new(0, 6)

-- ==================== متغيرات الحماية ====================
local botProtectionMode = "None" -- "Red", "Blue", "None"

-- ==================== وظيفة الأزرار ====================
redBtn.MouseButton1Click:Connect(function()
    if botProtectionMode == "Red" then
        botProtectionMode = "None"
        redBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        botProtectionMode = "Red"
        redBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        blueBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 150)
        print("🛡 Protecting Red bots")
    end
end)

blueBtn.MouseButton1Click:Connect(function()
    if botProtectionMode == "Blue" then
        botProtectionMode = "None"
        blueBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 150)
    else
        botProtectionMode = "Blue"
        blueBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        redBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        print("🛡 Protecting Blue bots")
    end
end)

-- ==================== التعرف على البوتات ====================
local function getBots()
    local bots = {}
    for _, obj in pairs(workspace.ActiveBots:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            table.insert(bots, obj)
        end
    end
    return bots
end

-- ==================== معرفة لون البوت ====================
local function getBotColor(bot)
    local rootPart = bot:FindFirstChild("HumanoidRootPart")
    if rootPart then
        if rootPart.BrickColor == BrickColor.new("Bright red") or rootPart.BrickColor == BrickColor.new("Really red") then
            return "Red"
        elseif rootPart.BrickColor == BrickColor.new("Bright blue") or rootPart.BrickColor == BrickColor.new("Navy blue") then
            return "Blue"
        end
    end
    return "Unknown"
end

-- ==================== X-RAY للبوتات ====================
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

-- ==================== تفعيل X-RAY ====================
local function initBotXray()
    for _, bot in pairs(getBots()) do
        applyBotXray(bot)
    end
end

-- ==================== مراقبة البوتات الجديدة ====================
workspace.ActiveBots.DescendantAdded:Connect(function(obj)
    if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
        applyBotXray(obj)
    end
end)

task.spawn(function()
    wait(1)
    initBotXray()
end)

-- ==================== تعديل Aimbot ====================
local function findClosestTargetWithProtection()
    local bestTarget = nil
    local bestDistance = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    -- اللاعبين العاديين
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not protectedPlayers[player] then
            local character = player.Character
            if character then
                local targetPart = getTargetPart(character)
                if targetPart then
                    local hum = character:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        local onScreen, screenPos = isOnScreen(targetPart.Position)
                        if onScreen then
                            local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                            if distance < bestDistance then
                                bestDistance = distance
                                bestTarget = targetPart
                            end
                        end
                    end
                end
            end
        end
    end

    -- البوتات
    for _, bot in pairs(getBots()) do
        local botColor = getBotColor(bot)
        local isProtected = false
        
        if botProtectionMode == "Red" and botColor == "Red" then
            isProtected = true
        elseif botProtectionMode == "Blue" and botColor == "Blue" then
            isProtected = true
        end
        
        if not isProtected then
            local targetPart = bot:FindFirstChild("HumanoidRootPart")
            if targetPart then
                local onScreen, screenPos = isOnScreen(targetPart.Position)
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if distance < bestDistance then
                        bestDistance = distance
                        bestTarget = targetPart
                    end
                end
            end
        end
    end
    
    return bestTarget
end
