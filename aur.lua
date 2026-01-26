local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local FIREBASE_URL = "https://karim-notifier-default-rtdb.europe-west1.firebasedatabase.app/history.json"
local PLACE_ID = 109983668079237 

local AutoJoinEnabled = false
local LastJobId = "" 

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SAB_MultiLine_Radar"
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
IconBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
IconBtn.Text = "📡"
IconBtn.TextSize = 25
IconBtn.Parent = ScreenGui
Instance.new("UICorner", IconBtn).CornerRadius = UDim.new(1, 0)
makeDraggable(IconBtn, IconBtn)

-- اللوحة
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 380)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame)

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 35)
Header.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Header.Parent = MainFrame
Instance.new("UICorner", Header)
makeDraggable(MainFrame, Header)

local AutoJoinBtn = Instance.new("TextButton")
AutoJoinBtn.Size = UDim2.new(1, -20, 0, 40)
AutoJoinBtn.Position = UDim2.new(0, 10, 0, 45)
AutoJoinBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
AutoJoinBtn.Text = "AUTO JOIN: OFF"
AutoJoinBtn.TextColor3 = Color3.new(1,1,1)
AutoJoinBtn.Font = Enum.Font.GothamBold
AutoJoinBtn.Parent = MainFrame
Instance.new("UICorner", AutoJoinBtn)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -100)
Scroll.Position = UDim2.new(0, 10, 0, 95)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 3
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y -- هذا يضمن تمدد القائمة للأسفل
Scroll.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.Parent = Scroll
UIList.Padding = UDim.new(0, 8)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

local function refreshData()
    local success, response = pcall(function() return game:HttpGet(FIREBASE_URL) end)
    
    if success and response ~= "null" then
        local data = HttpService:JSONDecode(response)
        local list = {}
        for k, v in pairs(data) do table.insert(list, v) end
        table.sort(list, function(a,b) return a.time > b.time end)
        
        -- مسح البيانات القديمة لضمان الخصوصية وسرعة الجهاز (طلبك السابق)
        for _, child in pairs(Scroll:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end

        for i, item in ipairs(list) do
            if i > 8 then break end -- عرض آخر 8 إشعارات فقط لتقليل الـ Lag
            
            local jobId = string.match(item.content, "%x+-%x+-%x+-%x+-%x+")
            local displayContent = item.content:gsub("JobId:[^\n]*", ""):trim()

            -- نظام الـ Auto Join
            if AutoJoinEnabled and jobId and i == 1 then
                if jobId ~= LastJobId then
                    LastJobId = jobId
                    task.spawn(function()
                        TeleportService:TeleportToPlaceInstance(PLACE_ID, jobId, LocalPlayer)
                    end)
                end
            end

            -- حاوية الإشعار (تتمدد تلقائياً للأسفل)
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -5, 0, 0)
            row.AutomaticSize = Enum.AutomaticSize.Y
            row.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            row.Parent = Scroll
            Instance.new("UICorner", row)
            
            local txt = Instance.new("TextLabel")
            txt.Size = UDim2.new(0.7, 0, 0, 0)
            txt.Position = UDim2.new(0, 10, 0, 8)
            txt.AutomaticSize = Enum.AutomaticSize.Y -- السماح للنص بالتمدد رأسياً
            txt.BackgroundTransparency = 1
            txt.Text = displayContent
            txt.TextColor3 = Color3.new(1,1,1)
            txt.TextSize = 12
            txt.RichText = true -- لدعم الرموز بشكل أفضل
            txt.TextWrapped = true -- أهم خاصية لدعم تعدد الأسطر
            txt.TextXAlignment = Enum.TextXAlignment.Left
            txt.TextYAlignment = Enum.TextYAlignment.Top
            txt.Font = Enum.Font.GothamMedium
            txt.Parent = row

            if jobId then
                local jb = Instance.new("TextButton")
                jb.Size = UDim2.new(0, 65, 0, 35)
                jb.Position = UDim2.new(1, -70, 0, 5)
                jb.Text = "JOIN"
                jb.BackgroundColor3 = Color3.fromRGB(0, 150, 70)
                jb.TextColor3 = Color3.new(1,1,1)
                jb.Font = Enum.Font.GothamBold
                jb.Parent = row
                Instance.new("UICorner", jb)
                jb.MouseButton1Click:Connect(function()
                    TeleportService:TeleportToPlaceInstance(PLACE_ID, jobId, LocalPlayer)
                end)
            end
            
            -- إضافة مساحة بسيطة في أسفل كل صف لضمان عدم تداخل الأسطر
            local padding = Instance.new("UIPadding", row)
            padding.PaddingBottom = UDim.new(0, 10)
        end
    end
end

AutoJoinBtn.MouseButton1Click:Connect(function()
    AutoJoinEnabled = not AutoJoinEnabled
    AutoJoinBtn.Text = AutoJoinEnabled and "AUTO JOIN: ON" or "AUTO JOIN: OFF"
    AutoJoinBtn.BackgroundColor3 = AutoJoinEnabled and Color3.fromRGB(0, 150, 70) or Color3.fromRGB(180, 0, 0)
    if AutoJoinEnabled then LastJobId = "STARTUP" end
end)

IconBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

task.spawn(function()
    while true do
        refreshData()
        task.wait(2) -- مهلة آمنة لتجنب الحظر
    end
end)
