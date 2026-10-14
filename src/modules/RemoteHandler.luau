if nil then repeat until nil script:Destroy() end

local module = {}

if not _G.ids then
	_G.ids = {}
end

local remotes = game.ReplicatedStorage:WaitForChild("Remotes")

module.Fire = function(remote, ...)
	if remotes:FindFirstChild(remote) then
		if not _G.ids[remote] then
			_G.ids[remote] = 0
		end
		_G.ids[remote] = _G.ids[remote] + 1
		
		remotes[remote]:FireServer(...)
		--remotes[remote]:FireServer(_G.ids[remote], ...)
	end
end

module.Invoke = function(remote, ...)
	if remotes:FindFirstChild(remote) then
		if not _G.ids[remote] then
			_G.ids[remote] = 0
		end
		_G.ids[remote] = _G.ids[remote] + 1
		
		remotes[remote]:InvokeServer(...)
		--remotes[remote]:InvokeServer(_G.ids[remote], ...)
	end
end

return module