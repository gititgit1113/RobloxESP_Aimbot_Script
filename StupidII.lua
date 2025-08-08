local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local CoreGui = (gethui and gethui()) or (get_hidden_gui and get_hidden_gui()) or game:GetService("CoreGui")
getgenv().espEnabled = true
getgenv().aimbotEnabled = true
local HighlightTable = {}
local function addHighlight(character)
    if not character then return end
    if HighlightTable[character] then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ExecutorHighlight"
    highlight.Adornee = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = Color3.new(1, 0, 0)
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.Parent = CoreGui
    HighlightTable[character] = highlight
end
local function removeHighlight(character)
    if HighlightTable[character] then
        HighlightTable[character]:Destroy()
        HighlightTable[character] = nil
    end
end
local function updateHighlights()
    for _, player in pairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            if getgenv().espEnabled then
                addHighlight(char)
            else
                removeHighlight(char)
            end
        end
    end
end
local function onCharacterAdded(character)
    if getgenv().espEnabled then
        addHighlight(character)
    end
    character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            removeHighlight(character)
        end
    end)
end
local function onPlayerAdded(player)
    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
end
for _, player in pairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
    removeHighlight(player.Character)
end)
local function getNearestTarget()
    local nearestDistance = math.huge
    local nearestHead = nil
    local camera = workspace.CurrentCamera
    local camPos = camera.CFrame.Position
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            if head and head.Parent then
                local distance = (head.Position - camPos).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestHead = head
                end
            end
        end
    end
    return nearestHead
end
local aimSpeed = 0.2
RunService.RenderStepped:Connect(function()
    local camera = workspace.CurrentCamera
    if getgenv().aimbotEnabled then
        local targetHead = getNearestTarget()
        if targetHead then
            local camPos = camera.CFrame.Position
            local desiredCFrame = CFrame.new(camPos, targetHead.Position)
            camera.CFrame = camera.CFrame:Lerp(desiredCFrame, aimSpeed)
        end
    end
    updateHighlights()
end)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "ESP_Aimbot_Menu"
mainFrame.Size = UDim2.new(0, 220, 0, 120)
mainFrame.Position = UDim2.new(0, 100, 0, 100)
mainFrame.BackgroundColor3 = Color3.new(0,0,0)
mainFrame.BackgroundTransparency = 0.3
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = false
mainFrame.Parent = CoreGui
mainFrame.ZIndex = 9999
local corner = Instance.new("UICorner", mainFrame)
corner.CornerRadius = UDim.new(0, 10)
local title = Instance.new("TextLabel")
title.Text = "StupidII's Menu"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, 0, 0, 30)
title.Parent = mainFrame
title.ZIndex = 9999
local function createToggle(text, initial, callback)
    local button = Instance.new("TextButton")
    button.Text = text .. ": " .. (initial and "ON" or "OFF")
    button.Font = Enum.Font.Gotham
    button.TextSize = 16
    button.TextColor3 = Color3.new(1,1,1)
    button.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    button.Size = UDim2.new(1, -20, 0, 30)
    button.Position = UDim2.new(0, 10, 0, 40 + (#mainFrame:GetChildren() - 3)*35)
    button.AutoButtonColor = true
    button.Parent = mainFrame
    button.ZIndex = 9999
    button.BorderSizePixel = 0
    local corner = Instance.new("UICorner", button)
    corner.CornerRadius = UDim.new(0, 6)
    button.MouseButton1Click:Connect(function()
        initial = not initial
        button.Text = text .. ": " .. (initial and "ON" or "OFF")
        callback(initial)
    end)
end
createToggle("ESP", getgenv().espEnabled, function(state)
    getgenv().espEnabled = state
    updateHighlights()
end)
createToggle("Aimbot", getgenv().aimbotEnabled, function(state)
    getgenv().aimbotEnabled = state
end)
local hsv = 0
local rgbMode = true
coroutine.wrap(function()
    while true do
        if rgbMode then
            hsv = (hsv + 1) % 360
            local color = Color3.fromHSV(hsv/360, 0.8, 0.9)
            mainFrame.BackgroundColor3 = color
            mainFrame.BackgroundTransparency = 0.25
        else
            mainFrame.BackgroundColor3 = Color3.new(0,0,0)
            mainFrame.BackgroundTransparency = 0.7
        end
        wait(0.03)
    end
end)()
local dragging
local dragInput
local dragStart
local startPos
local hidden = false
local circle = Instance.new("Frame")
circle.Size = UDim2.new(0, 30, 0, 30)
circle.Position = mainFrame.Position
circle.BackgroundColor3 = Color3.new(0,0,0)
circle.BackgroundTransparency = 0.3
circle.BorderSizePixel = 0
circle.Visible = false
circle.ZIndex = 9999
circle.Parent = CoreGui
local circleCorner = Instance.new("UICorner", circle)
circleCorner.CornerRadius = UDim.new(1,0)
local function updatePosition(guiObject, pos)
    local screenSize = workspace.CurrentCamera.ViewportSize
    local newX = math.clamp(pos.X, 0, screenSize.X - guiObject.AbsoluteSize.X)
    local newY = math.clamp(pos.Y, 0, screenSize.Y - guiObject.AbsoluteSize.Y)
    guiObject.Position = UDim2.new(0, newX, 0, newY)
end
local function startDrag(input)
    dragging = true
    dragStart = input.Position
    if hidden then
        circle.Position = mainFrame.Position
    end
    startPos = mainFrame.Position
    input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then
            dragging = false
            if hidden then
                return
            end
        end
    end)
end
local function drag(input)
    if dragging then
        local delta = input.Position - dragStart
        local newPos = UDim2.new(
            0,
            startPos.X.Offset + delta.X,
            0,
            startPos.Y.Offset + delta.Y
        )
        updatePosition(mainFrame, Vector2.new(newPos.X.Offset, newPos.Y.Offset))
        if hidden then
            updatePosition(circle, Vector2.new(newPos.X.Offset, newPos.Y.Offset))
        end
    end
end
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        startDrag(input)
    end
end)
mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        drag(input)
    end
end)
circle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        startDrag(input)
    end
end)
circle.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        drag(input)
    end
end)
local clickThreshold = 5
local clickStartPos
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        clickStartPos = input.Position
    end
end)
mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local delta = (input.Position - clickStartPos).Magnitude
        if delta <= clickThreshold then
            if hidden then
                hidden = false
                mainFrame.Visible = true
                circle.Visible = false
            else
                hidden = true
                mainFrame.Visible = false
                circle.Position = mainFrame.Position
                circle.Visible = true
            end
        end
    end
end)
circle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        clickStartPos = input.Position
    end
end)
circle.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local delta = (input.Position - clickStartPos).Magnitude
        if delta <= clickThreshold then
            if hidden then
                hidden = false
                mainFrame.Visible = true
                circle.Visible = false
            else
                hidden = true
                mainFrame.Visible = false
                circle.Position = mainFrame.Position
                circle.Visible = true
            end
        end
    end
end)
