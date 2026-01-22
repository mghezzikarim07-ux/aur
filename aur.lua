local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local FIREBASE_URL = "https://karim-notifier-default-rtdb.europe-west1.firebasedatabase.app/history.json"
local PLACE_ID = 109983668079237 

local AutoJoinEnabled = false
local ActivationTime = 0 
local LastProcessedTime = 0 -- لتسجيل وقت آخر إشعار تم الدخول إليه

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SAB_Single_Join_Radar"
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
IconBtn.Text = "🎯"
IconBtn.TextSize = 25
IconBtn.Parent = ScreenGui
Instance.new("UICorner", IconBtn).CornerRadius = UDim.new(1, 0)
makeDraggable(IconBtn, IconBtn)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 350)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -175)
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

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 1, 0)
Title.Text = "SINGLE JOIN RADAR"
Title.TextColor3 = Color3.new(1,1,1)
Title.BackgroundTransparency = 1
Title.Parent = Header

local AutoJoinBtn = Instance.new("TextButton")
AutoJoinBtn.Size = UDim2.new(1, -20, 0, 40)
AutoJoinBtn.Position = UDim2.new(0, 10, 0, 45)
AutoJoinBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
AutoJoinBtn.Text = "AUTO JOIN: OFF"
AutoJoinBtn.Font = Enum.Font.GothamBold
AutoJoinBtn.TextColor3 = Color3.new(1,1,1)
AutoJoinBtn.Parent = MainFrame
Instance.new("UICorner", AutoJoinBtn)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -100)
Scroll.Position = UDim2.new(0, 10, 0, 90)
Scroll.BackgroundTransparency = 1
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.ScrollBarThickness = 2
Scroll.Parent = MainFrame
Instance.new("UIListLayout", Scroll).Padding = UDim.new(0, 5)

local function refreshData()
    local success, response = pcall(function() 
        -- نطلب آخر 3 إشعارات فقط لضمان السرعة القصوى
        return game:HttpGet(FIREBASE_URL .. "?orderBy=\"time\"&limitToLast=3") 
    end)
    
    if success and response ~= "null" then
        local data = HttpService:JSONDecode(response)
        local list = {}
        for _, v in pairs(data) do table.insert(list, v) end
        table.sort(list, function(a,b) return a.time > b.time end)
        
        Scroll:ClearAllChildren()
        Instance.new("UIListLayout", Scroll).Padding = UDim.new(0, 5)

        for _, item in ipairs(list) do
            local jobId = string.match(item.content, "%x+-%x+-%x+-%x+-%x+")
            local displayContent = item.content:gsub("JobId:[^\n]*", "")

            -- المنطق الجديد: دخول مرة واحدة فقط لكل إشعار جديد
            if AutoJoinEnabled and jobId then
                if item.time > ActivationTime and item.time > LastProcessedTime then
                    LastProcessedTime = item.time -- سجل أننا عالجنا هذا الإشعار
                    task.spawn(function()
                        print("🚀 جاري محاولة الدخول لإشعار جديد...")
                        TeleportService:TeleportToPlaceInstance(PLACE_ID, jobId, LocalPlayer)
                    end)
                end
            end

            -- عرض العناصر في القائمة
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 40)
            row.AutomaticSize = Enum.AutomaticSize.Y
            row.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            row.Parent = Scroll
            Instance.new("UICorner", row)

            local txt = Instance.new("TextLabel")
            txt.Size = UDim2.new(0.75, 0, 1, 0)
            txt.Position = UDim2.new(0, 10, 0, 0)
            txt.Text = displayContent
            txt.TextColor3 = Color3.new(1,1,1)
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
        ActivationTime = os.time() * 1000
        LastProcessedTime = 0 -- تصفير للبدء من جديد
        AutoJoinBtn.Text = "AUTO JOIN: ON (READY)"
        AutoJoinBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 70)
    else
        AutoJoinBtn.Text = "AUTO JOIN: OFF"
        AutoJoinBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    end
end)

IconBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

task.spawn(function()
    while true do
        refreshData()
        task.wait(0.7) -- سرعة الفحص (أقل من ثانية) لضمان القنص
    end
end)
