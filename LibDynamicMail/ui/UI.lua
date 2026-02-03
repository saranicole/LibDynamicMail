LibDynamicMail = LibDynamicMail or {}
local LDM = LibDynamicMail

LDM.UI = {}
local UI = LDM.UI

local MailView = MAIL_SEND

if IsConsoleUI() or IsInGamepadPreferredMode() then
 MailView = MAIL_GAMEPAD
end

local UI_Shared = ZO_Object.MultiSubclass(ZO_GamepadVerticalParametricScrollList, ZO_SocialOptionsDialogGamepad)
LDM.UI.shared = UI_Shared
local UI_TemplateList = UI_Shared:Subclass()
UI.templateList = UI_TemplateList

function UI_Shared:New(...)
	return ZO_GamepadVerticalParametricScrollList.New(self, ...)
end

function UI_Shared:OnSelectedDataChangedCallback(categoryData, oldData)
	CALLBACK_MANAGER:FireCallbacks('LDM_GAMEPAD_CATEGORY_CHANGED', categoryData)
-- 	self:UpdateTooltip(categoryData)
end

function UI_Shared:BuildDropdownEntry(header, label, setupFunction, callback, finishedCallback, icon)
	local entry = {
		header = header or self.currentGroupingHeader,
		template = "ZO_GamepadDropdownItem",

		templateData =
		{
			text = GetStringFromData(label),
			setup = setupFunction,
			callback = callback,
			finishedCallback = finishedCallback,
			narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
		},
		icon = icon,
	}

	return entry
end

function UI_Shared:BuildDropdown(header, label, dropdownData, icon)

	local function onSelectedCallback(dropdown, entryText, entry)
		dropdownData.selectedIndex = entry.index

		if dropdownData.callback then
			dropdownData.callback(entry)
		end
	end

	local function callback(dialog)
		local targetData = dialog.entryList:GetTargetData()
		local targetControl = dialog.entryList:GetTargetControl()
		targetControl.dropdown:Activate()
	end

	local function dropdownEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, active)
		local dialogData = data and data.dialog and data.dialog.data

		local dropdowns = data.dialog.dropdowns
		if not dropdowns then
			dropdowns = {}
			data.dialog.dropdowns = dropdowns
		end
		local dropdown = control.dropdown
		table.insert(dropdowns, dropdown)

		dropdown:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
		dropdown:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
		dropdown:SetSelectedItemTextColor(selected)

		SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(data.dialog, dropdown)

		dropdown:SetSortsItems(false)
		dropdown:ClearItems()

		for i = 1, #dropdownData do
			local entryText = dropdownData[i].filterName
			local newEntry = dropdown:CreateItemEntry(entryText, onSelectedCallback)
			newEntry.index = i
			zo_mixin(newEntry, dropdownData[i])
			dropdown:AddItem(newEntry)
		end

		dropdown:UpdateItems()

		local initialIndex = dropdownData.selectedIndex or 1
		dropdown:SelectItemByIndex(initialIndex)
	end

	return self:BuildDropdownEntry(header, label, dropdownEntrySetup, callback, icon)
end

function UI_Shared:BuildTemplatesList()

	local function conditionFunction()
	  return true
-- 		local categoryData = self:GetTargetData()
-- 		if not categoryData then return false end
-- 		return categoryData.categoryType == CATEGORY_TYPE_ALL
	end

	if self.dropdownDataMain == nil then
		local dropdownData = {}
		for key, entry in pairs(LDM.Templates) do
      for templateName, templateObj in pairs(entry) do
        table.insert(dropdownData, {
          filterName = key,
          filterIndex = 1,
        })
      end
		end
		self.dropdownDataMain = dropdownData
		self.dropdownDataMain.selectedIndex = 1
		local groupId = self:AddOptionTemplateGroup(function() return key end)
	  self:AddOptionTemplate(groupId, function() return self:BuildDropdown("Test Dropdown", "Test Label", self.dropdownDataMain, "/esoui/art/mail/mail_tabicon_inbox_up.dds") end, conditionFunction)
	end
end

function UI_Shared:ResetFilters()
  self.dropdownDataMain.selectedIndex = 1
  self:Refresh()
end

function UI_Shared:Initialize()
	local listControl = self.control:GetNamedChild('Main'):GetNamedChild('List')

	-- Initialize self as the list.
	ZO_GamepadVerticalParametricScrollList.Initialize(self, listControl)
	ZO_SocialOptionsDialogGamepad.Initialize(self)

	-- Initialize the right side tooltip.
-- 	self.scrollTooltip = self.control:GetNamedChild("SideContent"):GetNamedChild("Tooltip")

	--ZO_Scroll_Gamepad_SetScrollIndicatorSide(self.scrollTooltip.scrollIndicator, ZO_SharedGamepadNavQuadrant_4_Background, LEFT)

	UI_TemplateList:InitializeKeybindDescriptor()

  if next(LDM.Templates) == nil then
	  self.noItemsLabel:SetText(LDM.Lang.NO_MATCHES)
	end

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

-- 	self:BuildTemplatesList()

-- 	local narrationInfo =
-- 	{
-- 		canNarrate = function()
-- 			return self.fragment:IsShowing()
-- 		end,
-- 		headerNarrationFunction = function()
-- 			return MailView:GetHeaderNarration()
-- 		end,
-- 	}
-- 	SCREEN_NARRATION_MANAGER:RegisterParametricList(self, narrationInfo)
end

function UI_TemplateList:GetHeaderData()
	local mailView = MailView

	return {
		tabBarEntries = self.tabBarEntries,

		data1HeaderText = function() return LDM.Lang.MAIL_PRESETS end,
		data1Text = function() return LDM.Lang.TEMPLATE_DESC end,
	}
end

function UI_TemplateList:InitializeCustomTabs()
	local mailView = MailView
	local tabBarEntries = mailView.tabBarEntries
	self.origTabBarEntries = self.origTabBarEntries or mailView.tabBarEntries
	self.orginalHeaderData = self.orginalHeaderData or MailView.baseHeaderData

  if self.origTabBarEntries == mailView.tabBarEntries then
    local newtab = {
      text = LDM.Lang.MAIL_PRESETS,
      callback = function() MailView:SwitchToFragment(self.fragment) end,
    }

    table.insert(tabBarEntries, 1, newtab)

    self.tabBarEntries = tabBarEntries
    mailView.tabBarEntries = tabBarEntries
	end
  ZO_GamepadGenericHeader_Refresh(mailView.header, self:GetHeaderData())
  ZO_GamepadGenericHeader_SetActiveTabIndex(mailView.header, 1)
	self.tabAdded = true
end

function UI_TemplateList:InitializeKeybindDescriptor()

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
				UI_Shared:ResetFilters()
			end,
			enabled = function() return true end,
			visible = function() return true end,
		},
	}

	ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() ZO_MailInteractionFragment:Show() end)
	ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self)
end

function UI_Shared:RefreshNoEntriesLabel()
	self.noItemsLabel:SetHidden(not self:IsEmpty())
end

function UI_Shared:RefreshKeybind()
	if self.fragment:IsHidden() then return end
	KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

local function isVisible(visible)
	if type(visible) == 'function' then
		visible = visible()
	end
	return visible
end

function UI_Shared:Refresh()
	self:Clear()
	local templates = self.templates or {}
	local lastFilterType
	local controlIndex = 1
	for i, data in ipairs(templates) do
-- 		if isVisible(data.visible) then
			local entryData = ZO_GamepadEntryData:New(data.addon, data.icon)

			entryData:SetDataSource(data)
			zo_mixin(entryData, data)

			entryData.controlIndex = controlIndex
			entryData:AddSubLabel(data.subject)

			entryData:SetHeader(data.addon.." - "..data.name)
      self:AddEntryWithHeader("ZO_GamepadMenuEntryTemplateLowercase42", entryData)
      self:AddEntry("ZO_GamepadMenuEntryTemplateLowercase42", entryData)
			controlIndex = controlIndex + 1
-- 		end
	end

	self:Commit()
	self:RefreshNoEntriesLabel()

	self:SetupOptions(self:GetTargetData())
	self:RefreshKeybind()
end

function UI_TemplateList:BuildTemplates()
  local templateObjects = {}
  for key, entry in pairs(LDM.Templates) do
    for templateName, templateObj in pairs(entry) do
      table.insert(templateObjects, {
        filterType = 0,
        addon = key,
        name = templateName,
        subject = entry.subject,
        recipient = entry.recipient,
        icon = "/esoui/art/mail/mail_tabicon_inbox_up.dds",

        enabled = true,
        visible = function() return true end,


        filter = {
          index = 0,
        },
        callback = function(currentFilter)

        end,
      })
    end
  end
  self.templates = templateObjects
end

function UI_Shared:RefreshHeader()
	local mailView = MailView
	if self.fragment:IsHidden() then
		ZO_GamepadGenericHeader_Refresh(mailView.header, mailView.baseHeaderData)
	else
		ZO_GamepadGenericHeader_Refresh(mailView.header, self:GetHeaderData())
	end
end

function UI_Shared:OnShown()
  UI_TemplateList.control:SetHidden(false)
	self:RefreshHeader()
end

function UI_Shared:OnHidden()
  UI_TemplateList.control:control(true)
	self:RefreshHeader()
end

function UI_TemplateList:OnOpenMailbox()
  EVENT_MANAGER:UnregisterForEvent("LDMmailboxInit", EVENT_MAIL_OPEN_MAILBOX)
  local parent = ZO_Mail_Gamepad_TopLevel

  UI_Shared.control = CreateControlFromVirtual(
      "LDM_List_Template",
      parent,
      "LDM_List_Template"
  )
  UI_Shared:Initialize()
  self:BuildTemplates()
	self:InitializeCustomTabs()
	self:InitializeKeybindDescriptor()
	UI_Shared:Refresh()
	local oldself = self

	UI_Shared.fragment:RegisterCallback("StateChange",  function(oldState, newState)
		if newState == SCENE_SHOWING then
			oldself:Activate()
			KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

			UI_Shared:Refresh()

		elseif newState == SCENE_SHOWN then
-- 			self:UpdateTooltip(self:GetTargetData())
			self:OnShown()
		elseif newState == SCENE_HIDDEN then
			KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)

			self:Deactivate()
			UI_Shared:RefreshHeader()
		end
	end)
end

function UI_TemplateList:Build(control)
	self.container = control
  EVENT_MANAGER:RegisterForEvent("LDMmailboxInit", EVENT_MAIL_OPEN_MAILBOX , function() self:OnOpenMailbox() end)
end

function LDM.changeState(index)
  LDM.state = index
end

function UI_Shared:onCategoryChanged(categoryData, selectedIndex)
  if not categoryData then return end

  if categoryData.callback then
    local filter = categoryData.filter or {}
    self.selectedIndex = selectedIndex

    LDM.changeState(filter.index)
    categoryData.callback(filter)

--     self.fragment:UpdateTooltip(self:GetTargetData())
  end
end

CALLBACK_MANAGER:RegisterCallback('LMD_GAMEPAD_CATEGORY_CHANGED', function()
  UI_Shared:onCategoryChanged(categoryData, selectedIndex)
end)
