-- Copyright (c) 2019 Seraph --
--dofile "../Libs/GameImprovements/interactable.lua"
-- read in maps
if  sm.isHost then -- Just avoid anythign that isnt the host for now
	dofile "racerData.lua"
end
-- Reverse Lights
-- Turns on when car starts braking
BreakLights = class( nil )
BreakLights.maxChildCount = -1
BreakLights.maxParentCount = -1
BreakLights.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
BreakLights.connectionOutput =sm.interactable.connectionType.logic
BreakLights.colorNormal = sm.color.new( 0x7c0000ff )
BreakLights.colorHighlight = sm.color.new( 0x7c000fff )
BreakLights.poseWeightCount = 2


function BreakLights.client_onCreate( self ) 
	self:client_init()
end

function BreakLights.client_onDestroy(self)
	
end

function BreakLights.client_init( self ) 
	self.id = self.shape.id
	self.racerID = nil
	self.active = true
end

function BreakLights.client_onRefresh( self )
	self:client_onDestroy()
	dofile "racerData.lua"
	self:client_init()

end

function BreakLights.setLights(self)
	if self.active ~= self.interactable.isActive then
		self.interactable:setActive(self.active)
	end
end

function BreakLights.calculateBrakeStatus(self)
	local brakes = getBrakes(self.racerID)
	local status = getStatus(self.racerID)
	if brakes > 0 or status == 0 then
		if self.active ~= true then
			self.active = true
			--print("breaking")
		end
	else
		if self.active ~= false then
			self.active = false
			--print("not braking")
		end
	end
	self:setLights()
end

function BreakLights.server_onFixedUpdate( self, timeStep )
	--[[if not sm.isHost then -- Just avoid anythign that isnt the host for now
		return
	end]]
	local parents = self.interactable:getParents()
	self:calculateBrakeStatus()
	for k=1, #parents do local v=parents[k]--for k, v in pairs(parents) do
		local typeparent = v:getType()
		local parentColor =  tostring(sm.shape.getColor(v:getShape()))
		if tostring(v:getShape():getShapeUuid()) == "efbd14a8-f896-4268-a273-b2b382db520c" and parentColor == "eeeeeeff" then --  white numberBlock: set racerID
			if v.power ~= self.racerID then
				self.racerID = v.power
				--print("Break Lights racerId:",self.racerID)
			end
		elseif tostring(v:getShape():getShapeUuid()) == "9805e02d-d987-4f64-9b64-2fb4177e2372"  then -- Engine Controller,
		end
		
	end
	
end