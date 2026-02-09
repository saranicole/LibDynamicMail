# LibDynamicMail
Library for Elder Scrolls Online Addons - Dynamic mail templates

## Development Status: alpha
unstable, use at your own risk

## Description
Allows addons to generate preset mail templates and trigger email processing events.  Pairs with LibTextFormat to create dynamic mail.

### Reason for being

Allows addons to generate preset mail templates and trigger email processing events.  Pairs with LibTextFormat to create dynamic mail.

### Platform Support

Works with all platforms - leverages Event manager on console to populate send fields since directly opening the mail view is prohibited.

## Basic Usage


### Sending

Pass the recipient, subject and body arguments to LibDynamicMail:ComposeMail to send.  There is a fourth parameter, sendNow, when when true will trigger an immediate send.  

Passing nil or false will populate the initial values in the Send Mail view without sending.

```

local recipient = "BFF",

local subject = "How was your day"

local body = "Hoping you are doing well"


-- Passing true to sendNow will trigger an immediate send.  Passing nil or false will populate the initial values in the Send Mail view.

MyAddon.LDM:ComposeMail(recipient, subject, body, sendNow)

```


### Processing Received Mail

With LibDynamicMail, your addon handles the initial event of mailbox opening.  This is intentionally left to the originating addon so that it controls when mail processing starts.

Somewhere in your addon player activated code:
```

EVENT_MANAGER:RegisterForEvent(MyAddonName.."mailbox", EVENT_MAIL_OPEN_MAILBOX , function(mailId) myAddonCallback(mailId) end )

```

If you are processing all mail that matches the search values, you will need two events and two callback, one pair that processes the mail entries into a list of mail Ids, and one pair that performs a callback on matching Ids.

The parameter is the callback namespace - it will be the key for registering/unregistering mail events for your code execution.

```

local function myAddonCallback()

  MyAddon.LDM:RegisterInboxEvents(MyAddon.Name.."Scan")
  MyAddon.LDM:RegisterInboxEvents(MyAddon.Name.."Process")

  MyAddon.LDM:RegisterInboxCallback(MyAddon.Name.."Scan", function(event, mailId)

    MyAddon.LDM.mailIds = self.mailInstance:FetchMailIdsForSubject("mysearchvalue")

  -- note that since we did not pass true at the end, no need to unregister the mail read event

  end)


  MyAddon.LDM:RegisterInboxCallback(MyAddon.Name.."Process", function(event, mailId)

      local function isValueInTable(table, element)

        for _, v in ipairs(table) do

          if element == v then

            return true

          end

        end

      return false

      end


      if not MyAddon.LDM.mailIds then

        return

      end


      if isValueInTable(self.mailInstance.mailIds, mailId) then

        -- note that RetrieveMailData takes a mail id and does NOT return the body

        local scanResults = MyAddon.LDM:RetrieveMailData(mailId)

        if not scanResults then

          return

        end


        scanResults.body = MyAddon.LDM:RetrieveActiveMailBody()

        if MyAddon.settings.deleteMatchingOnRead then

          MyAddon.LDM:SafeDeleteMail(mailId, true)

        end

    end
    -- processing requires that you call the unregister the read event in your callback

    -- add true as the last argument to RegisterInboxCallback to get this processing behavior

    MyAddon.LDM:UnregisterInboxReadEvents(MyAddon.Name.."Process")

    end

  -- adding true to the end allows you to continue to read mail after the first one has been processed

  -- however it also means you must call the function to unregister the inbox read events
  end, true)

  end)

end

```


What these function calls do:

RegisterInboxEvents - registers the EVENT_MAIL_READABLE based on the template name (note that this should happen before the callbacks are registered since they are dynamic)

RegisterInboxCallback - registers the callback to happen on a readable mail being available

FetchMailIdsForSubject - returns the mail ids of the received mail for any incoming mail with the subject that matches your search value

RetrieveMailData - takes a mail Id and retrieves all of the mail data except for the mail body (the text of the message)

RetrieveActiveMailBody - returns the body of the active (focused) mail message


### Thanks and Credit

Although it was not a one to one port, I took much of my inspiration from Dolgubon's hireling mail handling in [LazyWritCrafter](https://www.esoui.com/downloads/info1346-DolgubonsLazyWritCrafter.html).

Thank you [Dolgubon](https://www.esoui.com/forums/member.php?u=23366)!


### TBD

A means of processing/sending gold, attachments, COD, and similar are work in progress.

### Links

[ESOUI](https://www.esoui.com/downloads/info4379-LibDynamicMail.html)

[ESO Mods](https://mods.bethesda.net/en/elderscrollsonline/details/d98298fa-549a-4a02-ad04-7c3f0dc92445/LibDynamicMail)
