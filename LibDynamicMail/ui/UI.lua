LibDynamicMail = LibDynamicMail or {}
local LDM = LibDynamicMail

LDM.UI = {}
local UI = LDM.UI

local MailView = MAIL_SEND

if IsConsoleUI() or IsInGamepadPreferredMode() then
 MailView = MAIL_GAMEPAD
end

function UI:Initialize(control)
	local listControl = control:GetNamedChild('Main'):GetNamedChild('List')

	-- Initialize self as the list.
	ZO_GamepadVerticalParametricScrollList.Initialize(self, listControl)
	ZO_SocialOptionsDialogGamepad.Initialize(self)

	-- Initialize the right side tooltip.
	self.scrollTooltip = control:GetNamedChild("SideContent"):GetNamedChild("Tooltip")

	ZO_Scroll_Gamepad_SetScrollIndicatorSide(self.scrollTooltip.scrollIndicator, ZO_SharedGamepadNavQuadrant_4_Background, LEFT)

	self:InitializeKeybindDescriptor()

	self.noItemsLabel:SetText(LDM.Lang.NO_MATCHES)

	self:SetOnSelectedDataChangedCallback(function(_, selectedData, oldData, reselectingDuringRebuild, listIndex)
		self:OnSelectedDataChangedCallback(selectedData, oldData, reselectingDuringRebuild, listIndex)
	end)

--	self.targetSelectedIndex = 1
	self:SetOnTargetDataChangedCallback(function(_, newTargetData, oldTargetData)
		if ZO_IsTableEmpty(newTargetData) then
			self:SetupOptions(nil)
		else
			self:SetupOptions(newTargetData)
		end
	end)

--	self.fragment = ZO_SimpleSceneFragment:New(control)
	self.fragment = ZO_Object.MultiSubclass(ZO_SimpleSceneFragment:New(control), self)

    local function equalityFunction(left, right)
        return left.text == right.text
    end

	local function setupFunction(control, data, selected, reselectingDuringRebuild, enabled, active)
		ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
		control.m_data = data
	end

	self:AddDataTemplate("ZO_GamepadMenuEntryTemplateLowercase42", setupFunction, ZO_GamepadMenuEntryTemplateParametricListFunction, equalityFunction)
	self:AddDataTemplateWithHeader("ZO_GamepadMenuEntryTemplateLowercase42", setupFunction, ZO_GamepadMenuEntryTemplateParametricListFunction, equalityFunction, "ZO_GamepadMenuEntryHeaderTemplate")

--	self:BuildOptionsList()

	local narrationInfo =
	{
		canNarrate = function()
			return self.fragment:IsShowing()
		end,
		headerNarrationFunction = function()
			return MailView:GetHeaderNarration()
		end,
	}
	SCREEN_NARRATION_MANAGER:RegisterParametricList(self, narrationInfo)
end

function UI:GetHeaderData()
	local mailView = MailView

	return {
		tabBarEntries = self.tabBarEntries,

		data1HeaderText = function() return LDM.Lang.MAIL_PRESETS end,
		data1Text = function() return LDM.Lang.TEMPLATE_DESC end,
	}
end

function UI:InitializeCustomTabs()
	local mailView = MailView
	local tabBarEntries = mailView.tabBarEntries
	self.orginalHeaderData = MailView.baseHeaderData

	local newtab = {
		text = LDM.Lang.MAIL_PRESETS,
		callback = function() self.owner:SwitchToFragment(self.fragment) end,
	}

	table.insert(tabBarEntries, 1, newtab)

	self.tabBarEntries = tabBarEntries
	mapInfo.tabBarEntries = tabBarEntries

	ZO_GamepadGenericHeader_Refresh(mailView.header, self:GetHeaderData())
	ZO_GamepadGenericHeader_SetActiveTabIndex(mailView.header, 1)
end

function UI:InitializeKeybindDescriptor()

	self.keybindStripDescriptor = {
		alignment = KEYBIND_STRIP_ALIGN_LEFT,
		{ -- select item
			name = GetString(SI_GAMEPAD_SELECT_OPTION),
			keybind = "UI_SHORTCUT_PRIMARY",
			callback = function()
				local targetData = self:GetTargetData()

				if targetData then
					self.owner.teleportList:SwitchToFragment()
				end
			end,
			visible = function() return true end,
		},
		{ -- select refresh
			name = GetString(SI_OPTIONS_RESET),
			keybind = "UI_SHORTCUT_SECONDARY",
			callback = function()

				g_selectedIndex = 1
				self:ResetFilters()
			end,
			enabled = function() return true end,
			visible = function() return true end,
		},
	}

	ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() ZO_MailInteractionFragment:Show() end)
	ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self)
end

function UI:Refresh()
	self:Clear()
	local templates = self.templates or {}
	local lastFilterType
	local controlIndex = 1

	for i, data in ipairs(templates) do
		if isVisible(data.visible) then
			local entryData = ZO_GamepadEntryData:New(data.name, data.icon)

			entryData:SetDataSource(data)
			zo_mixin(entryData, data)

			entryData.controlIndex = controlIndex
			entryData:AddSubLabel(data.foundInZoneName)

			if lastFilterType ~= data.filterType then
				lastFilterType = data.filterType
				entryData:SetHeader(getHeaderString('CATEGORY', data.filterType))
				self:AddEntryWithHeader("ZO_GamepadMenuEntryTemplateLowercase42", entryData)
			else
				self:AddEntry("ZO_GamepadMenuEntryTemplateLowercase42", entryData)
			end
			controlIndex = controlIndex + 1
		end
	end

	self:Commit()
	self:RefreshNoEntriesLabel()

	self:SetupOptions(self:GetTargetData())
	self:RefreshKeybind()
end

function UI:Build(parent)
  local control = CreateControlFromVirtual(owner.name .. name, parentControl:GetNamedChild('Main'), "LDM_List_Template")
	self:Initialize(control)

	self.container = control

	self:BuildTemplates()
	self:InitializeCustomTabs()
	self:InitializeKeybindDescriptor()
	self:Refresh()

	self.fragment:RegisterCallback("StateChange",  function(oldState, newState)
		if newState == SCENE_SHOWING then
			self:Activate()
			KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

			self:Refresh()

		elseif newState == SCENE_SHOWN then
			self:UpdateTooltip(self:GetTargetData())
			self:OnShown()
		elseif newState == SCENE_HIDDEN then
			KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)

			self:Deactivate()
			self:RefreshHeader()
		end
	end)
end