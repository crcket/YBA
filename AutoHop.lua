-- Beautified w/ chatGPT

-- Initial Checks
repeat task.wait() until game:IsLoaded()
if game.PlaceId ~= 2809202155 then return end
game:GetService("RunService"):Set3dRenderingEnabled(true)

-- Services & Variables
local replicatedFirst = game:GetService("ReplicatedFirst")
local replicatedStorage = game:GetService("ReplicatedStorage")
local plr = game.Players.LocalPlayer
local itemSpawns = workspace["Item_Spawns"].Items
local plrGui = plr.PlayerGui
local loaded = false
local lastPickupTime = tick()
local Option = getgenv().Settings.SellAll and "Option2" or "Option1"
local luckyBought = false

-- Wait for everything
repeat task.wait() until game:IsLoaded() and game.ReplicatedStorage and game.ReplicatedFirst and plr and plr.Character and plr.PlayerGui

-- Anti-AFK
for _, v in pairs(getconnections(plr.Idled)) do
    v:Disable()
end

-- Server Hop Function
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

-- Webhook Notification
local function sendWebhook()
    local lCount = 1
    for _, item in pairs(plr.Backpack:GetChildren()) do
        if item.Name == "Lucky Arrow" then
            lCount += 1
        end
    end

    local req = request({
        Url = `https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds={plr.UserId}&size=48x48&format=png`
    })
    local body = game:GetService("HttpService"):JSONDecode(req.Body)

    request({
        Url = getgenv().Settings.URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = game:GetService("HttpService"):JSONEncode({
            content = nil,
            embeds = {{
                title = plr.Name,
                description = os.date("%I:%M %p"),
                color = 16776960,
                image = { url = "https://static.wikia.nocookie.net/your-bizarre-adventure/images/f/fd/LuckyArrow.png/revision/latest?cb=20221020062009" },
                thumbnail = { url = body.data[1].imageUrl },
                footer = { text = `{lCount}/9 lucky arrows` }
            }}
        })
    })
end

-- Fire Signal Helper
local function replacementFireSignal(signal)
    for _, conn in pairs(getconnections(signal)) do
        if conn.Function then
            return conn.Function
        end
    end
    return nil
end

-- Inventory Processing
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

task.spawn(function()
    while task.wait(12) do
        processInventory()
    end
end)

-- Metamethod Hook
local function hookmetamethod(obj, metamethod, newFunction)
    local meta = getrawmetatable(obj)
    assert(meta, "Object has no metatable.")
    local oldFunction = meta[metamethod]
    assert(type(oldFunction) == "function", "Metamethod not found or not a function.")

    setreadonly(meta, false)
    local hookedFunction = hookfunction(oldFunction, newFunction)
    setreadonly(meta, true)

    return hookedFunction
end

-- Folder & File Setup
if not isfolder("YBA_AUTOHOP") then makefolder("YBA_AUTOHOP") end
if not isfile("YBA_AUTOHOP/Count.txt") then writefile("YBA_AUTOHOP/Count.txt", "") end

-- Main Setup Function
local function setup()
    for _, v in pairs(getconnections(plr.Idled)) do v:Disable() end

    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        if tostring(self) == "Returner" and tostring(getnamecallmethod()) == "InvokeServer" then
            return "  ___XP DE KEY"
        end
        return old(self, ...)
    end)

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

    plr.Character.HumanoidRootPart.CFrame = CFrame.new(-23, -33, 28)

    for _, item in pairs(itemSpawns:GetChildren()) do
        local prox = item:WaitForChild("ProximityPrompt", 9)
        item.Name = prox.ObjectText
    end

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

    for _, v in pairs(itemSpawns:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.MaxActivationDistance == 0 and v.Name ~= "Proximity Prompt __" then
            v.Name = "ProximityPrompt __"
        end
    end
    for _, v in pairs(itemSpawns:GetChildren()) do
        if not v:FindFirstChild("ProximityPrompt") then v:Destroy() end
    end
end

-- Skip Screen & Play
local screen = plrGui:FindFirstChild("LoadingScreen1")
if screen then
    replacementFireSignal(screen.Frame.LoadingFrame.BarFrame.Skip.TextButton.MouseButton1Click)()
    task.wait(4)
    replacementFireSignal(plrGui.LoadingScreen.Frames.Main.Play.MouseButton1Click)()
    task.wait(0.1)
    replacementFireSignal(plrGui.LoadingScreen.Frames.Gamemodes.MainGame.Play.MouseButton1Click)()
    loaded = true
else
    replacementFireSignal(plrGui.LoadingScreen.Frames.Main.Play.MouseButton1Click)()
    task.wait()
    replacementFireSignal(plrGui.LoadingScreen.Frames.Gamemodes.MainGame.Play.MouseButton1Click)()
    loaded = true
end

-- Start Automation
if not getgenv().Settings.AutoFarm then return end
repeat task.wait(0.5) until loaded

setup()

local isNotOnAlready = true
itemSpawns.ChildAdded:Connect(function(item)
    repeat task.wait() until item.Name ~= "Model" and isNotOnAlready and not plr.Character.HumanoidRootPart.Anchored
    print(`-> picking up {item.Name}!`)
    lastPickupTime = tick()

    if getgenv().Settings.AutoFarm and item.PrimaryPart and item:FindFirstChild("ProximityPrompt __") then
        isNotOnAlready = false
        plr.Character.HumanoidRootPart.CFrame = item.PrimaryPart.CFrame
        task.wait(0.20)
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

-- Handle Message Selling
plrGui.ChildAdded:Connect(function(thing)
    if thing.Name == "Message" then
        task.wait()
        local itemName = thing:WaitForChild("TextLabel").Text:match("%d+%s+(.+) in your inventory"):gsub("%(s%)$", "")
        local item = plr.Backpack:FindFirstChild(itemName)
        if item then item.Parent = plr.Character end

        task.wait()
        local args = {
            [1] = "EndDialogue",
            [2] = { NPC = "Merchant", Option = Option, Dialogue = "Dialogue5" }
        }
        plr.Character.RemoteEvent:FireServer(unpack(args))
    end
end)

-- Auto Buy Lucky Arrow
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
            sendWebhook()
            local log = `{plr.Name} {os.date("%I:%M %p")}\n`
            writefile("YBA_AUTOHOP/Count.txt", readfile("YBA_AUTOHOP/Count.txt") .. log)
        else
            luckyBought = true
            getgenv().Settings.SellAll = false Option = "Option1"
        end
    end
end)

-- Auto Server Hop Timer
task.spawn(function()
    while task.wait(1) do
        if tick() - lastPickupTime > 10 then
            serverHop()
        end
    end
end)
