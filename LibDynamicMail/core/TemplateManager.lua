LibDynamicMail = LibDynamicMail or {}
local LDM = LibDynamicMail

LDM.Templates = {}
local templates = LDM.Templates

-- {
--     subject = "Welcome, {player}!",
--     body = "Hello {player}, enjoy your house {houseId|house}.",
--     defaultRecipient = nil
-- }

function LDM.RegisterTemplate(scopeName, templateName, templateObject)
  if not templates[scopeName] then
    templates[scopeName] = {}
  end
  if not templates[scopeName][templateName] then
    templates[scopeName][templateName] = {}
  end
    templates[scopeName][templateName] = templateObject
end

function LDM.GetTemplates(scopeName)
    return templates.templates[scopeName] or {}
end
