LibDynamicMail = LibDynamicMail or {}
local LDM = LibDynamicMail

LDM.Send = {}
local Send = LDM.Send

function Send:PopulateCompose(recipient)
  MAIL_MANAGER_GAMEPAD:GetSend():ComposeMailTo(ZO_FormatUserFacingCharacterOrDisplayName(recipient))
end
