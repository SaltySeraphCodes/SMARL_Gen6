if  sm.isHost then -- Just avoid anythign that isnt the host for now
	dofile "racerData.lua"
	dofile "mapCps.lua"
end
RaceControl = class( nil )
RaceControl.maxParentCount = -1
RaceControl.maxChildCount = -1
RaceControl.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
RaceControl.connectionOutput = sm.interactable.connectionType.power +  sm.interactable.connectionType.logic
RaceControl.colorNormal = sm.color.new( 0xFF00ccff  )
RaceControl.colorHighlight = sm.color.new( 0xF2F2F2ff  )
RaceControl.poseWeightCount = 2
--RaceControl.racerData = 
--print(tostring(RaceControl.colorNormal))
-- set contains helper lol:

function setContains(set, key)
	return set[key] ~= nil 
end
function RaceControl.server_onCreate( self ) 
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	self:server_init()
	print("Race control")
	
end
 

function RaceControl.readChat(self)

end

function RaceControl.server_init( self ) 
	local ingameReset = true
	if ingameReset then
		doubleCheckQualPos()
		setQualifyingPositions()
	end
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	self.clock = 0.3 -- 0.5 for day, 0 or 1 for night
	self.timeStep = 0--0.00001 -- How fast a day goes
	self.outputTimer = 0
	self.started = 0
	self.initialized = 0
	self.globalTimer = 0
	self.gotTick = false
	self.outputedRaceData = false
	self.outputedQualData = false
	self.formation = false
	self.allGreen = false

	-- Qualifying Session Data
	self.currentQualifyingIndex = 1 -- index of of car [racerData] that is qualifying
	self.currentQualifyingCar = nil -- Racer data of qualifying car?
	self.qualifyingSessionFinished = false
	-- Eror sateetes
	self.raceControlError = false
	print("race Control INit")
end

function RaceControl.server_onRefresh( self )
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	--calculateQualifyingPos()
	self:server_init()
end

function RaceControl.client_onCreate(self)
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
end

function RaceControl.sendQualifyingData(self)
	if self.gotTick and self.globalTimer % 5 == 0 then 
		--outputQualifyingData() -- Log Data for race control (can be moved anywhere)
	end
end

function RaceControl.sendFinishData(self)
	if self.gotTick and self.globalTimer % 5 == 0 then 
		--outputFinishData()
	end
end

function RaceControl.sendRacerCameraData(self) -- Outputs the racer Information every 10 seconds, To store in separate table to know proper car IDs
	if self.gotTick and self.globalTimer % 15 == 0 then 
		--outputRacerCameraData()
		--outputData() -- Log Data for race control (can be moved anywhere)
	end
end
function RaceControl.sendData(self)
	if self.gotTick then 
		--outputData() -- Log Data for race control (can be moved anywhere)
	end
end

function RaceControl.regulateQualifyingSession(self)
	local runningRacer = getCurrentQualifier()
	--print(runningRacer)
	local totalRacers = #racerData
	if self.currentQualifyingIndex > totalRacers then
		self.raceControlError = true
		print("Something went wrong With Qualifying index",self.currentQualifyingIndex)
		return
	end
	--if runningRacer == nil and not self.raceControlError then
	--	self.raceControlError = true
	--	print("Error starting qualifier session")
	--	return
	--print(runningRacer)
	if runningRacer == nil then
		print("Something wong")
		return
	end
	if runningRacer == 0 then
		--self.raceControlError = false
		print("Starting Qualifying Session")
		self.qualifyingSessionFinished = false
		self.currentQualifyingIndex = 1
		local firstRacer = racerData[1]
		if firstRacer == nil then
			print("Could not find Racers")
			self.raceControlError = true
			return
		end
		setCurrentQualifier(firstRacer)
		--print(runningRacer,getCurrentQualifier())
	else
		if self.qualifyingSessionFinished then return end -- Shortcut not qualifying
		local qualifyingRacer = racerData[self.currentQualifyingIndex]
		if qualifyingRacer == nil then
			print("Error when getting qualifying racer",self.currentQualifyingIndex)
			return
		else
			if runningRacer ~= qualifyingRacer then
				--print("Setting newQ",qualifyingRacer.racerID)
				setCurrentQualifier(qualifyingRacer)
			end
			if qualifyingRacer.finishedRace then
				--print(qualifyingRacer.racerID,"Finished Qualifying")
				if self.currentQualifyingIndex >= totalRacers then
					--print("Finished Qualifying Session")
					self.qualifyingSessionFinished = true
					-- Set raceStatus to 0?
					return
				else
					self.currentQualifyingIndex = self.currentQualifyingIndex + 1
					print("Sending Next Car Off",self.currentQualifyingIndex,totalRacers)
					if self.currentQualifyingIndex > totalRacers then
						print("Something went wrong")
					end
				end
			end
		end
	end
end

function RaceControl.server_onFixedUpdate(self, dt)
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	if self.interactable ~= nil then
		local myColor = tostring(sm.shape.getColor(self.interactable:getShape()))
	end
	
	local parents = self.interactable:getParents()
	local children = self.interactable:getChildren() 
	--aprint(#children)
	for k=1, #parents do local v=parents[k]--for k, v in pairs(parents) do
		local typeparent = v:getType()
		local parentColor =  tostring(sm.shape.getColor(v:getShape()))
		--print(parentColor)
		--if tostring(v:getShape():getShapeUuid()) == "efbd14a8-f896-4268-a273-b2b382db520c" and parentColor == "eeeeeeff" then -- If the parent is a white numberBlock
			local raceStatus = getRaceStatus()
			--print("raceStat",getRaceStatus)
			if raceStatus >= 1 then 
				self:sendData()
			end -- Add sendata for caution
			
			if raceStatus <= 0 then
				self:sendQualifyingData()
			end
			if raceStatus == 0 then
				self:sendRacerCameraData()
			end
			if raceStatus == -1 then
				self:regulateQualifyingSession()
			end
			if raceStatus == 2 then
				--self:sendFinishData()
			end
			if raceStatus == 1 then
				local inLine = checkFormation()
				self.formation = getFormationStatus()
				if inLine and not self.formation then
					print("Got all racers in formation!")
					setFormationStatus(true)
				end
				if inLine and self.formation then
					local firstPlaceCar = getRacerData(getIDFromPos(1))
					if firstPlaceCar == nil then
						print("No first place car")
						return
					end
					if firstPlaceCar.inFormationPlace then
						local allGreen = checkRacerinFormation() -- Checks if racers are all in good order
						if allGreen and self.allGreen == false then -- and not self.allGreen -- Sets greenflag if all is good
							print("Allracers are Good to go!")
							self.allGreen = true
						end

							--setRaceStatus(2)
					end
				end

			end
			if raceStatus ~= self.raceStatus then
				print("Set raceStatus",raceStatus)
				if raceStatus == 2 then 
					self.started = raceTimer()
				end
				if raceStatus == 0 then
					self.initialized = raceTimer()
				end
				--setRaceStatus(raceStatus)
				self.raceStatus = raceStatus
			end
		
		if parentColor == "222222ff" then-- If black, reset Button
			local power = v:getPower()
			if power == 1 then
				resetQualifyingData()
			end

		end
		
	end

end	

function RaceControl.client_onFixedUpdate( self, dt )
	if self.clock then
		self.clock = self.clock + self.timeStep
		sm.render.setOutdoorLighting(self.clock)
		if self.clock >=1 then
			self.clock = 0
		end
	end
	if self.started == nil then -- loading issues
		return
	end
	self.color = tostring(sm.shape.getColor(self.interactable:getShape()))
	local now = raceTimer()
	local floorCheck = math.floor(now - self.started)
	--print(floorCheck,self.globalTimer)
	if self.globalTimer ~= floorCheck then
		self.gotTick = true
		self.globalTimer = floorCheck
	else
		self.gotTick = false
		self.globalTimer = floorCheck
	end
end