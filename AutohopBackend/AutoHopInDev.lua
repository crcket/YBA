-- This is the DEV version of autohop!
repeat task.wait() until game:IsLoaded()

if game.PlaceId ~= 2809202155 or not getgenv().Settings.AutoFarm then
    return
end

local plr = game.Players.LocalPlayer
repeat task.wait() until plr.Character and plr.PlayerGui and plr:FindFirstChild("PlayerStats")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ItemSpawns = workspace["Item_Spawns"].Items
local PlrGui = plr.PlayerGui
local CoreGui = game.CoreGui
local Option = getgenv().Settings.SellAll and "Option2" or "Option1"
local LuckyBought = false
local AllowedAccounts = {}
local DataFolder = plr.PlayerStats
local MoneyValue = DataFolder.Money
local StartingCash = MoneyValue.Value
local ShowAutofarmingMessage = Instance.new("Message",gethui())
local JoinTime = `{os.date("%I")}:{os.date("%M")}`
local ItemCollectionConsole = loadstring(game:HttpGet("https://raw.githubusercontent.com/crcket/ROBLOX/refs/heads/main/crckonsle.lua"))()

if not isfolder("YBA_AUTOHOP") then
    makefolder("YBA_AUTOHOP")
end
if not isfile("YBA_AUTOHOP/Count.txt") then
    writefile("YBA_AUTOHOP/Count.txt", "")
end
if not isfile("YBA_AUTOHOP/whitelistedAccs.txt") then
    writefile("YBA_AUTOHOP/whitelistedAccs.txt","ROBLOX\r\nBuilderman\r\nYOURNAMEHERE")
end
if not isfile("YBA_AUTOHOP/lastLucky.txt") then
    writefile("YBA_AUTOHOP/lastLucky.txt", "")
end
if not isfile("YBA_AUTOHOP/lastJobId.txt") then
    writefile("YBA_AUTOHOP/lastJobId.txt", tostring(game.JobId))
end

if getgenv().Settings.LowGFX then
    game:GetService("RunService"):Set3dRenderingEnabled(false)
end



local function WebhookHandler(Mode)
    local LuckyCount = 1
    for _, Item in pairs(plr.Backpack:GetChildren()) do
        if Item.Name == "Lucky Arrow" then
            LuckyCount += 1
        end
    end
    local textContent, titleContent, descriptionContent, colorContent, imageContent, thumbnailContent, footerContent
    if Mode == "LuckyArrow" then
        local req = request({
            Url = `https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds={plr.UserId}&size=48x48&format=png`,
        })
        local body = game:GetService("HttpService"):JSONDecode(req.Body)

        titleContent = plr.Name
        descriptionContent = os.date("%I:%M %p")
        colorContent = 16776960
        imageContent = {
            url = "https://static.wikia.nocookie.net/your-bizarre-adventure/images/f/fd/LuckyArrow.png/revision/latest?cb=20221020062009",
        }
        thumbnailContent = { url = body.data[1].imageUrl }

        if
            getgenv().Settings.PingOnLuckyArrow
            and LuckyCount >= 9
            and readfile("YBA_AUTOHOP/lastLucky.txt") ~= plr.Name
        then
            writefile("YBA_AUTOHOP/lastLucky.txt", plr.Name)
            textContent =`<@{getgenv().Settings.DiscordID}>, your account ({plr.Name}) has around 9/9 lucky arrows`
        end
        footerContent = { text = `{LuckyCount}/9 lucky arrows` }
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
            content = textContent,
            embeds = {
                {
                    title = titleContent,
                    description = descriptionContent,
                    color = colorContent,
                    image = imageContent,
                    thumbnail = thumbnailContent,
                    footer = footerContent,
                },
            },
        }),
    })
end

function GetCashSinceJoin()
    return MoneyValue.Value - StartingCash
end

ShowAutofarmingMessage.Text = `Currently Autofarming.\n———————————————————\nPickup speed: {getgenv().Settings.PickupDelay} seconds \nServer join time: {JoinTime} {os.date("%p")}\nServer Id: {game.JobId}\n Money made since join: ${tostring(math.clamp(GetCashSinceJoin(), 0, 9e9))}\nScript version: {getgenv().AutoHopVersion}`

local function ProcessInventory()
    task.spawn(function()
        ItemCollectionConsole.Send(`Sold items.`, "ANNOUNCEMENT")
    end)
    warn(getgenv().Settings.SellAll)

    local uniqueItems = {}
    for _, Item in ipairs(plr.Backpack:GetChildren()) do
        uniqueItems[Item.Name] = Item
    end

    for name, Item in pairs(uniqueItems) do
        if name ~= "Lucky Arrow" and name ~= "Stand Arrow" then
            task.wait(0.5)
            plr.Character.Humanoid:EquipTool(Item)

            local MerchantEvent = plr.Character.RemoteEvent

            MerchantEvent:FireServer(
                "PromptTriggered",
                game:GetService("ReplicatedStorage").Dialogue.Merchant
            )
            local DialogueGui = PlrGui:WaitForChild("DialogueGui"):WaitForChild("Frame")
            local Continue = DialogueGui:WaitForChild("ClickContinue",1)
            firesignal(Continue.MouseButton1Click)
            
            for i=1,3 do
            Continue = DialogueGui:WaitForChild("ClickContinue",1)
            task.wait(0.2)
            firesignal(Continue.MouseButton1Click)
            local Options = DialogueGui:WaitForChild("Options")
            local Option1 = Options:WaitForChild("Option1").TextButton
            if i == 3 then
            	local Option6 = Options:WaitForChild("Option6").TextButton
            	firesignal(Option6.MouseButton1Click)
            	else firesignal(Option1.MouseButton1Click)
            	end
            end
            
        end
    end
    ShowAutofarmingMessage.Text =`Currently Autofarming.\n———————————————————\nPickup speed: {getgenv().Settings.PickupDelay} seconds \nServer join time: {JoinTime} {os.date("%p")}\nServer Id: {game.JobId}\n Money made since join: ${tostring(math.clamp(GetCashSinceJoin(), 0, 9e9))}\nScript version: {getgenv().AutoHopVersion}`
end

-- Auto Sell Inventory Every 5 Seconds

task.spawn(function()
    while task.wait(5) do
        ProcessInventory()
    end
end)

local function Setup()
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        if tostring(self) == "Returner" and tostring(getnamecallmethod()) == "InvokeServer"
        then
            return "  ___XP DE KEY"
        end
        return old(self, ...)
    end)

    -- Prevent spawn distance checks
    local Vec3Metatable = getrawmetatable(Vector3.new())
    local oldIndex = Vec3Metatable.__index
    setreadonly(Vec3Metatable, false)
    Vec3Metatable.__index = newcclosure(function(self, idx)
        if string.lower(idx) == "magnitude" and getcallingscript() == ReplicatedFirst.ItemSpawn
        then
            return 0
        end
        return oldIndex(self, idx)
    end)
    setreadonly(Vec3Metatable, true)

    -- Rename Items based on their prompt text
    for _, Item in pairs(ItemSpawns:GetChildren()) do
        local prox = Item:WaitForChild("ProximityPrompt", 5)
        Item.Name = prox.ObjectText
    end

    -- Handle newly spawned Items
    ItemSpawns.ChildAdded:Connect(function(Item)
        print("new Item added to workspace")
        local prox = Item:WaitForChild("ProximityPrompt", 5)
        Item.Name = prox.ObjectText
        for _, v in pairs(ItemSpawns:GetDescendants()) do
            if v:IsA("ProximityPrompt") and v.MaxActivationDistance == 0 and v.Name ~= "Proximity Prompt __"
            then
                v.Name = "ProximityPrompt __"
            end
        end

        for _, v in pairs(ItemSpawns:GetChildren()) do
            if not v:FindFirstChild("ProximityPrompt") then
                v:Destroy()
            end
        end
    end)
    local Result = readfile("YBA_AUTOHOP/whitelistedAccs.txt")
    for i in string.gmatch(Result, "[^\r\n]+") do
        table.insert(AllowedAccounts, i)
    end
end
local function CheckForKickMsg()
    local Msg = CoreGui:FindFirstChild("RobloxPromptGui")
    if Msg and Msg:FindFirstChild("ErrorPrompt", true) then
        return true
    end
    return false
end

if not plr.Character:FindFirstChild("RemoteEvent") then
    task.wait(1)
end
plr.Character.RemoteEvent:FireServer("PressedPlay")

-- Kick if Prestige 3+ (possible main)
if plr.PlayerStats.Prestige.Value >= 3 and not table.find(AllowedAccounts, plr.Name) then
    WebhookHandler("prestige3")
    plr:Kick("MAIN ACC DETECTED!")
end
Setup()
print("ran Setup")
task.spawn(function()
    ItemCollectionConsole.Send(`Ran setup on server {game.JobId}!`, "ANNOUNCEMENT")
end)

local NotOnAlready = true
local LastPickupTime = tick()
ItemSpawns.ChildAdded:Connect(function(Item)
    repeat task.wait() until Item.Name ~= "Model" and NotOnAlready and not plr.Character.HumanoidRootPart.Anchored
    if getgenv().Settings.AutoFarm and Item.PrimaryPart and Item:FindFirstChild("ProximityPrompt __") then
        print(`-> picking up {Item.Name}!`)
        task.spawn(function()
            ItemCollectionConsole.Send(`picking up {Item.Name}!`, "ITEM_PICKUP")
        end)
        LastPickupTime = tick()
        NotOnAlready = false
        plr.Character.HumanoidRootPart.CFrame = Item.PrimaryPart.CFrame
        task.wait(getgenv().Settings.PickupDelay or 0.2)
        if Item then
            firesignal(Item:FindFirstChildWhichIsA("ProximityPrompt").Triggered)
        end
        spawn(function()
            task.wait((getgenv().Settings.PickupDelay or 0.2) + 0.5)
            if Item.Parent and Item then
                firesignal(Item:FindFirstChildWhichIsA("ProximityPrompt").Triggered)
                task.wait((getgenv().Settings.PickupDelay or 0.2) + 0.5)
                if Item.Parent then
                    Item.Parent = nil
                    task.spawn(function()
                        ItemCollectionConsole.Send(`{Item.Name} took too long to pick up.. deleting`,"ITEM_TIMEOUT")
                    end)
                end
            end
        end)
        Item.AncestryChanged:Wait()
        NotOnAlready = true
        plr.Character.HumanoidRootPart.CFrame = CFrame.new(-23, -33, 28)
    end
end)

PlrGui.ChildAdded:Connect(function(Thing)
    if Thing.Name == "Message" then
        task.wait()
        local ItemName = Thing:WaitForChild("TextLabel",1)
        if Thing then
            ItemName = ItemName.Text:match("%d+%s+(.+) in your inventory"):gsub("%(s%)$", "")
        end
        local Item = plr.Backpack:FindFirstChild(ItemName)
        if Item then
            Item.Parent = plr.Character
        end
        ProcessInventory()
        plr.Character.RemoteEvent:FireServer("EndDialogue", {
            NPC = "Merchant",
            Option = Option,
            Dialogue = "Dialogue5",
        })
    end
end)

plr.PlayerStats.Money.Changed:Connect(function()
    if not LuckyBought and plr.PlayerStats.Money.Value >= 75_000 then
        local NumberOfLuckyArrows = 0
        for _, v in pairs(plr.Backpack:GetChildren()) do
            if v.Name == "Lucky Arrow" then
                NumberOfLuckyArrows += 1
            end
        end
        if NumberOfLuckyArrows <= 8 then
            LuckyBought = true
            task.wait(1)
            plr.Character.RemoteEvent:FireServer(
                "PurchaseShopItem",
                { ItemName = "1x Lucky Arrow" }
            )
            WebhookHandler("LuckyArrow")
            local NameAndTime = `{plr.Name} {os.date("%I:%M %p")}\n`
            writefile(
                "YBA_AUTOHOP/Count.txt",
                readfile("YBA_AUTOHOP/Count.txt") .. NameAndTime
            )
        else
            LuckyBought = true
            if getgenv().Settings.PingOnLuckyArrow then
                warn(readfile("YBA_AUTOHOP/lastLucky.txt"))
                if readfile("YBA_AUTOHOP/lastLucky.txt") == plr.Name then
                else
                    WebhookHandler("LuckyArrow")
                end
            end
            Option = "Option1"
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if tick() - LastPickupTime > 5 * 2 or CheckForKickMsg() then
            task.spawn(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/Cesare0328/my-scripts/refs/heads/main/CachedServerhop.lua"))()
                task.wait(3)
            end)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Cesare0328/my-scripts/refs/heads/main/CachedServerhop.lua"))()
        end
    end
end)
