RaceCamera = class()
RaceCamera.maxParentCount = -1
RaceCamera.maxChildCount = -1
RaceCamera.connectionInput = sm.interactable.connectionType.logic
RaceCamera.connectionOutput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
RaceCamera.colorNormal = sm.color.new(0x666666ff)
RaceCamera.colorHighlight = sm.color.new(0x888888ff)
if  sm.isHost then -- Just avoid anythign that isnt the host for now
	dofile "racerData.lua"
end
--dofile "CameraController.lua"

function RaceCamera.server_onCreate( self ) 
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end 
	print("ServerCreate")
end
 

function RaceCamera.client_init( self ) 
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end 
	self.cameraID = self.shape.id
	self.active = false
	self.power = 0
	print("Race Camera Created",self.cameraID)
	table.insert( raceCameras,self)
end

function RaceCamera.server_onRefresh( self )
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end 
	self:client_onDestroy()
	dofile "racerData.lua"
	self:client_init()
end

function RaceCamera.client_onCreate(self)
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end 
	self:client_init()
end



function RaceCamera.client_onDestroy(self)
	for k, v in pairs(raceCameras) do
		if v.cameraID == self.cameraID then
			--print("removed")
			table.remove(raceCameras, k)
			return
		end
	end
end


function RaceCamera.setPower(self,power) -- Has a builtin failsafe in case power suddennly gets shut off
	--print(power)

	if power == nil or self.power == nil then
		--print("no power set")
		return
	end
	self.power = power
end

function RaceCamera.setFocus(self,racePos)
	--print("setting Focus",self)
	--print("Setting CamFocus on Pos: ",racePos)
	local racerID = getIDFromPos(racePos)
	--print("Setting focus On CarID:",racerID)
	self:setPower(racePos)
end

function RaceCamera.client_onInteract(self, char, state)
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end 
	print("raceCameraInteract",char,state)
	sm.localPlayer.getPlayer():getCharacter():setLockingInteractable(nil)
	sm.camera.setCameraState(1)
	--print("Cameras:",raceCameras)
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

function RaceCamera.server_onFixedUpdate(self,dt)
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end 
	if self.power ~= self.interactable.power then
		--print("Setting Power",self.interactable.power)
		self.interactable:setPower(self.power)
	end
	--print("isnum",sm.interactable.isNumberType(self.interactable))
end

function RaceCamera.client_onAction(self, movement, state)
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
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

function RaceCamera.setActivity(self,active)
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end 
	print(self.cameraID,"Settig activeity",active)
	self.active = active

end