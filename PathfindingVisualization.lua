local module = {}
local temp = script.WaypointObjective
local nameTemp = script.NPCTemp
local pathServ = require(game.ServerStorage.CreatePath)
local points = {}
local tweenServ = game:GetService("TweenService")
local timeValues = {
	[10] = Color3.fromRGB(85, 170, 0),
	[20] = Color3.fromRGB(170, 255, 0),
	[30] = Color3.fromRGB(255, 152, 0),
	[40] = Color3.fromRGB(255, 0, 0),
}

function returnColor(Time)
	for value, color in pairs(timeValues) do
		if Time < value then
			return color
		end
	end
end

function module.BlockedPath(NPC, target)
	local waypoint = points[target]
	if waypoint then
		local npcName = waypoint.Main.NPCsAssigned:FindFirstChild(NPC.Name)
		if npcName then
			npcName.NoReach.Visible = true
			wait(3)
			npcName:Destroy()
			if not waypoint:FindFirstChild("Main") then
				waypoint:Destroy()
				return
			end
			if #waypoint:WaitForChild("Main").NPCsAssigned:GetChildren() == 1 then
				wait(5)
				--TODO:ADD_IMPLEMENTATION_FOR_FADING_OUT
				pcall(function()
					waypoint.Parent:Destroy()
				end)
				points[target] = nil
			end
		end
	end
end

function AssignNPC(NPC, objective, target)
	local label = nameTemp:Clone()
	label.Name = NPC.Name
	label.Text = NPC.Name
	label.Parent = objective.Main.NPCsAssigned
	local func = coroutine.wrap(function()
		local count = 0
		while wait(1) and objective:FindFirstChild("Main") do
			count += 1
			if count > 60 then
				--warn(NPC.Name.." couldn't reach his destination... how bad!")
				NPC:BreakJoints()
				module.BlockedPath(NPC, target)
			end
			tweenServ:Create(label, TweenInfo.new(1), {BackgroundColor3 = returnColor(count)}):Play()
		end
	end)
	func()
end

function module.CreatePath(a, b)
	return pathServ.CreatePath(a, b)
end

function module.FinishedWaypoint(NPC, target)
	local waypoint = points[target]
	if waypoint then
		local npcName = waypoint.Main.NPCsAssigned:FindFirstChild(NPC.Name)
		if npcName then
			npcName:Destroy()
			if #waypoint.Main.NPCsAssigned:GetChildren() == 1 then
				wait(.5)
				--TODO:ADD_IMPLEMENTATION_FOR_FADING_OUT
				pcall(function()
					waypoint.Parent:Destroy()
				end)
				points[target] = nil
			end
		end
	end
end

function module.AddWaypoint(NPC, target)
	local existingWaypoint = points[target]
	if existingWaypoint ~= nil then
		print("Duplicated target found: "..NPC.Name)
		AssignNPC(NPC, existingWaypoint, target)
		return
	end
	local bill = temp:Clone()
	local part = Instance.new("Part", workspace)
	part.Position = target
	part.Size =  Vector3.new(1,1,1)
	part.Anchored = true
	part.Name = "Marker_"..shared.BetterMathRandom(1, 100000)
	part.CanCollide = false
	part.Transparency = 1
	bill.Parent = part
	bill.Adornee = part
	points[target] = bill
	local func = coroutine.wrap(function()
		local Time = 0
		while wait(1) and bill:FindFirstChild("Main") do
			Time += 1
			bill.Main.Timer.Text = Time.."s"
		end
		print(part.Name.." no longer exists.")
		pcall(function()
			part:Destroy()
		end)
	end)
	func()
	AssignNPC(NPC, bill, target)
end

spawn(function() --i could use coroutines but spawn gets the job done
	while wait(10) do
		for _, item in ipairs(workspace.PathVisualization:GetChildren()) do
			local bill = item:FindFirstChild("WaypointObjective")
			if bill then
				local quantity = bill.Main.NPCsAssigned:GetChildren()
				if #quantity == 1 then
					item:Destroy()
					print("Deleted empty WaypointMarker.")
				end
			else
				item:Destroy()
			end
		end
	end
end)

return module