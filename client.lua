local playerNames = {}
local newbiePlayers = {}
local streamedPlayers = {}
local maskNumbers = {}
local nameThread = false
local myName = true
local namesVisible = true

local localPed = nil

local txd = CreateRuntimeTxd("adminsystem")
local tx = CreateRuntimeTextureFromImage(txd, "logo", "assets/logo.png")

RegisterCommand("names", function()
	setNamesVisible(not namesVisible)
end)

RegisterCommand("togmyname", function()
	myName = not myName
end)

AddEventHandler("esx_skin:playerRegistered", function()
	Wait(1000)
	TriggerServerEvent("requestPlayerNames")
end)

RegisterNetEvent("receivePlayerNames", function(names, newbies)
	playerNames = names
	newbiePlayers = newbies
end)

function generateRandomNumber()
	return string.format("%04d", math.random(0, 9999))
end

function playerStreamer()
	while namesVisible do
		streamedPlayers = {}
		localPed = PlayerPedId()

		local localCoords = GetEntityCoords(localPed)
		local localId = PlayerId()

		for _, player in pairs(GetActivePlayers()) do
			local playerPed = GetPlayerPed(player)

			if (player == localId and myName) or player ~= localId then
				if DoesEntityExist(playerPed) and HasEntityClearLosToEntity(localPed, playerPed, 17) and IsEntityVisible(playerPed) then
					local playerCoords = GetEntityCoords(playerPed)
					if IsSphereVisible(playerCoords, 0.0099999998) then
						local distance = #(localCoords - playerCoords)

						local serverId = tonumber(GetPlayerServerId(player))
						if serverId and distance <= STREAM_DISTANCE and playerNames[serverId] then
							local label
							if GetPedDrawableVariation(playerPed, 1) ~= 0 then -- Check if the player is wearing a mask
								if not maskNumbers[serverId] then
									maskNumbers[serverId] = generateRandomNumber()
								end
								label = "Masked_" .. maskNumbers[serverId]
							else
								label = playerNames[serverId] .. " (" .. serverId .. ")"
							end

							streamedPlayers[serverId] = {
								playerId = player,
								ped = playerPed,
								label = label
							}
						end
					end
				end
			end
		end

		if next(streamedPlayers) and not nameThread then
			CreateThread(drawNames)
		end

		Citizen.Wait(500)
	end

	streamedPlayers = {}
end
CreateThread(playerStreamer)

function drawNames()
	nameThread = true

	while next(streamedPlayers) do
		local myCoords = GetEntityCoords(localPed)

		for serverId, playerData in pairs(streamedPlayers) do
			local coords = getPedHeadCoords(playerData.ped)

			local dist = #(coords - myCoords)
			local scale = 1 - dist / STREAM_DISTANCE

			if scale > 0 then
				DrawText3D(coords, {
					{ text = playerData.label, color = { 255, 255, 255 } }
				}, scale, 255)
			end
		end

		Citizen.Wait(0)
	end

	nameThread = false
end

function setMyNameVisible(state)
	myName = state
end
exports("setMyNameVisible", setMyNameVisible)

function getMyNameVisible()
	return myName
end
exports("getMyNameVisible", getMyNameVisible)

function setNamesVisible(state)
	namesVisible = state
	if namesVisible then
		CreateThread(playerStreamer)
	end
end
exports("setNamesVisible", setNamesVisible)

exports("isNamesVisible", function()
	return namesVisible
end)

function getPedHeadCoords(ped)
	local headBone = 0x796e
	local coords = GetWorldPositionOfEntityBone(ped, GetPedBoneIndex(ped, headBone))
	return coords + vector3(0.0, 0.0, 0.3) -- Adjusted to move the text down
end

function DrawText3D(coords, texts, scale, alpha)
	SetDrawOrigin(coords.x, coords.y, coords.z, 0)
	for i, text in ipairs(texts) do
		SetTextFont(0)
		SetTextProportional(0)
		SetTextScale(0.35 * scale, 0.35 * scale) -- Adjusted scale to make text smaller
		SetTextColour(text.color[1], text.color[2], text.color[3], alpha)
		SetTextDropShadow(0, 0, 0, 0, alpha)
		SetTextEdge(2, 0, 0, 0, 150)
		SetTextCentre(true) -- Center the text
		SetTextEntry("STRING")
		AddTextComponentString(text.text)
		DrawText(0.0, 0.0)
	end
	ClearDrawOrigin()
end

-- Constants
STREAM_DISTANCE = 20.0

-- Example function to initialize player names
function initializePlayerNames()
	TriggerServerEvent("requestPlayerNames")
end
