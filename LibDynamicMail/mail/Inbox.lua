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
        and self.savedVars.InboxCallbacks[templateName][functionName]["func"]
  if not callback then return false end
  self.savedVars.InboxCallbacks[templateName][functionName]["func"](event, mailId)
  if not self.savedVars.InboxCallbacks[templateName][functionName]["preserveReadableEvent"] then
    event_manager:UnregisterForEvent(functionName.."mailboxreadable", EVENT_MAIL_READABLE)
  end
end

function LDM:UnregisterInboxReadEvents(functionName)
  event_manager:UnregisterForEvent(functionName.."mailboxreadable", EVENT_MAIL_READABLE)
end

function LDM:RegisterInboxCallback(templateName, functionName, functionCallback, preserveReadableEvent)
  self.savedVars.InboxCallbacks = self.savedVars.InboxCallbacks or {}
  self.savedVars.InboxCallbacks[templateName] = self.savedVars.InboxCallbacks[templateName] or {}
  self.savedVars.InboxCallbacks[templateName][functionName] = { func = functionCallback, preserveReadableEvent = preserveReadableEvent }
end

function LDM:RegisterInboxEvents(templateName, functionName)
  event_manager:RegisterForEvent(functionName.."mailboxreadable", EVENT_MAIL_READABLE, function(event, mailId)
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

function LDM:RetrieveActiveMailBody()
  if IsConsoleUI() or IsInGamepadPreferredMode() then
    local control = MailInbox.control:GetNamedChild("Inbox"):GetNamedChild("RightPane"):GetNamedChild("Container"):GetNamedChild("Inbox")
   return ZO_MailView_GetBody_Gamepad(control)
  else
    return MailInbox.body:GetText()
  end
end

function LDM:RetrieveMailData(mailId)
  local senderDisplayName, senderCharacterName, subject, firstItemIcon, unread, fromSystem, fromCS, returned, numAttachments, attachedMoney, codAmount, expiresInDays, secsSinceReceived, category = GetMailItemInfo(mailId)
  return {
    subject = subject,
    returned = returned,
    senderDisplayName = senderDisplayName,
    senderCharacterName = senderCharacterName,
    expiresInDays = expiresInDays,
    unread = unread,
    numAttachments = numAttachments,
    attachedMoney = attachedMoney,
    codAmount = codAmount,
    secsSinceReceived = secsSinceReceived,
    fromSystem = fromSystem,
    fromCS = fromCS,
    isFromPlayer = isFromPlayer,
    GetFormattedSubject = GetFormattedSubject,
    GetFormattedReplySubject = GetFormattedReplySubject,
    GetExpiresText = GetExpiresText,
    GetReceivedText = GetReceivedText,
    isReadInfoReady = isReadInfoReady,
    IsExpirationImminent = IsExpirationImminent,
    firstItemIcon = firstItemIcon,
    category = category
  }
end

function LDM:CheckMailForTemplateFieldValue(mailId, templateName, fieldKey, operator)
  local senderDisplayName, senderCharacterName, subject, firstItemIcon, unread, fromSystem, fromCS, returned, numAttachments, attachedMoney, codAmount, expiresInDays, secsSinceReceived, category = GetMailItemInfo(nextMailId)

  local mailData = {
    senderDisplayName = senderDisplayName,
    subject = subject
  }
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

function LDM:FetchMailIdsForTemplateFieldValue(templateName, fieldKey, operator, mailId, mailIds)
  local nextMailId = GetNextMailId(mailId)
  if not nextMailId then
    return mailIds
  end
  mailIds = mailIds or {}
  local mailData = {}

  local senderDisplayName, senderCharacterName, subject, firstItemIcon, unread, fromSystem, fromCS, returned, numAttachments, attachedMoney, codAmount, expiresInDays, secsSinceReceived, category = GetMailItemInfo(nextMailId)

  local nextMail = {
    senderDisplayName = senderDisplayName,
    subject = subject,
  }

  -- body search is not implemented
  local template = self:GetTemplate(templateName)

  if not template then d("|cFF0000[LDM]|r LibDynamicMail: Template not found") return false end
  if not operator or operator == "equals" then
    if template[fieldKey] == nextMail[fieldKey] then
      table.insert(mailIds, nextMailId)
    end
  end
  if operator == "contains" then
    if template[fieldKey]:find(nextMail[fieldKey], 1, true) ~= nil then
      table.insert(mailIds, nextMailId)
    end
  end
  return self:FetchMailIdsForTemplateFieldValue(templateName, fieldKey, operator, nextMailId, mailIds)
end

function LDM:CheckMailForTemplateSubject(mailId, templateName, operator)
  return self:CheckMailForTemplateFieldValue(mailId, templateName, "subject", operator)
end

function LDM:FetchMailIdsForTemplateSubject(templateName, operator)
  local mailIds = self:FetchMailIdsForTemplateFieldValue(templateName, "subject", operator)
  return mailIds
end

function LDM:CheckMailForTemplateSender(mailId, templateName, operator)
  return self:CheckMailForTemplateFieldValue(mailId, templateName, "senderDisplayName", operator)
end

function LDM:FetchMailIdsForTemplateSender(templateName, operator)
  return self:FetchMailIdsForTemplateFieldValue(templateName, "senderDisplayName", operator)
end
