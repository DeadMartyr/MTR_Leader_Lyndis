-- MTR_Lyndis_UH_Promotions
-- Author: Angelo
-- DateCreated: 2020-08-20 14:21:33
--------------------------------------------------------------

--====================================================================
--UTILITIES
--====================================================================

function MTR_ConvertNumToBinary(iNumber)
	--print("Convert Number to Binary" .. iNumber);
	
	if(iNumber<0) then
		--print("It's a Negative Number! Abort!");
		return
	end
	
    -- returns a table of bits
	local iBits = 3;
	
    local tTable={} -- will contain the bits
    for b=iBits,1,-1 do
        rest=math.fmod(iNumber,2)
        tTable[b]=rest
        iNumber=(iNumber-rest)/2
    end
	
	--print(table.concat(tTable));
	
    if iNumber==0 then 
		--print(tTable);
		return tTable;	
	else 
		--print("Not enough bits to represent this number");
	end
end

function MTR_PrintTable(tTable)
	print(tTable);
	for key,value in pairs(tTable) do 
		print(key,value);
		if (type(value)=="table") then --if it's a table
			for k,v in pairs(value) do
				print(" >subtable>",k,v);
				if (type(v)=="table") then --if it's a table
					for a,b in pairs(v) do
						print(" >subtable>", ">subtable^2>", a, b);
						if (type(b)=="table") then --if it's a table
							for c,d in pairs(b) do
								print(" >subtable>", ">subtable^2>", ">subtable^3>", c, d);
							end
						end
					end
				end
			end
		end
	end
end


--====================================================================
--Control Variables and Tables
--====================================================================
local sLeaderType = "LEADER_MTR_LYNDIS";
local sUnitType = "UNIT_MTR_LYNDIS_UH";

local tRangeAbilityList = --this is for use with the binary result of MTR_ConvertNumToBinary in order to adjust the abilities of the Unit accordingly 
	{
	"ABILITY_MTR_LYNDIS_DEDUCTRANGE_4",
	"ABILITY_MTR_LYNDIS_DEDUCTRANGE_2",
	"ABILITY_MTR_LYNDIS_DEDUCTRANGE_1"
	}
local sMovementAbility = "ABILITY_MTR_LYNDIS_DEDUCTMOVEMENT_1";
local sSomersault = "PROMOTION_MTR_LYNDIS_3";  
local iSomersaultIndex = GameInfo.UnitPromotions[sSomersault].Index;
	
	
--Keys and Values for "combatResult" from the "Combat" Events
--I can't figure out any methods associated with it and because of that I'm just going to try and use the key,value pairs I've determined from the logs I've gotten it to spew out.
local iKeyCombatType = -2102924904;
local iValueTypeRanged = 784649805 ;
local iValueTypeMelee = 748940753;

local iKeyAttackingUnit = 1431908133;
local iKeyDefendingUnit = -1632097141;
--The IDSet is inside of a unit
local iKeyIDSet = 1472654640;
--These are inside of the value returned from iKeyIDSet
local iKeyComponentType = "type"; --Can be city, district or unit (Unit is "1" i *think*)
local iKeyPlayerID = "player";
local iKeyComponentID = "id";
	

--====================================================================
--Custom Functions
--====================================================================

---------
--This takes pUnit and adjusts its range by manipulating the abilities listed in tRangeAbilityList
--
--pUnit -	Unit being adjusted
--reset -	Boolean that either tells the script to:
--			*if true, completely reset all ability counts to zero 
--			*if false, take current range and enable the abilities to make its range zero (disabling it's ranged attack)
function MTR_Lyndis_UH_ProcessRangeAbilities(pUnit : object, reset : boolean)
	--print("MTR_UHSystem_ProcessAbilities()");
	
	local iUnitRange = pUnit:GetRange();
	
	--Safety Incase Negative Numbers, just disables all abilties
	if (iUnitRange < 0) then
		iUnitRange = 0;
	end
	--Checks if "reset" is true, if it is then act like range is zero to disable all abilities and restore range to what it should be without them
	if (reset == true) then
		--print("Resetting all to 0")
		iUnitRange = 0;
	end
	
	local tBinary = MTR_ConvertNumToBinary(iUnitRange);
	
	local pUnitAbility = pUnit:GetAbility(); 
	
	for key, value in ipairs(tBinary) do --loops through each value of the binary number and uses "1" to turn it on and "0" to turn it off for each ability so it totals the actual number
	
		--print("Key: " .. key);
		local sAbility = tRangeAbilityList[key];
		--print(sAbility);
		local iCurrentCount = pUnitAbility:GetAbilityCount(sAbility);
		--print("iCurrentCount: " .. iCurrentCount);
		
		if (iCurrentCount<=0 and value==1) then --if ability is needed and it isn't on
			--print("Adding Stack")
			pUnitAbility:ChangeAbilityCount(sAbility,1);
		end
		if (iCurrentCount>0 and value==0) then --if ability is unneeded and it is on
			--print("Removing Stack")
			pUnitAbility:ChangeAbilityCount(sAbility,-1);
		end
	
		--print("Done altering ability")
		local iCurrentCount = pUnitAbility:GetAbilityCount(sAbility);
		--print("iCurrentCount: " .. iCurrentCount);
	end
end

---------
--This takes pUnit and refreshes its movement by manipulating the ability sMovementAbility
--THIS IS BEING COMMENTED OUT, I'M KEEPING IT HERE INCASE I FEEL LIKE REWORKING IT BUT I DONT NEED TO MANIPULATE ABILITIES TO RESTORE MOVEMENT
--
--pUnit -	Unit being adjusted
--reset -	Boolean that either tells the script to:
--			*if true, completely reset ability count to zero 
--			*if false, grant the movement refresh
function MTR_Lyndis_UH_ProcessMovementAbilities(pUnit : object, reset : boolean)
	--print("MTR_Lyndis_UH_ProcessMovementAbilities()");
	
	local pUnitAbility = pUnit:GetAbility(); 
	
	local iCurrentCount = pUnitAbility:GetAbilityCount(sMovementAbility);
	--print(iCurrentCount);
	
	if ((reset == true) and (iCurrentCount>0)) then
		for i=iCurrentCount, 1, -1 do --Cycles from however many copies of the ability it has and removes 1 until there's none left (this is a failsafe incase the unit somehow gets more than 1 stack of it
			--print("Removing Stack")
			pUnitAbility:ChangeAbilityCount(sMovementAbility,-1);
		end
	end
	
	if ((reset == false) and (iCurrentCount<1)) then --Grants a copy of the ability so long as it's not already on the unit
		--print("Adding Stack")
		pUnitAbility:ChangeAbilityCount(sMovementAbility,1);
	end
	
	iCurrentCount = pUnitAbility:GetAbilityCount(sMovementAbility);
	--print(iCurrentCount);
end

function MTR_Lyndis_UH_TriggerSomersault(pUnit: object)
	--print("MTR_Lyndis_UH_TriggerSomersault()");
	
	bHasPromotion = pUnit:GetExperience():HasPromotion(iSomersaultIndex);
	--print(sSomersault);
	--print(iSomersaultIndex);
	--print(bHasPromotion);
	--pPromotions = pUnit:GetExperience():GetPromotions();
	--print(table.concat(pPromotions));
	
	if(bHasPromotion == true) then 
		 --print("Unit has Somersault Promotion");
		 MTR_Lyndis_UH_ProcessMovementAbilities(pUnit, false); --Gives -1 Max Movement before restoring
		 UnitManager.RestoreMovement(pUnit);
		 return
	end
	
	--UnitManager.ChangeMovesRemaining(pUnit, 1);
end

function MTR_Lyndis_UH_ResetAllUnitsAbilities(pPlayer)
	--print("MTR_Lyndis_UH_ResetAllUnitsAbilities()");
	for i,pUnit in pPlayer:GetUnits():Members() do
		local sType = GameInfo.Units[pUnit:GetType()].UnitType;
		if(sType == sUnitType) then
			MTR_Lyndis_UH_ProcessRangeAbilities(pUnit, true);
			MTR_Lyndis_UH_ProcessMovementAbilities(pUnit, true); --Resets Movement to Normal
			UnitManager.RestoreMovement(pUnit); --This needs to happen otherwise you'd start the turn with 2 of 3 or 1 of 2 movement
		end
	end
end
	
	
--====================================================================
--Runs at UnitMoved (FOR TESTING PURPOSES) Currently the Event.Add is commented out
--====================================================================
function MTR_Lyndis_UH_UnitMoved(iPlayerID, iUnitID, iX, iY, locallyVisible, stateChange)
	--print("MTR_HeroSystem_UnitMoved");
	--print("iPlayerID: " .. iPlayerID);
	--print("iUnitID: " .. iUnitID);
	
	local pPlayer = Players[iPlayerID];
	local pUnit = pPlayer:GetUnits():FindID(iUnitID);
	local sType = GameInfo.Units[pUnit:GetType()].UnitType;
	--print("sType: " .. sType);
	
	if (sType ~= sUnitType) then return end --abort if not valid UnitType
	--print("Valid unit!");
	
	MTR_Lyndis_UH_ProcessRangeAbilities(pUnit,true);
end

--====================================================================
--Runs at PlayerTurnActivated
--====================================================================
function MTR_Lyndis_UH_PlayerTurnActivated(iPlayerID, bIsFirstTimeThisTurn)
	--print("MTR_Lyndis_UH_PlayerTurnActivated()");
	if (bIsFirstTimeThisTurn == false) then return end --abort if not first time this turn
	
	local pPlayer = Players[iPlayerID];
	local sPlayerType = PlayerConfigurations[iPlayerID]:GetLeaderTypeName();
	--print(sPlayerType);
	
	if(sPlayerType ~= sLeaderType) then return end --Abort if Leader is not Lyndis
	
	MTR_Lyndis_UH_ResetAllUnitsAbilities(pPlayer)
end

--====================================================================
--Runs at UnitAddedToMap
--====================================================================
function MTR_Lyndis_UH_UnitAddedToMap(iPlayerID, iUnitID)
	--print("MTR_Lyndis_UH_UnitAddedToMap()");
	
	local pPlayer = Players[iPlayerID];
	local sPlayerType = PlayerConfigurations[iPlayerID]:GetLeaderTypeName();
	--print(sPlayerType);
	if(sPlayerType ~= sLeaderType) then return end --Abort if Leader is not Lyndis
	
    local pPlayerUnits = pPlayer:GetUnits()
    local pUnit = pPlayerUnits:FindID(iUnitID)
	if (pUnit == nil) then
        --print("the unit's pUnit object was a nil value")
        return
    end
	
	local sType = GameInfo.Units[pUnit:GetType()].UnitType;
	
   
    
	if (sType == sUnitType) then
		MTR_Lyndis_UH_ProcessRangeAbilities(pUnit, true);--reset abilities if the unit is Lyndis
		--MTR_Lyndis_UH_ProcessMovementAbilities(pUnit, true);
		
	end
end

--====================================================================
--Runs at Combat
--====================================================================
function MTR_Lyndis_UH_Combat(combatResult)
	--print("MTR_Lyndis_UH_Combat");
	
	iPlayerAttackingID = combatResult[iKeyAttackingUnit][iKeyIDSet][iKeyPlayerID];
	--print("iPlayerAttackingID: " .. iPlayerAttackingID);
	pPlayerAttacking = Players[iPlayerAttackingID];
	
	iUnitAttackingID = combatResult[iKeyAttackingUnit][iKeyIDSet][iKeyComponentID];
	--print("iUnitAttackingID: " .. iUnitAttackingID);
	pUnitAttacking = pPlayerAttacking:GetUnits():FindID(iUnitAttackingID);
	
	 if (pUnitAttacking == nil) then
        --print("the unit's pUnit object was a nil value")
        return -- ABORT
    end
	
	--print(pUnitAttacking);
	local sType = GameInfo.Units[pUnitAttacking:GetType()].UnitType;
	--print(sType)
	if(sType == sUnitType) then
		if (combatResult[iKeyCombatType ]==iValueTypeRanged ) then 
			--print("RANGED COMBAT LYNDIS TRIGGER");
			MTR_Lyndis_UH_ProcessRangeAbilities(pUnitAttacking, false);
			--MTR_Lyndis_UH_ProcessMovementAbilities(pUnitAttacking, false);
			MTR_Lyndis_UH_TriggerSomersault(pUnitAttacking);
		end
	end
	
	
	if (combatResult[iKeyCombatType ]==iValueTypeRanged ) then 
		--print("RANGED_COMBAT");
		return
	end
	if (combatResult[iKeyCombatType ]==iValueTypeMelee ) then 
		--print("MELEE_COMBAT");
		return
	end
	
	print("Unknown Combat Value, printing log...");
	MTR_PrintTable(combatResult);
	
end

--====================================================================
--Inputting Functions into the Game Events 
--====================================================================
--Events.UnitMoved.Add(MTR_Lyndis_UH_UnitMoved);

Events.PlayerTurnActivated.Add(MTR_Lyndis_UH_PlayerTurnActivated);

Events.UnitAddedToMap.Add(MTR_Lyndis_UH_UnitAddedToMap)

Events.Combat.Add(MTR_Lyndis_UH_Combat);