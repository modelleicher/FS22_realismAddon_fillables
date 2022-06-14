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
realismAddon_fillables.includeSpecList = {"spec_trailer", "spec_combine"}
-- list of specs that if included disable the capacity limit 
realismAddon_fillables.excludeSpecList = {"spec_mixerWagon"}
-- list of fillTypes that are excluded from the capacity limit change 
realismAddon_fillables.excludeFillTypesList = {"diesel", "water", "liquidManure", "liquidFertilizer", "milk", "def", "herbicide", "digestate", "SUNFLOWER_OIL", "CANOLA_OIL", "OLIVE_OIL", "CHOCOLATE", "BOARDS", "FURNITURE", "EGG", "TOMATO", "LETTUCE", "ELECTRICCHARGE", "METHANE", "WOOL", "TREESAPLINGS" }



-- FillUnit:setFillUnitCapacity(fillUnitIndex, capacity, noEventSend)

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


function realismAddon_fillables:addFillUnitFillLevel(superFunc, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
	
	local includes, excludes = realismAddon_fillables.checkIncludeExcludeSpecs(self)
	
	if includes and excludes then
	

		local spec = self.spec_fillUnit
		local fillUnit = spec.fillUnits[fillUnitIndex]
		
		if realismAddon_fillables.checkExcludeFillType(fillUnit) then
		
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
					
					-- add the randomValue to lossPercent, max. random is 20% more than lossPercent and max lossPercent is 1 (100%)
					lossPercent = math.min(1, lossPercent + (randomValue * 0.2))
					
					-- finally remove loss from delta 
					fillLevelDelta = fillLevelDelta * lossPercent
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
		
	if includes and excludes then
	
		local spec = self.spec_fillUnit
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
		
	if includes and excludes then
	
	
		local spec = self.spec_fillUnit
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
	if includes and excludes then
	
	
		local spec = self.spec_fillUnit
		
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
				fillUnit.capacity = fillUnit.capacityOriginal
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
	if includes and excludes then
	
	
		local spec = self.spec_fillUnit
		
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
		component.mass = self:getComponentMass(component)
		
		-- add to serverMass
		self.serverMass = self.serverMass + component.mass
		
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


