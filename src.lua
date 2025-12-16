local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local scmd = {}
scmd.__index = scmd

function scmd.create()
    local self = setmetatable({}, scmd)
    self.PREFIX = ";"
    self:LoadPrefix()
    self.COMMANDS = {
        prefix = {aliases = {}, description = "Set a custom command prefix", args = {";", ","}},
        rejoin = {aliases = {"rj"}, description = "Rejoins the current server"},
        serverhop = {aliases = {"shop","hop","sh"}, description = "Serverhop to another server", args = {"random", "smallest", "largest"}},
        reset    = {aliases = {"rs"}, description = "Resets your character"},
        refresh  = {aliases = {"rf"}, description = "Refreshes your character"},
        respawn  = {aliases = {"resp"}, description = "Respawns your character"},
        fly      = {aliases = {"fl"}, description = "Enables flying mode"},
        unfly    = {aliases = {"uf"}, description = "Disables flying mode"},
        noclip   = {aliases = {"nc"}, description = "Walk through objects"},
        clip     = {aliases = {"cl"}, description = "Disable noclip"},
        speed    = {aliases = {"spd"}, description = "Change walk speed"},
        jump     = {aliases = {"jp"}, description = "Change jump power"},
        bring    = {aliases = {"b"}, description = "Bring a player to you"},
        tp       = {aliases = {"t"}, description = "Teleport to a location"},
        sit      = {aliases = {"st"}, description = "Sit your character"},
        unsit    = {aliases = {"ust"}, description = "Stand up"}
    }
    self.SORTED = {}
    self.COMMAND_LOOKUP = {}
    for cmdName, data in pairs(self.COMMANDS) do
        table.insert(self.SORTED, cmdName)
        self.COMMAND_LOOKUP[cmdName] = cmdName
        for _, alias in ipairs(data.aliases) do
            self.COMMAND_LOOKUP[alias] = cmdName
        end
    end
    table.sort(self.SORTED)
    self:CreateGUI()
    return self
end

function scmd:LoadPrefix()
    local success, data = pcall(function() return readfile("SCMD_Prefix.json") end)
    if success then
        local parsed = HttpService:JSONDecode(data)
        if parsed and parsed.prefix then
            self.PREFIX = parsed.prefix
        end
    end
end

function scmd:CreateGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "sinsly_cmd"
    gui.ResetOnSpawn = false
    gui.Parent = game:GetService("CoreGui")
    self.gui = gui

    local bar = Instance.new("Frame")
    bar.Size = UDim2.fromOffset(420, 36)
    bar.AnchorPoint = Vector2.new(1,1)
    bar.Position = UDim2.new(1,-12,1,-12)
    bar.BackgroundColor3 = Color3.fromRGB(20,20,20)
    bar.BorderSizePixel = 0
    bar.Parent = gui
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0,6)
    Instance.new("UIStroke", bar).Color = Color3.fromRGB(45,45,45)
    self.bar = bar

    local box = Instance.new("TextBox")
    box.Text = ""
    box.Size = UDim2.new(1,-12,1,0)
    box.Position = UDim2.new(0,6,0,0)
    box.BackgroundTransparency = 1
    box.ClearTextOnFocus = false
    box.PlaceholderText = self.PREFIX.."command"
    box.Font = Enum.Font.Code
    box.TextSize = 16
    box.TextColor3 = Color3.fromRGB(235,235,235)
    box.PlaceholderColor3 = Color3.fromRGB(120,120,120)
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.TextYAlignment = Enum.TextYAlignment.Center
    box.Parent = bar
    self.box = box

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
    self.preview = preview

    local layout = Instance.new("UIListLayout", preview)
    layout.Padding = UDim.new(0,4)

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
    self.tooltip = tooltip

    self.prevLength = 0
    self:ConnectEvents()
end

function scmd:ClearPreview()
    for _,v in ipairs(self.preview:GetChildren()) do
        if v:IsA("TextLabel") then v:Destroy() end
    end
end

function scmd:ResizePreview(count)
    if count == 0 then
        self.preview.Visible = false
        TweenService:Create(self.preview,TweenInfo.new(0.15),{Size = UDim2.fromOffset(420,0)}):Play()
        return
    end
    self.preview.Visible = true
    TweenService:Create(self.preview,TweenInfo.new(0.15),{Size = UDim2.fromOffset(420, count * 30 + 6)}):Play()
end

function scmd:Update(text, allowAutocomplete)
    allowAutocomplete = allowAutocomplete ~= false
    self:ClearPreview()
    if text == "" then self:ResizePreview(0) return end
    local query = text:sub(1,#self.PREFIX) == self.PREFIX and text:sub(#self.PREFIX+1):lower() or text:lower()
    local words = {}
    for word in query:gmatch("%S+") do table.insert(words, word) end
    local cmdQuery = words[1] or ""
    local argQuery = words[2] or ""

    if allowAutocomplete and cmdQuery ~= "" and self.COMMAND_LOOKUP[cmdQuery] then
        local mainCmd = self.COMMAND_LOOKUP[cmdQuery]
        if words[1]:lower() ~= mainCmd then
            cmdQuery = mainCmd
            self.box.Text = self.PREFIX .. cmdQuery .. " " .. (words[2] and words[2] or "")
            self.box.CursorPosition = #self.box.Text + 1
        end
    end

    local matches = {}
    for alias, main in pairs(self.COMMAND_LOOKUP) do
        if cmdQuery == "" or main:sub(1,#cmdQuery) == cmdQuery then
            if not table.find(matches, main) then table.insert(matches, main) end
        end
    end

    local totalLines = 0
    for _,cmdName in ipairs(matches) do
        local item = Instance.new("TextLabel")
        item.Size = UDim2.new(1,-10,0,26)
        item.BackgroundColor3 = Color3.fromRGB(28,28,28)
        item.Text = cmdName
        item.Font = Enum.Font.Code
        item.TextSize = 14
        item.TextXAlignment = Enum.TextXAlignment.Left
        item.TextYAlignment = Enum.TextYAlignment.Center
        item.TextColor3 = Color3.fromRGB(220,220,220)
        item.BorderSizePixel = 0
        item.Parent = self.preview
        local pad = Instance.new("UIPadding", item)
        pad.PaddingLeft = UDim.new(0,10)

        item.MouseEnter:Connect(function()
            local desc = self.COMMANDS[cmdName].description
            local aliases = table.concat(self.COMMANDS[cmdName].aliases, ", ")
            self.tooltip.Text = desc .. "\nAliases: " .. aliases
            self.tooltip.Size = UDim2.fromOffset(260, 36)
            self.tooltip.Position = UDim2.fromOffset(item.AbsolutePosition.X - 270, item.AbsolutePosition.Y)
            self.tooltip.Visible = true
        end)
        item.MouseLeave:Connect(function() self.tooltip.Visible = false end)

        totalLines += 1

        if cmdName == cmdQuery and self.COMMANDS[cmdName].args then
            local argMatches = {}
            for _,arg in ipairs(self.COMMANDS[cmdName].args) do
                if argQuery == "" or arg:sub(1,#argQuery) == argQuery then
                    table.insert(argMatches, arg)
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
                    argItem.Parent = self.preview
                    local pad = Instance.new("UIPadding", argItem)
                    pad.PaddingLeft = UDim.new(0,20)
                    totalLines += 1
                end
            end
            if allowAutocomplete and #argMatches == 1 then
                self.box.Text = self.PREFIX .. cmdName .. " " .. argMatches[1] .. " "
                self.box.CursorPosition = #self.box.Text + 1
            end
        end
    end
    self:ResizePreview(totalLines)
end

function scmd:ConnectEvents()
    self.box:GetPropertyChangedSignal("Text"):Connect(function()
        local currentLength = #self.box.Text
        local isDeleting = currentLength < self.prevLength
        self.prevLength = currentLength
        self:Update(self.box.Text, not isDeleting)
    end)
    self.box.FocusLost:Connect(function()
        self.box.Text = ""
        self:Update("", false)
    end)

    local KEY_NAMES = {[";"] = "Semicolon", [","] = "Comma"}
    UIS.InputBegan:Connect(function(i, gp)
        if gp then return end
        for prefixChar,_ in pairs(KEY_NAMES) do
            if i.KeyCode == Enum.KeyCode[KEY_NAMES[prefixChar]] then
                task.wait()
                self.box:CaptureFocus()
                self.box.Text = prefixChar
                self.box.CursorPosition = #self.box.Text + 1
                self:Update(prefixChar)
                break
            end
        end
    end)

    self.box.FocusLost:Connect(function(enterPressed)
        local text = self.box.Text
        if enterPressed and text:sub(1,#self.PREFIX) == self.PREFIX then
            local input = text:sub(#self.PREFIX+1)
            local args = {}
            for word in input:gmatch("%S+") do table.insert(args, word) end
            local cmdName = args[1]
            if cmdName and self.COMMAND_LOOKUP[cmdName] == "prefix" and args[2] then
                self.PREFIX = args[2]
                writefile("SCMD_Prefix.json", HttpService:JSONEncode({prefix = self.PREFIX}))
                self.box.PlaceholderText = self.PREFIX.."command"
            end
        end
    end)
end

return scmd
