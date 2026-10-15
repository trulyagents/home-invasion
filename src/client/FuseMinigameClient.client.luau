--!strict
-- The fuse box repair: unscrew the four panel screws, then drag each wire to the terminal
-- of the same colour. The server decides whether the power actually comes back on.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("HomeInvasionObjectives"):WaitForChild("Interaction") :: RemoteEvent

local SCREW_HOLD_SECONDS = 0.35
local MOUSE_BINDING = "FuseMinigameMouse"
local CANCEL_DISTANCE = 10
local PANEL = Color3.fromRGB(12, 11, 12)
local METAL = Color3.fromRGB(58, 60, 66)
local TEXT = Color3.fromRGB(232, 225, 214)
local ACCENT = Color3.fromRGB(196, 38, 30)
local BORDER = Color3.fromRGB(90, 20, 18)
local HEAD = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold)
local BODY = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local WIRES = {
    { name = "Red", color = Color3.fromRGB(200, 45, 40) },
    { name = "Yellow", color = Color3.fromRGB(225, 190, 50) },
    { name = "Blue", color = Color3.fromRGB(55, 110, 210) },
}

local gui = Instance.new("ScreenGui")
gui.Name = "FuseMinigame"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20 -- above the door and furniture hints
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local noticeGui = Instance.new("ScreenGui")
noticeGui.Name = "FuseNotice"
noticeGui.ResetOnSpawn = false
noticeGui.Parent = player.PlayerGui

local notice = Instance.new("TextLabel")
notice.Name = "Notice"
notice.AnchorPoint = Vector2.new(0.5, 1)
notice.Position = UDim2.new(0.5, 0, 1, -250)
notice.Size = UDim2.fromOffset(520, 30)
notice.BackgroundTransparency = 1
notice.FontFace = HEAD
notice.TextSize = 20
notice.TextColor3 = TEXT
notice.TextStrokeTransparency = 0.4
notice.Visible = false
notice.Parent = noticeGui

local function corner(parent: Instance, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
end

local function label(parent: Instance, text: string, font: Font, size: number, color: Color3): TextLabel
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.FontFace = font
    l.TextSize = size
    l.TextColor3 = color
    l.Text = text
    l.Parent = parent
    return l
end

-- Window -------------------------------------------------------------------------

local window = Instance.new("Frame")
window.Name = "Window"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.fromScale(0.5, 0.5)
window.Size = UDim2.fromOffset(440, 330)
window.BackgroundColor3 = PANEL
window.BackgroundTransparency = 0.08
window.Parent = gui
corner(window, 6)
local stroke = Instance.new("UIStroke")
stroke.Color = BORDER
stroke.Thickness = 1
stroke.Parent = window

local title = label(window, "FUSE BOX", HEAD, 24, ACCENT)
title.Position = UDim2.fromOffset(18, 10)
title.Size = UDim2.new(1, -60, 0, 30)
title.TextXAlignment = Enum.TextXAlignment.Left

local step = label(window, "", BODY, 14, TEXT)
step.Position = UDim2.fromOffset(18, 40)
step.Size = UDim2.new(1, -36, 0, 20)
step.TextXAlignment = Enum.TextXAlignment.Left

local close = Instance.new("TextButton")
close.Name = "Close"
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -10, 0, 10)
close.Size = UDim2.fromOffset(28, 28)
close.BackgroundColor3 = Color3.fromRGB(28, 24, 24)
close.FontFace = HEAD
close.TextSize = 18
close.TextColor3 = TEXT
close.Text = "X"
close.Parent = window
corner(close, 3)

local board = Instance.new("Frame")
board.Name = "Board"
board.Position = UDim2.fromOffset(18, 70)
board.Size = UDim2.new(1, -36, 1, -88)
board.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
board.Parent = window
corner(board, 4)

-- Stage 2 lives underneath the cover plate.
local wireLayer = Instance.new("Frame")
wireLayer.Name = "Wires"
wireLayer.Size = UDim2.fromScale(1, 1)
wireLayer.BackgroundTransparency = 1
wireLayer.Parent = board

local cover = Instance.new("Frame")
cover.Name = "Cover"
cover.Size = UDim2.fromScale(1, 1)
cover.BackgroundColor3 = METAL
cover.ZIndex = 5
cover.Active = true -- stops clicks reaching the wires underneath
cover.Parent = board
corner(cover, 4)
local warning = label(cover, "DANGER\nHIGH VOLTAGE", HEAD, 22, Color3.fromRGB(225, 190, 50))
warning.Size = UDim2.fromScale(1, 1)
warning.ZIndex = 6

-- State ----------------------------------------------------------------------------

local active = false
local fuseBox: BasePart? = nil
local connections: { RBXScriptConnection } = {}
local screwsLeft = 0
local heldScrew: GuiButton? = nil
local heldSince = 0
local dragging: { name: string, color: Color3, start: GuiObject, line: Frame }? = nil
local connected = 0
local noticeToken = 0

local function showNotice(text: string?)
    noticeToken += 1
    local token = noticeToken
    if not text then
        notice.Visible = false
        return
    end
    notice.Text = text
    notice.Visible = true
    task.delay(2.5, function()
        if noticeToken == token then
            notice.Visible = false
        end
    end)
end

local function clearChildren(parent: Instance)
    for _, child in parent:GetChildren() do
        child:Destroy()
    end
end

local function closeMinigame(sendCancel: boolean)
    if not active then
        return
    end
    active = false
    gui.Enabled = false
    RunService:UnbindFromRenderStep(MOUSE_BINDING)
    for _, connection in connections do
        connection:Disconnect()
    end
    table.clear(connections)
    heldScrew = nil
    if dragging then
        dragging.line:Destroy()
        dragging = nil
    end
    if sendCancel then
        remote:FireServer("FuseCancel")
    end
end

-- Draws a straight bar between two points given in the board's own pixel space.
local function placeLine(line: Frame, from: Vector2, to: Vector2)
    local delta = to - from
    line.Size = UDim2.fromOffset(delta.Magnitude, 6)
    line.Position = UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2)
    line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
end

local function centreOf(gui_: GuiObject): Vector2
    return gui_.AbsolutePosition + gui_.AbsoluteSize / 2 - board.AbsolutePosition
end

local function pointer(): Vector2
    local mouse = UserInputService:GetMouseLocation()
    -- GetMouseLocation includes the top bar inset; AbsolutePosition does not.
    local inset = game:GetService("GuiService"):GetGuiInset()
    return mouse - inset - board.AbsolutePosition
end

-- Stage 2: wires ------------------------------------------------------------------

local function buildWires()
    clearChildren(wireLayer)
    connected = 0
    step.Text = "Drag each wire to the terminal of the same colour"
    local order = { 1, 2, 3 }
    for i = #order, 2, -1 do
        local j = math.random(1, i)
        order[i], order[j] = order[j], order[i]
    end
    local terminals: { [string]: GuiObject } = {}
    for index, wire in WIRES do
        local y = UDim2.new(0, 0, (index - 0.5) / #WIRES, 0)
        local start = Instance.new("TextButton")
        start.Name = "Start" .. wire.name
        start.Text = ""
        start.AutoButtonColor = false
        start.AnchorPoint = Vector2.new(0, 0.5)
        start.Position = UDim2.new(0, 14, y.Y.Scale, 0)
        start.Size = UDim2.fromOffset(46, 22)
        start.BackgroundColor3 = wire.color
        start.ZIndex = 3
        start.Parent = wireLayer
        corner(start, 3)

        local target = wire
        local endWire = WIRES[order[index]]
        local terminal = Instance.new("Frame")
        terminal.Name = "End" .. endWire.name
        terminal.AnchorPoint = Vector2.new(1, 0.5)
        terminal.Position = UDim2.new(1, -14, y.Y.Scale, 0)
        terminal.Size = UDim2.fromOffset(46, 22)
        terminal.BackgroundColor3 = endWire.color
        terminal.ZIndex = 3
        terminal.Parent = wireLayer
        corner(terminal, 3)
        terminals[endWire.name] = terminal

        table.insert(connections, start.InputBegan:Connect(function(input)
            if dragging or start:GetAttribute("Done") then
                return
            end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            local line = Instance.new("Frame")
            line.AnchorPoint = Vector2.new(0.5, 0.5)
            line.BackgroundColor3 = target.color
            line.BorderSizePixel = 0
            line.ZIndex = 2
            line.Parent = wireLayer
            dragging = { name = target.name, color = target.color, start = start, line = line }
            placeLine(line, centreOf(start), centreOf(start))
        end))
    end

    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            placeLine(dragging.line, centreOf(dragging.start), pointer())
        end
    end))
    table.insert(connections, UserInputService.InputEnded:Connect(function(input)
        if not dragging then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local current = dragging
        dragging = nil
        local terminal = terminals[current.name]
        local hit = (pointer() - centreOf(terminal)).Magnitude < 34
        if not hit then
            current.line:Destroy()
            return
        end
        placeLine(current.line, centreOf(current.start), centreOf(terminal))
        current.start:SetAttribute("Done", true)
        connected += 1
        if connected == #WIRES then
            step.Text = "Restoring power..."
            remote:FireServer("FuseDone")
        end
    end))
end

-- Stage 1: screws -----------------------------------------------------------------

local function buildScrews()
    cover.Visible = true
    for _, child in cover:GetChildren() do
        if child:IsA("GuiButton") then
            child:Destroy()
        end
    end
    screwsLeft = 4
    step.Text = "Hold on each screw to undo it"
    for _, spot in { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1) } do
        local screw = Instance.new("TextButton")
        screw.Name = "Screw"
        screw.AutoButtonColor = false
        screw.AnchorPoint = spot
        screw.Position = UDim2.new(spot.X, spot.X == 0 and 12 or -12, spot.Y, spot.Y == 0 and 12 or -12)
        screw.Size = UDim2.fromOffset(34, 34)
        screw.BackgroundColor3 = Color3.fromRGB(150, 150, 155)
        screw.FontFace = HEAD
        screw.TextSize = 22
        screw.TextColor3 = Color3.fromRGB(40, 40, 44)
        screw.Text = "+"
        screw.ZIndex = 7
        screw.Parent = cover
        corner(screw, 17)
        table.insert(connections, screw.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                heldScrew = screw
                heldSince = os.clock()
            end
        end))
        table.insert(connections, screw.InputEnded:Connect(function(input)
            if heldScrew == screw and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                heldScrew = nil
                screw.Rotation = 0
            end
        end))
    end
end

-- Open / close --------------------------------------------------------------------

local function open(box: BasePart)
    closeMinigame(false)
    active = true
    fuseBox = box
    gui.Enabled = true
    -- First person locks the mouse to the centre every frame; free it after the camera runs.
    RunService:BindToRenderStep(MOUSE_BINDING, Enum.RenderPriority.Last.Value, function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end)
    buildWires()
    buildScrews()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local lastHealth = humanoid.Health
        table.insert(connections, humanoid.HealthChanged:Connect(function(health)
            if health < lastHealth then
                closeMinigame(true)
                showNotice("You got hit. Repair interrupted")
            end
            lastHealth = health
        end))
    end
    table.insert(connections, close.Activated:Connect(function()
        closeMinigame(true)
    end))
    table.insert(connections, UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
            closeMinigame(true)
        end
    end))
    table.insert(connections, RunService.RenderStepped:Connect(function()
        -- Screw being held: spin it, remove it when the hold is long enough.
        if heldScrew then
            local progress = (os.clock() - heldSince) / SCREW_HOLD_SECONDS
            heldScrew.Rotation = progress * 270
            if progress >= 1 then
                heldScrew:Destroy()
                heldScrew = nil
                screwsLeft -= 1
                if screwsLeft == 0 then
                    cover.Visible = false
                    step.Text = "Drag each wire to the terminal of the same colour"
                end
            end
        end
        -- Walking off, dying or putting the screwdriver away cancels the repair.
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
        local tool = char and char:FindFirstChildOfClass("Tool")
        if
            not root
            or not fuseBox
            or not fuseBox.Parent
            or (root.Position - fuseBox.Position).Magnitude > CANCEL_DISTANCE
            or not tool
            or tool:GetAttribute("WeaponId") ~= "Screwdriver"
        then
            closeMinigame(true)
            showNotice("Repair cancelled")
        end
    end))
end

remote.OnClientEvent:Connect(function(action, value)
    if action == "FuseStart" and typeof(value) == "Instance" and value:IsA("BasePart") then
        open(value)
    elseif action == "FuseEnd" then
        closeMinigame(false)
        showNotice(value)
    elseif action == "Notice" then
        showNotice(value)
    end
end)
player.CharacterRemoving:Connect(function()
    closeMinigame(true)
end)
