local LDM = LibDynamicMail

LDM.Inbox = {}
local Inbox = LDM.Inbox
Inbox.Callbacks = {}

local MailInbox = MAIL_INBOX
local event_manager = EVENT_MANAGER

if IsConsoleUI() or IsInGamepadPreferredMode() then
 MailInbox = ZO_MailInbox_Gamepad
end

local function selectRelevantMail(event, mailId, templateName, functionName)
  local senderDisplayName, senderCharacterName, subject, firstItemIcon, unread, fromSystem, fromCS, returned, numAttachments, attachedMoney, codAmount, expiresInDays, secsSinceReceived, category = GetMailItemInfo(mailId)
  local callback = Inbox.Callbacks[templateName]
        and Inbox.Callbacks[templateName][functionName]
  if not callback then return false end
  event_manager:UnregisterForEvent(templateName.."mailboxreadable", EVENT_MAIL_READABLE)
  Inbox.Callbacks[templateName][functionName](event, mailId)
end

function Inbox:RegisterCallback(templateName, functionName, functionCallback)
  self.Callbacks = self.Callbacks or {}
  self.Callbacks[templateName] = self.Callbacks[templateName] or {}
  self.Callbacks[templateName][functionName] = functionCallback
end

function Inbox:RegisterEvents(templateName, functionName)
  event_manager:RegisterForEvent(templateName.."mailboxreadable", EVENT_MAIL_READABLE, function(event, mailId)
    selectRelevantMail(event, mailId, templateName, functionName)
   end)
end

function Inbox:RetrieveActiveMailData(mailId)
  RequestReadMail(mailId)
  return MailInbox:GetActiveMailData()
end

function Inbox:CheckMailForTemplateFieldValue(mailId, templateName, fieldKey, operator)
  RequestReadMail(mailId)
  local mailData = MailInbox:GetActiveMailData()
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

function Inbox:CheckMailForTemplateSubject(mailId, templateName, operator)
  self:CheckMailForTemplateFieldValue(templateName, "subject", operator)
end

function Inbox:CheckMailForTemplateKeyword(mailId, templateName, operator)
  self:CheckMailForTemplateFieldValue(mailId, templateName, "body", operator)
end

function Inbox:CheckMailForTemplateSender(mailId, templateName, operator)
  self:CheckMailForTemplateFieldValue(templateName, "recipient", operator)
end
