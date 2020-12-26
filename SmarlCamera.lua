SmarlCamera = class()

function SmarlCamera.client_onCreate( self )
	self:client_init()
end

function SmarlCamera.client_init( self )
	self.angle = 0
	self.offsetPos = 0
	self.zoomStrength = 60
	self.teleports = sm.cameraMaps.maps
	self.curMapID = sm.cameraMaps.curID
	self.allCams = self.teleports[self.curMapID]
	self.curCamID = 1
	self.curCam = self.allCams[self.curCamID]
	self.zooming = false
	self.zoomoutg = false
	self.zoomSpeed = 0.1
	self.zoomAccel = 0.001
	self.raceStatus = 0
	self.gameWorld = sm.world.getCurrentWorld()
	self.player = sm.localPlayer.getPlayer()
	self.character = self.player:getCharacter()
	--print(self.player)
	self.location = self.character:getWorldPosition()
	self.primaryState = false
	self.secondaryState = false
	print("Smarl camera loaded",self.player,self.location)
	self.freeCamLocation = self.location
	self.freeCamDirection = sm.camera.getDirection()
	self.freeCamActive = false
end 

function SmarlCamera.server_createCam(self,player)
	local cam = self.curCam
	print("teleporting to",self.curCam)
	local normalVec = sm.vec3.normalize(self.freeCamDirection)
	local degreeAngle = math.atan2(normalVec.x,normalVec.y) --+ 1.5708 -- Hopefully accounts for xaxis woes, could switch y and x
	local newChar = sm.character.createCharacter( player, self.gameWorld, sm.vec3.new(cam.x,cam.y,cam.z), -degreeAngle)--cam.angle )	
	self.character = newChar
	player:setCharacter(newChar)

end


function SmarlCamera.server_teleportPlayer(self,location)
	print("teleporting to",location)	
	local player = self.player
	local normalVec = sm.vec3.normalize(self.freeCamDirection)
	local degreeAngle = math.atan2(normalVec.x,normalVec.y) --+ 1.5708 -- Hopefully accounts for xaxis woes, could switch y and x
	local newChar = sm.character.createCharacter( player, self.gameWorld,location,-degreeAngle)
	self.character = newChar
	player:setCharacter(newChar)

end

function SmarlCamera.client_onRefresh( self )
	print("refresh smarlCam")
	self:client_init()
end

function SmarlCamera.client_onWorldCreated( self, world )
	print("created world",world)
end


function SmarlCamera.client_onEvent( self, world )
	print("OnEvenr",world)
end

function SmarlCamera.client_onToggle(self, backwards)
	local dir = 1
	if backwards then
		dir = -1
	end
	self:toggleCamera(dir)
	
end

function SmarlCamera.switchCam(self,cam) -- Actually does the teleporting
	local player = self.player
	self.network:sendToServer( "server_createCam", player)
	
end


function SmarlCamera.teleportCharacter(self,location) -- teleports character to vec3 location
	self.network:sendToServer( "server_teleportPlayer", location)
end

function SmarlCamera.toggleCamera(self,dir) -- Determines next Cam and then causes telepoirt dir [-1,1] direction in list of cams
	local totalCam = #self.allCams
	local curCamID = self.curCamID

	local nextCamID = ((curCamID + dir) % totalCam)
	if nextCamID == 0 then nextCamID = totalCam end -- Wrap fix
	local nextCam = self.allCams[nextCamID] 
	self.curCamID = nextCamID
	self.curCam = nextCam
	self:switchCam(nextCam)
	---print("Toggleing",dir,curCamID,"next:",nextCamID)
	--self:setZoom(self.curCam.zoom)
end


function SmarlCamera.client_onEquip( self )
	print("on SMARL CONtoller Tool",self.location)
	sm.audio.play( "PotatoRifle - Equip" )

end

function SmarlCamera.client_onUnequip( self )

end


function SmarlCamera.client_onPrimaryUse( self, state )
	print("test")
	if state == 1 then
		self.zooming = true
	elseif state == 2 then
		self.zoomAccel = self.zoomAccel + 0.003
		self.accelZoom = true
	elseif state == 0 then
		self.zooming = false
		self.zoomAccel = 0
		self.zoomSpeed = 0.1
		self.accelZoom = false
	end
	
	return true
end

function SmarlCamera.client_onSecondaryUse( self, state )
	print('help')
	sm.camera.setCameraPullback( 1, 1 )
	if state == 1 then
		self.zoomoutg = true
	elseif state == 2 then
		self.zoomAccel = self.zoomAccel + 0.003
		self.accelZoom = true
	elseif state == 0 then
		self.zoomoutg = false
		self.zoomAccel = 0
		self.zoomSpeed = 0.1
		self.accelZoom = false
	end
	
	return true
end

function SmarlCamera.client_onReload(self)
	local isSprinting =  self.tool:isSprinting()
	local isCrouching =  self.tool:isCrouching() 
	local dir = 1
	local raceStatus = self.raceStatus
	--print("reload",isSprinting,isCrouching)
	if isCrouching then
		dir = -1
	end

	raceStatus = raceStatus + dir
	--print("Setting race status",raceStatus,dir)
	--print(sm.smarlFunctions)
	sm.smarlFunctions.setRaceStatus(raceStatus)
	self.raceStatus = raceStatus
	return true
end

function SmarlCamera.client_onFixedUpdate( self, timeStep )
	--print(sm.tool)
	self.location = self.character:getWorldPosition()
	self.freeCamDirection = sm.camera.getDirection()
	if not self.freeCamActive then 
		self.freeCamLocation = self.character:getWorldPosition()
	end

	local camMap = sm.cameraMaps['curID']
	if camMap ~= self.curMapID then
		--print("Changing Camera Map",camMap)
		self.curMapID = camMap
		self.curMap = self.maps[camMap]
	end
	if self.freeCamActive then
		local moveDir = self.tool:getRelativeMoveDirection()
		--print(moveDir)
		self.freeCamDirection = self.character:getDirection()
		--print(sm.vec3.length(moveDir))
		if sm.vec3.length(moveDir) == 1 then
			self.freeCamLocation = self.freeCamLocation + moveDir --+ self.freeCamDirection/2
		else
			self.freeCamLocation = self.freeCamLocation + moveDir
		end
		sm.camera.setPosition(self.freeCamLocation)
		sm.camera.setDirection(self.freeCamDirection)

	end
end

function SmarlCamera.client_onEquippedUpdate( self, primaryState, secondaryState )
	--print(primaryState,secondaryState)
	if primaryState ~= self.primaryState then
		if primaryState == 1 then
			print("left clicked",primaryState)
			self:activateFreecam()
		end
		self.primaryState = primaryState
	end

	if secondaryState ~= self.secondaryState then
		if secondaryState == 1 then
			print("right clicked",secondaryState)
			self:deactivateFreecam()
		end
		self.secondaryState = secondaryState
	end

	return true, true
end

function SmarlCamera.client_onAction(self, input, active)
	print("action",input,active)
end


function SmarlCamera.activateFreecam(self)
	print("freecam Activated")
	sm.camera.setPosition(self.location)
	sm.camera.setDirection(self.freeCamDirection)
	sm.camera.setCameraState(2)
	self.character:setLockingInteractable(self.interactable)
	self.freeCamActive = true

end


function SmarlCamera.deactivateFreecam(self)
	print("freecam Deacivated")
	self.character:setLockingInteractable(nil)
	sm.camera.setCameraState(1)
	self.freeCamActive = false
	-- teleport character
	self:teleportCharacter(self.freeCamLocation)
	

end