-----------------------------------------------------------------------------------
-- Library Name: LibDynamicMail (LTF)
-- Creator: Saranicole1980 (Sara Jarjoura)
-- Library Ideal: Advanced Text Formatting and Parsing
-- Library Creation Date: February, 2026
-- Publication Date: TBD
--
-- File Name: LibDynamicMail.lua
-- File Description: Contains the main functions of LTF
-- Load Order Requirements: After all other library files
--
-----------------------------------------------------------------------------------

LibDynamicMail = LibDynamicMail or {}

local LDM = LibDynamicMail

function LDM_Initialize( ... )
  LDM.UI.templateList:Build( ... )
end

LDM.RegisterTemplate("LDMTEST", "MYMAILTEMPLATE", { subject = "Welcome", body = "Hello!", receipient="Someone"})
