--!strict
-- Small helpers every task script uses: prompts, player checks, notices, models
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")

local TaskKit = {}

TaskKit.roundState = ReplicatedStorage:WaitForChild("HomeInvasionRoundState")
TaskKit.arena = workspace:WaitForChild("HomeInvasionPrototype")

local folder = ReplicatedStorage:FindFirstChild("HomeInvasionTasks") or Instance.new("Folder")
folder.Name = "HomeInvasionTasks"
folder.Parent = ReplicatedStorage
local remote = folder:FindFirstChild("Interaction") or Instance.new("RemoteEvent")
remote.Name = "Interaction"
remote.Parent = folder
TaskKit.remote = remote :: RemoteEvent

local taskFolder = TaskKit.arena:FindFirstChild("Tasks") or Instance.new("Folder")
taskFolder.Name = "Tasks"
taskFolder.Parent = TaskKit.arena
TaskKit.folder = taskFolder

-- notices show up through the fuse box client, which already draws them
local noticeRemote = ReplicatedStorage:WaitForChild("HomeInvasionObjectives"):WaitForChild("Interaction") :: RemoteEvent

function TaskKit.notify(player: Player, message: string)
    if player.Parent == Players then
        noticeRemote:FireClient(player, "Notice", message)
    end
end

function TaskKit.notifyTeam(teamName: string?, message: string)
    for _, player in Players:GetPlayers() do
        if player:GetAttribute("InRound") and (teamName == nil or player.Team == Teams:FindFirstChild(teamName)) then
            TaskKit.notify(player, message)
        end
    end
end

function TaskKit.phase(): string?
    return TaskKit.roundState:GetAttribute("Phase")
end

-- returns the root part if the player is alive, in the round and on the given team
function TaskKit.validPlayer(player: Player, teamName: string?): BasePart?
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if
        player.Parent ~= Players
        or player:GetAttribute("InRound") ~= true
        or not humanoid
        or humanoid.Health <= 0
        or not root
        or (teamName and player.Team ~= Teams:FindFirstChild(teamName))
    then
        return nil
    end
    return root :: BasePart
end

function TaskKit.inRange(player: Player, part: BasePart, range: number): boolean
    local root = TaskKit.validPlayer(player)
    return root ~= nil and (root.Position - part.Position).Magnitude <= range
end

-- forTeam lets the client hide prompts meant for the other side. The server still checks
function TaskKit.prompt(parent: Instance, objectText: string, actionText: string, hold: number, forTeam: string?, key: Enum.KeyCode?): ProximityPrompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.ObjectText = objectText
    prompt.ActionText = actionText
    prompt.HoldDuration = hold
    prompt.MaxActivationDistance = 8
    prompt.RequiresLineOfSight = false
    prompt.KeyboardKeyCode = key or Enum.KeyCode.F
    if forTeam then
        prompt:SetAttribute("ForTeam", forTeam)
    end
    prompt.Parent = parent
    return prompt
end

-- Studio only: automated tests can't press prompts, so they invoke
-- ServerStorage.StudioTaskTest with (prompt, player) to run the same handler
local handlers: { [ProximityPrompt]: (Player) -> () } = {}
if game:GetService("RunService"):IsStudio() then
    local hook = (ServerStorage:FindFirstChild("StudioTaskTest") or Instance.new("BindableFunction")) :: BindableFunction
    hook.Name = "StudioTaskTest"
    hook.Parent = ServerStorage
    -- all task scripts share this one module, so one handler table covers every prompt
    hook.OnInvoke = function(prompt, player)
        local handler = handlers[prompt]
        if handler then
            handler(player)
            return true
        end
        return false
    end
end

function TaskKit.connect(prompt: ProximityPrompt, handler: (Player) -> ())
    handlers[prompt] = handler
    prompt.Triggered:Connect(handler)
    prompt.Destroying:Connect(function()
        handlers[prompt] = nil
    end)
end

-- makes an invisible anchor part with the stored model on top, or a plain block if the model is missing
function TaskKit.place(name: string, cframe: CFrame, size: Vector3, color: Color3): BasePart
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Anchored = true
    part.CanCollide = false
    part.CFrame = cframe
    local models = ServerStorage:FindFirstChild("HomeInvasionTaskModels")
    local template = models and models:FindFirstChild(name)
    if template then
        local visual = template:Clone()
        visual.Name = "Visual"
        if visual:IsA("BasePart") then
            visual.Anchored = true
            visual.CanCollide = false
            visual.CFrame = cframe * CFrame.new(0, visual.Size.Y / 2 - size.Y / 2, 0)
        elseif visual:IsA("Model") then
            visual:PivotTo(cframe)
        end
        visual.Parent = part
        part.Transparency = 1
    end
    part.Parent = taskFolder
    return part
end

function TaskKit.setVisible(part: BasePart, visible: boolean)
    local visual = part:FindFirstChild("Visual")
    local parts = visual and (visual:IsA("BasePart") and { visual } or visual:GetDescendants()) or { part }
    for _, child in parts do
        if child:IsA("BasePart") then
            if child:GetAttribute("BaseTransparency") == nil then
                child:SetAttribute("BaseTransparency", child.Transparency)
            end
            child.Transparency = visible and child:GetAttribute("BaseTransparency") or 1
        end
    end
end

function TaskKit.sound(parent: Instance, id: string, volume: number, range: number?): Sound
    local sound = Instance.new("Sound")
    sound.SoundId = id
    sound.Volume = volume
    sound.RollOffMaxDistance = range or 120
    sound.Parent = parent
    return sound
end

-- runs onStart when preparation begins and onEnd when the round is over
function TaskKit.onRound(onStart: (() -> ())?, onActive: (() -> ())?, onEnd: (() -> ())?)
    TaskKit.roundState:GetAttributeChangedSignal("Phase"):Connect(function()
        local phase = TaskKit.phase()
        if phase == "Preparation" then
            if onEnd then
                onEnd()
            end
            if onStart then
                task.spawn(onStart)
            end
        elseif phase == "Active" then
            if onActive then
                task.spawn(onActive)
            end
        elseif onEnd then
            onEnd()
        end
    end)
end

return TaskKit
