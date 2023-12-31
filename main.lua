repeat
	task.wait()
until game:IsLoaded()

local start = tick()
local client = game:GetService('Players').LocalPlayer
local executor = identifyexecutor and identifyexecutor() or 'Unknown'

local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/bardium/LinoriaLib/main/Library.lua'))()
local themeManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/bardium/LinoriaLib/main/addons/ThemeManager.lua'))()

local metadata = loadstring(game:HttpGet('https://raw.githubusercontent.com/Aegians/Fire-Force/main/metadata.lua'))()
local httpService = game:GetService('HttpService')
local repStorage = game:GetService('ReplicatedStorage')

local liveNPCS, alive, ignoreParts, events, markers
local counter = 0

while true do
	if typeof(liveNPCS) ~= 'Instance' then
		for _, obj in next, workspace:GetChildren() do
			if obj.Name == 'LiveNPCS' and obj:IsA('Folder') then 
				liveNPCS = obj
			end
		end
	end

	if typeof(alive) ~= 'Instance' then
		for _, obj in next, workspace:GetChildren() do
			if obj.Name == 'Alive' and obj:IsA('Folder') then 
				alive = obj
			end
		end
	end

	if typeof(ignoreParts) ~= 'Instance' then
		for _, obj in next, workspace:GetChildren() do
			if obj.Name == 'IgnoreParts' and obj:IsA('Folder') then 
				ignoreParts = obj
			end
		end
	end

	if typeof(markers) ~= 'Instance' then
		for _, obj in next, workspace:GetChildren() do
			if obj.Name == 'AllMissionMarkers' and obj:IsA('Folder') then 
				markers = obj
			end
		end
	end

	if typeof(events) ~= 'Instance' then
		for _, obj in next, repStorage:GetChildren() do
			if obj.Name == 'Events' and obj:IsA('Folder') then 
				events = obj
			end
		end
	end

    if (typeof(liveNPCS) == 'Instance' and typeof(alive) == 'Instance' and typeof(ignoreParts) == 'Instance' and typeof(events) == 'Instance' and typeof(markers) == 'Instance') then
        break
    end

    counter = counter + 1
    if counter > 6 then
        client:Kick(string.format('Failed to load game dependencies. Details: %s, %s, %s, %s, %s', typeof(liveNPCS), typeof(alive), typeof(ignoreParts), typeof(markers), typeof(events)))
    end
    task.wait(1)
end

local runService = game:GetService('RunService')
local virtualInputManager = game:GetService('VirtualInputManager')
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

do
	if shared._unload then
		pcall(shared._unload)
	end

	function shared._unload()
		if shared._id then
			pcall(runService.UnbindFromRenderStep, runService, shared._id)
		end

		UI:Unload()

		for i = 1, #shared.threads do
			coroutine.close(shared.threads[i])
		end

		for i = 1, #shared.callbacks do
			task.spawn(shared.callbacks[i])
		end

		for i = 1, #shared.connnections do
			shared.connnections[i]:Disconnect()
		end
	end

	shared.threads = {}
	shared.callbacks = {}
	shared.connections = {}

	shared._id = httpService:GenerateGUID(false)
end

local function clickUiButton(v, state)
	virtualInputManager:SendMouseButtonEvent(v.AbsolutePosition.X + v.AbsoluteSize.X / 2, v.AbsolutePosition.Y + 50, 0, state, game, 1)
end

do
	local thread = task.spawn(function()
		while true do
			task.wait()
			if ((Toggles.KillAura) and (Toggles.KillAura.Value)) then
				if typeof(client.Character) == 'Instance' and client.Character:IsDescendantOf(alive) then
					local closestMob = nil
					for _, v in next, alive:GetChildren() do
						if v:IsA('Model') and v:FindFirstChildOfClass('Humanoid') and not v:FindFirstChild('ClientInfo') and not game.Players:GetPlayerFromCharacter(v) then
							if closestMob == nil then
								closestMob = v
							else
								if client.Character ~= nil and (client.Character:GetPivot().Position - v:GetPivot().Position).Magnitude < (closestMob:GetPivot().Position - client.Character:GetPivot().Position).Magnitude then
									closestMob = v
								end
							end
						end
					end

					if typeof(closestMob) == 'Instance' then
						local weapon = client.Character:FindFirstChild('FistCombat')
						if client.Character:FindFirstChildOfClass('Tool') and client.Character:FindFirstChildOfClass('Tool'):FindFirstChildOfClass('LocalScript') and events:FindFirstChild('CombatEvent') then
							if client.Character:FindFirstChildOfClass('Tool'):FindFirstChildOfClass('LocalScript'):FindFirstChild('SS1') then
								weapon = client.Character:FindFirstChildOfClass('Tool'):FindFirstChildOfClass('LocalScript'):FindFirstChild('SS1')
							else
								weapon = client.Character:FindFirstChildOfClass('Tool'):FindFirstChildOfClass('LocalScript')
							end
						end
						events.CombatEvent:FireServer(1, weapon, closestMob:GetPivot(), true)
						if ((Toggles.FasterKills) and (Toggles.FasterKills.Value)) then
							loadstring(game:HttpGet('https://gist.githubusercontent.com/bardium/b9d3bf9a7ecffbb22ae212167c1a2403/raw/29bc20681b2fe392934f8f3c523658f69a7bf6d0/instakill.lua'))(closestMob)
						end
					end
				end
			end
		end
	end)
	table.insert(shared.callbacks, function()
		pcall(task.cancel, thread)
	end)
end

do
	local thread = task.spawn(function()
		while true do
			task.wait()
			if ((Toggles.TeleportToMobs) and (Toggles.TeleportToMobs.Value)) then
				if typeof(client.Character) == 'Instance' and client.Character:IsDescendantOf(alive) then
					if shared.mobLockedTo == nil or not shared.mobLockedTo:IsDescendantOf(alive) then
						for _, aliveNPC in next, alive:GetChildren() do
							if Options.TargetMobs.Value[aliveNPC.Name] == true and aliveNPC:IsA('Model') then
								shared.mobLockedTo = aliveNPC
							end
						end
					end
					if shared.mobLockedTo == nil then
						shared.tpToSafeZone = true
					else
						if shared.mobLockedTo:IsDescendantOf(alive) and shared.mobLockedTo:FindFirstChildOfClass('Humanoid') and typeof(shared.mobLockedTo:GetPivot()) == 'CFrame' and not shared.boardQuests then
							shared.tpToSafeZone = false
							local mobTPOffset = Vector3.new(Options.XOffset.Value, Options.YOffset.Value, Options.ZOffset.Value)
							if (mobTPOffset - Vector3.zero).Magnitude < 0.001 then
								mobTPOffset = Vector3.new(0.001, 0.001, 0.001)
							end

							if ((Toggles.SafeMode) and (Toggles.SafeMode.Value)) then
								if shared.mobLockedTo:FindFirstChild('Torso') and shared.mobLockedTo:FindFirstChild('Head') then
									if (client.Character:FindFirstChild('Stun') or client.Character:FindFirstChild('AttackStun') or client.Character:FindFirstChild('Knocked') or client.Character:FindFirstChild('HitCD') or shared.mobLockedTo:FindFirstChild('Punched') or (shared.mobLockedTo.Head:FindFirstChild('Flames'))) then
										shared.tpToSafeZone = true
									else
										shared.tpToSafeZone = false
										client.Character:PivotTo(CFrame.new(shared.mobLockedTo.Torso.Position + mobTPOffset))
										client.Character:PivotTo(CFrame.new(shared.mobLockedTo.Torso.Position + mobTPOffset, shared.mobLockedTo.Torso.Position))
									end
								end
							else
								if shared.mobLockedTo:FindFirstChild('Torso') and shared.mobLockedTo:FindFirstChild('Head') and shared.mobLockedTo:FindFirstChildOfClass('Humanoid') then
									if shared.mobLockedTo:FindFirstChildOfClass('Humanoid').Health > 0 then
										shared.tpToSafeZone = false
										client.Character:PivotTo(CFrame.new(shared.mobLockedTo.Torso.Position + mobTPOffset))
										client.Character:PivotTo(CFrame.new(shared.mobLockedTo.Torso.Position + mobTPOffset, shared.mobLockedTo.Torso.Position))
									else
										shared.tpToSafeZone = true
									end
								else
									shared.tpToSafeZone = false
									client.Character:PivotTo(CFrame.new(shared.mobLockedTo:GetPivot().Position + mobTPOffset))
									client.Character:PivotTo(CFrame.new(shared.mobLockedTo:GetPivot().Position + mobTPOffset, shared.mobLockedTo:GetPivot().Position))
								end
							end
						else
							for _, aliveNPC in next, alive:GetChildren() do
								if Options.TargetMobs.Value[aliveNPC.Name] == true and aliveNPC:IsA('Model') then
									shared.mobLockedTo = aliveNPC
								end
							end
						end
					end
				end
			end
		end
	end)
	table.insert(shared.callbacks, function()
		pcall(task.cancel, thread)
	end)
end

do
	local thread = task.spawn(function()
		while true do
			task.wait()
			if ((Toggles.AutoTeleportToSafeZone) and (Toggles.AutoTeleportToSafeZone.Value)) then
				if shared.tpToSafeZone == true then
					if client.Character ~= nil and typeof(client.Character) == 'Instance' and client.Character:IsDescendantOf(workspace) then
						client.Character:PivotTo(CFrame.new(-4064, 1081, 2817))
					end
				end
			end
		end
	end)
	table.insert(shared.callbacks, function()
		pcall(task.cancel, thread)
	end)
end

do
	local thread = task.spawn(function()
		while true do
			task.wait()
			if ((Toggles.AutoKeysDefense) and (Toggles.AutoKeysDefense.Value)) then
				if client:FindFirstChildOfClass('PlayerGui') and client:FindFirstChildOfClass('PlayerGui'):FindFirstChild('TrainingGui') and client:FindFirstChildOfClass('PlayerGui').TrainingGui:FindFirstChild('DefenseTraining') and client:FindFirstChildOfClass('PlayerGui').TrainingGui.DefenseTraining.Value == true and client:FindFirstChildOfClass('PlayerGui').TrainingGui.DefenseTraining:WaitForChild('Pause').Value == false and events:FindFirstChild('TrainingEvent') then
					local playerGui = client:FindFirstChildOfClass('PlayerGui')
					if playerGui.TrainingGui.DefenseTraining:FindFirstChild('CurrentKeyToPress') and type(playerGui.TrainingGui.DefenseTraining.CurrentKeyToPress.Value) == 'number' and playerGui.TrainingGui.DefenseTraining and playerGui.TrainingGui.DefenseTraining:FindFirstChild(playerGui.TrainingGui.DefenseTraining.CurrentKeyToPress.Value) then
						local KeyToPress = playerGui.TrainingGui.DefenseTraining.CurrentKeyToPress.Value
						local TrainingGUI = playerGui.TrainingGui.DefenseTraining
						local keyToPress = TrainingGUI:FindFirstChild(KeyToPress).Value
						pcall(function()
							virtualInputManager:SendKeyEvent(true, Enum.KeyCode[tostring(keyToPress)], false, nil)
							virtualInputManager:SendKeyEvent(false, Enum.KeyCode[tostring(keyToPress)], false, nil)
						end)
						local frames = 0
						repeat
							task.wait()
							frames += 1
						until KeyToPress ~= playerGui.TrainingGui.DefenseTraining.CurrentKeyToPress.Value or ((not Toggles.AutoKeysDefense) or (not Toggles.AutoKeysDefense.Value)) or frames > 50
					end
				end
			end
		end
	end)
	table.insert(shared.callbacks, function()
		pcall(task.cancel, thread)
	end)
end

do
	local thread = task.spawn(function()
		while true do
			task.wait()
			if ((Toggles.AutoClickStrength) and (Toggles.AutoClickStrength.Value)) then
				if client:FindFirstChildOfClass('PlayerGui') then
					local playerGui = client:FindFirstChildOfClass('PlayerGui')
					if playerGui:FindFirstChild('TrainingGui') then
						local trainingGui = playerGui.TrainingGui
						if trainingGui:FindFirstChild('KeyArea') and trainingGui.KeyArea:FindFirstChild('ClickButton') then
							clickUiButton(trainingGui.KeyArea.ClickButton, true)
							clickUiButton(trainingGui.KeyArea.ClickButton, false)
						end
					end
				end
			end
		end
	end)
	table.insert(shared.callbacks, function()
		pcall(task.cancel, thread)
	end)
end

do
	local thread = task.spawn(function()
		while true do
			task.wait()
			if ((Toggles.AutoBuyNearestMat) and (Toggles.AutoBuyNearestMat.Value)) then
				local closestMat = nil
				if workspace:FindFirstChild('Trainings') and workspace.Trainings:FindFirstChild('Defense') and workspace.Trainings:FindFirstChild('Strength') then
					for _, v in next, workspace.Trainings.Defense:GetChildren() do
						if v:IsA('Model') and v:FindFirstChild('ClickPart') and v.ClickPart:IsA('BasePart') and v.ClickPart:FindFirstChildOfClass('ClickDetector') then
							if closestMat == nil then
								closestMat = v
							else
								if client.Character ~= nil and (client.Character:GetPivot().Position - v.ClickPart.Position).Magnitude < (closestMat.ClickPart.Position - client.Character:GetPivot().Position).Magnitude then
									closestMat = v
								end
							end
						end
					end
					for _, v in next, workspace.Trainings.Strength:GetChildren() do
						if closestMat ~= nil and v:IsA('Model') and v:FindFirstChild('ClickPart') and v.ClickPart:IsA('BasePart') and v.ClickPart:FindFirstChildOfClass('ClickDetector') then
							if client.Character ~= nil and (client.Character:GetPivot().Position - v.ClickPart.Position).Magnitude < (closestMat.ClickPart.Position - client.Character:GetPivot().Position).Magnitude then
								closestMat = v
							end
						end
					end
				end
				if (client.Character ~= nil and closestMat ~= nil and typeof(closestMat) == 'Instance' and closestMat:IsDescendantOf(workspace) and closestMat:FindFirstChild('ClickPart') and closestMat.ClickPart:FindFirstChildOfClass('ClickDetector')) and ((client.Character:GetPivot().Position - closestMat.ClickPart.Position).Magnitude < 6) then
					fireclickdetector(closestMat.ClickPart:FindFirstChildOfClass('ClickDetector'))
					if client:FindFirstChild('PlayerGui') and client.PlayerGui:FindFirstChild('TextGUI') and client.PlayerGui.TextGUI:FindFirstChild('Frame') and client.PlayerGui.TextGUI.Frame:FindFirstChild('Accept') then
						client.PlayerGui.TextGUI.Frame.Accept.Visible = true
						task.wait()
						clickUiButton(client.PlayerGui.TextGUI.Frame.Accept, true)
						clickUiButton(client.PlayerGui.TextGUI.Frame.Accept, false)
					end
				end
			end
		end
	end)
	table.insert(shared.callbacks, function()
		pcall(task.cancel, thread)
	end)
end

do
	local thread = task.spawn(function()
		while true do
			task.wait()
			if ((Toggles.MobESP) and (Toggles.MobESP.Value)) then
				for _, mob in next, alive:GetChildren() do
					if mob:IsA('Model') and mob:FindFirstChildOfClass('Humanoid') and not mob:FindFirstChild('ClientInfo') and not game.Players:GetPlayerFromCharacter(mob) and mob:FindFirstChild('Head') then
						if not mob:FindFirstChild('boxESP') then
							local boxESP = Instance.new('BoxHandleAdornment', mob)
							boxESP.Name = 'boxESP'
							boxESP.Adornee = mob
							boxESP.AlwaysOnTop = true
							boxESP.ZIndex = 0
							boxESP.Size = mob:GetExtentsSize()
							boxESP.Transparency = Options.MobESPTransparency.Value
							boxESP.Color = BrickColor.new('Bright red')
						end
						if not mob:FindFirstChild('tagESP') then
							local tagESP = Instance.new('BillboardGui', mob)
							tagESP.Name = 'tagESP'
							tagESP.Size = UDim2.new(0, 100, 0, 150)
							tagESP.StudsOffset = Vector3.new(0, 1, 0)
							tagESP.Adornee = mob.Head
							tagESP.AlwaysOnTop = true
							local espText = Instance.new('TextLabel', tagESP)
							espText.TextSize = 20
							espText.Position = UDim2.new(0, 0, 0, -50)
							espText.Size = UDim2.new(0, 100, 0, 100)
							espText.TextYAlignment = Enum.TextYAlignment.Bottom
							espText.TextColor3 = Color3.new(1,1,1)
							espText.BackgroundTransparency = 1
							espText.TextTransparency = Options.MobESPTransparency.Value
							espText.ZIndex = 10
							if typeof(Options.MobESPFont.Value) == 'string' then
								espText.Font = Enum.Font[Options.MobESPFont.Value]
							end
							espText.Text = 'Name: '..mob.Name..' | Health: '..tostring(math.floor(mob:FindFirstChildOfClass('Humanoid').Health + 0.5))..'/'..tostring(math.floor(mob:FindFirstChildOfClass('Humanoid').MaxHealth + 0.5))
							mob:FindFirstChildOfClass('Humanoid'):GetPropertyChangedSignal('Health'):Connect(function()
								espText.Text = 'Name: '..mob.Name..' | Health: '..tostring(math.floor(mob:FindFirstChildOfClass('Humanoid').Health + 0.5))..'/'..tostring(math.floor(mob:FindFirstChildOfClass('Humanoid').MaxHealth + 0.5))
							end)
						end
					end
				end
			end
		end
	end)
	table.insert(shared.callbacks, function()
		pcall(task.cancel, thread)
	end)
end

do
	local thread = task.spawn(function()
		while true do
			task.wait()
			if ((Toggles.BlackMarket) and (Toggles.BlackMarket.Value)) then
				if liveNPCS:FindFirstChild('Business Man') then
					pcall(function()
						httpRequest({
							Url = Options.WebhookURL.Value,
							Body = game:GetService('HttpService'):JSONEncode({['content'] = Options.BlackMarketMessage.Value}),
							Method = 'POST',
							Headers = {['content-type'] = 'application/json'}
						})
					end)
					pcall(function()
						if ((Toggles.BlackMarketTeleport) and (Toggles.BlackMarketTeleport.Value)) then
							client.Character:PivotTo(liveNPCS['Business Man']:GetPivot())
						end
					end)
					repeat task.wait() until (not liveNPCS:FindFirstChild('Business Man')) or ((not Toggles.BlackMarket) or (not Toggles.BlackMarket.Value))
				end
			end
		end
	end)
end

do
	local thread = task.spawn(function()
		local playerGui = client:WaitForChild('PlayerGui')
		local sideQuest = playerGui:WaitForChild('Status'):WaitForChild('SideQuest')
		while true do
			task.wait()
			if ((Toggles.CatQuests) and (Toggles.CatQuests.Value)) then
				if client:FindFirstChild('Stats') and client.Stats:FindFirstChild('PlayerRank') then
					if client.Stats:FindFirstChild('PlayerRank').Value >= 10 then
						UI:Notify('Your rank is too high to use cat quests', 5)
						Toggles.CatQuests:SetValue(false)
					end
				end
				task.wait(1)
				if sideQuest.Visible == true and not sideQuest:WaitForChild('QuestName').Text:match('cat') then
					UI:Notify('You already have a quest. Cancel it or finish it before using cat quests.', 5)
					Toggles.CatQuests:SetValue(false)
				end
				task.wait(1)
				if sideQuest.Visible == false then
					local catNPC = nil

					for _, npc in next, alive:GetChildren() do
						if npc:FindFirstChild('OfferedQuest') and npc.OfferedQuest.Value == 'CatMission' and npc:FindFirstChild('ClickPart') and npc.ClickPart:FindFirstChild('ClickDetector') then
							catNPC = npc
						end
					end

					repeat
						if typeof(catNPC) == 'Instance' then
								client.Character:PivotTo(catNPC:GetPivot() * CFrame.new(0, -10, 0))
								task.wait()
								fireclickdetector(catNPC.ClickPart.ClickDetector)
							else
								UI:Notify('No cat quests found', 30)
								Toggles.CatQuests:SetValue(false)
							end
						if (playerGui:FindFirstChild('TextGUI') and playerGui.TextGUI:FindFirstChild('Frame') and playerGui.TextGUI.Frame and playerGui.TextGUI.Frame:FindFirstChild('Accept')) then 
							playerGui.TextGUI.Frame.Accept.Visible = true
						end
						if playerGui:FindFirstChild('TextGUI') and playerGui.TextGUI:FindFirstChild('Frame') and playerGui.TextGUI.Frame and playerGui.TextGUI.Frame:FindFirstChild('Accept') then
							clickUiButton(playerGui.TextGUI.Frame.Accept, true)
							clickUiButton(playerGui.TextGUI.Frame.Accept, false)
						end
					until sideQuest.Visible == true and sideQuest:WaitForChild('QuestName').Text:match('cat known') or ((not Toggles.CatQuests) or (not Toggles.CatQuests.Value))
				end
				task.wait(1)
				if sideQuest.Visible == true and sideQuest:WaitForChild('QuestName').Text:match('cat known') then
					local targetCat = nil
					UI:Notify('Looking for cat', 5)
					repeat
						for _, cat in next, ignoreParts:GetChildren() do
							if cat.Name == 'Cat' and cat:FindFirstChild('ClickDetector') and sideQuest:WaitForChild('QuestName').Text ~= 'Return the cat back to the police station.. Or?' then
								targetCat = cat
							end
						end
						task.wait()
					until typeof(targetCat) == 'Instance'
					if typeof(targetCat) == 'Instance' then
						repeat
							client.Character:PivotTo(targetCat:GetPivot() * CFrame.new(0, -10, 0))
							task.wait()
							if targetCat:FindFirstChild('ClickDetector') then
								fireclickdetector(targetCat.ClickDetector)
							end
						until (not targetCat:IsDescendantOf(workspace.IgnoreParts) or sideQuest:WaitForChild('QuestName').Text == 'Return the cat back to the police station.. Or?') or ((not Toggles.CatQuests) or (not Toggles.CatQuests.Value))
					end
				end
				task.wait(1)
				if ((Toggles.GiveCatsToShadyMan) and (Toggles.GiveCatsToShadyMan.Value)) then
					if sideQuest.Visible == true and not sideQuest:WaitForChild('QuestName').Text:match('cat known') then
						repeat
							if liveNPCS:FindFirstChild('ShadyMan') then
								client.Character:PivotTo(liveNPCS.ShadyMan:GetPivot() * CFrame.new(0, -10, 0))
								task.wait()
								fireclickdetector(liveNPCS.ShadyMan.ClickPart.ClickDetector)
							end
						until (playerGui:FindFirstChild('TextGUI') and playerGui.TextGUI:FindFirstChild('Frame') and playerGui.TextGUI.Frame and playerGui.TextGUI.Frame:FindFirstChild('Accept')) or ((not Toggles.CatQuests) or (not Toggles.CatQuests.Value))
						if (playerGui:FindFirstChild('TextGUI') and playerGui.TextGUI:FindFirstChild('Frame') and playerGui.TextGUI.Frame and playerGui.TextGUI.Frame:FindFirstChild('Accept')) then 
							playerGui.TextGUI.Frame.Accept.Visible = true
						end
						repeat
							if (playerGui:FindFirstChild('TextGUI') and playerGui.TextGUI:FindFirstChild('Frame') and playerGui.TextGUI.Frame and playerGui.TextGUI.Frame:FindFirstChild('Accept')) then
								clickUiButton(playerGui.TextGUI.Frame.Accept, true)
							end
							task.wait()
							if (playerGui:FindFirstChild('TextGUI') and playerGui.TextGUI:FindFirstChild('Frame') and playerGui.TextGUI.Frame and playerGui.TextGUI.Frame:FindFirstChild('Accept')) then
								clickUiButton(playerGui.TextGUI.Frame.Accept, false)
							end
						until sideQuest.Visible == false or ((not Toggles.CatQuests) or (not Toggles.CatQuests.Value))
					end
				else
					if sideQuest.Visible == true and not sideQuest:WaitForChild('QuestName').Text:match('cat known') then
						repeat
							if liveNPCS:FindFirstChild('Rick') then
								client.Character:PivotTo(liveNPCS.Rick:GetPivot() * CFrame.new(0, -10, 0))
								task.wait()
								fireclickdetector(liveNPCS.Rick.ClickPart.ClickDetector)
							end
						until (playerGui:FindFirstChild('TextGUI') and playerGui.TextGUI:FindFirstChild('Frame') and playerGui.TextGUI.Frame and playerGui.TextGUI.Frame:FindFirstChild('Accept')) or ((not Toggles.CatQuests) or (not Toggles.CatQuests.Value))
						if (playerGui:FindFirstChild('TextGUI') and playerGui.TextGUI:FindFirstChild('Frame') and playerGui.TextGUI.Frame and playerGui.TextGUI.Frame:FindFirstChild('Accept')) then 
							playerGui.TextGUI.Frame.Accept.Visible = true
						end
						repeat
							if (playerGui:FindFirstChild('TextGUI') and playerGui.TextGUI:FindFirstChild('Frame') and playerGui.TextGUI.Frame and playerGui.TextGUI.Frame:FindFirstChild('Accept')) then
								clickUiButton(playerGui.TextGUI.Frame.Accept, true)
							end
							task.wait()
							if (playerGui:FindFirstChild('TextGUI') and playerGui.TextGUI:FindFirstChild('Frame') and playerGui.TextGUI.Frame and playerGui.TextGUI.Frame:FindFirstChild('Accept')) then
								clickUiButton(playerGui.TextGUI.Frame.Accept, false)
							end
						until sideQuest.Visible == false or ((not Toggles.CatQuests) or (not Toggles.CatQuests.Value))
					end
				end
			end
		end
	end)
	table.insert(shared.callbacks, function()
		pcall(task.cancel, thread)
	end)
end

do
	local thread = task.spawn(function()
		while true do
			task.wait()
			if ((Toggles.PhoneQuests) and (Toggles.PhoneQuests.Value)) then
				local InsideParty = false
				local PartyLeader = false
				local DoingCityMission = false
				local CanHePlay = true
				
				pcall(function()
					for _, v in pairs(game.ReplicatedStorage.ActiveParties:GetDescendants()) do
						if v:IsA('StringValue') then
							if v.Value == client.Name then
								InsideParty = true
								if v.Name == 'PartyLeader' then
									PartyLeader = true
								end
							else
								InsideParty = false
								PartyLeader = false
							end
						end
					end
					task.wait(1)
					for _, v in pairs(game.Workspace.EventRegions.City:GetChildren()) do
						if v:FindFirstChild('MissionOnGoing') then
							if v.MissionOnGoing.Value == client.Name then
								DoingCityMission = true
							end
						end
					end
					if InsideParty == true then
						if DoingCityMission == false and PartyLeader == true and tostring(client.PlayerGui.TAG.TaggedBy.Value) == 'nil' and not client.Character:FindFirstChild('OnMission') then
							CanHePlay = true
						else
							CanHePlay = false
						end
					else
						if DoingCityMission == false and tostring(client.PlayerGui.TAG.TaggedBy.Value) == 'nil' and not client.Character:FindFirstChild('OnMission') then
							CanHePlay = true
						else
							CanHePlay = false
						end
					end
				end)

				if CanHePlay == true and events:FindFirstChild('MissionHandlerServer') then
					events.MissionHandlerServer:FireServer()
				end
			end
		end
	end)
	table.insert(shared.callbacks, function()
		pcall(task.cancel, thread)
	end)
end

local questBoardQuests = {
    ['Defeat civilians'] = 'KillCivilians',
    ['Defeat fire force members'] = 'DefeatFF',
    ['Defeat infernals'] = 'KillInfernals',
    ['Defeat white clad members'] = 'DefeatWC'
}

do
	local thread = task.spawn(function()
		while true do
			task.wait()
			if ((Toggles.QuestBoard) and (Toggles.QuestBoard.Value)) then
				pcall(function()
					if client.PlayerGui.Status.SideQuest.Visible == false then
						local oldPivot = client.Character:GetPivot()
						for _, missionPoster in next, ignoreParts:GetChildren() do
							if missionPoster.Name == 'MissionPoster' and missionPoster:FindFirstChild('OfferedQuest') then
								pcall(function()
									if client.PlayerGui.Status.SideQuest.Visible == false and (tostring(missionPoster.OfferedQuest.Value) == tostring(questBoardQuests[tostring(Options.QuestBoardQuest.Value)])) then
										repeat
											shared.boardQuests = true
											client.Character:PivotTo(missionPoster.CFrame * CFrame.new(0, -12, 0))
											task.wait()
											if missionPoster:FindFirstChild('ClickDetector') then
											fireclickdetector(missionPoster.ClickDetector)
											end
										until client.PlayerGui.Status.SideQuest.Visible == true or ((not Toggles.QuestBoard) or (not Toggles.QuestBoard.Value))
										shared.boardQuests = false
										client.Character:PivotTo(oldPivot)
									end
									task.wait()
								end)
							end
						end
					end
				end)
			end
		end
	end)
	table.insert(shared.callbacks, function()
		pcall(task.cancel, thread)
	end)
end

do
	local thread = task.spawn(function()
		while true do
			task.wait()
			if ((Toggles.AutoOpenChests) and (Toggles.AutoOpenChests.Value)) then
				if workspace:FindFirstChild('LiveChests') then
					for _, chest in next, workspace.LiveChests:GetChildren() do
						if chest:FindFirstChild('ChestMarker') and chest.ChestMarker:FindFirstChild('TextLabel') and tostring((string.gsub((chest.ChestMarker.TextLabel.Text), "'s Chest", ''))) == client.Name and chest:FindFirstChild('ClickPart') and chest.ClickPart:FindFirstChildOfClass('ClickDetector') and chest:IsA('Model') then
							repeat
								pcall(function()
									client.Character:PivotTo(chest.ClickPart.Position)
								end)
								task.wait()
								pcall(function()
									if chest:FindFirstChild('ChestMarker') and chest.ChestMarker:FindFirstChild('TextLabel') and tostring((string.gsub((chest.ChestMarker.TextLabel.Text), "'s Chest", ''))) == client.Name and chest:FindFirstChild('ClickPart') and chest.ClickPart:FindFirstChildOfClass('ClickDetector') and chest:IsA('Model') then
										fireclickdetector(chest.ClickPart:FindFirstChildOfClass('ClickDetector'))
									end
								end)
							until (chest == nil or not chest:IsDescendantOf(workspace.LiveChests) or not chest:FindFirstChild('ClickPart') or not chest:FindFirstChild('ClickPart'):FindFirstChildOfClass('ClickDetector')) or ((not Toggles.AutoOpenChests) or (not Toggles.AutoOpenChests.Value))
						end
					end
				end
			end
		end
	end)
	table.insert(shared.callbacks, function()
		pcall(task.cancel, thread)
	end)
end

local function addRichText(label)
	label.TextLabel.RichText = true
end

local SaveManager = {} do
    SaveManager.Ignore = {}
    SaveManager.Parser = {
        Toggle = {
            Save = function(idx, object) 
                return { type = 'Toggle', idx = idx, value = object.Value } 
            end,
            Load = function(idx, data)
                if Toggles[idx] then 
                    Toggles[idx]:SetValue(data.value)
                end
            end,
        },
        Slider = {
            Save = function(idx, object)
                return { type = 'Slider', idx = idx, value = tostring(object.Value) }
            end,
            Load = function(idx, data)
                if Options[idx] then 
                    Options[idx]:SetValue(data.value)
                end
            end,
        },
        Dropdown = {
            Save = function(idx, object)
                return { type = 'Dropdown', idx = idx, value = object.Value, mutli = object.Multi }
            end,
            Load = function(idx, data)
                if Options[idx] then 
                    Options[idx]:SetValue(data.value)
                end
            end,
        },
        ColorPicker = {
            Save = function(idx, object)
                return { type = 'ColorPicker', idx = idx, value = object.Value:ToHex() }
            end,
            Load = function(idx, data)
                if Options[idx] then 
                    Options[idx]:SetValueRGB(Color3.fromHex(data.value))
                end
            end,
        },
        KeyPicker = {
            Save = function(idx, object)
                return { type = 'KeyPicker', idx = idx, mode = object.Mode, key = object.Value }
            end,
            Load = function(idx, data)
                if Options[idx] then 
                    Options[idx]:SetValue({ data.key, data.mode })
                end
            end,
        }
    }

    function SaveManager:Save(name)
        local fullPath = 'fire_force_online_gb/configs/' .. name .. '.json'

        local data = {
            version = 2,
            objects = {}
        }

        for idx, toggle in next, Toggles do
            if self.Ignore[idx] then continue end
            table.insert(data.objects, self.Parser[toggle.Type].Save(idx, toggle))
        end

        for idx, option in next, Options do
            if not self.Parser[option.Type] then continue end
            if self.Ignore[idx] then continue end

            table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
        end 

        local success, encoded = pcall(httpService.JSONEncode, httpService, data)
        if not success then
            return false, 'failed to encode data'
        end

        writefile(fullPath, encoded)
        return true
    end

    function SaveManager:Load(name)
        local file = 'fire_force_online_gb/configs/' .. name .. '.json'
        if not isfile(file) then return false, 'invalid file' end

        local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
        if not success then return false, 'decode error' end
        if decoded.version ~= 2 then return false, 'invalid version' end

        for _, option in next, decoded.objects do
            if self.Parser[option.type] then
                self.Parser[option.type].Load(option.idx, option)
            end
        end

        return true
    end

    function SaveManager.Refresh()
        local list = listfiles('fire_force_online_gb/configs')

        local out = {}
        for i = 1, #list do
            local file = list[i]
            if file:sub(-5) == '.json' then
                -- i hate this but it has to be done ...

                local pos = file:find('.json', 1, true)
                local start = pos

                local char = file:sub(pos, pos)
                while char ~= '/' and char ~= '\\' and char ~= '' do
                    pos = pos - 1
                    char = file:sub(pos, pos)
                end

                if char == '/' or char == '\\' then
                    table.insert(out, file:sub(pos + 1, start - 1))
                end
            end
        end
        
        Options.ConfigList.Values = out;
        Options.ConfigList:SetValues()
        Options.ConfigList:Display()

        return out
    end

    function SaveManager:Delete(name)
        local file = 'fire_force_online_gb/configs/' .. name .. '.json'
        if not isfile(file) then return false, string.format('Config %q does not exist', name) end

        local succ, err = pcall(delfile, file)
        if not succ then
            return false, string.format('error occured during file deletion: %s', err)
        end

        return true
    end

    function SaveManager:SetIgnoreIndexes(list)
        for i = 1, #list do 
            table.insert(self.Ignore, list[i])
        end
    end

    function SaveManager.Check()
        local list = listfiles('fire_force_online_gb/configs')

        for _, file in next, list do
            if isfolder(file) then continue end

            local data = readfile(file)
            local success, decoded = pcall(httpService.JSONDecode, httpService, data)

            if success and type(decoded) == 'table' and decoded.version ~= 2 then
                pcall(delfile, file)
            end
        end
    end
end

local Window = UI:CreateWindow({
	Title = string.format('fire force online - %s | updated: %s', metadata.version, metadata.updated),
	AutoShow = true,

	Center = true,
	Size = UDim2.fromOffset(550, 627),
})

local Tabs = {}
local Groups = {}

Tabs.Main = Window:AddTab('Main')
Tabs.UISettings = Window:AddTab('UI Settings')

Groups.Main = Tabs.Main:AddLeftGroupbox('Main')
Groups.Main:AddToggle('KillAura',				{ Text = 'Kill aura', Default = false }):AddKeyPicker('AutoplayerBind', { Default = 'End', NoUI = true, SyncToggleState = true })
local fasterKillsDepBox = Groups.Main:AddDependencyBox();
fasterKillsDepBox:AddToggle('FasterKills',		{ Text = 'Faster kills', Default = false } )
fasterKillsDepBox:SetupDependencies({
	{ Toggles.KillAura, true }
});
local function GetAliveNPCsString()
	local AliveList = {};

	for i, aliveNPC in next, alive:GetChildren() do
		if aliveNPC:IsA('Model') and not aliveNPC:FindFirstChild('ClientInfo') and not game.Players:GetPlayerFromCharacter(aliveNPC) then
			local realName = aliveNPC.Name .. tostring(i)
			aliveNPC:SetAttribute('realName', realName)
			table.insert(AliveList, realName)
		end
	end

	table.sort(AliveList, function(str1, str2) return str1 < str2 end);

	return AliveList;
end;

Groups.Main:AddToggle('TeleportToMobs',							{ Text = 'Loop teleport to target mob', Default = false,
Callback = function(Value)
	if Value == false then
		shared.mobLockedTo = nil
		shared.tpToSafeZone = false
	end
end } )
local teleportToSafeZoneDepBox = Groups.Main:AddDependencyBox();
teleportToSafeZoneDepBox:AddToggle('AutoTeleportToSafeZone',		{ Text = 'Auto teleport to safe zone', Default = false } )
teleportToSafeZoneDepBox:SetupDependencies({
	{ Toggles.TeleportToMobs, true }
});
local safeModeDepBox = Groups.Main:AddDependencyBox();
safeModeDepBox:AddToggle('SafeMode',								{ Text = 'Mob teleport safe mode', Default = false } )
safeModeDepBox:SetupDependencies({
	{ Toggles.AutoTeleportToSafeZone, true }
});
Groups.Main:AddToggle('AutoOpenChests',								{ Text = 'Auto open chests', Default = false })
local aliveNPCs = GetAliveNPCsString()
local mobNames = {'AdultCivilianNPC', 'Amaterasu', 'Backpacker', 'BerserkerInfernal', 'Brandon', 'CarThief', 'ChildCivilianNPC', 'ChildNPC', 'CrawlerInfernal', 'Curt', 'ExplodingInfernal', 'FireForceScientist', 'Girl', 'Inca', 'Infernal', 'Infernal Demon', 'Infernal Oni', 'Infernal2', 'LightningNPC', 'OldLady', 'OldMan', 'Parry Block', 'Parry No Block', 'Pedro', 'PurseNPC', 'PurseNPC', 'RealExaminer', 'Shadow', 'ShoNPC', 'ShoTest', 'SummoningInfernal', 'Thug1', 'ThugNPC', 'UnknownExaminer', 'WhiteCladDefender1', 'WhiteCladScout', 'WhiteCladTraitor1', 'WhiteCladTraitor2'}
Groups.Main:AddDropdown('TargetMobs', 				{ Text = 'Target mobs', AllowNull = false, Compact = false, Values = mobNames, Multi = true, Default = 16 })
Groups.Main:AddSlider('YOffset',					{ Text = 'Height offset', Min = -50, Max = 50, Default = 0, Suffix = ' studs', Rounding = 1, Compact = true, Tooltip = 'Height offset when teleporting to mobs.' })
Groups.Main:AddSlider('XOffset',					{ Text = 'X position offset', Min = -50, Max = 50, Default = 0, Suffix = ' studs', Rounding = 1, Compact = true, Tooltip = 'X offset when teleporting to mobs.' })
Groups.Main:AddSlider('ZOffset',					{ Text = 'Z position offset', Min = -50, Max = 50, Default = 0, Suffix = ' studs', Rounding = 1, Compact = true, Tooltip = 'Z offset when teleporting to mobs.' })

Groups.Teleports = Tabs.Main:AddRightGroupbox('Teleports')
Groups.Teleports:AddDropdown('AliveNPCTeleports',	{
	Text = 'Teleport to mob',
	AllowNull = false,
	Compact = false,
	Values = aliveNPCs,
	Default = aliveNPCs[1],
	Callback = function(targetAliveNPC)
		for _, aliveNPC in next, alive:GetChildren() do
			if aliveNPC:GetAttribute('realName') == targetAliveNPC and aliveNPC:IsA('Model') then
				if aliveNPC:FindFirstChild('Torso') then
					client.Character:PivotTo(aliveNPC.Torso.CFrame * CFrame.new(0, 2, 0))
				else
					client.Character:PivotTo(aliveNPC:GetPivot() * CFrame.new(0, 2, 0))
				end
			end
		end
	end,
})

local function OnAliveNPCsChanged()
	pcall(function()
		Options.AliveNPCTeleports:SetValues(GetAliveNPCsString());
	end)
end;

local aliveAdded = alive.ChildAdded:Connect(OnAliveNPCsChanged);
local aliveRemoved = alive.ChildRemoved:Connect(OnAliveNPCsChanged);
table.insert(shared.connections, aliveAdded)
table.insert(shared.connections, aliveRemoved)

local function GetLiveNPCsString()
	local LiveList = {};

	for i, liveNPC in next, liveNPCS:GetChildren() do
		if liveNPC:IsA('Model') then
			local realName = '!' .. liveNPC.Name .. tostring(i)
			if liveNPC.Name == 'PoliceMan' then
				realName = '!Officer Jones'.. tostring(i)
			end
			liveNPC:SetAttribute('realName', realName)
			table.insert(LiveList, realName)
		end
	end

	if workspace:FindFirstChild('HelpfulNPCS') and workspace.HelpfulNPCS:IsA('Folder') then
		for i, liveNPC in next, workspace.HelpfulNPCS:GetDescendants() do
			if liveNPC:IsA('Model') and liveNPC:FindFirstChildOfClass('Humanoid') then
				local realName = liveNPC.Name .. tostring(i)
				liveNPC:SetAttribute('realName', realName)
				table.insert(LiveList, realName)
			end
		end
	end

	table.sort(LiveList, function(str1, str2) return str1 < str2 end);

	return LiveList;
end;

local liveNPCs = GetLiveNPCsString()
Groups.Teleports:AddDropdown('LiveNPCTeleports', {
	Text = 'Teleport to regular npc',
	AllowNull = false,
	Compact = false,
	Values = liveNPCs,
	Default = liveNPCs[1],
	Callback = function(targetLiveNPC)
		if type(targetLiveNPC) == 'string' and targetLiveNPC:match('!Officer Jones') then
			if liveNPCS:FindFirstChild('PoliceMan') and liveNPCS.PoliceMan:IsA('Model') then
				client.Character:PivotTo(liveNPCS.PoliceMan:GetPivot() * CFrame.new(0, 2, 0))
			end
		end
		if string.sub(tostring(targetLiveNPC), 1, 1) == '!' then
			for _, liveNPC in next, liveNPCS:GetChildren() do
				if liveNPC:GetAttribute('realName') == targetLiveNPC and liveNPC:IsA('Model') then
					client.Character:PivotTo(liveNPC:GetPivot() * CFrame.new(0, 2, 0))
				end
			end
		elseif workspace:FindFirstChild('HelpfulNPCS') then
			for _, liveNPC in next, workspace.HelpfulNPCS:GetDescendants() do
				if liveNPC:GetAttribute('realName') == targetLiveNPC and liveNPC:IsA('Model') then
					client.Character:PivotTo(liveNPC:GetPivot() * CFrame.new(0, 2, 0))
				end
			end
		end
	end,
})

local function OnLiveNPCsChanged()
	pcall(function()
		Options.LiveNPCTeleports:SetValues(GetLiveNPCsString());
	end)
end;

local liveAdded = liveNPCS.ChildAdded:Connect(OnLiveNPCsChanged);
local liveRemoved = liveNPCS.ChildRemoved:Connect(OnLiveNPCsChanged);

table.insert(shared.connections, liveAdded)
table.insert(shared.connections, liveRemoved)

local function GetMarkersString()
	local MarkerList = {};

	for _, marker in next, markers:GetChildren() do
		if marker:IsA('BillboardGui') and marker.Enabled == true and marker.Adornee ~= nil and typeof(marker.Adornee) == 'Instance' and marker.Adornee:IsDescendantOf(workspace) then
			table.insert(MarkerList, marker.Name)
		end
	end

	table.sort(MarkerList, function(str1, str2) return str1 < str2 end);

	return MarkerList;
end;

local markersString = GetMarkersString()
Groups.Teleports:AddDropdown('MarkerTeleports', {
	Text = 'Teleport to marker',
	AllowNull = true,
	Compact = false,
	Values = markersString,
	Default = markersString[1] ~= nil and markersString[1] or 'No markers found',
	Callback = function(marker)
		if type(marker) ~= 'nil' and markers:FindFirstChild(marker) and markers[marker].Adornee:IsDescendantOf(workspace) and client.Character:IsDescendantOf(alive) then
			client.Character:PivotTo(markers[marker].Adornee:GetPivot())
		end
	end,
})

Groups.Teleports:AddButton('Refresh markers', function()
	Options.MarkerTeleports:SetValues(GetMarkersString());
end)

Groups.Training = Tabs.Main:AddLeftGroupbox('Training')
Groups.Training:AddToggle('AutoKeysDefense',	{ Text = 'Auto press defense keys', Default = false, Tooltip = 'Auto presses correct keys for defense training.' } )
Groups.Training:AddToggle('AutoClickStrength',	{ Text = 'Auto click strength button', Default = false, Tooltip = 'Auto click strength buttons for defense training.' } )
Groups.Training:AddToggle('AutoBuyNearestMat',	{ Text = 'Auto buy nearest training mat', Default = false, Tooltip = 'Auto buys the nearest training mat to you.' } )

local possibleFonts = {
	'Arial',
	'ArialBold',
	'SourceSans',
	'SourceSansBold',
	'SourceSansLight',
	'SourceSansItalic',
	'Bodoni',
	'Garamond',
	'Cartoon',
	'Code',
	'Highway',
	'SciFi',
	'Arcade',
	'Fantasy',
	'Antique',
	'SourceSansSemibold',
	'Gotham',
	'GothamMedium',
	'GothamBold',
	'GothamBlack',
	'AmaticSC',
	'Bangers',
	'Creepster',
	'DenkOne',
	'Fondamento',
	'FredokaOne',
	'GrenzeGotisch',
	'IndieFlower',
	'JosefinSans',
	'Jura',
	'Kalam',
	'LuckiestGuy',
	'Merriweather',
	'Michroma',
	'Nunito',
	'Oswald',
	'PatrickHand',
	'PermanentMarker',
	'Roboto',
	'RobotoCondensed',
	'RobotoMono',
	'Sarpanch',
	'SpecialElite',
	'TitilliumWeb',
	'Ubuntu',
}
Groups.ESP = Tabs.Main:AddRightGroupbox('ESP')
Groups.ESP:AddToggle('MobESP', 				{ Text = 'Mob esp', Default = true})
Groups.ESP:AddSlider('MobESPTransparency',	{ Text = 'Mob esp transparency', Min = 0, Max = 1, Default = 0.5, Suffix = '%', Rounding = 3, Compact = true })
Groups.ESP:AddDropdown('MobESPFont',		{
	Text = 'Mob ESP Font',
	AllowNull = false,
	Compact = false,
	Values = possibleFonts,
	Default = possibleFonts[4]
})
Groups.ESP:AddButton('Refresh ESP', function()
	for _, v in next, alive:GetDescendants() do
		if v.Name == 'boxESP' or v.Name == 'tagESP' then
			v:Destroy()
		end
	end
end)

Groups.Webhooks = Tabs.Main:AddRightGroupbox('Webhooks')
Groups.Webhooks:AddInput('WebhookURL', 					{ Text = 'Webhook URL', Tooltip = 'Webhooks are a utility used to automatically send messages, usueful when used in Discord.', Placeholder = 'webhook url here' } )
Groups.Webhooks:AddToggle('BlackMarket', 				{ Text = 'Black market webhook' })
local blackMarketDepBox = Groups.Webhooks:AddDependencyBox();
blackMarketDepBox:AddInput('BlackMarketMessage', 			{ Text = 'Black market message', Tooltip = 'Message sent in webhook when black market is found.', Default = 'black market found!!! @' .. tostring(client.Name), Placeholder = 'black market message here!' } )
blackMarketDepBox:AddToggle('BlackMarketTeleport',		{ Text = 'Black market auto teleport', Default = false } )
blackMarketDepBox:SetupDependencies({
	{ Toggles.BlackMarket, true }
});

Groups.Quests = Tabs.Main:AddLeftGroupbox('Quests')

local oldPivot = typeof(client.Character) == 'Instance' and client.Character:GetPivot() or CFrame.new(-535, 555, 4638)
Groups.Quests:AddToggle('CatQuests', { Text = 'Complete cat quests', Default = false, Callback = function(Value)
	if Value == true then
		oldPivot = typeof(client.Character) == 'Instance' and client.Character:GetPivot() or CFrame.new(-535, 555, 4638)
	else
		if typeof(client.Character) == 'Instance' and typeof(oldPivot) == 'CFrame' then
			client.Character:PivotTo(oldPivot)
		end
	end
end })
local catFarmDepBox = Groups.Quests:AddDependencyBox();
catFarmDepBox:AddToggle('GiveCatsToShadyMan', { Text = 'Give cats to shady man', Default = false })
catFarmDepBox:AddLabel('If you experience problems with the cat quests, please re-execute. Also make sure the UI isnt covering the dialog text UI.', true)
catFarmDepBox:SetupDependencies({
	{ Toggles.CatQuests, true }
});
Groups.Quests:AddToggle('PhoneQuests', { Text = 'Auto ring phone', Default = false })
Groups.Quests:AddToggle('QuestBoard', { Text = 'Auto quest board', Default = false })
Groups.Quests:AddDropdown('QuestBoardQuest', { Text = 'Quest board quests', AllowNull = false, Compact = false, Values = {'Defeat civilians', 'Defeat fire force members', 'Defeat infernals', 'Defeat white clad members'}, Multi = false, Default = 16 })

Groups.Configs = Tabs.UISettings:AddRightGroupbox('Configs')
Groups.Credits = Tabs.UISettings:AddRightGroupbox('Credits')

addRichText(Groups.Credits:AddLabel('<font color="#0bff7e">Made By Aegians</font> - script'))
addRichText(Groups.Credits:AddLabel('<font color="#ff0000">spokyn</font> - gay nigga'))
addRichText(Groups.Credits:AddLabel('<font color="#3da5ff">wally & Inori</font> - ui library'))

Groups.UISettings = Tabs.UISettings:AddRightGroupbox('UI Settings')
Groups.UISettings:AddLabel('Changelogs:\n' .. metadata.message or 'no message found!', true)
Groups.UISettings:AddDivider()
Groups.UISettings:AddButton('Unload Script', function() pcall(shared._unload) end)
Groups.UISettings:AddButton('Copy Github', function()
	if pcall(setclipboard, 'https://github.com/Aegians?tab=repositories') then
		UI:Notify('Successfully copied Github link to your clipboard!', 5)
	end
end)

Groups.UISettings:AddLabel('Menu toggle'):AddKeyPicker('MenuToggle', { Default = 'Delete', NoUI = true })

UI.ToggleKeybind = Options.MenuToggle

if type(readfile) == 'function' and type(writefile) == 'function' and type(makefolder) == 'function' and type(isfolder) == 'function' then
    makefolder('fire_force_online_gb')
    makefolder('fire_force_online_gb\\configs')

    Groups.Configs:AddDropdown('ConfigList', { Text = 'Config list', Values = {}, AllowNull = true })
    Groups.Configs:AddInput('ConfigName',    { Text = 'Config name' })

    Groups.Configs:AddDivider()

    Groups.Configs:AddButton('Save config', function()
        local name = Options.ConfigName.Value;
        if name:gsub(' ', '') == '' then
            return UI:Notify('Invalid config name.', 3)
        end

        local success, err = SaveManager:Save(name)
        if not success then
            return UI:Notify(tostring(err), 5)
        end

        UI:Notify(string.format('Saved config %q', name), 5)
        task.defer(SaveManager.Refresh)
    end)

    Groups.Configs:AddButton('Load', function()
        local name = Options.ConfigList.Value
        local success, err = SaveManager:Load(name)
        if not success then
            return UI:Notify(tostring(err), 5)
        end

        UI:Notify(string.format('Loaded config %q', name), 5)
    end):AddButton('Delete', function()
        local name = Options.ConfigList.Value
        if name:gsub(' ', '') == '' then
            return UI:Notify('Invalid config name.', 3)
        end

        local success, err = SaveManager:Delete(name)
        if not success then
            return UI:Notify(tostring(err), 5)
        end

        UI:Notify(string.format('Deleted config %q', name), 5)

        task.spawn(Options.ConfigList.SetValue, Options.ConfigList, nil)
        task.defer(SaveManager.Refresh)
    end)

    Groups.Configs:AddButton('Refresh list', SaveManager.Refresh)

    task.defer(SaveManager.Refresh)
    task.defer(SaveManager.Check)
else
    Groups.Configs:AddLabel('Your exploit is missing file functions so you are unable to use configs.', true)
    --UI:Notify('Failed to create configs tab due to your exploit missing certain file functions.', 2)
end

themeManager:SetLibrary(UI)
themeManager:ApplyToGroupbox(Tabs.UISettings:AddLeftGroupbox('Themes'))

shared.mobLockedTo = nil
shared.tpToSafeZone = false
shared.boardQuests = false
UI:Notify(string.format('Loaded script in %.4f second(s)!', tick() - start), 3)
if executor ~= 'Fluxus' and executor ~= 'Electron' and executor ~= 'Valyse' then
	UI:Notify(string.format('You may experience problems with the script/UI because you are using %s', executor), 30)
	task.wait()
	UI:Notify(string.format('Exploits this script works well with currently: Fluxus, Electron, and Valyse'), 30)
end
