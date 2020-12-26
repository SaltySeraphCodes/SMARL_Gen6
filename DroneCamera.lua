DroneCamera = class()
DroneCamera.maxParentCount = -1
DroneCamera.maxChildCount = -1
DroneCamera.connectionInput = sm.interactable.connectionType.logic
DroneCamera.connectionOutput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
DroneCamera.colorNormal = sm.color.new(0x666666ff)
DroneCamera.colorHighlight = sm.color.new(0x888888ff)
if  sm.isHost then -- Just avoid anythign that isnt the host for now
	dofile "racerData.lua"
end
--dofile "CameraController.lua"

function DroneCamera.server_onCreate( self ) 
	print("Drone Create")
end
 

function DroneCamera.client_init( self ) 
	--if  not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	self.cameraID = self.shape.id
	self.active = false
	self.power = 0
	self.followCar = 1
	self.velocity = nil
	self.location = nil
	print("Drone Camera Created",self.cameraID)
	table.insert( droneCamera,self)
end

function DroneCamera.server_onRefresh( self )
	
	self:client_onDestroy()
	--if  not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	dofile "racerData.lua"
	self:client_init()
end

function DroneCamera.client_onCreate(self)
	--if  not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	self:client_init()
end



function DroneCamera.client_onDestroy(self)
	--if  not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	for k, v in pairs(droneCamera) do
		if v.cameraID == self.cameraID then
			--print("removed")
			table.remove(droneCamera, k)
			return
		end
	end
end


function DroneCamera.setPower(self,power) -- Has a builtin failsafe in case power suddennly gets shut off
	--print(power)

	if power == nil or self.power == nil then
		--print("no power set")
		return
	end
	self.power = power
end

function DroneCamera.setFocus(self,racePos)
	print("Setting droneFocus on Pos: ",racePos)
	local racerID = getIDFromPos(racePos)
	--print("Setting focus On CarID:",racerID)
	self:setPower(racePos)
	self.followCar = racerID
end

function DroneCamera.client_onInteract(self, char, state)
	--if  not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	print("DroneCameraInteract",char,state)
	sm.localPlayer.getPlayer():getCharacter():setLockingInteractable(nil)
	sm.camera.setCameraState(1)
	--print("Cameras:",DroneCameras)
	--sm.localPlayer.getPlayer():getCharacter():setLockingInteractable(nil)
	--sm.camera.setCameraState(1)
	--self.active = false
	--if state and #self.interactable:getParents() == 0 then
		--self.active = true
		--self.current_dir = char:getDirection()
		--sm.camera.setCameraState(2)
		--sm.camera.setPosition(self.shape:getWorldPosition())
		--char:setLockingInteractable(self.interactable)
	--end
end

function DroneCamera.server_onFixedUpdate(self,dt)
	--if  not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	self.location = sm.shape.getWorldPosition(self.shape)
	self.velocity = sm.shape.getVelocity(self.shape)
	if self.power ~= self.interactable.power then
		--print("Setting Power",self.interactable.power)
		self.interactable:setPower(self.power)
	end
	--self:hover()
	--print("isnum",sm.interactable.isNumberType(self.interactable))
end

function DroneCamera.client_onAction(self, movement, state)
	--if  not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	print("raceCam",movement,state)
	if movement == 0 then
		--none
		--sm.camera.setPosition(sm.localPlayer.getPlayer():getCharacter():getWorldPosition() + sm.vec3.new(0, 0, 0))
	elseif movement == 1 then
		self.left = state
	elseif movement == 2 then
		self.right = state
	elseif movement == 3 then
		self.forward = state
	elseif movement == 4 then
		self.backward = state
	elseif (movement == 15 or movement == 17) and state then
		print("set false")
		self:setActivity(false)
		sm.localPlayer.getPlayer():getCharacter():setLockingInteractable(nil)
		sm.camera.setCameraState(1)
		
	elseif movement == 20 then
		self.speed = math.min(self.max, self.speed + self.step)
		print(self.speed)
	elseif movement == 21 then
		self.speed = math.max(self.min, self.speed - self.step)
		print(self.speed)
	end
end

function DroneCamera.setActivity(self,active)
	--if  not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	print(self.cameraID,"Settig activeity",active)
	self.active = active

end