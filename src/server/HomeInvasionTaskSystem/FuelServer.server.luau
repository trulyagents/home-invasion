-- the escape car starts out empty. Protectors carry a gas can from the house to the
-- car. Invaders can drain the tank, which sends the can back into the house
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(script.Parent.Config)
local TaskKit = require(script.Parent.TaskKit)
local SpotPicker = require(ServerScriptService.HomeInvasionRoundSystem.SpotPicker)

local roundState = TaskKit.roundState
local noise = game:GetService("ServerStorage"):WaitForChild("HomeInvasionNoise")
local can, canPrompt, carrier, spot
local fuelPrompt, drainPrompt
local lastDrain = 0

local function setCarrier(player)
    if carrier then
        carrier:SetAttribute("HasFuel", nil)
    end
    carrier = player
    if player then
        player:SetAttribute("HasFuel", true)
    end
end

local function cleanup()
    setCarrier(nil)
    if can then
        can:Destroy()
    end
    for _, prompt in { fuelPrompt, drainPrompt } do
        prompt:Destroy()
    end
    can, canPrompt, fuelPrompt, drainPrompt = nil, nil, nil, nil
    SpotPicker.release(spot)
    spot = nil
    roundState:SetAttribute("CarFueled", nil)
end

local function dropCan(position)
    setCarrier(nil)
    can.CFrame = CFrame.new(position)
    local visual = can:FindFirstChild("Visual")
    if visual and visual:IsA("BasePart") then
        visual.CFrame = can.CFrame * CFrame.new(0, visual.Size.Y / 2 - can.Size.Y / 2, 0)
    end
    TaskKit.setVisible(can, true)
    canPrompt.Enabled = true
end

-- puts the can on a free spot in the house, away from everyone
local function hideCan()
    SpotPicker.release(spot)
    spot = SpotPicker.take(Config.GasMinDistance)
    if spot then
        dropCan(spot.Position + Vector3.new(0, 0.65, 0))
    end
end

local function makeCan()
    can = TaskKit.place("GasCan", CFrame.new(0, -500, 0), Vector3.new(0.7, 1.3, 1.1), Color3.fromRGB(170, 30, 25))
    canPrompt = TaskKit.prompt(can, "Gas can", "Take", 0.4, "Protectors")
    TaskKit.connect(canPrompt, function(player)
        local root = TaskKit.validPlayer(player, "Protectors")
        if carrier or not root or (root.Position - can.Position).Magnitude > 10 or player:GetAttribute("HasKeys") then
            if player:GetAttribute("HasKeys") then
                TaskKit.notify(player, "Your hands are full. Someone else has to carry the gas")
            end
            return
        end
        local phase = TaskKit.phase()
        if phase ~= "Preparation" and phase ~= "Active" then
            return
        end
        setCarrier(player)
        TaskKit.setVisible(can, false)
        canPrompt.Enabled = false
        TaskKit.notify(player, "Take the gas can to the car")
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        humanoid.Died:Once(function()
            if carrier == player and can then
                dropCan(root.Position - Vector3.new(0, 2.3, 0))
            end
        end)
    end)
end

local function makeCarPrompts()
    local pad = TaskKit.arena:FindFirstChild("EscapePoint", true)
    if not pad then
        return
    end
    fuelPrompt = TaskKit.prompt(pad, "Escape car", "Fill the tank", Config.FuelSeconds, "Protectors")
    TaskKit.connect(fuelPrompt, function(player)
        if roundState:GetAttribute("CarFueled") or carrier ~= player
            or not TaskKit.validPlayer(player, "Protectors") or not TaskKit.inRange(player, pad, 14) then
            if carrier ~= player then
                TaskKit.notify(player, "You need the gas can")
            end
            return
        end
        setCarrier(nil)
        roundState:SetAttribute("CarFueled", true)
        noise:Fire(pad.Position, "car")
        TaskKit.notifyTeam("Protectors", "The car has gas now")
    end)
    drainPrompt = TaskKit.prompt(pad, "Escape car", "Drain the tank", Config.DrainSeconds, "Invaders")
    TaskKit.connect(drainPrompt, function(player)
        if not roundState:GetAttribute("CarFueled") or TaskKit.phase() ~= "Active"
            or not TaskKit.validPlayer(player, "Invaders") or not TaskKit.inRange(player, pad, 14) then
            return
        end
        if os.clock() - lastDrain < Config.DrainCooldown then
            TaskKit.notify(player, "The tank is nearly dry already. Try again later")
            return
        end
        lastDrain = os.clock()
        roundState:SetAttribute("CarFueled", false)
        hideCan()
        TaskKit.notifyTeam("Protectors", "Someone drained the car. The gas can is back in the house")
    end)
end

local function setup()
    cleanup()
    lastDrain = 0
    roundState:SetAttribute("CarFueled", false)
    makeCan()
    hideCan()
    -- the escape pad is made by the objective script, so give it a moment
    local deadline = os.clock() + 5
    while not TaskKit.arena:FindFirstChild("EscapePoint", true) and os.clock() < deadline do
        task.wait(0.2)
    end
    if TaskKit.phase() == "Preparation" then
        makeCarPrompts()
    end
end

TaskKit.onRound(setup, nil, cleanup)

Players.PlayerRemoving:Connect(function(player)
    if player == carrier and can then
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            dropCan(root.Position - Vector3.new(0, 2.3, 0))
        else
            hideCan()
        end
    end
end)
