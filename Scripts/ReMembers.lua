local reMembers = {}
local debug = false
local configSectionName = "ReMembers.List"

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
		Invite()
	end
end

function GetMemberByName(name, raidMembers)
	for groupKey,_ in pairs(raidMembers) do
		for memberKey, member in pairs(raidMembers[groupKey]) do
			local IsEqualNames = userMods.FromWString(member.name) == userMods.FromWString(name)
			if IsEqualNames then
				member.Pos = {groupNumber = groupKey, positionNumber = memberKey}
				return member
			end
		end
	end
	return nil
end

function RaidSwap()
	if debug then ChatLog("---------------------------------") end
	if reMembers.List == nil or #reMembers.List == 0 then return end
	for key, member in pairs(reMembers.List) do
		if not member.IsSwapped == true then
			local raidMembers = raid.GetMembers()
			local _member = GetMemberByName(member.name, raidMembers)
			if debug then ChatLog("Processing " .. userMods.FromWString(member.name)) end
			if _member ~= nil then
				local shouldSwap = _member.Pos.groupNumber ~= member.Pos.groupNumber or _member.Pos.positionNumber ~= member.Pos.positionNumber
				if debug then ChatLog("Should swap: " .. tostring(shouldSwap)) end
				if shouldSwap then

					local raidLenght = Lenght(raidMembers) - 1
					if debug then ChatLog("Raid length: " .. tostring(raidLenght) .. ". Member group number: " .. tostring(member.Pos.groupNumber)) end
					if debug then ChatLog("Remembered pos: " .. tostring(member.Pos.groupNumber) .. ":" .. tostring(member.Pos.positionNumber)) end
					if not reMembers.IsEventRaidChangedProcessed then
						reMembers.IsEventRaidChangedProcessed = true
						common.RegisterEventHandler(OnRaidChanged, "EVENT_RAID_CHANGED")
					end
					local shouldCreateNewGroup = raidLenght < member.Pos.groupNumber
					if debug then ChatLog("Should create new group: " .. tostring(shouldCreateNewGroup)) end
					if shouldCreateNewGroup then
						if debug then ChatLog("Isolate " .. userMods.FromWString(member.name)) end
						raid.IsolateMember(_member.uniqueId) return end
					local toSwap = raidMembers[member.Pos.groupNumber][member.Pos.positionNumber]
					if toSwap ~= nil then
						if debug then ChatLog("Swap " .. userMods.FromWString(member.name) .. " and " .. userMods.FromWString(toSwap.name)) end
						reMembers.List[key].IsSwapped = true
						raid.SwapMembers(toSwap.uniqueId, _member.uniqueId) return
					else
						if debug then ChatLog("Move " .. userMods.FromWString(member.name) .. " to groupNumber " .. tostring(member.Pos.groupNumber)) end
						raid.MoveMemberToGroup(_member.uniqueId, member.Pos.groupNumber) return end
				end
				if debug then ChatLog("---") end
			end
		end
	end
	for key,_ in pairs(reMembers.List) do reMembers.List[key].IsSwapped = false end
	reMembers.IsEventRaidChangedProcessed = nil
end

function Lenght(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

function OnRaidChanged()
	if not reMembers.IsEventRaidChangedProcessed then common.UnRegisterEventHandler(OnRaidChanged, "EVENT_RAID_CHANGED") return end
	if debug then ChatLog("EVENT_RAID_CHANGED received") end
	RaidSwap()
end

function Invite()
	if reMembers.List == nil or #reMembers.List == 0 then return end
	if reMembers.IsRaid then
		if raid.IsExist() then
			for _, member in pairs(reMembers.List) do raid.InviteByName(member.name) end
		return end
		if group.IsLeader() then CreateRaid() return end
		if group.GetLeaderIndex() >= 0 then ChatLog("You are not leader of this group!") return end
		common.RegisterEventHandler(OnGroupAppeared, "EVENT_GROUP_APPEARED")
	end
	for _, member in pairs(reMembers.List) do group.InviteByName(member.name) end
end

function OnGroupAppeared()
    common.UnRegisterEventHandler(OnGroupAppeared, "EVENT_GROUP_APPEARED")
	CreateRaid()
end

function OnRaidAppeared()
	common.UnRegisterEventHandler(OnRaidAppeared, "EVENT_RAID_APPEARED")
	Invite()
end

function CreateRaid()
	if #reMembers.List > 12 then raid.Create()
	else raid.CreateSmall() end
	SetLootMaster()
	common.RegisterEventHandler(OnRaidAppeared, "EVENT_RAID_APPEARED")
end

function CleanTable()
	reMembers.IsRaid = false
	reMembers.List = {}
	userMods.SetGlobalConfigSection(configSectionName, nil)
end

function LogMembers()
	if reMembers.List == nil or #reMembers.List == 0 then
		ChatLog("reMembers list is empty!")
		return
	end
	ChatLog ("IsRaid: " .. tostring(reMembers.IsRaid))
	ChatLog ("Count: " .. tostring(#reMembers.List))
	local enum = ""
	for _, member in pairs(reMembers.List) do
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
		reMembers.IsRaid = true
		local groups = raid.GetMembers()
		for groupKey,_ in pairs(groups) do
			for memberKey, member in pairs(groups[groupKey]) do
				local _member = { name = member.name }
				_member.Pos = { groupNumber = groupKey, positionNumber = memberKey }
				table.insert(reMembers.List, _member)
			end
		end
	else
		local members = group.GetMembers()
		if members == nil then
			ChatLog("You are alone!")
			return
		end
		for memberKey, member in pairs(members) do
			local _member = { name = member.name }
			_member.Pos = { groupNumber = 0, positionNumber = memberKey }
			table.insert(reMembers.List, _member)
		end
	end

	userMods.SetGlobalConfigSection(configSectionName, reMembers)
	LogMembers()
end

function SetLootMaster()
	if loot.CanSetLootScheme() then
		loot.SetLootScheme(LOOT_SCHEME_TYPE_MASTER)
		common.RegisterEventHandler(SetItemQuality, "EVENT_SECOND_TIMER")
	end
end

function SetItemQuality()
	common.UnRegisterEventHandler(SetItemQuality, "EVENT_SECOND_TIMER")
	loot.SetMinItemQualityForLootScheme(ITEM_QUALITY_UNCOMMON)
end

function Init()
    common.UnRegisterEventHandler(Init, "EVENT_AVATAR_CREATED")
    common.RegisterEventHandler(SetLootMaster, "EVENT_GROUP_APPEARED")
    common.RegisterEventHandler(SetLootMaster, "EVENT_GROUP_LEADER_CHANGED")
    common.RegisterEventHandler(SetLootMaster, "EVENT_RAID_LEADER_CHANGED")
	common.RegisterReactionHandler(OnLeftClickButtonPressed, "ReactionLeftClickButtonPressed")
	common.RegisterReactionHandler(OnRightClickButtonPressed, "ReactionRightClickButtonPressed")

	SetLootMaster();

	local _reMembers = userMods.GetGlobalConfigSection(configSectionName)
	if _reMembers ~= nil then reMembers = _reMembers end

	local button = mainForm:GetChildChecked("Button", false)

	DnD.Init (button, button, true, true, nil, KBF_SHIFT)
end

common.RegisterEventHandler(Init, "EVENT_AVATAR_CREATED")
if avatar.IsExist() then Init() end