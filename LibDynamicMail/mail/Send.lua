local LDM = LibDynamicMail
local LTF = LibTextFormat

local mailSend = MAIL_SEND

if IsInGamepadPreferredMode() or IsConsoleUI() then
  mailSend = MAIL_GAMEPAD:GetSend()
end

local function NormalizeAccountName(name)
    if not IsDecoratedDisplayName(name) then
        return DecorateDisplayName(name)
    end
    return name
end

function LDM:PopulateCompose(templateName, values)
  local template = self:GetTemplate(templateName)
  if not template then d("|cFF0000[LDM]|r LibDynamicMail: Template not found") return false end

  local parsedSubject = template.subject
  local parsedRecipient = template.recipient
  local parsedBody = template.body

  if self.formatter and values then
    local scope = self.formatter.Scope(values)
    if values.recipient then
      parsedRecipient = self.formatter:format(template.recipient, scope)
    end
    if values.subject then
      parsedSubject = self.formatter:format(template.subject, scope)
    end
    if values.body then
      parsedBody = self.formatter:format(template.body, scope)
    end
  end

  local decoratedRecipient = NormalizeAccountName(parsedRecipient)

  if IsInGamepadPreferredMode() or IsConsoleUI() then
    mailSend:InsertBodyText(parsedBody)
    mailSend.initialContact = parsedRecipient
    mailSend.initialSubject = parsedSubject
    MAIN_MENU_GAMEPAD:ShowScene("mailGamepad")
    ZO_GamepadGenericHeader_SetActiveTabIndex(MAIN_MENU_GAMEPAD.header, 2)
  else
    mailSend.to:SetText(decoratedRecipient)
    mailSend.subject:SetText(parsedSubject)
    mailSend.body:SetText(parsedBody)
    MAIN_MENU_KEYBOARD:ShowScene("mailSend")
  end

end
