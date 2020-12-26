DroneControl = class()
DroneControl.maxParentCount = -1
DroneControl.maxChildCount = -1
DroneControl.connectionInput = sm.interactable.connectionType.logic
DroneControl.connectionOutput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
DroneControl.colorNormal = sm.color.new(0x666666ff)
DroneControl.colorHighlight = sm.color.new(0x888888ff)
if  sm.isHost then -- Just avoid anythign that isnt the host for now
	dofile "racerData.lua"
end
function DroneControl.server_onCreate( self ) 
	if not sm.isHost then -- Just avoid anythign that isnt the host for now
		return
	end
	print("Drone Create")
end
 

function DroneControl.client_init( self )
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end 
	self.cameraID = self.shape.id
	self.active = false
	self.power = 0
	self.followCar = nil
	self.hoverHeight = 35
	self.velocity = nil
	self.location = nil
	self.hasError = false
	print("Drone Control Created",self.cameraID)
	table.insert( droneInfo,self)
end

function DroneControl.server_onRefresh( self )
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
		--return
	--end
	self:client_onDestroy()
	dofile "racerData.lua"
	self:client_init()
end

function DroneControl.client_onCreate(self)
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
		--return
	--end
	self:client_init()
end



function DroneControl.client_onDestroy(self)
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
		--return
	--end
	for k, v in pairs(droneInfo) do
		if v.cameraID == nil then
			print("error in DroneInfo table")
			return
		end
		if v.cameraID == self.cameraID then
			table.remove(droneInfo, k)
			return
		end
	end
end


function DroneControl.setPower(self,power) -- Has a builtin failsafe in case power suddennly gets shut off
	--print(power)

	if power == nil or self.power == nil then
		--print("no power set")
		return
	end
	self.power = power
end

function DroneControl.setFocus(self,racer)
	print("Setting droneFocus on Pos: ",racePos)
	local racerID = getIDFromPos(racePos)
	--print("Setting focus On CarID:",racerID)
	self:setPower(racePos)
	self.followCar = racerID
end


function DroneControl.setFollow(self,racer)
	print("Setting droneFocus on racer: ",racer.racerID)
	if racer == nil then
		print("BAD ERROR")
	end
	self.followCar = racer.racerID
end

function DroneControl.changeHeight(self,height) -- Changes hover height 
	print("Changing drone height to",height)
	self.hoverHeight = height -- Possibly make smoother?? or set hover speed based on distance away
end

function DroneControl.client_onInteract(self, char, state)
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	print("DroneControlInteract",char,state)
	sm.localPlayer.getPlayer():getCharacter():setLockingInteractable(nil)
	sm.camera.setCameraState(1)
end

function DroneControl.server_onFixedUpdate(self,dt)
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	self.location = sm.shape.getWorldPosition(self.shape)
	self.velocity = sm.shape.getVelocity(self.shape)
	
	if self.power ~= self.interactable.power then
		--print("Setting Power",self.interactable.power)
		self.interactable:setPower(self.power)
	end
	local parents = self.interactable:getParents()
	for k=1, #parents do local v=parents[k]--for k, v in pairs(parents) do
		local typeparent = v:getType()
		local parentColor =  tostring(sm.shape.getColor(v:getShape()))
		self.followCar = v.power
	end 
	self:hover()
	--print(self.velocity.z)
	if math.abs(self.velocity.z) < 4 then 
		self:followRacer()
	end
	--print("isnum",sm.interactable.isNumberType(self.interactable))
end

function DroneControl.hover(self) -- Hovers drone at certain height set by self.hoverHeight
	local hoverHeight = self.hoverHeight
	local heightAdjust = -20
	local maxThrust = 0.02
	local limit = 180
	--if self.location.z - hoverHeight > 1 then
	heightAdjust =  (self.location.z-hoverHeight)/maxThrust*-1
	if heightAdjust < 140 then
		heightAdjust = 140
	end
	--end
	if heightAdjust > limit then
		heightAdjust = limit + 5
	end
	--print(heightAdjust,hoverHeight,self.location.z)
	--print(self.location.z - hoverHeight, (self.location.z-hoverHeight)/maxThrust*-1,heightAdjust)
	local hoverVec = sm.vec3.new(0,0,heightAdjust)
	--print("correcting tilt")
	sm.physics.applyImpulse( self.shape.body, hoverVec, true)
	--print(self.velocity)
end

function DroneControl.followRacer(self) -- Makes drone follow a racer
	local racer =  getRacerData(self.followCar)
	if racer == nil then racer = racerData[1]
		if racer == nil or racer.racerID == 0 then 
			if self.hasError == false then
				print("Drone: No racers found")
			end
			racer = {['racerID'] = 0, ['location']=sm.vec3.new(0,0,30), ['brakePower'] = 0, ['dirVel'] =0 } -- Just a dummy data
			self.hasError = true
		else
			self.hasError = false
		end
			self.followCar = racer.racerID
	end
	if racer.racerID == nil then
		if self.hasError == false then
			print("Malformed racer",racer)
			print("Drone Read bad racer",racer.racerID)
			self.hasError = true
		end
	end
	--print(self.followCar)
	--print(racer.location,self.locatio20
	local multiplier = 1
	local locationDif = (racer.location - self.location)
	local distance = (sm.vec3.length2(locationDif)) 
	local selfSpeed = sm.vec3.length2(self.velocity)
	--print(locationDif)
	if distance < 500 then
		multiplier = 0.5
	end
	if distance > 3000 then
		multiplier = 5
	end
	if multiplier > 6000 then
		multiplier = 10
	end
	if multiplier > 10000 then
		multiplier = 15
	end
	local locationVec = sm.vec3.new(locationDif.x,locationDif.y,0) * multiplier
	 
	
	
	
	--print(distance,selfSpeed)
	if selfSpeed > 2000 then
		locationVec = locationVec/ (selfSpeed-2000 )
	end

	--print(selfSpeed)

	--print(racer.dirVel,racer.speed,racer.brakePower)
	if racer.brakePower > 100  and selfSpeed > 300 and distance < 6000 then
		locationVec = self.velocity * -5
	end
	--print(distance)
	if racer.dirVel < 10 and selfSpeed > 30 and distance < 800 then
		--print("slowing")
		locationVec = self.velocity * -5
	end
	if racer.velocity == nil then
		racer.velocity = sm.vec3.new(0,0,0)
	end

	local movementVec = racer.velocity * 3 -- TODO, add multiplier?
	--print(movementVec)
	
	sm.physics.applyImpulse( self.shape.body, locationVec, true)
	
	sm.physics.applyImpulse( self.shape.body, movementVec, true)

end

function DroneControl.client_onAction(self, movement, state)
	print("Drone Control",movement,state)
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
		--print("set false")
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

function DroneControl.setActivity(self,active)
	print(self.cameraID,"Settig activeity",active)
	self.active = active

end