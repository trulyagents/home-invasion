-- keypad for the safe that holds the car keys. The server picks the code and checks guesses
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("HomeInvasionTasks"):WaitForChild("Interaction")

local gui = Instance.new("ScreenGui")
gui.Name = "SafeKeypad"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local font = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(260, 330)
panel.BackgroundColor3 = Color3.fromRGB(28, 30, 28)
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", panel)
stroke.Color = Color3.fromRGB(90, 110, 90)
stroke.Thickness = 2

local function text(name, y, height, size, value)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Position = UDim2.fromOffset(10, y)
    label.Size = UDim2.new(1, -20, 0, height)
    label.BackgroundTransparency = 1
    label.FontFace = font
    label.TextSize = size
    label.TextColor3 = Color3.fromRGB(225, 225, 210)
    label.Text = value
    label.Parent = panel
    return label
end

text("Title", 8, 26, 22, "SAFE")
local clueLabel = text("Clues", 34, 20, 15, "")
local display = text("Display", 58, 44, 36, "_ _ _")
display.BackgroundTransparency = 0
display.BackgroundColor3 = Color3.fromRGB(15, 25, 15)
display.TextColor3 = Color3.fromRGB(120, 230, 130)
Instance.new("UICorner", display).CornerRadius = UDim.new(0, 6)

local entered = ""

local function redraw()
    local shown = {}
    for index = 1, 3 do
        shown[index] = entered:sub(index, index) ~= "" and entered:sub(index, index) or "_"
    end
    display.Text = table.concat(shown, " ")
end

local function close()
    gui.Enabled = false
    entered = ""
end

local function press(key)
    if key == "C" then
        entered = ""
    elseif key == "OK" then
        if #entered == 3 then
            remote:FireServer("SafeGuess", entered)
        end
    elseif #entered < 3 then
        entered ..= key
    end
    redraw()
end

local keys = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "OK" }
for index, key in keys do
    local column = (index - 1) % 3
    local row = (index - 1) // 3
    local button = Instance.new("TextButton")
    button.Position = UDim2.fromOffset(20 + column * 76, 112 + row * 46)
    button.Size = UDim2.fromOffset(68, 40)
    button.BackgroundColor3 = key == "OK" and Color3.fromRGB(50, 110, 60) or Color3.fromRGB(55, 58, 55)
    button.FontFace = font
    button.TextSize = 22
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = key
    button.AutoButtonColor = true
    button.Parent = panel
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
    button.Activated:Connect(function()
        press(key)
    end)
end

local closeButton = Instance.new("TextButton")
closeButton.Position = UDim2.fromOffset(20, 298)
closeButton.Size = UDim2.new(1, -40, 0, 24)
closeButton.BackgroundTransparency = 1
closeButton.FontFace = font
closeButton.TextSize = 16
closeButton.TextColor3 = Color3.fromRGB(180, 170, 160)
closeButton.Text = "Close (Esc / X)"
closeButton.Parent = panel
closeButton.Activated:Connect(close)

UserInputService.InputBegan:Connect(function(input)
    if not gui.Enabled then
        return
    end
    if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.X then
        close()
    elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
        press("OK")
    elseif input.KeyCode == Enum.KeyCode.Backspace then
        entered = entered:sub(1, -2)
        redraw()
    else
        local digit = input.KeyCode.Value - Enum.KeyCode.Zero.Value
        local pad = input.KeyCode.Value - Enum.KeyCode.KeypadZero.Value
        if digit >= 0 and digit <= 9 then
            press(tostring(digit))
        elseif pad >= 0 and pad <= 9 then
            press(tostring(pad))
        end
    end
end)

remote.OnClientEvent:Connect(function(action, value)
    if action == "SafeOpen" then
        entered = ""
        clueLabel.Text = typeof(value) == "string" and ("Notes say: " .. value) or ""
        redraw()
        gui.Enabled = true
    elseif action == "SafeWrong" then
        entered = ""
        display.Text = "WRONG"
        display.TextColor3 = Color3.fromRGB(230, 80, 70)
        task.delay(0.8, function()
            display.TextColor3 = Color3.fromRGB(120, 230, 130)
            redraw()
        end)
    elseif action == "SafeClose" then
        close()
    end
end)

-- walking off or dying closes it
player.CharacterAdded:Connect(close)
