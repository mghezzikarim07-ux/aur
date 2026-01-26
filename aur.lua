local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- الرابط بدون إضافات لتجنب مشاكل الفلترة
local FIREBASE_URL = "https://karim-notifier-default-rtdb.europe-west1.firebasedatabase.app/history.json"
local PLACE_ID = 109983668079237 

local AutoJoinEnabled = false
local LastJobId = "" 

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SAB_Final_Fix_v2"
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

local IconBtn = Instance.new("TextButton")
IconBtn.Size = UDim2.new(0, 50, 0, 50)
IconBtn.Position = UDim2.new(0, 10, 0.5, 0)
IconBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
IconBtn.Text = "📡"
IconBtn.TextColor3 = Color3.new(1,1,1)
IconBtn.TextSize = 25
IconBtn.Parent = ScreenGui
Instance.new("UICorner", IconBtn).CornerRadius = UDim.new(1, 0)
makeDraggable(IconBtn, IconBtn)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 350)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame)

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 35)
Header.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Header.Parent = MainFrame
Instance.new("UICorner", Header)
makeDraggable(MainFrame, Header)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "SAB RADAR FIXED"
Title.TextColor3 = Color3.new(1,1,1)
Title.Parent = Header

local AutoJoinBtn = Instance.new("TextButton")
AutoJoinBtn.Size = UDim2.new(1, -20, 0, 40)
AutoJoinBtn.Position = UDim2.new(0, 10, 0, 45)
AutoJoinBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
AutoJoinBtn.Text = "AUTO JOIN: OFF"
AutoJoinBtn.Font = Enum.Font.GothamBold
AutoJoinBtn.TextColor3 = Color3.new(1,1,1)
AutoJoinBtn.Parent = MainFrame
Instance.new("UICorner", AutoJoinBtn)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -100)
Scroll.Position = UDim2.new(0, 10, 0, 95)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 2
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = MainFrame
Instance.new("UIListLayout", Scroll).Padding = UDim.new(0, 5)

local function refreshData()
    -- طلب البيانات بشكل مباشر لتجنب مشاكل الفهرسة (Index Errors)
    local success, response = pcall(function() 
        return game:HttpGet(FIREBASE_URL) 
    end)
    
    if success and response ~= "null" then
        local data = HttpService:JSONDecode(response)
        local list = {}
        
        -- تحويل البيانات لجدول مرتب
        for k, v in pairs(data) do 
            v.id = k 
            table.insert(list, v) 
        end
        table.sort(list, function(a,b) return a.time > b.time end)
        
        -- تنظيف القائمة وعرض الإشعارات (مسح البيانات القديمة لضمان الأداء)
        Scroll:ClearAllChildren()
        local layout = Instance.new("UIListLayout", Scroll)
        layout.Padding = UDim.new(0, 5)

        for i, item in ipairs(list) do
            if i > 5 then break end -- عرض آخر 5 فقط لتوفير الموارد
            
            local jobId = string.match(item.content, "%x+-%x+-%x+-%x+-%x+")
            local displayContent = item.content:gsub("JobId:[^\n]*", "")

            -- منطق الـ Auto Join: يعمل فقط مع أحدث إشعار (الأول في القائمة)
            if AutoJoinEnabled and jobId and i == 1 then
                if jobId ~= LastJobId then
                    LastJobId = jobId
                    task.spawn(function()
                        TeleportService:TeleportToPlaceInstance(PLACE_ID, jobId, LocalPlayer)
                    end)
                end
            end

            -- تصميم الصفوف
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 45)
            row.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            row.Parent = Scroll
            Instance.new("UICorner", row)

            local txt = Instance.new("TextLabel")
            txt.Size = UDim2.new(0.7, 0, 1, 0)
            txt.Position = UDim2.new(0, 10, 0, 0)
            txt.Text = displayContent
            txt.TextColor3 = Color3.new(1,1,1)
            txt.TextSize = 11
            txt.TextWrapped = true
            txt.BackgroundTransparency = 1
            txt.TextXAlignment = Enum.TextXAlignment.Left
            txt.Parent = row

            if jobId then
                local jb = Instance.new("TextButton")
                jb.Size = UDim2.new(0, 60, 0, 30)
                jb.Position = UDim2.new(1, -65, 0.5, -15)
                jb.Text = "JOIN"
                jb.BackgroundColor3 = Color3.fromRGB(0, 150, 70)
                jb.TextColor3 = Color3.new(1,1,1)
                jb.Parent = row
                Instance.new("UICorner", jb)
                jb.MouseButton1Click:Connect(function()
                    TeleportService:TeleportToPlaceInstance(PLACE_ID, jobId, LocalPlayer)
                end)
            end
        end
    end
end

AutoJoinBtn.MouseButton1Click:Connect(function()
    AutoJoinEnabled = not AutoJoinEnabled
    if AutoJoinEnabled then
        AutoJoinBtn.Text = "AUTO JOIN: ON"
        AutoJoinBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 70)
        LastJobId = "STARTUP" -- لكي لا يدخل أول سيرفر موجود مسبقاً فوراً
    else
        AutoJoinBtn.Text = "AUTO JOIN: OFF"
        AutoJoinBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    end
end)

IconBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

-- حلقة التكرار
task.spawn(function()
    while true do
        refreshData()
        task.wait(1.5) -- وقت متوازن لتجنب الـ Limits وضمان السرعة
    end
end)
