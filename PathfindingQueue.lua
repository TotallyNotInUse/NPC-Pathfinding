local module = {}
local pathServ = game:GetService("PathfindingService")
local Requests = {
	Completed = 0,
	Success = 0,
	Fail = 0,
	Sent = 0,
	Ghost = 0,
}
local board = workspace.Billboard.Screen.SurfaceGui
local pendingPaths = {}
local npcPending = {}
local completedPaths = {}
local creationTimes = {}

function module.CreatePath(NPC, Objective)
	local completed = false
	local start = tick()
	pendingPaths[NPC.Name] = Objective
	table.insert(npcPending, NPC.Name)
	local a = 0
	spawn(function()
		while not completed do
			if not NPC:FindFirstChild("Head") then
				pcall(function()
					NPC:Destroy()
				end)
				return
			end
			NPC.Head.Overhead.Main.State.Text = "AWAITING PATH FOR "..Objective.Name.." ("..a.."s)"
			wait()
		end
	end)
	repeat
		a += 1
		if a >= 30 then
			break
		end
		wait(1)
	until completedPaths[NPC.Name] ~= nil
	completed = true
	local path = completedPaths[NPC.Name]
	if path == nil then
		Requests.Fail += 1
		NPC.Head.Overhead.Main.State.Text = "TIME LIMIT NOT REACHED"
		return nil
	elseif path == false then
		if not NPC:FindFirstChild("Head") then
			pcall(function()
				NPC:Destroy()
			end)
			return false
		end
		NPC.Head.Overhead.Main.State.Text = "PATH NOT AVAILABLE"
		return false
	else
		local endTime = tick()-start
		endTime = string.sub(tostring(endTime), 1, 4)
		table.insert(creationTimes, tonumber(endTime))
		pendingPaths[NPC.Name] = nil
		completedPaths[NPC.Name] = nil
		return path
	end
end

function average(t)
	local sum = 0
	for _,v in pairs(t) do
		sum = sum + v
	end
	return sum / #t
end

function HandleRequests()
	local runServ = game:GetService("RunService")
	while runServ.Stepped:Wait() do
		local queue = npcPending[1]
		if queue ~= nil then
			local item = pendingPaths[queue]
			if item then
				Requests.Sent += 1
				local npc = workspace.NPCs:FindFirstChild(queue)
				if npc then
					local succ, path = pcall(function()
						return pathServ:FindPathAsync(npc.HumanoidRootPart.Position, item.Position)
					end)
					if succ then
						if path.Status == Enum.PathStatus.NoPath then
							completedPaths[queue] = false
							Requests.Sent -= 1
							Requests.Completed -= 1
						else
							Requests.Success += 1
							completedPaths[queue] = path
						end
					else
						completedPaths[queue] = false
					end
				else
					completedPaths[queue] = false
				end
				Requests.Completed += 1
				table.remove(npcPending, table.find(npcPending, queue))	
			else
				Requests.Ghost += 1
				table.remove(npcPending, table.find(npcPending, queue))
			end
		end
	end
end

for i = 1, 1, 1 do --can be modified to add more handlers, usually use 1 handler per 100 NPCs
	local func = coroutine.wrap(HandleRequests)
	func()
end
spawn(function()
	while wait(1) do
        --math is wrong i know
		game.ReplicatedStorage.RequestQueue.Value = #npcPending
		
		local endTime = string.sub(tostring(average(creationTimes)), 1, 4)
		local percenCompleted = math.floor(Requests.Completed/Requests.Sent*100)
		local percenFailed = math.floor(Requests.Fail/Requests.Completed*100)
		local percenSuccess = math.floor(Requests.Success/Requests.Completed*100)
		local percenGhost = math.floor(Requests.Ghost/Requests.Sent*100)
		--local percenFake = math.floor(Requests.Fake/Requests.Sent*100)
		
		board.Average.Text = "Average time to completed requests: "..endTime.." seconds."
		board.Completed.Text = percenCompleted.."% of requests sent, were completed."
		board.Failed.Text = percenFailed.."% of requests sent, failed to complete."
		--board.Fake.Text = percenFake.."% of requests sent, couldn't be reached."
		board.Ghost.Text = percenGhost.."% of requests sent, were ghost requests."
		board.Success.Text = percenSuccess.."% of requests sent, completed successfully."
	end
end)

return module