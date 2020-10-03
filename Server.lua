-- // Services \\ --

repStorage = game:GetService("ReplicatedStorage")
players = game:GetService("Players")
serverStorage = game:GetService("ServerStorage")

-- // Remote Events \\ --

eventFolder = repStorage:WaitForChild("Events")
funcFolder = repStorage:WaitForChild("Functions")

fireShotEvent = eventFolder:WaitForChild("FireShot")
equipWeaponFunc = funcFolder:WaitForChild("EquipWeapon")
unequipWeaponFunc = funcFolder:WaitForChild("UnequipWeapon")

-- // Objects \\ --

effectFolder = serverStorage:WaitForChild("Effects")
bulletImpact = effectFolder:WaitForChild("bulletImpact")

-- // Functions \\ --

function createImpact(raycastResult)
	local bulletImpactClone = bulletImpact:Clone()
	bulletImpactClone.Parent = workspace
	bulletImpactClone.CFrame = CFrame.new(raycastResult.Position, raycastResult.Position - raycastResult.Normal);
	
	local dustFX = bulletImpactClone:FindFirstChild("DustFX")
	
	if dustFX then
		dustFX.Color = ColorSequence.new(raycastResult.Instance.Color)
	end
	
	if raycastResult.Material == Enum.Material.Metal then
		bulletImpactClone:WaitForChild("hitMetal"):Play()
	else
		if math.random(1, 2) == 1 then
			bulletImpactClone:WaitForChild("hitConcrete1"):Play()
		else
			bulletImpactClone:WaitForChild("hitConcrete2"):Play()
		end
	end
end

function fireShot(player, weapon, cameraCFrame, damage)
	if weapon == nil then
		return
	end
	local muzzle = weapon:FindFirstChild("Muzzle")
	if muzzle ~= nil then
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		raycastParams.FilterDescendantsInstances = {weapon}
		local raycastResult = workspace:Raycast(cameraCFrame.Position, cameraCFrame.LookVector*500, raycastParams)
		if raycastResult then
			local parentHit = raycastResult.Instance.Parent
			if parentHit:IsA("Accessory") then
				parentHit = parentHit.Parent
			end
			if parentHit ~= workspace then
				local vicHum = parentHit:FindFirstChild("Humanoid")
				if vicHum ~= nil then
					local totalDamage = damage
					if raycastResult.Instance.Name == "Head" then
						totalDamage = totalDamage * 2
					end
					vicHum.Health = vicHum.Health - totalDamage
					return
				end
			end
			
			createImpact(raycastResult)
			
		end
	end
end

-- // equip weapons on server, pass weapon to client

function equipWeapon(player, weapon)
	
	if weapon ~= nil then
		local weaponClone = weapon:Clone()
		weaponClone.Parent = player.Character
		
		local charHand = player.Character:FindFirstChild("RightHand")
		
		if charHand ~= nil then
			local weaponCloneWeld = Instance.new("WeldConstraint", charHand)
			weaponClone:SetPrimaryPartCFrame(charHand.CFrame)
			weaponCloneWeld.Part0 = charHand
			weaponCloneWeld.Part1 = weaponClone:FindFirstChild("Handle")
		end
		return weaponClone
	end
	
	print("failed to equip weapon for " .. player.Name)
	return
end

function unequipWeapon(player, weapon)
	
	if weapon ~= nil then
		weapon:Destroy()
	else
		print("Tried to unequip nil")
	end
	
	return
		
end

-- // Event Listeners \\ --

fireShotEvent.OnServerEvent:Connect(fireShot)
equipWeaponFunc.OnServerInvoke = equipWeapon
unequipWeaponFunc.OnServerInvoke = unequipWeapon