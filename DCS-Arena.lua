-------------------------------
--User setings
-------------------------------

--starting credits
BlueCredits = 200
RedCredits = 200

--Credits undefined units are worth when killed
CreditsUnknownUnit = 1

--Name of zone in where unit placement is allowed
BlueSpawnZoneName = "spawnzoneblue"
RedSpawnZoneName = "spawnzonered"

--number of HQ zones defined in the editor
RedHQZones = 17
BlueHQZones = 17

--Time to instantly place units at start
SpawnTimerLimit = 900

--Time until hint of location for the enemy HQ is given
HintTimer = 1800

--no longer used sam ressuply timer t.b.r
Samresupplytimer = 6000

--------------------------------
--Don'change anything below here
--------------------------------

UnitTable = {}

UnitTable["tank"] = 2		-- MBT
UnitTable["artillery"] = 3	-- Artillery
UnitTable["aaa"] = 4		-- aaa 
UnitTable["samsr"] = 10 	-- short range Sa-6 / Hawk
UnitTable["sampd"] = 10		-- sam-point defence Sa-15 / Roland
UnitTable["samlr"] = 20 	-- long range S300 / Patriot

ClientCost = {}

ClientCost["A-10A"] = 5
ClientCost["A-10C"] = 5
ClientCost["A-10C_2"] = 5
ClientCost["AJS37"] = 5
ClientCost["AV8BNA"] = 5
ClientCost["C-101CC"] = 2
ClientCost["C-101EB"] = 1
ClientCost["F-14A-135-GR"] = 5
ClientCost["F-14B"] = 5
ClientCost["F-15C"] = 4
ClientCost["F-16C_50"] = 5
ClientCost["F-5E-3"] = 3
ClientCost["FA-18C_hornet"] = 5
ClientCost["L-39C"] = 1
ClientCost["L-39ZA"] = 2
ClientCost["M-2000C"] = 5
ClientCost["MiG-21Bis"] = 5
ClientCost["MiG-29A"] = 5
ClientCost["MiG-29G"] = 5
ClientCost["MiG-29S"] = 5
ClientCost["Su-25"] = 5
ClientCost["Su-25T"] = 5
ClientCost["Su-33"] = 5
ClientCost["JF-17"] = 5
ClientCost["TF-51D"] = 1
ClientCost["UH-1H"] = 2
ClientCost["Mi-8MT"] = 2
ClientCost["KA-50"] = 4

ActiveUnits = {}

LogisticsTable = {}

SupportHandler = EVENTHANDLER:New()
EventHandlerKill = EVENTHANDLER:New():HandleEvent( EVENTS.Kill )
EventHandlerBirth = EVENTHANDLER:New():HandleEvent( EVENTS.Birth )
EventHandlerLand = EVENTHANDLER:New():HandleEvent( EVENTS.Land )
EventHandlerTakeoff = EVENTHANDLER:New():HandleEvent( EVENTS.Takeoff )
EventHandlerDead = EVENTHANDLER:New():HandleEvent( EVENTS.Dead )

LogisticsClientSet = SET_CLIENT:New():FilterPrefixes("Transport"):FilterStart()
GroundUnitsSet = SET_UNIT:New():FilterCategories("ground"):FilterStart()
ClientSet = SET_CLIENT:New():FilterStart()

--Number of HQ Zones
BlueHQ = math.random (BlueHQZones)
RedHQ = math.random (RedHQZones)

--Set Hint Flag to false to start
HintActivation = false

--SSB activation
trigger.action.setUserFlag("SSB",100)

function showCredits(coalition)
	env.info(coalition)
	if coalition == 1 then 
		MessageAll = MESSAGE:New( "Available credits: "..RedCredits,  25):ToCoalition(coalition)
	elseif coalition == 2 then
		MessageAll = MESSAGE:New( "Available credits: "..BlueCredits,  25):ToCoalition(coalition)
	end
end


--Menu Stuff
local MenuCoalitionRed = MENU_COALITION:New( coalition.side.RED, "Mission Options" )
local MenuCoalitionBlue = MENU_COALITION:New( coalition.side.BLUE, "Mission Options" )
local MenuAdd = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Show Available Credits", MenuCoalitionBlue, showCredits, 2 )
local MenuAdd = MENU_COALITION_COMMAND:New( coalition.side.RED, "Show Available Credits", MenuCoalitionRed, showCredits, 1 )

function SpawnHq(BlueHQ, RedHQ)
	for i = 1, 2, 1
		do
			if i == 1 then
				HQZone = "r"..RedHQ
				HQName = "Red HQ"
				HQCountry = country.id.RUSSIA
			elseif i == 2 then
				HQZone = "b"..BlueHQ
				HQName = "Blue HQ"
				HQCountry = country.id.USA
			end
			
			local HQSpawnBuilding = SPAWNSTATIC:NewFromType("ComCenter", "Structures", HQCountry)
			local Zone = ZONE:FindByName( HQZone)
			local HQBuilding = HQSpawnBuilding:SpawnFromZone(Zone, 0, HQName )

			--local CommsTowerSpawnBuilding = SPAWNSTATIC:NewFromType("Comms tower M", "Structures", HQCountry):initCoordinate(Zone:GetCoordinate())
			
		end
end

SpawnHq(BlueHQ, RedHQ)

--------------
--Schedulars--
--------------

--10Sec Schedular
local MissionSchedule10Sec = SCHEDULER:New( nil, 
  function()
	--ResupplyScheduleCheck()
	SupplyCrateLoad()
	--CheckUnitsNearHQ()
	BaseHintCheck()
  end, {}, 1, 10
  )

--10Min Schedular
local MissionSchedule10Min = SCHEDULER:New( nil, 
  function()
	StatusUpdate()
  end, {}, 1, 600
  )

--function to give periodic updates on available credit on both sides
function StatusUpdate()
	MessageAll = MESSAGE:New( "Status Update:", 25):ToAll()
	MessageAll = MESSAGE:New( "Credits Red: "..RedCredits,  25):ToAll()
	MessageAll = MESSAGE:New( "Credits Blue: "..BlueCredits,  25):ToAll()
end

--function to add "Hint" intel menu after HintTimer has expired
function BaseHintCheck()
	MissionTimer = timer.getAbsTime() - env.mission.start_time
	if (MissionTimer > HintTimer) and HintActivation == false then
		local AudioCue = USERSOUND:New( "TransmisionEntrante.ogg" )
		AudioCue:ToAll()
		MessageAll = MESSAGE:New( "Intel received regarding the enemy base(check the Mission Options menu)", 25):ToAll()		
		local MenuAdd = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Show Hint", MenuCoalitionBlue, BaseHint, 2 )
		local MenuAdd = MENU_COALITION_COMMAND:New( coalition.side.RED, "Show Hint", MenuCoalitionRed, BaseHint, 1 )
		HintActivation = true
	end
end

--function to get the grid reference for the enemy base
function BaseHint(coalition)
	if coalition == 1 then
		local HQName = "Blue HQ"
		local HQObjCoord = STATIC:FindByName(HQName):GetCoordinate():ToStringMGRS()
		local hint_a = string.sub(HQObjCoord, 10,-13)
		local hint_b = string.sub(HQObjCoord, 13,-11)
		local hint_c = string.sub(HQObjCoord, 19,-5)
		MessageAll = MESSAGE:New( "Enemy base located in sector "..hint_a..hint_b..hint_c,  25):ToCoalition(coalition)
	elseif coalition == 2 then 
		local HQName = "Red HQ"
		local HQObjCoord = STATIC:FindByName(HQName):GetCoordinate():ToStringMGRS()
		local hint_a = string.sub(HQObjCoord, 10,-13)
		local hint_b = string.sub(HQObjCoord, 13,-11)
		local hint_c = string.sub(HQObjCoord, 19,-5)
		MessageAll = MESSAGE:New( "Enemy base located in sector "..hint_a..hint_b..hint_c,  25):ToCoalition(coalition)
	end
end

--Function to check if there are still units near HQ within set radius
function CheckUnitsNearHQ()
	for i = 1, 2, 1
		do
			--set HQZone
			if i == 1 then
				HQZone = "R"..RedHQ
			elseif i == 2 then
				HQZone = "B"..BlueHQ
			end
			Zone = ZONE:FindByName( HQZone )
			--Zone:FlareZone( FLARECOLOR.Red, 90, 60 )
			
			Zone:Scan({Object.Category.UNIT}, coalition.side.BLUE)
			if Zone:IsNoneInZoneOfCoalition(coalition.side.BLUE) == true then
				MessageAll = MESSAGE:New( "Unit still in "..HQZone,  25):ToAll()
			end
		end
end

--supply funtions
function ResupplyScheduleCheck()
	if ActiveUnits ~= nil then 
		for k,v in pairs(ActiveUnits) do
			--changed to more generic "sam" selectors
			if string.match(k,"sam") then
				if timer.getAbsTime() - v > Samresupplytimer then
					MessageAll = MESSAGE:New( k,  25):ToAll()
					SuppliedUnit = GROUP:FindByName( k )
					local suppliedUnitName = SuppliedUnit:GetName()

					-- disable SAM site to simulate out of resources
					SuppliedUnit:SetAIOff()

					-- create marker for resupply
					local supplyMarkerLoc = SuppliedUnit:GetCoordinate()
					Mymarker=MARKER:New(supplyMarkerLoc, "Please Resupply this unit!"):ToAll()
					
					--create resupplyzone
					ZoneA = ZONE_GROUP:New( k, SuppliedUnit, 200 )
					--debug flares
					ZoneA:FlareZone( FLARECOLOR.White, 90, 60 )

					LogisticsClientSet:ForEachClientInZone(ZoneA, function(client)
							if (client ~= nil) and (client:IsAlive()) then 
								if (client:InAir() == false) and (LogisticsTable[client:Name()] == "logistics") then
									LogisticsTable[client:Name()] = nil
									-- re-enable sam to simulate resupply
									SuppliedUnit:SetAIOn()

									-- reset resuppoly timer
									ActiveUnits[suppliedUnitName] = timer.getAbsTime()
									MessageAll = MESSAGE:New( "Sam Resupplied",  25):ToAll()
								end
							end
						end
					)
				end
			end
		end
	end
end

function SupplyCrateLoad()
	for i = 1, 2, 1
		do
			local SupplyCrateName = ReturnCoalitionName(i).." Supply Crate"

			local SupplyCrate = STATIC:FindByName(SupplyCrateName, false)
			if SupplyCrate ~= nil then
				local SupplyCrateCoords = SupplyCrate:GetCoordinate()
				
				ZoneCrate = ZONE_GROUP:New( SupplyCrateName, SupplyCrate, 50 )

				LogisticsClientSet:ForEachClientInZone(ZoneCrate, function(client)
					if (client ~= nil) and (client:IsAlive()) then 
						if client:InAir() == false then
							if LogisticsTable[client:Name()] == nil then
								--pick up logistics crate
								LogisticsTable[client:Name()] = "logistics"
							else
								MessageAll = MESSAGE:New( client:Name().. "heeft al een krat aan boord van type: "..LogisticsTable[client:Name()],  25):ToAll()
							end
						end
					end
				end
				)
			end
		end
	

end

function ReturnCoalitionName(coalition)
 if coalition == 1 then
	return "Red"
 elseif coalition == 2 then
	return "Blue"
 end
end

function SpawnUnitCheck(coord, coalition, text)
	Unitcost = UnitTable[text]
	MissionTimer = timer.getAbsTime() - env.mission.start_time

	if coalition == 1 then
		SpawnZone = ZONE:FindByName( RedSpawnZoneName )
	elseif coalition ==2 then
		SpawnZone = ZONE:FindByName( BlueSpawnZoneName )
	end

	if text ~= "jtac" and text ~= "awacs" then
		if coord:IsInRadius(SpawnZone:GetCoordinate(), SpawnZone:GetRadius()) then
			if MissionTimer < SpawnTimerLimit then
				if Unitcost ~= nil then	
					if coalition == 1 then
						Credits = RedCredits
					elseif coalition == 2 then
						Credits = BlueCredits
					end
						
					if Credits < Unitcost then
						MessageAll = MESSAGE:New( "Onvoldoende Credits!",  25):ToCoalition(coalition)
					else
						
						MessageAll = MESSAGE:New( "Credits: "..Credits,  25):ToCoalition(coalition)
						env.info("Credit Log: ".. ReturnCoalitionName(coalition) .." Credits: ".. Credits)

						Credits = Credits - Unitcost
						if coalition == 2 then
							BlueCredits = Credits
						elseif coalition == 1 then
							RedCredits = Credits
						end
						
						SpawnUnit(coord, coalition, text)

						MessageAll = MESSAGE:New( "Unitcost: "..Unitcost,  25):ToCoalition(coalition)
						env.info("Credit Log: ".. ReturnCoalitionName(coalition) .." spawning a unit for : ".. Unitcost)

						MessageAll = MESSAGE:New( Credits.." Credits over",  25):ToCoalition(coalition)
						env.info("Credit Log: ".. ReturnCoalitionName(coalition) .." Credits over: ".. Credits)
					end
				else
					MessageAll = MESSAGE:New( "Ongeldige Unit!",  25):ToCoalition(coalition)
				end
			else
				MessageAll = MESSAGE:New( "Instant spawn placement timer expired!",  25):ToCoalition(coalition)
			end
		else
			MessageAll = MESSAGE:New( "Units in eigen zone plaatsen!",  25):ToCoalition(coalition)
		end
	else
		--awacs/jtac code invoegen
	end
end

--unit sequencing
UnitNr = 1

function SpawnUnit(coord, coalition, text)
	local SpawnUnitTemplate = ReturnCoalitionName(coalition).."_"..text
	local UnitAlias = ReturnCoalitionName(coalition).." "..text .. "#" ..UnitNr
	local SpawnUnit = SPAWN:NewWithAlias( SpawnUnitTemplate, UnitAlias )
	SpawnUnit:SpawnFromVec2( coord:GetVec2() )
	ActiveUnits[UnitAlias.."#001"] = timer.getAbsTime()
	UnitNr = UnitNr + 1
end

function MarkRemoved(Event)
    if Event.text~=nil then 
        local text = Event.text:lower()
        local vec3 = {z=Event.pos.z, x=Event.pos.x}
		local coalition = Event.coalition
        local coord = COORDINATE:NewFromVec3(vec3)
		
		SpawnUnitCheck(coord, coalition, text)	
    end
end

function EventHandlerBirth:OnEventBirth(Event)
	env.info("Birth Detected")
	if Event.IniPlayerName ~= nil then
		local initiator = Event.IniPlayerName
		local initiator_type = Event.IniTypeName
		local initiator_coalition = Event.IniCoalition
		local initiator_cost = ClientCost[initiator_type]
		local initiator_DcsGroupName = Event.IniGroupName
		
		if initiator_coalition == 1 then
			if initiator_cost > RedCredits then
				MessageAll = MESSAGE:New( "Te weinig credits voor dit vliegtuig",  25):ToCoalition(initiator_coalition)
				---SSB Kick on not enough Credits
				trigger.action.setUserFlag(initiator_DcsGroupName,100)
			else
				env.info("Credit Log: Red Credits: ".. RedCredits)
				env.info("Credit Log: New Player: " .. initiator .. ", Type: ".. initiator_type.. ", Cost: ".. initiator_cost.. ", Coalition: ".. initiator_coalition)
			end
		elseif initiator_coalition ==2 then
			if initiator_cost > BlueCredits then
				MessageAll = MESSAGE:New( "Te weinig credits voor dit vliegtuig",  25):ToCoalition(initiator_coalition)
				---SSB Kick on not enough Credits
				env.info("group" .. initiator_DcsGroupName)
			else
				env.info("Credit Log: Blue Credits: ".. BlueCredits)			
				env.info("Credit Log: New Player: " .. initiator .. ", Type: ".. initiator_type.. ", Cost: ".. initiator_cost.. ", Coalition: ".. initiator_coalition)
			end
		end
		
	end
end

function EventHandlerKill:OnEventKill(Event)
	
	local targetType = Event.TgtTypeName
	local targetCoalition = Event.TgtCoalition
	
	if ClientCost[targetType] ~= nil then
		local CreditsEarned = ClientCost[targetType]
		if targetCoalition == 2 then
			env.info("Credit Log: Red Credits: ".. RedCredits)
			RedCredits = RedCredits + CreditsEarned
			env.info("Credit Log: Red Credits gained: ".. CreditsEarned .. " New Total: ".. RedCredits)
		elseif targetCoalition == 1 then
			env.info("Credit Log: Blue Credits: ".. BlueCredits)
			BlueCredits = BlueCredits + CreditsEarned
			env.info("Credit Log: Blue Credits gained: ".. CreditsEarned .. " New Total: ".. BlueCredits)
		end
	else
		CreditsEarned = CreditsUnknownUnit
		if targetCoalition == 2 then
			env.info("Credit Log: Red Credits: ".. RedCredits)
			RedCredits = RedCredits + CreditsEarned
			env.info("Credit Log: Red Credits gained: ".. CreditsEarned .. " New Total: ".. RedCredits)
		elseif targetCoalition == 1 then
			env.info("Credit Log: Blue Credits: ".. BlueCredits)
			BlueCredits = BlueCredits + CreditsEarned
			env.info("Credit Log: Blue Credits gained: ".. CreditsEarned .. " New Total: ".. BlueCredits)
		end
	end
end

function EventHandlerDead:OnEventDead(Event)
	local DeadObject = Event.IniUnitName
	if DeadObject == "Blue HQ" then
		MessageAll = MESSAGE:New( DeadObject.." is destroyed",  100):ToAll()
	elseif DeadObject == "Red HQ" then
		MessageAll = MESSAGE:New( DeadObject.." is destroyed",  100):ToAll()
	end
end

function EventHandlerTakeoff:OnEventTakeoff(Event)
	if Event.initiator ~= nil then
		local initiator = Event.IniGroupName
		local client = CLIENT:FindByName(initiator)
		local clientType = client:GetTypeName()
		local coalition = client:GetCoalition()
		local clientCost = ClientCost[clientType]
		local clientLocation = Event.PlaceName
		local airbaseCoalition = AIRBASE:FindByName(clientLocation):GetCoalition()
		local clientLoadout = client:GetAmmo()

		--begin om loadouts uit te lezen
		--for index, data in ipairs(clientLoadout) do
		--	env.info(index)
		--	for k, v in pairs(data) do
		--		env.info("ammo:"..k..": "..v)
		--	end			
		--end

		if coalition == 1 and airbaseCoalition == 1 then
			env.info("Credit Log: Red Credits: ".. RedCredits .. " Deducted: ".. clientCost)
			RedCredits = RedCredits - clientCost
			env.info("Credit Log: Red Credits: ".. RedCredits)
		elseif coalition == 2  and airbaseCoalition == 2 then
			env.info("Credit Log: Blue Credits: ".. BlueCredits .. " Deducted: ".. clientCost)
			BlueCredits = BlueCredits - clientCost
			env.info("Credit Log: Blue Credits: ".. BlueCredits)
		end
	end
	
end

function EventHandlerLand:OnEventLand(Event)
	if Event.initiator ~= nil then
		local initiator = Event.initiator:getName()
		local client = CLIENT:FindByName(initiator)
		local clientType = client:GetTypeName()
		local clientCoalition = client:GetCoalition()
		local clientCost = ClientCost[clientType]
		local clientLocation = Event.PlaceName
		local airbaseCoalition = AIRBASE:FindByName(clientLocation):GetCoalition()

		if clientCoalition == 1 and airbaseCoalition == 1 then
			env.info("Credit Log: Red Credits: ".. RedCredits .. " Returned: ".. clientCost)
			RedCredits = RedCredits + clientCost
			env.info("Credit Log: Red Credits: ".. RedCredits)
		elseif clientCoalition == 2 and airbaseCoalition == 2 then
			env.info("Credit Log: Blue Credits: ".. BlueCredits .. " Returned: ".. clientCost)
			BlueCredits = BlueCredits + clientCost
			env.info("Credit Log: Blue Credits: ".. BlueCredits)
		end
	end
end

function SupportHandler:onEvent(Event)
    if Event.id == world.event.S_EVENT_MARK_ADDED then
        -- env.info(string.format("BTI: Support got event ADDED id %s idx %s coalition %s group %s text %s", Event.id, Event.idx, Event.coalition, Event.groupID, Event.text))
    elseif Event.id == world.event.S_EVENT_MARK_CHANGE then
        -- env.info(string.format("BTI: Support got event CHANGE id %s idx %s coalition %s group %s text %s", Event.id, Event.idx, Event.coalition, Event.groupID, Event.text))
    elseif Event.id == world.event.S_EVENT_MARK_REMOVED then
        -- env.info(string.format("BTI: Support got event REMOVED id %s idx %s coalition %s group %s text %s", Event.id, Event.idx, Event.coalition, Event.groupID, Event.text))
		MarkRemoved(Event)
	end
end


world.addEventHandler(SupportHandler)