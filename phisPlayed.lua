local addonName, phis = ...

local phisFrame = CreateFrame('Frame', addonName..'CheckFrame', UIParent)


-------------------------
--   AUXILLIARY FUNCTIONS   --
-------------------------

-- prints with the addon name as prefix
function phis.print(str)
	print('|cFFDED868'..GetAddOnMetadata(addonName,'Title')..' v'..GetAddOnMetadata(addonName,'Version')..':|r '..str)
end

-- converts seconds to days, hours, minutes, seconds
function phis.secondsToDays(s)
	local days = floor(s/86400)
	local hours = floor(mod(s, 86400)/3600)
	local minutes = floor(mod(s,3600)/60)
	local seconds = floor(mod(s,60))
	return format("%d days, %d hours, %d minutes, %d seconds", days, hours, minutes, seconds)
end

-- converts seconds to approx hours
function phis.secondsToHours(s)
	local hours = floor(s / 3600 + 0.5)
	return format("%d hours", hours)
end

-- unregister TIME_PLAYED_MSG from default chatframe so it does not print the playtime message in Chat
function phis.getTimePlayed()
    DEFAULT_CHAT_FRAME:UnregisterEvent("TIME_PLAYED_MSG")
    RequestTimePlayed()
    C_Timer.After(3, function()
        DEFAULT_CHAT_FRAME:RegisterEvent("TIME_PLAYED_MSG")
    end)
end

-------------------------
--   ADDON FUNCTIONS   --
-------------------------

local function initAddon()
	-- first time loading the addon
	if not phisPlayedSavedVars then
		phis.print('Loaded for the first time.')
		phisPlayedSavedVars = {}
	end
end

-- show total playtime if realmName == nil, else show only playtime for given realm
local function getTotalPlaytime(realmName)
	local playtime = 0
	
	if realmName ~= nil and realmName ~= '' then
		if not phisPlayedSavedVars[realmName] then
			return 0
		end
		for k,v in pairs(phisPlayedSavedVars[realmName]) do
			playtime = playtime + v
		end
	else
		for k,v in pairs(phisPlayedSavedVars) do
			if type(v) == 'table' then
				playtime = playtime + getTotalPlaytime(k)
			else
				playtime = playtime + v
			end
		end
	end
	
	return playtime
end

local function updatePlaytime(player, realm, playtime)
	if player == nil or realm == nil then
		return
	end
	
	if not phisPlayedSavedVars[realm] then
		phisPlayedSavedVars[realm] = {}
	end
	
	phisPlayedSavedVars[realm][player] = playtime
end

-------------------------
--    SLASH COMMANDS   --
-------------------------

SLASH_PPL1 = '/phisplayed'
SLASH_PPL2 = '/ppl'

SlashCmdList['PPL'] = function(msg)
	if not phisPlayedSavedVars then
		initAddon()
	end
	
	if msg:lower() ~= nil and msg:lower() ~= '' then
		phis.print('Total playtime on '..msg..': '..phis.secondsToDays(getTotalPlaytime(msg:lower()))..' ('..phis.secondsToHours(getTotalPlaytime(msg:lower()))..')')
	else
		phis.print('Total playtime: '..phis.secondsToDays(getTotalPlaytime())..' ('..phis.secondsToHours(getTotalPlaytime())..')')
	end	
end

-------------------------
--        EVENTS       --
-------------------------
phisFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
phisFrame:RegisterEvent('PLAYER_LEAVING_WORLD')
phisFrame:RegisterEvent('TIME_PLAYED_MSG')
phisFrame:RegisterEvent('PLAYER_LOGIN')

phisFrame:SetScript('OnEvent', function(self, event, ...)
	if(event == 'PLAYER_LOGIN') then
		initAddon()
		phisFrame:UnregisterEvent('PLAYER_LOGIN')
		return
	end
	
    if(event == 'PLAYER_ENTERING_WORLD' or event == 'PLAYER_LEAVING_WORLD') then
		phis.getTimePlayed()
	end

    if (event == 'TIME_PLAYED_MSG') then
        local playtime = ...
		phis.playerName, phis.realmName = UnitFullName("player")
		phis.realmName = phis.realmName:lower()
		updatePlaytime(phis.playerName, phis.realmName, playtime)
    end
end)