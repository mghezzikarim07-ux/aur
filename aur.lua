local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local FIREBASE_URL = "https://karim-notifier-default-rtdb.europe-west1.firebasedatabase.app/history.json"
local PLACE_ID = 109983668079237 
local MIN_THRESHOLD = 6.0 

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SAB_Elite_Radar_V3"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

-- وظيفة السحب (Dragging)
local function makeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- الأيقونة
local IconBtn = Instance.new("TextButton")
IconBtn.Size = UDim2.new(0, 60, 0, 60)
IconBtn.Position = UDim2.new(0, 20, 0.5, 0)
IconBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
IconBtn.Text = "💎"
IconBtn.TextSize = 30
IconBtn.TextColor3 = Color3.new(1,1,1)
IconBtn.Parent = ScreenGui
Instance.new("UICorner", IconBtn).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", IconBtn).Color = Color3.fromRGB(255, 215, 0)
makeDraggable(IconBtn, IconBtn)

-- اللوحة الرئيسية
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 430)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -215)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(45, 45, 45)

-- الرأس (Header)
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Header.Parent = MainFrame
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)
makeDraggable(MainFrame, Header)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "ELITE SERVER RADAR"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -38, 0, 7)
MinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.new(1,1,1)
MinBtn.Parent = Header
Instance.new("UICorner", MinBtn)

-- القائمة
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -65)
Scroll.Position = UDim2.new(0, 10, 0, 55)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 2
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = MainFrame
Instance.new("UIListLayout", Scroll).Padding = UDim.new(0, 10)

-- الوظائف البرمجية
local function isServerWorthIt(fullText)
    for valueStr in string.gmatch(fullText, "%((%d+%.?%d*)M/s%)") do
        if tonumber(valueStr) and tonumber(valueStr) >= MIN_THRESHOLD then return true end
    end
    return false
end

local function cleanFinalText(fullText)
    local startIdx = string.find(fullText, "Objects:")
    local endIdx = string.find(fullText, "Teleport code:")
    local result = ""
    if startIdx and endIdx then result = string.sub(fullText, startIdx + 8, endIdx - 1)
    elseif startIdx then result = string.sub(fullText, startIdx + 8)
    else result = fullText end
    result = result:gsub("^[%s:]+", "")
    return result:match("^%s*(.-)%s*$") or "No Items Found"
end

local function refreshData()
    local success, response = pcall(function() return game:HttpGet(FIREBASE_URL) end)
    if success and response ~= "null" then
        local data = HttpService:JSONDecode(response)
        for _, v in pairs(Scroll:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
        
        local list = {}
        for _, v in pairs(data) do 
            if isServerWorthIt(v.content) then table.insert(list, v) end
        end
        table.sort(list, function(a,b) return a.time > b.time end)
        
        for i, item in ipairs(list) do
            if (os.time() * 1000 - item.time) > 120000 then continue end
            
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -5, 0, 0)
            row.AutomaticSize = Enum.AutomaticSize.Y
            row.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            row.Parent = Scroll
            Instance.new("UICorner", row)
            
            local txt = Instance.new("TextLabel")
            txt.Size = UDim2.new(1, -20, 0, 0)
            txt.AutomaticSize = Enum.AutomaticSize.Y
            txt.Position = UDim2.new(0, 10, 0, 10)
            txt.BackgroundTransparency = 1
            txt.Text = cleanFinalText(tostring(item.content))
            txt.TextColor3 = Color3.fromRGB(255, 215, 0)
            txt.TextWrapped = true
            txt.Font = Enum.Font.GothamMedium
            txt.TextSize = 15
            txt.TextXAlignment = Enum.TextXAlignment.Left
            txt.Parent = row
            
            local jobId = string.match(item.content, "%w+-%w+-%w+-%w+-%w+")
            if jobId then
                local joinBtn = Instance.new("TextButton")
                joinBtn.Size = UDim2.new(0.9, 0, 0, 32)
                joinBtn.Position = UDim2.new(0.05, 0, 1, 5)
                joinBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 70)
                joinBtn.Text = "JOIN SERVER"
                joinBtn.TextColor3 = Color3.new(1,1,1)
                joinBtn.Font = Enum.Font.GothamBold
                joinBtn.Parent = row
                Instance.new("UICorner", joinBtn)
                
                local p = Instance.new("UIPadding", row)
                p.PaddingBottom = UDim.new(0, 45)

                joinBtn.MouseButton1Click:Connect(function()
                    TeleportService:TeleportToPlaceInstance(PLACE_ID, jobId, LocalPlayer)
                end)
            else
                Instance.new("UIPadding", row).PaddingBottom = UDim.new(0, 10)
            end
        end
    end
end

-- التحكم بالواجهة
IconBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    IconBtn.Visible = false
    refreshData()
end)

MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    IconBtn.Visible = true
end)

-- تحديث تلقائي
task.spawn(function()
    while true do
        if MainFrame.Visible then refreshData() end
        task.wait(1)
    end
end)
