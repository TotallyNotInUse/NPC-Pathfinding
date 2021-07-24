local regionPart = workspace.Baseplate
local lastValue = 0
local redKills = 0
local blueKills = 0
local minRange = regionPart.Position - (0.5 * regionPart.Size)
local maxRange = regionPart.Position + (0.5 * regionPart.Size)

function GetBlueColors()
	local count = 0
	for _, npc in ipairs(workspace.NPCs:GetChildren()) do
		if npc.Team.Value == game.Teams.BLUE then
			count += 1
		end
	end
	return count
end

function GetRedColors()
	local count = 0
	for _, npc in ipairs(workspace.NPCs:GetChildren()) do
		if npc.Team.Value == game.Teams.RED then
			count += 1
		end
	end
	return count
end

function shared.BetterMathRandom(min, max)
	local v = 0
	repeat
		v = math.random(min, max)
		wait()
	until v ~= lastValue
	lastValue = v
	return v
end

workspace.NPCs.ChildRemoved:Connect(function(child)
	local creator = child.Humanoid:FindFirstChild("creator")
	if creator then
		local killerName = creator.Value
		local killer = workspace.NPCs:FindFirstChild(killerName)
		if killer then
			local killerColor = killer.Team.Value.TeamColor.Color
			local victimColor = child.Team.Value.TeamColor.Color
			if killerColor == Color3.fromRGB(255,0,0) then
				killerColor = "rgb(255,0,0)"
				redKills += 1
			else
				killerColor = "rgb(0,0,255)"
				blueKills += 1
			end
			if victimColor == Color3.fromRGB(255,0,0) then
				victimColor = "rgb(255,0,0)"
			else
				victimColor = "rgb(0,0,255)"
			end
			local str = string.format("<b><font color=\"%s\">%s</font></b> killed <b><font color=\"%s\">%s</font></b>!", killerColor, killer.Name, victimColor, child.Name)
			game.ReplicatedStorage.Events.FeedEvent:FireAllClients(str)
		end
	else
		local victimColor = child.Team.Value.TeamColor.Color
		if victimColor == Color3.fromRGB(255,0,0) then
			victimColor = "rgb(255,0,0)"
		else
			victimColor = "rgb(0,0,255)"
		end
		game.ReplicatedStorage.Events.FeedEvent:FireAllClients("<font color=\""..victimColor.."\">"..child.Name.."</font> committed suicide.")
	end
end)

function GenNpc()
	local model = game.ServerStorage.Dummy:Clone()
	model.Team.Value = game.Teams:GetChildren()[shared.BetterMathRandom(1, #game.Teams:GetChildren())]
	model.Name = "NPC"..shared.BetterMathRandom(1, 10000)
	model.Parent = workspace.NPCs
	for _, item in ipairs(model:GetChildren()) do
		if item:IsA("BasePart") then
			item.BrickColor = model.Team.Value.TeamColor
			item:SetNetworkOwner(nil)
		end
	end
	model:MoveTo(Vector3.new(shared.BetterMathRandom(minRange.X, maxRange.X), 100, shared.BetterMathRandom(minRange.Z, maxRange.Z)))
	game.Debris:AddItem(model.ForceField, 5)
end

game:BindToClose(function()
	warn("The game finished with these stats: \n Blue had "..blueKills.." kills. \n Red had "..redKills.." kills.")
	if blueKills > redKills then
		warn("BLUE team won the game!")
	else
		warn('RED team won the game!')
	end
end)

while wait(1) do
	local limit = game.ReplicatedStorage.Limit.Value
	local count = #workspace.NPCs:GetChildren()
	if count < limit then
		for i = limit-count, 1, -1 do
			GenNpc()
			wait()
		end
	end
	if GetBlueColors() == count or GetRedColors() == count then
		workspace.NPCs:ClearAllChildren()
	end
	if count > limit then
		workspace.NPCs:ClearAllChildren()
	end
end