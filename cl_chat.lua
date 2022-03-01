local chatInputActive, chatInputActivating, chatHidden, chatLoaded, Cfg = false, false, true, false, {
    Suggestions = true;
}

-- EVENTS
RegisterNetEvent('chatMessage', function(author, color, text)
    local args = {text}
    if author ~= "" then
        table.insert(args, 1, author)
    end
    SendNUIMessage({
        type = 'ON_MESSAGE',
        message = {
            color = color,
            multiline = true,
            args = args
        }
    })
end)
RegisterNetEvent('chat:addTemplate', function(id, html)
    SendNUIMessage({
        type = 'ON_TEMPLATE_ADD',
        template = {
            id = id,
            html = html
        }
    })
end)
RegisterNetEvent('chat:addMessage', function(message)
    message.bgcolor = message.color
    SendNUIMessage({
        type = 'ON_MESSAGE',
        message = message
    })
end)
RegisterNetEvent('chat:addSuggestion', function(name, help, params)
    SendNUIMessage({
        type = 'ON_SUGGESTION_ADD',
        suggestion = {
            name = name,
            help = help,
            params = params or nil
        }
    })
end)
RegisterNetEvent('chat:addSuggestions', function(suggestions)
    if Cfg.Suggestions then 
        for _, suggestion in ipairs(suggestions) do
            SendNUIMessage({
                type = 'ON_SUGGESTION_ADD',
                suggestion = suggestion
            })
        end
    end
end)
RegisterNetEvent('chat:removeSuggestion', function(name)
    SendNUIMessage({
        type = 'ON_SUGGESTION_REMOVE',
        name = name
    })
end)
RegisterNetEvent('chat:clear', function(name)
    SendNUIMessage({
        type = 'ON_CLEAR'
    })
end)
RegisterNetEvent('__cfx_internal:serverPrint', function(msg)
    print(msg)

    SendNUIMessage({
        type = 'ON_MESSAGE',
        message = {
            templateId = 'print',
            multiline = true,
            args = {msg}
        }
    })
end)
-- NUI CALLBACKS
RegisterNUICallback('chatResult', function(data, cb)
    chatInputActive = false
    SetNuiFocus(false)

    if not data.canceled then
        local id = PlayerId()

        -- deprecated
        local r, g, b = 0, 0x99, 255

        if data.message:sub(1, 1) == '/' then
            ExecuteCommand(data.message:sub(2))
        else
            TriggerServerEvent('_chat:messageEntered', GetPlayerName(id), {r, g, b}, data.message)
        end
    end

    cb('ok')
end)

RegisterNUICallback('loaded', function(data, cb)
    TriggerServerEvent('chat:init');

    refreshCommands()
    refreshThemes()

    chatLoaded = true

    cb('ok')
end)

-- FUNCTIONS

refreshCommands = function()
    if GetRegisteredCommands then
        local registeredCommands = GetRegisteredCommands()

        local suggestions = {}

        for _, command in ipairs(registeredCommands) do
            if IsAceAllowed(('command.%s'):format(command.name)) then
                table.insert(suggestions, {
                    name = '/' .. command.name,
                    help = ''
                })
            end
        end

        TriggerEvent('chat:addSuggestions', suggestions)
    end
end

refreshThemes = function()
    local themes = {}

    for resIdx = 0, GetNumResources() - 1 do
        local resource = GetResourceByFindIndex(resIdx)

        if GetResourceState(resource) == 'started' then
            local numThemes = GetNumResourceMetadata(resource, 'chat_theme')

            if numThemes > 0 then
                local themeName = GetResourceMetadata(resource, 'chat_theme')
                local themeData = json.decode(GetResourceMetadata(resource, 'chat_theme_extra') or 'null')

                if themeName and themeData then
                    themeData.baseUrl = 'nui://' .. resource .. '/'
                    themes[themeName] = themeData
                end
            end
        end
    end

    SendNUIMessage({
        type = 'ON_UPDATE_THEMES',
        themes = themes
    })
end

-- COMMANDS

RegisterCommand('chat', function()
    SetTextChatEnabled(false)
    SetNuiFocus(false)

    if not chatInputActive then
        chatInputActive = true
        chatInputActivating = true

        SendNUIMessage({
            type = 'ON_OPEN'
        })
    end

    if chatInputActivating then
        SetNuiFocus(true)

        chatInputActivating = false
    end

    if chatLoaded then
        local shouldBeHidden = false

        if IsScreenFadedOut() or IsPauseMenuActive() then
            shouldBeHidden = true
        end

        if (shouldBeHidden and not chatHidden) or (not shouldBeHidden and chatHidden) then
            chatHidden = shouldBeHidden

            SendNUIMessage({
                type = 'ON_SCREEN_STATE_CHANGE',
                shouldHide = shouldBeHidden
            })
        end
    end
end)

-- KEY MAPPINGS

RegisterKeyMapping('chat', 'Abre el chat', 'keyboard', 'T')


-- COMMANDS

-- RegisterCommand("ooc", function(source, args)
--     local args = table.concat(args, " ")
--     TriggerEvent("chatMessage", "["..GetPlayerServerId(PlayerId()).."]".." [OOC]", {0,255,255}, args)
--     -- TriggerServerEvent("chatMessage", -1, {27,27,27}, "^0[^1OOC^0] ^7" .. GetPlayerName(PlayerId()) .. "^7: " .. args)
-- end)