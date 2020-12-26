-- Copyright (c) 2019 Seraph --
--dofile "../Libs/GameImprovements/interactable.lua"
-- read in maps
if  sm.isHost then -- Just avoid anythign that isnt the host for now
	dofile "racerData.lua"
end
-- This will be the main logical brain that should control other parts of the car based off of speed/turn angle, will output different number combinations for acceleration/Turn angle
-- Should interact with other cars as well
-- CarBrain.lua --
PositionDisplay = class( nil )
PositionDisplay.maxChildCount = -1
PositionDisplay.maxParentCount = -1
PositionDisplay.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
PositionDisplay.connectionOutput =sm.interactable.connectionType.power
PositionDisplay.colorNormal = sm.color.new( 0x0e8031ff )
PositionDisplay.colorHighlight = sm.color.new( 0x0e803fff )
PositionDisplay.poseWeightCount = 2


function PositionDisplay.client_onCreate( self ) 
	self:client_init()
	
end

function PositionDisplay.client_onDestroy(self)
	
end

function PositionDisplay.client_init( self ) 
	self.id = self.shape.id
	self.racerID = nil
	self.position = 0
end

function PositionDisplay.client_onRefresh( self )
	self:client_onDestroy()
	--Readfile()
	self:client_init()

end

function PositionDisplay.setPos(self)
	if self.position ~= self.interactable.power then
		self.interactable:setPower(self.position)
	end
end
function PositionDisplay.calculatePosition(self)
	--print("calcPos")
	local pos = getPosition(self.racerID)
	--print("POS",pos)
	if pos == nil then print(racerData) end -- Quick Reset
	if self.position ~= pos then
		self.position = pos
	end
	self:setPos()
end
--dofile "test.lua"
function Readfile()
	print()
	local file = dofile("../Scripts/test.lua")
	print(file)
end
function PositionDisplay.server_onFixedUpdate( self, timeStep ) -- Maybe only update every once in awhile instead of onfixed update?
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	local parents = self.interactable:getParents()
	self:calculatePosition()
	--print("break boost",boost)

	for k=1, #parents do local v=parents[k]--for k, v in pairs(parents) do
		local typeparent = v:getType()
		local parentColor =  tostring(sm.shape.getColor(v:getShape()))
		--print(parentColor)

		if tostring(v:getShape():getShapeUuid()) == "efbd14a8-f896-4268-a273-b2b382db520c" and parentColor == "eeeeeeff" then --  white numberBlock: set racerID
			if v.power ~= self.racerID then
				self.racerID = v.power
				--print("Position Display id:",self.racerID)
			end
		elseif tostring(v:getShape():getShapeUuid()) == "9805e02d-d987-4f64-9b64-2fb4177e2372"  then -- Engine Controller,
		end
		
	end
	
end