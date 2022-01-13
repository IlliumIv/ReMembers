Global('Members', {})

function OnLeftClickButtonPressed(params)
	if DnD.IsDragging() then
		-- ChatLog("Dragging...")
		return
	end
	-- ChatLog("LeftClickPressed!")

	if common.GetBitAnd(params.kbFlags, KBF_ALT) ~=0 then
		if raid.IsExist() then
			repeat
				local result = RaidSwap()
			until result
			ChatLog("Swap is end!")
		end
	else
		LogMembers()
		Invite(false)
	end
end


function RaidSwap()
	ChatLog("Called RaidSwap")
	for groupKey,_ in pairs(Members) do
		if type(Members[groupKey]) == "table" then
			for memberKey,_ in pairs(Members[groupKey]) do

				ChatLog("Processing " .. userMods.FromWString(Members[groupKey][memberKey].name))
				ChatLog("Remembered pos: " .. tostring(groupKey) .. ":" .. tostring(memberKey))

				local groups = raid.GetMembers()
				local currentMemberPos = GetMemberCurrentPosByName(Members[groupKey][memberKey].name, groups)

				ChatLog("Current pos: " .. tostring(currentMemberPos.groupNumber) .. ":" .. tostring(currentMemberPos.positionNumber))

				if {currentMemberPos.groupNumber, currentMemberPos.positionNumber} ~= {groupKey, memberKey} then
					ChatLog("Should swap!")
					local currentMemberId = groups[currentMemberPos.groupNumber][currentMemberPos.positionNumber].uniqueId
					local memberToMoveId = groups[groupKey][memberKey].uniqueId
					raid.SwapMembers(currentMemberId, memberToMoveId)
					return false
				end
			end
		end
	end

	return true
end


function GetMemberCurrentPosByName(name, groups)
	for groupKey,_ in pairs(groups) do
		if type(groups[groupKey]) == "table" then
			for memberKey,_ in pairs(groups[groupKey]) do
				local IsEqualNames = userMods.FromWString(groups[groupKey][memberKey].name) == userMods.FromWString(name)
				if IsEqualNames then
					local pos = { groupNumber = groupKey, positionNumber = memberKey }
					return pos
				end
			end
		end
	end

	return nil
end

function Invite(shouldInviteToRaid)
	if Members[0] == nil then return false end
	if not Members.IsEventProcessed then common.RegisterEventHandler(OnGroupAppeared, "EVENT_GROUP_APPEARED") end
	Members.IsEventProcessed = true
	-- ChatLog("Should Invite To Raid: " .. tostring(shouldInviteToRaid))
	for groupKey,_ in pairs(Members) do
		if type(Members[groupKey]) == "table" then
			for memberKey,_ in pairs(Members[groupKey]) do
				if avatar.id ~= Members[groupKey][memberKey].id then
					if shouldInviteToRaid then raid.InviteByName(Members[groupKey][memberKey].name)
					else group.InviteByName(Members[groupKey][memberKey].name) end
				end
			end
		end
	end

	Members.InviteDateTime = common.GetLocalDateTime().overallMs
	return true
end

function OnGroupAppeared()
    common.UnRegisterEventHandler(OnGroupAppeared, "EVENT_GROUP_APPEARED")
	Members.IsEventProcessed = false
	if common.GetLocalDateTime().overallMs - Members.InviteDateTime > 30000 then return end
	if Members.IsRaid then
		if Members.Count > 12 then raid.Create()
		else raid.CreateSmall() end
		Invite(true)
	end
end

function CleanTable()
	Members.IsRaid = false
	Members.Count = 0
	local count = #Members
	for i = 0, count do Members[i] = nil end
end

function LogMembers()
	if Members[0] == nil then
		ChatLog("Members list is empty!")
		return
	end
	ChatLog ("IsRaid: " .. tostring(Members.IsRaid))
	ChatLog ("Count: " .. tostring(Members.Count))
	for groupKey,_ in pairs(Members) do
		if type(Members[groupKey]) == "table" then
			for memberKey,_ in pairs(Members[groupKey]) do
				ChatLog(userMods.FromWString(Members[groupKey][memberKey].name))
			end
		end
	end
end

function Length(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

function OnRightClickButtonPressed()
	if DnD.IsDragging() then
		-- ChatLog("Dragging...")
		return
	end
	-- ChatLog("RightClickPressed!")

	CleanTable()

	local member_count = 0
	if raid.IsExist() then
		Members.IsRaid = true
		local groups = raid.GetMembers()
		for groupKey,_ in pairs(groups) do
			member_count = member_count + Length(groups[groupKey])
			Members[groupKey] = groups[groupKey]
		end
	else
		local members = group.GetMembers()
		if members == nil then
			ChatLog("You are alone!")
			return
		end
		member_count = member_count + Length(members)
		Members[0] = members
	end

	Members.Count = member_count
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
if avatar.IsExist() then
    Init()
end

