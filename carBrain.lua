-- SMARL CAR AI V2 
-- Copyright (c) 2020 SaltySeraph --
--dofile "../Libs/GameImprovements/interactable.lua"
-- read in maps
if sm.isHost then -- Just avoid anythign that isnt the host for now
dofile "mapCPs.lua"
dofile "racerData.lua"
dofile( "$CHALLENGE_DATA/Scripts/game/challenge_shapes.lua" )
dofile( "$CHALLENGE_DATA/Scripts/game/challenge_tools.lua" )
dofile( "$CHALLENGE_DATA/Scripts/challenge/world_util.lua" )
end
-- This will be the main logical brain that should control other parts of the car based off of speed/turn angle, will output different number combinations for acceleration/Turn angle
-- Should interact with other cars as well
-- CarBrain.lua --
-- TODO: add wal/collision correction also reduce drastic radar adjusts
Brain = class( nil )
Brain.maxChildCount = -1
Brain.maxParentCount = -1
Brain.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
Brain.connectionOutput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
Brain.colorNormal = sm.color.new( 0x76034dff )
Brain.colorHighlight = sm.color.new( 0x8f2268ff )
Brain.poseWeightCount = 2

-- (Event) Called from Game
function Brain.server_loadWorldContent( self, data )
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end 
	print("World: loadWorldContent")
	print(data)
	sm.event.sendToGame( "server_onFinishedLoadContent" )
	self.loadingWorld = false
end

function Brain.client_onCreate( self ) 
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	self.effect = sm.effect.createEffect("GasEngine - Level 3", self.interactable )
	self:client_init()
	self.effect:setParameter("gas", 1.0 )
	print("Created Car AI Brain")
end

function Brain.client_onDestroy(self)
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	self:resetTiming()
	for k, v in pairs(racerData) do
		if v.id == self.id then
			table.remove(racerData, k)
			return
		end
	end
end

function Brain.setDataFromRaceData( self )
end

function Brain.client_init( self ) 
	self.loaded = false
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	self.id = self.shape.id
	
	self.raceStatus = getRaceStatus() -- Race status, [0-4?], set/read from global file? new mod part? or wireless reciever, sent from race control, set to 2 (green flag) for now
	-- Racer Identifiers
	self.racerID = nil
	self.carData = {} -- Contains name, id, topspeed, accel, and downforce
	-- Map and checkpoint definitions
	self.mapID = nil
	if self.mapID ~= nil then -- Prevent confusion at the beginning
		print("setting mapID",self.mapID)
		self.map = mapSet[self.mapID]
		self.cpData = self.map[self.nextCP] -- The Data from next CP, TODO: determine if having one for lastCP is good
	end
	self.curCP = 1 -- Starts at 1
	self.nextCP = 1 -- ^^ -- Possibly just pool fromr acerData
		

	self.currentLap = 0 -- lap count
	self.racePosition = 0 -- Race positon
	self.cautionPosition = 0 -- Gets set whenever caution comes out
	self.totalLaps = 0 -- Set by board
	self.finishPosition = 0 -- WHat position the racer finished in

	-- timing
	self.startTime = 0
	self.splitReset = 0
	self.lastLapTime = 0
	self.bestLapTime = 0
	self.totalTime = 0
	self.timeSplit = 0

	-- Car Positional attibutes
	self.location = sm.shape.getWorldPosition(self.shape)
	self.roadPos = 0 -- gets recalculated by getRoadPosition 
	self.status = 0 -- 0 = stopped 1 = moving -1 = reverse
	self.startingRace = false
	--self.turning = 0
	self.exitTurn = false -- Obsolete
	self.running = false -- Obsolete
	self.resetCar = false -- Obsolete
	self.easyFirstCorners = true
	
	--ErrorCorrecting states
	self.correcting = false
	self.CPCorrecting = false
	self.stuck = false
	self.offTrackCor = 0
	self.carTilted = false
	self.errorTurn = false
	self.correctionTimeout = 0
	self.timeoutCounter = 0
	self.reset = false
	self.closeProx = false
	self.TCS = 0
	--movement States
	self.turnState = 0
	self.drivingState = 0 -- Driving State Enums: -1 = reverse, 0 = stopped, 1 = straight (no draft), 2 = straight(draft), 3 = passing, 4 = turning left, 5 = turning 6 = inline (formation)
	self.draftState = 0 -- 0 = no cars in range to draft, 1 = in range/to draft
	self.isDrafting = false
	self.isPassing = false
	self.launching = false
	self.finishedRace = false
	self.stop = false -- a hard stop
	self.hittingApex = false
	-- Caution attrs
	self.followCar = nil -- RacerData object
	self.inLine = false
	self.catchup = false
	self.slowDown = false
	self.uturn = 0
	self.cautionAdjust = 0
	self.carPass = 0
	self.followDistance = 16
	--Qualify attrs
	self.qualifyingSplits = {}
	self.qualifyPosition = 0
	self.qualifyingTime = nil
	-- Formation attrs
	self.formationCar = 0
	self.formationLane = 0
	self.formationFlag = false
	self.inFormationPlace = false
	self.isAligned = false
	-- Directional inputs
	self.lastDirection = 0
	self.currentDirection = 0
	self.goalDirection = 0
	
	-- Position tracking
	self.trackPos = 25 --  getTrackPos (0 = inside, 50? = outside)
	self.distFromCP = 0 -- getTrack POS returns distance from next checkpoint

	-- Car attributes
	self.topSpeedECU = 0
	self.accelECU = 0
	self.downforceECU = 0
	self.raceLinePref = 15
	self.MAX_SPEED = 8000
	-- Control \
	
	self.steeringValue = 0
	self.dirVel = 0
	self.power = 0
	self.speed = 0 -- Pulled in from engineControler power
	self.enginePower = 0 -- Our own calculated enginePower, engineController will read from this
	self.handling = 15 -- steering wheel turn limits
	self.turnLimit = 0
	self.boost = 0 -- can be sped up or slowed down depending on +- num
	self.radar = createRadar()
	self.brakePower = 0
	self.maxEngineSpeed = 0
	table.insert(racerData, self)
	--print("Car Set")
end


function Brain.client_onRefresh( self )
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	self:client_onDestroy()
	--self.effect = sm.effect.createEffect("GasEngine - Level 3", self.interactable )
	dofile "mapCPs.lua"
	dofile "racerData.lua"
	self:client_init()

end

function Brain.setCarStats(self) -- Reads and converts car data and stores it for easy ecu access
	
	local carData = getCarData(self.racerID)
	if carData == nil then
		print("Error while loading car data",self.racerID)
		return 
	end
	--print(carData)
	self.topSpeedECU = convertTopSpeedToECU(carData['TopSpeed'])
	self.accelECU = carData['Acceleration']
	self.downforceECU =  convertDownforceToECU(carData['Downforce'])
	if self.raceStatus == 2 or self.raceStatus == -1 then
		self.raceLinePref = carData['RaceLine']
	end
	if self.qualifyPosition == nil then 
		self.qualifyPosition = carData['Q']
	end
end

-- Sets Steering Value
function Brain.setSteering(self,value)
	local maxVal = 55
	local minVal = -55
	if self.carTilted ~= 0 then
		--print('cartilted') 
		return -- Dont do this
	end
	if value > maxVal then value = maxVal end
	if value < minVal then value = minVal end
	if self.turnState ~= 0 then

		--print(value)
	end

	if value ~= self.interactable.power then
		self.interactable:setPower(value)
	end
end


function movementStatus(self)
	local front = self.shape.getAt(self.shape)
	local velocity = self.shape.getVelocity(self.shape)
	local faceX = getSign(front.x)
	local faceY = getSign(front.y)
	local velX = getSign(velocity.x)
	local velY = getSign(velocity.y)

	if math.abs(velocity.x) < 0.3 and math.abs(velocity.y) < 0.3 then
		--print("stopped")
		return 0
	end

	if faceX ~= velX then 
		if faceY ~= velY then
			--print("Possibly going backwards")
			return -1
		end
	end

	if faceX == velX and faceY == velY then
		--print("Moving forward")
		return 1
	end

end


-- Car speed functions
function Brain.calculateAcceleration(self,throttleValue) -- Calculates acceleration at Throttle
	local carData = self.carData
	local velocity = self.velocity -- Or just get vel of desired direction
	local totalVel = sm.vec3.length(velocity) -- maybe move this out to function that calculates velocity
	self.dirVel = totalVel -- set this just in case
	local accelLimit = self.accelECU 
	local topSpeed =self.topSpeedECU 
	local downforce = self.downforceECU
	local handiCap = 0 
	--print(topSpeed)
	-- Sinwave acceleration: calculates how much to add to to tal power based on velocity (sinwave version)
	if not self.easyFirstCorners then 
		if self.isDrafting and self.raceStatus == 2 then -- should be set to 2, Sets the topSpeed TODO: Make switch where I can turn on or off drafting
			topSpeed = topSpeed-0.006 -- Make var??
			accelLimit = accelLimit + 0.04
		end
		
		if self.racePosition ~= 1 and self.raceStatus == 2 then 
			local multiplier = 1
			if type(self.timeSplit) == 'string' then
				multiplier = 4
			else
				multiplier = self.timeSplit /4
				if multiplier > 3.5 then
					multiplier = 3.5
				end
			end
			handiCap = multiplier
		end
		
	end
	
	if self.raceStatus == 1 or self.raceStatus == 3 then
		handiCap = 0
	end
	if self.racePosition ~= nil and self.racePosition ~= 0 and type(self.timeSplit) ~= 'string' and (self.timeSplit >= 0.9 and self.timeSplit <= 1.5 ) then -- If not  A lap down and less than a second from the leader
		--handiCap = -2 -- begin to out the playing field
	elseif self.racePosition ~= nil and self.racePosition ~= 0 and type(self.timeSplit) ~= 'string' and self.timeSplit <= 0.9 then
		--handiCap = -3 -- Even out the playing field
	end
	--handiCap = 0 
	if self.racePosition == 1 then
		handiCap = -0.7 	 -- TODO: MAke a list of global vars to use here
	end
	if self.raceStatus == -1 then
		handiCap = 1
	end
	--print(self.racerID,handiCap)
	-- TODO: Add to global vars remove when ready
	-- IF globalHandicap ~= 0, set handicap to global handicap, else use regular calculated handicap
	local nextAccel = (math.sin( topSpeed*totalVel+ downforce ) * accelLimit + handiCap) + 10 * downforce
	--print(self.racePosition,handiCap)
	--print(string.format("%i: %i %i %i %s",self.racerID, self.racePosition, handiCap, nextAccel,self.timeSplit))

	if self.launching then
		nextAccel = accelLimit + (downforce/3)
	end

	local engineCap = self.MAX_SPEED
	if self.correcting then
		engineCap = 2300
	end
	if self.raceStatus == 3 then 
		if self.catchup then 
			--print(self.racerID,"catchup",self.formationFlag)
			engineCap = 2000
		else
			engineCap = 950
		end
		if self.slowDown then 
			if self.turnState == 0 then  -- TODO: determine if this should be moved to ops
				engineCap = 500
			end
		end
	end

	if self.raceStatus == 1 then 
		if self.catchup then 
			if self.formationFlag then 
				engineCap = 1700
			else
				engineCap = 2000
			end
		else -- No catchup no slowdown
			engineCap = 1100
			if self.formationFlag then 
				engineCap = 700
			end
		end
		if self.slowDown then  -- If slowing down
			if self.formationFlag then
				engineCap = 600
			else
				engineCap = 800
			end
		end
	end
	if self.finishedRace then
		engineCap = 1800
	end
	if self.status == 0 then 
		if self.enginePower >= 1000 then
			nextAccel = -30
		elseif self.enginePower > 0 and self.enginePower < 1000 then
			engineCap = 0
		end
		if self.enginePower < 0 then 
			nextAccel = 25
		end
	elseif self.status == 1 then
		if self.enginePower >= engineCap then -- Shouldnt get here...
			nextAccel = -3
		end
	end
	if self.stop then
		engineCap = 0
	end
	if self.enginePower > engineCap then
		nextAccel = -25
		if self.enginePower < engineCap + 20 then -- Flatlines at engineCap
			self.enginePower = engineCap
			nextAccel = 0
		end
	end
	--print(string.format("%d : %.2f -- %.2f",self.racerID,nextAccel,totalVel))
	if self.status == -1 then -- Reverse
		nextAccel = nextAccel * -0.8
	end
	if self.correcting then
		nextAccel = nextAccel * 1.2
		if nextAccel > 0 then
			nextAccel = nextAccel * 0.3
		end
	end
	return nextAccel
end


function Brain.calculatePower(self,accel) -- may get more complex...

	local power = self.enginePower
	
	if self.topSpeedECU == 0 or self.stop then 
		power = power -25
		if power < 50 then 
			power = 0 
			accel = 0
		end
	end

	power = power + accel
	
	if math.abs(accel) > 25 then		
		--print("AC",self.racerID,accel)
	end
	if power == 0 then -- vehichle engine stopped
		self.drivingState = 0
	elseif power > 0 then 
		self.drivingState = 1
	else
		self.drivingState = -1
	end


	if self.status == -1 then -- Trying to go in reverse
		if self.drivingState == 0 then
			--print("Moving backward")
		end

		if self.enginePower > 1 then -- If trying to slow down to go backwards
			power = 0 
			return power
		end 
			
		if self.enginePower < -1300 then -- Dont go too fast while backwards
			power = -1300
			return power
		end
		-- This may be where the problems come from...
		return power
	end
	if self.status == 0 then
		if self.drivingState ~= 0 then 
			--print("Stopped")
			power = 0
		end
	end
	if self.status == 1 then
		if self.dirVel > 5 and self.launching then 
			self.launching = false
			--print("finish launch")
		end
		if power < 0 then 
			self.launching = true
			power = power + 10
		end
		if self.drivingState == 0 then 
			--print("moving forward")
			self.launching = true
			self.drivingState = 1
		end
	end

	local downForceMultiplier = 600
	local baseNumber = 2900
	local brakeMultiplier = 1

	if self.racerID >= 1 then --Faster
		downForceMultiplier = 1200
		baseNumber = 3800
		brakeMultiplier = 2.7
	end

	local baseSpeed = baseNumber + (self.downforceECU*downForceMultiplier) -- Downforce effects cornering speeds maybe also effect turn angle too?
	local brakeStrength = 26
	if easyFirstCorners then
		 baseSpeed = 2600
		 brakeStrength = 29
	end
	
	
	if self.brakePower > 0 then -- Braking logic
		local difference = self.speed - (baseSpeed - self.brakePower)
		if self.racerID == 1 then
			--print(self.racerID,difference)
		end
		if difference > 1500 then
			brakeStrength = 30 * brakeMultiplier
		elseif difference > 700 then
				brakeStrength = 29 * brakeMultiplier
		elseif difference > 500 then
				brakeStrength = 28 * brakeMultiplier
		end

		if power > baseSpeed - self.brakePower then
			if self.isPassing then
				power = self.enginePower - brakeStrength
			else
				power = self.enginePower - (brakeStrength + 0.5) -- Or custom brake strength
			end
		else
			power = self.enginePower + accel
		end
	end
	if power < -1100 then 
		power = -1000
	end
	if self.racerID == 1 then
		--print(self.racerID,power,self.brakePower,self.speed)
	end
	return power
end

function Brain.calculateTurnBraking(self)
	local minBrakeDistance = 20 -- C
	local maxBrakeDistance = 60-- D
	if self.isDrafting then 
		minBrakeDistance = minBrakeDistance + 5
		maxBrakeDistance = maxBrakeDistance + 5
	end

	if self.isPasing then 
		minBrakeDistance = minBrakeDistance + 5
		maxBrakeDistance = maxBrakeDistance + 5
	end
	if self.raceStatus == -1 then
		minBrakeDistance = 30
		maxBrakeDistance = 55
	end

	if self.speed > 4000 then
		maxBrakeDistance = maxBrakeDistance + self.speed/1900
		minBrakeDistance = minBrakeDistance + self.speed/1900
	end

	local maxTrackPos =  50 -- B
	local distFromCP = math.abs( self.distFromCP)
	local trackPos = self.trackPos
	local speed = self.speed
	local nextCP = self.map[self.nextCP]
	--print(nextCP.action)
	if nextCP.action == 0 then
		return 0
	end
	local brakePower = 0
	-- [A,B] - [C,D]
	-- C+(D−C)*(x−A)/(B−A)  -- Scale equation
	-- Calculate braking distance
	local brakingDistance = maxBrakeDistance + (minBrakeDistance - maxBrakeDistance) * (trackPos - 0) / (maxTrackPos) 

	if distFromCP < brakingDistance then -- If turning already or braking? maybe just set brakeValue and reset when done turning
		
		local minBrakePower = 250
		local maxBrakePower = 1350

		if self.raceStatus == -1 then
			minBrakePower = 200
			maxBrakePower = 1300
		end
		if trackPos < 8 then
			maxBrakePower = maxBrakePower + 250
		end
		if  checkOutside(self.radar,14) and trackPos < 8 then
			print(self.racerID, "trying not to send it")
			maxBrakePower = maxBrakePower + 400
		end
		if trackPos >= 44 then 
			maxBrakePower = maxBrakePower + 50
			minBrakePower = minBrakePower + 50
		end
		if self.isPassing then 
			maxBrakePower = maxBrakePower + 5
			minBrakePower = minBrakePower + 15
		end

		if self.isDrafting then 
			maxBrakePower = maxBrakePower + 10
			minBrakePower = minBrakePower + 20
		end
		brakePower = maxBrakePower + (minBrakePower - maxBrakePower) * (trackPos - 0) / (maxTrackPos) 
	end

	return brakePower
	
end

function Brain.setEnginePower(self,power)
	if power ~= self.enginePower then
		self.enginePower = power 
	end
	if self.reset then
		self.enginePower = 0.69420
		self.reset = false
	end
	
end

-- Car Steering functionsss
function Brain.calculateTurnAdjustment(self) -- Todo: rename to calculateTurn...
	local velocity = self.velocity -- Eventually  make dynamic using cp location, but I'm lazy
	local directionalVectors = {sm.vec3.new(0,1,velocity.z), -- North
								sm.vec3.new(1,0,velocity.z), -- East
								sm.vec3.new(0,-1,velocity.z), -- South
								sm.vec3.new(-1,0,velocity.z) -- West
								}
	local goalDirection = self.goalDirection
	--print(goalDirection,directionalVectors)
	local goalVector = directionalVectors[(goalDirection +1)]
	local turnDir = self.turnState
	local trackPos = self.trackPos
	local turnLimit = self.turnLimit
	local turnAngle = 0 --calculateTurnAngle(self) 

	if turnLimit == 0 or turnLimit == nil then
		turnLimit =  calculateTurnLimit(self,trackPos)
		self.turnLimit = turnLimit
	end
	--print("Got",turnLimit)
	local directionalOffset = sm.vec3.dot(goalVector,velocity)
	local directionalCross = sm.vec3.cross(goalVector,velocity)
	turnAngle = (directionalCross.z) --* turnDir
	
	if self.speed >= 3000 then -- NOTICE In case I want DIFFERENT TYPES of cars
		turnAngle = turnAngle * 1.5
	elseif self.raceStatus == 1 or self.raceStatus == 3 or self.finishedRace then
		--print("awkturnAngle")
		turnAngle = turnAngle * 0.9
	elseif self.speed < 2500 then
		-- Check trackPos?
		turnAngle = turnAngle * 0.9 -- Or make this less?
		--print("slowSPeed Mult",turnAngle)
	end
	-- Add limiter
	if turnAngle > turnLimit then
		turnAngle = turnLimit
	elseif turnAngle < -turnLimit then
		turnAngle = -turnLimit
	end
	if self.racerID == 1 then
		--print(turnAngle,turnLimit,directionalCross,self.trackPos)
	end

	if directionalCross.z < 8  and directionalCross.z > -8 then -- Check if straight on with next cp Maybe even set acceleration speed depending on speed/trackPos?
		--print("str",directionalOffset,directionalCross)
		self.currentDirection = goalDirection -- Or just use setGoalDirection()
		self.turnState = 0
		self.turnLimit = 0
		-- If passing, Reset pass
		if self.isPassing then -- if car is tryihng to pass
			self.isPassing = false -- only stop after a turn
			--print("Stopped pass")
		end
		--print()
		--print()
	end
	
	if self.trackPos < 12 and self.isPassing then
		turnAngle = turnAngle * 1.4
		--print("multiplying TurnAngle",turnAngle)
	end
	
	return turnAngle

end

function Brain.getGoalDirAdjustment(self) -- Allows racer to stay relatively straight
	local velocity = self.velocity
	local angleMultiplier = 10
	if sm.vec3.length2(velocity) > 10 then 
		 velocity = sm.vec3.normalize(self.velocity) -- Normalized to prevent oversteer
	end
	local directionalVectors = {sm.vec3.new(0,1,velocity.z), -- North
								sm.vec3.new(1,0,velocity.z), -- East
								sm.vec3.new(0,-1,velocity.z), -- South
								sm.vec3.new(-1,0,velocity.z) -- West
								} -- Can be customizable
	local goalDirection = self.goalDirection
	local goalVector = directionalVectors[(goalDirection +1)]
	local turnAngle = 0 
	local directionalOffset = sm.vec3.dot(goalVector,velocity)
	local directionalCross = sm.vec3.cross(goalVector,velocity)
	turnAngle = (directionalCross.z) * angleMultiplier -- NOTE: will return wrong when moving oposite of goalDir
	-- Add limiter?
	--print(turnAngle)
	if self.hittingApex then turnAngle = turnAngle/1.5 end
	return turnAngle
end


function Brain.calculateDrafting(self) -- Calculates steering needed and returns angle adjust
	local draftZone = 70 -- TODO: Make global constant
	local onsideThreshold = 2.5
	local draftSteering = 0
	local isDrafting = false
	local limiter = 3.5
	-- POSIBLY SWITCH TO LONG RANGE RADAR?
	for k=1, #racerData do local v=racerData[k]
		if v.racerID ~= self.racerID then 
			if v.nextCP == self.nextCP  or (v.nextCP == 2 and self.nextCP == 1) then -- ensure on same cp too
				local dis = getDistance(self.location,v.location)
				if dis < draftZone then -- else: set long distance flag to true to speed up car slightly or go for more optimal line
					local distanceB = distanceBehind(self,v)
					
					if distanceB < -12 then
						--self.draftState = 1
						local distanceS = distanceOnside(self,v) -- Calculate with vectors instead?
						
						if distanceS < onsideThreshold and distanceS > -onsideThreshold then
							isDrafting = true
						end
						--print("DistanceOnside",distanceS)
						if getRelativeSpeed(self,v) >= 9 and self.brakePower < 2000 and dis < 65 then 
							if not self.isPassing then -- GEt out of there!
								--print("OverTake")
								if checkFrontLeft(self.radar,25) then 
									draftSteering = 3.9
								elseif checkFrontRight(self.radar,25) then
									draftSteering = -3.9
								else
									draftSteering = -2 -- nothing yet
								end
								
								return draftSteering, isDrafting
							else
								draftSteering = 0 
								-- Turn Pass to true?
								return draftSteering, isDrafting
							end
						end
						
						draftSteering = distanceS/-3.9
						if draftSteering > limiter then
							draftSteering = limiter
						elseif draftSteering < -limiter then
							draftSteering = -limiter
						end
					else 
						self.draftState = 0
					end
				end
			end
		end
	end
	
    return draftSteering, isDrafting

end

function Brain.calculatePassAdjustment(self) -- Moves car inside/outside based off of radar
	local radar = self.radar
	local trackPos = self.trackPos
	local isPasing = self.isPassing
	local passAngle = 0
	local nextCp = self.map[self.nextCP]
	local turnDirection = nextCp['action']
	local canPass = false
	local passLimiter = 3.1
	if self.speed > 3100 then 
		passLimiter = 2.7
	end
	-- Maybe first check (before functionacall??) if distFromCP is > 50 or so
	--  check if ispassing is true here
	local notNilFrontList = findNotNil({radar['F'], radar['FFR'], radar['FFL']})
	if #notNilFrontList > 0 then -- If there is something in front --TODO also check if they are moving faster than car in front, if not, then cancel pass
		local lessThanList = isLessThan(notNilFrontList,11) -- Also check the velDiff
		if #lessThanList > 0 then
			--print(self.racerID,"Passing",trackPos,self.turnState)
			--if self.trackPos > 17 then ??? end
			canPass = true
		else
			canPass = false
			
		end
	end
	if self.isPassing then 
		local dist, closestRacer = getClosestFrontRacer(self)
		if closestRacer ~= nil and dist~= nil then 
			local behindDist = math.abs(distanceBehind(self,closestRacer))
			local speedDif = getRelativeSpeed(self,closestRacer)
			--print(self.racerID,closestRacer.racerID,speedDif)
			if behindDist > 13  or speedDif < 0 then
				--print(self.racerID,"Canceld Passing",closestRacer.racerID,dist,behindDist)
				self.isPassing = false
			end
		end
	end
	if canPass then -- For starting pass, needs completing pass flag for when space
		if turnDirection == 0 then 
			if not checkFrontRight(radar,16) then 
				turnDirection = 1
			elseif not checkFrontLeft(radar,16) then
				turnDirection = -1
			else -- nowhere to go, bump draft?
				turnDirection = 0
				--print("bump draft")
			end
		end
		
			if trackPos >= 20 or self.isPassing then -- If there is room on inside
				if turnDirection == 1 then -- Right turn: TODO: make this simpler?
					if checkRightSide(radar,11) then 
						if checkLeftSide(radar,11) then
							--print("Cannot pass eitherSide")
						else
							--print("Can pass On outside")
							passAngle = passLimiter/2 * -turnDirection -- turn left
						end
					else
						--print("Can pass on inside")
						passAngle = passLimiter * turnDirection -- turn right
						
					end
				elseif turnDirection == -1 then
					if checkLeftSide(radar,11) then 
						if checkRightSide(radar,11
					) then
							--print("Cannot pass eitherSide")
						else
						--	print("Can pass On outside")
							passAngle = passLimiter/2 * -turnDirection -- Turn Right
						end
					else
					--	print("Can pass on inside")
						passAngle = passLimiter * turnDirection -- turn left
					
					end		
				end
			else -- There is no room on insside, only check outside
				if turnDirection == 1 then -- Right turn: TODO: make this simpler?
					if checkLeftSide(radar,11) then
						--print("Cannot pass Outside Left")
					else
						--print("Can pass Outside Left")
						passAngle = passLimiter/2 * -turnDirection -- turn left
					end
				elseif turnDirection == -1 then -- Left turn
					if checkRightSide(radar,11) then
						--print("Cannot pass outside right")
					else
						--print("Can pass On outside Right")
						passAngle = passLimiter/2 * -turnDirection -- Turn Right
					end
				end
			end
		
		
	end
	-- Set isPassing WARNING: SIDEeFFECT
	if self.racerID == 1 then 
		--print(isPasing, passAngle)
	end
	if  self.isPassing == false and self.correcting == false then 
		if passAngle ~= 0 then 
			self.isPassing = true
			--print("Started Pass")
		end
	
	else
		if passAngle == 0 then
			--self.isPassing = false -- only stop after a turn
			--print("Stopped pass")
		end
	end
	-- TODO: Complete pass process, checks radar for substancial space and empty front

	return passAngle
end

function Brain.calculateApexAdjustment(self)
	
	local apexAdjust = 0
	local apexMult = 5
	local maxApex = 20
	local action = self.cpData['action']
	local dist = math.abs( self.distFromCP )
	if action == 0 then
		return 0
	end
	if action ~= 0 then
		if self.racerID == 1 then
			--print(self.distFromCP,self.trackPos,self.speed)
		end
		if self.speed > 2700 and self.TCS < 1                                  then -- Make sure not to be going too slow
			if not checkInside(self.radar,7) then -- Make sure no one is inside
				if dist <= self.trackPos *1.5 then -- Within apex hitting range -- Create Adjustable Ratio?
					if self.trackPos > 6 and self.trackPos < 48 then -- if outside of inside line
						self.hittingApex = true
						apexAdjust = 80/(dist+(self.trackPos/2.8)) * action -- Adjustable?
						if self.isPassing  then
							apexAdjust = apexAdjust/1.5
						end
					end
				end
			end
		end
	end
	if apexAdjust > maxApex then
		apexAdjust = maxApex
	elseif apexAdjust < -maxApex then
		apexAdjust = -maxApex
	end
	--print(apexAdjust)
	return apexAdjust
end

function Brain.calculateCautionPass(self) -- Moves car inside/outside based off of radar
	local radar = self.radar
	local trackPos = self.trackPos
	local isPasing = self.isPassing
	local passAngle = 0
	local nextCp = self.map[self.nextCP]
	local turnDirection = nextCp['action']
	local canPass = false
	local letPass = false
	local passLimiter = 3
	local adjustMultiplier = 1
	 
	local notNilFrontList = findNotNil({radar['F'], radar['FFR'], radar['FFL']})
	if #notNilFrontList > 0 then -- If there is something in front
		local lessThanList = isLessThan(notNilFrontList,6)
		if #lessThanList > 0 then -- If there is a car in front less than 6
			canPass = true
		else
			canPass = false
			--if self.isPassing then
				--self.isPassing = false
			--print("Stopped canPass")
			--end
		end
	end

	if canPass or letPass then -- For starting pass, needs completing pass flag for when space'
		if turnDirection == 0 then 
			if not checkFrontRight(radar,9) then 
				turnDirection = 1 
			elseif not checkFrontLeft(radar,9) then
				turnDirection = -1
			else -- nowhere to go, bump draft?
				turnDirection = 0
				--print("bump draft")
			end
		end
		if trackPos >= 10 or self.isPassing then -- If there is room on inside
			if turnDirection == 1 then -- Right turn: TODO: make this simpler?
				if not  checkRightSide(radar,7) then -- Pass inside
					passAngle = passLimiter * turnDirection * adjustMultiplier
					
				end
			elseif turnDirection == -1 then
				if not checkLeftSide(radar,7) then 
					--	print("Can pass On outside")
						passAngle = passLimiter * -turnDirection * adjustMultiplier
				end
			end
		end		
	end
	-- Set isPassing WARNING: SIDEeFFECT
	if  self.isPassing == false then 
		if passAngle ~= 0 then 
			self.isPassing = true
			print("Started Pass")
		end
	else
		if passAngle == 0 then
		end
	end
	-- TODO: Complete pass process, checks radar for substancial space and empty front

	return passAngle
end

function getDirectionFromFront(self,precision) -- Precision fraction 0-1
	local front = self.shape.getAt(self.shape)
	--print(front)
	if front.y >precision then -- north?
		--print("north") 
		return 0
	end

	if front.x > precision then
		--print("east")
		return 1
	end
	
	if front.y < -precision then
		--print("south")
		return 2
	end

	if front.x < -precision then
		--print("west")
		return 3
	end
	return -1
end

function getGoalOffset(self,directionOffset,goalDirection,currentDirection, velocity) -- return the positive/negative difference of the velocity and goal direction
	local frontDir = getDirectionFromFront(self,0.75)
	--print(frontDir)
	if self.running == false then
		return 0
	end

	
	local multiplier = 1
	local offSetmultiplier = 1.3
	local turnMultiplier = 3.3
	local turnLimiter = self.handling
	local closestWallDist = getClosestWall(self) -- if zero make dist arbitrary num
	if closestWallDist == 0 then closestWallDist = 1 end

	if self.running == true and self.handling == 0 and self.resetCar == false then
		self.resetCar = true
		--print("Resetting car",directionOffset,turnMultiplier)
		self.handling = 30 
		turnMultiplier = -5
	end

	if self.resetCar == true then
		local movementStatus = movementStatus(self)
		--print(movementStatus,frontDir)
		if movementStatus == 1 then
			--print("Moving forward",currentDirection,frontDir,goalDirection)
			--currentDirection = frontDir
			self.handling =30
			if currentDirection ~= frontDir then -- if it is opposite direction?
				turnMultiplier = -5
			else 
				turnMultiplier = 5
			end

			if currentDirection == frontDir and currentDirection == goalDirection then
				--print("corrected")
				self.resetCar = false
				self.handling = self.defaultHandling
			end
		elseif movementStatus == -1 then
			currentDirection = frontDir
			--print("backward")
			--self.boost = -3000
			turnMultiplier = -5
			self.handling =55
		else 
			--print("stopped")
			currentDirection = frontDir
			self.handling =40
			turnMultiplier = 3
		end

	end


	local closestWallDir = getSign(closestWallDist)
	if goalDirection == currentDirection then -- If heading in same direction
		if self.turning ~= 0 and self.exitTurn == false then
			--print("Exiting turn")
			self.exitTurn = true
		end
		self.handling = self.defaultHandling -- setting of handling? maybe move to somewhere else
		if getDirectionFromFront(self,0.96) == currentDirection then
			--print("97% front")
			self.turning = 0
			
		end
		if getDirectionFromFront(self,0.99) == currentDirection and self.exitTurn == true then
			--print("completely forward")
			self.exitTurn = false
		end
		
		if self.uturn ~= 0 then  -- Finished performing uturn
			self.uturn = 0
			--print("uturn done")
		end
		if goalDirection == 0 then -- north 
			if velocity.x < 0 then
				multiplier = offSetmultiplier
			elseif velocity.x > 0 then
				multiplier = -offSetmultiplier
			end
		elseif goalDirection == 2 then -- south
			if velocity.x < 0 then
				multiplier = -offSetmultiplier
			elseif velocity.x > 0 then
				multiplier = offSetmultiplier
			end
		elseif goalDirection == 1 then -- East
			if velocity.y > 0 then
				multiplier = offSetmultiplier
			elseif velocity.y < 0 then
				multiplier = -offSetmultiplier
			end
		elseif goalDirection == 3 then -- West
			if velocity.y > 0 then
				multiplier = -offSetmultiplier
			elseif velocity.y < 0 then
				multiplier = offSetmultiplier
			end
		end
	else 

		-- Dynamically get turn angle bassed on closest wall?
		-- large switch case for how to turn (overrides multiplier and directionoffset)
		directionOffset = 10 -- make dynamic
		--self.turning = 1
		if goalDirection == 0 then -- If goal is to face north
			if currentDirection == 1 then -- if facing east, turn left
				multiplier = -turnMultiplier -- adjustable
			elseif currentDirection == 3 then --if facing west, turn right
				multiplier = turnMultiplier
			elseif currentDirection == 2 then -- if facing south (big oops) big adjust -- may need to call slowdown
				multiplier = 2 * -closestWallDir
				self.uturn = 1
			end
		elseif goalDirection == 1 then -- If goal is to face east
			if currentDirection == 2 then -- if facing south, turn left
				multiplier = -turnMultiplier -- adjustable
			elseif currentDirection == 0 then --if facing north, turn right
				multiplier = turnMultiplier
			elseif currentDirection == 3 then -- if facing west (big oops) big adjust 
				multiplier = 2 * -closestWallDir
				self.uturn = 1
			end
		elseif goalDirection == 2 then -- If goal is to face south
			if currentDirection == 3 then -- if facing west, turn left
				multiplier = -turnMultiplier -- adjustable
			elseif currentDirection == 1 then --if facing east, turn right
				multiplier = turnMultiplier
			elseif currentDirection == 0 then -- if facing north (big oops) big adjust 
				multiplier = 2 * -closestWallDir 
				self.uturn = 1
			end
		elseif goalDirection == 3 then -- If goal is to face west
			if currentDirection == 0 then -- if facing north, turn left
				multiplier = -turnMultiplier -- adjustable
			elseif currentDirection == 2 then --if facing south, turn right
				multiplier = turnMultiplier
			elseif currentDirection == 1 then -- if facing east (big oops) big adjust 
				multiplier = 2 * -closestWallDir
				self.uturn = 1
			end
		end
	end
	
	if self.status == -1 then
		multiplier = multiplier * 30 -- mom gave me this number lol
	end
	if self.uturn == 1 then
		--print("uturn",multiplier,self.handling,self.boost)
		self.boost = -2000
	end
	local offSet = directionOffset * multiplier
	--print(offSet,self.uturn)
	--` Turn limiter (adjustable?)
	if offSet > turnLimiter and self.uturn == 0 then 
		offSet = turnLimiter
		--print(offSet)
	elseif offSet < -turnLimiter and self.uturn == 0 then
		offSet = -turnLimiter
		--print(offSet)
	end
	--print(offSet,turnLimiter,turnMultiplier)
	return offSet
end

function Brain.getWallAdjustment(self) -- will return 0, +/- 3, 5, or 10 depending on closeness of wall
	local adjustment = 0
	local distanceRight = 100
	local distanceLeft = 100
	local hitR,rightData = sm.physics.raycast(self.location,self.location + self.shape.right*-10) 
	local hitL,leftData = sm.physics.raycast(self.location,self.location + self.shape.right*10) 
	if hitR then
		if rightData.type == "terrainAsset" then
			distanceRight = rightData.fraction
			
		end
	end
	if hitL then
		if leftData.type == "terrainAsset" then
			distanceLeft = leftData.fraction
			
		end
	end
	if self.racerID == 1 then 
		--print(distanceLeft,distanceRight)
	end
	--local hitF,distanceFront = sm.physics.distanceRaycast(self.location,self.shape.at*10) 
	--local hitB,distanceBack = sm.physics.distanceRaycast(self.location,self.shape.at*-10) 

	--print("",distanceRight*100)
	local distanceFilter = 2 -- How soon curve starts > = closer, < = further
	local adjustmenRate = 17 -- How Steep curve is, > = more turn, < = less turn
	local directionSign = 0 -- Sets whether should turn left or right according to left or right wall
	-- Will start adjusting as soon as adjustment is > 0
	if hitR then -- Sensed on right wall
		local rightDistance = distanceRight * distanceFilter
		directionSign = -1 -- Wall on right side, turn left (-1)
		adjustment = -math.log(rightDistance) * adjustmenRate -- Check graph to understand use
	end

	if hitL then -- Sensed on left wall
		local leftDistance = distanceLeft * distanceFilter
		directionSign = 1 -- Wall on left side, turn right (1)
		adjustment = -math.log(leftDistance) * adjustmenRate -- Check graph to understand use
	end


	if adjustment > 0 then
		if self.racerID == 1 then
			--print(string.format("Left: %.2f, Right: %.2f, adjustment: %.2f, %i",distanceLeft,distanceRight,adjustment,directionSign))
		end
		return directionSign * adjustment
	else
		return 0
	end	
end	

-- Caution functions
function Brain.calculateCautionAdjust(self) -- TODO: erase the two statments to just normal ones
	if self.followCar == nil or self.racePosition == 0 then
		-- NO follow cars set
		return 0,0
	end
	--print(self.racerID,self.followCar)
	local adjust = 0
	local car = 0
	local distB, backCar = getClosestBackRacer(self)
	local distF, frontCar = getClosestFrontRacer(self)

	--print(self.racerID,":",self.cautionPosition,self.racePosition, backCar ~= nil, frontCar ~= nil)
	if self.racePosition < self.cautionPosition and backCar ~= nil then -- If you are ahead of supposed to beand there exists any car behind
		--print(self.racerID,"letPass")
		if  frontCar == nil then -- If there is no car ahead of you, slow down
			adjust = -1
			car = backCar
		elseif self.followCar ~= 0 and frontCar.racerID ~= self.followCar.racerID then -- If you are not following the proper car,let them pass -- Front should never let anyone pass (followCar == 0) but keep eye out
			adjust = -1
			car = backCar
		end

	elseif self.racePosition > self.cautionPosition and frontCar ~= nil  then -- If behind of where you should be
		if self.followCar == 0 or frontCar.racerID ~= self.followCar.racerID then
			adjust = 1
			car = frontCar
		end
		--print(self.racerID,"pass")
		
	end

	if self.cautionAdjust ~= adjust then -- IF some pass got completed, check what it was and act accordingly
		--print(self.racerID,"adjust mismatch, O:c",self.cautionAdjust,adjust)
		if self.cautionAdjust == -1 and frontCar ~= nil and self.carPass ~= nil then -- If there is a car in front and you are letting somone pass
			if frontCar.racerID == self.carPass.racerID then -- if the car you wanted to pass is in front
				--print(self.racerID,"Let pass - pass complete",distF) -- Add racePOs update TODOL Add validation for actual passing (Iff distFB are <0?)
				
				self.racePosition = self.racePosition + 1 -- May get sketchy if multiple cars pass, use CP updatting then
			end
			if self.followCar ~= 0 and frontCar.racerID == self.followCar.racerID then -- you are now in perfect line
				print(self.racerID," behind folow car")
				-- Add new flag to maintain this pos?
			end
		end

			if  (self.cautionAdjust == 1 and backCar ~= nil and frontCar ~= nil and self.carPass ~= nil) then
				if backCar.racerID == self.carPass.racerID then
					--print(self.racerID,"pass - pass complete",distB) -- RacePos update
					self.racePosition = self.racePosition - 1
				end
				if self.followCar ~= 0 and frontCar.RacerID == self.followCar.racerID then -- behind goal car
					print(self.racerID,"behind follow Car")
					-- Add flag?
				end
			end
			--- TODO: Add conditional for first place cars (if followCar = 0)
	end
	return adjust, car
end 

function getClosestWall(self) -- returns +-distance depending on wall/object
	local hitR,distanceRight = sm.physics.distanceRaycast(self.location,self.shape.right*-20) -- may have to use regular cast instead of raycast
	local hitL,distanceLeft = sm.physics.distanceRaycast(self.location,self.shape.right*20) 
	local distL = 5000 -- arbitrary high num for now
	local distR = 5000 -- arbitrary high num for now
	if hitR then
		 distR = distanceRight * 100
	end
	if hitL then
		distL = distanceLeft * 100
	end

	if distR < distL then -- if right wall is closer
		return distanceRight
	elseif distL < distR then
		return -distL 
	else -- if both are equal
		return 0
	end
end

function isBehind(racerA, racerB) -- return 1, 0, or -1 for infront, neutral, or behind
	local threshold = 4
	local isBehind = 0
	--local racerAVelocity = racerA.velocity
	--local racerBVelocity = racerB.velocity
	local currentDir = racerA.goalDirection

	local diffX = racerA.location.x - racerB.location.x
	local diffY = racerA.location.y - racerB.location.y

	if currentDir == 0 then -- if north, check if y is greater
		if diffY > threshold then
			isBehind = 1
		end
		if diffY < -threshold then
			isBehind = -1
		end
	end 
	if currentDir == 2 then -- if south, check if y is lesser
		if diffY < -threshold then
			isBehind = 1
		end
		if diffY > threshold then
			isBehind = -1
		end
	end

	if currentDir == 1 then -- if east, check if X is greater
		if diffX > threshold then
			isBehind = 1
		end
		if diffX < -threshold then
			isBehind = -1
		end
	end 
	if currentDir == 3 then -- if west, check if y is lesser
		if diffX < -threshold then
			isBehind = 1
		end
		if diffX > threshold then
			isBehind = -1
		end
	end

	--print(racerA.racerID,diffX,diffY,isBehind)
	return isBehind
end

function isOnside(racerA,racerB) -- returns -1, 0 , or 1 for onLeft, neutral, or onRight
	local threshold = 1
	local onSide = 0
	local currentDir = racerA.goalDirection
	local diffX,diffY
	if type(racerB) == "Vec3" then -- probably checking a checkpoint
		 diffX = racerA.location.x - racerB.x
		 diffY = racerA.location.y - racerB.y
	else
		 diffX = racerA.location.x - racerB.location.x
		 diffY = racerA.location.y - racerB.location.y
	end

	if currentDir == 0 then -- if north, check if X is greater
		if diffX > threshold then
			onSide = 1
		end
		if diffX < -threshold then
			onSide = -1
		end
	end 
	if currentDir == 2 then -- if south, check if X is lesser
		if diffX < -threshold then
			onSide = 1
		end
		if diffX > threshold then
			onSide = -1
		end
	end

	if currentDir == 1 then -- if east, check if Y is greater
		if diffY > threshold then
			onSide = 1
		end
		if diffY < -threshold then
			onSide = -1
		end
	end 
	if currentDir == 3 then -- if west, check if Y is lesser
		if diffY < -threshold then
			onSide = 1
		end
		if diffY > threshold then
			onSide = -1
		end
	end
	--print("onside",onSide)
	return onSide
end

-- Track Positional functions--------
function Brain.setRoadPosition(self,position )
	if self.roadPos ~= position then
		self.roadPos = position
		--print("RoadPos:",self.roadPos)
	end
end

function getRoadPosition(self,cp,cpLocation1,cpLocation2,dist1,dist2,min) -- uses cp location and dir to get which side of the road car is on (0 is middle)
	--print(cp)
	local pos1 = distanceOnside(self,cpLocation1)
	local pos2 = distanceOnside(self,cpLocation2)
	--print(string.format("%.4f --- %.4f",pos1,pos2))
	if math.abs(pos1) < math.abs(pos2) then 
		if pos1 < 0 then
			--print("right")
		elseif pos1 >0 then
			--print("left")
		end
		return pos1
	elseif math.abs(pos2) < math.abs(pos1) then 
		if pos2 < 0 then
			--print("right2")
		elseif pos2 >0 then
			--print("left2") 
		end
		return pos2
	end
end

function Brain.getTrackPosition(self,cp) -- SIDE/ConvienientEFFECT: gets SELF DISTANCE FROM NEXT CHECKPOINT
	
	local curDir = self.currentDirection
	local trackPos = 0
	local distFromCp = self.distFromCP
	horizontalOffset,verticalOffset = getCheckpointVHOffset(self,cp)
	--if self.turnState == 0 then -- Temporary fix? prevents seting incorrect vertical offset
	distFromCp = verticalOffset  -- set dist from cp
	--end
	--print(distFromCp)
	local action = cp.action 
	if cp.action == 0 then -- find next cp i its just going to go straight5
		local cpID = cp.id
		local nextCP = self.map[cpID + 1]
		action = nextCP.action
	end

	if action == 1 then -- If right turn next
		--print(verticalOffset,horizontalOffset)
		if verticalOffset > 4 then -- if CP on Left ?
			trackPos = 45-horizontalOffset
		else -- If cp on right
			trackPos = horizontalOffset
		end
	elseif action == -1 then -- If left turn next
		if verticalOffset < 4 then -- If CP on Left
			--print("checkpoint on left")
			trackPos = horizontalOffset
		else -- if cp on right?
			--print("Checkpoint on right")
			trackPos = 45-horizontalOffset
		end
	else -- Fail safe.
		trackPos = math.abs( horizontalOffset )
	end
	
	return trackPos,distFromCp
end

function Brain.getRacingLineAdjustment(self)
	local optimalLine = self.raceLinePref
	local adjustLimiter = 3 -- Or higher?
	local lineAdjust = 0
	local nextCP = self.map[self.nextCP]
	if nextCP['action'] == 0 then -- Should set things right for optimal line on front stretch
		local cpID = nextCP.id
		nextCP = self.map[cpID + 1]
	end
	--print(self.trackPos)
	if nextCP['action'] == -1  then -- If next turn  is  left, means inside is oposite
		lineAdjust =  optimalLine - self.trackPos
	else
		lineAdjust = self.trackPos - optimalLine 
	end
	lineAdjust = lineAdjust / 4

	if math.abs(lineAdjust) < 0.1 then -- minithresshold
		return 0
	end
	
	
	if lineAdjust > adjustLimiter then -- Limit turning
		return adjustLimiter
	elseif lineAdjust < -adjustLimiter then
		--print(-adjustLimiter)
		return  -adjustLimiter
	else 
		return 	lineAdjust
	end
end
----------------------------- Error Checking --------
function Brain.determineError(self) -- Returns true/status if car needs to be corrected
	local isErr = false
	local currentDir = getDirectionFromFront(self,0.8)
	local isOffTrack, correctionDirection = determineOffTrack(self)

	--[[if math.abs(self.distFromCP) <= 15 then 
		--print(self.racerID,"determining estimated cp")
		local estimatedCP = estimateCP(self)
		if estimatedCP == nil then
			local frontDist = getDistanceFront(self)
			if frontDist~= false  and frontDist < 8 then
				--print(self.racerID,"About to hit wall and oFf track")
				self.status = 0
			end
			return 
		end
		--print(estimatedCP.id,self.nextCP,(self.nextCP) %#self.map +1)
		if estimatedCP.id == (self.nextCP) %#self.map +1 then -- Quick cp updating (TODO: Organize this to proper place)
			--print(self.racerID,"Cp Correction",estimatedCP)
			self.CPCorrecting = true 
			self:setCP(estimatedCP)
			-- Dont need isErr because speed is too great and would flip car un
		end
	end]]
	
	if self.racerID ==6 or self.racerID == 16 then
		--print(self.racerID,self.enginePower,self.dirVel,self.launching)
	end
	if self.racerID == 14 then
		--print(self.dirVel,self.enginePower)
	end
	if (math.abs(self.enginePower) >= 200 and self.dirVel <= 0.5) or (self.dirVel <= 1.2 and self.launching == false) then -- Must have hit wall  
		if self.raceStatus == 3 or self.raceStatus == 1 then 
			--print(self.racerID,self.enginePower)
			if self.enginePower >= 100 then 
				if not self.stuck then
					print(self.racerID,"cautionFormationStuck")
					self.stuck = true
				end
				isErr = true
			end
		else
			if not self.stuck then 
				print(self.racerID,"Stuck")
				self.stuck = true
			end
			isErr = true	
		end	
	end
	
	if currentDir ~= self.goalDirection and self.turnState == 0 then -- Maybe do this about
		if not self.errorTurn then 
			--print(self.racerID, "ErrorTurn")
			self.errorTurn = true
		end
		isErr = true
	end 
	
	if isOffTrack then 
		if self.raceStatus == 1 or self.raceStatus == 3 then 
			if math.abs(correctionDirection) <11 then 
				--print(self.racerID,"offtrack correction is false?")
				isErr = false
			end
		else
			if self.turnState == 0 then 
				if self.offTrackCor == 0 then 
					--print(self.racerID,"offTrack",correctionDirection) -- TODO: FIgure out what to do with correction direction?
				end
				isErr =  true
				self.offTrackCor = correctionDirection
			end
		end
	end

	local isTilted, offSet = checkTilted(self) -- TODO: DO SOMETHING TO FIX THIS
	if isTilted then 
		isErr = true
		if self.carTilted == 0 then 
			print(self.racerID,"car tilted")
		end
		self.carTilted = offSet
	else
		self.carTilted = 0
	end
	return isErr
end

function Brain.correctError(self)
	if not self.correcting then -- Assign Correcting info
		self.correctionTimeout = raceTimer()
		if self.raceStatus ~= 0 or self.status == -1 then 
			self.correcting = true
			--self.status = -1
		else
		self.correcting = true
		self.status = -1
		end
	end

	-- Collection of radarChecksd
	if (checkFrontSide(self.radar,4.7)) then -- TODO: Side effect when finished race and spin out on cooldaown lap
		if not self.finished or not self.finishedRace or self.status == -1 then 
			self.slowDown = true
		else
			self.status = -1
		end
	end

	if self.offTrackCor ~= 0 then -- If off track,
		--print(self.racerID,'offtrackEstimate')
		local estimatedCP = estimateCP(self) -- Estimate which cp car could possibly be on 
		if estimatedCP == nil then 
			--print(self.racerID,"Cp estimation Fail")
		else
			self.CPCorrecting = true -- Is this needed?
			self:setCP(estimatedCP)
		end
	end

	if self.errorTurn then -- If not going correct way'
			if  self.raceStatus ~= 0 or not self.stuck or self.dirVel > 1.5 then 
				self.TCS = self.TCS + 10
				--print(self.racerID,self.TCS)
				self.brakePower = self.TCS -- Todo: Fix this as well
			else
				self.TCS = 0
				self.status = -1
				--print(self.racerID,"reverseTCS")
			end
	end
		
	if self.stuck then -- Probably stuck on wall
		local frontDist = getDistanceFront(self)
		local backDist = getDistanceBack(self)
		local checkDis = 14
		if self.status == 1 then
			checkDis = 5
		end
		if self.raceStatus == 1 or self.raceStatus == 3 then
			 checkDis = 30
		end
		
		if not frontDist or frontDist > checkDis then -- If there is room in front
			--print(self.racerID,"FrontDSitFale")
			self.status = 1
		else 
			self.status = -1
		end
		if (checkFrontSide(self.radar,4.5)) then 
			self.status = -1
		end
	end
	
	if self.status == -1 then -- If going baackwards for reason
		local frontDist = getDistanceFront(self)
		local backDist = getDistanceBack(self)
		local checkDis = 25
		if self.raceStatus == 1 or self.raceStatus == 3 then
			 checkDis = 30
		end
		if not frontDist or frontDist > checkDis then -- If there is room in front
			--print(self.racerID,"done")
			self.status = 1
			checkDis = 5
		else 
			self.status = -1
		end
	
		if backDist ~= false and backDist < 5 then -- checkdis?
			self.status = 1
			--print(self.racerID,"backDistFalse")
		end
	end

	if self.carTilted ~= 0 then -- If car is tiltedd
		self.status = 0
		local offset = sm.vec3.new(0,0,0)
		local angularVelocity = self.shape.body:getAngularVelocity()
		local worldRotation = self.shape:getWorldRotation()
		local upDir = self.shape:getUp()
		--print(angularVelocity)
		--print(worldRotation)
		--print(upDir)
		-- Check if upside down,
		local stopDir = -self.velocity
		stopDir.z = 1600
		
		offset = -upDir *2
		if self.location.z >= 5 then 
			stopDir.z = 1100
			--offset = 
		end
		--print("correcting tilt")
		sm.physics.applyImpulse( self.shape.body, stopDir,true,offset)
	end
end

function Brain.checkCorrection(self)
	self:determineError()
	local curDir = getDirectionFromFront(self,0.90)
	local dirVel = self.dirVel

	if raceTimer() - self.correctionTimeout > 3 and dirVel < 2 then --TODOL MAke TIMEOUT TImer a variable, currently 3
		print(self.racerID,"Error Timeout",self.timeoutCounter)
		self.timeoutCounter = self.timeoutCounter + 1
		if self.timeoutCounter >4 then
			sm.log.warning(string.format("|| Car #%i Is stuck near Turn #%i ||",self.racerID, self.curCP)) -- TODO: Possibly trigger a full course yellow and output data
			self.status = 0 -- Add stop state to just quit trying?
			self.correcting = true
			self.status = 0
			local estimatedCP = estimateCP(self)
			if estimatedCP == nil then -- and self.cpcorrecting = true?
				print(self.racerID, "CP estimate Fail oN ERROr timeout Reset")
			else
				self:setCP(estimatedCP)
				if dirVel > 15 then
					--print("Corrected")
					self.CPCorrecting = false
				end
			end
			self:resetRacer()
		else
			self:resetError()
		end
	end
	if self.goalDirection == curDir then -- Only do this after certain conditions?
		--print(dirVel)
		if dirVel >= 1 then
			--print("estimateing")
			
			if not checkFrontSide(self.radar,5) then 
				--print(self.racerID,"Estimating CP just because")
				local estimatedCP = estimateCP(self)
				if estimatedCP == nil then -- and self.cpcorrecting = true?
					print(self.racerID, "CP estimate Fail  goalDirection correction")
				else
					self:setCP(estimatedCP)
					if dirVel > 15 then
						--print("Corrected")
						self.CPCorrecting = false
					end
				end
				if dirVel > 10 then
					--print("Corrected")
					self.CPCorrecting = false
				end
				self:resetError()
			end
		end
	end
end

function Brain.resetRacer(self) -- attempts to reset car by resetting engine and some brain functions
	--print("resetting racer") -- TODO: have fallthorouygh case for offset as carTilted and stuff
	self.reset = true
	self.status = 1
	self.TCS = 0
	local correctionVec = sm.vec3.new(0,0,4000) --("Have this be calculated depending on angle?")
	--print(self.location.z)
	if self.carTilted ~= 0 then 
		correctionVec = sm.vec3.new(0,0,4500)
	end
	if self.location.z > 5 then 
		correctionVec =self.shape:getUp() -- CHange this to self.chape.up)
	end
	sm.physics.applyImpulse( self.shape.body, correctionVec,true)
	self:resetError()
end

function Brain.resetError(self)
	--print("Error Reset")
	self.correcting = false
	self.stuck = false
	self.offTrackCor = 0
	self.errorTurn = false
	self.carTilted = false
	self.status = 1
	self.TCS = 0
end

--------------
function checkDraft(self) -- if self is behind car and within draft zone (adjustable)
	local draftZone = 100 -- ~100 blocks
	local onsideThreshold = 5
	local finalDraft = 0
	local boostLimiter = 700

	if self.status > 0 and self.uturn == 0 and self.turning == 0 then
		for k=1, #racerData do local v=racerData[k]
			if v.racerID ~= self.racerID then 
				local dis = getDistance(self.location,v.location)
				if dis < draftZone then
					local distanceB = distanceBehind(self,v)
					if distanceB < 0 then
						local distanceS = distanceOnside(self,v)
						if distanceS < onsideThreshold and distanceS > -onsideThreshold then
							finalDraft = math.abs(35 * (distanceB)) -- +50 is changeble
						end
					end
				end
			end
		end
	end

	if finalDraft > boostLimiter then
		finalDraft = boostLimiter
	end
	if finalDraft ~= self.boost then
		--print(self.racerID,"Draft:",finalDraft)
	end
    return finalDraft
end



-- Checkpoint  functions (rleated to positional) -------------
function Brain.calculateQualifyingSplits(self,now,cp) -- Calculates qualifying splits and also outputs time split
	--print("Getting quallifying split")
	racePos = 1
	self.racePosition = 1
	local split = getQualifyingSplit(self,cp,now)
	self.timeSplit = split
	--print(self.racerID,"TimeSPlit",self.timeSplit)
	split =  string.format("%.3f",split)
	outputTimeSplit(self,split)
	self.qualifyingSplits = setQualifyingSplit(self,cp,now)
end

function Brain.updateCheckpointStatus(self,cp)
	--print(self.trackPos)
	--print("updatingCp",cp)
	if isInCP(self.location,cp) then
		--print("tr",self.trackPos)
		--print("HitCP",cp.id,cp.action, self.distFromCP)
		if not self.finishedRace then 
			self:setCarStats() 
		end
		self:performCpAction(cp)
	end
end

function Brain.performCpAction(self, cp) -- Reads input from checkpoint, performs input
	local action = cp.action
	local now = raceTimer()
	local racePos = 0
	local split
	if self.CPCorrecting then
		self.CPCorrecting = false
		self.timeoutCounter = 0
	end	
	if action == 0 and cp.id == 1 then --If crosses finishLine
		--print(self.racerID,"crossing finish")
		if self.currentLap >= 0 and self.raceStatus >= 2 then -- If not on formation lap ( problems may occur in different race states)
			split = self:setSplit()
		else -- sets initial split
			split = now - self.splitReset
			self.splitReset = now
		end
		if self.raceStatus >= 1 then -- If in green flag racing possibly not have formation lap count?
			self.currentLap = self.currentLap + 1
		end
		if self.racePosition <= 1 then
			outputRaceStatus(self.raceStatus)
		end
		if self.raceStatus == -1 then
			self.currentLap = self.currentLap + 1 -- Initial lap then hot lap
			print(self.racerID,"On lap",self.currentLap)
			if self.currentLap == 2 then
				self:calculateQualifyingSplits(now,cp)
				self.finishedRace = true
				self.racePosition = 0
				self.qualifyingTime = split
				print("finished qualifying",split)
				if split == nil then
					print("Split is still nil")
				end
				local topQualTime = getTopQualTime()
				if topQualTime == nil or split < topQualTime then
					--print("Nil")
					setTopQual(self,split)
					--setQualifyingMark(self.qualifyingSplits)
					print("New Top qualifier",self.racerID,split)
				else
					if split < topQualTime then
						print("TOP QUAL TIME ERROR")
					else
						print("QUalifying time was not fastest")
					end
				end
				calculateQualifyingPos() -- calculates all the qualifying pos of each racer
				print(self.racerID,"Finished Qualifying",self.qualifyPosition)
			end
		end
	end
	
	if action ~= 0 then -- Simplified /TUrning m
		local curDir = self.goalDirection
		self.lastDirection = curDir
		local nextDir =  (curDir + action) %4 -- TODO: Update this to use Direction attribute
		self.goalDirection = nextDir
		self.turnState = action -- Action is either -1 or 1
	end
	
	-- Moved this to see if it can keep turnCalc Before?
	self.curCP = cp.id
	self.nextCP = cp.nxt 
	self.cpData = self.map[cp.nxt]
	--print("TrackPOS",self.trackPos)
	if self.raceStatus == -1 and not self.finishedRace and self.currentLap == 1 then -- If qualifying, need to do right on finish too...
		self:calculateQualifyingSplits(now,cp)
	else
		
		if not self.finishedRace then 
			racePos = calculateRacePosition(self)
			--print(self.racerID,"CalculatedPos",racePos)
			self.racePosition = racePos
			if racePos ~= 0 then 
				if racePos == 1 and not self.finishedRace then 
					setTimeSplit(self,cp,now)
					self.timeSplit = "--:--:---"
					--print(self.timeSplit)
					
				elseif racePos > 1 then
					local timeSplit = getTimeSplit(self,cp,now)
					--print(self.racerID,timeSplit)
					self.timeSplit = timeSplit
				end
				if self.currentLap == self.totalLaps then 
					--self.currentLap = self.totalLaps +1
					self.finishedRace = true
					if self.racePosition == 1 then
						self.timeSplit = self.currentLap .. " Laps"
					end
					print("FinishtimeSPlit",self.timeSplit)
					self.finishPosition = self.racePosition
					setFinishData(self)
					
					outputFinishData()
				end
					
					--self:stopTimer() -- TODO: FINISH THIS FUnction
			end
		else
			if self.nextCP == 2 and self.trackPos > 42 then
				self.status = 0
				self.stop = true
			end

		end
	end
end

function Brain.setCP(self,cp)
	
	local cpID = cp['id']
	if self.nextCP == cpID then -- Shortcut
		return
	end
	local totalCP = #self.map
	self.nextCP = cpID
	self.curCP = (cpID -1 %totalCP) + 1
	--print()
	--print(self.curCP)

	self.cpData = self.map[cp.id]
	self.goalDirection =  (cp['dir'] - cp['action']) % 4
	--print("Set CP",cpID)
end

function Brain.confirmRacePos(self) -- Checks the racer behind and sees if everything checks out
	dis,racer = getClosestBackRacer(self)
	if racer == nil then
		return
	end
	
	if racer.nextCP == self.nextCP and racer.currentLap == self.currentLap then -- Racer is actually behind you (cp checking may not be necessary tho)
		if racer.racePosition < self.racePosition and racer.racePosition ~= 0 and dis > 9 then
			local swap = racer.racePosition
			racer.racePosition = self.racePosition
			self.racePosition = swap
			--print(self.racerID,"Swap with",racer.racerID,racer.racePosition,self.racePosition,dis)
		elseif racer.racePosition == self.racePosition and self.racePosition < #racerData then -- Makesure you are within the total cars availible, dont just add racepos for no reason
			racer.racePosition = self.racePosition + 1
			--print(self.racerID,"Added racePosition",self.racePosition)
		end
	end

end
-----------------------------------------

-- Timing functions-----------------------
function Brain.calculateSplit( self, split, now)
	
	self.lastLapTime = split
	if self.bestLapTime == 0 then
		--print("Initial best lap")
		self.bestLapTime = split
	elseif split < self.bestLapTime  then
		--print("New best lap!",split)
		self.bestLapTime = split
	end
	if self.totalLaps > 0 then -- If totalLaps is set
		if self.currentLap == self.totalLaps then
			print(self.racerID,"Finished!")
			self.totalTime = now - self.startTime
		end
	end
end

function Brain.startTimer(self)
	local now = raceTimer()
	--print("StarTime",self.startTime)
	if self.startTime == 0 then
		self.startTime = now
		self.splitReset = now
		--print("started",now)
	else 
		--print("Resuming",now)
		

	end

end

function Brain.setSplit(self)
	local now = raceTimer()
	split = now - self.splitReset
	self.splitReset = now
	self:calculateSplit(split,now)
	print(string.format("%i: %.3f ",self.racerID,split))
	return split
end

function Brain.stopTimer(self)
	local now = raceTimer()
	--print("stopped",now)
end

function Brain.resetTiming( self )
	--print(self.racerID,"Reset timing")
	self.curCP = 0
	self.nextCP = 1
	self.currentLap = 0 -- lap count
	self.racePosition = 0 -- Race positon
	self.totalLaps = 0

	-- timing
	self.startTime = 0
	self.splitReset = 0
	self.lastLapTime = 0
	self.bestLapTime = 0
	self.totalTime = 0
	self.timeSplit = 0
	--outputSingleData(self)
end
------------------------------------


-- Radar functions
function findNotNil(dataList) -- Returns the values that are not nill 
	local notNilList = {}
	for k=1, #dataList do local v=dataList[k]
		if v ~= nil or v ~= 0 then 
			--print("Got:",v,dataList) -- Figure out how to return dictionary key back
			table.insert(notNilList,v)
		end
	end
	return notNilList
end

function isLessThan(dataList,value) -- Returns the values (not nil) that are less than value
	local lessThan = {}
	for k=1, #dataList do local v=dataList[k]
		if v <= value and v ~= 0 then 
			table.insert(lessThan,v)
		end
	end
	return lessThan
end


function checkWholeLeft(radar,value)
	local notNilLeftList = findNotNil({radar['L'], radar['LLF'], radar['LLB'],radar['FL'], radar['BL']})
	if #notNilLeftList > 0 then 
		local lessThanList = isLessThan(notNilLeftList,value)
		if #lessThanList > 0 then -- If there is a car potentially in the way, dont do it
			return true
		end
	end
	return false
end


function checkWholeRight(radar,value)
	local notNilLeftList = findNotNil({radar['R'], radar['RRF'], radar['RRF'],radar['FR'], radar['BR']})
	if #notNilLeftList > 0 then 
		local lessThanList = isLessThan(notNilLeftList,value)
		if #lessThanList > 0 then -- If there is a car potentially in the way, dont do it
			return true
		end
	end
	return false
end

function checkRightSide(radar,value) -- returns true if there is something on right side of radar <= value
	local notNilRightList = findNotNil({radar['R'], radar['RRF'], radar['RRB']})
	if #notNilRightList > 0 then 
		local lessThanList = isLessThan(notNilRightList,value)
		if #lessThanList > 0 then -- If there is a car potentially in the way, dont do it
			return true
		end
	end
	return false
end

function checkLeftSide(radar,value) -- returns true if there is something on right side of radar <= value
	local notNilRightList = findNotNil({radar['L'], radar['LLF'], radar['LLB']})
	if #notNilRightList > 0 then 
		local lessThanList = isLessThan(notNilRightList,value)
		if #lessThanList > 0 then -- If there is a car potentially in the way, dont do it
			return true
		end
	end
	return false
end
function checkFrontSide(radar,value)
	local notNilList = findNotNil({radar['FL'], radar['F'], radar['FR']})
	if #notNilList > 0 then 
		local lessThanList = isLessThan(notNilList,value)
		if #lessThanList > 0 then -- If there is a car potentially in the way, dont do it
			return true
		end
	end
	return false
end

function checkBackSide(radar,value)
	local notNilList = findNotNil({radar['BL'], radar['BBL'],radar['B'], radar['BR'],radar['BBR']})
	if #notNilList > 0 then 
		local lessThanList = isLessThan(notNilList,value)
		if #lessThanList > 0 then -- If there is a car potentially in the way, dont do it
			return true
		end
	end
	return false
end

function checkFrontCorners(radar,value)
	local notNilList = findNotNil({radar['FL'], radar['FR']})
	if #notNilList > 0 then 
		local lessThanList = isLessThan(notNilList,value)
		if #lessThanList > 0 then -- If there is a car potentially in the way, dont do it
			return true
		end
	end
	return false
end

function checkFrontLeft(radar,value)
	local notNilList = findNotNil({radar['FL'], radar['FFL']})
	if #notNilList > 0 then 
		local lessThanList = isLessThan(notNilList,value)
		if #lessThanList > 0 then -- If there is a car potentially in the way, dont do it
			return true
		end
	end
	return false
end

function checkFrontRight(radar,value)
	local notNilList = findNotNil({radar['FR'], radar['FFR']})
	if #notNilList > 0 then 
		local lessThanList = isLessThan(notNilList,value)
		if #lessThanList > 0 then -- If there is a car potentially in the way, dont do it
			return true
		end
	end
	return false
end

function checkBackRight(radar,value)
	local notNilList = findNotNil({radar['BR'], radar['BBR']})
	if #notNilList > 0 then 
		local lessThanList = isLessThan(notNilList,value)
		if #lessThanList > 0 then -- If there is a car potentially in the way, dont do it
			return true
		end
	end
	return false
end

function checkBackLeft(radar,value)
	local notNilList = findNotNil({radar['BL'], radar['BBL']})
	if #notNilList > 0 then 
		local lessThanList = isLessThan(notNilList,value)
		if #lessThanList > 0 then -- If there is a car potentially in the way, dont do it
			return true
		end
	end
	return false
end

function checkInside(radar,value,turnDir) -- Checks inside car depending on next action
	if turnDir == -1 then
		return checkWholeLeft(radar,value)
	elseif turnDir == 1 then
		return checkWholeRight(radar,value)
	end
end	


function checkOutside(radar,value,turnDir) -- Checks inside car depending on next action
	if turnDir == 1 then
		return checkWholeLeft(radar,value)
	elseif turnDir == -1 then
		return checkWholeRight(radar,value)
	end
end	

-- RADAR V0.0

-- **** Positional Mapping *** (Dictionary Keys and their relative positions)
-- -------------------------------
-- | FL  | FFL |  F  | FFR | FR  |
-- -------------------------------
-- | LLF | 	*  |  *  |	*  | RRF |
-- -------------------------------   
-- |  L  | 	*  |  C  |  *  |  R  |
-- -------------------------------
-- | LLB | 	*  |  *  |	*  | BBR |
-- -------------------------------
-- | BL  | BBL |  B  | BBR | BR  |
-- -------------------------------

-- ****  Angle Mapping *** (what angle results to which pos on map *in degree radians)
-- TODO: ^^^^ this ^^^

-- Hint:: (0 = 90 degrees cos)
-- Gets pos of all cars (side effect) (possibly filter those on same CP)
-- If Car is within a threshold Distance(currently 8), calculate their radar pos
-- Returns Table (dictionary) of above keys, if no car in grid/area, Values will be 0, else, values will be distance away

function replaceIfLess(value,check) -- Move to RacerData with other helper funcitons
	if value == 0.00 then
		return check
	end

	if check < value then
		return check
	else
		return value
	end
end

function createRadar()
	 local radarData = {
		["FL"]=0,["FFL"]=0,["F"]=0,["FFR"]=0,		["FR"]=0,
		["LLF"] = 0, 								 ["RRF"] = 0,
		["L"] = 0, 					    			 ["R"] = 0,
		["LLB"] = 0, 								["RRB"] = 0,
		["BL"]=0,["BBL"]=0,["B"]=0,["BBR"]=0,		["BR"]=0,
	 }
	 return radarData
end

function Brain.updateRadar(self,radarData) -- STIll messing around if radar should be persistent or not
	--print("Updating radar",self)
	local radarData = {
		["FL"]=0,["FFL"]=0,["F"]=0,["FFR"]=0,		["FR"]=0,
		["LLF"] = 0, 								 ["RRF"] = 0,
		["L"] = 0, 					    			 ["R"] = 0,
		["LLB"] = 0, 								["RRB"] = 0,
		["BL"]=0,["BBL"]=0,["B"]=0,["BBR"]=0,		["BR"]=0,
	 }
	local distanceThreshold = 25 -- can change
	-- First Get all cars within distance threshold
	local racers = getRacersInRange(self,distanceThreshold)
	
	-- Loop Through Cars to check radar/location on each
	for k=1, #racers do local v=racers[k]
		local racer = v[1]
		local distance = v[2]
		-- Make this into a separate function ?
		local relativePos = {['x'] = (racer.location.x - self.location.x), ['y'] = (racer.location.y - self.location.y),['z'] = (racer.location.z - self.location.z)}
		local relativeVec = sm.vec3.normalize(sm.vec3.new(relativePos['x'],relativePos['y'],relativePos['z'])) -- Normalizes the vector generated by the difference of  positions, may possibly get length via this?
		local frontVector = self.shape.getAt(self.shape)
		local dotedVector = sm.vec3.dot(frontVector,relativeVec) -- Dotted vector gets if car is in front/behind at what angle, but not Left/Right
		local horizontalPos = getSign(sm.vec3.cross(relativeVec,frontVector).z) -- Gets sign  from crossed vector which returns + for right & - for left
		local verticalPos = getSign(dotedVector)
		-- Now map angles according tro thing
		local carStatus = 0
		if self.racerID == 14 then
			--print(dotedVector)
		end
		-- Check front/Rear

		local radarDist =distance
		if dotedVector > 0.98 and dotedVector <= 	1 then -- F
			radarData['F'] = replaceIfLess(radarData['F'],radarDist)
		elseif dotedVector < -0.99  and dotedVector >= -1 then -- B
			radarData['B'] = replaceIfLess(radarData['B'],radarDist)
		else
			if horizontalPos == 1  then -- If car on right -- TODO: MAke radar cutoffs variables
				-- Front Checking
				if dotedVector > 0.90 and dotedVector <= 0.98 then -- FFR
					radarData['FFR'] =replaceIfLess(radarData['FFR'],radarDist)
				elseif dotedVector > 0.73 and dotedVector <= 0.90 then -- FR
					radarData['FR'] = replaceIfLess(radarData['FR'],radarDist)
				elseif dotedVector > 0.25 and dotedVector <= 0.73 then -- RRF
					radarData['RRF'] =replaceIfLess(radarData['RRF'],radarDist)
				elseif dotedVector > -0.25 and dotedVector <= 0.25 then -- R -- Directly Right
					radarData['R'] = replaceIfLess(radarData['R'],radarDist)

				-- Back Checking
				elseif dotedVector < -0.25 and dotedVector >= -0.86 then -- RRB
					radarData['RRB'] = replaceIfLess(radarData['RRB'],radarDist)
				elseif dotedVector < -0.86 and dotedVector >= -0.93 then -- BR
					radarData['BR'] = replaceIfLess(radarData['BR'],radarDist)
				elseif dotedVector < -0.93 and dotedVector >= -0.99 then -- BBR
					radarData['BBR'] = replaceIfLess(radarData['BBR'],radarDist)
				end

			elseif horizontalPos == -1 then -- if car on left
				if dotedVector > 0.90 and dotedVector <= 0.98 then -- FFL
					radarData['FFL'] = replaceIfLess(radarData['FFL'],radarDist)
				elseif dotedVector > 0.71 and dotedVector <= 0.90 then -- FL
					radarData['FL'] = replaceIfLess(radarData['FL'],radarDist)
				elseif dotedVector > 0.25 and dotedVector <= 0.73 then -- LLF
					radarData['LLF'] = replaceIfLess(radarData['LLF'],radarDist)

				elseif dotedVector > -0.25 and dotedVector <= 0.25 then -- L -- Directly Left
					radarData['L'] = replaceIfLess(radarData['L'],radarDist)

				-- Back Checking
				elseif dotedVector < -0.25 and dotedVector >= -0.85 then -- LLB
					radarData['LLB'] = replaceIfLess(radarData['LLB'],radarDist)
				elseif dotedVector < -0.85 and dotedVector >= -0.90 then -- BL
					radarData['BL'] =replaceIfLess(radarData['BL'],radarDist)
				elseif dotedVector < -0.90 and dotedVector >= -0.99 then -- BBL
					radarData['BBL'] =replaceIfLess(radarData['BBL'],radarDist)
				end
			end
		end
		
		
	
	-- Append to map data (overwrites if closer, )
	end
	if self.racerID == 1 then
		-- printRadar(radarData)
	end
	-- 
	return radarData
end

function printRadar(radar) -- Graphical representation of radar
	print(string.format("\n %.2f  %.2f  %.2f  %.2f  %.2f \n %.2f                 	    %.2f \n %.2f	                     %.2f \n %.2f	                     %.2f \n %.2f  %.2f  %.2f  %.2f  %.2f \n",
		radar["FL"], radar["FFL"], radar["F"],radar["FFR"], radar["FR"],
		radar["LLF"],		 					 radar["RRF"],
		radar["L"],								radar ["R"],
		radar["LLB"],						 radar["RRB"],
		radar["BL"],  radar["BBL"],radar["B"] ,radar["BBR"], radar["BR"]
	))
end


function Brain.getRadarAdjustment(self) -- adjusts the turning if the radar is less than a certain threshold
	local radar = self.radar
	local frontThreshold = 10
	local sideAdjustThreshold = 5
	local cornerThreshold = 7
	local radarAdjustment = 0
	local adjustMultiplier = 2.5
	local brakeThreshold = 9
	local alertThresh = 6
	local brakeAdjust = 0 
	local numProx = 0 
	if self.speed < 2600 then
		brakeThreshold = 4
		alertThresh = 3.5
		sideAdjustThreshold = 4
		cornerThreshold = 4
	end
	if self.speed > 3500 and self.turnState == 0 then 
		adjustMultiplier = 1.2
		sideAdjustThreshold = 3.7
		cornerThreshold = 3.5
		brakeThreshold = 7
		alertThresh = 6
	end
	if self.speed > 4000 and self.turnState == 0 then 
		adjustMultiplier = 1.1
		sideAdjustThreshold = 3.5
		cornerThreshold = 3
		brakeThreshold = 6
		alertThresh = 7
	end
	if self.turnState ~= 0 then 
		adjustMultiplier = 1.3
		sideAdjustThreshold = sideAdjustThreshold + 1
		cornerThreshold = cornerThreshold + 1
		frontThreshold = frontThreshold
	end
	if self.easyFirstCorners then
		sideAdjustThreshold = sideAdjustThreshold + 3
		cornerThreshold = cornerThreshold + 3
		brakeThreshold = 10 -- TODO: Test if this works
		frontThreshold = 11
		alertThresh = 7 
	end
	if checkLeftSide(radar,sideAdjustThreshold) then
		if self.turnState == -1 then 
			adjustMultiplier = 1.5
		end
		if self.turnState == 1 then 
			adjustMultiplier = 2.5
		end
		radarAdjustment = radarAdjustment + (1* adjustMultiplier)
		numProx = numProx +1
	end

	if checkRightSide(radar,sideAdjustThreshold) then
		if self.turnState == 1 then 
			adjustMultiplier = 1.4
		end
		if self.turnState == -1 then 
			adjustMultiplier = 2.5
		end
		radarAdjustment = radarAdjustment + (-1 * adjustMultiplier)
		numProx = numProx +1
	end

	if checkFrontLeft(radar,frontThreshold) then
		if self.turnState == 1 then 
			adjustMultiplier = 3
		end
		if self.turnState == -1 then 
			adjustMultiplier = 1.5
		end
		radarAdjustment =  radarAdjustment  + (1 * adjustMultiplier)
		numProx = numProx +1
	end
	if checkFrontRight(radar,frontThreshold) then
		if self.turnState == -1 then 
			adjustMultiplier = 3
		end
		if self.turnState == 1 then 
			adjustMultiplier = 1.5
		end
		radarAdjustment =  radarAdjustment+ (-1 * adjustMultiplier)
		numProx = numProx +1
	end
	
	if checkBackLeft(radar,cornerThreshold) then 
		if self.turnState == -1 then 
			adjustMultiplier = 1.2
		end
		if self.turnState == 1 then
			adjustMultiplier = 1.5
		end
		if self.turnState == 0 then
			if checkBackLeft(radar,3) then
				adjustMultiplier = 1.2
			else
				adjustMultiplier = 0.3
			end
		end
		numProx = numProx +1
		radarAdjustment =  radarAdjustment + (1 * adjustMultiplier)

	end
	if checkBackRight(radar,cornerThreshold) then 
		if self.turnState == -1 then 
			adjustMultiplier = 1.5
		end
		if self.turnState == 1 then
			adjustMultiplier = 1.4
		end
		if self.turnState == 0 then
			if checkBackRight(radar,3) then
				adjustMultiplier = 1.2
			else
				adjustMultiplier = 0.3
			end
		end

		numProx = numProx +1
		radarAdjustment = radarAdjustment + (-1 * adjustMultiplier)
	end



	if checkFrontSide(radar,brakeThreshold) then  -- Slow down if too close to car in front
		--print(self.racerID,"BrakeThreshold")		
		brakeAdjust = 60
		if self.isPassing then 
			brakeAdjust = 15
		end
		if checkFrontSide(radar,alertThresh) then  -- Slow down if too close to car in front
			--print(self.racerID,"alertTHresh",radar) 
			brakeAdjust = 120
			if self.raceStatus == 3 or self.raceStatus == 1 then 
				brakeAdjust = 180
			end
			if checkFrontSide(radar,5.1) then  -- Slow down if too close to car in front
				--print(self.racerID,"Collision?")
				brakeAdjust = 150 -- 500?
				if self.raceStatus == 3 or self.raceStatus == 1 then --Todo: what to check on formation lap?
					--print("cautionCollision")
					brakeAdjust = 800
				else
					self.status = 0
					if self.dirVel < 2 then 
						self.status = -1
					end
				end
			else
				if self.status == 0 and not self.correcting then
					self.status = 1
				end
			end
		else
			if self.status == 0 and not self.correcting then
				self.status = 1
			end
		end
	else
		if self.status == 0 and not self.correcting then
			self.status = 1
		end
	end

	if checkFrontCorners(radar,cornerThreshold) then -- conditional upon turn or straight?
		if self.turnState ~= 0 then 
			brakeAdjust = brakeAdjust + 80
			radarAdjustment = radarAdjustment * 2
			--print(self.racerID,"car front corner while turning",radarAdjustment)  -- Make dynamic somehow? -- TODO: Test for constant instead of steady increase (lower increase)\
		else
			if self.passing then 
				print(self.racerID,"car front corner while passing",radarAdjustment)
				brakeAdjust = brakeAdjust + 10
			else
				--print(self.racerID,"car front corner general",radarAdjustment)
				brakeAdjust = brakeAdjust + 4
			end
		end
		--print(self.racerID,"Corner Brake",self.brakePower)
	end


	if numProx >= 2  and self.raceStatus == 2 then 
		--print(self.racerID,"CLoseprox",numProx)
		self.closeProx = true
		radarAdjustment = radarAdjustment /2
	end


	return radarAdjustment, brakeAdjust
end

function  Brain.sideProximity( self )
	local radar = self.radar
	if checkLeftSide(radar,10) then
		return true
	end

	if checkRightSide(radar,10) then
		return true
	end
end
-----------------------------------
--- Racing Operations ---
------------------------

function Brain.performQualifyingOperations(self) -- Similar to raceOp, but more speed focused RS.-1
	local steeringValue = 0
	local drivingState = self.drivingState
	local raceLineAdjust = 0
	local turnAdjust = 0
	local terrainAjustment = self:getWallAdjustment() -- radar?
	local straightAdjustment = 0
	local radarAdjustment = 0
	local braking = 0
	local radarBraking = 0
	local curDir = getDirectionFromFront(self,0.89)
	local dirVel = self.dirVel
	local straightMult = 1 -- Make into smooth ratio/curve
	local raceLineMult = 1.5
	local speedAdjustment = 1
	
	if self.speed > 0 and self.speed < 1500 then
		speedAdjustment = 1.5
	elseif self.speed > 1500 and self.speed < 2000 then 
		raceLineMult = 1.5
		straightMult = 1.5
		speedAdjustment = 1
	elseif self.speed >2000 and self.speed < 3000 then 
		raceLineMult = 1
		straightMult = 1.3
		speedAdjustment = 0.8
	elseif self.speed > 3000 and self.speed < 3500 then 
		raceLineMult = 0.8
		straightMult = 1.2
		speedAdjustment = 0.6
	elseif self.speed > 3500 then 
		raceLineMult = 0.7
		straightMult = 1
		speedAdjustment = 0.4
	end
	if self:sideProximity() then 
		straightMult = 1.5
		raceLineMult = 0.1
		speedAdjustment = 0.9
	end
	if self.finishedRace then
		self.raceLinePref = 46
		if self.speed < 2000 then
			raceLineMult = raceLineMult * 5
		end
	end
	
	if self.status == 1 then -- If driving forward
		if self.drivingState ~= 1 and  self.launching == false then
			--print("launching")
			self.launching = true
			
		end
	end

	if self.turnState == 0 then -- If not Turning -- MAIN LOGIC
		if not self.isPassing then -- if not passing
			straightAdjustment = self:getGoalDirAdjustment() * straightMult -- * weighting to get straighter lines
			--print(self.goalDirection,curDir)
			if self.correcting then
				straightAdjustment = straightAdjustment * 3.5 -- * turnMult
			end
			-- Check if going opposite direcation: then multiply straight adjust
			if math.abs(straightAdjustment) > 4 + straightMult  and not self.correcting and not self.hittingApex then -- brake when oversteering
				if self.speed > 1800 then 
					self.TCS = self.TCS + 25
					braking = braking + self.TCS
					straightAdjustment = straightAdjustment * 2
					--print(string.format("TCS %d ",self.brakePower,braking))
				else
					self.TCS = self.TCS + 10
					braking = braking + self.TCS -- same here with tcs
					straightAdjustment = straightAdjustment * 2.7
					--print("Correcting",self.brakePower,braking)
				end
			else
				self.TCS = 0
			end
			-- if in lower position, get faster racing line?
			-- If on first lap, do not use RL or DraftA until after turn 1d
			raceLineAdjust = self:getRacingLineAdjustment()  * raceLineMult --weighting to increase RL conformity
			
			if math.abs(raceLineAdjust) >= 0.5 and math.abs(straightAdjustment) < 2 then
				straightAdjustment = 0
			end
			if  math.abs(straightAdjustment) >= 5 then 
				raceLineAdjust = raceLineAdjust / 2
			end
			--print(raceLineAdjust)	 
		else -- If is passing
			straightAdjustment = self:getGoalDirAdjustment() * straightMult -- maybe less?
		
			raceLineAdjust = 0 -- dont try to follow raceLine
		end

	else  -- If turning
		turnAdjust = self:calculateTurnAdjustment() -- Make more dependent on trackPos/speed?
		if turnAdjust <= 5 then -- Temp Fix for hitting apex
			self.hittingApex = false 
		end
		if self.trackPos >= 40 then
			self.hittingApex = false 
			braking = braking + 100
			turnAdjust = turnAdjust * 1.5 -- ???
			--print(self.racerID,"understeer braking",turnAdjust)
		end
	end

	radarAdjustment, radarBraking = self:getRadarAdjustment() -- Uses radar to adjust whether or not to turn/ how deep
	braking = braking + radarBraking
	
	-- Apex hitting 
	apexAdjustment = self:calculateApexAdjustment()

	if terrainAjustment ~= 0 then -- if there is a wall adjustment, set that as priority adjustment ( no use running into wall  to avoid car)
		if self.finishedRace then
			terrainAjustment = terrainAjustment/4
		end
		passAdjustment = 0
		radarAdjustment = radarAdjustment * 0.5 -- Smaller?
		-- turnAdjustment?
	end

	if radarAdjustment ~= 0 then
		raceLineAdjust = raceLineAdjust /4
		straightAdjustment = straightAdjustment /1.5
	end
	
	if drivingState == 0 then -- Not moving
	elseif drivingState == 1 then -- Moving
	elseif drivingState == -1 then -- reversing
	end 

	if math.abs(apexAdjustment) > 0 then
		straightAdjustment = 0
		raceLineAdjust  = 0
	end
	radarAdjustment = radarAdjustment * speedAdjustment
	steeringValue = turnAdjust + terrainAjustment + raceLineAdjust + straightAdjustment + apexAdjustment + radarAdjustment-- Combine all turning angles
	self:setSteering(steeringValue)

	-- ########### ECU CONTROL ########
	--print("preturnBrake",braking)
	local preturnBraking = braking
	local turnBraking = self:calculateTurnBraking()
	braking = preturnBraking + turnBraking
	local postTurnBraking =braking
	--print("radarBraking",radarBraking,braking
	-- CONDITIONAL BEfore only before turns and stuff, but now just straight up
	if self.turnState == 0 then
		self.brakePower = braking -- TODO: figure out if doing this staright up is okay or have separate setterFunction
		if self.racerID == 1 then
		--print("straightBrake",self.brakePower,preturnBraking,braking)
		end
	else
		self.brakePower = self.brakePower + radarBraking/4-- no more radar braking? multiply turn brake multiplication in radabrake funciton
		if self.racerID == 1 then
			--print("TurnBrake",self.brakePower,preturnBraking,braking )
		end
	end
	if self.brakePower >= 3000 and self.speed < 3500 then
		--print(self.racerID,"BrakeLockup",self.speed,self.brakePower, preturnBraking,braking)
		--self.brakePower = 2000
	end
	local throttle = 1 -- placeholder just in case we want to go half throttle or even have throttle effect the topSpeed when calc accel instead
	local accel = self:calculateAcceleration(throttle)
	local enginePower = self:calculatePower(accel) -- calculate throttle?
	
	self:setEnginePower(enginePower)
end


function Brain.performFormationOperations(self) -- Sets Everything necessary for formation lap RS.1
	local nextCP = self.map[self.nextCP]
	local steeringValue = 0
	local drivingState = self.drivingState
	local raceLineAdjust = 0
	local turnAdjust = 0
	local terrainAjustment = self:getWallAdjustment()
	local straightAdjustment = 0
	local draftAdjustment = 0 -- follow car in front
	local isDrafting = false
	local passAdjustment = 0 -- if if car in front and self is moving faster, turn to inside line prefered
	local radarAdjustment = 0
	local braking = 0
	local radarBraking = 0
	local curDir = getDirectionFromFront(self,0.89)
	local dirVel = self.dirVel
	local straightMult = 1.5 -- Make into smooth ratio/curve
	local raceLineMult = 5
	local draftMult = 0 -- no drafting... unless...?
	local cautionLane = 0 -- 0 = middle, -1 = outside, 1 = inside
	local cautionAdjust = 0
	defaultRaceLine = 25
	--print(nextCP['nxt'])
	-- Check Formation status and line up accordingly
	local formationStatus = getFormationStatus()
	--print(self.racerID,self.raceLinePref,self.catchup,self.slowDown)
	if self.nextCP <= 2 or nextCP['nxt'] == 1  then -- Find some way to tighen lines even more
		--print(self.racerID,"tighen lines?")
		self.followDistance = 14
	else
		self.followDistance = 19
	end

	if formationStatus then -- If global status means all good then
		if self.formationFlag == false then -- If not already forming up
			if self.nextCP <= 2 then  -- If not past first turn
				self.formationFlag = true
				print(self.racerID,"Forming up",self.formationLane,self.raceLinePref) -- Say so
			else -- Not needed but here anyways
				--self.formationFlag = false
				--self.inFormationPlace = false
				--print(self.racerID,"Stopped forming up") -- Doesnt actually form up until necessary
				self.raceLinePref = defaultRaceLine
			end
		else -- If already forming up
			if self.inFormationPlace then
				self.catchup = false
			end
			if self.nextCP > 2 then -- If past first corner, stop everything
				self.formationFlag = false
				print(self.racerID,"Canceled Formation Lap")
				self.inFormationPlace = false
				setFormationStatus(false)
				self.raceLinePref = defaultRaceLine
			end
		end
	else
		if self.formationFlag then -- if already trying to form, dont
			self.formationFlag = false
			self.inFormationPlace = false
			self.raceLinePref = defaultRaceLine
		else -- If not formation status and not trying to form
			--print(self.racerID,"waiting on formation",self.formationFlag,self.qualifyPosition,self.racePosition)
			if self.nextCP <= 2 then -- If on front stretch
				--print(self.qualifyPosition,self.racePosition)
				if self.qualifyPosition == self.racePosition then
					if self.isAligned and self.cautionAdjust == 0 and self.catchup == false then -- If following well with racer in front
						self.slowDown = true
					end
				else
					self.slowDown = false
				end
			end
		end
	end

	if self.turnState == 0 then -- If not Turning -- MAIN LOGIC
		-- Only pass on certain conditions?? like if dist from cp is longer than #?
		straightAdjustment = self:getGoalDirAdjustment() * straightMult -- * weighting to get straighter lines
		if self.correcting then
			straightAdjustment = straightAdjustment * 4 -- * turnMult?
		end

		if not self.formationFlag then 
			-- Caution opperations when not trying to form up
			cautionAdjust, cautionCar = self:calculateCautionAdjust()
			local distF, frontCar = getClosestFrontRacer(self)
			if cautionAdjust ~= self.cautionAdjust then
				if cautionAdjust == 0 then -- always be able to cancel a caution car
					--print(self.racerID,"Either finish pass or cancel pass")
					self.cautionAdjust = cautionAdjust
					self.carPass = cautionCar
					self.raceLinePref = defaultRaceLine
				end
				if (math.abs(self.distFromCP) > 20 and math.abs(self.trackPos - defaultRaceLine) < 30)then 
					--print(self.racerID,"adjusting",cautionAdjust)
					self.cautionAdjust = cautionAdjust
					self.carPass = cautionCar
				else 
					--print(self.racerID,"Not further than 50 ")
				end
			end
			--print(self.racerID,cautionAdjust)
			if self.cautionAdjust == -1 then -- Means go to outside and slow down
				--print("sloow",self.raceLinePref,self.racerID)
				self.catchup = false -- Speed up to move outside? or else maybe stay
				self.raceLinePref = 35
				if self.trackPos >= 27 and not self.slowDown and self.turnState == 0 then  -- If close ish to raceLine, and not turning, then slow down.
					--print(self.racerID,"slowing down")
					self.slowDown = true
					self.catchup = false
				end
				if self.turnState ~= 0 then -- If turning, dont slowdown or speedup
					self.slowDown = false
					self.catchup = false
				end
			end

			if self.cautionAdjust == 1 then  -- means stay on inside and (sped up?)
				self.slowDown = false
				self.catchup = true
				self.raceLinePref = 20
				if distF ~= nil and distF < 5 then 
				 	if math.abs( distanceOnside(self,frontCar)) <= 3 then -- If far enough back and not going to run into them
						self.catchup = false
					else
						self.catchup = true 
					end
				else 
					self.catchup = true
				end
				-- catchup if on inside?
			end
			
			
			if self.cautionAdjust == 0 then -- means stay in place -- Recheck racePOS?
				self.carPass = 0
				-- how far car in front is if not in front
				if self.racePosition ~= 1 then 
					--print(self.racerID,distF,frontCar.racerID)
					if distF ~= nil then 
						if distF > self.followDistance then -- TTry to stay close
							if frontCar.turnState ~= 0 then 
								--print(self.racerID, "Follow Car is turning")
								if distF < 22 then -- Hopefully prevents cars from running through eachother in curves
									self.catchup = false
									self.slowDown = false
								end
							end
							self.catchup = true
							self.slowDown = false
						elseif distF < self.followDistance-1 then 
							self.slowDown = true
							self.catchup = false
						else
							self.slowDown = false
							self.catchup = false
						end
					else
						if self.racePosition ~= self.qualifyPosition then
							if self.qualifyPosition == 1 then
								--print(self.racerID, "Should be leading")
								self.catchup = false
							else
								--print(self.racerID, "shouldnt be leading")
								self.catchup = false
								self.raceLinePref = 40
								self.slowDown = true
							end
						end
					end
				else -- allegedly in line
					self.catchup = false
					self.slowDown = false
				end
				--self.raceLinePref = 25
			end
		else -- If self.Formationflag is true

			local distFromLane = nil
			local insideLane = 15
			local outsideLane = 30
		
		
			if self.formationLane == 1 then 
				self.raceLinePref = insideLane
				
			elseif self.formationLane == 0 then
				self.raceLinePref = outsideLane
			end
			distFromLane = self.trackPos - self.raceLinePref
			
			if math.abs(distFromLane) < 3 then  -- If close to prefered lane
				local carDist = nil
				if self.formationCar ~= 0 then  -- If formation car is set
					carDist = distanceBehind(self,self.formationCar) * -1 -- gets distance in front from specified racer
				end
				if self.qualifyPosition == 2 then -- if in second, try to keep up with first
					carDist = distanceBehind(self,self.followCar) * -1 -- To make it closer than it actually is?
					if carDist == nil then 
						carDist = nil
						self.slowDown = true
						--print("Nil second place carDist")
					else
						carDist = carDist +16 -- Bring in second place row
					end
					--print(self.racerID,carDist)
				end
				if carDist ~= nil then
					if carDist > 19 then -- Too far
						self.catchup = true
						self.slowDown = false
						self.inFormationPlace = false
						--print(self.racerID,"speed up")
					elseif carDist < 18 then  -- Too close 
						--print(self.racerID,"slow down")
						self.slowDown = true
						self.catchup = false
						self.inFormationPlace = false
					else -- Just right
						self.slowDown = false
						self.catchup = false
						self.inFormationPlace = true
					end
				else -- Something either wrong or first place is all good?
					self.catchup = false
					self.slowDown = false
					self.inFormationPlace = true
				end
			else -- If not in lane distance
				--print(self.racerID,"not in lane dist")
				self.catchup = true -- could be true
				self.slowDown = false
			end
			-- 
		end

		--print(self.racerID,self.raceLinePref)
		--print(self.racerID,":",self.formationLane,self.raceLinePref)
		raceLineAdjust = self:getRacingLineAdjustment()  * raceLineMult --weighting to increase RL conformity
		--print(self.raceLinePref,raceLineAdjust)
		if math.abs(raceLineAdjust) >= 5 then
			straightAdjustment = straightAdjustment /2
		end
		if math.abs(straightAdjustment) > 4 then 
			raceLineAdjust = raceLineAdjust / 2
		end

	else  -- If turningdw
		local multiplier = 1.5
		if self.cautionAdjust == -1 then
			multiplier = 0.9
		elseif cautionAdjust == 1 then
			multiplier = 2.1
		end
		-- Need to make turninc consistent... just make catchup and slow down false or true
		self.slowDown = false
		self.catchup = true -- Finicky with this one
		turnAdjust = self:calculateTurnAdjustment() * multiplier -- If messing up, check here
	end

	radarAdjustment, radarBraking = self:getRadarAdjustment() -- Uses radar to adjust whether or not to turn/ how deep
	radarAdjustment = radarAdjustment * 6
	braking = braking + radarBraking
	if terrainAjustment ~= 0 then -- if there is a wall adjustment, set that as priority adjustment ( no use running into wall  to avoid car)
		radarAdjustment = radarAdjustment * 0.5 -- Smaller?
		-- turnAdjustment?
	end

	if radarAdjustment ~= 0 then
		raceLineAdjust = 0
	end
	
	if drivingState == 0 then -- Not moving
	elseif drivingState == 1 then -- Moving
	elseif drivingState == -1 then -- reversing
	end 
	
	steeringValue = turnAdjust + terrainAjustment + raceLineAdjust + straightAdjustment + radarAdjustment-- Combine all turning angles
	--print(string.format("%.2f , %.2f, %.2f",raceLineAdjust,straightAdjustment,steeringValue))
	self:setSteering(steeringValue)

	-- ########### ECU CONTROL ########
	--print("preturnBrake",braking)
	--braking = braking + self:calculateTurnBraking() -- Should this be removed during caution?
	--print("radarBraking",radarBraking,braking
	-- CONDITIONAL BEfore only before turns and stuff, but now just straight up
	if self.turnState == 0 then  -- TOdo: allow for better braking
		self.brakePower = braking -- TODO: figure out if doing this staright up is okay or have separate setterFunction
	--print(braking)
	else
		self.brakePower = self.brakePower + radarBraking/2 -- TODO: reduce radarBraking or have it be constant somehow by setting brakeSPeed before turn and adding on to that
	end
	local throttle = 1 -- placeholder just in case we want to go half throttle or even have throttle effect the topSpeed when calc accel instead
	local accel = self:calculateAcceleration(throttle)
	local enginePower = self:calculatePower(accel) -- calculate throttle?

	--print(self.speed)

	self:setEnginePower(enginePower)
end

function Brain.performRaceOperations(self) -- Sets Everything necessary for race operations (green flag)RS.2
	local steeringValue = 0
	local drivingState = self.drivingState
	local raceLineAdjust = 0
	local turnAdjust = 0
	local terrainAjustment = self:getWallAdjustment() -- radar?
	local straightAdjustment = 0
	local draftAdjustment = 0 -- follow car in front
	local apexAdjustment = 0
	local isDrafting = false
	local passAdjustment = 0 -- if car in front and self is moving faster, turn to inside line prefered
	local radarAdjustment = 0
	local braking = 0
	local radarBraking = 0
	local curDir = getDirectionFromFront(self,0.89)
	local dirVel = self.dirVel
	local straightMult = 1 -- Make into smooth ratio/curve
	local raceLineMult = 1.4
	local draftMult = 1
	local speedAdjustment = 1
	if self.finishedRace then
		self.raceLinePref = 44
	end
	if self.speed > 0 and self.speed < 1500 then
		speedAdjustment = 1.5
	elseif self.speed > 1500 and self.speed < 2000 then 
		raceLineMult = 0
		straightMult = 2.5
		draftMult = 0.6
		speedAdjustment = 1
	elseif self.speed >2000 and self.speed < 3000 then 
		raceLineMult = 0.9
		straightMult = 1.5
		draftMult = 0.5
		speedAdjustment = 0.9
	elseif self.speed > 3000 and self.speed < 4000 then 
		raceLineMult = 1
		straightMult = 1.3
		draftMult = 0.3
		speedAdjustment = 0.8
	elseif self.speed > 4000 then 
		raceLineMult = 0.6
		straightMult = 1.5
		draftMult = 0.1
		speedAdjustment = 0.7
	end
	if self:sideProximity() then 
		straightMult = 1.8
		draftMult = 0
		raceLineMult = 0.1
		--speedAdjustment = 0.9
	end
		
	
	if self.status == 1 then -- If driving forward
		if self.drivingState ~= 1 then
			--print("launching")
			self.launching = true
		end
	end

	if self.turnState == 0 then -- If not Turning -- MAIN LOGIC
		draftAdjustment, isDrafting = self:calculateDrafting() -- Also return draft strength/speed
		if self.isDrafting ~= isDrafting then -- Separate to sedDraft(draft)
			self.isDrafting = isDrafting
		end
		draftAdjustment = draftAdjustment * draftMult
		-- Only pass on certain conditions?? like if dist from cp is longer than #?
		passAdjustment = self:calculatePassAdjustment()
		if not self.isPassing then -- if not passing
			straightAdjustment = self:getGoalDirAdjustment() * straightMult -- * weighting to get straighter lines
			--print(self.goalDirection,curDir)
			if self.correcting then
				straightAdjustment = straightAdjustment * 3.5 -- * turnMult
			end
			-- Check if going opposite direcation: then multiply straight adjust
			if math.abs(straightAdjustment) > 3 + straightMult  and not self.correcting and not self.hittingApex then -- brake when oversteering
				if self.speed > 2000 then 
					self.TCS = self.TCS + 25
					braking = braking + self.TCS
					straightAdjustment = straightAdjustment * 2
					if self.racerID == 1 then
						--print("Fast trackPosBraking",braking)
					end
					--print(string.format("TCS %d ",self.speed))
				else
					self.TCS = self.TCS + 10
					braking = braking + self.TCS
					if self.racerID == 1 then
						--print("Slow tcsBraking",braking)
					end
					straightAdjustment = straightAdjustment * 2.5
					--print("Correcting",straightAdjustment)
				end
			else
				self.TCS = 0 -- TODO: Maybe have it ramp down instead of instant 0
			end
			-- if in lower position, get faster racing line?
			-- If on first lap, do not use RL or DraftA until after turn 1d
			raceLineAdjust = self:getRacingLineAdjustment()  * raceLineMult --weighting to increase RL conformity
			
			if math.abs(raceLineAdjust) >= 0.5 and math.abs(straightAdjustment) < 2 then
				straightAdjustment = 0
			end
			if  math.abs(straightAdjustment) >= 2 then 
				raceLineAdjust = raceLineAdjust / 2
			end
			--print(raceLineAdjust)	 
		else -- If is passing
			straightAdjustment = self:getGoalDirAdjustment() * straightMult -- maybe less?
			draftAdjustment = 0 -- dont try to draft
			if not self.sideProximity then
				raceLineAdjust = raceLineAdjust * 0.6 -- dont try to follow raceLine maybe only do it clear on sides
			else
				raceLineAdjust = raceLineAdjust *0.2
			end
		end

		-- Apex hitting 
		apexAdjustment = self:calculateApexAdjustment()

	else  -- If turning
		turnAdjust = self:calculateTurnAdjustment() -- Make more dependent on trackPos/speed?
		if self.hittingApex then -- Temp Fix for hitting apex
			self.hittingApex = false 
		end
		if self.trackPos >= 40 then
			braking = braking + 200
			if self.racerID == 1 then
			end
			turnAdjust = turnAdjust * 1.5 -- ???
		end
	end

	radarAdjustment, radarBraking = self:getRadarAdjustment() -- Uses radar to adjust whether or not to turn/ how deep
	braking = braking + radarBraking
	if self.racerID == 1 then
		--print(radarBraking,self.TCS,self.brakePower,self.turnState)

	end
	if terrainAjustment ~= 0 then -- if there is a wall adjustment, set that as priority adjustment ( no use running into wall  to avoid car)
		draftAdjustment = 0
		passAdjustment = 0
		radarAdjustment = 0
		-- turnAdjustment?
	end

	if radarAdjustment ~= 0 then
		draftAdjustment = 0
		raceLineAdjust = raceLineAdjust /4
		straightAdjustment = straightAdjustment /1.4
		apexAdjustment = apexAdjustment/1.5
	end
	if math.abs(apexAdjustment) > 0 and straightAdjustment < 2 then
		straightAdjustment = 0
		raceLineAdjust  = 0
	end
	if passAdjustment > 0 then
		--print(self.racerID,"isPas adjust",self.raceLineAdjust,self.terrainAjustment)
		raceLineAdjust = raceLineAdjust * 0.01 -- ??
	end
	if drivingState == 0 then -- Not moving
	elseif drivingState == 1 then -- Moving
	elseif drivingState == -1 then -- reversing
	end 

	-- Prevent CHaos on first Corner
	if self.easyFirstCorners then 
		raceLineAdjust = raceLineAdjust *0.2
		if self.nextCP > 3 then 
			self.easyFirstCorners = false
		end
		draftAdjustment = draftAdjustment * 0.05
		straightAdjustment = straightAdjustment * 1.7
		apexAdjustment = apexAdjustment *0.7
		passAdjustment = passAdjustment*0.3
	end
	radarAdjustment = radarAdjustment * speedAdjustment
	passAdjustment = passAdjustment * speedAdjustment

	steeringValue = turnAdjust + terrainAjustment + passAdjustment+ draftAdjustment + raceLineAdjust +  apexAdjustment + straightAdjustment + radarAdjustment + self.offTrackCor-- Combine all turning angles
	if	self.racerID == 1 then
		--print(string.format("TOTAL: %.2f | Apex: %.2f, Turn: %.2f, straight: %.2f, raceLine: %.2f, terrain: %.2f, radar: %.2f, draft: %.2f, pass: %.2f ",steeringValue, apexAdjustment,turnAdjust,straightAdjustment,raceLineAdjust,terrainAjustment,radarAdjustment, draftAdjustment,passAdjustment))
	end
	--print(self.dirVel)
		self:setSteering(steeringValue)

	-- ########### ECU CONTROL ########
	
	braking = braking + self:calculateTurnBraking()

	
	-- CONDITIONAL BEfore only before turns and stuff, but now just straight up
	if self.turnState == 0 and not self.correcting then
		self.brakePower = braking -- TODO: figure out if doing this staright up is okay or have separate setterFunction
		
	else
		self.brakePower = self.brakePower + radarBraking/10 -- TODO: reduce radarBraking or have it be constant somehow by setting brakeSPeed before turn and adding on to that
	end
	local throttle = 1 -- placeholder just in case we want to go half throttle or even have throttle effect the topSpeed when calc accel instead
	local accel = self:calculateAcceleration(throttle)
	local enginePower = self:calculatePower(accel) -- calculate throttle?
	if self.racerID == 4 then
		--print(accel,enginePower)
		
	end
	self:setEnginePower(enginePower)
end

function Brain.performCautionOperations(self) -- Sets Everything necessary for caution operations (Yellow flag) RS.3
	local steeringValue = 0
	local drivingState = self.drivingState
	local raceLineAdjust = 0
	local turnAdjust = 0
	local terrainAjustment = self:getWallAdjustment()
	local straightAdjustment = 0
	local draftAdjustment = 0 -- follow car in front
	local isDrafting = false
	local passAdjustment = 0 -- if if car in front and self is moving faster, turn to inside line prefered
	local radarAdjustment = 0
	local braking = 0
	local radarBraking = 0
	local curDir = getDirectionFromFront(self,0.89)
	local dirVel = self.dirVel
	local straightMult = 1 -- Make into smooth ratio/curve
	local raceLineMult = 5
	local draftMult = 0 -- no drafting... unless...?
	local cautionLane = 0 -- 0 = middle, -1 = outside, 1 = inside
	local cautionAdjust = 0
	self.raceLinePref = 25
	
	if self.status == 1 then -- If driving forward
		if self.drivingState ~= 1 then
			--print("launching")
			self.launching = true
		end
	end
	if self.turnState == 0 then -- If not Turning -- MAIN LOGIC
		-- Only pass on certain conditions?? like if dist from cp is longer than #?
		straightAdjustment = self:getGoalDirAdjustment() * straightMult -- * weighting to get straighter lines
		if self.correcting then
			straightAdjustment = straightAdjustment * 4 -- * turnMult?
		end
		if math.abs(straightAdjustment) > 4 + straightMult  and not self.correcting then -- brake when oversteering
			if self.speed > 1500 then 
				braking = braking + 30 
				straightAdjustment = straightAdjustment * 1.5
			else
				braking = braking + 5
				straightAdjustment = straightAdjustment * 2.5
			end
		end
		-- Caution opperations: Determine Race line and brake power
		cautionAdjust, cautionCar = self:calculateCautionAdjust()
		local distF, frontCar = getClosestFrontRacer(self)
		if cautionAdjust ~= self.cautionAdjust then
			if (math.abs(self.distFromCP) > 50 or self.nextCP == 1 ) or cautionAdjust == 0 then 
				--print(self.racerID,"adjusting",cautionAdjust)
				self.cautionAdjust = cautionAdjust
				self.carPass = cautionCar
			else 
				--print(self.racerID,"Not further than 50 ")
			end
		end

		if self.cautionAdjust == -1 then -- Means go to outside and slow down
			if distF ~= nil and distF > 20 and self.racePosition > 1 then 
				self.catchup = true
			else
				self.catchup = false
			end
			self.raceLinePref = 35
			if self.trackPos >= 32 and not self.slowDown and self.turnState == 0 then 
				--print(self.racerID,"slowing down")
				self.slowDown = true
			end
			if self.turnState ~= 0 then
				self.slowDown = false
			end
		end

		if self.cautionAdjust == 1 then  -- means stay in middle and speed up?
			self.slowDown = false
			--self.catchup = true
			self.raceLinePref = 20

			if distF == nil or distF > 17 then 
				self.catchup = true
			else
				self.catchup = false 
			end
			-- catchup if on inside?
		end
		
		
		if self.cautionAdjust == 0 then -- means stay in place
			self.carPass = 0
			-- how far car in front is if not in front
			if self.racePosition ~= 1 then 
				--print(self.racerID,distF,frontCar.racerID)
				if distF ~= nil then 
					if distF > 15 then -- TTry to stay close
						self.catchup = true
						self.slowDown = false
					elseif distF < 10 then 
						self.slowDown = true
						self.catchup = false
					else
						self.slowDown = false
						self.catchup = false
					end
				end
			else -- allegedly in line
				self.catchup = false
				self.slowDown = false
			end
			self.raceLinePref = 25
		end



		raceLineAdjust = self:getRacingLineAdjustment()  * raceLineMult --weighting to increase RL conformity

		if math.abs(raceLineAdjust) >= 1 and math.abs(straightAdjustment) < 1.5 then
			straightAdjustment = 0
		end

	else  -- If turningdw
		turnAdjust = self:calculateTurnAdjustment() * 1.5 -- shaper turns because too slow
	end

	radarAdjustment, radarBraking = self:getRadarAdjustment() -- Uses radar to adjust whether or not to turn/ how deep
	radarAdjustment = radarAdjustment * 4
	braking = braking + radarBraking
	if terrainAjustment ~= 0 then -- if there is a wall adjustment, set that as priority adjustment ( no use running into wall  to avoid car)
		draftAdjustment = 0
		passAdjustment = 0
		radarAdjustment = radarAdjustment * 0.1 -- Smaller?
		-- turnAdjustment?
	end

	if radarAdjustment ~= 0 then
		draftAdjustment = 0
		raceLineAdjust = 0
	end
	
	if drivingState == 0 then -- Not moving
	elseif drivingState == 1 then -- Moving
	elseif drivingState == -1 then -- reversing
	end 
	
	steeringValue = turnAdjust + terrainAjustment + passAdjustment+ draftAdjustment + raceLineAdjust + straightAdjustment + radarAdjustment-- Combine all turning angles
	--print(string.format("%.2f , %.2f, %.2f",raceLineAdjust,straightAdjustment,steeringValue))
	self:setSteering(steeringValue)

	-- ########### ECU CONTROL ########
	--print("preturnBrake",braking)
	--braking = braking + self:calculateTurnBraking() -- Should this be removed during caution?
	--print("radarBraking",radarBraking,braking
	-- CONDITIONAL BEfore only before turns and stuff, but now just straight up
	if self.turnState == 0 then  -- TOdo: allow for better braking
		self.brakePower = braking -- TODO: figure out if doing this staright up is okay or have separate setterFunction
	--print(braking)
	else
		self.brakePower = self.brakePower + radarBraking -- TODO: reduce radarBraking or have it be constant somehow by setting brakeSPeed before turn and adding on to that
	end
	local throttle = 1 -- placeholder just in case we want to go half throttle or even have throttle effect the topSpeed when calc accel instead
	local accel = self:calculateAcceleration(throttle)
	local enginePower = self:calculatePower(accel) -- calculate throttle?
	--print(accel,enginePower)
	--print(self.speed)

	self:setEnginePower(enginePower)
end


function Brain.parseParents( self ) -- Gets and parses parents, setting them accordingly
	--print("Parsing Parents")
	local parents = self.interactable:getParents()
	for k=1, #parents do local v=parents[k]--for k, v in pairs(parents) do
		local typeparent = v:getType()
		local parentColor =  tostring(sm.shape.getColor(v:getShape()))
		--print(parentColor)

		if tostring(v:getShape():getShapeUuid()) == "efbd14a8-f896-4268-a273-b2b382db520c" and parentColor == "eeeeeeff" then --  white numberBlock: set racerID
			if v.power ~= self.racerID and v.power ~= 0 then
				self.racerID = v.power
				print("RacerID:",self.racerID)
				self.enginePower = 0
				local carData = getCarData(v.power)
				if carData == nil then
					print("Error while loading car data",v.power)
					return
				end
				self:setCarStats()
			end
		elseif tostring(v:getShape():getShapeUuid()) == "efbd14a8-f896-4268-a273-b2b382db520c" and parentColor == "4a4a4aff" then --  dark grey numBlock: set total laps
				local totalLaps = v:getPower()
				--print("power =",totalLaps)
				if totalLaps ~= self.totalLaps then
					self.totalLaps = totalLaps
					--print(self.racerID,"TotalLaps:",self.totalLaps)
				end
		elseif tostring(v:getShape():getShapeUuid()) == "efbd14a8-f896-4268-a273-b2b382db520c" and parentColor == "817c00ff" then --  darkyellow NumBlock, set map Index Possibly move internally 
			--print("yelloq",v.power)
			if v.power ~= self.mapID and v.power ~= 0 then --
				self.mapID = v.power
				self.map = mapSet[self.mapID]
				self.cpData = self.map[self.nextCP]
				--sm.cameramaps.curID = v.power
				--print(self.racerID,"Map ID:", self.mapID)
				
			end
		elseif tostring(v:getShape():getShapeUuid()) == "9805e02d-d987-4f64-9b64-2fb4177e2372"  then -- Engine Controller, set power
			if v.power ~= self.speed then 
				self.speed = v.power
				if v.power > self.maxEngineSpeed then
					self.maxEngineSpeed = v.power
				end
				--print(self.maxEngineSpeed)
			end
		end
	end
	
end

function Brain.updateEffect(self) -- TODO: Un comment this when ready
	if self.effect:isPlaying() == false and getRaceStatus() ~=0 then -- ~= 0
		self.effect:start()
	elseif self.effect:isPlaying() and self.status == 0 and self.speed == 0 and getRaceStatus() == 0 then
		self.effect:setParameter( "load", 1 )
		self.effect:setParameter( "rpm", self.speed )
		self.effect:stop()
	end
	local engineConversion = reverseRatioConversion(0,self.MAX_SPEED,0,1,self.speed)
	local brakingConversion = ratioConversion(0,1600,0,1,self.brakePower) --2000 means more breaking coolown sound
	if self.racerID == 1 then
		--print(self.speed,engineConversion,self.brakePower,brakingConversion)
	end
	if self.effect:isPlaying() then
		self.effect:setParameter( "rpm", engineConversion )
		self.effect:setParameter( "load", brakingConversion ) --?
	end
end

function Brain.client_onUpdate(self,timestep) -- This oculd be a problem
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	self:updateEffect()
end

function Brain.client_onFixedUpdate(self,timeStep)
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
	--	return
	--end
	--[[ look for any other useful client side functions?
	if self.dirVel > 0 then 
		local camPos = sm.camera.getPosition()
		local distFromCar = getDistance(self.location,camPos)
		local distHeight = self.location.z - camPos.z
		local shake = 0
		--print(distFromCar)
		if math.abs(distHeight) < 10 and distFromCar < 10 then
			shake = ((self.dirVel/400))
			shake = shake/distFromCar
			--sm.camera.setShake(shake)
		end
		
	end
	if self.dirVel <=0.9 or self.status == 0 then
		--sm.camera.setShake(0)
	end]]
end

function Brain.server_onFixedUpdate( self, timeStep ) -- New State based and radar assisted
	--if not sm.isHost then -- Just avoid anythign that isnt the host for now
		--return
	--end
	--print('hey')
	self:parseParents()
	local raceStatus = getRaceStatus() -- Unsure if more semiglobal variables needed
	--print(self.map,self.racerID,self.totalLaps)
	if self.map == nil or self.racerID == nil or self.racerID == 0 or self.totalLaps == nil then -- or self.effect == nil
		self.loaded = false -- loading var
	else 
		self.loaded = true
	end
	if not self.loaded then return end -- dont calculate if not loaded everything yet
	--print(self.racerID,'loade')
	if self.raceStatus ~= raceStatus then
		if raceStatus == 3 then 
			--print("set caution")
			local car = setCautionCarToFollow(self)
			--print(self.racerID,"follow",carID)
			self.followCar = car
		elseif raceStatus == 2 then 
			self.easyFirstCorners = true -- ??????? is ther a better way? no
		elseif raceStatus == 1 then 
			local car,followCar = setFormationCarToFollow(self)
			self.followCar = car
			self.formationCar = followCar
			self.currentLap = -1 -- ???? TODO ???
			self.finishedRace = false
			self.stop = false
			self.raceLinePref = 25
			-- Perform checks??
			self.currentLap = 0
		elseif raceStatus == -1 then 
			self.finishedRace = false
			self.currentLap = 0
		elseif raceStatus == 0 then 
			-- Stoped
			self.finishedRace = false --- Maybe create separate finishe tags for qualifying VS Race
			self.stop = true
		elseif raceStatus ~= 0 then
			local estimatedCP = estimateCP(self) -- Todo: make this a separate funciton called CCp estimation
			if estimatedCP == nil then 
				print(self.racerID,"Cp estimation Fail on StarMovement")
			else
				self.CPCorrecting = true -- Is this needed?
				self:setCP(estimatedCP)
			end
		end
		self.raceStatus = raceStatus
	end
	--print(self.racerID,raceStatus)
	local nextCP = nil
	if self.map == nil then
		print(self.racerID,"map not loaded")
		--nextCP = ?
	else
		nextCP = self.map[self.nextCP]
	end
	self.location = sm.shape.getWorldPosition(self.shape)
	if self.radar == nil then
		self.radar = createRadar()
	end
	self.velocity = sm.shape.getVelocity(self.shape)
	self.radar = self:updateRadar(self.radar) -- semicomplex radar api
	if self.racerID == 1 then 
		--print(self.trackPos)
	end
	self.trackPos, self.distFromCP = self:getTrackPosition(nextCP) -- Gets location (inside to outside depending on turn)
	self:updateCheckpointStatus(nextCP) -- Just uses distFromCP to check whether or not to update to next checkpoint
	--print("CheckpointStatusupdated",nextCP)
	--print(string.format("%i: %.3f | %.3f : %.2f",self.racerID,self.trackPos,self.distFromCP,self.raceLinePref))
	--print(self.location)
	local isErr = false
	if raceStatus ~= 0 and not self.correcting and not self.stop then -- iSFINISHEDrACE USED  to be here and below
		 isErr = self:determineError()
	end
	if isErr or self.correcting and not self.stop then
		self.hittingApex = false -- Stop trying to hit the apex
		self:correctError()
		self:checkCorrection()
	end
	if raceStatus == -1 then
		self:performQualifyingOperations()
		local qualifyingRacer = getCurrentQualifier()
		--print("hello?",qualifyingRacer)
		if qualifyingRacer ~= nil then
			if qualifyingRacer.racerID == self.racerID then -- YOURE UP!
				self.stop = false
				if not self.correcting and self.dirVel < 2 then 
					self.status = 1
					self.launching = true
				end
			elseif not self.finishedRace then
				--print("no MOve")
				self.status = 0
				self.stop = true
			else
				--print("sitting here")
				if not self.correcting and self.dirVel < 2 then 
					self.status = 1
					self.launching = true
				end
			end
		else
			print("QualRacer not found")
		end

		if self.finishedRace and self.currentLap == 3 and (self.trackPos > 45 and self.trackPos <47) then
			self.status = 0
		end
	elseif raceStatus == 0 then -- If red flag/ all stop
		self.status = 0
		self.finishedRace = false
		self.stop = false
		if self.enginePower ~= 0 then
			local enPower = self.enginePower - 30
			if self.enginePower < 0 then
				enPower = 0
			end
			self:setEnginePower(enPower)
		end
	elseif raceStatus == 1 then -- Formation Lap,
		self:performFormationOperations()
		-- Need to manualy reset qualification data
		if not self.correcting then 
			self.status = 1
		end
	elseif raceStatus == 2 then -- Green flag
		if self.status >= 2 then
			--print("Green flag!")
			self.status = 1
		end
		if self.status == 0 and not self.correcting then
			self.status = 1
			self.launching = true
		end
		self:performRaceOperations() -- Params?

	elseif raceStatus == 3 then -- Yellow flag (slow/stop? sets Q for formation lap)
		self:performCautionOperations()
		if not self.correcting then 
			self.status = 1
		end
	else -- Possibilities. White and/or checkered flag
		print("Race Status Error",raceStatus)
	end
	if self.racePosition ~= 0 and not self.finishedRace then -- Double check racePoswA
		self:confirmRacePos()
	end
	if self.finishedRace then -- Maybe not have second condition
		if checkBackSide(self.radar,6) then
			if self.dirVel < 6 then
				self:setEnginePower(self.speed + 100)
			end
		end
	end
	return --0 TYODO: REMOVE THIS TO ENSURE REST OF ETING
end


function getLocal(shape, vec)
    return sm.vec3.new(sm.shape.getRight(shape):dot(vec), sm.shape.getAt(shape):dot(vec), sm.shape.getUp(shape):dot(vec))
end

function Brain.client_setPoseWeight(self, Data)
	self.interactable:setPoseWeight(Data.pose , Data.level)
end


function runningAverage(self, num)
  local runningAverageCount = 5
  if self.runningAverageBuffer == nil then self.runningAverageBuffer = {} end
  if self.nextRunningAverage == nil then self.nextRunningAverage = 0 end
  
  self.runningAverageBuffer[self.nextRunningAverage] = num 
  self.nextRunningAverage = self.nextRunningAverage + 1 
  if self.nextRunningAverage >= runningAverageCount then self.nextRunningAverage = 0 end
  
  local runningAverage = 0
  for k, v in pairs(self.runningAverageBuffer) do
    runningAverage = runningAverage + v
  end
  --if num < 1 then return 0 end
  return runningAverage / runningAverageCount;
end

