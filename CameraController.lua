CameraControl = class()
CameraControl.maxParentCount = -1
CameraControl.maxChildCount = -1
CameraControl.connectionInput = sm.interactable.connectionType.logic
CameraControl.connectionOutput = sm.interactable.connectionType.logic
CameraControl.colorNormal = sm.color.new(0xffaaaaff)
CameraControl.colorHighlight = sm.color.new(0x888888ff)

if  sm.isHost then -- Just avoid anythign that isnt the host for now
	dofile "racerData.lua"
	dofile "RaceCamera.lua"
end
function CameraControl.server_onCreate( self ) 
	print("CamControl Oncreate")
end
 

function CameraControl.client_init( self )
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	self.currentCameraIndex = 0 -- Which camera index is currently being active, If there are no cameras, then just skip
	self.currentCamera = nil --Current Camera MetaData
	self.cameraActive = false -- if any Cameras Are being used
	self.onBoardActive = false -- If onboard camera is active

	self.spacePressed = false -- If space is pressed
	self.shiftPressed = false -- if shift (or any other invalid key) is pressed

	self.focusedRacerID = nil -- ID of racer all cameras are being focused on
	self.focusedRacePos = nil -- The position of the racer all cameras are being focused on
	self.focusPos = false -- Keep camera focused on car set by focusedRacePos
	self.focusRacer = false -- Keep camera focused on Car set by racerID, nomatter the pos
	
	self.droneData = nil -- All of the necessary Drone Data 
	self.droneActive = false -- Drone Toggle

	self.droneFollowRacerID = nil -- Drone following racer
	self.droneFollowRacePos = nil -- Drone Following racePosition
	self.droneFocusRacerID = nil -- Drone Focus on racer
	self.droneFocusRacePos = nil -- Drone focus on racePos

	self.droneFollowPos = false -- Drone keep focused on following by racePosition
	self.droneFollowRacer = false -- Drone keep focused on following by racerID
	self.droneFocusPos = false -- Keep Drone Focused on focusing by racePos
	self.droneFocusRacer = false -- Keep Drone Focused on focusing by racerID
	
	self.focusedRacerData = nil -- All of the specified focused racer data
	-- Followed racer data?
	self.raceStatus = getRaceStatus()
	

	self.finishCameraActive = false -- If it is currently focusing on finish camera

	-- Error states to prevent spam
	self.errorShown = false
	self.hasError = false
	print("Camera Control Init")
end

function CameraControl.server_onRefresh( self )
	self:client_onDestroy()
	dofile "racerData.lua"
	self:client_init()
	sortCameras()
end

function CameraControl.client_onCreate(self)
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	self:client_init()
	self:loadDroneData()
end

function CameraControl.client_onDestroy(self)
	self.cameraActive = false
	self.droneActive = false
end

function CameraControl.loadDroneData(self) -- Just checks and grabs Drone Data
	if droneInfo then -- Scalablility?
		if #droneInfo == 1 then
			self.droneData = droneInfo[1]
			if self.droneData == nil then print("Error Reading Drone Data") end
		else
			print("No Drones Found")
		end
	else
		print("Drone Info Table not created")
	end
end

function CameraControl.iterateCameraFocusByPos(self,direction) -- Cycle Which racer to Focus on ( NON Drone Function), Itterates by position
	if self.focusedRacePos == nil then 
		print("Defaulting RacePos Focus to 1")
		self.focusedRacePos = 1
	end
	local totalRacers = #racerData
	
	local nextRacerPos = self.focusedRacePos + direction
	--print(self.focusedRacePos + direction)
	if nextRacerPos == 0 or nextRacerPos > totalRacers then
		print("Iterate focus On Pos Overflow/UnderFlow Error",nextRacerPos) 
		nextRacerPos = self.focusedRacePos -- prevent from index over/underflow by keeping still, cycling could create confusion
		return
	end
	--print("Iterating Focus to next Pos:",nextRacerPos)
	local nextRacer = getRacerByPos(nextRacerPos)
	--print(nextRacer)
	if nextRacer == nil then
		--print(Error getting next racer)
		-- Means that the racers POS are 0 or error
		return
	end
	self.focusedRacerData = nextRacer
	self.focusedRacePos = nextRacerPos
	self.focusedRacerID =nextRacer.racerID
	self.focusPos = true
	self.focusRacer = false
	-- Also sets drone? or have it separate, Both focuses and follows drone
	self.droneFollowRacerID = nextRacer.racerID 
	self.droneFollowRacePos = nextRacerPos
	self.droneFocusRacerID = nextRacer.racerID 
	self.droneFocusRacePos = nextRacerPos 

	self.droneFollowPos = true 
	self.droneFollowRacer = false 
	self.droneFocusPos = true 
	self.droneFocusRacer = false 

	self:focusAllCameras(nextRacer)
end


function CameraControl.iterateCameraFocusByIndex(self,direction) -- Cycle Which racer to Focus on ( NON Drone Function), Itterates by Index,() ID if sorted)
	if self.focusedRacerID == nil then 
		print("Defaulting index Focus to 1")
		self.focusedRacerID = 1
	end
	local totalRacers = #racerData
	
	local nextRacerID = self.focusedRacerID + direction
	--print(self.focusedRacePos + direction)
	if nextRacerID == 0 or nextRacerID > nextRacerID then
		print("Iterate focus On ID Overflow/UnderFlow Error",nextRacerPos) 
		nextRacerID = self.nextRacerID -- prevent from index over/underflow by keeping still, cycling could create confusion
		return
	end
	--print("Iterating Focus to next Pos:",nextRacerPos)
	local nextRacer = getRacerByIndex(nextRacerID)
	--print(nextRacer)
	if nextRacer == nil then
		--print(Error getting next racer)
		-- Means that the racers POS are 0 or error
		print("CamControl,iterate index: Something went wrong when getting racer",nextRacerID)
		return
	end
	self.focusedRacerData = nextRacer
	self.focusedRacePos = nextRacer.racePosition
	self.focusedRacerID =nextRacer.racerID
	self.focusPos = false
	self.focusRacer = true
	-- Also sets drone? or have it separate, Both focuses and follows drone
	self.droneFollowRacerID = nextRacer.racerID 
	self.droneFollowRacePos = nextRacer.racePosition
	self.droneFocusRacerID = nextRacer.racerID 
	self.droneFocusRacePos = nextRacer.racePosition

	self.droneFollowPos = false 
	self.droneFollowRacer = true 
	self.droneFocusPos = false 
	self.droneFocusRacer = true 

	self:focusAllCameras(nextRacer)
end


function CameraControl.focusCameraOnPos(self,racePos) -- Grabs Racers from racerData by RacerID, pulls racer
	local racer = getRacerByPos(racePos) -- Racer Index is just populated as they are added in
	if racer == nil then
		print("Camera Focus on racer Pos Error")
		return
	end
	if racer.racePosition == nil then
		print("Racer has no RacePos",racer)
		return
	end
	self.focusedRacerData = racer
	self.focusedRacePos = racer.racePosition
	self.focusedRacerID = racer.racerID
	self.focusPos = true
	self.focusRacer = false
	-- Also sets drone? or have it separate, Both focuses and follows drone
	self.droneFollowRacerID = racer.racerID 
	self.droneFollowRacePos = racer.racePosition
	self.droneFocusRacerID = racer.racerID 
	self.droneFocusRacePos = racer.racePosition

	self.droneFollowPos = true 
	self.droneFollowRacer = false 
	self.droneFocusPos = true 
	self.droneFocusRacer = false

	self:focusAllCameras(racer)
end
function CameraControl.focusCameraOnRacerIndex(self,racerIndex) -- Grabs Racers from racerData by RacerID, pulls racer
	local racer = getRacerByIndex(racerIndex) -- Racer Index is just populated as they are added in
	if racer == nil then
		print("Camera Focus on racer index Error")
		return
	end
	if racer.racePosition == nil then
		print("Racer has no RacePos",racer.racerID)
		return
	end
	self.focusedRacerData = racer
	self.focusedRacePos = racer.racePosition
	self.focusedRacerID = racer.racerID
	self.focusPos = false
	self.focusRacer = true
	-- Also sets drone? or have it separate, Both focuses and follows drone
	self.droneFollowRacerID = racer.racerID 
	self.droneFollowRacePos = racer.racePosition
	self.droneFocusRacerID = racer.racerID 
	self.droneFocusRacePos = racer.racePosition

	self.droneFollowPos = false 
	self.droneFollowRacer = true 
	self.droneFocusPos = false 
	self.droneFocusRacer = true

	self:focusAllCameras(racer)
end

function CameraControl.setDroneFollowRacerIndex(self,racerIndex) -- Tells the drone to follow whatever index it is
	local racer = getRacerByIndex(racerIndex) -- Racer Index is just populated as they are added in
	if racer == nil then
		print("Drone follow racer index Error",racerIndex)
		return
	end
	if racer.racePosition == nil then
		print("Drone Racer has no RacePos",racer.racerID)
		return
	end

	-- Also sets drone? or have it separate, Both focuses and follows drone
	self.droneFollowRacerID = racer.racerID 
	self.droneFollowRacePos = racer.racePosition

	self.droneFollowPos = false 
	self.droneFollowRacer = true 

	self.droneData:setFollow(racer)
end

function CameraControl.setDroneFollowFocusedRacer(self) -- Tells the drone to follow whatever Car it is focused on
	local racer = getRacerByIndex(self.focusedRacerID) -- Racer Index is just populated as they are added in
	if racer == nil then
		print("Drone follow Focused racer index Error",self.focusedRacerID)
		return
	end
	if racer.racePosition == nil then
		print("Drone Racer has no RacePos",racer.racerID)
		return
	end

	-- Also sets drone? or have it separate, Both focuses and follows drone
	self.droneFollowRacerID = racer.racerID 
	self.droneFollowRacePos = racer.racePosition

	self.droneFollowPos = false 
	self.droneFollowRacer = true 
	self.droneData:setFollow(racer)
end

--[[function _Depreciated_CameraControl.focusCameraOnCar(self, carIndex) -- Focuses all cameras on a certain car indedx (up to 10) ** Depreciated but keeping just in case
	--print("Focusing on car:",carIndex)
	if carIndex > #racerData or carIndex <= 0 then
		print("Car Indexing Error")
		return
	end
	local racer = racerData[carIndex]
	local racerPos = racer.racePosition
	self:setAllCameraFocus(racerPos)
--end]]--

function CameraControl.focusAllCameras(self, racer) --Sets all Cameras to focus on a racer
	local racerID = racer.racerID
	local racePos = racer.racePosition

	if racer.racerID == nil then
		print("Setting Camera focus nill/invalid racer")
		return
	end 
	--Drone Focusing is be done inside getter goal.
	for k=1, #raceCameras do local v=raceCameras[k]-- Foreach camera, set their individual focus/power
		if v.power ~= racePos then
			--print(v.power,racePos)
			v:setFocus(racePos)
		end
	end
end


-----
--- Camera Switching functions

function CameraControl.switchToFinishCam(self) -- Unsure if to make separate cam for this?
	self.finishCameraActive = true
end


function CameraControl.toggleDroneCam(self) -- Sets Camera and posistion for drone cam, 
	if not self.droneActive then
		print("switching to drone")
		if self.droneData == nil then
			print("retrying connection to drone")
			self:loadDroneData()
			if self.droneData == nil then
				print("connection to drone Failed")
				return
			end
		end
		if self.focusedRacerData == nil then
			print("Drone Error focus on racer")
			return
		end
		local location = self.focusedRacerData.location
		local objLoc = self.droneData.location
		local goalOffset =  location - objLoc
		local camDir = sm.camera.getDirection()
		
		objLoc.z = objLoc.z-1.5
		sm.camera.setDirection(goalOffset)
		sm.camera.setPosition(objLoc)
		self.droneActive = true
		self.onBoardActive = false
	else
		self:cycleCamera(0) -- Go back to drone
		self.droneActive = false
		self.onBoardActive = false

	end
			--end
end

function CameraControl.toggleOnBoardCam(self) -- Toggles on board for whichever racer is focused
	if not self.onBoardActive then
		if self.focusedRacerData == nil then
			print("NO camera Focused on")
			return
		end
		self.droneActive = false
		self.onBoardActive = true
		local racer = self.focusedRacerData
		local location = racer.location
		local goalOffset =  location - sm.camera.getPosition()
		local camDir = sm.camera.getDirection()
		local carDir = racer.shape:getAt()
		location.z = location.z +4-- Offset higher
		sm.camera.setDirection(carDir)
		sm.camera.setPosition(location)
	else
		self:cycleCamera(0) -- Go back to drone
		self.droneActive = false
		self.onBoardActive = false
	end
end

function CameraControl.switchToCamera(self, cameraIndex) -- switches to certain cameras based on  inddex (up to 10) 0-9
	
	--cameraIndex = cameraIndex - 1 -- Accounts for stupid non zero indexed arrays
	local totalCams = #raceCameras
	if cameraIndex > #raceCameras or cameraIndex <= 0 then
		print("Camera Switch Indexing Error",cameraIndex)
		return
	end
	local camera = raceCameras[cameraIndex]
	if camera == nil then 
		print("Camera not found",cameraIndex)
		return
	end
	if camera.cameraID == nil then
		print("Error when switching to camera",camera,cameraIndex)
		return
	end
	self.onBoardActive = false
	self.droneActive = false
	self.currentCameraIndex = cameraIndex - 1
	--print("switching to camera:",cameraIndex,self.currentCameraIndex)
	self:setNewCamera(cameraIndex - 1)
end



function CameraControl.cycleCamera(self, direction)
	if self.droneActive then
		print("exit Cycle Drone")
		self.droneActive = false
		self.onBoardActive = false

	end
	if self.onBoardActive then
		self.onBoardActive = false
	end
	local totalCam = #raceCameras
	--print(totalCam,self.currentCameraIndex)
	local nextIndex = (self.currentCameraIndex + direction ) %totalCam
	--print("next index",nextIndex)
	if nextIndex > totalCam then
		print("Camera Index Error")
		return
	end
	self:setNewCamera(nextIndex)
	
end

function CameraControl.setNewCamera(self, cameraIndex) -- Switches to roadside camera based off of its index
	self.currentCameraIndex = cameraIndex
	if raceCameras == nil or #raceCameras == 0 then
		print("No Cameras Found")
		return
	end
	local cameraToView = raceCameras[self.currentCameraIndex + 1]
	print("viewing cam", self.currentCameraIndex + 1)
	if cameraToView == nil then
		print("Error connecting to road Cam",self.currentCameraIndex)
		return
	end
	self.currentCamera = cameraToView
	local camLoc = cameraToView.shape:getWorldPosition()
	--camLoc.z = camLoc.z + 2.1 -- Offsets it to be above cam
	sm.camera.setPosition(camLoc)
	sm.camera.setDirection(cameraToView.shape:getUp())
	sm.camera.setCameraState(2)
	--sm.camera.cameraSphereCast(50,sm.vec3.new(1,10,20),sm.vec3.new(1,23,32))  What do?
	sm.localPlayer.getPlayer():getCharacter():setLockingInteractable(self.interactable)
end

-- Utility functions

function CameraControl.client_onInteract(self, char, state)
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	if state then 
		self.cameraActive = true
		--print(raceCameras)
		if #raceCameras == 0 then
			print("There are no cameras in this world")
			self.cameraActive = false
			return 
		end
		if self.currentCameraIndex > #raceCameras then -- If somehow a camera was deleted, reset index
			print("reset index")
			self.currentCameraIndex = 0
		end
		print("Started Viewing Camera",self.currentCameraIndex)
		self:setNewCamera(self.currentCameraIndex)
		
	else
		--print("OffE")
		--cameraToView:setActivity(false)
	end
	
end

function CameraControl.client_onUpdate(self,dt)
	--self:focusCameraOnRacerID(self.lookingAtCarID) -- Make sure camera is focused on car
	--print("onUpdate, dt",dt)
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	local goalOffset = nil
	goalOffset = self:getGoal()
	if goalOffset == nil then
		return
	end
	
	
	if self.focusRacer then
		self:calculateFocus()
	end
	self:updateCameraPos(goalOffset,dt)
	
	--print("update")
end

function CameraControl.client_onFixedUpdate(self,dt)
	--self:focusCameraOnRacerID(self.lookingAtCarID) -- Make sure camera is focused on car
	--print("fixedUpdate, dt",dt)
end

function CameraControl.calculateFocus(self)
	local racer = self.focusedRacerData -- Racer Index is just populated as they are added in
	if racer == nil then
		print("Calculating Focus on racer index Error")
		return
	end
	if racer.racePosition == nil and not self.errorShown then
		print("CFocus has no RacePos",racer)
		self.errorShown = true
		return
	end
	self:focusAllCameras(racer)

end


function CameraControl.client_onAction(self, key, state) -- On Keypress
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	if key == 0 then
	 self.shiftPressed = state
	elseif key == 1 and state then -- A key
		if self.spacePressed and self.shiftPressed then
		elseif self.spacePressed then
		elseif self.shiftPressed then
		else
			self:iterateCameraFocusByIndex(-1)
		end
	elseif key == 2 and state then -- D Key
		if self.spacePressed and self.shiftPressed then
		elseif self.spacePressed then
		elseif self.shiftPressed then
		else
			self:iterateCameraFocusByIndex(1)
		end
	elseif key == 3 and state then -- W Key
		if self.spacePressed and self.shiftPressed then
		elseif self.spacePressed then
		elseif self.shiftPressed then
		else -- None pressed
			self:iterateCameraFocusByPos(1)
		end
	elseif key == 4 and state then -- S Key
		if self.spacePressed and self.shiftPressed then
		elseif self.spacePressed then
		elseif self.shiftPressed then
		else
			self:iterateCameraFocusByPos(-1)
		end

	elseif key >= 5 and key <= 14 and state then -- Number Keys 1-0
		local convertedIndex = key - 4
		if self.spacePressed and self.shiftPressed then
			self:setDroneFollowRacerIndex(convertedIndex)
		elseif self.spacePressed then -- focus race Pos
			self:focusCameraOnPos(convertedIndex)
		elseif self.shiftPressed then
			self:switchToCamera(convertedIndex)
		else -- Focus Racer Index
			self:focusCameraOnRacerIndex(convertedIndex)
		end
		
	elseif key == 15 and state  then -- 'E' Pressed
		if self.spacePressed and self.shiftPressed then -- Finish Cam?
			--print("Toggle Onboard Cam")
			self:toggleOnBoardCam()
			
		elseif self.spacePressed then
			self:toggleDroneCam()
		--elseif self.shiftPressed then
		else -- Maybe move to toggling function
			self.cameraActive = false
			self.droneActive = false
			sm.localPlayer.getPlayer():getCharacter():setLockingInteractable(nil)
			sm.camera.setCameraState(1)
		end

	elseif key == 16 then -- SpacePressed
		self.spacePressed = state

	elseif key == 18 and state then -- Right Click,
		if self.spacePressed and self.shiftPressed then
		elseif self.spacePressed then
			self:cycleRaceStatus(-1)
		elseif self.shiftPressed then
		else
			self:cycleCamera(-1)
		end
	elseif key == 19 and state then -- Left Click, 
		if self.spacePressed and self.shiftPressed then
		elseif self.spacePressed then
			self:cycleRaceStatus(1)
		elseif self.shiftPressed then
		else
			self:cycleCamera(1)
		end
		
	elseif key == 20 then -- Scroll wheel up/ X 
		if self.spacePressed and self.shiftPressed then
			self:setDroneFollowFocusedRacer()
		elseif self.spacePressed then
		elseif self.shiftPressed then
		else -- None pressed
			if self.droneActive then -- Move up by 1
				self.droneData:changeHeight(self.droneData.hoverHeight +1)
			end
		end
	elseif key == 21 then --scrool wheel down % C Pressed -- Zoom? Drone Height?
		if self.spacePressed and self.shiftPressed then
		elseif self.spacePressed then
		elseif self.shiftPressed then
		else -- None pressed
			if self.droneActive then -- Move down by 1
				self.droneData:changeHeight(self.droneData.hoverHeight -1)
			end
		end
	end
	return false
end


function CameraControl.getGoal( self) -- Finds focused car and takes location based on that
	local racer = self.focusedRacerData
	-- If droneactive get droneFocusData
	
	if racer == nil then 
		if #racerData > 0 then
			racer = racerData[1]
			self.hasError = false
		else
			if not self.hasError then
				print("No Focused Racer")
				self.hasError = true
			end
			return nil
		end
	end
	if racer.racerID == nil  then
		if self.hasError == false then
			print("malformed racer") -- Add hasError?
			self.hasError = true
		end
		return nil
	else
		self.hasError = false
	end
	--print(carID)
	local location = racer.location
	
	local camLoc = sm.camera.getPosition()
	local goalOffset =  location - camLoc
	--print(camLoc)
	return goalOffset
end

--- Race Control Functions
function CameraControl.cycleRaceStatus(self,dir)
	local raceStatus = raceStatus + dir
	print("Setting race status",raceStatus,dir)
	--print(sm.smarlFunctions)
	sm.smarlFunctions.setRaceStatus(raceStatus)
	self.raceStatus = raceStatus
end

-- CameraMovement functions

function CameraControl.updateCameraPos(self,goal,dt)
	--print(dt)
	if self.currentCamera ~= nil and self.cameraActive then
		local cameraToView = self.currentCamera
		
		local camDir = sm.camera.getDirection()
		local objDir = cameraToView.shape:getUp()
		local camLoc = sm.camera.getPosition()
		--print(camLoc)
		local objLoc = cameraToView.shape:getWorldPosition()
		local dirMovement = nil
		local locMovement = nil
		
		local dirDT = dt * 0.2
		if self.droneActive then
			if self.droneData == nil then
				print("Error connecting to drone")
			end
			objLoc = self.droneData.location
			if objLoc == nil then
				return
			end
			--print(camLoc)
			--camDir = self.droneData.shape:getUp()
			camLoc.z = camLoc.z-0.15
			locMovement = sm.vec3.lerp(camLoc,objLoc,dt*6)
			-- TEmporary scenic cam	
			--local newGoal = sm.vec3.new(0,0,0)
			--dirMovement = sm.vec3.lerp(camDir,newGoal,dirDT)
			dirMovement = sm.vec3.lerp(camDir,goal,dirDT)
			--dirMovement = sm.vec3.new(0,0,-0.1)
			sm.camera.setDirection(dirMovement)
			sm.camera.setPosition(locMovement)
			--print(locMovement)
		elseif self.onBoardActive then
			local racer = self.focusedRacerData
			local location = racer.location
			--print(location.z)
			local goalOffset =  location - sm.camera.getPosition()
			local camDir = sm.camera.getDirection()
			local carDir = racer.shape:getAt()
			--location.z = location.z + 1.4 -- Offset higher
			--print(location.z)
			locMovement = sm.vec3.lerp(camLoc,location,dt*2)	
			dirMovement = sm.vec3.lerp(camDir,carDir,dt)
			--print(dirMovement)
			sm.camera.setDirection(dirMovement)
			locMovement.z = location.z +4
			sm.camera.setPosition(locMovement)
		else
			--print(camLoc.z,objLoc.z)
			locMovement = sm.vec3.lerp(camLoc,objLoc,dt*3)	
			dirMovement = sm.vec3.lerp(camDir,objDir,dt*3)
			--print(dirMovement)
			sm.camera.setDirection(dirMovement)
			sm.camera.setPosition(locMovement)
		end
			
		
	end
end

-- Camera Control Documentation
--[[
	'E' - Exits camera
	* While in normal camera *
	1-0 | Focus on racer Index 
	'W' | Cycle Focus to next place +1 (Stops at Last)
	'S' | Cycle Focus to next place -1 (Stops at First)
	'A' | Cycle Focus to next index +1 (Stops at Last)
	'D' | Cycle Focus to next index -1 (Stops at First)

	* While in Drone Mode *
	1-0 | Focus on racer Index 
	'W' | Cycle Focus to next place +1 (Stops at Last)
	'S' | Cycle Focus to next place -1 (Stops at First)
	Scroll Wheel | Adjust Drone Height


	Zoom in and out with   Left and right click? (Smooth FOV?) -- PLANED, so far, camera cycle is left/right
	!Space Bar is activator for different controlls!
	Space +:
	1-0 Select SPecific place
	E - Toggles Drone Camera

	Left/Right click: Toggle race control status forward/backward
	Overhead Drone Controls? WASD?

	Eventually have toggling for certain algorithms to automatically cycle cameras when a certain car/obj is close to them (EX: constantly following first place around the track)
	Shift +:
	1-0 Select Specific Camera
]]