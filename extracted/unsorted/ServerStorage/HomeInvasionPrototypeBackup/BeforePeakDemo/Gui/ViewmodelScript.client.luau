local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid", 1)
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 1)
local LeftArm = Character:FindFirstChild("Left Arm") or Character:FindFirstChild("LeftHand")
local RightArm = Character:FindFirstChild("Right Arm") or Character:FindFirstChild("RightHand")
local Camera = Workspace.CurrentCamera
local spring = require(ReplicatedStorage:WaitForChild("Modules").Spring)
local thread = require(ReplicatedStorage:WaitForChild("Modules").Thread)
local recoilViewmodel = ReplicatedStorage:WaitForChild("Events"):FindFirstChild("recoilViewmodel")

Player.CharacterAdded:connect(function(c)
	Humanoid = c:WaitForChild("Humanoid", 1)
	HumanoidRootPart = c:WaitForChild("HumanoidRootPart", 1)
	LeftArm = c:FindFirstChild("Left Arm") or c:FindFirstChild("LeftHand")
	RightArm = c:FindFirstChild("Right Arm") or c:FindFirstChild("RightHand")
end)

local aimCFrame = CFrame.new()
local arms = nil

local generalSettings = {
	canSwing = true;
	canBobble = true;
	canAim = true;
	canRecoil = true;

	fpsCam = true;
	camBobble = false;
	camImpact = true;
	camHurt = true;

	lowestFallHeight = 20;
	maxFallHeight = 30;
	
	recoilYRotMax = 16;
	recoilZPosMax = 1;
	recoilYPosMax = 0.5;
}

--legends:
--[s]: speed
--[d]: damper
--[t]: target
--[p]: position
--[v]: velocity
local speedSpring = spring.spring.new()
speedSpring.s = 15
local swaySpring = spring.spring.new(0)
swaySpring.s = 40
swaySpring.d = 40
local swaySpeed = spring.spring.new(0)
swaySpeed.s = 6
swaySpeed.d = 1
swaySpeed.t = 1
local damageSpring = spring.spring.new(Vector3.new())
damageSpring.s = 20
damageSpring.d = 0.75
local impactSpring = spring.spring.new(Vector3.new())
impactSpring.s	= 0
impactSpring.d	= 1
local velocitySpring = spring.spring.new(Vector3.new())
velocitySpring.s = 0
velocitySpring.t = Vector3.new(1)
velocitySpring.p = Vector3.new(1)
local aimSpring = spring.spring.new()
aimSpring.s = 34
aimSpring.d = 0.9
aimSpring.t = 1
local swingSpring = spring.spring.new(Vector3.new())
swingSpring.s = 10
swingSpring.d = 0.5

local offStates = {"Jumping", "PlatformStanding", "Ragdoll", "Seated", "FallingDown", "FreeFalling", "GettingUp", "Swimming", "Climbing"}
local onStates = {"Running"}

local velocity = Vector3.new()
local speed = 0
local distance = 0
local swayt = 0
local lastHealth = Humanoid.Health
local isFalling = false
local deb = false

local c1 = 0.3		
local c2 = 0
local c3 = 0
local c4 = 0
local c5 = 0
local c6 = 0
local c7 = CFrame.new()

for _,state in pairs(offStates) do
	Humanoid[state]:Connect(function()
		active = false
	end)
end

for _,state in pairs(onStates) do
	Humanoid[state]:Connect(function(speed)
		active = (speed > 1)
	end)
end

local function lerp(a, b, alpha)
	return a + (b - a) * alpha
end

local function randomize(value)
	return (0.5 - math.random()) * 2 * value
end

local function toQuaternion(c)
	local x,y,z,
		xx,yx,zx,
		xy,yy,zy,
		xz,yz,zz=CFrame.new().components(c)
	local tr=xx+yy+zz
	if tr>2.99999 then
		return x,y,z,0,0,0,1
	elseif tr>-0.99999 then
		local m=2*(tr+1)^0.5
		return x,y,z,
			  (yz-zy)/m,
			  (zx-xz)/m,
			  (xy-yx)/m,
			  m/4
	else
		local qx=xx+yx+zx+1
		local qy=xy+yy+zy+1
		local qz=xz+yz+zz+1
		local m	=(qx*qx+qy*qy+qz*qz)^0.5
		return x,y,z,qx/m,qy/m,qz/m,0
	end
end

local function interpolator(c0,c1)
	if c1 then
		local x0,y0,z0,qx0,qy0,qz0,qw0=toQuaternion(c0)
		local x1,y1,z1,qx1,qy1,qz1,qw1=toQuaternion(c1)
		local x,y,z=x1-x0,y1-y0,z1-z0
		local c=qx0*qx1+qy0*qy1+qz0*qz1+qw0*qw1
		if c<0 then
			qx0,qy0,qz0,qw0=-qx0,-qy0,-qz0,-qw0
		end
		if c<0.9999 then
			local s=(1-c*c)^0.5
			local th=math.acos(c)
			return function(t)
				local s0=math.sin(th*(1-t))/s
				local s1=math.sin(th*t)/s
				return CFrame.new(
					x0+t*x,
					y0+t*y,
					z0+t*z,
					s0*qx0+s1*qx1,
					s0*qy0+s1*qy1,
					s0*qz0+s1*qz1,
					s0*qw0+s1*qw1
				)
			end
		else
			return function(t)
				return CFrame.new(x0+t*x,y0+t*y,z0+t*z,qx1,qy1,qz1,qw1)
			end
		end
	else
		local x,y,z,qx,qy,qz,qw=toQuaternion(c0)
		if qw<0.9999 then
			local s=(1-qw*qw)^0.6
			local th=math.acos(qw)
			return function(t)
				local s1=math.sin(th*t)/s
				return CFrame.new(
					t*x,
					t*y,
					t*z,
					s1*qx,
					s1*qy,
					s1*qz,
					math.sin(th*(1-t))/s+s1*qw
				)
			end
		else
			return function(t)
				return CFrame.new(t*x,t*y,t*z,qx,qy,qz,qw)
			end
		end
	end
end

local function fromAxisAngle(x,y,z)
	if not y then
		x,y,z=x.x,x.y,x.z
	end
	local m=(x*x+y*y+z*z)^0.5
	if m>1e-5 then
		local si=math.sin(m/2)/m
		return CFrame.new(0,0,0,si*x,si*y,si*z,math.cos(m/2))
	else
		return CFrame.new()
	end
end

local function getHit(d)
  	local l = CFrame.new():VectorToObjectSpace(d)
  	damageSpring:accelerate(Vector3.new(l.z, 0, -l.x) * 0.25)
	thread:Wait(0.03)
	damageSpring:accelerate(Vector3.new(-l.z, 0, 0) * 0.25)
end

local function gunBob(a, r, baseWalkSpeed)
    local a, r = a or 1, r or 1
	local d, s, v = distance * 6.28318 * 3 / 4, speed, -velocity
    --if s < baseWalkSpeed then
	local w = Vector3.new(r * math.sin(d / 4 - 9988) / 256 + r * (math.sin(d / 64) - r * v.z / 3) / 641, r * math.cos(d / 128) / 128 - r * math.cos(d / 8) / 256, r * math.sin(d / 8) / 128 + r * v.x / 1024) * s / 20 * 6.28318
	return CFrame.new(r * math.cos(d / 7.4 - 10000) * s / 196, 1.25 * a * math.sin(d / 4) * s / 621, 0) * fromAxisAngle(w)
    --else
      	--local w = Vector3.new((r * math.sin(d / 4 - 1) / 256 + r * (math.sin(d / 64) - r * v.z / 4) / 512) * s / 20 * 6.28318, (r * math.cos(d / 128) / 128 - r * math.cos(d / 8) / 256) * s / 20 * 6.28318, r * math.sin(d / 8) / 128 * (5 * s - 56) / 20 * 6.28318 + r * v.x / 1024)
      	--return CFrame.new(r * math.cos(d / 8 - 1) * (5 * s - 56) / 196, 1.25 * a * math.sin(d / 4) * s / 512, 0) * fromAxisAngle(w)
    --end
end

local function gunSway(a)
    local d, s = tick() * 6, 2 * (1.2 - a)
	return CFrame.new(math.cos(d / 8 - 9) * s / 1028, -math.sin(d / 10) * s / 128, math.sin(d / 16) * s / 64)
end

local function HealthChanged(health)
	if lastHealth > health and lastHealth - health >= 5 then
		if Humanoid.Health ~= Humanoid.MaxHealth then
			damagedealt = lastHealth-health
			thread:Spawn(function()
				local dir = Vector3.new(0, 0, 0)
				if Humanoid:FindFirstChild("creator") then
					local killer = Humanoid:FindFirstChild("creator")
					local killerChar = killer.Value.Character
					local killerHum = killerChar:FindFirstChildOfClass("Humanoid")
					local killerHRP = killerChar:FindFirstChild("HumanoidRootPart")
					if killerChar and killerHRP and killerHum and killerHum.Health > 0 then
						dir = (Camera.CFrame.p - killerHRP.Position).unit
					else
						dir = (Camera.CFrame.p - HumanoidRootPart.Position).unit
					end
				else
					dir = (Camera.CFrame.p - HumanoidRootPart.Position).unit
				end
				getHit((-damagedealt / 12 + 4.166666666666667) * dir)
			end)
		end
	end
	lastHealth = health
end

Humanoid.FreeFalling:connect(function(falling)
	isFalling = falling
	if isFalling and not deb then
		deb = true
		local maxHeight, lowHeight = 0, math.huge
		while isFalling do
			local height = HumanoidRootPart.Position.y
			if height > maxHeight then
				maxHeight = height
			end
			if height < lowHeight then
				lowHeight = height
			end
			thread:Wait()
		end
		local fallHeight = maxHeight - lowHeight
		local impactHeight = fallHeight - generalSettings.lowestFallHeight
		if impactHeight > 0 then
			--local damage = impactHeight * (humanoid.MaxHealth / generalSettings.maxFallHeight)
			--humanoid:TakeDamage(damage)
			impactSpring:accelerate(Vector3.new(0, 0, math.random(-impactHeight, impactHeight) / 5))
		end
		deb = false
	end
end)

if recoilViewmodel then
	recoilViewmodel.Event:Connect(function(value)
		c1 = value
	end)	
end

Camera.ChildAdded:Connect(function(child)
	arms = nil
	if child.Name == "Arms" then
		arms = child
		if arms:FindFirstChild("AimPoint") then
			aimCFrame = arms.PrimaryPart.CFrame:ToObjectSpace(arms.AimPoint.CFrame):Inverse()
		end
		arms.AncestryChanged:Connect(function()
			if arms and not arms:IsDescendantOf(game) then
				arms = nil
				aimCFrame = nil
			end
		end)
	end
end)


RunService.RenderStepped:Connect(function(dt)
	if Character and HumanoidRootPart and Humanoid then
		local mouseDelta = UserInputService:GetMouseDelta()
		c1 = c1 > 0.1 and lerp(c1, 0, dt * 11) or 0
    	local a = velocitySpring.v
    	swingSpring.t = Vector3.new(a.z / 1024 / 32 + a.y / 1024 / 16 + (mouseDelta.y / 10) / 1024 * 3 / 2, a.x / 1024 / 32 + (mouseDelta.x / 10) / 1024 * 3 / 2, -(mouseDelta.x / 10) / 1024 * 3 / 2)
		local aim = aimSpring.p
		local relv = CFrame.new().VectorToObjectSpace(HumanoidRootPart.CFrame, HumanoidRootPart.Velocity)
		speedSpring.t = (active and Humanoid.Health > 0) and (Vector3.new(1, 0, 1) * relv).magnitude or 0
		velocitySpring.t = relv
		speed = speedSpring.p
		distance = distance + dt * speedSpring.p
		velocity = velocitySpring.p
		swayt = swayt + dt * swaySpeed.p
		if generalSettings.fpsCam then
			local cf = CFrame.new()
			cf = Camera.CoordinateFrame
		    local t = swayt
		    local s, d = 0.5 * speed, distance * 6.28318 / 4 * 3 / 4
		    local ss = swaySpring.p
		    local bobAngles = fromAxisAngle(s * math.cos(d + 2) / 2048, s * math.cos(d / 2) / 2048, s * math.cos(d / 2 + 2) / 4096) * fromAxisAngle(ss * math.cos(2 * t + 2) / 2048, ss * math.cos(2 * t / 2) / 2048, ss * math.cos(2 * t / 2 - 2) / 4096)
		    local damageAngles = fromAxisAngle(damageSpring.p)
			local impactAngles = fromAxisAngle(impactSpring.p)
			if generalSettings.camBobble then
				cf = cf * bobAngles
			end
			if generalSettings.camHurt then
				cf = cf * damageAngles
			end
			if generalSettings.camImpact then
				cf = cf * impactAngles
			end
			Camera.CoordinateFrame = cf
		end
		if Humanoid.Health > 0 and Camera and Camera:FindFirstChild("Arms") and Camera.Arms.PrimaryPart then
			if Camera and Camera:FindFirstChild("Arms") and Camera.Arms:FindFirstChild("VMArms") then
				local child = Camera.Arms
				if child and child.Name == "Arms" and Character and LeftArm and RightArm then
					child:WaitForChild("VMArms")["Left Arm"].Transparency = 0
					child:WaitForChild("VMArms")["Right Arm"].Transparency = 0
					if Character:FindFirstChild("Shirt") then
						child:WaitForChild("VMArms")["Left Arm"].Shirt.Texture = Character.Shirt.ShirtTemplate
						child:WaitForChild("VMArms")["Right Arm"].Shirt.Texture = Character.Shirt.ShirtTemplate						
					end
					child:WaitForChild("VMArms")["Left Arm"].Color = LeftArm.Color
					child:WaitForChild("VMArms")["Right Arm"].Color = RightArm.Color
				end
			end
			c2 = lerp(c2, generalSettings.recoilYRotMax * c1, c1 == 0 and dt * 7 or dt * 6) + lerp(c3, randomize(2) * c1, c1 == 0 and dt * 7 or dt / 2)
			c3 = lerp(c3, randomize(1.3) * c1, c1 == 0 and dt * 7 or dt * 3)
			c4 = lerp(c4, randomize(5) * c1, c1 == 0 and dt * 7 or dt / 3)
			c5 = lerp(c5, generalSettings.recoilYPosMax * c1, c1 == 0 and dt * 7 or dt * 0.4)
			c6 = lerp(c6, generalSettings.recoilZPosMax * c1, c1 == 0 and dt * 7 or dt * 0.9)
			c7 = CFrame.new(0, c5, c6) * CFrame.Angles(math.rad(c2), c3, c4)
			
			local cf = CFrame.new()
			cf = Camera.CoordinateFrame * CFrame.new(0, 0, (Camera.FieldOfView / 90 - 1) * 0.3)
			
			if Camera.Arms:FindFirstChild("isAiming").Value then
				mouseDelta = mouseDelta * 0.75
				aimSpring.t = Camera.Arms:FindFirstChild("aimSteady").aim.Value
			else
				aimSpring.t = Camera.Arms:FindFirstChild("aimSteady").noAim.Value
			end
			
			if generalSettings.canSwing then
				cf = cf * fromAxisAngle(swingSpring.v)
			end
			if generalSettings.canBobble then
				cf = cf * gunBob(0.7 - 0.3 * aimSpring.p, 1 - 0.8 * aimSpring.p, Humanoid.WalkSpeed) * gunSway(aim)
			end
			if generalSettings.canAim then
				if Camera.Arms:FindFirstChild("AimPoint") then
					local aimcf = interpolator(aimCFrame)
					cf = cf * aimcf(aim)
				end
			end
			if generalSettings.canRecoil then
				cf = cf * c7
			end
			local offset = require(Camera.Arms:FindFirstChild("offset"))
			local offst = interpolator(offset)
			cf = cf * offst(1 - aim)
			
			Camera.Arms.PrimaryPart.Anchored = true
			if Camera.CameraType == Enum.CameraType.Custom then
				Camera.Arms.PrimaryPart.CFrame = cf
			end
		end
	end
end)

Humanoid.HealthChanged:connect(HealthChanged)
Humanoid.Died:connect(function() HealthChanged(20) end)
HealthChanged(Humanoid.Health)