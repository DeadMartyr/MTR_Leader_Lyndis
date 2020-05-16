-- MTR_Lyndis_Scripts
-- Author: Martyr
-- DateCreated: 2020-04-11 17:50:51
--------------------------------------------------------------

--Element 1: Gain flat progress increase in a city for any tiles gained in that city. Plains (flat & hills) grant extra
--DONE


--Element 2: Grants Culture +1 food and +1 culture for every 3 plains tiles (flat & hills) OWNED by a city


--References:
-- Query	Plot	:GetOwner()


--====================================================================
--Utilities
--Credit: Chrisy15 and LeeS
--====================================================================
function MTR_getValidPlayersWithTrait(sTrait)
	--print("MTR_getValidPlayersWithTrait");
	local tValidPlayers = {}
	
	for k, v in ipairs(PlayerManager.GetWasEverAliveIDs()) do
		--print("for k, v in ipairs statement");
		local leaderType = PlayerConfigurations[v]:GetLeaderTypeName() --this returns actual String ("LEADER_MTR_LYNDIS")
        for trait in GameInfo.LeaderTraits() do -- the variable trait here is actually a table  THIS PART SCREENS ALL LEADERS IN THE GAME FOR THE TRAITS
			--print("trait");
			--print(trait);
			--print(trait.LeaderType);
			--print(trait.TraitType);
            if trait.LeaderType == leaderType and trait.TraitType == sTrait then 
				--print("Valid Trait!");
                tValidPlayers[v] = true 
            end;
        end
        if not tValidPlayers[v] then --IF v WAS NOT ADDED YET (saves processing power)
			--print("if not statement")
            local civType = PlayerConfigurations[v]:GetCivilizationTypeName() --returns actual String
			--print("civType " .. civType);
            for trait in GameInfo.CivilizationTraits() do -- the variable trait here is a table THIS PART SCREENS ALL CIVILIZATIONS IN THE GAME FOR THIS TRAIT
				--print("trait");
				--print(trait);
				--print(trait.CivilizationType);
				--print(trait.TraitType);
                if trait.CivilizationType == civType and trait.TraitType == sTrait then 
					--print("Valid Trait!");
                    tValidPlayers[v] = true 
                end;
            end
        end
    end
	--print("returning...");
    return tValidPlayers
end

--Function by LeeS, City:GetOwnedPlots() is weird as hell and wouldn't work, this just manually does what it's supposed to
function GetCityPlots(pCity)
    local tTempTable = {}
    if pCity ~= nil then
        local iCityRadius = 3
        local iTableCount = 1
        local iCityOwner = pCity:GetOwner()
        local iCityX, iCityY = pCity:GetX(), pCity:GetY()
        for dx = (iCityRadius * -1), iCityRadius do
            for dy = (iCityRadius * -1), iCityRadius do
                local pPlotNearCity = Map.GetPlotXYWithRangeCheck(iCityX, iCityY, dx, dy, iCityRadius);
                if pPlotNearCity and (pPlotNearCity:GetOwner() == iCityOwner) then
                    local iPlotIndex, bAddToTable = pPlotNearCity:GetIndex(), false
                    if ((Cities.GetPlotWorkingCity(iPlotIndex) ~= nil) and (pCity == Cities.GetPlotWorkingCity(iPlotIndex))) then
                        bAddToTable = true
                    elseif ((Cities.GetPlotWorkingCity(iPlotIndex) == nil) and (pCity == Cities.GetPlotPurchaseCity(iPlotIndex))) then
                        bAddToTable = true
                    end
                    if (bAddToTable == true) then
                        tTempTable[iTableCount] = pPlotNearCity
                        iTableCount = iTableCount + 1
                    end
                end
            end
        end
    end
    return tTempTable
end

--====================================================================
--Constants
--====================================================================

	local sTrait = "TRAIT_LEADER_MTR_LYNDIS_UA";
	local tValidPlayerList = MTR_getValidPlayersWithTrait(sTrait); --Key is PlayerID, returns true or nil based on what MTR_getValidPlayersWithTrait returns
	
	--Element 1 Data Table, holds amounts to boost for each type of Terrain
	local tValidTerrainExpansionList = 
		{
		[GameInfo.Terrains["TERRAIN_GRASS"].Index] = 5,
		[GameInfo.Terrains["TERRAIN_GRASS_HILLS"].Index] = 2.5,
		[GameInfo.Terrains["TERRAIN_PLAINS"].Index] = 10,
		[GameInfo.Terrains["TERRAIN_PLAINS_HILLS"].Index] = 5 
		}
	
	
	--Element 2 Control Variables
	local tValidTerrainOwnedList = 
	{
	[GameInfo.Terrains["TERRAIN_PLAINS"].Index] = 2, -- 2 "points" for a plains
	[GameInfo.Terrains["TERRAIN_PLAINS_HILLS"].Index] = 1 -- 1 "point" for a plains hills
	}
	local iPointsPerStack = 4;	-- x "Points" gives a "Stack"
	local iCulturePerStack = 1; -- x Culture per Stack
	local iFoodPerStack = 1;	-- x Food per Stack
	
	local iDummyStack1 = GameInfo.Buildings["BUILDING_MTR_LYNDIS_UA_DUMMY_STACK1"].Index;
	local iDummyStack2 = GameInfo.Buildings["BUILDING_MTR_LYNDIS_UA_DUMMY_STACK2"].Index;
	local iDummyStack3 = GameInfo.Buildings["BUILDING_MTR_LYNDIS_UA_DUMMY_STACK3"].Index;
	local iDummyStack4 = GameInfo.Buildings["BUILDING_MTR_LYNDIS_UA_DUMMY_STACK4"].Index;
	local iDummyStack5 = GameInfo.Buildings["BUILDING_MTR_LYNDIS_UA_DUMMY_STACK5"].Index;
	local iDummyStack6 = GameInfo.Buildings["BUILDING_MTR_LYNDIS_UA_DUMMY_STACK6"].Index;
	
	

--====================================================================
--Runs on CityTileOwnershipChanged
--====================================================================
function MTR_LyndisUA_ExpansionBoost(pCity, pPlot)
	print("MTR_LyndisUA_ExpansionBoost");
	local iBoostToApply = 0;
	print(pPlot:GetTerrainType());
	
	if (tValidTerrainExpansionList[pPlot:GetTerrainType()]~=nil) then
		print("ITS VALID!");
		iBoostToApply = tValidTerrainExpansionList[pPlot:GetTerrainType()];
	end
	
	pCity:GetBuildQueue():AddProgress(iBoostToApply);
	print("Boost of " .. iBoostToApply);
end

function MTR_LyndisUA_CityTileOwnershipChanged(owner, cityID)
	print("MTR_LyndisUA_CityTileOwnershipChanged")
	print(owner);
	--print(cityID);
	
	if(tValidPlayerList[owner]==true) then
		print("ValidPlayer!")
		local pPlayer = Players[owner];
		local pCity = pPlayer:GetCities():FindID(cityID);
		local tCityPlots = GetCityPlots(pCity)
		if tCityPlots ~= nil then
			for Item, pPlot in ipairs(tCityPlots) do
				print(pCity:GetName() .. "| X: " .. pPlot:GetX() .. " Y: " .. pPlot:GetY());
				if (pPlot:GetProperty("TRAIT_LEADER_MTR_LYNDIS_UA") == nil) then
					print("Tile wasn't acted on before!");
					MTR_LyndisUA_ExpansionBoost(pCity, pPlot);
					pPlot:SetProperty("TRAIT_LEADER_MTR_LYNDIS_UA", 1);
					print("PropertySet!");
				end
			end
		end
	end
end
	
--====================================================================
--Runs on PlotPropertyChanged
--====================================================================
--function MTR_LyndisUA_PlotPropertyChanged(iX, iY)
--	print("MTR_LyndisUA_PlotPropertyChanged")
--	print("X: " .. iX);
--	print("Y: " .. iY);
--end

--====================================================================
--Runs on PlayerTurnDeactivated
--====================================================================
function MTR_LyndisUA_StripDummies(pCityBuildings, iStacksRequired)
	print("MTR_LyndisUA_StripDummies");
	if ((pCityBuildings:HasBuilding(iDummyStack1) == true) and (iStacksRequired~=1)) then
		pCityBuildings:RemoveBuilding(iDummyStack1);
		print("Reset Stacks from 1");
	end
	if ((pCityBuildings:HasBuilding(iDummyStack2) == true) and (iStacksRequired~=2)) then
		pCityBuildings:RemoveBuilding(iDummyStack2);
		print("Reset Stacks from 2");
	end
	if ((pCityBuildings:HasBuilding(iDummyStack3) == true) and (iStacksRequired~=3)) then
		pCityBuildings:RemoveBuilding(iDummyStack3);
		print("Reset Stacks from 3");
	end
	if ((pCityBuildings:HasBuilding(iDummyStack4) == true) and (iStacksRequired~=4)) then
		pCityBuildings:RemoveBuilding(iDummyStack4);
		print("Reset Stacks from 4");
	end
	if ((pCityBuildings:HasBuilding(iDummyStack5) == true) and (iStacksRequired~=5)) then
		pCityBuildings:RemoveBuilding(iDummyStack5);
		print("Reset Stacks from 5");
	end
	if ((pCityBuildings:HasBuilding(iDummyStack6) == true) and (iStacksRequired~=6)) then
		pCityBuildings:RemoveBuilding(iDummyStack6);
		print("Reset Stacks from 6");
	end
end

function MTR_LyndisUA_AdjustCityDummy(pCity, iCountedTiles)
	print("MTR_LyndisUA_AdjustCityDummy");
	local iStacksRequired = math.floor(iCountedTiles / iPointsPerStack);
	print("Stacks Required: " .. iStacksRequired);
	
	local pCityBuildings = pCity:GetBuildings() -- Get city buildings
	
	
	--needed to create the dummy buildings for some reason
	local pPlot = Map.GetPlot(pCity:GetX(), pCity:GetY())
	local iPlot = pPlot:GetIndex()
	
	if(iStacksRequired==0) then
		print("Zero Stacks");
		MTR_LyndisUA_StripDummies(pCityBuildings, iStacksRequired);
		return --abort if 0 stacks
	end
	if(iStacksRequired==1) then
		print("One Stack");
		MTR_LyndisUA_StripDummies(pCityBuildings, iStacksRequired);
		if (pCityBuildings:HasBuilding(iDummyStack1) ~= true) then
			pCity:GetBuildQueue():CreateIncompleteBuilding(iDummyStack1, iPlot, 100)
			end
		return --abort if 1 stacks
	end
	if(iStacksRequired==2) then
		print("Two Stacks");
		MTR_LyndisUA_StripDummies(pCityBuildings, iStacksRequired);
		if (pCityBuildings:HasBuilding(iDummyStack2) ~= true) then
			pCity:GetBuildQueue():CreateIncompleteBuilding(iDummyStack2, iPlot, 100)
			end
		return --abort if 2 stacks
	end
	if(iStacksRequired==3) then
		print("Three Stacks");
		MTR_LyndisUA_StripDummies(pCityBuildings, iStacksRequired);
		if (pCityBuildings:HasBuilding(iDummyStack3) ~= true) then
			pCity:GetBuildQueue():CreateIncompleteBuilding(iDummyStack3, iPlot, 100)
			end
		return --abort if 3 stacks
	end
	if(iStacksRequired==4) then
		print("Four Stacks");
		MTR_LyndisUA_StripDummies(pCityBuildings, iStacksRequired);
		if (pCityBuildings:HasBuilding(iDummyStack4) ~= true) then
			pCity:GetBuildQueue():CreateIncompleteBuilding(iDummyStack4, iPlot, 100)
			end
		return --abort if 4 stacks
	end
	if(iStacksRequired==5) then
		print("Five Stacks");
		MTR_LyndisUA_StripDummies(pCityBuildings, iStacksRequired);
		if (pCityBuildings:HasBuilding(iDummyStack5) ~= true) then
			pCity:GetBuildQueue():CreateIncompleteBuilding(iDummyStack5, iPlot, 100)
			end
		return --abort if 5 stacks
	end
	if(iStacksRequired>=6) then
		print("Six Stacks");
		MTR_LyndisUA_StripDummies(pCityBuildings, iStacksRequired);
		if (pCityBuildings:HasBuilding(iDummyStack6) ~= true) then
			pCity:GetBuildQueue():CreateIncompleteBuilding(iDummyStack6, iPlot, 100)
			end
		return --abort if 6 stacks
	end
end

function MTR_LyndisUA_PlayerTurnDeactivated(playerID)
	print("MTR_LyndisUA_PlayerTurnDeactivated")
	print("playerID: " .. playerID);
	if(tValidPlayerList[playerID]==true) then
		print("ValidPlayer!")
		local pPlayer = Players[playerID];
		for i, pCity in pPlayer:GetCities():Members() do --for each of the players cities
			local tCityPlots = GetCityPlots(pCity);
			local iCountedTiles = 0;
			if tCityPlots ~= nil then
				for Item, pPlot in ipairs(tCityPlots) do --for each of the plots in that city
					if (tValidTerrainOwnedList[pPlot:GetTerrainType()]~=nil) then
						print("Valid Terrain: " .. tValidTerrainOwnedList[pPlot:GetTerrainType()]);
						iCountedTiles = iCountedTiles + tValidTerrainOwnedList[pPlot:GetTerrainType()];
						print("Current Count: " .. iCountedTiles);
					end
				end
			end
			MTR_LyndisUA_AdjustCityDummy(pCity, iCountedTiles);
		end
	end
end
	
	
--====================================================================
--Inputting Functions into the Game Events 
--====================================================================
Events.CityTileOwnershipChanged.Add(MTR_LyndisUA_CityTileOwnershipChanged);
--Events.PlotPropertyChanged.Add(MTR_LyndisUA_PlotPropertyChanged);
Events.PlayerTurnDeactivated.Add(MTR_LyndisUA_PlayerTurnDeactivated);