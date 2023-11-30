-- by modelleicher ( Farming Agency )

-- This Script is made to enhance realism on fillable vehicles. It consists of mainly two things.
-- 1. With default FS22, all fillTypes have real mass (and not half of real as in previous FS versions)
--		If you play with the trailer fill limit enabled it allows you to only fill trailers until the max allowed weight of that trailer is reached through the amount of the particular fillType.
--		If you play without the trailer fill limit enabled you can fill trailers up to 100% no matter what, BUT it will never weight more than max allowed weight. This means that the additional mass that would make the trailer heavier is discarded.
--		This way it enables for unrealistically high capacities and casual players to not worry about having enough horsepower to pull a trailer. But for realism players this isn't enough.
-- 		So this mod changes that. With trailer fill limit disabled you can load past the max allowed weight and the mass will be added. Also if you have the trailer selected it will show the % of overload below the fillLevel bar.
-- 		In addition to that, if you have the trailer overloaded it will amount more damage when driving. The faster you drive the more damage amounts (speed^2) so if you need to overload your trailer, drive slowly unless you want to repair it often.
--
-- 2. The second feature of this script is to not have a rigid capacity limit. You can fill trailers past 100%, BUT the further above 100% you fill the more of the fill gets "spilled" e.g. lost. 
-- 		This is simply because IRL you don't have any rigid limits either. If you have 150l left in your combine you don't need another trailer for that, or if you're full just a few meters away from the field ending you don't need to unload first.
--		The loss is 0% at 100% capacity and 100% at 130% capacity but the actual loss amount is also a bit random up to 20% more than the mathematical loss, so as soon as 100% capacity are reached you can lose up to 20% of each further filling

realismAddon_fillables = {};

-- Multiplayer for the max amount a fillUnit can be overfilled, 1.5 = 150%, at max there will be 100% loss so this value is never actually reached when playing realistically
realismAddon_fillables.capacityMultiplier = 1.3

-- list of specs that need to be included in order to change the capacity limit 
realismAddon_fillables.includeSpecList = {"spec_combine", "spec_trailer"}
-- list of specs that if included disable the capacity limit 
realismAddon_fillables.excludeSpecList = {"spec_mixerWagon", "spec_baler" }
-- list of fillTypes that are excluded from the capacity limit change 
realismAddon_fillables.excludeFillTypesList = {"unknown", "cotton", "diesel", "water", "liquidManure", "liquidFertilizer", "milk", "def", "herbicide", "digestate", "SUNFLOWER_OIL", "CANOLA_OIL", "OLIVE_OIL", "CHOCOLATE", "BOARDS", "FURNITURE", "EGG", "TOMATO", "LETTUCE", "ELECTRICCHARGE", "METHANE", "WOOL", "TREESAPLINGS" }



-- Input  stuff for turning the feature off on particular vehicles for compatability with Courseplay/AutoDrive and so on 
------------------------------------------------------------------------------------------------------------------------
-- onRegister actionEvent for FillUnit 
function realismAddon_fillables.onRegisterActionEvents(self, isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_fillUnit

        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.REALISM_ADDON_FILLABLES_LOCALONOFF , self, FillUnit.RAFtoggleOnOffLocally, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
            
			if spec.realismAddon_fillables_active then
				g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_REALISM_ADDON_FILLABLES_LOCALON"))
			else
				g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_REALISM_ADDON_FILLABLES_LOCALOFF"))
			end
        end
    end
end
FillUnit.onRegisterActionEvents = Utils.appendedFunction(FillUnit.onRegisterActionEvents, realismAddon_fillables.onRegisterActionEvents)

-- add toggleOnOffLocally function 
function realismAddon_fillables.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "RAFtoggleOnOffLocally", FillUnit.RAFtoggleOnOffLocally)
end
FillUnit.registerFunctions = Utils.appendedFunction(FillUnit.registerFunctions, realismAddon_fillables.registerFunctions)

-- register realismAddon_fillables_active variable in onLoad
function realismAddon_fillables.onLoad(self, superFunc, savegame)
    local returnValue = superFunc(self, savegame)
   
    local spec = self.spec_fillUnit
	spec.realismAddon_fillables_active = true

    return returnValue
end
FillUnit.onLoad = Utils.overwrittenFunction(FillUnit.onLoad, realismAddon_fillables.onLoad)

-- toggle func is also the inputEvent func at the same time 
function FillUnit.RAFtoggleOnOffLocally(self, actionName, inputValue, callbackState, isAnalog, value, value2, value3, state, noEventSend)
	local spec = self.spec_fillUnit
	
	
	
	if state ~= nil then
		spec.realismAddon_fillables_active = state	
	else
		spec.realismAddon_fillables_active = not spec.realismAddon_fillables_active
	end
	
     -- call event
    realismAddon_fillables_toggleOnOffEvent.sendEvent(self, state, noEventSend)
	
	if spec.actionEvents ~= nil and spec.actionEvents[InputAction.REALISM_ADDON_FILLABLES_LOCALONOFF] ~= nil then
		if spec.realismAddon_fillables_active then
		    g_inputBinding:setActionEventText(spec.actionEvents[InputAction.REALISM_ADDON_FILLABLES_LOCALONOFF].actionEventId, g_i18n:getText("action_REALISM_ADDON_FILLABLES_LOCALON"))
		else
		    g_inputBinding:setActionEventText(spec.actionEvents[InputAction.REALISM_ADDON_FILLABLES_LOCALONOFF].actionEventId, g_i18n:getText("action_REALISM_ADDON_FILLABLES_LOCALOFF"))
		end
	end	
end

-- onReadStream and onWriteStream
function realismAddon_fillables.onReadStream(self, streamId, connection)
	local spec = self.spec_fillUnit
    if spec.realismAddon_fillables_active ~= nil then
        local realismAddon_fillables_active = streamReadBool(streamId)
        if realismAddon_fillables_active ~= nil then
            self:RAFtoggleOnOffLocally(nil, nil, nil, nil, nil, nil, nil, realismAddon_fillables_active, true)
        end
    end
end
FillUnit.onReadStream = Utils.appendedFunction(FillUnit.onReadStream, realismAddon_fillables.onReadStream)

function realismAddon_fillables.onWriteStream(self, streamId, connection)
	local spec = self.spec_fillUnit
    if spec.realismAddon_fillables_active ~= nil then
	    streamWriteBool(streamId, spec.realismAddon_fillables_active)
    end
end
FillUnit.onWriteStream = Utils.appendedFunction(FillUnit.onWriteStream, realismAddon_fillables.onWriteStream)


-- Event for toggle on off locally per vehicle 
realismAddon_fillables_toggleOnOffEvent = {}
local realismAddon_fillables_toggleOnOffEvent_mt = Class(realismAddon_fillables_toggleOnOffEvent, Event)

InitEventClass(realismAddon_fillables_toggleOnOffEvent, "realismAddon_fillables_toggleOnOffEvent")

function realismAddon_fillables_toggleOnOffEvent.emptyNew()
	local self = Event.new(realismAddon_fillables_toggleOnOffEvent_mt)
    self.className = "realismAddon_fillables_toggleOnOffEvent";
	return self
end

function realismAddon_fillables_toggleOnOffEvent.new(vehicle, state)
	local self = realismAddon_fillables_toggleOnOffEvent.emptyNew()
	self.vehicle = vehicle
	self.state = state

	return self
end

function realismAddon_fillables_toggleOnOffEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadBool(streamId)

	self:run(connection)
end

function realismAddon_fillables_toggleOnOffEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.state)
end

function realismAddon_fillables_toggleOnOffEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:RAFtoggleOnOffLocally(nil, nil, nil, nil, nil, nil, nil, self.state, true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(realismAddon_fillables_toggleOnOffEvent.new(self.vehicle, self.state), nil, connection, self.vehicle)
	end
end

function realismAddon_fillables_toggleOnOffEvent.sendEvent(vehicle, state, noEventSend)
	if (noEventSend == nil or noEventSend == false) then
		if g_server ~= nil then
			g_server:broadcastEvent(realismAddon_fillables_toggleOnOffEvent.new(vehicle, state), nil, nil, vehicle)
		else
			g_client:getServerConnection():sendEvent(realismAddon_fillables_toggleOnOffEvent.new(vehicle, state))
		end
	end
end
-- Input Stuff End 
-------------------

function realismAddon_fillables.checkIncludeExcludeSpecs(self)
	local includes = false
	for _, specname in pairs(realismAddon_fillables.includeSpecList) do
		if self[specname] ~= nil then
			includes = true
			break
		end
	end
	
	local excludes = true
	for _, specname in pairs(realismAddon_fillables.excludeSpecList) do
		if self[specname] ~= nil then
			excludes = false
			break
		end
	end
		
	return includes, excludes
end

function realismAddon_fillables.checkExcludeFillType(fillUnit)
	
	for _, fillTypeName in pairs(realismAddon_fillables.excludeFillTypesList) do
		
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
		
		if fillUnit.fillType == fillTypeIndex then
			return false
		end		
	end
	return true
end

function realismAddon_fillables.fillForageWagon(self, superFunc)
	
	local includes, excludes = realismAddon_fillables.checkIncludeExcludeSpecs(self)
	if includes and excludes and self.spec_fillUnit.realismAddon_fillables_active then	
		local spec = self.spec_forageWagon	

		local loadInfo = self:getFillVolumeLoadInfo(spec.loadInfoIndex)
		local filledLiters = self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, spec.workAreaParameters.litersToFill, spec.lastFillType, ToolType.UNDEFINED, loadInfo)

		local fillUnit = self.spec_fillUnit.fillUnits[spec.fillUnitIndex]
		if fillUnit.fillLevel >= fillUnit.capacity * (realismAddon_fillables.capacityMultiplier - 0.01) then
			self:setIsTurnedOn(false)
			self:setPickupState(false)		
		end

		spec.workAreaParameters.litersToFill = spec.workAreaParameters.litersToFill - filledLiters

		if spec.workAreaParameters.litersToFill < 0.01 then
			spec.workAreaParameters.litersToFill = 0
		end
		return true
	else
		return superFunc()
	end
end
ForageWagon.fillForageWagon = Utils.overwrittenFunction(ForageWagon.fillForageWagon, realismAddon_fillables.fillForageWagon)


function realismAddon_fillables:addFillUnitFillLevel(superFunc, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
	
	local includes, excludes = realismAddon_fillables.checkIncludeExcludeSpecs(self)
	
	local spec = self.spec_fillUnit	
	
	if includes and excludes and spec.realismAddon_fillables_active then
	
		local fillUnit = spec.fillUnits[fillUnitIndex]
		
		if fillUnit ~= nil and realismAddon_fillables.checkExcludeFillType(fillUnit) then
		
			-- backup original capacity
			local capacityOriginal = fillUnit.capacity
			
			-- capacity is temporarily raised by realismAddon_fillables.capacityMultiplier 
			fillUnit.capacity = fillUnit.capacity * realismAddon_fillables.capacityMultiplier
			
			-- calculate the loss-amount 
			-- it is 0% loss at 100% default capacity and 100% loss when reaching the new capacity
			-- the actual amount is also a bit random
			
			-- only do stuff if we add to the fillUnit, not remove 
			if fillLevelDelta > 0 then
				local oldLevel = fillUnit.fillLevel
				
				-- only do stuff if we actually are at capacity or above 
				if oldLevel > capacityOriginal then
					
					-- to make it easier, use oldLevel to calculate loss, not potential new level 
					-- 		percent loss       amount over 			   / 		range 
					local lossPercent = (oldLevel - capacityOriginal) / (fillUnit.capacity - capacityOriginal)
					
					-- random value between 0 and 1
					local randomValue = math.random()
					
					-- changed to lossPercent * randomValue 
					lossPercent = math.min(1, lossPercent * randomValue)
					
					-- finally remove loss from delta (changed) 
					fillLevelDelta = fillLevelDelta - (fillLevelDelta * lossPercent)
				end
			end
			
			-- call original function while capacity is temporarily raised and with loss-added delta 
			local returnValue = superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
			
			-- reset capacity
			fillUnit.capacity = capacityOriginal
			
			return returnValue
		else
			return superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
		end
	else
		return superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
	end
	
end
FillUnit.addFillUnitFillLevel = Utils.overwrittenFunction(FillUnit.addFillUnitFillLevel, realismAddon_fillables.addFillUnitFillLevel)

-- getFillUnitAllowsFillType checks if fillLevel is below capacity for given fillType so we need to replace capacity temporarily there too 
function realismAddon_fillables:getFillUnitAllowsFillType(superFunc, fillUnitIndex, fillType)

	local includes, excludes = realismAddon_fillables.checkIncludeExcludeSpecs(self)
		
	local spec = self.spec_fillUnit	
	
	if includes and excludes and spec.realismAddon_fillables_active then

		local fillUnit = spec.fillUnits[fillUnitIndex]		
	
		if realismAddon_fillables.checkExcludeFillType(fillUnit) then
			
			-- backup original capacity	
			local capacityOriginal = fillUnit.capacity
			
			-- capacity is temporarily raised by realismAddon_fillables.capacityMultiplier 
			fillUnit.capacity = fillUnit.capacity * realismAddon_fillables.capacityMultiplier
			
			-- call original function while capacity is temporarily raised 
			local returnValue = superFunc(self, fillUnitIndex, fillType)
			
			-- reset capacity
			fillUnit.capacity = capacityOriginal
			
			return returnValue
		else
			return superFunc(self, fillUnitIndex, fillType)
		end
	else
		return superFunc(self, fillUnitIndex, fillType)
	end
end
FillUnit.getFillUnitAllowsFillType = Utils.overwrittenFunction(FillUnit.getFillUnitAllowsFillType, realismAddon_fillables.getFillUnitAllowsFillType)

-- getFillUnitFreeCapacity returns the available free capacity so we need to overwrite this as well 
function realismAddon_fillables:getFillUnitFreeCapacity(superFunc, fillUnitIndex, fillTypeIndex, farmId)
	
	local includes, excludes = realismAddon_fillables.checkIncludeExcludeSpecs(self)
		
	local spec = self.spec_fillUnit	
	
	if includes and excludes and spec.realismAddon_fillables_active then
	
		local fillUnit = spec.fillUnits[fillUnitIndex]	
	
		if realismAddon_fillables.checkExcludeFillType(fillUnit) then

			-- backup original capacity	
			local capacityOriginal = fillUnit.capacity
			-- capacity is temporarily raised by realismAddon_fillables.capacityMultiplier 
			fillUnit.capacity = fillUnit.capacity * realismAddon_fillables.capacityMultiplier
			
			-- call original function while capacity is temporarily raised 	
			local returnValue = superFunc(self, fillUnitIndex, fillTypeIndex, farmId)
			
			-- reset capacity
			fillUnit.capacity = capacityOriginal
			
			return returnValue
		else
			return superFunc(self, fillUnitIndex, fillTypeIndex, farmId)		
		end
	else
		return superFunc(self, fillUnitIndex, fillTypeIndex, farmId)
	end
end
FillUnit.getFillUnitFreeCapacity = Utils.overwrittenFunction(FillUnit.getFillUnitFreeCapacity, realismAddon_fillables.getFillUnitFreeCapacity)

function realismAddon_fillables.onReadUpdateStream(self, superFunc, streamId, timestamp, connection)

	local includes, excludes = realismAddon_fillables.checkIncludeExcludeSpecs(self)
	
	local spec = self.spec_fillUnit	
	

	if includes and excludes and spec.realismAddon_fillables_active then
	
		-- go through all fillUnits and set capacities if neccesary 
		for i = 1, table.getn(spec.fillUnits) do
			local fillUnit = spec.fillUnits[i]		
			if realismAddon_fillables.checkExcludeFillType(fillUnit) then
				-- backup original capacity	
				fillUnit.capacityOriginal = fillUnit.capacity
				-- capacity is temporarily raised by realismAddon_fillables.capacityMultiplier 
				fillUnit.capacity = fillUnit.capacity * realismAddon_fillables.capacityMultiplier					
			end
		end
		

		-- call original function while capacity is temporarily raised 	
		local returnValue = superFunc(self, streamId, timestamp, connection)
		

		-- go through all fillUnits and reset capacities if neccesary 
		for i = 1, table.getn(spec.fillUnits) do
			local fillUnit = spec.fillUnits[i]			
			if realismAddon_fillables.checkExcludeFillType(fillUnit) then
				-- reset capacity back 
				-- check if capacityOriginal backup exists first because if fillUnit fillType changed during call of the original function it might not have been affected by the capacity change this call 
				if fillUnit.capacityOriginal ~= nil then
					fillUnit.capacity = fillUnit.capacityOriginal
				end
			end
		end	


		return returnValue		
	else
		return superFunc(self, streamId, timestamp, connection)
	end

end
FillUnit.onReadUpdateStream = Utils.overwrittenFunction(FillUnit.onReadUpdateStream, realismAddon_fillables.onReadUpdateStream)

function realismAddon_fillables.onWriteUpdateStream(self, superFunc, streamId, connection, dirtyMask)
	local includes, excludes = realismAddon_fillables.checkIncludeExcludeSpecs(self)
	
	local spec = self.spec_fillUnit	
	
	
	if includes and excludes and spec.realismAddon_fillables_active then
			
		-- go through all fillUnits and set capacities if neccesary 
		for i = 1, table.getn(spec.fillUnits) do
			local fillUnit = spec.fillUnits[i]				
			if realismAddon_fillables.checkExcludeFillType(fillUnit) then		
				-- backup original capacity	
				fillUnit.capacityOriginal = fillUnit.capacity
				-- capacity is temporarily raised by realismAddon_fillables.capacityMultiplier
				fillUnit.capacity = fillUnit.capacity * realismAddon_fillables.capacityMultiplier			
			end
		end
		
		-- call original function while capacity is temporarily raised 	
		local returnValue = superFunc(self, streamId, connection, dirtyMask)	
		
		-- go through all fillUnits and reset capacities if neccesary 
		for i = 1, table.getn(spec.fillUnits) do
			local fillUnit = spec.fillUnits[i]					
			if realismAddon_fillables.checkExcludeFillType(fillUnit) then			
				-- reset capacity back 
				fillUnit.capacity = fillUnit.capacityOriginal					
			end
		end		
		
		return returnValue	
	else
		return superFunc(self, streamId, connection, dirtyMask)
	end
end
FillUnit.onWriteUpdateStream = Utils.overwrittenFunction(FillUnit.onWriteUpdateStream, realismAddon_fillables.onWriteUpdateStream)


-- 
function realismAddon_fillables:onDrawFillUnit(superFunc, isActiveForInput, isActiveForInputIgnoreSelection)
	superFunc(self, isActiveForInput, isActiveForInputIgnoreSelection)

	if isActiveForInput then
		if self.overloadPercentage ~= nil and self.overloadPercentage > 0 then
		
			setTextAlignment(RenderText.ALIGN_LEFT)	
			setTextBold(true)
			setTextColor(0.8, 0, 0, 1)
			renderText(0.725, 0.014, 0.014, tostring(self.overloadPercentage).."% overloaded")	
			setTextColor(1, 1, 1, 1)			
			renderText(0.724, 0.013, 0.014, tostring(self.overloadPercentage).."% overloaded")			
		end
	end
end
FillUnit.onDraw = Utils.overwrittenFunction(FillUnit.onDraw, realismAddon_fillables.onDrawFillUnit)

function realismAddon_fillables:onUpdateTickFillUnit(superFunc, dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	superFunc(self, dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	
	-- calculate added damage from overloading 
	if self.overloadPercentage ~= nil and self.overloadPercentage > 0 and self:getLastSpeed() > 1 and self.addDamageAmount ~= nil then 
		-- speed range from 0 to 80kph with FS vehicles
		local speedFactor = math.min(80, self:getLastSpeed()) / 80 -- range 0 to 1
		local overloadFactor = self.overloadPercentage / 100 -- range 0 to 1 whereas 1 = 100% overloading 
		
		-- overloading itself shouldn't be as bad but adding speed to it makes it so much worse
		local damageFactor = self.overloadPercentage * (speedFactor ^ 2) -- at 25% overload, 0.4 damage at 10kph, 1.6 damage at 20kph, 6.25 damage at 40kph, 25 damage at 80kph
		
		local damageAdd = 0.0000001 * dt * damageFactor

		self:addDamageAmount(damageAdd)
	end
end
FillUnit.onUpdateTick = Utils.overwrittenFunction(FillUnit.onUpdateTick, realismAddon_fillables.onUpdateTickFillUnit)

-- overwrite Vehicle.updateMass so mass is calculated differently, mass will not be limited by maxMass anymore
function realismAddon_fillables.updateVehicleMass(self, superFunc)

	-- only run our func if fillUnit exists in this vehicle (maybe change to tipper or something like that if issues arise) 
	if self.spec_fillUnit == nil then
		superFunc(self)
	end
	
	-- reset to 0 
	self.serverMass = 0
	
	for _, component in ipairs(self.components) do
	
		-- why is defaultMass not set in load?
		if component.defaultMass == nil then
			if component.isDynamic then
				component.defaultMass = getMass(component.node)
			else
				component.defaultMass = 1
			end
		end
		
		-- get additionalMass from other specializations, this is first
		local additionalMass = self:getAdditionalComponentMass(component)
		
		-- set component mass, this needs to happen before the next step
		component.mass = component.defaultMass + additionalMass		
		
		-- get component mass with wheels, the component.mass from above is already used
		--component.mass = self:getComponentMass(component)
		
		-- add to serverMass
		--self.serverMass = self.serverMass + component.mass
		self.serverMass = self.serverMass + self:getComponentMass(component)
		-- change mass calculation to not double the wheels fix 
		
		-- calculate overload percentage
		self.overloadPercentage = 0
		if self.serverMass > self.maxComponentMass then
			self.overloadPercentage = math.floor(((self.serverMass / self.maxComponentMass) - 1) * 100)
		end
		
		-- if mass changed more than 2kg update 
		if self.isServer and component.isDynamic and math.abs(component.lastMass - component.mass) > 0.02 then
		
			setMass(component.node, component.mass)

			component.lastMass = component.mass
		end		
		
	end
end
Vehicle.updateMass = Utils.overwrittenFunction(Vehicle.updateMass, realismAddon_fillables.updateVehicleMass)

-- overwrite Vehicle.getSpecValueAdditionalWeight function so it does show the possible load weight even with trailerFillLimit turned off
function realismAddon_fillables.vehicleGetSpecValueAdditionalWeight(storeItem, superFunc, realItem, configurations, saleItem, returnValues, returnRange)

	if storeItem.specs.additionalWeight ~= nil then
		local baseWeight = Vehicle.getSpecValueWeight(storeItem, realItem, configurations, saleItem, true)

		if baseWeight ~= nil then
			local additionalWeight = storeItem.specs.additionalWeight - baseWeight

			if returnValues then
				return additionalWeight
			else
				return g_i18n:formatMass(additionalWeight)
			end
		end
	end

	return nil
end
Vehicle.getSpecValueAdditionalWeight = Utils.overwrittenFunction(Vehicle.getSpecValueAdditionalWeight, realismAddon_fillables.vehicleGetSpecValueAdditionalWeight)


