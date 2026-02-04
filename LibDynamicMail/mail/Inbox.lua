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
  Inbox.Callbacks[templateName][functionName]()
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

function Inbox:WatchMailByTemplateFieldValue(templateName, fieldKey, fieldValue, operator)
  local template = LDM.GetTemplate(templateName)
  if not template then d("|cFF0000[LDM]|r LibDynamicMail: Template not found") return false end
  if not operator or operator == "equals" then
    if template[fieldKey] == fieldValue then
      return true
    end
  end
  if operator == "contains" then
    if template[fieldKey]:find(fieldValue, 1, true) ~= nil then
      return true
    end
  end
  return false
end

function Inbox:WatchMailByTemplateSubject(templateName, operator)
  self:WatchMailByTemplateFieldValue(templateName, "subject", fieldValue, operator)
end

function Inbox:WatchMailByTemplateKeyword(templateName, operator)
  self:WatchMailByTemplateFieldValue(templateName, "body", fieldValue, operator)
end

function Inbox:WatchMailByTemplateSender(templateName, operator)
  self:WatchMailByTemplateFieldValue(templateName, "recipient", fieldValue, operator)
end
