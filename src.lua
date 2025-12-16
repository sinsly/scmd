local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

local PREFIX = ";"

local function loadPrefix()
    local success, data = pcall(function()
        return readfile("SCMD_Prefix.json")
    end)
    if success then
        local parsed = HttpService:JSONDecode(data)
        if parsed and parsed.prefix then
            PREFIX = parsed.prefix
        end
    end
end
loadPrefix()

local COMMANDS = {
    prefix = {aliases = {}, description = "Set a custom command prefix", args = {";", ","}},
    rejoin = {aliases = {"rj"}, description = "Rejoins the current server"},
    serverhop = {aliases = {"shop","hop","sh"}, description = "Serverhop to another server", args = {"random","smallest","largest"}},
    fly = {aliases = {"fl"}, description = "Enables flying mode"},
    unfly = {aliases = {"uf"}, description = "Disables flying mode"},
    noclip = {aliases = {"nc"}, description = "Walk through objects"},
    clip = {aliases = {"cl"}, description = "Disable noclip"},
    dex = {aliases = {}, description = "Open Dark Dex"},
    rspy = {aliases = {}, description = "Open Remote Spy"},
}

local SORTED = {}
local COMMAND_LOOKUP = {}

for cmd, data in pairs(COMMANDS) do
    table.insert(SORTED, cmd)
    COMMAND_LOOKUP[cmd] = cmd
    for _, alias in ipairs(data.aliases) do
        COMMAND_LOOKUP[alias] = cmd
    end
end

table.sort(SORTED)

local gui = Instance.new("ScreenGui")
gui.Name = "scmd"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
pcall(function()
    gui.Parent = CoreGui
end)

local bar = Instance.new("Frame")
bar.Size = UDim2.fromOffset(420, 36)
bar.AnchorPoint = Vector2.new(1,1)
bar.Position = UDim2.new(1,-12,1,-12)
bar.BackgroundColor3 = Color3.fromRGB(20,20,20)
bar.BorderSizePixel = 0
bar.Parent = gui
Instance.new("UICorner", bar).CornerRadius = UDim.new(0,6)
Instance.new("UIStroke", bar).Color = Color3.fromRGB(45,45,45)

local box = Instance.new("TextBox")
box.Text = ""
box.Size = UDim2.new(1,-12,1,0)
box.Position = UDim2.new(0,6,0,0)
box.BackgroundTransparency = 1
box.ClearTextOnFocus = false
box.PlaceholderText = PREFIX.."command"
box.Font = Enum.Font.Code
box.TextSize = 16
box.TextColor3 = Color3.fromRGB(235,235,235)
box.PlaceholderColor3 = Color3.fromRGB(120,120,120)
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Center
box.Parent = bar

local preview = Instance.new("Frame")
preview.Size = UDim2.fromOffset(420,0)
preview.AnchorPoint = Vector2.new(1,1)
preview.Position = UDim2.new(1,-12,1,-52)
preview.BackgroundColor3 = Color3.fromRGB(20,20,20)
preview.BorderSizePixel = 0
preview.ClipsDescendants = true
preview.Visible = false
preview.Parent = gui
Instance.new("UICorner", preview).CornerRadius = UDim.new(0,6)
Instance.new("UIStroke", preview).Color = Color3.fromRGB(45,45,45)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,4)
layout.Parent = preview

local tooltip = Instance.new("TextLabel")
tooltip.Visible = false
tooltip.BackgroundColor3 = Color3.fromRGB(30,30,30)
tooltip.TextColor3 = Color3.fromRGB(230,230,230)
tooltip.Font = Enum.Font.Code
tooltip.TextSize = 13
tooltip.TextWrapped = true
tooltip.BorderSizePixel = 0
tooltip.ZIndex = 10
tooltip.Parent = gui
Instance.new("UICorner", tooltip).CornerRadius = UDim.new(0,6)
Instance.new("UIStroke", tooltip).Color = Color3.fromRGB(60,60,60)

local function clearPreview()
    for _,v in ipairs(preview:GetChildren()) do
        if v:IsA("TextLabel") then
            v:Destroy()
        end
    end
end

local function resizePreview(count)
    if count == 0 then
        preview.Visible = false
        TweenService:Create(preview, TweenInfo.new(0.15), {
            Size = UDim2.fromOffset(420,0)
        }):Play()
        return
    end
    preview.Visible = true
    TweenService:Create(preview, TweenInfo.new(0.15), {
        Size = UDim2.fromOffset(420, count * 30 + 6)
    }):Play()
end

local function update(text, allowAutocomplete)
    allowAutocomplete = allowAutocomplete ~= false
    clearPreview()

    if text == "" then
        resizePreview(0)
        return
    end

    local query = text:sub(1,#PREFIX) == PREFIX and text:sub(#PREFIX+1):lower() or ""
    local words = {}
    for w in query:gmatch("%S+") do
        table.insert(words, w)
    end

    local rawCmd = words[1] or ""
    local argQuery = words[2] or ""
    local mainCmd = COMMAND_LOOKUP[rawCmd]

    if allowAutocomplete and mainCmd and rawCmd ~= mainCmd then
        box.Text = PREFIX .. mainCmd .. (argQuery ~= "" and " "..argQuery or "")
        box.CursorPosition = #box.Text + 1
    end

    local totalLines = 0

    for _,cmd in ipairs(SORTED) do
        if rawCmd == "" or cmd:sub(1,#rawCmd) == rawCmd then
            local item = Instance.new("TextLabel")
            item.Size = UDim2.new(1,-10,0,26)
            item.BackgroundColor3 = Color3.fromRGB(28,28,28)
            item.Text = cmd
            item.Font = Enum.Font.Code
            item.TextSize = 14
            item.TextXAlignment = Enum.TextXAlignment.Left
            item.TextYAlignment = Enum.TextYAlignment.Center
            item.TextColor3 = Color3.fromRGB(220,220,220)
            item.BorderSizePixel = 0
            item.Parent = preview
            Instance.new("UIPadding", item).PaddingLeft = UDim.new(0,10)
            totalLines += 1

            item.MouseEnter:Connect(function()
                local data = COMMANDS[cmd]
                tooltip.Text = data.description .. "\nAliases: " .. table.concat(data.aliases, ", ")
                tooltip.Size = UDim2.fromOffset(260,36)
                tooltip.Position = UDim2.fromOffset(item.AbsolutePosition.X - 270, item.AbsolutePosition.Y)
                tooltip.Visible = true
            end)

            item.MouseLeave:Connect(function()
                tooltip.Visible = false
            end)

            if mainCmd == cmd and COMMANDS[cmd].args then
                for _,arg in ipairs(COMMANDS[cmd].args) do
                    if argQuery == "" or arg:sub(1,#argQuery) == argQuery then
                        local argItem = Instance.new("TextLabel")
                        argItem.Size = UDim2.new(1,-10,0,26)
                        argItem.BackgroundColor3 = Color3.fromRGB(35,35,35)
                        argItem.Text = "  "..arg
                        argItem.Font = Enum.Font.Code
                        argItem.TextSize = 14
                        argItem.TextXAlignment = Enum.TextXAlignment.Left
                        argItem.TextYAlignment = Enum.TextYAlignment.Center
                        argItem.TextColor3 = Color3.fromRGB(200,200,200)
                        argItem.BorderSizePixel = 0
                        argItem.Parent = preview
                        Instance.new("UIPadding", argItem).PaddingLeft = UDim.new(0,20)
                        totalLines += 1
                    end
                end
            end
        end
    end

    resizePreview(totalLines)
end

local prevLen = 0
box:GetPropertyChangedSignal("Text"):Connect(function()
    local len = #box.Text
    update(box.Text, len >= prevLen)
    prevLen = len
end)

UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.Semicolon or i.KeyCode == Enum.KeyCode.Comma then
        local c = i.KeyCode == Enum.KeyCode.Semicolon and ";" or ","
        task.wait()
        box:CaptureFocus()
        box.Text = c
        box.CursorPosition = 2
        update(c,true)
    end
end)

box.FocusLost:Connect(function(enter)
    if not enter then return end
    local text = box.Text
    box.Text = ""
    update("",false)

    if text:sub(1,#PREFIX) ~= PREFIX then return end

    local args = {}
    for w in text:sub(#PREFIX+1):gmatch("%S+") do
        table.insert(args,w)
    end

    local cmd = COMMAND_LOOKUP[args[1] or ""]

    if cmd == "prefix" and args[2] then
        PREFIX = args[2]
        writefile("SCMD_Prefix.json", HttpService:JSONEncode({prefix = PREFIX}))
        box.PlaceholderText = PREFIX.."command"

    elseif cmd == "dex" then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/sinsly/exploit-tools/main/v4-darkdex.lua"))()

    elseif cmd == "rspy" then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/sinsly/exploit-tools/main/remotespy.lua"))()
    end
end)
