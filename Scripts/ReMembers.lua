Global('Members', {})
local debug = false

function OnLeftClickButtonPressed(params)
	if DnD.IsDragging() then
		if debug then ChatLog("Dragging...") end
		return
	end
	if debug then ChatLog("LeftClickPressed!") end

	if common.GetBitAnd(params.kbFlags, KBF_ALT) ~=0 then
		if raid.IsExist() then RaidSwap() end
	else
		-- LogMembers()
		Invite(false)
	end
end

function GetCurrentPosByName(name, raidMembers)
	for groupKey,_ in pairs(raidMembers) do
		for memberKey,_ in pairs(raidMembers[groupKey]) do
			local IsEqualNames = userMods.FromWString(raidMembers[groupKey][memberKey].name) == userMods.FromWString(name)
			if IsEqualNames then
				return { groupNumber = groupKey, positionNumber = memberKey }
			end
		end
	end
	return nil
end

function RaidSwap()
	if debug then ChatLog("---------------------------------") end
	if Members.List == nil or #Members.List == 0 then return end
	for key, member in pairs(Members.List) do
		if not member.IsSwapped == true then
			local raidMembers = raid.GetMembers()
			local currentPos = GetCurrentPosByName(member.name, raidMembers)
			if debug then ChatLog("Processing " .. userMods.FromWString(member.name)) end
			if currentPos ~= nil then
				local shouldSwap = currentPos.groupNumber ~= member.Pos.groupNumber or currentPos.positionNumber ~= member.Pos.positionNumber
				if debug then ChatLog("Should swap: " .. tostring(shouldSwap)) end
				if shouldSwap then

					local raidLenght = Lenght(raidMembers) - 1
					if debug then ChatLog("Raid length: " .. tostring(raidLenght) .. ". Member group number: " .. tostring(member.Pos.groupNumber)) end
					if debug then ChatLog("Remembered pos: " .. tostring(member.Pos.groupNumber) .. ":" .. tostring(member.Pos.positionNumber)) end
					if not Members.IsEventRaidChangedProcessed then
						Members.IsEventRaidChangedProcessed = true
						common.RegisterEventHandler(OnRaidChanged, "EVENT_RAID_CHANGED")
					end
					local shouldCreateNewGroup = raidLenght < member.Pos.groupNumber
					if debug then ChatLog("Should create new group: " .. tostring(shouldCreateNewGroup)) end
					if shouldCreateNewGroup then
						if debug then ChatLog("Isolate " .. userMods.FromWString(member.name)) end
						raid.IsolateMember(raidMembers[currentPos.groupNumber][currentPos.positionNumber].uniqueId) return end
					local toSwap = raidMembers[member.Pos.groupNumber][member.Pos.positionNumber]
					if toSwap ~= nil then
						if debug then ChatLog("Swap " .. userMods.FromWString(member.name) .. " and " .. userMods.FromWString(toSwap.name)) end
						Members.List[key].IsSwapped = true
						raid.SwapMembers(toSwap.uniqueId, member.uniqueId) return
					else
						if debug then ChatLog("Move " .. userMods.FromWString(member.name) .. " to groupNumber " .. tostring(member.Pos.groupNumber)) end
						raid.MoveMemberToGroup(member.uniqueId, member.Pos.groupNumber) return end
				end
				if debug then ChatLog("---") end
			end
		end
	end
	for key,_ in pairs(Members.List) do Members.List[key].IsSwapped = false end
	Members.IsEventRaidChangedProcessed = nil
end

function Lenght(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

function OnRaidChanged()
	if not Members.IsEventRaidChangedProcessed then common.UnRegisterEventHandler(OnRaidChanged, "EVENT_RAID_CHANGED") return end
	if debug then ChatLog("EVENT_RAID_CHANGED received") end
	RaidSwap()
end

function Invite(shouldInviteToRaid)
	if Members.List == nil or #Members.List == 0 then return end
	if not Members.IsEventGroupAppearedProcessed then common.RegisterEventHandler(OnGroupAppeared, "EVENT_GROUP_APPEARED") end
	Members.IsEventGroupAppearedProcessed = true
	if debug then ChatLog("Should Invite To Raid: " .. tostring(shouldInviteToRaid)) end
	for _, member in pairs(Members.List) do
		if shouldInviteToRaid then raid.InviteByName(member.name)
		else group.InviteByName(member.name) end
	end

	Members.InviteDateTime = common.GetLocalDateTime().overallMs
end

function OnGroupAppeared()
    common.UnRegisterEventHandler(OnGroupAppeared, "EVENT_GROUP_APPEARED")
	Members.IsEventGroupAppearedProcessed = nil
	if common.GetLocalDateTime().overallMs - Members.InviteDateTime > 30000 then return end
	if Members.IsRaid then
		if #Members.List > 12 then raid.Create()
		else raid.CreateSmall() end
		Invite(true)
	end
end

function CleanTable()
	Members.IsRaid = false
	Members.List = {}
end

function LogMembers()
	if Members.List == nil or #Members.List == 0 then
		ChatLog("Members list is empty!")
		return
	end
	ChatLog ("IsRaid: " .. tostring(Members.IsRaid))
	ChatLog ("Count: " .. tostring(#Members.List))
	local enum = ""
	for _, member in pairs(Members.List) do
		enum = enum .. userMods.FromWString(member.name) .. ", "
	end
	ChatLog(string.sub(enum, 0, string.len(enum) - 2) .. ".")
end

function OnRightClickButtonPressed()
	if DnD.IsDragging() then
		if debug then ChatLog("Dragging...") end
		return
	end
	if debug then ChatLog("RightClickPressed!") end

	CleanTable()

	if raid.IsExist() then
		Members.IsRaid = true
		local groups = raid.GetMembers()
		for groupKey,_ in pairs(groups) do
			for memberKey, member in pairs(groups[groupKey]) do
				member.Pos = {groupNumber = groupKey, positionNumber = memberKey}
				table.insert(Members.List, member)
			end
		end
	else
		local members = group.GetMembers()
		if members == nil then
			ChatLog("You are alone!")
			return
		end
		for memberKey, member in pairs(members) do
			member.Pos = {groupNumber = 0, positionNumber = memberKey}
			table.insert(Members.List, member)
		end
	end
	LogMembers()
end

function Init()
    common.UnRegisterEventHandler(Init, "EVENT_AVATAR_CREATED")
	common.RegisterReactionHandler(OnLeftClickButtonPressed, "ReactionLeftClickButtonPressed")
	common.RegisterReactionHandler(OnRightClickButtonPressed, "ReactionRightClickButtonPressed")

	Members.IsRaid = false

	-- local widgetMainPanel = mainForm:GetChildChecked("MainPanel", false)
	local button = mainForm:GetChildChecked("Button", false)

--	DnD.Init (wtMovable, wtReacting, fUseCfg, fLockedToScreenArea, Padding, KbFlag, Cursor)
	-- DnD.Init(widgetMainPanel)
	DnD.Init (button, button, true, true, nil, KBF_SHIFT)
end

common.RegisterEventHandler(Init, "EVENT_AVATAR_CREATED")
if avatar.IsExist() then Init() end