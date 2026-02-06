local LDM = LibDynamicMail

local MailInbox = MAIL_INBOX
local event_manager = EVENT_MANAGER

if IsConsoleUI() or IsInGamepadPreferredMode() then
 MailInbox = MAIL_GAMEPAD:GetInbox()
end

function LDM:selectRelevantMail(event, mailId, templateName, functionName)
  self.savedVars.InboxCallbacks = self.savedVars.InboxCallbacks or {}
  local senderDisplayName, senderCharacterName, subject, firstItemIcon, unread, fromSystem, fromCS, returned, numAttachments, attachedMoney, codAmount, expiresInDays, secsSinceReceived, category = GetMailItemInfo(mailId)
  local callback = self.savedVars.InboxCallbacks[templateName]
        and self.savedVars.InboxCallbacks[templateName][functionName]
  if not callback then return false end
  event_manager:UnregisterForEvent(templateName.."mailboxreadable", EVENT_MAIL_READABLE)
  self.savedVars.InboxCallbacks[templateName][functionName](event, mailId)
end

function LDM:RegisterInboxCallback(templateName, functionName, functionCallback)
  self.savedVars.InboxCallbacks = self.savedVars.InboxCallbacks or {}
  self.savedVars.InboxCallbacks[templateName] = self.savedVars.InboxCallbacks[templateName] or {}
  self.savedVars.InboxCallbacks[templateName][functionName] = functionCallback
end

function LDM:RegisterInboxEvents(templateName, functionName)
  event_manager:RegisterForEvent(templateName.."mailboxreadable", EVENT_MAIL_READABLE, function(event, mailId)
    self:selectRelevantMail(event, mailId, templateName, functionName)
   end)
end

function LDM:SafeDeleteMail(mailId, forceBool)
  local requestResult = RequestReadMail(mailId)
  if requestResult ~= nil and requestResult <= REQUEST_READ_MAIL_RESULT_SUCCESS_SERVER_REQUESTED then
    DeleteMail(mailId, forceBool)
  else
    zo_callLater(function()
        self:SafeDeleteMail(mailId, forceBool)

    end, math.max(GetLatency()+10, 100))
  end
end

local function getBody()
  if IsConsoleUI() or IsInGamepadPreferredMode() then
    local control = MailInbox.control:GetNamedChild("Inbox"):GetNamedChild("RightPane"):GetNamedChild("Container"):GetNamedChild("Inbox")
   return ZO_MailView_GetBody_Gamepad(control)
  else
    return MailInbox.body:GetText()
  end
end

function LDM:RetrieveActiveMailData(mailId)
  RequestReadMail(mailId)
  local mailData = MailInbox:GetActiveMailData()
  mailData.body = getBody()
  return mailData
end

function LDM:CheckMailForTemplateFieldValue(mailId, templateName, fieldKey, operator)
  RequestReadMail(mailId)
  local mailData = MailInbox:GetActiveMailData()
  mailData.body = getBody()
  local template = self:GetTemplate(templateName)
  if not template then d("|cFF0000[LDM]|r LibDynamicMail: Template not found") return false end
  if not operator or operator == "equals" then
    if template[fieldKey] == mailData[fieldKey] then
      return true
    end
  end
  if operator == "contains" then
    if template[fieldKey]:find(mailData[fieldKey], 1, true) ~= nil then
      return true
    end
  end
  return false
end

function LDM:CheckMailForTemplateSubject(mailId, templateName, operator)
  return self:CheckMailForTemplateFieldValue(mailId, templateName, "subject", operator)
end

function LDM:CheckMailForTemplateKeyword(mailId, templateName, operator)
  return self:CheckMailForTemplateFieldValue(mailId, templateName, "body", operator)
end

function LDM:CheckMailForTemplateSender(mailId, templateName, operator)
  return self:CheckMailForTemplateFieldValue(mailId, templateName, "senderDisplayName", operator)
end
