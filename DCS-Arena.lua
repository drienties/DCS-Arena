SupportHandler = EVENTHANDLER:New()

UnitNr = 1

BlueCredits = 400
BlueReservedCredits =0
RedCredits = 400
RedReservedCredits = 0


SpawnTimerLimit = 900

Samresupplytimer = 6000

UnitTable = {}

UnitTable["tank"] = 10		-- MBT
UnitTable["artillery"] = 10		-- Artillery
UnitTable["aaa"] = 10		-- aaa 
UnitTable["samsr"] = 20 	-- short range Sa-6 / Hawk
UnitTable["sampd"] = 20		-- sam-point defence Sa-15 / Roland
UnitTable["samlr"] = 40 	-- long range S300 / Patriot

ClientCost = {}

ClientCost["A-10C_2"] = 5
ClientCost["Su-25T"] = 5
ClientCost["FA-18C_hornet"] = 5
ClientCost["MiG-29A"] = 5
ClientCost["MiG-21Bis"] = 5
ClientCost["JF-17"] = 5
ClientCost["L-39ZA"] = 2
ClientCost["M-2000C"] = 5
ClientCost["TF-51D"] = 1
ClientCost["AJS37"] = 5
ClientCost["AV8BNA"] = 5
ClientCost["C-101CC"] = 2
ClientCost["F-14A-135-GR"] = 5
ClientCost["F-14B"] = 5
ClientCost["F-15C"] = 4
ClientCost["F-16C_50"] = 5
ClientCost["F-5E-3"] = 3
ClientCost["UH-1H"] = 2
ClientCost["Mi-8MT"] = 2

ActiveUnits = {}

LogisticsTable = {}

LogisticsClientSet = SET_CLIENT:New():FilterPrefixes("Transport"):FilterStart()
GroundUnitsSet = SET_UNIT:New():FilterCategories("ground"):FilterStart()

--enable SSB flag
--trigger.action.setUserFlag("SSB",100)
--trigger.action.setUserFlag("F-14A Blue-1",100)



BlueHQ = math.random (17)
RedHQ = math.random (17)

function showCredits(coalition)
	env.info(coalition)
	if coalition == 1 then 
		MessageAll = MESSAGE:New( "Available credits: "..RedCredits,  25):ToAll()
	elseif coalition == 2 then
		MessageAll = MESSAGE:New( "Available credits: "..BlueCredits,  25):ToAll()
	end
end

--Menu Stuff
local MenuCoalitionRed = MENU_COALITION:New( coalition.side.RED, "Manage Credits" )
local MenuCoalitionBlue = MENU_COALITION:New( coalition.side.BLUE, "Manage Credits" )
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
			
			local HQSpawnBuilding = SPAWNSTATIC:NewFromType("Shelter", "Structures", HQCountry)
			local Zone = ZONE:FindByName( HQZone)
			local HQBuilding = HQSpawnBuilding:SpawnFromZone(Zone, 0, HQName )
		end
end
--spawn HQ on 1 of 5 zones
SpawnHq(BlueHQ, RedHQ)

local MissionSchedule = SCHEDULER:New( nil, 
  function()
	--disabled for now
	--ResupplyScheduleCheck()
	SupplyCrateLoad(2)
	CreditCheck()
	--CheckUnitsNearHQ()
  end, {}, 1, 10
  )

function CreditCheck()

end

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
				ZoneCrate:FlareZone( FLARECOLOR.Red, 90, 60 )

				LogisticsClientSet:ForEachClientInZone(ZoneCrate, function(client)
					if (client ~= nil) and (client:IsAlive()) then 
						if client:InAir() == false then
							if LogisticsTable[client:Name()] == nil then
								--pick up logistics crate
								MessageAll = MESSAGE:New( client:Name(),  25):ToAll()
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
end

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

function BirthDetected(Event)
	env.info("Birth Detected")
	if Event.IniPlayerName ~= nil then
		local initiator = Event.IniPlayerName
		local initiator_type = Event.IniTypeName
		local initiator_coalition = Event.IniCoalition
		local initiator_cost = ClientCost[initiator_type]
		if initiator_coalition == 1 then
			env.info("Credit Log: Red Credits: ".. RedCredits)
			RedReservedCredits = RedReservedCredits + initiator_cost
			env.info("Credit Log: Red Credits: ".. RedCredits .. " Reserved: ".. RedReservedCredits)
		elseif initiator_coalition ==2 then
			env.info("Credit Log: Blue Credits: ".. BlueCredits)
			BlueReservedCredits = BlueReservedCredits + initiator_cost
			env.info("Credit Log: Blue Credits: ".. BlueCredits .. " Reserved: ".. BlueReservedCredits)
		end
		env.info("New Player: " .. initiator .. ", Type: ".. initiator_type.. ", Cost: ".. initiator_cost.. ", Coalition: ".. initiator_coalition)
	end
end

function KillDetected(Event)
	local targetType = Event.TgtTypeName
	local targetCoalition = Event.TgtCoalition
	if ClientCost[targetType] ~= nil then
		local CreditsEarned = ClientCost[targetType]
		if targetCoalition == 1 then
			RedCredits = RedCredits + CreditsEarned
		elseif targetCoalition ==2 then
			BlueCredits = BlueCredits + CreditsEarned
		end
	else
		if targetCoalition == 1 then
			RedCredits = RedCredits + 2
		elseif targetCoalition ==2 then
			BlueCredits = BlueCredits + 2
		end
	end
end

function DeadObjectDetected(Event)
	local DeadObject = Event.IniUnitName
	if DeadObject == "Blue HQ" then
		MessageAll = MESSAGE:New( DeadObject.." is destroyed",  100):ToAll()
	elseif DeadObject == "Red HQ" then
		MessageAll = MESSAGE:New( DeadObject.." is destroyed",  100):ToAll()
	end
end

function TakeOffEvent(Event)
	if Event.initiator ~= nil then
		env.info("Player Takeoff detected")
		local initiator = Event.initiator:getName()
		local client = CLIENT:FindByName(initiator)
		local coalition = client:GetCoalition()
		if coalition == 1 then
			env.info("Credit Log: Red Credits: ".. RedCredits .. " Deducted: ".. RedReservedCredits)
			RedCredits = RedCredits - RedReservedCredits
			env.info("Credit Log: Red Credits: ".. RedCredits)
		elseif coalition ==2 then
			env.info("Credit Log: Blue Credits: ".. BlueCredits .. " Deducted: ".. BlueReservedCredits)
			BlueCredits = BlueCredits - BlueReservedCredits
			env.info("Credit Log: Blue Credits: ".. BlueCredits)
		end
	end
	MessageAll = MESSAGE:New( "Takeoff!!",  100):ToAll()
end

function LandingEvent(Event)
	if Event.initiator ~= nil then
		env.info("Player landing detected")
		local initiator = Event.initiator:getName()
		local client = CLIENT:FindByName(initiator)
		local clientType = client:GetTypeName()
		local clientCoalition = client:GetCoalition()
		local clientCost = ClientCost[clientType]
		if clientCoalition == 1 then
			env.info("Credit Log: Red Credits: ".. RedCredits .. " Returned: ".. clientCost)
			RedCredits = RedCredits + clientCost
			env.info("Credit Log: Red Credits: ".. RedCredits)
		elseif clientCoalition == 2 then
			env.info("Credit Log: Blue Credits: ".. BlueCredits .. " Returned: ".. clientCost)
			BlueCredits = BlueCredits + clientCost
			env.info("Credit Log: Blue Credits: ".. BlueCredits)
		end
		env.info("player in: ".. clientType .. " landed" )
		--local location = Event.PlaceName

	end
	MessageAll = MESSAGE:New( "Landing",  100):ToAll()
end

function SupportHandler:onEvent(Event)
    if Event.id == world.event.S_EVENT_MARK_ADDED then
        -- env.info(string.format("BTI: Support got event ADDED id %s idx %s coalition %s group %s text %s", Event.id, Event.idx, Event.coalition, Event.groupID, Event.text))
    elseif Event.id == world.event.S_EVENT_MARK_CHANGE then
        -- env.info(string.format("BTI: Support got event CHANGE id %s idx %s coalition %s group %s text %s", Event.id, Event.idx, Event.coalition, Event.groupID, Event.text))
    elseif Event.id == world.event.S_EVENT_MARK_REMOVED then
        -- env.info(string.format("BTI: Support got event REMOVED id %s idx %s coalition %s group %s text %s", Event.id, Event.idx, Event.coalition, Event.groupID, Event.text))
		MarkRemoved(Event)
	elseif Event.id == world.event.S_EVENT_BIRTH then
		--birth detected
		BirthDetected(Event)
	elseif Event.id == world.event.S_EVENT_KILL then
		--death detected
		--KillDetected(Event)
	elseif Event.id == world.event.S_EVENT_DEAD then
		--death detected
		DeadObjectDetected(Event)
	elseif Event.id == world.event.S_EVENT_LAND then
		--landing detected
		LandingEvent(Event)
    elseif Event.id == world.event.S_EVENT_TAKEOFF then
		--landing detected
		TakeOffEvent(Event)
		
    end
end




world.addEventHandler(SupportHandler)