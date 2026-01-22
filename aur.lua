local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local FIREBASE_URL = "https://karim-notifier-default-rtdb.europe-west1.firebasedatabase.app/history.json"
local PLACE_ID = 109983668079237 

local AutoJoinEnabled = false
local ActivationTime = 0 

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SAB_Elite_Radar_Final"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

-- وظيفة السحب
local function makeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- الأيقونة
local IconBtn = Instance.new("TextButton")
IconBtn.Size = UDim2.new(0, 50, 0, 50)
IconBtn.Position = UDim2.new(0, 10, 0.5, 0)
IconBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
IconBtn.Text = "⚡"
IconBtn.TextSize = 25
IconBtn.TextColor3 = Color3.new(1,1,1)
IconBtn.Parent = ScreenGui
Instance.new("UICorner", IconBtn).CornerRadius = UDim.new(1, 0)
makeDraggable(IconBtn, IconBtn)

-- اللوحة الرئيسية
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 400)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- الرأس (Header)
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Header.Parent = MainFrame
Instance.new("UICorner", Header)
makeDraggable(MainFrame, Header)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "SAB RADAR V6"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- زر Auto Join
local AutoJoinBtn = Instance.new("TextButton")
AutoJoinBtn.Size = UDim2.new(1, -20, 0, 35)
AutoJoinBtn.Position = UDim2.new(0, 10, 0, 50)
AutoJoinBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
AutoJoinBtn.Text = "AUTO JOIN: OFF"
AutoJoinBtn.TextColor3 = Color3.new(1,1,1)
AutoJoinBtn.Font = Enum.Font.GothamBold
AutoJoinBtn.Parent = MainFrame
Instance.new("UICorner", AutoJoinBtn)

AutoJoinBtn.MouseButton1Click:Connect(function()
    AutoJoinEnabled = not AutoJoinEnabled
    if AutoJoinEnabled then
        ActivationTime = os.time() * 1000 
        AutoJoinBtn.Text = "AUTO JOIN: ON"
        AutoJoinBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 70)
    else
        AutoJoinBtn.Text = "AUTO JOIN: OFF"
        AutoJoinBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    end
end)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -35, 0, 5)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.new(1,1,1)
MinBtn.Parent = Header

-- القائمة
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -110)
Scroll.Position = UDim2.new(0, 10, 0, 95)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 2
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = MainFrame
Instance.new("UIListLayout", Scroll).Padding = UDim.new(0, 8)

local function refreshData()
    local success, response = pcall(function() return game:HttpGet(FIREBASE_URL) end)
    if success and response ~= "null" then
        local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(response) end)
        if not decodeSuccess then return end
        
        -- مسح القائمة الحالية (تذكر طلبك لمسح البيانات تلقائياً)
        for _, v in pairs(Scroll:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
        
        local list = {}
        for _, v in pairs(data) do table.insert(list, v) end
        table.sort(list, function(a,b) return a.time > b.time end)
        
        for i, item in ipairs(list) do
            -- عرض آخر دقيقتين فقط
            if (os.time() * 1000 - item.time) > 120000 then continue end
            
            local content = tostring(item.content)
            
            -- استخراج JobId
            local jobId = string.match(content, "%x+-%x+-%x+-%x+-%x+")
            
            -- تنظيف النص للعرض (إزالة سطر JobId)
            local displayContent = content:gsub("JobId:[^\n]*", "")
            
            if AutoJoinEnabled and jobId and item.time > ActivationTime then
                TeleportService:TeleportToPlaceInstance(PLACE_ID, jobId, LocalPlayer)
                return 
            end

            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -5, 0, 0)
            row.AutomaticSize = Enum.AutomaticSize.Y
            row.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            row.Parent = Scroll
            Instance.new("UICorner", row)
            
            local txt = Instance.new("TextLabel")
            txt.Size = UDim2.new(0.7, 0, 0, 0)
            txt.AutomaticSize = Enum.AutomaticSize.Y
            txt.Position = UDim2.new(0, 10, 0, 8)
            txt.BackgroundTransparency = 1
            txt.Text = displayContent
            txt.TextColor3 = Color3.new(1,1,1)
            txt.TextSize = 12
            txt.TextWrapped = true
            txt.Font = Enum.Font.GothamMedium
            txt.TextXAlignment = Enum.TextXAlignment.Left
            txt.Parent = row
            
            if jobId then
                local jb = Instance.new("TextButton")
                jb.Size = UDim2.new(0.25, 0, 0, 30)
                jb.Position = UDim2.new(0.72, 0, 0.5, -15)
                jb.BackgroundColor3 = Color3.fromRGB(0, 120, 60)
                jb.Text = "JOIN"
                jb.TextColor3 = Color3.new(1,1,1)
                jb.Font = Enum.Font.GothamBold
                jb.Parent = row
                Instance.new("UICorner", jb)
                
                jb.MouseButton1Click:Connect(function()
                    TeleportService:TeleportToPlaceInstance(PLACE_ID, jobId, LocalPlayer)
                end)
            end
            
            local p = Instance.new("UIPadding", row)
            p.PaddingBottom = UDim.new(0, 10)
            p.PaddingTop = UDim.new(0, 5)
        end
    end
end

IconBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    IconBtn.Visible = false
    refreshData()
end)

MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    IconBtn.Visible = true
    -- مسح البيانات المعروضة عند التصغير للخصوصية وسرعة الهاتف
    for _, v in pairs(Scroll:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
end)

task.spawn(function()
    while true do
        if MainFrame.Visible or AutoJoinEnabled then refreshData() end
        task.wait(2)
    end
end)
