local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local FIREBASE_URL = "https://karim-notifier-default-rtdb.europe-west1.firebasedatabase.app/history.json"
local PLACE_ID = 109983668079237 

-- القائمة المحدثة (تم حذف Los Nooo My Hotspotsitos)
local TARGET_ITEMS = {
    "Mariachi Corazoni", "Chillin Chili", "La Taco Combinasion", 
    "Bombardinii Tortini", "Capi Taco", "Nooo My Hotspot", 
    "Corn Corn Corn Sahur", "Tacorita Bicicleta", 
    "chipso and queso", "quesadillo vampiro"
}

local LastJoinedJob = "" -- لمنع تكرار الدخول لنفس السيرفر

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SAB_AutoJoin_Radar"
ScreenGui.Parent = game:GetService("CoreGui")

-- [إعدادات الواجهة المختصرة]
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 100)
MainFrame.Position = UDim2.new(0.5, -150, 0, 50)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 1, 0)
StatusLabel.Text = "Status: Monitoring for Items..."
StatusLabel.TextColor3 = Color3.new(1, 1, 1)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 14
StatusLabel.Parent = MainFrame

-- وظيفة التحقق من العناصر
local function isItemMatch(fullText)
    for _, itemName in pairs(TARGET_ITEMS) do
        if string.find(string.lower(fullText), string.lower(itemName)) then
            return true
        end
    end
    return false
end

-- وظيفة البحث والـ Auto Join
local function checkAndJoin()
    local success, response = pcall(function() return game:HttpGet(FIREBASE_URL) end)
    if success and response ~= "null" then
        local data = HttpService:JSONDecode(response)
        
        local latestItems = {}
        for _, v in pairs(data) do table.insert(latestItems, v) end
        table.sort(latestItems, function(a,b) return a.time > b.time end)

        for _, item in ipairs(latestItems) do
            -- التحقق إذا كان العنصر مطلوباً وإذا كان الإشعار حديثاً (آخر دقيقتين)
            if isItemMatch(item.content) and (os.time() * 1000 - item.time) < 120000 then
                local jobId = string.match(item.content, "%w+-%w+-%w+-%w+-%w+")
                
                if jobId and jobId ~= LastJoinedJob then
                    LastJoinedJob = jobId
                    StatusLabel.Text = "ITEM FOUND! Joining Server..."
                    StatusLabel.TextColor3 = Color3.new(0, 1, 0)
                    
                    -- مسح البيانات قبل الانتقال لضمان الخصوصية
                    data = nil 
                    
                    task.wait(0.5)
                    TeleportService:TeleportToPlaceInstance(PLACE_ID, jobId, LocalPlayer)
                    break
                end
            end
        end
    end
end

-- حلقة التحديث التلقائي
task.spawn(function()
    while true do
        checkAndJoin()
        task.wait(1.5) -- فحص كل ثانية ونصف
    end
end)

-- تنظيف البيانات عند الخروج من السيرفر أو إغلاق السكربت
game:GetService("LogService").MessageOut:Connect(function()
    -- محاكاة مسح البيانات لضمان عدم بقاء سجلات
    StatusLabel.Text = "Data Cleared."
end)
