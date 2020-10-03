--[[

	Log:
	
	A Flock of Bricks 9/28/2020
	
	- This script handles inputs, the inventory system, and weapon handling
	
]]

-- // Services \\ --

repStorage = game:GetService("ReplicatedStorage")
userInputService = game:GetService("UserInputService")
runService = game:GetService("RunService")
players = game:GetService("Players")
contextActionService = game:GetService("ContextActionService")
tweenService = game:GetService("TweenService")
debrisService = game:GetService("Debris")
starterGUI = game:GetService("StarterGui")

-- // Dependency Objects \\ --

player = players.LocalPlayer
character = player.Character or player.CharacterAdded:Wait()
mouse = player:GetMouse()

-- // Modules \\ --

PlayerScripts = player:WaitForChild("PlayerScripts")
PlayerModule = PlayerScripts:WaitForChild("PlayerModule")
CameraModule = PlayerModule:WaitForChild("CameraModule")
ControlModule = require(PlayerModule:WaitForChild("ControlModule"))

modules = repStorage:WaitForChild("Modules")
gunStats = modules:WaitForChild("GunStats")

M4A1Object = require(gunStats:WaitForChild("M4A1Info"))
RevolverObject = require(gunStats:WaitForChild("RevolverInfo"))

Poppercam = require(CameraModule:WaitForChild("Poppercam"))

Popper = Poppercam.new()

-- // Objects \\ --

humanoid = character:WaitForChild("Humanoid")
rootPart = character:WaitForChild("HumanoidRootPart")
upperTorso = character:WaitForChild("UpperTorso")
waist = upperTorso:WaitForChild("Waist")
head = character:WaitForChild("Head")

function onCharacterAdded(character)
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	upperTorso = character:WaitForChild("UpperTorso")
	waist = upperTorso:WaitForChild("Waist")
	head = character:WaitForChild("Head")
	
	playerGUI = player:WaitForChild("PlayerGui")
	mainGUI = playerGUI:WaitForChild("ScreenGui")
	crosshair = mainGUI:WaitForChild("Crosshair")
end

camera = workspace.CurrentCamera
cameraAimOffset = Vector3.new(2.75, 1.75, 4) -- // where the camera goes when aiming
cameraIdleOffset = Vector3.new(0, 3, 15) -- // where the camera goes when not aiming
equippedWeapon = nil

inventory = {
	M4A1Object,
	RevolverObject
}

-- // Variables \\ --

FRAMES_TO_MAX_CLIMB = 6
MIN_AIM_TIME = 0.75

aimIndex = 0
equippedIndex = 0
cameraAngleX = 0
cameraAngleY = 0
recoilX = 0
recoilY = 0
fovRecoil = 0
muzzleTime = 0
tickCheck = 0
fsi = -1
aiming = false
mouse1Down = false
mouse2Down = false
qDown = false
equipDebounce = false
storedClassicCamera = CFrame.new() -- // Stores the camera CFrame pre-aim
storedAimedCamera = CFrame.new() -- // Stores the camera CFrame post-aim

-- // Remote Functions \\ --

funcFolder = repStorage:WaitForChild("Functions")
eventFolder = repStorage:WaitForChild("Events")
fireShotEvent = eventFolder:WaitForChild("FireShot")
equipWeaponFunc = funcFolder:WaitForChild("EquipWeapon")
unequipWeaponFunc = funcFolder:WaitForChild("UnequipWeapon")

-- // Initializing Statements \\ --

-- nothing for now

-- // GUIS \\ --

playerGUI = player:WaitForChild("PlayerGui")
mainGUI = playerGUI:WaitForChild("ScreenGui")
crosshair = mainGUI:WaitForChild("Crosshair")

-- // Functions \\ --

function endAnimation(animName)
	local animationTracks = humanoid:GetPlayingAnimationTracks()
	
	for i = 1, #animationTracks do
		if animationTracks[i].Name == animName then
			animationTracks[i]:Stop()
		end
	end
end

function equip(index)
	
	if equipDebounce == false then
		
		equipDebounce = true
	
		if equippedWeapon ~= nil then
			
			unequipWeaponFunc:InvokeServer(equippedWeapon)
			equippedWeapon = nil
			
			endAnimation("Hold")
			endAnimation("Aim")
			
		end
		
		if equippedIndex == index then -- // unequipping weapon
			
			equippedIndex = 0
			
		else
			
			equippedIndex = index
			
			equippedWeapon = equipWeaponFunc:InvokeServer(inventory[equippedIndex].model)
			
			if aiming == true then
				playAnimation("Aim")
			else
				playAnimation("Hold")
			end
			
			fsi = -1
			FRAMES_TO_MAX_CLIMB = 5 + (inventory[equippedIndex].recoil^5)
			
			userInputService.MouseIconEnabled = false -- Move this section of code to occur on join game once GUI is setup
			camera.CameraType = Enum.CameraType.Scriptable
			userInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			
		end
		
		equipDebounce = false
		
	end
		
end

function playerInput(actionName, inputState, inputObject)

	if inputState == Enum.UserInputState.Change then
		
		cameraAngleX = cameraAngleX - inputObject.Delta.X

		cameraAngleY = math.clamp(cameraAngleY - inputObject.Delta.Y*0.4, -75 - recoilY/10, 75 - recoilY/10)

	end
end

function playAnimation(animName)
	
	if equippedWeapon == nil then
		return
	end
	
	local gunAnimations = equippedWeapon:FindFirstChild("Animations")
	
	if gunAnimations ~= nil then
		local anim = gunAnimations:FindFirstChild(animName)
		if anim ~= nil then
			humanoid:LoadAnimation(anim):Play()
		end
	end
end

function enableShoulderCameraSettings()
	userInputService.MouseDeltaSensitivity = 0.6
	crosshair.Visible = true
	aiming = true
	storedClassicCamera = camera.CFrame
	humanoid.AutoRotate = false
	endAnimation("Hold")
	playAnimation("Aim")
end

function disableShoulderCameraSettings()
	crosshair.Visible = false
	userInputService.MouseDeltaSensitivity = 1
	aiming = false
	humanoid.AutoRotate = true
	endAnimation("Aim")
	playAnimation("Hold")
end

function muzzleFlash()
	
	local muzzle = equippedWeapon:FindFirstChild("Muzzle")
	
	if muzzle ~= nil then
		local muzzleFlashParticle = muzzle:FindFirstChild("MuzzleFlash")
		if muzzleFlashParticle ~= nil then
			muzzleFlashParticle.Enabled = true
			muzzleTime = 4
		else
			print("No muzzleFlash found")
		end
	else
		print("No muzzle found")
	end
end

function endMuzzleFlash()
	local muzzle = equippedWeapon:FindFirstChild("Muzzle")
	if muzzle ~= nil then
		local muzzleFlashParticle = muzzle:FindFirstChild("MuzzleFlash")
		if muzzleFlashParticle ~= nil then
			muzzleFlashParticle.Enabled = false
		else
			print("No muzzleFlash found")
		end
	else
		print("No muzzle found")
	end
end

function playSound()
	if equippedWeapon ~= nil then
		local audioFolder = equippedWeapon:FindFirstChild("Audio")
		
		if audioFolder == nil then
			return
		end
		
		local shootSound = audioFolder:FindFirstChild("Fire")
		
		if shootSound ~= nil then
			local shootSoundClone = shootSound:Clone()
			shootSoundClone.Parent = equippedWeapon:FindFirstChild("Muzzle")
			shootSoundClone:Play()
			debrisService:AddItem(shootSoundClone, 3)
		end
	end
end

function fireShot()
	
	playAnimation("Shoot")
	playSound()
	--desiredRecoilY = desiredRecoilY + inventory[equippedIndex].recoil
	muzzleFlash()
	fsi = 0
	
	if equippedWeapon ~= nil then
	
		fireShotEvent:FireServer(equippedWeapon, camera.CFrame, inventory[equippedIndex].damage) -- // reminder: if I need more than damage in the future, pass the object
		
	end
	
end

function popCamera(positionCFrame, focusCFrame) -- // Tests to see if the camera's clipping anything. If it is, the move the camera towards the player.
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {character}
	local popRaycastResults = workspace:Raycast(head.Position, positionCFrame.Position - head.Position, raycastParams)
	if popRaycastResults then
		return CFrame.new(popRaycastResults.Position, focusCFrame.Position)
	else
		return CFrame.new(positionCFrame.Position, focusCFrame.Position)
	end
end

function updateCamera(dt) -- // Everything that modifies the camera and would be called in RenderStepped runs here, otherwise the RenderStepped function is too cluttered
	local startCFrame = CFrame.new((rootPart.CFrame.Position)) * CFrame.Angles(0, math.rad(cameraAngleX), 0) * CFrame.Angles(math.rad(cameraAngleY) + math.rad(recoilY/10), 0, 0)
	
	if aiming == true then
		local cameraCFrame = startCFrame:ToWorldSpace(CFrame.new(cameraAimOffset.X, cameraAimOffset.Y, cameraAimOffset.Z))
		local cameraFocus = startCFrame:ToWorldSpace(CFrame.new(cameraAimOffset.X, cameraAimOffset.Y, -10000))
		camera.CFrame = storedClassicCamera:Lerp(CFrame.new(cameraCFrame.Position, cameraFocus.Position), 1-(1-aimIndex))
		
		storedAimedCamera = camera.CFrame
	else
		local cameraCFrame = startCFrame:ToWorldSpace(CFrame.new(cameraIdleOffset.X, cameraIdleOffset.Y, cameraIdleOffset.Z))
		local cameraFocus = startCFrame:ToWorldSpace(CFrame.new(cameraIdleOffset.X, cameraIdleOffset.Y, -10000))
		camera.CFrame = popCamera(cameraCFrame, cameraFocus):Lerp(storedAimedCamera, 1-(1-aimIndex))
		
	end
end

-- // Event Listeners & Event Handlers \\ --

player.CharacterAdded:Connect(onCharacterAdded)

runService.RenderStepped:Connect(function(dt)
	
	if humanoid.Health > 0 then
	
		if aiming == true then -- // when in transition stage from not aiming to aiming
			
			if aimIndex < .9 then
				aimIndex = aimIndex + .1
				humanoid.WalkSpeed = (16 - (aimIndex * 10))
			end
			
			local spread = 80 - (40 * aimIndex) - fsi*(fsi-(FRAMES_TO_MAX_CLIMB * 2))/3
			
			crosshair.Size = UDim2.new(0, spread, 0, spread)
			
			if fsi >= 0 and fsi <= (FRAMES_TO_MAX_CLIMB * 2) then
				recoilY += ((FRAMES_TO_MAX_CLIMB - fsi) * 2 * inventory[equippedIndex].recoil)
				fsi = fsi + 1
			elseif fsi > (FRAMES_TO_MAX_CLIMB * 2) then
				fsi = -1
			end
			
			camera.FieldOfView = 70 - fsi*(fsi-(FRAMES_TO_MAX_CLIMB * 2))/10
			
			updateCamera(dt)
			
			local x, y, z = workspace.CurrentCamera.CFrame:ToOrientation()
			
			waist.C0 = waist.C0:Lerp(CFrame.Angles(math.clamp(x, -1, 1), 0, 0), 1-(1-aimIndex))
			rootPart.CFrame = rootPart.CFrame:Lerp(CFrame.new(rootPart.Position) * CFrame.Angles(0, y, 0), 1-(1-aimIndex))
			
		else
			
			if aimIndex > 0 then -- // runs when in process of un-aiming
				aimIndex = math.floor(aimIndex*10 - 1)/10 -- // Work-around for a floating point error
				humanoid.WalkSpeed = (16 - (aimIndex * 10))
				waist.C0 = waist.C0:Lerp(CFrame.Angles(0, 0, 0), 1-(1-aimIndex))
			end
			
			updateCamera(dt)
			
		end
	
		if muzzleTime > 0 then
			muzzleTime = muzzleTime - 1
			if muzzleTime <= 0 then
				endMuzzleFlash()
			end
		end
		
	end
	
end)

userInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		local keyPressed = input.KeyCode
		
		if keyPressed == Enum.KeyCode.One then
			equip(1)
		elseif keyPressed == Enum.KeyCode.Two then
			equip(2)
		end
		
		if keyPressed == Enum.KeyCode.Q then
			
			qDown = true
			
			if equippedIndex ~= 0 then
				enableShoulderCameraSettings()
			end
		end
		
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		
		mouse1Down = true
		
		while mouse1Down == true do
			if equippedWeapon ~= nil then
				if aiming == true then
					if (tick() - tickCheck > 60/inventory[equippedIndex].rpm) then
						fireShot()
						tickCheck = tick()
						if inventory[equippedIndex].gunType == "Semi-Automatic" then
							break
						end
					end
				else
					enableShoulderCameraSettings()
				end
			end
			runService.Heartbeat:Wait()
		end
		
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		
		mouse2Down = true
		
		if equippedIndex ~= 0 then
			enableShoulderCameraSettings()
		end
		
	elseif input.UserInputType == Enum.UserInputType.Touch then
		print("Player touched screen at ", input.Position)
	elseif input.UserInputType == Enum.UserInputType.Gamepad1 then
		print("Console input: ",input.KeyCode)
	end
end)

userInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		local keyPressed = input.KeyCode
		
		if keyPressed == Enum.KeyCode.Q then
			
			qDown = false
			
			if mouse2Down == false and mouse1Down == false then
				disableShoulderCameraSettings()
			end
		end
		
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		
		mouse1Down = false
		
		if mouse2Down == false and qDown == false then
			if MIN_AIM_TIME > tick() - tickCheck then
				wait(MIN_AIM_TIME - (tick() - tickCheck))
				if MIN_AIM_TIME > tick() - tickCheck or mouse1Down == true or mouse2Down == true then
					return
				end
			end
			disableShoulderCameraSettings()
		end
		
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		
		mouse2Down = false
		
		if mouse1Down == false and qDown == false then
			disableShoulderCameraSettings()
		end
		
	end
end)

contextActionService:BindAction("PlayerInput", playerInput, false, Enum.UserInputType.MouseMovement, Enum.UserInputType.Touch)