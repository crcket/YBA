getgenv().Settings = {
    AutoFarm = true; -- Whether or not the script is activated
    SellAll = true; -- Sells items every 5 seconds
    PickupDelay = 0.165; -- Recommeded lowest is 0.165 and highest is 0.25
    PingOnLuckyArrow = true; -- Pings your discord account when you reach 9 lucky arrows
    LowGFX = true; -- Disables 3D rendering if true
    DiscordID = YOURDISCORDIDHERE; -- The discord id you want to be pinged once your account gets a lucky arrow
    DevMode = false; -- Developer mode — includes potentially buggy and unreleased features
    URL = "DISCORDWEBHOOKHERE"
}
loadstring(request({Url = "https://raw.githubusercontent.com/crcket/YBA/refs/heads/main/AutoHop_Centralized.lua"}).Body)()