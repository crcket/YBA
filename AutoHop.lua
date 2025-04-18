--// Comments and beautification done w/ chatGPT

--// 📌 Initial Checks
repeat task.wait() until game:IsLoaded()
if game.PlaceId ~= 2809202155 then return end

--// 📦 Services & Variables
local replicatedFirst = game:GetService("ReplicatedFirst")
local replicatedStorage = game:GetService("ReplicatedStorage")
local plr = game.Players.LocalPlayer
local itemSpawns = workspace["Item_Spawns"].Items
local plrGui = plr.PlayerGui
local loaded = false
local Option = getgenv().Settings.SellAll and "Option2" or "Option1"
local luckyBought = false
local allowedAccs = {}

--// 📁 Folder & File Setup
task.spawn(function()
if not isfolder("YBA_AUTOHOP") then makefolder("YBA_AUTOHOP") end
if not isfile("YBA_AUTOHOP/Count.txt") then writefile("YBA_AUTOHOP/Count.txt", "") end
if not isfile("YBA_AUTOHOP/whitelistedAccs.txt") then
    writefile("YBA_AUTOHOP/whitelistedAccs.txt", "ROBLOX\r\nBuilderman\r\nYOURNAMEHERE")
end
if not isfile("YBA_AUTOHOP/theme.mp3") then
    local response = request({Url = "https://raw.githubusercontent.com/crcket/YBA/refs/heads/main/Diavolo%20Theme%20but%20it's%20EPIC%20VERSION%20(King%20Crimson%20Requiem).mp3",Method = "GET"})
    if response.StatusCode == 200 then
        writefile("YBA_AUTOHOP/theme.mp3", response.Body)
        print("File saved successfully!")
    else
        warn("Failed to download file. Status Code:", response.StatusCode)
    end
end
workspace:WaitForChild("LoadingScreen"):WaitForChild("Song").SoundId = getcustomasset("YBA_AUTOHOP/theme.mp3")
end)
--// ⏳ Wait for Core Game Objects
repeat task.wait() until game:IsLoaded() and game.ReplicatedStorage and game.ReplicatedFirst 
    and plr and plr.Character and plr.PlayerGui and plr:FindFirstChild("PlayerStats")

--// 🔁 Server Hop Function
local function serverHop()
    local gameId = game.PlaceId
    local servers, cursor = {}, ""

    repeat
        local success, result = pcall(function()
            return game.HttpService:JSONDecode(game:HttpGet(
                "https://games.roblox.com/v1/games/" .. gameId .. "/servers/Public?sortOrder=Asc&limit=100&cursor=" .. cursor
            ))
        end)

        if success and result and result.data then
            for _, server in ipairs(result.data) do
                if server.playing >= 10 and server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(servers, server.id)
                end
            end
            cursor = result.nextPageCursor or ""
        else
            break
        end
    until cursor == "" or #servers >= 1

    if #servers > 0 then
        game:GetService("TeleportService"):TeleportToPlaceInstance(gameId, servers[math.random(1, #servers)], plr)
    else
        warn("No available servers found.")
    end
end

--// 📬 Webhook Notification Handler
local function webHookHandler(Mode)
    local lCount = 1
    for _, item in pairs(plr.Backpack:GetChildren()) do
        if item.Name == "Lucky Arrow" then
            lCount += 1
        end
    end

    local titleContent, descriptionContent, colorContent, imageContent, thumbnailContent, footerContent

    if Mode == "luckyArrow" then
        local req = request({Url = `https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds={plr.UserId}&size=48x48&format=png`})
        local body = game:GetService("HttpService"):JSONDecode(req.Body)

        titleContent = plr.Name
        descriptionContent = os.date("%I:%M %p")
        colorContent = 16776960
        imageContent = {url = "https://static.wikia.nocookie.net/your-bizarre-adventure/images/f/fd/LuckyArrow.png/revision/latest?cb=20221020062009"}
        thumbnailContent = {url = body.data[1].imageUrl}
        footerContent = {text = `{lCount}/9 lucky arrows`}

    elseif Mode == "prestige3" then
        titleContent = "Possible Main acc detected!"
        descriptionContent = `An account with the name of {plr.Name} is prestige 3+ and has been automatically kicked due to possibly being a main account.\n\nPlease go to your exploit's workspace folder and navigate to YBA_AUTOHOP/whitelistedAccs.txt and add a new account`
        colorContent = 16711680
    end

    request({
        Url = getgenv().Settings.URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = game:GetService("HttpService"):JSONEncode({
            content = nil,
            embeds = {{
                title = titleContent,
                description = descriptionContent,
                color = colorContent,
                image = imageContent,
                thumbnail = thumbnailContent,
                footer = footerContent,
            }}
        })
    })
end

--// 🎒 Inventory Processor
local function processInventory()
    if not getgenv().Settings.SellAll then return end

    local uniqueItems = {}
    for _, item in ipairs(plr.Backpack:GetChildren()) do
        uniqueItems[item.Name] = item
    end

    for name, item in pairs(uniqueItems) do
        if name ~= "Lucky Arrow" and name ~= "Stand Arrow" then
            task.wait(0.5)
            plr.Character.Humanoid:EquipTool(item)
            plr.Character.RemoteEvent:FireServer("EndDialogue", {
                NPC = "Merchant",
                Option = Option,
                Dialogue = "Dialogue5"
            })
        end
    end
end

-- Auto Sell Inventory Every 12 Seconds
task.spawn(function()
    while task.wait(12) do
        processInventory()
    end
end)

--// 🔧 Main Setup
local function setup()
    -- Hook "Returner" InvokeServer call
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        if tostring(self) == "Returner" and tostring(getnamecallmethod()) == "InvokeServer" then
            return "  ___XP DE KEY"
        end
        return old(self, ...)
    end)

    -- Prevent spawn distance checks
    local vector3Metatable = getrawmetatable(Vector3.new())
    local oldIndex = vector3Metatable.__index
    setreadonly(vector3Metatable, false)
    vector3Metatable.__index = newcclosure(function(self, idx)
        if string.lower(idx) == "magnitude" and getcallingscript() == replicatedFirst.ItemSpawn then
            return 0
        end
        return oldIndex(self, idx)
    end)
    setreadonly(vector3Metatable, true)

    -- Move to pickup point
    plr.Character.HumanoidRootPart.CFrame = CFrame.new(-23, -33, 28)

    -- Rename items based on their prompt text
    for _, item in pairs(itemSpawns:GetChildren()) do
        local prox = item:WaitForChild("ProximityPrompt", 9)
        item.Name = prox.ObjectText
    end

    -- Handle newly spawned items
    itemSpawns.ChildAdded:Connect(function(item)
        local prox = item:WaitForChild("ProximityPrompt", 9)
        item.Name = prox.ObjectText

        for _, v in pairs(itemSpawns:GetDescendants()) do
            if v:IsA("ProximityPrompt") and v.MaxActivationDistance == 0 and v.Name ~= "Proximity Prompt __" then
                v.Name = "ProximityPrompt __"
            end
        end

        for _, v in pairs(itemSpawns:GetChildren()) do
            if not v:FindFirstChild("ProximityPrompt") then v:Destroy() end
        end
    end)
    local res = readfile("YBA_AUTOHOP/whitelistedAccs.txt")
    for i in string.gmatch(res,"[^\r\n]+") do
        table.insert(allowedAccs,i)
    end
end

--// ▶️ Skip Loading Screen and Enter Game
plr.Character.RemoteEvent:FireServer("PressedPlay")
loaded = true

--// 🚀 Start Automation
if not getgenv().Settings.AutoFarm then return end
repeat task.wait(0.5) until loaded
task.wait(5)
local lastPickupTime = tick()
-- Kick if Prestige 3+ (possible main)
if plr.PlayerStats.Prestige.Value >= 3 and not table.find(allowedAccs,plr.Name) then
    webHookHandler("prestige3")
    plr:Kick("MAIN ACC DETECTED!")
end

setup()

--// 🧲 Auto Pickup Logic
local isNotOnAlready = true
itemSpawns.ChildAdded:Connect(function(item)
    repeat task.wait() until item.Name ~= "Model" and isNotOnAlready and not plr.Character.HumanoidRootPart.Anchored
    print(`-> picking up {item.Name}!`)
    lastPickupTime = tick()

    if getgenv().Settings.AutoFarm and item.PrimaryPart and item:FindFirstChild("ProximityPrompt __") then
        isNotOnAlready = false
        plr.Character.HumanoidRootPart.CFrame = item.PrimaryPart.CFrame
        task.wait(getgenv().Settings.PickupDelay or 0.2)
        firesignal(item:FindFirstChildWhichIsA("ProximityPrompt").Triggered)

        spawn(function()
            task.wait(2)
            if item.Parent then
                firesignal(item:FindFirstChildWhichIsA("ProximityPrompt").Triggered)
            end
        end)

        item.AncestryChanged:Wait()
        isNotOnAlready = true
        plr.Character.HumanoidRootPart.CFrame = CFrame.new(-23, -33, 28)
    end
end)

--// 🧾 Auto Sell When "Message" Pops Up
plrGui.ChildAdded:Connect(function(thing)
    if thing.Name == "Message" then
        task.wait()
        local itemName = thing:WaitForChild("TextLabel").Text:match("%d+%s+(.+) in your inventory"):gsub("%(s%)$", "")
        local item = plr.Backpack:FindFirstChild(itemName)
        if item then item.Parent = plr.Character end

        plr.Character.RemoteEvent:FireServer("EndDialogue", {
            NPC = "Merchant",
            Option = Option,
            Dialogue = "Dialogue5"
        })
    end
end)

--// 🍀 Auto Buy Lucky Arrows
plr.PlayerStats.Money.Changed:Connect(function()
    if not luckyBought and plr.PlayerStats.Money.Value >= 50000 then
        local luckyNum = 0
        for _, v in pairs(plr.Backpack:GetChildren()) do
            if v.Name == "Lucky Arrow" then luckyNum += 1 end
        end
        if luckyNum <= 8 then
            luckyBought = true
            task.wait(1)
            plr.Character.RemoteEvent:FireServer("PurchaseShopItem", { ItemName = "1x Lucky Arrow" })
            webHookHandler("luckyArrow")
            local log = `{plr.Name} {os.date("%I:%M %p")}\n`
            writefile("YBA_AUTOHOP/Count.txt", readfile("YBA_AUTOHOP/Count.txt") .. log)
        else
            luckyBought = true
            getgenv().Settings.SellAll = false
            Option = "Option1"
        end
    end
end)

--// ⏰ Server Hop if Inactive
task.spawn(function()
    while task.wait(1) do
        if tick() - lastPickupTime > 10 then
            serverHop()
        end
    end
end)
