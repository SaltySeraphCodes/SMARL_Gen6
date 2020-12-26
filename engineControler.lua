-- Copyright (c) 2019 Seraph--
--dofile "mapCPs.lua"
if  sm.isHost then -- Just avoid anythign that isnt the host for now
	dofile "racerData.lua"
end
-- engineControler.lua --
engineControler = class( nil )
engineControler.maxChildCount = -1
engineControler.maxParentCount = -1
engineControler.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
engineControler.connectionOutput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
engineControler.colorNormal = sm.color.new( 0x76034dff )
engineControler.colorHighlight = sm.color.new( 0x8f2268ff )
engineControler.poseWeightCount = 2


function engineControler.server_onCreate( self ) 
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	--print("Oncreate")
	self:server_init()
	
end

function engineControler.server_init( self ) 
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	--print("Creating engine controller ")
	self.power=  0
	self.racerID = 0
	self.failsafe = false
end

function engineControler.client_onRefresh( self )
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	print()
	--dofile "mapCPs.lua"
	--dofile "racerData.lua"
	self:server_onCreate()
end


function engineControler.setPower(self,power) -- Has a builtin failsafe in case power suddennly gets shut off
	--print(power)
	if power == 0.69420 then
		--print("Refreshing engineCOntroler")
		self:client_onRefresh()
		return
	end
	if power == nil or self.power == nil then
		return
	end
	if (power >=0 and power <= 1000) and self.power > 1000 then 
		if not self.failsafe then 
			self.failsafe = true
			--print("failsafe")
		end
		self.power = self.power-32
	else
		self.power = power
	end
	local hit,distance = sm.physics.distanceRaycast(sm.shape.getWorldPosition(self.shape),self.shape.at*20)
	--print(hit,distance)
	if distance <= 0.04 then
		--print('Actual collision')
		self.power = self.power-40
	end
	if self.power ~= self.interactable.power then
		--print(self.power,self.interactable.power)
		self.interactable:setPower(self.power)
	end
end

function getStatusFromVelocity(velocity)
	local status = 0 -- parsing: 0 = stoped, 1 = moving
	if math.abs(velocity.y) <= 1 and math.abs(velocity.x) <= 1 then
		status = 0
	else
		status = 1
	end
	return status
end


function engineControler.server_onFixedUpdate( self, timeStep )
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	
	local parents = self.interactable:getParents()

	--print("hello",parents)
	for k=1, #parents do local v=parents[k]--for k, v in pairs(parents) do
		local typeparent = v:getType()
		local parentColor =  tostring(sm.shape.getColor(v:getShape()))
		if tostring(v:getShape():getShapeUuid()) == "efbd14a8-f896-4268-a273-b2b382db520c" and parentColor == "eeeeeeff" then --White numberBlock = set racerID
			if v.power ~= self.racerID then
				self.racerID = v.power
				self.data = getRacerData(self.racerID) -- Racer Data
			end
		end
	end
	-- GEt a quickcheck of whats uprfornt
	
	-- Read and set controllerData
	if self.data == nil then
		return
	else
		self:setPower(self.data.enginePower)
	end
end