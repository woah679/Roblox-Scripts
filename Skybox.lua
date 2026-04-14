--_G.PushNotification("Green", "Client sided btw nigger foenem")
repeat task.wait() until _G.WindUI and _G.Tabs

local WindUI = _G.WindUI
local Tabs = _G.Tabs
local Lighting = game:GetService("Lighting")

local function LoadCustomImage(url, filename)
    if not filename:lower():match("%.png$") and not filename:lower():match("%.gif$") then
        filename = filename .. ".png"
    end

    if isfile(filename) then
        delfile(filename)
    end

    local success, data = pcall(function()
        return game:HttpGet(url, true)
    end)

    if not success or not data then
        WindUI:Notify({
            Title = "Skybox",
            Content = "Failed to download image from URL",
            Duration = 5
        })
        return nil
    end

    writefile(filename, data)

    local getAsset = getcustomasset or getsynasset
    if not getAsset then
        WindUI:Notify({
            Title = "Skybox",
            Content = "loll very bad exec cannot use getcustomasset OLOLOLOL",
            Duration = 5
        })
        return nil
    end

    return getAsset(filename)
end

-- da thing dat does stuff
repeat task.wait() until _G.WindUI and _G.Functions and _G.Tabs
repeat task.wait() until _G.WindUI.Notify

local WindUI = _G.WindUI
local Window = _G.Window
local Tabs = _G.Tabs
local Connections = _G.Connections
local Functions = _G.Functions

repeat task.wait() until _G.Tabs and _G.Tabs.Visuals

local function scan(tbl)
    for _, v in pairs(tbl) do
        if typeof(v) == "table" then

            if v.Title == "Change Time" or v.Name == "Change Time" then
                if v.Callback then
                    pcall(function()
                        v.Callback(true)
                    end)
                end
            end

            if v.Title == "World Time" or v.Name == "World Time" then
                if v.Callback then
                    pcall(function()
                        v.Callback(12)
                    end)
                end
            end

            scan(v)
        end
    end
end

scan(_G.Tabs.Visuals)


-- stupid ass pussy chat gpt feature for u retards who want this XD
local SkyPresets = {
    ["Purple Nebula"] = {type = "asset", id = "159454299"},
    ["Blue Sky"] = {type = "asset", id = "7018684000"},

    ["Sam Kalish"] = {
        type = "url",
        url = "https://cdn.discordapp.com/avatars/128988722837323776/dfe6a8a3dace8d4e88f26a27e46a1862.webp?size=4096"
    },

   --[[ ["MrBeast"] = {
        type = "url",
        url = "https://cdn.discordapp.com/attachments/1479203981489082532/1487846087057477843/togif-21.gif?ex=69de66a5&is=69dd1525&hm=d473de0f9d4c2997efb7e0881f44dfa5b0da00aa20cc3808714530baff9d646f&"
    },]]
    -- Add more URL presets easily here:
    -- ["Name"] = { type = "url", url = "https://..." },
}

local selectedPreset = nil
local assetInput = ""
local urlInput = ""
local mode = "Preset"

local function applySky(modeType, value)
   
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("Sky") then
            v:Destroy()
        end
    end

    task.wait(0.3)

    local sky = Instance.new("Sky")

    if modeType == "asset" then
        local id = "rbxassetid://" .. tostring(value)
        sky.SkyboxBk = id
        sky.SkyboxDn = id
        sky.SkyboxFt = id
        sky.SkyboxLf = id
        sky.SkyboxRt = id
        sky.SkyboxUp = id

    elseif modeType == "url" then
        local customAsset = LoadCustomImage(value, "CustomSky_" .. math.random(100000, 999999))
        if not customAsset then
            return
        end

        sky.SkyboxBk = customAsset
        sky.SkyboxDn = customAsset
        sky.SkyboxFt = customAsset
        sky.SkyboxLf = customAsset
        sky.SkyboxRt = customAsset
        sky.SkyboxUp = customAsset
    end

    sky.Parent = Lighting
end

Tabs.Visuals:Section({ Title = "Skybox System [client]" })

Tabs.Visuals:Dropdown({
    Title = "Mode",
    Values = {"Preset", "Asset ID", "URL"},
    Callback = function(v)
        mode = v
    end
})

Tabs.Visuals:Dropdown({
    Title = "Presets",
    Values = (function()
        local t = {}
        for n in pairs(SkyPresets) do
            table.insert(t, n)
        end
        table.sort(t)
        return t
    end)(),
    Callback = function(v)
        selectedPreset = v
    end
})

Tabs.Visuals:Input({
    Title = "Asset ID",
    Placeholder = "123456789",
    Callback = function(v)
        assetInput = v
    end
})

Tabs.Visuals:Input({
    Title = "Image URL [prob wont work]",
    Placeholder = "https://...",
    Callback = function(v)
        urlInput = v
    end
})

Tabs.Visuals:Button({
    Title = "Apply Skybox",
    Callback = function()
        if mode == "Preset" then
            local p = SkyPresets[selectedPreset]
            if not p then
                return WindUI:Notify({
                    Title = "Skybox",
                    Content = "No preset selected",
                    Duration = 3
                })
            end
            applySky(p.type, p.id or p.url)

        elseif mode == "Asset ID" then
            if assetInput == "" then
                return WindUI:Notify({
                    Title = "Skybox",
                    Content = "Enter an Asset ID",
                    Duration = 3
                })
            end
            applySky("asset", assetInput)

        elseif mode == "URL" then
            if urlInput == "" then
                return WindUI:Notify({
                    Title = "Skybox",
                    Content = "Enter an Image URL",
                    Duration = 3
                })
            end
            applySky("url", urlInput)
        end
    end
})
