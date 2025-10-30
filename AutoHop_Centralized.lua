local GithubChecker = loadstring(game:HttpGet("https://raw.githubusercontent.com/crcket/ROBLOX/refs/heads/main/GithubSHAChecker.lua"))()
local CheckFunc = GithubChecker.CheckGithubSHA
local ExecuteUrl = "https://raw.githubusercontent.com/crcket/YBA/refs/heads/main/AutoHop.lua"
if getgenv().Settings.DevMode then
    ExecuteUrl = "https://raw.githubusercontent.com/crcket/YBA/refs/heads/main/AutoHopInDev.lua"
else
    ExecuteUrl = "https://raw.githubusercontent.com/crcket/YBA/refs/heads/main/AutoHop.lua" -- redundancy
end
getgenv().AutoHopVersion = CheckFunc(ExecuteUrl)
loadstring(request({Url = ExecuteUrl}).Body)()
