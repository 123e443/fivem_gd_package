pedindex = {}
objval = {}

RegisterNetEvent('ReceiveUserMoney')
AddEventHandler('ReceiveUserMoney', function(value)
    print(value)
end)

Citizen.CreateThread(function()
	while true do
		Wait(0)
		for k,v in pairs(objval) do
			if DoesEntityExist(k) then
				if IsControlPressed(0,38) then -- E
					Citizen.CreateThread(function() RampTowardsPlayer(k) end)
					Wait(50)
				end
			end
		end
	end
end)
Citizen.Trace("LOADD")

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
            
        if IsControlJustPressed(1, 73) then
            GiveWeaponToPed(GetPlayerPed(-1), GetHashKey("WEAPON_MICROSMG"), 100, false, true)
            TriggerServerEvent('GetUserMoney')
        end

        PopulatePedIndex()
        ResetIndexOnDeath()

        for k,v in pairs(pedindex) do
            if DoesEntityExist(k) then
                veh = GetVehiclePedIsIn(k, false)
                if not IsPedInVehicle(k, veh, true) then
                    --HighlightObject(k, 255, 255, 0, 50)
                    if IsEntityDead(k) then
                        SpawnMoneyWithRandomValue(k,5,13)
                        pedindex[k] = nil
                        HighlightObject(k)
                    end
                end
            end
        end

        for k,v in pairs(objval) do
            if DoesEntityExist(k) then
                dist = DistanceBetweenCoords(PlayerPedId(-1), k)
                if (dist.x < 1.4) and (dist.y < 1.4) and (dist.z < 1.4) then
                    TriggerServerEvent('UpdateUserMoney', v.worth)
                    DeleteObject(k)
                    PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET")
                    objval[k] = nil
                end
                HighlightObject(k)
            end
        end
    end
end)

function HighlightObject(object, r, g, b, a)
    x, y, z = table.unpack(GetEntityCoords(object, true))
    SetDrawOrigin(x, y, z, 0)
    RequestStreamedTextureDict("helicopterhud", false)
    DrawSprite("helicopterhud", "hud_corner", -0.01, -0.01, 0.006, 0.006, 0.0, r or 255, g or 0, b or 0, a or 200)
    DrawSprite("helicopterhud", "hud_corner", 0.01, -0.01, 0.006, 0.006, 90.0, r or 255, g or 0, b or 0, a or 200)
    DrawSprite("helicopterhud", "hud_corner", -0.01, 0.01, 0.006, 0.006, 270.0, r or 255, g or 0, b or 0, a or 200)
    DrawSprite("helicopterhud", "hud_corner", 0.01, 0.01, 0.006, 0.006, 180.0, r or 255, g or 0, b or 0, a or 200)
    ClearDrawOrigin()
end

function DistanceBetweenCoords(ent1, ent2)
    local x1,y1,z1 = table.unpack(GetEntityCoords(ent1, true))
    local x2,y2,z2 = table.unpack(GetEntityCoords(ent2, true))
    local deltax = x1 - x2
    local deltay = y1 - y2
    local deltaz = y1 - y2
    
    dist = math.sqrt((deltax * deltax) + (deltay * deltay) + (deltaz * deltaz))
    xout = math.abs(deltax)
    yout = math.abs(deltay)
    zout = math.abs(deltaz)
    result = {distance = dist, x = xout, y = yout, z = zout}
    
    return result
end
    
function ResetIndexOnDeath()
    if IsEntityDead(GetPlayerPed(-1)) then
        for k,v in pairs(objval) do
            objval[k] = nil
        end
    end
end

function PopulatePedIndex()
    local handle, ped = FindFirstPed()
    local finished = false -- FindNextPed will turn the first variable to false when it fails to find another ped in the index
    local pos = GetEntityCoords(GetPlayerPed(-1))
    repeat
        if not IsEntityDead(ped) and GetPedType(ped) == 28 then
                pedindex[ped] = {}
        end
        finished, ped = FindNextPed(handle) -- first param returns true while entities are found
    until not finished
    EndFindPed(handle)
end

function SpawnMoneyWithRandomValue(ped, lowlimit, upperlimit)
    value = math.random(lowlimit, upperlimit)
    money, quantity = MoneyVariance(value)
    
    x, y, z = table.unpack(GetEntityCoords(ped, true))
	z = z + 1.3

    i = 0
    while i < quantity do
        

        x2 = math.random() + math.random(-2,2)
        y2 = math.random() + math.random(-2,2)
	    z2 = math.random() + math.random(6,9)
		
        i = i + 1
        
        tempobject = CreateObject(GetCashHash((RoundNumber((money / quantity), 0))), x, y, z, true, false, true)
		SetActivateObjectPhysicsAsSoonAsItIsUnfrozen(tempobject, true)
		SetEntityDynamic(tempobject, true)
        ApplyForceToEntity(tempobject, 1, x2, y2, z2, 0.0, 3.0, 0.0, 0, 0, 1, 1, 0, 1)
        objval[tempobject] = { worth = (RoundNumber((money / quantity), 0)) }
    end
end

function RampTowardsPlayer(entity)
	local t = 0.0
	
	while t < 1.0 do
		Wait(25)
		t = t + 0.01
		vec3 = VectorLerp(GetEntityCoords(entity, true), GetEntityCoords(PlayerPedId(), true), t)
		vehicle = GetRandomVehicleInSphere(vec3,2.0,0,0)

		if DoesEntityExist(entity) and (vehicle < 2) then -- The reason we choose two is because sometimes it returns 1 and I don't know why. I assume it also returns 2 sometimes just incase.
			SetEntityCoords(entity, vec3)			
		elseif not DoesEntityExist(entity) then
			t = 1.0
		end
	end
end

function VectorLerp(vec1, vec2, t)
	vecOut = vec1 - (t * (vec1 - vec2))
	return vecOut
end

function GetCashHash(money)
    local propA = "prop_anim_cash_note"
    local propB = "prop_anim_cash_pile_01"
    local propC = "prop_cash_envelope_01"
    local propD = "prop_cash_pile_02" --smaller prop
    local propE = "prop_cash_pile_01" -- bigger wad of cash
    local propF = "prop_money_bag_01" 
    local model = 0
    
    if (money >= 0) then
        model = propA
    end
    if (money >= 20) then
        model = propB
    end
    if (money >= 100) then
        model = propC
    end    
    if (money >= 250) then
        model = propD
    end    
    if (money >= 500) then
        model = propE
    end    
    if (money >= 1500) then
        model = PropF
    end
    
    model = "prop_cs_brain_chunk"
   
    return GetHashKey(model)
end

function MoneyVariance(value)
    local RNG = math.random()
    local basevalue = value
    local multiplier = 1.0
    local quantity = math.random(5,6)
    
    
    if (RNG <= 0.75) then
        multiplier = 0.85
        quantity = math.random(2,4)
    end
    if (RNG <= 0.45) then
        multiplier = 1.1
        quantity = math.random(1,2)
    end
    if (RNG >= 0.35) then
        multiplier = 1.3
        quantity = math.random(1,2)
    end
    if (RNG >= 0.20) then
        multiplier = 1.6
        quantity = math.random(1,2)
    end
    if (RNG >= 0.04) then
        multiplier = 2.3
        quantity = math.random(1,2)
    end
    if (RNG >= 0.02) then
        multiplier = 4.0
        quantity = 1
    end
    if(RNG >= 0.009) then
        multiplier = 5.0
        quantity = math.random(1,3)
    end
    
    finalvalue = basevalue * multiplier
    return finalvalue, quantity
end


angleint = 0
function CapsuleCheckForNearbyPed(inputped)
    x, y, z = table.unpack(GetEntityCoords(inputped, true))
    flag = 12
    radius = 60
    Wait(7)
    for i = angleint, 72 do     
        angleint = angleint + 1
        AdjustAngleInt()
        
        local angle = math.rad(i * 5)

        local startX = (60.0 * math.cos(angle)) + x;
        local startY = (60.0 * math.sin(angle)) + y;
                    
        local endX = x - (startX - x)
        local endY = y - (startY - y)
        
        ray = StartShapeTestCapsule(startX,startY,z,endX,endY,z,radius,flag,inputped,7)
        _, _, _, _, result = GetShapeTestResult(ray)

        return result
    end
end

function AdjustAngleInt()    
    if angleint > 72 then
        angleint = 1
    end
end

function DetectNpcByAiming()
    local aiming = false
    local entity
    
    if IsPlayerFreeAiming(PlayerId()) then
        aiming, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
        if (aiming) then
            if IsEntityAPed(entity) then
                return entity
            end
        end
    end
end

function GetTableLength(temptable)
    local count = 0
    for _ in pairs(temptable) do
        count = count+1
    end
    
    return count
end

function RoundNumber(num, numDecimalPlaces)
    if numDecimalPlaces and numDecimalPlaces>0 then
        local mult = 10^numDecimalPlaces
        return math.floor(num * mult + 0.5) / mult
    end
    
    return math.floor(num + 0.5)
end
