--script inside NPC
local char = script.Parent
local framework = require(game.ServerStorage.Pathfinding)
local pathServ = require(game.ServerStorage.CreatePath)
local hrp = char.HumanoidRootPart
local notReacheable = {}
local lastValue = 0
local overhead = char.Head.Overhead.Main

function BetterMathRandom(min, max)
	local v = 0
	repeat
		v = math.random(min, max)
		wait()
	until v ~= lastValue
	lastValue = v
	return v
end

function GetNewObjective()
	overhead.State.Text = "GETTING NEW TARGET..."
	local items = workspace:GetDescendants()
	local parts = {}
	for _, item in ipairs(items) do
		if item:IsA('BasePart') and item.Parent ~= workspace.PathVisualization then
			if notReacheable[item] == nil then
				table.insert(parts, item)
			end
		end
	end
	overhead.State.Text = "TARGET OBTAINED"
	return parts[BetterMathRandom(1, #parts)]
end

function FindEnemy()
	overhead.State.Text = "FINDING ENEMY..."
	local nearDist = 100
	local nearEnemy
	for _, player in ipairs(workspace.NPCs:GetChildren()) do
		if player.Team.Value ~= char.Team.Value then
			local succ, dist = pcall(function()
				return (hrp.Position-player.HumanoidRootPart.Position).Magnitude
			end)
			if succ and dist < nearDist then	
				nearDist = dist
				nearEnemy = player
			end
		end
	end
	if nearEnemy then
		overhead.State.Text = "FOUND ENEMY: "..nearEnemy.Name
	else
		overhead.State.Text = "COULDN'T FIND ENEMY"
	end
	return nearEnemy or false
end

char.Humanoid:GetPropertyChangedSignal("Sit"):Connect(function()
	repeat
		char.Humanoid.Jump = true
		wait()
	until char.Humanoid.Sit == false
end)

function DespawnTarget(target)
	framework.FinishedWaypoint(char, target)
end

function CreatePath(NPC, Objective)
	overhead.State.Text = "CREATING PATH TO: "..Objective.Name.."..."
	local path
	repeat
		path = pathServ.CreatePath(NPC, Objective)
		wait()
		if path == false then
			notReacheable[Objective] = true
			Objective = GetNewObjective()
		end
	until path ~= false and path ~= nil
	overhead.State.Text = "PATH CREATED!"
	return path
end

function ComputePath(Path)
	overhead.State.Text = "COMPUTING PATH..."
	local points = Path:GetWaypoints()
	local target = points[#points]
	framework.AddWaypoint(char, target.Position)
	local blocked = false
	Path.Blocked:Connect(function()
		overhead.State.Text = "PATH IS BLOCKED, ABORTING..."
		blocked = true
		framework.BlockedPath(char, target.Position)
	end)
	for _, way in ipairs(points) do
		overhead.State.Text = "MOVING TO WAYPOINT..."
		if blocked == true then
			break
		end
		char.Humanoid:MoveTo(way.Position)
		char.Humanoid.MoveToFinished:Wait()
	end
	framework.FinishedWaypoint(char, target.Position)
	overhead.State.Text = "OBJECTIVE REACHED"
	return true
end

overhead.NPCName.Text = char.Name
--repeat wait() until char.Team.Value ~= nil
overhead.NPCName.TextColor3 = char.Team.Value.TeamColor.Color
ComputePath(CreatePath(char, GetNewObjective()))
while wait() do
	local enemy = FindEnemy()
	if enemy then
		repeat
			ComputePath(CreatePath(char, enemy.HumanoidRootPart))
			wait()
			if not enemy:FindFirstChild("Humanoid") or enemy.Humanoid.Health <= 0 then
				break
			end
			if (hrp.Position-enemy.HumanoidRootPart.Position).Magnitude > 50 then
				overhead.State.Text = "ENEMY IS OUT OF REACH"
				break
			end
		until enemy.Humanoid.Health <= 1
	else
		ComputePath(CreatePath(char, GetNewObjective()))
	end
end