-- Shows secret roles (traitor, survivor), trap controls, and objective hints.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local state = ReplicatedStorage:WaitForChild("HomeInvasionRoundState")
local secretRole = state:WaitForChild("SecretRole")
local traps = ReplicatedStorage:WaitForChild("HomeInvasionTraps"):WaitForChild("Interaction")

local gui = Instance.new("ScreenGui")
gui.Name = "RoleHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function label(name, position, size, textSize)
	local text = Instance.new("TextLabel")
	text.Name = name
	text.AnchorPoint = Vector2.new(0.5, 0)
	text.Position = position
	text.Size = size
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextSize = textSize
	text.TextColor3 = Color3.fromRGB(235, 225, 210)
	text.TextStrokeTransparency = 0.4
	text.TextWrapped = true
	text.Visible = false
	text.Parent = gui
	return text
end

local banner = label("Banner", UDim2.fromScale(0.5, 0.22), UDim2.fromOffset(600, 90), 26)
local info = label("Info", UDim2.new(0.5, 0, 1, -150), UDim2.fromOffset(600, 50), 16)

local secret = nil -- "Traitor" for the traitor, or the traitor's name for Invaders
local bannerToken = 0

local function showBanner(text, color, seconds)
	bannerToken += 1
	local token = bannerToken
	banner.Text = text
	banner.TextColor3 = color
	banner.Visible = true
	task.delay(seconds, function()
		if token == bannerToken then
			banner.Visible = false
		end
	end)
end

local function refresh()
	local phase = state:GetAttribute("Phase")
	local inRound = player:GetAttribute("InRound") == true
	if not inRound or not (phase == "Preparation" or phase == "Active") then
		info.Visible = false
		if phase ~= "Starting" then
			secret = nil
		end
		return
	end
	local lines = {}
	if secret == "Traitor" then
		table.insert(lines, "You're the traitor. Help the Invaders win, and don't get caught.")
	elseif secret then
		table.insert(lines, "The traitor is " .. secret .. ". Don't hurt them.")
	end
	if player:GetAttribute("Survivor") then
		table.insert(lines, string.format("T: set a nail trap (%d left)", player:GetAttribute("TrapsLeft") or 0))
	end
	if player:GetAttribute("HasKeys") then
		table.insert(lines, "You have the car keys. Get to the escape point!")
	elseif phase == "Active" and state:GetAttribute("KeysHolder") then
		table.insert(lines, state:GetAttribute("KeysHolder") .. " has the car keys")
	end
	if phase == "Active" and state:GetAttribute("PowerOn") == false and player:GetAttribute("RoundRole") == "Protectors" then
		table.insert(lines, "The power is out. Find the fuse box (G).")
	end
	info.Text = table.concat(lines, "\n")
	info.Visible = #lines > 0
end

secretRole.OnClientEvent:Connect(function(kind, name)
	if kind == "Traitor" then
		secret = "Traitor"
		showBanner("You're the TRAITOR.\nYou hired the Invaders. Make sure nobody gets out.", Color3.fromRGB(230, 80, 70), 7)
	elseif kind == "TraitorIs" then
		secret = name
		showBanner(name .. " is working with you.", Color3.fromRGB(230, 80, 70), 5)
	end
	refresh()
end)

player:GetAttributeChangedSignal("Survivor"):Connect(function()
	if player:GetAttribute("Survivor") then
		showBanner("You're the SURVIVOR.\nPress T to set nail traps for the Invaders.", Color3.fromRGB(120, 200, 140), 6)
	end
	refresh()
end)

player:GetAttributeChangedSignal("HasKeys"):Connect(function()
	if player:GetAttribute("HasKeys") then
		showBanner("You found the car keys.\nGet to the escape point!", Color3.fromRGB(230, 200, 90), 4)
	end
end)

traps.OnClientEvent:Connect(function(kind, message)
	if kind == "Notice" then
		showBanner(message, Color3.fromRGB(235, 225, 210), 2)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or UserInputService:GetFocusedTextBox() then
		return
	end
	if input.KeyCode == Enum.KeyCode.T and player:GetAttribute("Survivor") then
		traps:FireServer("Place")
	end
end)

state.AttributeChanged:Connect(refresh)
player.AttributeChanged:Connect(refresh)
refresh()
