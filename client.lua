local piggyback = {
	InProgress = false,
	targetSrc = -1,
	type = "",
	personPiggybacking = {
		animDict = "anim@arena@celeb@flat@paired@no_props@",
		anim = "piggyback_c_player_a",
		flag = 49,
	},
	personBeingPiggybacked = {
		animDict = "anim@arena@celeb@flat@paired@no_props@",
		anim = "piggyback_c_player_b",
		attachX = 0.0,
		attachY = -0.07,
		attachZ = 0.45,
		flag = 33,
	}
}

local carry = {
	InProgress = false,
	targetSrc = -1,
	type = "",
	personCarrying = {
		animDict = "missfinale_c2mcs_1",
		anim = "fin_c2_mcs_1_camman",
		flag = 49,
	},
	personCarried = {
		animDict = "nm",
		anim = "firemans_carry",
		attachX = 0.27,
		attachY = 0.15,
		attachZ = 0.63,
		flag = 33,
	}
}

local function drawNativeNotification(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

local function GetClosestPlayer(radius)
    local players = GetActivePlayers()
    local closestDistance = -1
    local closestPlayer = -1
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    for _,playerId in ipairs(players) do
        local targetPed = GetPlayerPed(playerId)
        if targetPed ~= playerPed then
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(targetCoords - playerCoords)
            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = playerId
                closestDistance = distance
            end
        end
    end
	if closestDistance ~= -1 and closestDistance <= radius then
		return closestPlayer
	else
		return nil
	end
end

local function ensureAnimDict(animDict)
    if not HasAnimDictLoaded(animDict) then
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(0)
        end        
    end
    return animDict
end

RegisterCommand("piggyback",function(source, args)
	if not piggyback.InProgress and not carry.InProgress then
		local closestPlayer = GetClosestPlayer(3)
		if closestPlayer then
			local targetSrc = GetPlayerServerId(closestPlayer)
			if targetSrc ~= -1 then
				piggyback.InProgress = true
				piggyback.targetSrc = targetSrc
				TriggerServerEvent("Piggyback:sync", targetSrc)
				ensureAnimDict(piggyback.personPiggybacking.animDict)
				piggyback.type = "piggybacking"
			else
				drawNativeNotification("~r~No one nearby to piggyback!")
			end
		else
			drawNativeNotification("~r~No one nearby to piggyback!")
		end
	else
		piggyback.InProgress = false
		ClearPedSecondaryTask(PlayerPedId())
		DetachEntity(PlayerPedId(), true, false)
		TriggerServerEvent("Piggyback:stop", piggyback.targetSrc)
		piggyback.targetSrc = 0
	end
end, false)

RegisterCommand("carry",function(source, args)
	if not carry.InProgress and not piggyback.InProgress then
		local closestPlayer = GetClosestPlayer(3)
		if closestPlayer then
			local targetSrc = GetPlayerServerId(closestPlayer)
			if targetSrc ~= -1 then
				carry.InProgress = true
				carry.targetSrc = targetSrc
				TriggerServerEvent("CarryPeople:sync", targetSrc)
				ensureAnimDict(carry.personCarrying.animDict)
				carry.type = "carrying"
			else
				drawNativeNotification("~r~No one nearby to carry!")
			end
		else
			drawNativeNotification("~r~No one nearby to carry!")
		end
	else
		carry.InProgress = false
		ClearPedSecondaryTask(PlayerPedId())
		DetachEntity(PlayerPedId(), true, false)
		TriggerServerEvent("CarryPeople:stop", carry.targetSrc)
		carry.targetSrc = 0
	end
end, false)

RegisterNetEvent("Piggyback:syncTarget")
AddEventHandler("Piggyback:syncTarget", function(targetSrc)
	local playerPed = PlayerPedId()
	local targetPed = GetPlayerPed(GetPlayerFromServerId(targetSrc))
	piggyback.InProgress = true
	ensureAnimDict(piggyback.personBeingPiggybacked.animDict)
	AttachEntityToEntity(playerPed, targetPed, 0, piggyback.personBeingPiggybacked.attachX, piggyback.personBeingPiggybacked.attachY, piggyback.personBeingPiggybacked.attachZ, 0.5, 0.5, 180, false, false, false, false, 2, false)
	piggyback.type = "beingPiggybacked"
end)

RegisterNetEvent("CarryPeople:syncTarget")
AddEventHandler("CarryPeople:syncTarget", function(targetSrc)
	local targetPed = GetPlayerPed(GetPlayerFromServerId(targetSrc))
	carry.InProgress = true
	ensureAnimDict(carry.personCarried.animDict)
	AttachEntityToEntity(PlayerPedId(), targetPed, 0, carry.personCarried.attachX, carry.personCarried.attachY, carry.personCarried.attachZ, 0.5, 0.5, 180, false, false, false, false, 2, false)
	carry.type = "beingCarried"
end)

RegisterNetEvent("Piggyback:cl_stop")
AddEventHandler("Piggyback:cl_stop", function()
	piggyback.InProgress = false
	ClearPedSecondaryTask(PlayerPedId())
	DetachEntity(PlayerPedId(), true, false)
end)

RegisterNetEvent("CarryPeople:cl_stop")
AddEventHandler("CarryPeople:cl_stop", function()
	carry.InProgress = false
	ClearPedSecondaryTask(PlayerPedId())
	DetachEntity(PlayerPedId(), true, false)
end)

Citizen.CreateThread(function()
	while true do
		if piggyback.InProgress then
			if piggyback.type == "beingPiggybacked" then
				if not IsEntityPlayingAnim(PlayerPedId(), piggyback.personBeingPiggybacked.animDict, piggyback.personBeingPiggybacked.anim, 3) then
					TaskPlayAnim(PlayerPedId(), piggyback.personBeingPiggybacked.animDict, piggyback.personBeingPiggybacked.anim, 8.0, -8.0, 100000, piggyback.personBeingPiggybacked.flag, 0, false, false, false)
				end
			elseif piggyback.type == "piggybacking" then
				if not IsEntityPlayingAnim(PlayerPedId(), piggyback.personPiggybacking.animDict, piggyback.personPiggybacking.anim, 3) then
					TaskPlayAnim(PlayerPedId(), piggyback.personPiggybacking.animDict, piggyback.personPiggybacking.anim, 8.0, -8.0, 100000, piggyback.personPiggybacking.flag, 0, false, false, false)
				end
			end
		end
		
		if carry.InProgress then
			if carry.type == "beingCarried" then
				if not IsEntityPlayingAnim(PlayerPedId(), carry.personCarried.animDict, carry.personCarried.anim, 3) then
					TaskPlayAnim(PlayerPedId(), carry.personCarried.animDict, carry.personCarried.anim, 8.0, -8.0, 100000, carry.personCarried.flag, 0, false, false, false)
				end
			elseif carry.type == "carrying" then
				if not IsEntityPlayingAnim(PlayerPedId(), carry.personCarrying.animDict, carry.personCarrying.anim, 3) then
					TaskPlayAnim(PlayerPedId(), carry.personCarrying.animDict, carry.personCarrying.anim, 8.0, -8.0, 100000, carry.personCarrying.flag, 0, false, false, false)
				end
			end
		end
		Wait(0)
	end
end)
