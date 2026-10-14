-- NOTE: was Disabled in Studio
local cam = workspace.CurrentCamera

local function remove()
	local function begone(name)
		local obj = cam:FindFirstChild(name)
		if obj then obj:Destroy() end
	end

	begone("Bloom1")
	begone("Blur1")
	begone("ColorCorrection1")
	cam.CameraType = Enum.CameraType.Custom
end

remove()
