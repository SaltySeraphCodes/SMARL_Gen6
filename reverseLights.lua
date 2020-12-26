-- Copyright (c) 2019 Seraph --
--dofile "../Libs/GameImprovements/interactable.lua"
-- read in racerData
if  sm.isHost then -- Just avoid anythign that isnt the host for now
	dofile "racerData.lua"
end
-- Turns on when car is reversing
-- 
-- reverseLights.lua --
ReverseLights = class( nil )
ReverseLights.maxChildCount = -1
ReverseLights.maxParentCount = -1
ReverseLights.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
ReverseLights.connectionOutput =sm.interactable.connectionType.logic
ReverseLights.colorNormal = sm.color.new( 0xeeeeeeff )
ReverseLights.colorHighlight = sm.color.new( 0xeeeeefff )
ReverseLights.poseWeightCount = 2


function ReverseLights.client_onCreate( self ) 
	--if  not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	self:client_init()
end

function ReverseLights.client_onDestroy(self)
	
end

function ReverseLights.client_init( self ) 
	--if  not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	self.id = self.shape.id
	self.racerID = nil
	self.active = false
end

function ReverseLights.client_onRefresh( self )
	--if  not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	self:client_onDestroy()
	dofile "racerData.lua"
	self:client_init()

end

function ReverseLights.setLights(self)
	if self.active ~= self.interactable.isActive then
		self.interactable:setActive(self.active)
	end
end

function ReverseLights.calculateSpeedStatus(self)
	--if  not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	--local boost = getBoost(self.racerID)
	local status = getStatus(self.racerID)
	if status == -1 then
		if self.active ~= true then
			self.active = true
		end
	else
		if self.active ~= false then
			self.active = false
		end
	end
	self:setLights()
end

function ReverseLights.server_onFixedUpdate( self, timeStep )
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end	
	local parents = self.interactable:getParents()
	for k=1, #parents do local v=parents[k]--for k, v in pairs(parents) do
		local typeparent = v:getType()
		local parentColor =  tostring(sm.shape.getColor(v:getShape()))
		self:calculateSpeedStatus()
		if tostring(v:getShape():getShapeUuid()) == "efbd14a8-f896-4268-a273-b2b382db520c" and parentColor == "eeeeeeff" then --  white numberBlock: set racerID
			if v.power ~= self.racerID then
				self.racerID = v.power
				--print("Reverse Lights racerId:",self.racerID)
			end
		elseif tostring(v:getShape():getShapeUuid()) == "9805e02d-d987-4f64-9b64-2fb4177e2372"  then -- Engine Controller,
			
		end
		
	end
	
end