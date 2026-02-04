local LDM = LibDynamicMail

-- {
--     subject = "Welcome, {player}!",
--     body = "Hello {player}, enjoy your house {houseId|house}.",
--     defaultRecipient = nil
-- }

local TEMPLATE_SCHEMA =
{
    subject   = "string",
    body      = "string",

    recipient = { "string", "function", optional = true },
    icon      = { "string", optional = true },

    callback  = { "function", optional = true },
}

local function ValidateObject(obj, schema, context)
    context = context or "object"

    if type(obj) ~= "table" then
        return false, string.format("%s must be a table", context)
    end

    for field, rule in pairs(schema) do
        local optional = false
        local expectedTypes

        if type(rule) == "table" then
            expectedTypes = rule
            optional = rule.optional
        else
            expectedTypes = { rule }
        end

        local value = obj[field]

        if value == nil then
            if not optional then
                return false, string.format(
                    "%s missing required field '%s'",
                    context, field
                )
            end
        else
            local ok = false
            local actualType = type(value)

            for _, t in ipairs(expectedTypes) do
                if actualType == t then
                    ok = true
                    break
                end
            end

            if not ok then
                return false, string.format(
                    "%s field '%s' must be %s (got %s)",
                    context,
                    field,
                    table.concat(expectedTypes, " or "),
                    actualType
                )
            end
        end
    end

    return true
end

function LDM:ListTemplates()
  return self:GetVar("templates")
end

function LDM:RegisterTemplate(templateName, template)
  local templates = self:ListTemplates() or {}
  local ok, err = ValidateObject(
        template,
        TEMPLATE_SCHEMA,
        string.format("LibDynamicMail template '%s'", templateName or "?")
    )
  if not ok then
      d("|cFF0000[LDM]|r " .. err)
      return false
  end
  if not templates[templateName] then
    templates[templateName] = {}
  end
  templates[templateName] = template
  self:SaveToVars("templates", templates)
end

function LDM:GetTemplate(templateName)
  return self:GetVarByValue("templates", templateName)
end
