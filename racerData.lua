-- A table of racers and their data, gets read in by anyone 
-- additional getters/setters for data, shared functions by CAR AI 
--racerData.lua
--print("loading RacerData")
-- TODO: Major overhaul between client and server functions
--[[if  not sm.isHost then -- Just avoid anythign that isnt the host for now
	return
end]]
initalDataFlag = false
raceTimer = os.clock --global race clocka
 --globalish race Statusw
if not raceStatus then raceStatus = 0 end
if not racerData then racerData = {} end
if not raceCameras then
	print("Creating Camera Table")
	raceCameras = {}
end

if not droneInfo then
	print("Creating drone Data Table") 
	droneInfo = {}
end

function sortRacers()
	print("Sorting Racers")
	table.sort(racerData, racerIDCompare)
end

function sortCameras()
	print("Sorting Cameras")
	table.sort(raceCameras, cameraCompare)
end

if racerData then 
	sortRacers()
end
if raceCameras then
	sortCameras()
end

-- TODO: Add suspension bias? Default (quickestt) Suspension: 4F 7R
CarData= { -- Possibly Have different engine notes too? Up to 6
	{['id'] = 1, ['name'] = "WHR", ['TopSpeed'] = 40, ['Acceleration'] = 30, ['Downforce'] = 25, ['Q']=1, ['RaceLine']=23},
	{['id'] = 2, ['name'] = "LMR", ['TopSpeed'] = 40.4, ['Acceleration'] = 30, ['Downforce'] = 25, ['Q']=2, ['RaceLine']=23}, 
	{['id'] = 3, ['name'] = "CHS", ['TopSpeed'] = 40.3, ['Acceleration'] = 30, ['Downforce'] = 25, ['Q']=3, ['RaceLine']=23}, 
	{['id'] = 4, ['name'] = "GHP", ['TopSpeed'] = 40.3, ['Acceleration'] = 30, ['Downforce'] = 25, ['Q']=4, ['RaceLine']=23}, 
	{['id'] = 5, ['name'] = "RTH", ['TopSpeed'] = 40.2, ['Acceleration'] = 30, ['Downforce'] = 25, ['Q']=5, ['RaceLine']=23},
	{['id'] = 6, ['name'] = "BBR", ['TopSpeed'] = 40.1, ['Acceleration'] = 30, ['Downforce'] = 25, ['Q']=6, ['RaceLine']=23},
	{['id'] = 7, ['name'] = "SHZ", ['TopSpeed'] = 40.9, ['Acceleration'] = 30, ['Downforce'] = 25, ['Q']=7, ['RaceLine']=23},
	{['id'] = 8, ['name'] = "BKN", ['TopSpeed'] = 40.8, ['Acceleration'] = 30, ['Downforce'] = 25, ['Q']=8, ['RaceLine']=23},
	{['id'] = 9, ['name'] = "FDR", ['TopSpeed'] = 40.7, ['Acceleration'] = 30, ['Downforce'] = 25, ['Q']=9, ['RaceLine']=23},
	{['id'] = 10,['name'] = "LTR", ['TopSpeed'] = 40.6, ['Acceleration'] = 30, ['Downforce'] = 25, ['Q']=10,['RaceLine']=23},
	{['id'] = 11, ['name'] = "LAL", ['TopSpeed'] = 40.5, ['Acceleration'] = 30, ['Downforce'] = 25, ['Q']=11, ['RaceLine']=23},
	{['id'] = 12, ['name'] = "PSR", ['TopSpeed'] = 40.4, ['Acceleration'] = 30, ['Downforce'] = 25, ['Q']=12, ['RaceLine']=23},
	{['id'] = 13, ['name'] = "SPD", ['TopSpeed'] = 40.3, ['Acceleration'] = 30, ['Downforce'] = 25, ['Q']=13, ['RaceLine']=23},
	{['id'] = 14, ['name'] = "TYB", ['TopSpeed'] = 40.2, ['Acceleration'] = 30, ['Downforce'] = 25, ['Q']=14, ['RaceLine']=23},
	{['id'] = 15, ['name'] = "NAT", ['TopSpeed'] = 40.1, ['Acceleration'] = 30, ['Downforce'] = 25, ['Q']=15, ['RaceLine']=23},
	{['id'] = 16, ['name'] = "PKG", ['TopSpeed'] = 40, ['Acceleration'] = 30, ['Downforce'] = 25 ,['Q']=16, ['RaceLine']=23},

	{['id'] = 17, ['name'] = "F2A", ['TopSpeed'] = 35, ['Acceleration'] = 20, ['Downforce'] = 20, ['Q']=1, ['RaceLine']=27},
	{['id'] = 18, ['name'] = "F1B",['TopSpeed'] = 48, ['Acceleration'] = 40, ['Downforce'] = 55, ['0']=2, ['RaceLine']=10},
	{['id'] = 19, ['name'] = "F2C", ['TopSpeed'] = 50, ['Acceleration'] = 40, ['Downforce'] = 55, ['Q']=1, ['RaceLine']=10},
	{['id'] = 20, ['name'] = "VGD",['TopSpeed'] = 50, ['Acceleration'] = 40, ['Downforce'] = 55, ['Q']=2, ['RaceLine']=10},
	{['id'] = 21, ['name'] = "F2A", ['TopSpeed'] = 45, ['Acceleration'] = 20, ['Downforce'] = 55, ['Q']=1, ['RaceLine']=10},
	{['id'] = 22, ['name'] = "F1B",['TopSpeed'] = 50, ['Acceleration'] = 20, ['Downforce'] = 55, ['0']=2, ['RaceLine']=10},
	{['id'] = 23, ['name'] = "F2C", ['TopSpeed'] = 50, ['Acceleration'] = 40, ['Downforce'] = 55, ['Q']=1, ['RaceLine']=10},
	{['id'] = 24, ['name'] = "VGD",['TopSpeed'] = 50, ['Acceleration'] = 40, ['Downforce'] = 55, ['Q']=2, ['RaceLine']=10}
	
}
local tempQualData  = { {['racerID'] = 1, ['qualTime'] = 65.253, ['qualSplit'] = 0, ['place'] = 1},
						{['racerID'] = 2, ['qualTime'] = 65.348, ['qualSplit'] = 0, ['place'] = 2},
						{['racerID'] = 3, ['qualTime'] = 65.225, ['qualSplit'] = 0, ['place'] = 3},
						{['racerID'] = 4, ['qualTime'] = 65.339, ['qualSplit'] = 0, ['place'] = 4},
						{['racerID'] = 5, ['qualTime'] = 65.715, ['qualSplit'] = 0, ['place'] = 5},
						{['racerID'] = 6, ['qualTime'] = 65.329, ['qualSplit'] = 0, ['place'] = 6},
						{['racerID'] = 7, ['qualTime'] = 64.596, ['qualSplit'] = 0, ['place'] = 7},
						{['racerID'] = 8, ['qualTime'] = 65.353, ['qualSplit'] = 0, ['place'] = 8},
						{['racerID'] = 9, ['qualTime'] = 66.624, ['qualSplit'] = 0, ['place'] = 9},
						{['racerID'] = 10, ['qualTime'] = 65.038, ['qualSplit'] = 0, ['place'] = 10},
						{['racerID'] = 11, ['qualTime'] = 65.670, ['qualSplit'] = 0, ['place'] = 11},
						{['racerID'] = 12, ['qualTime'] = 65.081, ['qualSplit'] = 0, ['place'] = 12},
						{['racerID'] = 13, ['qualTime'] = 64.964, ['qualSplit'] = 0, ['place'] = 13},
						{['racerID'] = 14, ['qualTime'] = 65.572, ['qualSplit'] = 0, ['place'] = 14},
						{['racerID'] = 15, ['qualTime'] = 65.395, ['qualSplit'] = 0, ['place'] = 15},
						{['racerID'] = 16, ['qualTime'] = 65.617, ['qualSplit'] = 0, ['place'] = 16},
						}
			

if not qualifyingData then qualifyingData = {} end -- Contains data of the top qualifier
if not cpSplits then cpSplits = {} end 
if not cpQSplits then cpQSplits = {} end  -- Contains the splits from the top Qualifier
if not tempSplits then tempSplits = {} end 
if not finishData then finishData = {} end
if not allQualifiers then allQualifiers = {} end

if not raceControlStatus then 
	print("Creating raceControl states")
	raceControlStatus = {
		['totalCars'] = #racerData,
		['formationStatus'] = false,
		['cautionStatus']  = false,
		['currentQualifier'] = 0, 
	}
	--print(raceControlStatus)
end
--[[ Car Characteristics: (Engine on sinwave)
	Top Speed: Highest M/s value before Engine stops producing more power [21-40]
	Acceleration: Peak m/s^2 Before engine acceleration begins to decrease [0-30]
	DownForce: Allows you to have higher acceleration at lower speeds the expense of top speed  [30-100]
]]--

-- Helper functions
function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function cameraCompare(a,b)
	return a['cameraID'] < b['cameraID']
end

function racerIDCompare(a,b)
	return a['racerID'] < b['racerID']
end

function getTimeSplit(racer,cp,now)
	local checkCP = cpSplits[cp.id]
	if checkCP == nil then
		return 0
	end
	local lapDif =  cpSplits[cp.id].lap - racer.currentLap
	if lapDif >=1 then
		return "+"..lapDif
	end
	local timeDif = now - cpSplits[cp.id].time
	
	return tonumber(string.format("%.3f",timeDif))
end

function setTimeSplit(racer,cp,now)
	local leaderTime = now
	data = {['CPID'] = cp.id, ['racerID'] = racer.racerID, ['time'] = leaderTime,['lap'] = racer.currentLap}
	--table.insert(cpSplits, data)
	cpSplits[cp.id] = data
	--print(cpSplits)
end
function setTopQual(racer,time)
	print("Setting Top QualifyingData",qualifyingData)
	qualifyingData['racer'] = racer.racerID
	qualifyingData['time'] = time
	--print("CpqSplits Edit")
	cpQSplits = shallowcopy(racer.qualifyingSplits)
	--print("Set TOp Qual",cpQSplits)
end
function getSplitFromFirst(time)
	return time - qualifyingData['time']
end

function getTopQualTime()
	--print("returning QualifyingData",qualifyingData)
	return qualifyingData['time']
end

function getCurrentQualifier()
	--print("QC",raceControlStatus,raceControlStatus['currentQualifier'])
	return raceControlStatus['currentQualifier']
end

function setCurrentQualifier(racer)
	raceControlStatus['currentQualifier'] = racer
end

function getQualifyingSplit(racer,cp,now)
	local lapTime = now - racer.splitReset
	if cpQSplits == nil then
		return lapTime
	end
	local checkCP = cpQSplits[cp.id]
	--print(racer.racerID,checkCP,"getting qualifying split")

	if checkCP == nil then
		return lapTime
	end
	--print(lapTime)
	local timeDif = lapTime - cpQSplits[cp.id].time
	return string.format("%.3f",timeDif)
end

function setQualifyingSplit(racer,cp,now) -- Sets the splits for each racer
	local lapTime = now - racer.splitReset
	--print("Setting Qualifying Split",lapTime)
	data = {['CPID'] = cp.id, ['racerID'] = racer.racerID, ['time'] = lapTime, ['lap'] = racer.currentLap} -- TODO: COnvert lap to turn to show which racer went first in case of ties
	tempSplits[cp.id] = data
	return tempSplits
end

function setQualifyingData(racer,data)
	--print("setting QualData",data)
	allQualifiers[racer.racerID] = data
	--print(allQualifiers)
end

function setQualifyingMark(qualSplits)
	print("set qualifying mark")
	cpQSplits = shallowcopy(qualSplits)
end

function resetQualifyingData()
	print("Resetting all qualifying Data")
	cpSplits = {}
	cpQSplits ={}
	tempSplits = {}
	qualifyingData = {}
	allQualifiers = {}
	setCurrentQualifier(0)
end
function resetTempSplits()
	tempSplits = {}
end


---- External Datat loading!!!
function tesExternalJson()
	local variousLocations = {
		gameData = "$GAME_DATA/.../file.json",
		survivalData = "$SURVIVAL_DATA/.../file.json",
		modData = "$MOD_DATA/.../file.json",
		
	}
		
	for name, path in pairs( variousLocations ) do
		local json = sm.json.open( path )
		print("opening",name,path)
		for i, j in ipairs( json ) do
			print("loaded",json)
			print(i,j)
		end
	end
end


function setRacerQualifyPosition(racerID,place)
	racer = racerData[racerID]
	if racer.qualifyPosition ~= place then
		print("Updating place for racer",racerID,place)
		racerData[racerID].qualifyPosition = place
		allQualifiers[racer.racerID].place = racer.qualifyPosition
	end

end
--[[Q6 Results
{"id": "1", "qualTime": "77.5", "qualSplit": "0.316",  "place": "13"}
{"id": "2", "qualTime": "77.4", "qualSplit": "0.216",  "place": "7"},
{"id": "3", "qualTime": "77.435", "qualSplit": "0.251",  "place": "9"},
{"id": "4", "qualTime": "77.452", "qualSplit": "0.268",  "place": "11"},
{"id": "5", "qualTime": "77.551", "qualSplit": "0.367",  "place": "16"},
{"id": "6", "qualTime": "77.533", "qualSplit": "0.349",  "place": "14"},
{"id": "7", "qualTime": "77.216", "qualSplit": "0.032",  "place": "3"},
{"id": "8", "qualTime": "77.201", "qualSplit": "0.017",  "place": "2"},
{"id": "9", "qualTime": "77.482", "qualSplit": "0.298",  "place": "12"},
{"id": "10", "qualTime": "77.402", "qualSplit": "0.218",  "place": "8"},
{"id": "11", "qualTime": "77.184", "qualSplit": "77.184",  "place": "1"},
{"id": "12", "qualTime": "77.451", "qualSplit": "0.267",  "place": "10"},
{"id": "13", "qualTime": "77.385", "qualSplit": "0.201",  "place": "5"},
{"id": "14", "qualTime": "77.251", "qualSplit": "0.067",  "place": "4"},
{"id": "15", "qualTime": "77.536", "qualSplit": "0.352",  "place": "15"},
{"id": "16", "qualTime": "77.4", "qualSplit": "0.216",  "place": "7"}
]]

--[[Q7 Results
 {"id": "1", "qualTime": "86.351", "qualSplit": "0.433",  "place": "10"},
 {"id": "2", "qualTime": "86.268", "qualSplit": "0.350",  "place": "8"},
 {"id": "3", "qualTime": "86.352", "qualSplit": "0.434",  "place": "11"},
 {"id": "4", "qualTime": "86.352", "qualSplit": "0.434",  "place": "12"},
 {"id": "5", "qualTime": "86.403", "qualSplit": "0.485",  "place": "13"},
 {"id": "6", "qualTime": "86.287", "qualSplit": "0.369",  "place": "9"},
 {"id": "7", "qualTime": "86.234", "qualSplit": "0.316",  "place": "6"},
 {"id": "8", "qualTime": "86.119", "qualSplit": "0.201",  "place": "4"},
 {"id": "9", "qualTime": "86.667", "qualSplit": "0.749",  "place": "16"},
 {"id": "10", "qualTime": "86.234", "qualSplit": "0.316",  "place": "7"},
 {"id": "11", "qualTime": "86.017", "qualSplit": "0.099",  "place": "2"},
 {"id": "12", "qualTime": "86.434", "qualSplit": "0.516",  "place": "14"},
 {"id": "13", "qualTime": "86.118", "qualSplit": "0.200",  "place": "3"},
 {"id": "14", "qualTime": "85.918", "qualSplit": "85.918",  "place": "1"},
 {"id": "15", "qualTime": "86.467", "qualSplit": "0.549",  "place": "15"},
 {"id": "16", "qualTime": "86.13", "qualSplit": "0.212",  "place": "5"}
]]

--[[ Q8 REsults
 {"id": "1", "qualTime": "75.601", "qualSplit": "0.300",  "place": "4"},
 {"id": "2", "qualTime": "75.703", "qualSplit": "0.402",  "place": "10"},
 {"id": "3", "qualTime": "75.734", "qualSplit": "0.433",  "place": "11"},
 {"id": "4", "qualTime": "75.85", "qualSplit": "0.549",  "place": "14"},
 {"id": "5", "qualTime": "75.801", "qualSplit": "0.500",  "place": "13"},
 {"id": "6", "qualTime": "75.701", "qualSplit": "0.400",  "place": "9"},
 {"id": "7", "qualTime": "75.65", "qualSplit": "0.349",  "place": "6"},
 {"id": "8", "qualTime": "75.751", "qualSplit": "0.450",  "place": "12"},
 {"id": "9", "qualTime": "76.186", "qualSplit": "0.885",  "place": "16"},
 {"id": "10", "qualTime": "75.553", "qualSplit": "0.252",  "place": "3"},
 {"id": "11", "qualTime": "75.517", "qualSplit": "0.216",  "place": "2"},
 {"id": "12", "qualTime": "75.67", "qualSplit": "0.369",  "place": "7"},
 {"id": "13", "qualTime": "75.618", "qualSplit": "0.317",  "place": "5"},
 {"id": "14", "qualTime": "75.301", "qualSplit": "75.301",  "place": "1"},
 {"id": "15", "qualTime": "75.852", "qualSplit": "0.551",  "place": "15"},
 {"id": "16", "qualTime": "75.686", "qualSplit": "0.385",  "place": "8"}
 ]]

function setQualifyingPositions() -- Predefine and set positions
	local posTable ={4,10,11,14,13,9,6,12,16,3,2,7,5,1,15,8}
	for i = 1, #posTable do 
		local racer = racerData[i]
		--print(i)
		local qualPos = racer.qualifyPosition
		racer.qualifyPosition = posTable[i]
		print("Set preliminary qualify position",racer.racerID,qualPos,posTable[i])
	end
end




function assignQualifyingData() -- Assigns initial qualifying data
	for k=1, #allQualifiers do local v=allQualifiers[k] -- Double check the thing
		local place = 1
		local qualTime = v.qualTime
		if qualTime == nil then
			--print("No time set")
		else
			for j = 1, #allQualifiers do x=allQualifiers[j]
				if x.racerID ~= v.racerID then 
					local otherQualTime = x.qualTime
					if otherQualTime ~= nil then 
						if otherQualTime < qualTime then
							place = place + 1
						elseif qualTime == otherQualTime then
							if x.place ~= nil then
								place = place +1
							end
						end
					end
				end
			end
			setRacerQualifyPosition(v.racerID,place)
		end
	end
	-- Also Do splits
	--print("Doing Splits")
	for k=1, #racerData do local v=racerData[k]
		local split = v.qualifyingTime
		if split == nil then
			split = 0
			--print("emptyu split")
		else
			if v.qualifyPosition ~= 1 then
				split = getSplitFromFirst(split) 
				--print(v.racerID,"Split From first:",split)
			end
			if v.qualifyingTime == nil then
				--print("NOtime")
			else
				qData = {['racerID'] = v.racerID, ['qualTime'] = v.qualifyingTime, ['qualSplit'] = split, ['place'] = v.qualifyPosition}
				setQualifyingData(v,qData)
			end
		end
	end
end

function doubleCheckQualPos()
	for k=1, #allQualifiers do local v=allQualifiers[k] -- Double checking is stopped for now
		local place = 1
		local qualTime = v.qualTime
		if qualTime == nil then
			--print("No time set")
		else
			for j = 1, #allQualifiers do x=allQualifiers[j]
				if x.racerID ~= v.racerID then 
					local otherQualTime = x.qualTime
					if otherQualTime ~= nil then 
						if otherQualTime < qualTime then
							place = place + 1
						elseif qualTime == otherQualTime then
							--print("same qualifying time",x,v)
							if x.place ~= nil then
								if x.racerID < v.racerID then
									--print("first car ahead")
									place = place +1
								else
									--print("first better",x,v)
								end
							else
								print("racer hasnt gone yet?")
							end
						end
					end
				end
			end
			--print("Doublecheck=",v.racerID,place)
			--print("DQPOS",v.racerID,place)
			v.qualifyPosition = place
			allQualifiers[v.racerID].place = place
		end
		--print("endloop")
	end
end

function calculateQualifyingPos()
	local topQualPos = getTopQualTime()
	if topQualPos == nil then
		return
	end
	for k=1, #racerData do local v=racerData[k]
		local place = 1
		local qualTime = v.qualifyingTime
		if qualTime == nil then
			--print("No time set")
		else
			for j = 1, #racerData do x=racerData[j]
				if x.racerID ~= v.racerID then 
					local otherQualTime = x.qualifyingTime
					if otherQualTime ~= nil then 
						if otherQualTime < qualTime then
							place = place + 1
						elseif qualTime == otherQualTime then
							if x.qualifyPosition ~= nil then
								place = place +1
							end
						end
					end
				end
			end
			v.qualifyPosition = place
			print("QPOS",v.racerID,place)
		end
		--print("endloop")
	end
	doubleCheckQualPos()
	--[[
	for k=1, #allQualifiers do local v=allQualifiers[k] -- Double checking is stopped for now
		local place = 1
		local qualTime = v.qualTime
		if qualTime == nil then
			--print("No time set")
		else
			for j = 1, #allQualifiers do x=allQualifiers[j]
				if x.racerID ~= v.racerID then 
					local otherQualTime = x.qualTime
					if otherQualTime ~= nil then 
						if otherQualTime < qualTime then
							place = place + 1
						elseif qualTime == otherQualTime then
							if x.place ~= nil then
								place = place +1
							end
						end
					end
				end
			end
			setRacerQualifyPosition(v.racerID,place)
			
			--print("QPOS",v.racerID,place)
		end
		--print("endloop")
	end]]

	-- Also Do splits
	--print("Doing Splits")
	for k=1, #racerData do local v=racerData[k]
		local split = v.qualifyingTime
		if split == nil then
			split = 0
			--print("emptyu split")
		else
			if v.qualifyPosition ~= 1 then
				split = getSplitFromFirst(split) 
				--print(v.racerID,"Split From first:",split)
			end
			if v.qualifyingTime == nil then
				--print("NOtime")
			else
				qData = {['racerID'] = v.racerID, ['qualTime'] = v.qualifyingTime, ['qualSplit'] = split, ['place'] = v.qualifyPosition}
				setQualifyingData(v,qData)
			end
		end
	end
end

function getQualifyPos(racerID)
	for k=1, #allQualifiers do local v=allQualifiers[k]
		if v.racerID == racerID then 
			return v.place
		end
	end
end

function ratioConversion(a,b,c,d,x) -- Convert x to a ratio from a,b to  c,d
	return c+ (d - c) * (x - b) / (a - b)  -- Scale equation
end

function reverseRatioConversion(a,b,c,d,x) -- Convert x to a ratio from a,b to  c,d but backwards
	return c+ (d - c) * (x - a) / (b - a)  -- Scale equation
end

function convertTopSpeedToECU(speed) -- converts the top speed (m/s) to ecu values (fraction)
	--[A,B] - [C,D] [17,40?] - [0.15,0.008]
	-- C+(D−C)*(x−A)/(B−A)  -- Scale equation
	-- Calculate ECU Conversion
	local masterSpeed = -1
	if masterSpeed ~= -1 then 
		--print("running master")
		speed = masterSpeed
	end

	minECU = 0.008
	maxECU = 0.15
	minSpeed = 17
	maxSpeed = 40
	if speed == 0 then return 0 end
	local convertedECUNew = ratioConversion(minSpeed,maxSpeed,minECU,maxECU,speed) -- Switch to this when necessary
	local convertedECU = maxECU + (minECU - maxECU) * (speed - minSpeed) / (maxSpeed)
	return convertedECU
end

function convertDownforceToECU(downforce) -- converts the downforce (int) to ecu df (fraction)
	local convertedDownforce = downforce /100
	return convertedDownforce
end

--[[function debugPrint(racer,content)
	if racer.racerID == 1 then
		print(content)
	end
end]]

function getRaceStatus()
	return raceStatus
end

function setRaceStatus(status)
	if status ~= raceStatus then
		if status == 3 then
			setCautionPositions()
		elseif status == 2 then
			--- GreenFlag
		elseif status == 1 then
			setFormationPositions()
		else
		end
		raceStatus = status
		outputRaceStatus(status)
	end
end

function setCautionPositions()
	for k=1, #racerData do local v=racerData[k]
		local curPos = v.racePosition
		if curPos == 0 then 
			curPos = v.qualifyPosition
		end
		v.cautionPosition = curPos
		print(v.racerID,":",curPos)
	end
	--print("Set caution Positions")
end

function setCautionCarToFollow(racer)
	if racer.cautionPosition == 1 then
		--print(racer.racerID, "Is in lead") 
		return 0
	end
	for k=1, #racerData do local v=racerData[k]
		if v.cautionPosition == racer.cautionPosition - 1 then 
			--print(racer.racerID, "Follow",v.racerID)
			return v
		end
	end
	
end

function getCautionRacers(racer)
	local shouldPass = false
	local letPass = false
	--local distF = nil 
	local goalCar = racer.followCar.racerID
	local distF, frontCar = getClosestFrontRacer(racer)
	local distB, backCar = getClosestBackRacer(racer)

	if frontCar ~= nil then
		if frontCar.cautionPosition > racer.cautionPosition and goalCar ~= 0  and distF <= 60 then -- Pass
			shouldPass = true

			if frontCar.racerID == goalCar then 
				print(racer.racerID, "Should not be trying to pass", frontCar.racerID)
			end
		end
		if frontCar.racerID == goalCar then -- Inline
			shouldPass = false
		else 
			--print(racer.racerID,"notinLIne")
		end
	end
	if backCar ~= nil and racer.cautionPosition ~= #racerData and goalCar ~= 0  and distB <= 30 then
		if backCar.cautionPosition < racer.cautionPosition then -- Let pass
			letPass = true
		end
	end
	if distF == nil then
		distF = 11
	end
	return shouldPass, letPass, distF
end

function setFormationStatus(status)
	--print(raceControlStatus['formationStatus'],"Set",status)
	if raceControlStatus['formationStatus'] ~= status then
		--print("settingformation check to ",status)
		raceControlStatus['formationStatus'] = status
		print("Formation status,","set to",raceControlStatus['formationStatus'])
	end
end

function getFormationStatus()
		return raceControlStatus['formationStatus']
end

function checkFormation()
	local inLine = true
	for k=1, #racerData do local v=racerData[k]
		if v.followCar == nil then 
			print(v.racerID,"Formation Position not set")
			-- TODO: Set formation position
			return false
		end
		--print("CHECKING:",v.racerID)
		if v.qualifyPosition ~= v.racePosition then 
			inLine = false
			--print(v.racerID,"out of pos line")
		end
		local dis, racer = getClosestFrontRacer(v)
		--print(dis,racer)
		if v.nextCP > 2 then
		--	--print("Not on front stretch") short runways nofair here
			inLine = false
		end

		if racer == nil then
			if v.qualifyPosition ~= 1 then
				--print(v.racerID,"nil followCar")
				inLine = false
			end
		end
		
		if v.followCar ~= 0 and racer ~= nil and v.followCar.racerID ~= racer.racerID then -- ALIGNment checking for formations
			if dis ~= nil then
				if dis < 18 and inline then
					print(v.racerID,"isaligned")
					v.isAligned = true
				end
			else
				--print(v.racerID,"not alligntd")
				v.isAligned = false
			end
		else 
			--print(v.racerID,"not alligntd")
			v.isAligned = false
		end
		if inLine  then 
			--print(v.racerID,"inline")
			v.isAligned = true
		end
	end

	if inLine and not getFormationStatus() then
		print("All racers Inline")
	end
	return inLine
end

function checkRacerinFormation() -- Checks the information boolean of racers when they are aligned for races.
	local allGreen = true
	for k=1, #racerData do local v=racerData[k]
		if not v.inFormationPlace then 
			--print(v.racerID, "Not inplace")
			allGreen = false
		end
	end
			
	return allGreen
end

function setFormationPositions()
	for k=1, #racerData do local v=racerData[k]	
		--print("CHecking",v.racerID,v.qualifyPosition)
		if v.qualifyPosition == 0 then -- If the qualifyiPos somehow got stuck
			v.qualifyPosition = getQualifyPos(v.racerID)
		end
		if v.qualifyPosition == nil then
			v.qualifyPosition = v.racerID
		end
		local formationLane = v.qualifyPosition %2
		print(v.racerID,":",v.qualifyPosition,formationLane)
		v.formationLane = formationLane
		v.cautionPosition = v.qualifyPosition
	end
	--print("Set Formation Lanes")

end
function setFormationCarToFollow(racer)
	if racer.qualifyPosition == 1 then
		--print(racer.racerID, "Is in lead") 
		return 0,0
	end
	local cautionCar
	local formationCar
	for k=1, #racerData do local v=racerData[k]
		if v.qualifyPosition == racer.qualifyPosition - 1 then 
			--print(racer.racerID, "Follow",v.racerID)
			cautionCar =  v
		end
		if racer.qualifyPosition > 2 then 
			if v.qualifyPosition == racer.qualifyPosition - 2 then 
				formationCar = v
			end
		else
			formationCar = 0
		end
	end
	--print(racer.racerID,"C",cautionCar,"F",formationCar)
	return cautionCar,formationCar
end

function getCheckpointVHOffset(racer,point) -- Returns the vertical and horizontal position of a checkpoint (x1,y1) relative to racer's front (+-Dist)
	-- Check if point is racer or not?
	local relativePos = {['x'] = (racer.location.x - point['x1']), ['y'] = (racer.location.y - point['y1']), ['z'] = (racer.location.z)}
	local relativeVec = sm.vec3.new(relativePos['x'],relativePos['y'],relativePos['z'])--vector generated by the difference of  positions,
	
	local goalDirection = racer.goalDirection
	--local frontVector = racer.shape.getAt(racer.shape) -- Wherever car is facing
	local frontVector = nil
	if goalDirection == 0 then 
		frontVector = sm.vec3.new(0,1,0)
	elseif goalDirection == 1 then
		frontVector = sm.vec3.new(1,0,0)
	elseif goalDirection == 2 then
		frontVector = sm.vec3.new(0,-1,0)
	elseif goalDirection == 3 then
		frontVector = sm.vec3.new(-1,0,0)
	end
		
	--frontVector = flatenVector(frontVector)
	--local normalRelVec = sm.vec3.normalize(relativeVec) -- uneccessary?
	local dotedVector = sm.vec3.dot(frontVector,relativeVec) -- Dotted vector gets if car is in front/behind at what angle, but not Left/Right
	local crossVector = sm.vec3.cross(relativeVec,frontVector)
	local horizontalPos = getSign(crossVector.z) -- Gets sign  from crossed vector which returns + for right & - for left
	--local vecelen2 = sm.vec3.length2(crossVector) -- less resource intensive, will need to convert
	local hVecLen= sm.vec3.length(crossVector) -- return s 0 - 50? -- Horizontal offset from singular point
	local vVecLen= dotedVector -- return int, if negative, behind cp (hopefully)
	--print(vVecLen)
	--local verticalPos = getSign(dotedVector)
	--print("CPVHO",hVecLen,vVecLen)
	-- Hint: negative vVec means checkpoint is on right of car, positive means cp is on left
	return hVecLen,vVecLen
end

function setFinishData(racer)
	local data = {["id"]= racer.racerID, ["bestLap"] = racer.bestLapTime, ["place"] = racer.finishPosition, ["timeSplit"]= racer.timeSplit}
	finishData[racer.racerID] = data
end
--[[
local upDir = self.shape:getUp()
	--print(upDir)
	local frontDir = self.shape:getAt()
	local offset =0
	if getSign(frontDir.x) == -1 then 
		offset = getSign(upDir.x)
	else
		offset = getSign(upDir.y)
	end
	if math.abs(upDir.y) > 0.4 or math.abs(upDir.x) > 0.4  or upDir.z > -0.6 then  
		local correctionVec = sm.vec3.new(0,0,-2000) --("Have this be calculated depending on angle?")
		sm.physics.applyImpulse( self.shape.body, correctionVec,0,sm.vec3.new(0,offset,offset))
	end

]]
function checkTilted(racer) -- TODO: Dive into this one for untilting
	local offset = 0 
	local upDir = racer.shape:getUp()
	local frontDir = racer.shape:getAt()
	if getSign(frontDir.x) == -1 then 
		offset = getSign(upDir.x)
	else
		offset = getSign(upDir.y)
	end
	if math.abs(upDir.y) > 0.6 or math.abs(upDir.x) > 0.6  or upDir.z > -0.8 then  
		return true, offset
	
	end


	local onNose = -0.5
	--print(racer.shape.worldRotation.z)
	if math.abs(racer.shape.worldRotation.z) > 0.25 then 
		--print("Car Tilted")
		return true, offset
	end
	--print("notTiltes")
	return false
end

function estimateCP(racer) --  TODO: Fix These so it estimates properly --Estimates Which cp the car is by, Starts off with current, last, then next
	--print(racer.racerID,racer.stuck, racer.correctionTimeout, racer.dirVel)
	local checkMode = 0 -- 0: check closest cp, 1: check furthest cp
	if racer.correctionTimeout >= 10 and math.abs( racer.dirVel ) <= 1 then -- seconds car has been stuck, possibly check against racer.stuck too TODO: add time to global changable defines
		--print(racer.racerID," has been stuck for too long, changign to check furthest cp")
		checkMode = 1
	end
	
	local estimatedCp = nil
	local allCps = racer.map -- REpopluate all CPs with only the few that are closest
	local totalCP = #racer.map
	local closestCP = findClosestCP(racer,checkMode) -- TODOL Probably  can return list of cps car is within,
	local adjacentCPs = {}
	if closestCP ~= nil then
		for i=-1,1, 1 do 
			local cpIndex =  (closestCP.id + i) %totalCP +1
			local cp = allCps[cpIndex]
			--print(racer.racerID,"appending",i,cpIndex,cp.id)
			table.insert(adjacentCPs,cp)
		end
	else-- if the closest hasnt been found for some reason
		adjacentCPs = allCps -- Just default to checking all of them
	end
	

	local longestDistAway = nil
	-- Check CP Loop
	local curCp = racer.curCP -- Dont need this, because it will always be index 2 in adjacent, however if adjacent is longer than 3 then it should use it as index
	local cp = adjacentCPs[2] -- Should always be the middle one... as the current cp
	local isProper, distAway = checkCP(racer,cp)
	
	if isProper then 
		estimatedCP = cp
		longestDistAway = distAway
	end
	
	for i= 1,#adjacentCPs,1 do -- for every adjacent cp, 
		--cp = i %totalCP +1
		cp = adjacentCPs[i]
		local isProper, distAway = checkCP(racer,cp)
		if isProper then 
			if racer.racerID == 1 then
				--print(isProper,cp.id,estimatedCp,distAway)
			end
			if estimatedCp == nil or distAway < longestDistAway then
				if racer.racerID == 2 then
					--print(racer.racerID,"Found shorter cp",cp,estimatedCp,distAway,longestDistAway)
				end
				estimatedCp = cp 
				longestDistAway = distAway
			end
		end -- else, fall through and continue
	end
	--print(racer.racerID,"estimated",estimatedCP)
	return estimatedCp
end

function checkCP(racer,cp) -- CHecks the CP and verifies that cart is within rangeeee and also behind
	local offTrack, distOff, distAway = checkOffTrack(racer,cp)
	if not offTrack then -- If car is between checkpoint
		--print(curCp,"onTrack")
		
		if distAway ~= nil then -- Error checking
			isBehind = checkIsBehind(racer,cp)
			if distAway >= -12 and isBehind then -- and isBehind? If car is behind Cp in any way
				if racer.racerID == 3 then
					--print(racer.racerID,"found Good CP",cp.id,distAway)
				end
				return true, distAway
			else -- If car is ahead of Cp, try to move forward
				--print("Not proper cp")
				return false, distAway 
			end
		else
			print("Error when finding offtrack distance")
			return false, 0
		end
	else
		--print("Not on track")
		return false, 0
	end
end


function findClosestCP(racer,checkMode) -- finds checkpoint closest to racer TODO: Figure out exaclty when this is called
	local closestDist = nil
	local closestCP = nil
	local allCps = racer.map
	local totalCP = #racer.map
	for i= 1,(#racer.map),1 do -- Check every checkpoint to find the closest
		cp = i %totalCP +1
		cp = allCps[cp]
		isOff,offDist,distAway = checkOffTrack(racer,cp)
		if isOff == false then -- IF within the constraints,
			--print(racer.racerID, "withinCP",offDist,distAway,cp.id)
			local insideCorner = {['x'] = cp.x1, ['y'] = cp.y1}
			local distance = getDistance(racer.location,insideCorner)
			if checkMode == 0 then 
				if closestDist == nil or distance < closestDist then
					--print(racer.racerID,"closer:",cp.id)			
					closestDist = distance
					closestCP = cp
				end
			elseif checkMode == 1 then -- Calculates the farthest checkpoint within range, should only have to choose between two hopefully, will fix later
				if closestDist == nil or distance > closestDist then
					--print(racer.racerID,"closer:",cp.id)			
					closestDist = distance
					closestCP = cp
				end
			end
		end
	end

	if closestCP == nil then -- Possibly use the closest distance OFF from the "invalid Cps"
		print(racer.racerID,"Trouble finding CP")
	end
	return closestCP

end



function checkIsBehind(racer,cp) -- checks that the racer is not ahead of the cp
	local goalDirection = (cp['dir'] - cp['action']) % 4
	local distanceAway = nil
	if goalDirection == 0 then
		local location = math.min(cp.y1,cp.y2) -- Can make this more efficient --- if 2 then math.max if 1 then maxX if 3 then min x
		distanceAway =  location - racer.location.y
	elseif goalDirection == 1 then
		local location = math.min(cp.x1,cp.x2) -- Can make this more efficient --- if 2 then math.max if 1 then maxX if 3 then min x
		distanceAway = location - racer.location.x 
	elseif goalDirection == 2 then
		local location = math.max(cp.y1,cp.y2) -- Can make this more efficient --- if 2 then math.max if 1 then maxX if 3 then min x
		distanceAway = racer.location.y - location -- Revberse?
	elseif goalDirection == 3 then
		local location = math.max(cp.x1,cp.x2) -- Can make this more efficient --- if 2 then math.max if 1 then maxX if 3 then min x
		distanceAway = racer.location.x - location -- Reberse?
	
	end
	
	if distanceAway >=0 then
		if racer.racerID == 3 then
			--print(cp.id,goalDirection,distanceAway,"isBehind")
		end
		return true
	else
		return false
	end
	return false
end


function getSign(x) -- helper function until they get addes separtgely
    if x<0 then
      return -1
    elseif x>0 then
      return 1
    else
      return 0
    end
 end



 function getRacerData(racerID) -- Returns the shape/data of racer (from racerID)
	--print("getRacerData",racerID,racerData)
	for k=1, #racerData do local v=racerData[k]
		if v.racerID == racerID then 
			return v
		end
	end
end

function getCarData(racerID) -- Returns the customizable engine data (carData) of racer (from racerID)
	for k=1, #CarData do local v=CarData[k]
		if v.id == racerID then 
			return v
		end
	end
end

function getRacerByIndex(racerIndex) -- Returns all racer data in racerData according to racerIndex
	if racerIndex <= 0 or racerIndex == nil then
		print("Getting racer index error",racerIndex)
		return nil
	end
	return racerData[racerIndex]
end

function getPosition(racerID) -- Gets race Posistion of racer accoring to racerID
	local racer= getRacerData(racerID)
	
	if racer == nil then 
		print("GetPosition: Invalid Race ID",racerID,racer)
		return 0
	end
	local position = racer.racePosition
	if position == nil then
		print("getPos: Racer Position is nil")
		return 0
	end
	return position
end

function getRacerByPos(racePos) -- Return whole racer based off of race posistion
	for k=1, #racerData do local v=racerData[k]
		if v.racePosition == racePos then 
			--print("v")
			return v
		end
	end
end

function getIDFromPos(racePos)
	for k=1, #racerData do local v=racerData[k]
		if v.racePosition == racePos then 
			return v.racerID
		end
	end
end

function getLapsLeft()
	for k=1, #racerData do local v=racerData[k]
		if v.racePosition <= 1 then 
			return (v.totalLaps - v.currentLap)
		end
	end
end

function getRelativeSpeed(racer,racerB)
	local relSpeed = racer.dirVel - racerB.dirVel
	--print(string.format("REl = %.2f",relSpeed))
	--if relSpeed < 10 then return 10 end
	return relSpeed
end

function getBoost(racerID)
	local racer= getRacerData(racerID)
	if racer == nil then return 0 end
	local boost = racer.boost
	if boost == nil then return 0 end
	--print("Booost",boost)
	return boost
end

function getBrakes(racerID)
	local racer= getRacerData(racerID)
	if racer == nil then return 0 end
	local brakes = racer.brakePower
	if brakes == nil then return 0 end
	--print("Booost",boost)
	return brakes
end

function getExitTurn(racerID)
	local racer= getRacerData(racerID)
	if racer == nil then return false end
	local exitTurn = racer.exitTurn
	if exitTurn == nil then return false end
	--print("exit",exitTurn)
	return exitTurn
end

function getStatus(racerID)
	local racer= getRacerData(racerID)
	if racer == nil then return 0 end
	local status = racer.status
	if status == nil then return 0 end
	return status
end

function getDistance (locationA, locationB)
	local dx = (locationB.x - locationA.x)^2
	local dy = (locationB.y - locationA.y)^2

	return math.sqrt(dx + dy)
end

function get2Ddistance(p1,p2)
	return  math.abs(p1) - math.abs(p2)
end

-- Positional helpers

function distanceBehind(racerA, racerB) -- returns offset behind

	local currentDir = racerA.currentDirection

	local diffX = racerA.location.x - racerB.location.x
	local diffY = racerA.location.y - racerB.location.y

    if currentDir == 0 then -- if north, check if y is greater
		return diffY
	end 
	if currentDir == 2 then -- if south, check if y is lesser
		 return -diffY
	end

	if currentDir == 1 then -- if east, check if X is greater
		return diffX
	end 
	if currentDir == 3 then -- if west, check if y is lesser
		return -diffX
	end
	return 0 -- shouldnt come to this but just in case
end

function distanceOnside(racerA,racerB) -- returns offset on side

	local currentDir = racerA.currentDirection
	local diffX,diffY
	if type(racerB) == "Vec3" then -- probably checking a checkpoint
		 diffX = racerA.location.x - racerB.x
		 diffY = racerA.location.y - racerB.y
	else
		 diffX = racerA.location.x - racerB.location.x
		 diffY = racerA.location.y - racerB.location.y
	end

	if currentDir == 0 then -- if north, check if X is greater
		return diffX
	end 
	if currentDir == 2 then -- if south, check if X is lesser
		return -diffX
	end

	if currentDir == 1 then -- if east, check if Y is greater
		return -diffY
	end 
	if currentDir == 3 then -- if west, check if Y is lesser
		return diffY
    end
    
	return 0
end

function getDistanceFront(racer) -- Runs a distance Raycast for any object in front
	local hit,dist = sm.physics.distanceRaycast(racer.location,racer.shape.at*20) 
	if hit then
		return dist *20 
	end
	return false
end

function getDistanceBack(racer)
	local hit,dist = sm.physics.distanceRaycast(racer.location,racer.shape.at*-20) 
	if hit then
		return dist *20
	end
	return false
end

function calculateTurnLimit(racer,trackPos) -- TODO: Mess with this to get better turning
	local turnLimit = 0
	local maxTurn = 55 -- Can be pulled from handling?
		
	local minTurn = 9
	local turnMult = -.9
	
	if racer.isPassing then 
		turnMult = -0.3
	end
	if trackPos <20 then 
		turnMult = -0.5
	else
		turnMult = -0.9
	end
	
	turnLimit = 1.6/(0.003*(trackPos-1))
	minTurn = 9
	turnLimit = turnLimit*1.5
	
	if turnLimit < minTurn then 
		turnLimit = minTurn
	elseif turnLimit > maxTurn then
		turnLimit = maxTurn
	end

	if racer.finishedRace then turnLimit = turnLimit / 2 end
	return turnLimit
end

function isInCP(location,cp) -- Callthis Onupdate, not onFixedUpdate
	local minX = math.min(cp['x1'],cp['x2'])
	local minY = math.min(cp['y1'],cp['y2'])
	local maxX = math.max(cp['x1'],cp['x2'])
	local maxY = math.max(cp['y1'],cp['y2'])
	if location.x > minX and location.x < maxX then
		if location.y > minY and location.y < maxY then
			return true
		end
	end
	return false
end

function distanceFromCp(location,cp)
	local distance = -1
	local minX = math.min(cp.x1,cp.x2)
	local minY = math.min(cp.y1,cp.y2)
	local maxX = math.max(cp.x1,cp.x2)
	local maxY = math.max(cp.y1,cp.y2)
	if location.x > minX and location.x < maxX then
		distance = get2Ddistance(location.y, minY)
		--print("between X coords",distance)
	end

	if location.y > minY and location.y < maxY then
		distance = get2Ddistance(location.x, minX)
		--print("between Y coords",distance)
	end
	return distance 
end

function determineOffTrack(racer)
	local isOff = false
	local offDist = 0
	local cp = racer.cpData
	local goalMult = 1
	--print("determindOff",cp)
	if racer.goalDirection == 0 or racer.goalDirection == 2 then 
		if racer.goalDirection == 2 then 
			goalMult = -1
		end
		local side1 = math.max(cp.x1,cp.x2)
		local side2 = math.min(cp.x1,cp.x2)
		local locX = racer.location.x
		--print(side1,side2,racer.location.x)
		if locX >= side1 then 
			isOff = true
			offDist = (side1 - locX) * goalMult
		elseif locX <= side2 then
			isOff = true
			offDist = (side2 - locX) * goalMult
		end
	elseif racer.goalDirection == 1 or racer.goalDirection == 3 then 
		if racer.goalDirection == 1 then 
			goalMult = -1
		end
		--print("huh?",cp)
		local side1 = math.max(cp.y1,cp.y2)
		local side2 = math.min(cp.y1,cp.y2)
		local locY = racer.location.y
		if locY >= side1 then 
			--print("side1")
			isOff = true
			offDist = (side1 - locY)  * goalMult
		elseif locY <= side2 then
			isOff = true
			--print('side2')
			offDist = (side2 - locY) * goalMult
		end
	end
	--print(isOff,offDist)
	if racer.racerID == 2 then
		if isOff then
			--print("isOffcurrentCp",cp)
		end
	end
	return isOff,offDist
end

function checkOffTrack(racer,cp) -- Determines if racer is within cp and how far ahead/behind it is
	local isOff = false
	local offDist = 0
	local distAway = nil
	local goalMult = 1
	local goalDirection = (cp['dir'] - cp['action']) % 4
	
	if goalDirection == 0 or goalDirection == 2 then
		local side1 = math.max(cp.x1,cp.x2)
		local side2 = math.min(cp.x1,cp.x2)
		local side3 = cp.y1 -- Front
		local locX = racer.location.x 
		if goalDirection == 2 then 
			goalMult = -1
		end

		distAway = (side3 - racer.location.y) * goalMult
		if locX >= side1 then 
			isOff = true
			offDist = (side1 - locX) * goalMult
		elseif locX <= side2 then
			isOff = true
			offDist = (side2 - locX) * goalMult
		end
	elseif goalDirection == 1 or goalDirection == 3 then 
		local side1 = math.max(cp.y1,cp.y2)
		local side2 = math.min(cp.y1,cp.y2)
		local side3 = cp.x1
		local locY = racer.location.y
		if goalDirection == 1 then 
			goalMult = -1
		end
			
		distAway =  (racer.location.x -side3) * goalMult
		if locY >= side1 then 
			isOff = true
			offDist = (side1 - locY)  * goalMult
		elseif locY <= side2 then
			isOff = true
			offDist = (side2 - locY) * goalMult
		end
	end
	--print(cp.id,distAway)
	return isOff,offDist,distAway
end

function  updateRacerPositions(racer,place,rePlace) -- Replaces racer's place if another has same place, TODO: USe this when making new pos checker algo
	for k=1, #racerData do local v=racerData[k]
		if v ~= nil and racer.racerID ~= v.racerID then 
			--print("looking for someone not me",place,self.place,raceData['place'])
			if place == v.racePosition then
				--print("found conflicting place",raceData['color'],raceData['place'],place,self.place)
				v.racePosition = rePlace
				--print('replaced',v.racerID,rePlace)
			end
			
		end
	end
end

function calculateRacePosition(racer) -- calculates and return position based on number of racers and laps and checkpoint TODO: Update this
	local position = racer.racePosition
	local count = #racerData
	--print("Cars = ",count)
	for k=1, #racerData do local v=racerData[k]
		--print(v.racerID,v.racePosition)
		if v.racerID ~= racer.racerID then 
			if racer.currentLap > v.currentLap then -- if a lap down
				--print("Lap ahead",racer.currentLap)
				--v.racePosition = position
				count = count - 1
			elseif racer.currentLap == v.currentLap then -- if on same lap calculate cp id
				--print("same lap")
				if racer.curCP > v.curCP then -- if a cp ahead
					--v.racePosition = position
					count = count - 1
				elseif racer.curCp == v.curCP then -- if on same cp
					print("on same cp") -- perform pos calc?
					return position
				end
			end
		end
	end
	--print("")
	updateRacerPositions(racer,count,position)
	return count
end

function getClosestRacer(racer) -- returns object and distance of closest car to Racer
	local closestRacer = nil -- Racer object
	local closestDistance = nil

	for k=1, #racerData do local v=racerData[k]
		if v.racerID ~= racer.racerID then 
			local dis = getDistance(racer.location,v.location)
			if closestDistance == nil or dis < closestDistance then
				closestRacer = v
				closestDistance = dis
			end
		end
    end
    return closestDistance, closestRacer
end

function getRacersInRange(racer,range) -- returns object and distance of closest car to Racer
	local closestRacers = {}  -- list of racers

	for k=1, #racerData do local v=racerData[k]
		if v.racerID ~= racer.racerID then 
			local dis = getDistance(racer.location,v.location)
			if  dis <= range then
				--print("gotless",v)
				table.insert(closestRacers,{v,dis})
			end
		end
    end
    return closestRacers
end

function getDistFromRacer(racer,target) -- returns object and distance of target that is behind racer TODO: Just do any target
	local distance = nil
	for k=1, #racerData do local v=racerData[k]
		if v.racerID == target then 
			if distanceBehind(racer,v) <0 then
				distance = getDistance(racer.location,v.location)
			end
		end
    end
    return distance
end

function getClosestFrontRacer(racer) -- returns object and distance of closest car in front
	local closestRacer = nil -- Racer object
	local closestDistance = nil
	for k=1, #racerData do local v=racerData[k]
		if v.racerID ~= racer.racerID then 
			if distanceBehind(racer,v) <0 then
				local dis = getDistance(racer.location,v.location)
				if closestDistance == nil or dis < closestDistance then
					closestRacer = v
					closestDistance = dis
				end
			end
		end
    end
    return closestDistance, closestRacer
end

function getClosestBackRacer(racer) -- returns object and distance of closest car behind
	local closestRacer = nil -- Racer object
	local closestDistance = nil
	for k=1, #racerData do local v=racerData[k]
		if v.racerID ~= racer.racerID then 
			if distanceBehind(racer,v) >0 then
				local dis = getDistance(racer.location,v.location)
				if closestDistance == nil or dis < closestDistance then
					closestRacer = v
					closestDistance = dis
				end
			end
		end
    end
    return closestDistance, closestRacer
end

--- Data OUTPUTING FUNCTIONs-----
function outputRacerCameraData()
	print("---------Racer List----------")
	for k=1, #racerData do local v=racerData[k]
		if v ~= nil then 
			local carInfo = getCarData(v.racerID)
			local output = ''.. k ..':'..carInfo.name..''
			sm.log.info(output)
		end
	end
	print("-----------------------------")
end

function outputQualifyingData()
	if #allQualifiers == 0 then
		return
	end
	doubleCheckQualPos()
	local outputString = 'qualifying_data= [ '
	for k=1, #allQualifiers do local v=allQualifiers[k]
		if v ~= nil then
			local qualSplit = string.format("%.3f",v.qualSplit)
			local output = '{"id": "'.. v.racerID..'", "qualTime": "'..v.qualTime..'", "qualSplit": "'..qualSplit..'",  "place": "'..v.place..'"},'
			outputString = outputString .. output
		end
	end
	local noCommaEnding = string.sub(outputString,1,-2)
	local endString = ']'
	outputString = noCommaEnding .. endString 
	sm.log.info(outputString)
end

function outputTimeSplit(v,time)
	local output = 'split_data= {"id": "'.. v.racerID..'", "timeSplit": "'..time..'"}'
	sm.log.info(output)
end

function outputData() -- Outputs race data into a  big list
	local outputString = 'smarl_data= [ '
	for k=1, #racerData do local v=racerData[k]
		if v ~= nil then
			local output = '{"id": "'.. v.racerID..'", "locX": "'..v.location.x..'", "locY": "'..v.location.y..'", "lastLap": "'..v.lastLapTime..'", "bestLap": "'..v.bestLapTime ..'", "lapNum": "'.. v.currentLap..'", "place": "'.. v.racePosition..'", "timeSplit": "'.. v.timeSplit..'"},'
			outputString = outputString .. output
		end
	end
	local noCommaEnding = string.sub(outputString,1,-2)
	local endString = ']'
	outputString = noCommaEnding .. endString 
	sm.log.info(outputString)
end

function outputSingleData(v)
	local output = 'smarl_data= {"id": "'.. v.racerID..'", "locX": "'..v.location.x..'", "locY": "'..v.location.y..'", "lastLap": "'..v.lastLapTime..'", "bestLap": "'..v.bestLapTime ..'", "lapNum": "'.. v.currentLap..'", "place": "'.. v.racePosition..'", "timeSplit": "'.. v.timeSplit..'"}'
	sm.log.info(output)
end

function outputRaceStatus(status) -- Get to output like laps or anything else,
	local lapsLeft = getLapsLeft()
	if lapsLeft == nil then
		lapsLeft = "--"
	end
	local output = 'race_status= {"status": "'.. status..'", "lapsLeft": "'.. lapsLeft..'"}'
	sm.log.info(output)
end


function outputFinishData()
	local outputString = 'finish_data= [ '
	for k=1, #racerData do local v=racerData[k]
		if v ~= nil and v.finishedRace then
			local output = '{"id": "'.. v.racerID..'", "bestLap": "'..v.bestLapTime ..'", "place": "'.. v.racePosition..'", "qualPos": "'.. v.qualifyPosition..'", "split": "'.. v.timeSplit..'"},'
			outputString = outputString .. output
		end
	end
	local noCommaEnding = string.sub(outputString,1,-2)
	local endString = ']'
	outputString = noCommaEnding .. endString 
	sm.log.info(outputString)

end

setFinishDataTable = {
	{['racerID'] = 1, ['bestLap'] = 65.253, ['place'] = 0, ['place'] = 1},
	{['racerID'] = 2, ['qualTime'] = 65.348, ['qualSplit'] = 0, ['place'] = 2},
	{['racerID'] = 3, ['qualTime'] = 65.225, ['qualSplit'] = 0, ['place'] = 3},
	{['racerID'] = 4, ['qualTime'] = 65.339, ['qualSplit'] = 0, ['place'] = 4},
	{['racerID'] = 5, ['qualTime'] = 65.715, ['qualSplit'] = 0, ['place'] = 5},
	{['racerID'] = 6, ['qualTime'] = 65.329, ['qualSplit'] = 0, ['place'] = 6},
	{['racerID'] = 7, ['qualTime'] = 64.596, ['qualSplit'] = 0, ['place'] = 7},
	{['racerID'] = 8, ['qualTime'] = 65.353, ['qualSplit'] = 0, ['place'] = 8},
	{['racerID'] = 9, ['qualTime'] = 66.624, ['qualSplit'] = 0, ['place'] = 9},
	{['racerID'] = 10, ['qualTime'] = 65.038, ['qualSplit'] = 0, ['place'] = 10},
	{['racerID'] = 11, ['qualTime'] = 65.670, ['qualSplit'] = 0, ['place'] = 11},
	{['racerID'] = 12, ['qualTime'] = 65.081, ['qualSplit'] = 0, ['place'] = 12},
	{['racerID'] = 13, ['qualTime'] = 64.964, ['qualSplit'] = 0, ['place'] = 13},
	{['racerID'] = 14, ['qualTime'] = 65.572, ['qualSplit'] = 0, ['place'] = 14},
	{['racerID'] = 15, ['qualTime'] = 65.395, ['qualSplit'] = 0, ['place'] = 15},
	{['racerID'] = 16, ['qualTime'] = 65.617, ['qualSplit'] = 0, ['place'] = 16},

}

function outputSetFinishData() -- Dothis later
	local outputString = 'finish_data= [ '
	for k=1, #racerData do local v=racerData[k]
		if v ~= nil and v.finishedRace then
			local output = '{"id": "'.. v.racerID..'", "bestLap": "'..v.bestLapTime ..'", "place": "'.. v.racePosition..'", "qualPos": "'.. v.qualifyPosition..'", "split": "'.. v.timeSplit..'"},'
			outputString = outputString .. output
		end
	end
	local noCommaEnding = string.sub(outputString,1,-2)
	local endString = ']'
	outputString = noCommaEnding .. endString 
	sm.log.info(outputString)
end

if not sm.smarlFunctions then --TODO: add more global functions that connect to tool too
	sm.smarlFunctions = {} 
	sm.smarlFunctions['setRaceStatus'] = setRaceStatus
end
