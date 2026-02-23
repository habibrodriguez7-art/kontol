-- GUARD: Cegah double execution saat reconnect/rejoin
if _G.LynxScriptLoaded then
    -- Stop semua modules dari instance lama
    pcall(function()
        if _G._LynxModules and _G._LynxModules.CleanupAllModules then
            _G._LynxModules.CleanupAllModules()
        end
    end)
    -- Destroy GUI lama
    pcall(function()
        local oldGui = game:GetService("CoreGui"):FindFirstChild("LynxGui")
        if oldGui then oldGui:Destroy() end
    end)
    -- Tunggu cleanup selesai
    task.wait(1)
end
_G.LynxScriptLoaded = true

-- ============================================================
-- EVENT RESOLVER: Deteksi nama event yang terenkripsi
-- ============================================================
local EventResolver = nil
local ER_URL = "https://raw.githubusercontent.com/habibrodriguez7-art/newGui/refs/heads/main/EventResolver.lua"

-- Coba load EventResolver
local erSuccess, erError = pcall(function()
    -- Coba dari file lokal dulu (jika di-paste langsung)
    if _G.EventResolver then
        EventResolver = _G.EventResolver
    else
        -- Load dari URL atau gunakan inline
        local erCode = game:HttpGet(ER_URL)
        if erCode and #erCode > 100 then
            EventResolver = loadstring(erCode)()
        end
    end
end)

-- Fallback: Inline EventResolver jika gagal load dari URL
if not EventResolver then
    pcall(function()
        -- Minimal inline resolver yang menggunakan Net module
        EventResolver = {
            _re = {},
            _rf = {},
            _initialized = false,
        }
        
        function EventResolver:Init()
            if self._initialized then return true end
            local RS = game:GetService("ReplicatedStorage")
            local ok, Net = pcall(function()
                return require(RS.Packages.Net)
            end)
            if ok and Net then
                -- Resolve RemoteEvents
                local reNames = {
                    "FishCaught", "FishingMinigameChanged", "FishingStopped",
                    "UpdateChargeState", "BaitSpawned", "SpawnTotem",
                    "ReplicateTextEffect", "EquipToolFromHotbar", "FavoriteItem",
                    "EquipItem", "ActivateEnchantingAltar", "ActivateSecondEnchantingAltar",
                    "RollEnchant", "ClaimPirateChest", "ObtainedNewFishNotification",
                }
                for _, name in ipairs(reNames) do
                    pcall(function()
                        self._re[name] = Net:RemoteEvent(name)
                    end)
                end
                -- Resolve RemoteFunctions
                local rfNames = {
                    "ChargeFishingRod", "RequestFishingMinigameStarted",
                    "CancelFishingInputs", "CatchFishCompleted",
                    "UpdateAutoFishingState", "SellAllItems", "UpdateFishingRadar",
                    "PurchaseWeatherEvent", "PurchaseCharm", "InitiateTrade",
                }
                for _, name in ipairs(rfNames) do
                    pcall(function()
                        self._rf[name] = Net:RemoteFunction(name)
                    end)
                end
                self._initialized = true
            end
            return self._initialized
        end
        
        function EventResolver:GetRE(name)
            if not self._initialized then self:Init() end
            return self._re[name]
        end
        
        function EventResolver:GetRF(name)
            if not self._initialized then self:Init() end
            return self._rf[name]
        end
        
        function EventResolver:GetNetFolder()
            local ok, f = pcall(function()
                return game:GetService("ReplicatedStorage")
                    :WaitForChild("Packages", 5)
                    :WaitForChild("_Index", 5)
                    :WaitForChild("sleitnick_net@0.2.0", 5)
                    :WaitForChild("net", 5)
            end)
            return ok and f or nil
        end
        
        function EventResolver:PrintReport()
        end
    end)
end

-- Inisialisasi EventResolver
if EventResolver then
    pcall(function()
        EventResolver:Init()
    end)
end

_G.EventResolver = EventResolver

-- GANTI URL INI DENGAN LINK RAW GITHUB LIBRARY.LUA KAMU
local LIBRARY_URL = "https://raw.githubusercontent.com/habibrodriguez7-art/newGui/refs/heads/main/10.lua"
local Lynx = nil
local librarySuccess, libraryError = pcall(function()
    Lynx = loadstring(game:HttpGet(LIBRARY_URL))()
end)

if not librarySuccess or not Lynx then
    warn("[Lynx] ❌ Gagal memuat Library dari: " .. LIBRARY_URL)
    warn("[Lynx] Error: " .. tostring(libraryError))
    -- Tampilkan notifikasi error ke user
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Lynx Error",
            Text = "Gagal memuat library! Cek koneksi internet atau URL.",
            Duration = 10
        })
    end)
    -- PENTING: Hentikan script sepenuhnya jika library gagal dimuat
    error("[Lynx] Script dihentikan karena library tidak dapat dimuat. Pastikan URL valid dan koneksi internet aktif.")
    return nil
else
    -- Library loaded
end

local CombinedModules = {}
_G._LynxModules = CombinedModules

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace") or workspace
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local localPlayer = Players.LocalPlayer
local LocalPlayer = localPlayer
local player = localPlayer
local Character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid", 5)

localPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid", 5)
end)

local NetEvents = {
    RF_ChargeFishingRod = nil,
    RF_RequestMinigame = nil,
    RF_CancelFishingInputs = nil,
    RF_UpdateAutoFishingState = nil,
    
    RE_FishingCompleted = nil,
    RE_MinigameChanged = nil,
    RE_FishCaught = nil,
    RE_FishingStopped = nil,
    
    netFolder = nil,
    
    IsInitialized = false
}

local function InitializeNetEvents()
    if NetEvents.IsInitialized then return true end
    
    local success = pcall(function()
        -- Gunakan EventResolver untuk mendapatkan net folder
        if EventResolver then
            NetEvents.netFolder = EventResolver:GetNetFolder()
            
            -- Resolve semua events via EventResolver
            NetEvents.RF_ChargeFishingRod = EventResolver:GetRF("ChargeFishingRod")
            NetEvents.RF_RequestMinigame = EventResolver:GetRF("RequestFishingMinigameStarted")
            NetEvents.RF_CancelFishingInputs = EventResolver:GetRF("CancelFishingInputs")
            NetEvents.RF_UpdateAutoFishingState = EventResolver:GetRF("UpdateAutoFishingState")
            NetEvents.RE_FishingCompleted = EventResolver:GetRF("CatchFishCompleted")
            NetEvents.RE_MinigameChanged = EventResolver:GetRE("FishingMinigameChanged")
            NetEvents.RE_FishCaught = EventResolver:GetRE("FishCaught")
            NetEvents.RE_FishingStopped = EventResolver:GetRE("FishingStopped")
        else
            -- Fallback ke hardcoded (format lama)
            NetEvents.netFolder = ReplicatedStorage
                :WaitForChild("Packages", 5)
                :WaitForChild("_Index", 5)
                :WaitForChild("sleitnick_net@0.2.0", 5)
                :WaitForChild("net", 5)

            NetEvents.RF_ChargeFishingRod = NetEvents.netFolder:WaitForChild("RF/ChargeFishingRod", 5)
            NetEvents.RF_RequestMinigame = NetEvents.netFolder:WaitForChild("RF/RequestFishingMinigameStarted", 5)
            NetEvents.RF_CancelFishingInputs = NetEvents.netFolder:WaitForChild("RF/CancelFishingInputs", 5)
            NetEvents.RF_UpdateAutoFishingState = NetEvents.netFolder:WaitForChild("RF/UpdateAutoFishingState", 5)
            NetEvents.RE_FishingCompleted = NetEvents.netFolder:WaitForChild("RF/CatchFishCompleted", 5)
            NetEvents.RE_MinigameChanged = NetEvents.netFolder:WaitForChild("RE/FishingMinigameChanged", 5)
            NetEvents.RE_FishCaught = NetEvents.netFolder:WaitForChild("RE/FishCaught", 5)
            NetEvents.RE_FishingStopped = NetEvents.netFolder:WaitForChild("RE/FishingStopped", 5)
        end
    end)
    
    if success and NetEvents.netFolder then
        NetEvents.IsInitialized = true
    else
        warn("⚠️ [NetEvents] Gagal menginisialisasi network events!")
    end
    
    return NetEvents.IsInitialized
end

InitializeNetEvents()

_G.NetEvents = NetEvents
_G.SharedCharacter = Character
_G.SharedHumanoid = Humanoid

local function safeGetConfig(key, default)
    if _G.GetConfigValue and type(_G.GetConfigValue) == "function" then
        local success, value = pcall(function()
            return _G.GetConfigValue(key, default)
        end)
        if success and value ~= nil then
            return value
        end
    end
    return default
end

local function safeFire(func)
    task.spawn(function()
        pcall(func)
    end)
end

-- Global Rod Check Helper (digunakan oleh InstantV1, blatantV1, blatantV2)
local RodCheckHelper = (function()
    local Helper = {}
    
    local cache = {
        v5 = nil,
        v6 = nil,
        v7 = nil,
        initialized = false
    }
    
    function Helper.Init()
        if cache.initialized then return true end
        
        local success = pcall(function()
            local RS = ReplicatedStorage
            cache.v5 = {
                Net = RS.Packages._Index["sleitnick_net@0.2.0"].net,
                PlayerStatsUtility = require(RS.Shared.PlayerStatsUtility),
                ItemUtility = require(RS.Shared.ItemUtility)
            }
            cache.v6 = {
                REEquip = (EventResolver and EventResolver:GetRE("EquipToolFromHotbar")) or cache.v5.Net["RE/EquipToolFromHotbar"]
            }
            cache.v7 = {
                Data = require(RS.Packages.Replion).Client:WaitReplion("Data")
            }
        end)
        
        cache.initialized = success
        return success
    end
    
    function Helper.IsRodEquipped()
        if not cache.initialized then
            if not Helper.Init() then return true end
        end
        
        local success, result = pcall(function()
            local equippedId = cache.v7.Data:Get("EquippedId")
            if not equippedId then return false end
            
            local equippedItem = cache.v5.PlayerStatsUtility:GetItemFromInventory(
                cache.v7.Data, 
                function(item) return item.UUID == equippedId end
            )
            
            if not equippedItem then return false end
            
            local itemData = cache.v5.ItemUtility:GetItemData(equippedItem.Id)
            return itemData and itemData.Data.Type == "Fishing Rods"
        end)
        
        return success and result or false
    end
    
    function Helper.EquipRod()
        if not cache.initialized then
            if not Helper.Init() then return end
        end
        
        pcall(function()
            cache.v6.REEquip:FireServer(1)
        end)
    end
    
    -- Helper untuk digunakan di loop fishing
    -- Returns true jika bisa lanjut, false jika harus skip
    function Helper.EnsureRodEquipped()
        if Helper.IsRodEquipped() then
            return true
        end
        
        Helper.EquipRod()
        task.wait(0.5)
        
        if Helper.IsRodEquipped() then
            return true
        end
        
        task.wait(1)
        return false -- skip iterasi ini
    end
    
    return Helper
end)()

local function disableFishingAnim()
    pcall(function()
        local hum = _G.SharedHumanoid or Humanoid
        if not hum then return end
        
        for _, track in pairs(hum:GetPlayingAnimationTracks()) do
            local name = track.Name:lower()
            if name:find("fish") or name:find("rod") or name:find("cast") or name:find("reel") then
                track:Stop(0)
            end
        end
    end)
    
    task.spawn(function()
        local char = _G.SharedCharacter or Character
        if not char then return end
        
        local rod = char:FindFirstChild("Rod") or char:FindFirstChildWhichIsA("Tool")
        if rod and rod:FindFirstChild("Handle") then
            local handle = rod.Handle
            local weld = handle:FindFirstChildOfClass("Weld") or handle:FindFirstChildOfClass("Motor6D")
            if weld then
                weld.C0 = CFrame.new(0, -1, -1.2) * CFrame.Angles(math.rad(-10), 0, 0)
            end
        end
    end)
end

CombinedModules.StuckDetector = (function()
local StuckDetector = {}
StuckDetector.__index = StuckDetector

-- Initialize detector variables
local detectorEnabled = false
local stuckThreshold = 15 -- default seconds
local fishingTimer = 0
local lastFishCount = 0
local savedPosition = nil
local savedLookVector = nil
local updateConnection = nil
local isRespawning = false -- Flag to prevent position update during respawn

-- Notification function
local function notify(message, duration)
    if chloex then
        chloex(message, duration)
    else
        print(message)
    end
end

-- Get current fish count from bag
local function getFishCount()
    local success, result = pcall(function()
        local bagLabel = player.PlayerGui:WaitForChild("Inventory")
            :WaitForChild("Main")
            :WaitForChild("Top")
            :WaitForChild("Options")
            :WaitForChild("Fish")
            :WaitForChild("Label")
            :WaitForChild("BagSize")
        
        local count = tonumber((bagLabel.Text or "0/???"):match("(%d+)/")) or 0
        return count
    end)
    
    return success and result or 0
end

-- Save current position and look direction
local function saveCurrentState()
    if isRespawning then return end -- Don't save during respawn
    
    local char = player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        savedPosition = hrp.CFrame
        savedLookVector = hrp.CFrame.LookVector
    end
end

-- Respawn character at saved position with same look direction
local function respawnAtPosition()
    if not savedPosition then return end
    
    isRespawning = true -- Set flag to prevent position updates
    
    -- Kill character to respawn
    if player.Character then
        player.Character:BreakJoints()
    end
    
    -- Wait for respawn and immediately teleport
    task.spawn(function()
        local newChar = player.CharacterAdded:Wait()
        local hrp = newChar:WaitForChild("HumanoidRootPart", 10)
        
        if not hrp then 
            isRespawning = false
            return 
        end
        
        -- Wait for character to fully load
        task.wait(0.1)
        
        -- Immediately teleport to saved position before spawn island loads
        hrp.CFrame = CFrame.new(savedPosition.Position, savedPosition.Position + savedLookVector)
        
        -- Anchor to prevent falling
        hrp.Anchored = true
        task.wait(0.3)
        hrp.Anchored = false
        
        -- Re-equip rod with better error handling
        task.wait(0.2)
        pcall(function()
            local equipEvent = EventResolver and EventResolver:GetRE("EquipToolFromHotbar")
            if not equipEvent then
                -- Fallback ke path lama
                local netFolder = ReplicatedStorage:FindFirstChild("Packages")
                if netFolder then
                    netFolder = netFolder:FindFirstChild("_Index")
                    if netFolder then
                        netFolder = netFolder:FindFirstChild("sleitnick_net@0.2.0")
                        if netFolder then
                            netFolder = netFolder:FindFirstChild("net")
                            if netFolder then
                                equipEvent = netFolder:FindFirstChild("RE/EquipToolFromHotbar")
                            end
                        end
                    end
                end
            end
            if equipEvent then
                equipEvent:FireServer(1)
            end
        end)
        
        -- Wait a bit more before allowing position saves again
        task.wait(0.5)
        isRespawning = false -- Allow position saves again
        
        notify("Respawned at saved position!", 3)
    end)
end

-- Main detector loop
local function startDetector()
    if updateConnection then
        updateConnection:Disconnect()
    end
    
    fishingTimer = 0
    lastFishCount = getFishCount()
    saveCurrentState()
    
    local lastPositionSave = tick()
    
    updateConnection = RunService.Heartbeat:Connect(function(dt)
        if not detectorEnabled then
            if updateConnection then
                updateConnection:Disconnect()
                updateConnection = nil
            end
            return
        end
        
        -- Update timer
        fishingTimer = fishingTimer + dt
        
        -- Continuously save position every 1 second
        local currentTime = tick()
        if currentTime - lastPositionSave >= 1 then
            saveCurrentState()
            lastPositionSave = currentTime
        end
        
        -- Check fish count every 0.5 seconds
        if fishingTimer % 0.5 < dt then
            local currentCount = getFishCount()
            
            -- If fish count increased, reset timer
            if currentCount > lastFishCount then
                fishingTimer = 0
                lastFishCount = currentCount
                saveCurrentState() -- Update saved position immediately when catching fish
            end
            
            -- Check if stuck
            if fishingTimer >= stuckThreshold then
                notify("Stuck detected! Respawning...", 3)
                respawnAtPosition()
                fishingTimer = 0
                lastFishCount = getFishCount()
            end
        end
        
        -- Update paragraph display (throttle: setiap 1 detik saja)
        if DetectorParagraph and fishingTimer % 1 < dt then
            local status = "Fishing..."
            local statusColor = "0,255,127" -- Green
            
            if fishingTimer >= (stuckThreshold * 0.8) then
                status = "Potential Stuck"
                statusColor = "255,165,0" -- Orange
            end
            
            DetectorParagraph:SetContent(string.format(
                "<font color='rgb(%s)'>Status: %s</font>\n<font color='rgb(100,200,255)'>Timer: %.1fs / %ds</font>\n<font color='rgb(173,216,230)'>Fish Count: %d</font>",
                statusColor,
                status,
                fishingTimer,
                stuckThreshold,
                lastFishCount
            ))
        end
    end)
end

-- Stop detector
local function stopDetector()
    detectorEnabled = false
    
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
    
    if DetectorParagraph then
        DetectorParagraph:SetContent("<font color='rgb(200,200,200)'>Status: Detector Offline</font>\nTimer: 0.0s\nFish Count: 0")
    end
end

-- Public functions
function StuckDetector:Start(threshold)
    stuckThreshold = threshold or 15
    detectorEnabled = true
    startDetector()
    notify("Stuck Detector started! Threshold: " .. stuckThreshold .. "s", 3)
end

function StuckDetector:Stop()
    stopDetector()
    notify("Stuck Detector stopped!", 3)
end

function StuckDetector:SetThreshold(seconds)
    stuckThreshold = seconds
end

function StuckDetector:IsRunning()
    return detectorEnabled
end

return StuckDetector
end)()

CombinedModules.legit = (function()
    local Legit = {}
    Legit.Active = false
    Legit.AutoShake = false

    Legit.Settings = {
        Mode = "AlwaysPerfect",
        CompleteDelay = 0.8,
        ShakeDelay = 0.05,
        ChargeTarget = 0.95,
        ChargeWaitTimeout = 1.0,
        AfterCastWait = 0.01,
        BetweenAttempts = 0.5,
        CastRetryDelay = 1.5,
        ShakeDetectionTimeout = 3.0,
        CatchWaitTimeout = 8.0,
    }

    local fishingThread = nil
    local shakeThread = nil
    local cosmeticFolder = nil
    local userId = tostring(Players.LocalPlayer.UserId)
    local FishingController = nil
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local Camera = workspace.CurrentCamera
    local PlayerGui = Players.LocalPlayer.PlayerGui

    local function initFishingController()
        if not FishingController then
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local Controllers = ReplicatedStorage:FindFirstChild("Controllers")
            
            if Controllers then
                local FishingControllerModule = Controllers:FindFirstChild("FishingController")
                if FishingControllerModule then
                    FishingController = require(FishingControllerModule)
                end
            end
            
            if not FishingController then
                return false
            end
        end
        return true
    end

    local function getScreenCenter()
        local viewport = Camera.ViewportSize
        return Vector2.new(viewport.X / 2, viewport.Y / 2)
    end

    local function bobberExists()
        if not cosmeticFolder then
            cosmeticFolder = workspace:FindFirstChild("CosmeticFolder")
        end
        
        if cosmeticFolder then
            local userFolder = cosmeticFolder:FindFirstChild(userId)
            return userFolder ~= nil
        end
        
        return false
    end

    local function getCurrentGUID()
        if not FishingController then
            return nil
        end
        
        local success, guid = pcall(function()
            return FishingController:GetCurrentGUID()
        end)
        
        return success and guid or nil
    end

    local function requestClick()
        if not FishingController then
            return false
        end
        
        return safeFire(function()
            FishingController:RequestFishingMinigameClick()
        end)
    end

    local function isOnCooldown()
        local success, result = pcall(function()
            return FishingController:OnCooldown()
        end)
        return success and result or false
    end

    local function tryCast()
        local screenCenter = getScreenCenter()
        local lastGUID = nil
        
        while FishingController._autoLoop do
            if getCurrentGUID() then
                task.wait(0.05)
            else
                VirtualInputManager:SendMouseButtonEvent(screenCenter.X, screenCenter.Y, 0, true, game, 1)
                task.wait(0.05)
                
                local chargeGui = PlayerGui:WaitForChild("Charge", 1)
                if chargeGui then
                    local success, bar = pcall(function()
                        return chargeGui:WaitForChild("Main"):WaitForChild("CanvasGroup"):WaitForChild("Bar")
                    end)
                    
                    if success and bar then
                        local startTime = tick()
                        
                        while bar:IsDescendantOf(PlayerGui) and bar.Size.Y.Scale < Legit.Settings.ChargeTarget do
                            task.wait(0.001)
                            
                            if tick() - startTime > Legit.Settings.ChargeWaitTimeout then
                                break
                            end
                        end
                    end
                end
                
                VirtualInputManager:SendMouseButtonEvent(screenCenter.X, screenCenter.Y, 0, false, game, 1)
                
                local shakeStartTime = tick()
                local shakeDetected = false
                
                while tick() - shakeStartTime < Legit.Settings.ShakeDetectionTimeout do
                    local currentGUID = getCurrentGUID()
                    
                    if currentGUID and currentGUID ~= lastGUID then
                        shakeDetected = true
                        lastGUID = currentGUID
                        break
                    end
                    
                    task.wait(0.05)
                end
                
                if shakeDetected then
                    local catchStartTime = tick()
                    
                    while tick() - catchStartTime < Legit.Settings.CatchWaitTimeout do
                        if not getCurrentGUID() then
                            break
                        end
                        
                        task.wait(0.1)
                    end
                    
                    while getCurrentGUID() do
                        task.wait(0.05)
                    end
                    
                    task.wait(1.3)
                end
                
                return shakeDetected
            end
            
            task.wait(0.05)
        end
        
        return false
    end

    local function castQuick()
        if not FishingController then
            return false
        end
        
        local screenCenter = getScreenCenter()
        
        local success = safeFire(function()
            FishingController:RequestChargeFishingRod(screenCenter, true)
        end)
        
        if success then
            task.wait(0.25)
            return true
        end
        
        return false
    end

    local function alwaysPerfectLoop()
        RodCheckHelper.Init()
        
        if not initFishingController() then
            Legit.Active = false
            return
        end
        
        FishingController._autoLoop = true
        
        local completed = false
        
        while Legit.Active and FishingController._autoLoop do
            if not RodCheckHelper.EnsureRodEquipped() then
                task.wait(0.5)
                continue
            end
            
            if not bobberExists() then
                repeat
                    tryCast()
                    task.wait(0.1)
                until bobberExists() or not FishingController._autoLoop
            end
            
            while bobberExists() and FishingController._autoLoop do
                if getCurrentGUID() then
                    local startTime = tick()
                    
                    while getCurrentGUID() and FishingController._autoLoop do
                        pcall(function()
                            FishingController:RequestFishingMinigameClick()
                        end)
                        
                        if tick() - startTime >= Legit.Settings.CompleteDelay then
                            task.wait(Legit.Settings.CompleteDelay)
                            
                            repeat
                                if NetEvents and NetEvents.RE_FishingCompleted then
                                    pcall(function()
                                        NetEvents.RE_FishingCompleted:InvokeServer()
                                    end)
                                end
                                
                                task.wait(0.05)
                                completed = not getCurrentGUID() or not FishingController._autoLoop
                            until completed
                            
                            break
                        else
                            task.wait(0.01)
                        end
                        
                        if completed then
                            break
                        end
                    end
                end
                
                completed = false
                task.wait(0.2)
            end
            
            repeat
                task.wait(0.1)
            until not bobberExists() or not FishingController._autoLoop
            
            if FishingController._autoLoop then
                task.wait(0.2)
                tryCast()
            end
            
            task.wait(0.2)
        end
    end

    local function normalLoop()
        RodCheckHelper.Init()
        
        if not initFishingController() then
            Legit.Active = false
            return
        end
        
        if not FishingController._oldGetPower then
            FishingController._oldGetPower = FishingController._getPower
        end
        FishingController._getPower = function()
            return 0.999
        end
        
        FishingController._autoLoop = true
        
        while Legit.Active and FishingController._autoLoop do
            if not RodCheckHelper.EnsureRodEquipped() then
                task.wait(0.5)
                continue
            end
            
            local currentGUID = getCurrentGUID()
            
            if currentGUID then
                local startTime = tick()
                
                while getCurrentGUID() and FishingController._autoLoop do
                    pcall(function()
                        FishingController:RequestFishingMinigameClick()
                    end)
                    
                    if tick() - startTime >= Legit.Settings.CompleteDelay then
                        if NetEvents and NetEvents.RE_FishingCompleted then
                            pcall(function()
                                NetEvents.RE_FishingCompleted:InvokeServer()
                            end)
                        end
                        
                        task.wait(0.1)
                        
                        if not getCurrentGUID() or not FishingController._autoLoop then
                            break
                        end
                    end
                    
                    task.wait(0.1)
                end
            else
                castQuick()
            end
            
            task.wait(0.05)
        end
        
        if FishingController and FishingController._oldGetPower then
            FishingController._getPower = FishingController._oldGetPower
            FishingController._oldGetPower = nil
        end
    end

    local function autoShakeLoop()
        if not initFishingController() then
            return
        end
        
        local clickEffect = PlayerGui:FindFirstChild("!!! Click Effect")
        
        if clickEffect then
            clickEffect.Enabled = false
        end
        
        while Legit.AutoShake do
            requestClick()
            task.wait(Legit.Settings.ShakeDelay)
        end
        
        if clickEffect then
            clickEffect.Enabled = true
        end
    end

    function Legit.Start()
        if Legit.Active then
            return
        end
        
        if not initFishingController() then
            return
        end
        
        Legit.Active = true
        cosmeticFolder = workspace:FindFirstChild("CosmeticFolder")
        
        if Legit.Settings.Mode == "AlwaysPerfect" then
            fishingThread = task.spawn(alwaysPerfectLoop)
        elseif Legit.Settings.Mode == "Normal" then
            fishingThread = task.spawn(normalLoop)
        end
    end

    function Legit.Stop()
        if not Legit.Active then
            return
        end
        
        Legit.Active = false
        
        if FishingController then
            FishingController._autoLoop = false
            
            if FishingController._oldGetPower then
                FishingController._getPower = FishingController._oldGetPower
                FishingController._oldGetPower = nil
            end
        end
        
        if fishingThread then
            task.cancel(fishingThread)
            fishingThread = nil
        end
        
        if NetEvents and NetEvents.RF_CancelFishingInputs then
            safeFire(function()
                NetEvents.RF_CancelFishingInputs:InvokeServer()
            end)
        end
    end

    function Legit.StartAutoShake()
        if Legit.AutoShake then
            return
        end
        
        Legit.AutoShake = true
        shakeThread = task.spawn(autoShakeLoop)
    end

    function Legit.StopAutoShake()
        if not Legit.AutoShake then
            return
        end
        
        Legit.AutoShake = false
        
        if shakeThread then
            task.cancel(shakeThread)
            shakeThread = nil
        end
        
        local clickEffect = PlayerGui:FindFirstChild("!!! Click Effect")
        if clickEffect then
            clickEffect.Enabled = true
        end
    end

    function Legit.SetMode(mode)
        if mode == "AlwaysPerfect" or mode == "Normal" then
            Legit.Settings.Mode = mode
            
            if Legit.Active then
                Legit.Stop()
                task.wait(0.5)
                Legit.Start()
            end
        end
    end

    function Legit.SetChargeTarget(target)
        if target >= 0 and target <= 1 then
            Legit.Settings.ChargeTarget = target
        end
    end
    
    function Legit.SetCompleteDelay(delay)
        if delay > 0 then
            Legit.Settings.CompleteDelay = delay
        end
    end

    return Legit
end)()

CombinedModules.InstantV1 = (function()
    local Instant = {}
    Instant.Active = false

    Instant.Settings = {
        CompleteDelay = 0.04,
    }

    local spamLoopThread = nil

    local function instantSpamLoop()
        RodCheckHelper.Init()
        
        while Instant.Active do
            -- Gunakan helper global untuk cek rod
            if not RodCheckHelper.EnsureRodEquipped() then
                continue -- Skip jika rod belum siap
            end
            
            local currentTime = tick()
    
            pcall(function()
                NetEvents.RF_ChargeFishingRod:InvokeServer({[1] = currentTime})
            end)
            task.wait(0.3)
            pcall(function()
                NetEvents.RF_RequestMinigame:InvokeServer(1, 0, currentTime)
            end)
        
            task.wait(Instant.Settings.CompleteDelay)
            
            pcall(function()
                NetEvents.RE_FishingCompleted:InvokeServer()
            end)
            task.wait(0.07)
        end
    end

    function Instant.UpdateSettings(completeDelay)
        if completeDelay ~= nil then
            Instant.Settings.CompleteDelay = completeDelay
        end
    end

    function Instant.Start()
        if Instant.Active then 
            return
        end
        
        Instant.Active = true
        spamLoopThread = task.spawn(instantSpamLoop)
    end

    function Instant.Stop()
        if not Instant.Active then 
            return
        end
        
        Instant.Active = false
        
        if spamLoopThread then
            task.cancel(spamLoopThread)
            spamLoopThread = nil
        end

        safeFire(function()
            NetEvents.RF_CancelFishingInputs:InvokeServer()
        end)
    end

    return Instant
end)()

CombinedModules.StableResult = (function()
    
    local StableResult = {}

    StableResult.Enabled = false

    local RF_UpdateAutoFishingMiniGame = nil

    local function InitializeRemote()
        if RF_UpdateAutoFishingMiniGame then return true end
        
        local success = pcall(function()
            local Net = ReplicatedStorage:WaitForChild("Packages", 3)
                :WaitForChild("_Index", 3)
                :WaitForChild("sleitnick_net@0.2.0", 3)
                :WaitForChild("net", 3)
            
            RF_UpdateAutoFishingMiniGame = (EventResolver and EventResolver:GetRF("UpdateAutoFishingState")) or Net:WaitForChild("RF/UpdateAutoFishingState", 3)
        end)
        
        return success and RF_UpdateAutoFishingMiniGame ~= nil
    end
    
    function StableResult.Start()
        if StableResult.Enabled then
            return false
        end
        
        if not InitializeRemote() then
            return false
        end
        
        StableResult.Enabled = true

        local success = pcall(function()
            RF_UpdateAutoFishingMiniGame:InvokeServer(true)
        end)
        
        if not success then
            StableResult.Enabled = false
            return false
        end

        pcall(function()
            LocalPlayer:SetAttribute("Loading", nil)
        end)
        
        return true
    end
    
    function StableResult.Stop()
        if not StableResult.Enabled then
            return false
        end
        
        StableResult.Enabled = false

        if RF_UpdateAutoFishingMiniGame then
            pcall(function()
                RF_UpdateAutoFishingMiniGame:InvokeServer(false)
            end)
        end

        pcall(function()
            LocalPlayer:SetAttribute("Loading", false)
        end)
        
        return true
    end
    
    function StableResult.IsEnabled()
        return StableResult.Enabled
    end
    
    return StableResult
end)()

CombinedModules.blatantV1 = (function()
    local UltraBlatant = {}
    UltraBlatant.Active = false

    UltraBlatant.Settings = {
        SpamCastDelay = 0.05,
        CompleteDelay = 0.01,
        InstantComplete = true,
        ChargeSpam = 5,
    }

    local spamLoopThread = nil

    local function ultraSpamLoop()
        RodCheckHelper.Init()
        
        while UltraBlatant.Active do
            if not RodCheckHelper.EnsureRodEquipped() then
                continue
            end
            
            local currentTime = workspace:GetServerTimeNow()
            
            for i = 1, UltraBlatant.Settings.ChargeSpam do
                safeFire(function()
                    NetEvents.RF_ChargeFishingRod:InvokeServer(nil, nil, currentTime, nil)
                end)
                task.wait(0.3)
                safeFire(function()
                    NetEvents.RF_RequestMinigame:InvokeServer(-1.2331848144531, 0.89899236174132, currentTime)
                end)
                
                if i < UltraBlatant.Settings.ChargeSpam then
                    task.wait(0.05)
                end
            end
            
            if UltraBlatant.Settings.InstantComplete then
                task.wait(UltraBlatant.Settings.CompleteDelay)
                safeFire(function()
                    NetEvents.RE_FishingCompleted:InvokeServer()
                end)
                task.wait(0.01)
                safeFire(function()
                    NetEvents.RF_CancelFishingInputs:InvokeServer()
                end)
            end
            
            task.wait(UltraBlatant.Settings.SpamCastDelay)
        end
    end

    function UltraBlatant.UpdateSettings(completeDelay, spamCastDelay, chargeSpam, spamCompleteCount)
        if completeDelay ~= nil then
            UltraBlatant.Settings.CompleteDelay = completeDelay
        end
        if spamCastDelay ~= nil then
            UltraBlatant.Settings.SpamCastDelay = spamCastDelay
        end
        if chargeSpam ~= nil then
            UltraBlatant.Settings.ChargeSpam = chargeSpam
        end
        if spamCompleteCount ~= nil then
            UltraBlatant.Settings.SpamCompleteCount = spamCompleteCount
        end
    end

    function UltraBlatant.Start()
        if UltraBlatant.Active then 
            return
        end
        
        UltraBlatant.Active = true
        spamLoopThread = task.spawn(ultraSpamLoop)
    end

    function UltraBlatant.Stop()
        if not UltraBlatant.Active then 
            return
        end
        
        UltraBlatant.Active = false
        
        if spamLoopThread then
            task.cancel(spamLoopThread)
            spamLoopThread = nil
        end

        safeFire(function()
            NetEvents.RF_CancelFishingInputs:InvokeServer()
        end)
    end

    return UltraBlatant
end)()

CombinedModules.blatantV2 = (function()
    local UltraBlatant = {}
    UltraBlatant.Active = false

    UltraBlatant.Settings = {
        SpamCastDelay = 0.05,
        CompleteDelay = 0.01,
        InstantComplete = true,
        ChargeSpam = 3,
    }

    local spamLoopThread = nil

    local function ultraSpamLoop()
        RodCheckHelper.Init()
        
        while UltraBlatant.Active do
            if not RodCheckHelper.EnsureRodEquipped() then
                continue
            end
            
            local currentTime = tick()
            
            for i = 1, UltraBlatant.Settings.ChargeSpam do
                safeFire(function()
                    NetEvents.RF_ChargeFishingRod:InvokeServer({[1] = currentTime})
                end)
                safeFire(function()
                    NetEvents.RF_RequestMinigame:InvokeServer(1, 0, currentTime)
                end)
                
                if i < UltraBlatant.Settings.ChargeSpam then
                    task.wait(0.05)
                end
            end
            
            if UltraBlatant.Settings.InstantComplete then
                task.wait(UltraBlatant.Settings.CompleteDelay)
                safeFire(function()
                    NetEvents.RE_FishingCompleted:InvokeServer()
                end)
                
                task.wait(0.009)
                safeFire(function()
                    NetEvents.RF_CancelFishingInputs:InvokeServer()
                end)
                
                task.wait(0.01)
            end
            
            task.wait(UltraBlatant.Settings.SpamCastDelay)
        end
    end

    function UltraBlatant.UpdateSettings(completeDelay, spamCastDelay, chargeSpam, spamCompleteCount)
        if completeDelay ~= nil then
            UltraBlatant.Settings.CompleteDelay = completeDelay
        end
        if spamCastDelay ~= nil then
            UltraBlatant.Settings.SpamCastDelay = spamCastDelay
        end
        if chargeSpam ~= nil then
            UltraBlatant.Settings.ChargeSpam = chargeSpam
        end
        if spamCompleteCount ~= nil then
            UltraBlatant.Settings.SpamCompleteCount = spamCompleteCount
        end
    end

    function UltraBlatant.Start()
        if UltraBlatant.Active then 
            return
        end
        
        UltraBlatant.Active = true
        spamLoopThread = task.spawn(ultraSpamLoop)
    end

    function UltraBlatant.Stop()
        if not UltraBlatant.Active then 
            return
        end
        
        UltraBlatant.Active = false
        
        if spamLoopThread then
            task.cancel(spamLoopThread)
            spamLoopThread = nil
        end

        safeFire(function()
            NetEvents.RF_CancelFishingInputs:InvokeServer()
        end)
    end

    return UltraBlatant
end)()

-- Module NoFishingAnimation
CombinedModules.NoFishingAnimation = (function()
local NoFishingAnimation = {}
NoFishingAnimation.Enabled = false
NoFishingAnimation.Connection = nil
NoFishingAnimation.SavedPose = {}
NoFishingAnimation.ReelingTrack = nil
NoFishingAnimation.AnimationBlocker = nil

-- Fungsi untuk find ReelingIdle animation
local function getOrCreateReelingAnimation()
    local success, result = pcall(function()
        local character = localPlayer.Character
        if not character then return nil end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return nil end
        
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then return nil end
        
        -- Cari animasi ReelingIdle yang sudah ada
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            local name = track.Name
            if name:find("Reel") and name:find("Idle") then
                return track
            end
        end
        
        -- Cari di semua loaded animations
        for _, track in pairs(humanoid.Animator:GetPlayingAnimationTracks()) do
            if track.Animation then
                if track.Name:find("Reel") then
                    return track
                end
            end
        end
        
        -- Jika tidak ada, coba cari di character tools
        for _, tool in pairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                for _, anim in pairs(tool:GetDescendants()) do
                    if anim:IsA("Animation") then
                        local name = anim.Name
                        if name:find("Reel") and name:find("Idle") then
                            local track = animator:LoadAnimation(anim)
                            return track
                        end
                    end
                end
            end
        end
        
        return nil
    end)
    
    if success then
        return result
    end
    return nil
end

-- Fungsi untuk capture pose dari Motor6D
local function capturePose()
    NoFishingAnimation.SavedPose = {}
    local count = 0
    
    pcall(function()
        local character = localPlayer.Character
        if not character then return end
        
        -- Simpan SEMUA Motor6D
        for _, descendant in pairs(character:GetDescendants()) do
            if descendant:IsA("Motor6D") then
                NoFishingAnimation.SavedPose[descendant.Name] = {
                    Part = descendant,
                    C0 = descendant.C0,
                    C1 = descendant.C1,
                    Transform = descendant.Transform
                }
                count = count + 1
            end
        end
    end)
    
    return count > 0
end

-- Fungsi untuk STOP SEMUA animasi secara permanent
local function killAllAnimations()
    pcall(function()
        local character = localPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return nil end
        
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then return nil end
        
        -- STOP semua playing animations
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            track:Stop(0)
            track:Destroy()
        end
        
        -- STOP semua humanoid animations
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            track:Stop(0)
            track:Destroy()
        end
    end)
end

-- Fungsi untuk BLOCK animasi baru agar tidak play
local function blockNewAnimations()
    if NoFishingAnimation.AnimationBlocker then
        NoFishingAnimation.AnimationBlocker:Disconnect()
    end
    
    pcall(function()
        local character = localPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then return nil end
        
        -- Hook semua animasi baru yang mau play
        NoFishingAnimation.AnimationBlocker = animator.AnimationPlayed:Connect(function(animTrack)
            if NoFishingAnimation.Enabled then
                animTrack:Stop(0)
                animTrack:Destroy()
            end
        end)
    end)
end

-- Fungsi untuk freeze pose
local function freezePose()
    if NoFishingAnimation.Connection then
        NoFishingAnimation.Connection:Disconnect()
    end
    
    -- Throttle: hanya update setiap 2 frame untuk hemat CPU
    local frameCounter = 0
    
    NoFishingAnimation.Connection = RunService.Heartbeat:Connect(function()
        if not NoFishingAnimation.Enabled then return end
        
        frameCounter = frameCounter + 1
        if frameCounter % 2 ~= 0 then return end -- skip setiap frame ganjil
        
        pcall(function()
            local character = localPlayer.Character
            if not character then return end
            
            -- APPLY SAVED POSE (AnimationBlocker sudah block animasi baru, jadi tidak perlu Stop lagi)
            for jointName, poseData in pairs(NoFishingAnimation.SavedPose) do
                local motor = character:FindFirstChild(jointName, true)
                if motor and motor:IsA("Motor6D") then
                    motor.C0 = poseData.C0
                    motor.C1 = poseData.C1
                end
            end
        end)
    end)
end

-- Fungsi Stop
local function stopFreeze()
    if NoFishingAnimation.Connection then
        NoFishingAnimation.Connection:Disconnect()
        NoFishingAnimation.Connection = nil
    end
    
    if NoFishingAnimation.AnimationBlocker then
        NoFishingAnimation.AnimationBlocker:Disconnect()
        NoFishingAnimation.AnimationBlocker = nil
    end
    
    if NoFishingAnimation.ReelingTrack then
        NoFishingAnimation.ReelingTrack:Stop()
        NoFishingAnimation.ReelingTrack = nil
    end
    
    NoFishingAnimation.SavedPose = {}
end

function NoFishingAnimation.Start()
    if NoFishingAnimation.Enabled then
        return false, "Already enabled"
    end
    
    local character = localPlayer.Character
    if not character then 
        return false, "Character not found"
    end
    
    -- 1. Cari atau buat ReelingIdle animation
    local reelingTrack = getOrCreateReelingAnimation()
    
    if reelingTrack then
        -- 2. Play animasi (pause setelah beberapa frame)
        reelingTrack:Play()
        reelingTrack:AdjustSpeed(0) -- Pause animasi di frame pertama
        
        NoFishingAnimation.ReelingTrack = reelingTrack
        
        -- 3. Tunggu animasi apply ke Motor6D
        task.wait(0.2)
        
        -- 4. Capture pose
        local success = capturePose()
        
        if success then
            -- 5. KILL semua animasi
            killAllAnimations()
            
            -- 6. Block animasi baru
            blockNewAnimations()
            
            -- 7. Enable freeze
            NoFishingAnimation.Enabled = true
            freezePose()
            
            return true, "Pose frozen successfully"
        else
            reelingTrack:Stop()
            return false, "Failed to capture pose"
        end
    else
        return false, "Reeling animation not found"
    end
end

-- Fungsi Start dengan delay (RECOMMENDED)
function NoFishingAnimation.StartWithDelay(delay, callback)
    if NoFishingAnimation.Enabled then
        return false, "Already enabled"
    end
    
    delay = delay or 2
    
    -- Jalankan di coroutine agar tidak blocking
    task.spawn(function()
        task.wait(delay)
        
        local success = capturePose()
        
        if success then
            -- KILL semua animasi
            killAllAnimations()
            
            -- Block animasi baru
            blockNewAnimations()
            
            -- Enable freeze
            NoFishingAnimation.Enabled = true
            freezePose()
            
            -- Callback jika ada
            if callback then
                callback(true, "Pose frozen successfully")
            end
        else
            -- Callback error
            if callback then
                callback(false, "Failed to capture pose")
            end
        end
    end)
    
    return true, "Starting with delay..."
end

-- Fungsi Stop
function NoFishingAnimation.Stop()
    if not NoFishingAnimation.Enabled then
        return false, "Already disabled"
    end
    
    NoFishingAnimation.Enabled = false
    stopFreeze()
    
    return true, "Pose unfrozen"
end

-- Fungsi untuk cek status
function NoFishingAnimation.IsEnabled()
    return NoFishingAnimation.Enabled
end

-- Handle respawn
localPlayer.CharacterAdded:Connect(function(character)
    if NoFishingAnimation.Enabled then
        NoFishingAnimation.Enabled = false
        stopFreeze()
    end
end)

-- Cleanup
Players.PlayerRemoving:Connect(function(player)
    if player == localPlayer then
        if NoFishingAnimation.Enabled then
            NoFishingAnimation.Stop()
        end
    end
end)

return NoFishingAnimation
end)()

CombinedModules.AutoEquipRod = (function()
    local AutoEquipRod = {}

    local v0 = {
        Players = Players,
        RS = ReplicatedStorage
    }

    local success, v5 = pcall(function()
        return {
            Net = v0.RS.Packages._Index["sleitnick_net@0.2.0"].net,
            PlayerStatsUtility = require(v0.RS.Shared.PlayerStatsUtility),
            ItemUtility = require(v0.RS.Shared.ItemUtility)
        }
    end)

    if not success then
        AutoEquipRod.isSupported = false
        AutoEquipRod.Start = function() end
        AutoEquipRod.Stop = function() end
        return AutoEquipRod
    end

    local v6Success, v6 = pcall(function()
        return {
            Events = {
                REEquip = (EventResolver and EventResolver:GetRE("EquipToolFromHotbar")) or v5.Net["RE/EquipToolFromHotbar"]
            }
        }
    end)

    if not v6Success then
        AutoEquipRod.isSupported = false
        AutoEquipRod.Start = function() end
        AutoEquipRod.Stop = function() end
        return AutoEquipRod
    end

    local v7Success, v7 = pcall(function()
        return {
            Data = require(v0.RS.Packages.Replion).Client:WaitReplion("Data")
        }
    end)

    if not v7Success then
        AutoEquipRod.isSupported = false
        AutoEquipRod.Start = function() end
        AutoEquipRod.Stop = function() end
        return AutoEquipRod
    end

    AutoEquipRod.isSupported = true

    local v8 = {
        autoEquipRod = false,
        loopConnection = nil
    }

    local function isRodEquipped()
        local success, result = pcall(function()
            local v217 = v7.Data:Get("EquippedId")
            if not v217 then
                return false
            end
            
            local equippedItem = v5.PlayerStatsUtility:GetItemFromInventory(v7.Data, function(v218)
                return v218.UUID == v217
            end)
            
            if not equippedItem then
                return false
            end
            
            local itemData = v5.ItemUtility:GetItemData(equippedItem.Id)
            return itemData and itemData.Data.Type == "Fishing Rods"
        end)
        
        return success and result or false
    end

    local function equipRod()
        pcall(function()
            if not isRodEquipped() then
                v6.Events.REEquip:FireServer(1)
            end
        end)
    end

    function AutoEquipRod.Start()
        v8.autoEquipRod = true
        
        if v8.loopConnection then
            v8.loopConnection:Disconnect()
        end
        
        v8.loopConnection = task.spawn(function()
            while v8.autoEquipRod do
                equipRod()
                task.wait(1)
            end
        end)
    end

    function AutoEquipRod.Stop()
        v8.autoEquipRod = false
        
        if v8.loopConnection then
            task.cancel(v8.loopConnection)
            v8.loopConnection = nil
        end
    end

    return AutoEquipRod
end)()

CombinedModules.LockPosition = (function()

local LockPosition = {}
LockPosition.Enabled = false
LockPosition.LockedPos = nil
LockPosition.Connection = nil

function LockPosition.Start()
    if LockPosition.Enabled then return end
    LockPosition.Enabled = true
    local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    LockPosition.LockedPos = hrp.CFrame

    LockPosition.Connection = RunService.Heartbeat:Connect(function()
        if not LockPosition.Enabled then return end

        local c = player.Character
        if not c then return end
        
        local hrp2 = c:FindFirstChild("HumanoidRootPart")
        if not hrp2 then return end

        hrp2.CFrame = LockPosition.LockedPos
    
    end)
end

function LockPosition.Stop()
    LockPosition.Enabled = false

    if LockPosition.Connection then
        LockPosition.Connection:Disconnect()
        LockPosition.Connection = nil
    end
end

return LockPosition
end)()

CombinedModules.DisableCutscenes = (function()
    local DisableCutscenes = {}
    
    local CutsceneController = nil
    local OldPlayCutscene = nil
    local isDisabled = false
    
    local function initializeCutsceneHook()
        pcall(function()
            CutsceneController = require(game:GetService("ReplicatedStorage"):WaitForChild("Controllers"):WaitForChild("CutsceneController"))
            if CutsceneController and CutsceneController.Play then
                OldPlayCutscene = CutsceneController.Play
                
                CutsceneController.Play = function(self, ...)
                    if isDisabled then
                        return 
                    end
                    return OldPlayCutscene(self, ...)
                end
            end
        end)
    end
    
    initializeCutsceneHook()
    
    function DisableCutscenes.Start()
        if isDisabled then return end
        isDisabled = true
        
        if not CutsceneController then
            initializeCutsceneHook()
        end
    end
    
    function DisableCutscenes.Stop()
        if not isDisabled then return end
        isDisabled = false
    end
    
    function DisableCutscenes.IsHooked()
        return CutsceneController ~= nil and OldPlayCutscene ~= nil
    end
    
    return DisableCutscenes
end)()

CombinedModules.PingPanel = (function()
local PingMonitor = {}
PingMonitor.__index = PingMonitor

local updateConnection
local gui = {}
local isVisible = false

local Theme = {
    BgColor = Color3.fromRGB(15, 15, 20),
    StrokeColor = Color3.fromRGB(255, 140, 50),
    HeaderText = Color3.fromRGB(255, 140, 50),
    SubText = Color3.fromRGB(180, 180, 180),
    GoodColor = Color3.fromRGB(100, 255, 150),
    WarnColor = Color3.fromRGB(255, 220, 100),
    BadColor = Color3.fromRGB(255, 100, 100),
    NotifColor = Color3.fromRGB(255, 235, 100)
}

local function createMonitorGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LynxPanelMonitor"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screenGui.DisplayOrder = 999999
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = CoreGui
    
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, 200, 0, 45)
    container.Position = UDim2.new(0.5, -100, 0, 15)
    container.BackgroundColor3 = Theme.BgColor
    container.BackgroundTransparency = 0.25
    container.BorderSizePixel = 0
    container.Visible = false
    container.Parent = screenGui
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 10)
    containerCorner.Parent = container
    
    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Theme.StrokeColor
    stroke.Thickness = 1.5
    stroke.Transparency = 0.6
    stroke.Parent = container
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Theme.BgColor),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 35))
    }
    gradient.Rotation = 45
    gradient.Parent = container
    
    local logoIcon = Instance.new("ImageLabel")
    logoIcon.Name = "LogoIcon"
    logoIcon.Size = UDim2.new(0, 32, 0, 32)
    logoIcon.Position = UDim2.new(0, 6, 0.5, -16)
    logoIcon.BackgroundTransparency = 1
    logoIcon.Image = "rbxassetid://118176705805619"
    logoIcon.ScaleType = Enum.ScaleType.Fit
    logoIcon.Parent = container
    
    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 6)
    logoCorner.Parent = logoIcon
    
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -46, 1, 0)
    content.Position = UDim2.new(0, 43, 0, 0)
    content.BackgroundTransparency = 1
    content.Parent = container
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -8, 0, 14)
    titleLabel.Position = UDim2.new(0, 4, 0, 4)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "LYNX PANEL"
    titleLabel.TextColor3 = Theme.HeaderText
    titleLabel.TextSize = 11
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Top
    titleLabel.Parent = content
    
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Name = "StatsLabel"
    statsLabel.Size = UDim2.new(1, -8, 0, 16)
    statsLabel.Position = UDim2.new(0, 4, 0, 16)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text = "Ping: --ms | CPU: --ms | FPS: --"
    statsLabel.TextColor3 = Theme.SubText
    statsLabel.TextSize = 9
    statsLabel.Font = Enum.Font.GothamBold
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.TextYAlignment = Enum.TextYAlignment.Top
    statsLabel.RichText = true
    statsLabel.Parent = content
    
    local notifLabel = Instance.new("TextLabel")
    notifLabel.Name = "NotifLabel"
    notifLabel.Size = UDim2.new(1, -8, 0, 12)
    notifLabel.Position = UDim2.new(0, 4, 0, 32)
    notifLabel.BackgroundTransparency = 1
    notifLabel.Text = "Notifications : 0"
    notifLabel.TextColor3 = Theme.SubText
    notifLabel.TextSize = 9
    notifLabel.Font = Enum.Font.GothamBold
    notifLabel.TextXAlignment = Enum.TextXAlignment.Left
    notifLabel.TextYAlignment = Enum.TextYAlignment.Top
    notifLabel.Parent = content
    
    local dragging = false
    local dragInput, dragStart, startPos
    
    container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = container.Position
            
            TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0.3, Thickness = 2}):Play()
            TweenService:Create(container, TweenInfo.new(0.2), {BackgroundTransparency = 0.15}):Play()
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 0.6, Thickness = 1.5}):Play()
                    TweenService:Create(container, TweenInfo.new(0.3), {BackgroundTransparency = 0.25}):Play()
                end
            end)
        end
    end)
    
    container.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            container.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    return {
        ScreenGui = screenGui,
        Container = container,
        StatsLabel = statsLabel,
        NotifLabel = notifLabel,
        Stroke = stroke
    }
end

local function getPing()
    local ping = 0
    pcall(function()
        local networkStats = Stats:FindFirstChild("Network")
        if networkStats then
            local serverStatsItem = networkStats:FindFirstChild("ServerStatsItem")
            if serverStatsItem then
                ping = math.floor(serverStatsItem["Data Ping"]:GetValue())
            end
        end
        
        if ping == 0 then
            ping = math.floor(player:GetNetworkPing() * 1000)
        end
    end)
    return ping
end

local function getNotificationCount()
    local count = 0
    
    pcall(function()
        local playerGui = player.PlayerGui
        if playerGui then
            local textNotifications = playerGui:FindFirstChild("Text Notifications")
            if textNotifications then
                local frame = textNotifications:FindFirstChild("Frame")
                if frame then
                    for _, child in ipairs(frame:GetChildren()) do
                        if child.Name == "Tile" and child:IsA("Frame") then
                            count = count + 1
                        end
                    end
                end
            end
        end
    end)
    
    return count
end

local function getColorTag(value, thresholds, reversed)
    local color
    if reversed then
        if value >= thresholds[1] then
            color = Theme.GoodColor
        elseif value >= thresholds[2] then
            color = Theme.WarnColor
        else
            color = Theme.BadColor
        end
    else
        if value <= thresholds[1] then
            color = Theme.GoodColor
        elseif value <= thresholds[2] then
            color = Theme.WarnColor
        else
            color = Theme.BadColor
        end
    end
    
    return string.format('<font color="rgb(%d,%d,%d)">', 
        math.floor(color.R * 255), 
        math.floor(color.G * 255), 
        math.floor(color.B * 255))
end

local function initializeGUI()
    local existing = CoreGui:FindFirstChild("LynxPanelMonitor")
    if existing then
        existing:Destroy()
        task.wait(0.1)
    end
    
    gui = createMonitorGUI()
end

function PingMonitor:Show()
    if not gui or not gui.ScreenGui then
        initializeGUI()
    end
    
    if gui and gui.Container then
        gui.Container.Visible = true
        isVisible = true
        
        -- Fade in animation
        gui.Container.BackgroundTransparency = 1
        TweenService:Create(
            gui.Container,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.25}
        ):Play()
        
        -- Update loop
        local lastUpdate = 0
        local fpsAccumulator = 0
        local cpuSmooth = 0
        local currentFPS = 0
        local lastNotifCount = 0
        
        updateConnection = RunService.Heartbeat:Connect(function(dt)
            if not gui or not gui.ScreenGui or not gui.ScreenGui.Parent or not isVisible then
                if updateConnection then
                    updateConnection:Disconnect()
                end
                return
            end
            
            -- FPS Calculation
            fpsAccumulator = fpsAccumulator + dt
            if fpsAccumulator >= 0.5 then
                currentFPS = math.floor(1 / dt)
                fpsAccumulator = 0
            end
            
            -- CPU Calculation (smoothed)
            local rawLoad = math.clamp((dt / 0.01667) * 35, 0, 100)
            cpuSmooth = (cpuSmooth * 0.9) + (rawLoad * 0.1)
            
            -- Update display periodically
            local currentTime = tick()
            if currentTime - lastUpdate >= 0.35 then
                local ping = getPing()
                local cpu = math.floor(cpuSmooth)
                local notifCount = getNotificationCount()
                
                -- Build colored text for stats
                local pingColor = getColorTag(ping, {50, 100}, false)
                local cpuColor = getColorTag(cpu, {50, 80}, false)
                local fpsColor = getColorTag(currentFPS, {50, 30}, true)
                
                gui.StatsLabel.Text = string.format(
                    "Ping: %s%dms</font> | CPU: %s%dms</font> | FPS: %s%d</font>",
                    pingColor, ping,
                    cpuColor, cpu,
                    fpsColor, currentFPS
                )
                
                -- Update notification count
                gui.NotifLabel.Text = string.format("Notifications : %d", notifCount)
                
                lastNotifCount = notifCount
                lastUpdate = currentTime
            end
        end)
    end
end

function PingMonitor:Hide()
    if gui and gui.Container then
        TweenService:Create(
            gui.Container,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {BackgroundTransparency = 1}
        ):Play()
        
        task.wait(0.3)
        gui.Container.Visible = false
        isVisible = false
        
        if updateConnection then
            updateConnection:Disconnect()
            updateConnection = nil
        end
    end
end

function PingMonitor:Destroy()
    if updateConnection then
        updateConnection:Disconnect()
    end
    if gui and gui.ScreenGui then
        gui.ScreenGui:Destroy()
    end
    gui = {}
end

return PingMonitor
end)()

-- Module DisableExtras
CombinedModules.DisableExtras = (function()
local module = {}

local VFXFolder = ReplicatedStorage:WaitForChild("VFX")
local DisableNotificationConnection = nil
local isVFXDisabled = false

-- Deteksi support untuk override module
local supportsModuleOverride = false
local VFXControllerModule = nil
local originalVFXHandle = nil
local originalRenderAtPoint = nil
local originalRenderInstance = nil

-- Cek apakah executor support override module functions
local success = pcall(function()
    VFXControllerModule = require(ReplicatedStorage:WaitForChild("Controllers").VFXController)
    originalVFXHandle = VFXControllerModule.Handle
    originalRenderAtPoint = VFXControllerModule.RenderAtPoint
    originalRenderInstance = VFXControllerModule.RenderInstance
    supportsModuleOverride = true
end)

if not success then
    warn("[DisableExtras] Module override not supported, using fallback method (delete)")
end

function module.StartSmallNotification()
    if DisableNotificationConnection then return end
    
    local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui
    local SmallNotification = PlayerGui:FindFirstChild("Small Notification")
    
    if not SmallNotification then
        SmallNotification = PlayerGui:WaitForChild("Small Notification", 5)
        if not SmallNotification then
            return false
        end
    end
    
    -- Sekali disable saja, tidak perlu RenderStepped setiap frame
    SmallNotification.Enabled = false
    
    -- Gunakan event untuk handle kalau game re-enable
    DisableNotificationConnection = SmallNotification:GetPropertyChangedSignal("Enabled"):Connect(function()
        if SmallNotification.Enabled then
            SmallNotification.Enabled = false
        end
    end)
end

function module.StopSmallNotification()
    if DisableNotificationConnection then
        DisableNotificationConnection:Disconnect()
        DisableNotificationConnection = nil
    end
    
    local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui
    local SmallNotification = PlayerGui:FindFirstChild("Small Notification")
    if SmallNotification then
        SmallNotification.Enabled = true
    end
end

local SkinEffectConnection = nil
local function disableDiveEffects()
    for _, child in pairs(VFXFolder:GetChildren()) do
        if child.Name:match("Dive$") then
            child:Destroy()
        end
    end
    
    local cosmeticFolder = workspace:FindFirstChild("CosmeticFolder")
    if cosmeticFolder then
        pcall(function() cosmeticFolder:ClearAllChildren() end)
    end
end

function module.StartSkinEffect()
    if isVFXDisabled then return end
    isVFXDisabled = true
    
    if supportsModuleOverride then
        VFXControllerModule.Handle = function(...) end
        VFXControllerModule.RenderAtPoint = function(...) end
        VFXControllerModule.RenderInstance = function(...) end
        
        local cosmeticFolder = workspace:FindFirstChild("CosmeticFolder")
        if cosmeticFolder then
            pcall(function() cosmeticFolder:ClearAllChildren() end)
        end
    else
        disableDiveEffects()
        
        -- Event-driven saja, tidak perlu Heartbeat setiap frame
        -- ChildAdded sudah cukup untuk handle VFX baru
        
        VFXFolder.ChildAdded:Connect(function(child)
            if isVFXDisabled and child.Name:match("Dive$") then
                child:Destroy()
            end
        end)
        
        local cosmeticFolder = workspace:FindFirstChild("CosmeticFolder")
        if cosmeticFolder then
            cosmeticFolder.ChildAdded:Connect(function(child)
                if isVFXDisabled then
                    child:Destroy()
                end
            end)
        end
    end
end

function module.StopSkinEffect()
    if not isVFXDisabled then return end
    isVFXDisabled = false
    
    if supportsModuleOverride then
        VFXControllerModule.Handle = originalVFXHandle
        VFXControllerModule.RenderAtPoint = originalRenderAtPoint
        VFXControllerModule.RenderInstance = originalRenderInstance
    else
        if SkinEffectConnection then
            SkinEffectConnection:Disconnect()
            SkinEffectConnection = nil
        end
    end
end

return module
end)()

CombinedModules.WalkOnWater = (function()

local WalkOnWater = {
	Enabled = false,
	Platform = nil,
	AlignPos = nil,
	Connection = nil
}

local PLATFORM_SIZE = 14
local OFFSET = 3
local LAST_WATER_Y = nil

local function GetCharacterReferences()
	local char = LocalPlayer.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return end

	return char, humanoid, hrp
end

local function ForceSurfaceLift()
	local _, humanoid, hrp = GetCharacterReferences()
	if not humanoid or not hrp then return end

	if humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then
		return
	end

	for _ = 1, 60 do
		hrp.Velocity = Vector3.new(0, 80, 0)
		task.wait(0.03)

		if humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then
			break
		end
	end

	hrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
end

local function GetWaterHeight()
	local _, _, hrp = GetCharacterReferences()
	if not hrp then return LAST_WATER_Y end

	local origin = hrp.Position + Vector3.new(0, 5, 0)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = { LocalPlayer.Character }
	params.IgnoreWater = false

	local result = Workspace:Raycast(
		origin,
		Vector3.new(0, -600, 0),
		params
	)

	if result then
		LAST_WATER_Y = result.Position.Y
		return LAST_WATER_Y
	end

	return LAST_WATER_Y
end

local function CreatePlatform()
	if WalkOnWater.Platform then
		WalkOnWater.Platform:Destroy()
	end

	local p = Instance.new("Part")
	p.Size = Vector3.new(PLATFORM_SIZE, 1, PLATFORM_SIZE)
	p.Anchored = true
	p.CanCollide = true
	p.Transparency = 1
	p.CanQuery = false
	p.CanTouch = false
	p.Name = "WaterLockPlatform"
	p.Parent = Workspace

	WalkOnWater.Platform = p
end

local function SetupAlign()
	local _, _, hrp = GetCharacterReferences()
	if not hrp then return false end

	if WalkOnWater.AlignPos then
		WalkOnWater.AlignPos:Destroy()
	end

	local att = hrp:FindFirstChild("RootAttachment")
	if not att then
		att = Instance.new("Attachment")
		att.Name = "RootAttachment"
		att.Parent = hrp
	end

	local ap = Instance.new("AlignPosition")
	ap.Attachment0 = att
	ap.MaxForce = math.huge
	ap.MaxVelocity = math.huge
	ap.Responsiveness = 200
	ap.RigidityEnabled = true
	ap.Parent = hrp

	WalkOnWater.AlignPos = ap
	return true
end

local function Cleanup()
	if WalkOnWater.Connection then
		WalkOnWater.Connection:Disconnect()
		WalkOnWater.Connection = nil
	end

	if WalkOnWater.AlignPos then
		WalkOnWater.AlignPos:Destroy()
		WalkOnWater.AlignPos = nil
	end

	if WalkOnWater.Platform then
		WalkOnWater.Platform:Destroy()
		WalkOnWater.Platform = nil
	end
end

function WalkOnWater.Start()
	if WalkOnWater.Enabled then return end

	local char, humanoid, hrp = GetCharacterReferences()
	if not char or not humanoid or not hrp then return end

	ForceSurfaceLift()

	WalkOnWater.Enabled = true
	LAST_WATER_Y = nil

	CreatePlatform()
	if not SetupAlign() then
		WalkOnWater.Enabled = false
		Cleanup()
		return
	end

	WalkOnWater.Connection = RunService.Heartbeat:Connect(function()
		if not WalkOnWater.Enabled then return end

		local _, _, currentHRP = GetCharacterReferences()
		if not currentHRP then return end

		local waterY = GetWaterHeight()
		if not waterY then return end

		if WalkOnWater.Platform then
			WalkOnWater.Platform.CFrame = CFrame.new(
				currentHRP.Position.X,
				waterY - 0.5,
				currentHRP.Position.Z
			)
		end

		if WalkOnWater.AlignPos then
			WalkOnWater.AlignPos.Position = Vector3.new(
				currentHRP.Position.X,
				waterY + OFFSET,
				currentHRP.Position.Z
			)
		end
	end)
end

function WalkOnWater.Stop()
	WalkOnWater.Enabled = false
	Cleanup()
end

LocalPlayer.CharacterAdded:Connect(function()
	if WalkOnWater.Enabled then
		task.wait(0.5)
		Cleanup()
		WalkOnWater.Enabled = false
		WalkOnWater.Start()
	end
end)
return WalkOnWater
end)()

CombinedModules.SkinSwapAnimation = (function()

local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")

local Animator = humanoid:FindFirstChildOfClass("Animator")
if not Animator then
    Animator = Instance.new("Animator", humanoid)
end

local SkinAnimation = {}
SkinAnimation.Connections = {}

local SkinDatabase = {
    ["Eclipse"] = "rbxassetid://107940819382815",
    ["HolyTrident"] = "rbxassetid://128167068291703",
    ["SoulScythe"] = "rbxassetid://82259219343456",
    ["OceanicHarpoon"] = "rbxassetid://76325124055693",
    ["BinaryEdge"] = "rbxassetid://109653945741202",
    ["Vanquisher"] = "rbxassetid://93884986836266",
    ["KrampusScythe"] = "rbxassetid://134934781977605",
    ["BanHammer"] = "rbxassetid://96285280763544",
    ["CorruptionEdge"] = "rbxassetid://126613975718573",
    ["PrincessParasol"] = "rbxassetid://99143072029495"
}

local CurrentSkin = nil
local AnimationPool = {}
local IsEnabled = false
local POOL_SIZE = 3

local killedTracks = {}
local replaceCount = 0
local currentPoolIndex = 1

local function LoadAnimationPool(skinId)
    local animId = SkinDatabase[skinId]
    if not animId then
        return false
    end
    
    for _, track in ipairs(AnimationPool) do
        pcall(function()
            track:Stop(0)
            track:Destroy()
        end)
    end
    AnimationPool = {}
    
    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    anim.Name = "CUSTOM_SKIN_ANIM"
    
    for i = 1, POOL_SIZE do
        local track = Animator:LoadAnimation(anim)
        track.Priority = Enum.AnimationPriority.Action4
        track.Looped = false
        track.Name = "SKIN_POOL_" .. i
        
        task.spawn(function()
            pcall(function()
                track:Play(0, 1, 0)
                task.wait(0.05)
                track:Stop(0)
            end)
        end)
        
        table.insert(AnimationPool, track)
    end
    
    currentPoolIndex = 1
    return true
end

local function GetNextTrack()
    for i = 1, POOL_SIZE do
        local track = AnimationPool[i]
        if track and not track.IsPlaying then
            return track
        end
    end
    
    currentPoolIndex = currentPoolIndex % POOL_SIZE + 1
    return AnimationPool[currentPoolIndex]
end

local function IsFishCaughtAnimation(track)
    if not track or not track.Animation then return false end
    
    local trackName = string.lower(track.Name or "")
    local animName = string.lower(track.Animation.Name or "")
    
    if string.find(trackName, "fishcaught") or 
       string.find(animName, "fishcaught") or
       string.find(trackName, "caught") or 
       string.find(animName, "caught") then
        return true
    end
    
    return false
end

local function InstantReplace(originalTrack)
    local nextTrack = GetNextTrack()
    if not nextTrack then return end
    
    replaceCount = replaceCount + 1
    killedTracks[originalTrack] = tick()
    
    task.spawn(function()
        for i = 1, 10 do
            pcall(function()
                if originalTrack.IsPlaying then
                    originalTrack:Stop(0)
                    originalTrack:AdjustSpeed(0)
                    originalTrack.TimePosition = 0
                end
            end)
            task.wait()
        end
    end)
    
    pcall(function()
        if nextTrack.IsPlaying then
            nextTrack:Stop(0)
        end
        nextTrack:Play(0, 1, 1)
        nextTrack:AdjustSpeed(1)
    end)
    
    task.delay(1, function()
        killedTracks[originalTrack] = nil
    end)
end

player.CharacterAdded:Connect(function(newChar)
    task.wait(1.5)
    
    char = newChar
    humanoid = char:WaitForChild("Humanoid")
    Animator = humanoid:FindFirstChildOfClass("Animator")
    if not Animator then
        Animator = Instance.new("Animator", humanoid)
    end
    
    killedTracks = {}
    replaceCount = 0
    
    if IsEnabled and CurrentSkin then
        task.wait(0.5)
        LoadAnimationPool(CurrentSkin)
        
        if SkinAnimation.Connections.AnimationPlayed then
            SkinAnimation.Connections.AnimationPlayed:Disconnect()
        end
        SkinAnimation.Connections.AnimationPlayed = humanoid.AnimationPlayed:Connect(function(track)
            if not IsEnabled then return end
            if IsFishCaughtAnimation(track) then
                task.spawn(function()
                    InstantReplace(track)
                end)
            end
        end)
    end
end)

function SkinAnimation.SwitchSkin(skinId)
    if not SkinDatabase[skinId] then
        return false
    end
    
    CurrentSkin = skinId
    
    if IsEnabled then
        return LoadAnimationPool(skinId)
    end
    
    return true
end

function SkinAnimation.Enable()
    if IsEnabled then
        return false
    end
    
    if not CurrentSkin then
        return false
    end
    
    local success = LoadAnimationPool(CurrentSkin)
    if success then
        IsEnabled = true
        killedTracks = {}
        replaceCount = 0
        
        SkinAnimation.Connections.AnimationPlayed = humanoid.AnimationPlayed:Connect(function(track)
            if not IsEnabled then return end
            if IsFishCaughtAnimation(track) then
                task.spawn(function()
                    InstantReplace(track)
                end)
            end
        end)
        
        -- SATU connection saja (gabungan RenderStepped + Heartbeat + Stepped)
        -- Menghemat CPU karena hanya 1x iterasi tracks per frame, bukan 3x
        SkinAnimation.Connections.Heartbeat = RunService.Heartbeat:Connect(function()
            if not IsEnabled then return end
            
            local tracks = humanoid:GetPlayingAnimationTracks()
            
            for _, track in ipairs(tracks) do
                if string.find(string.lower(track.Name or ""), "skin_pool") then
                    continue
                end
                
                -- Stop killed tracks (dulu di Heartbeat + Stepped)
                if killedTracks[track] then
                    if track.IsPlaying then
                        pcall(function()
                            track:Stop(0)
                            track:AdjustSpeed(0)
                        end)
                    end
                    continue
                end
                
                -- Detect & replace fish caught animation (dulu di RenderStepped)
                if track.IsPlaying and IsFishCaughtAnimation(track) then
                    task.spawn(function()
                        InstantReplace(track)
                    end)
                end
            end
        end)
        
        return true
    end
    
    return false
end

function SkinAnimation.Disable()
    if not IsEnabled then
        return false
    end
    
    IsEnabled = false
    killedTracks = {}
    replaceCount = 0
    
    for name, conn in pairs(SkinAnimation.Connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    SkinAnimation.Connections = {}
    
    for _, track in ipairs(AnimationPool) do
        pcall(function()
            track:Stop(0)
        end)
    end
    
    return true
end

function SkinAnimation.IsEnabled()
    return IsEnabled
end

function SkinAnimation.GetCurrentSkin()
    return CurrentSkin
end

function SkinAnimation.GetReplaceCount()
    return replaceCount
end

return SkinAnimation
end)()

CombinedModules.AutoTotem3X = (function()
    local AutoTotem3X = {}
    
    local RS = ReplicatedStorage
    local LP = localPlayer
    
    local Net = RS.Packages["_Index"]["sleitnick_net@0.2.0"].net
    local RE_EquipToolFromHotbar = (EventResolver and EventResolver:GetRE("EquipToolFromHotbar")) or Net["RE/EquipToolFromHotbar"]
    
    local HOTBAR_SLOT = 2
    local CLICK_COUNT = 5
    local CLICK_DELAY = 0.2
    local TRIANGLE_RADIUS = 58
    local CENTER_OFFSET = Vector3.new(0, 0, -7.25)
    
    local isRunning = false
    local currentTask = nil
    
    local function tp(pos)
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = CFrame.new(pos)
            task.wait(0.5)
            return true
        end
        return false
    end
    
    local function equipTotem()
        local success = pcall(function()
            RE_EquipToolFromHotbar:FireServer(HOTBAR_SLOT)
        end)
        task.wait(1.5)
        return success
    end
    
    local function autoClick()
        for i = 1, CLICK_COUNT do
            if not isRunning then break end
            
            pcall(function()
                VirtualUser:Button1Down(Vector2.new(0, 0))
                task.wait(0.05)
                VirtualUser:Button1Up(Vector2.new(0, 0))
            end)
            task.wait(CLICK_DELAY)
            
            local char = LP.Character
            if char then
                for _, tool in pairs(char:GetChildren()) do
                    if tool:IsA("Tool") then
                        pcall(function()
                            tool:Activate()
                        end)
                    end
                end
            end
            task.wait(CLICK_DELAY)
        end
    end
    
    function AutoTotem3X.Start()
        
        if isRunning then
            return false, "Auto Totem sudah berjalan"
        end
        
        if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then
            return false, "Character tidak ditemukan"
        end
        
        isRunning = true
        
        currentTask = task.spawn(function()
            local success, err = pcall(function()
                local char = LP.Character or LP.CharacterAdded:Wait()
                local root = char:WaitForChild("HumanoidRootPart")
                
                local centerPos = root.Position
                local adjustedCenter = centerPos + CENTER_OFFSET
                
                local angles = {90, 210, 330}
                local totemPositions = {}
                
                for i, angleDeg in ipairs(angles) do
                    local angleRad = math.rad(angleDeg)
                    local offsetX = TRIANGLE_RADIUS * math.cos(angleRad)
                    local offsetZ = TRIANGLE_RADIUS * math.sin(angleRad)
                    table.insert(totemPositions, adjustedCenter + Vector3.new(offsetX, 0, offsetZ))
                end
                
                for i, pos in ipairs(totemPositions) do
                    if not isRunning then 
                        break 
                    end
                    
                    tp(pos)
                    equipTotem()
                    autoClick()
                    task.wait(2)
                end
                
                if isRunning then
                    tp(centerPos)
                    task.wait(1)
                end
            end)
            
            if not success then
                warn("[AutoTotem3X] Error: " .. tostring(err))
            end
            
            isRunning = false
            currentTask = nil
        end)
        
        return true, "Auto Totem 3X dimulai"
    end
    
    function AutoTotem3X.Stop()
        
        if not isRunning then
            return false, "Auto Totem tidak sedang berjalan"
        end
        
        isRunning = false
        
        if currentTask then
            task.cancel(currentTask)
            currentTask = nil
        end
        
        return true, "Auto Totem 3X dihentikan"
    end
    
    function AutoTotem3X.IsRunning()
        return isRunning
    end
    
    return AutoTotem3X
end)()

CombinedModules.AutoFavorite = (function()
local AutoFavoriteModule = {}

local v0 = {
    RS = ReplicatedStorage,
    Players = Players
}
local v5, v6, v7
local referencesInitialized = false
local onChangeConnected = false
local isScanning = false

local TIER_NAMES = {
    [1] = "Common",
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Mythic",
    [7] = "SECRET"
}

local function InitializeReferences()
    if referencesInitialized then return true end
    
    local success = pcall(function()
        v5 = {
            Net = v0.RS.Packages._Index["sleitnick_net@0.2.0"].net,
            ItemUtility = require(v0.RS.Shared.ItemUtility),
            PlayerStatsUtility = require(v0.RS.Shared.PlayerStatsUtility)
        }
        
        v6 = {
            Events = {
                REFav = (EventResolver and EventResolver:GetRE("FavoriteItem")) or v5.Net["RE/FavoriteItem"]
            }
        }
        
        v7 = {
            Data = require(v0.RS.Packages.Replion).Client:WaitReplion("Data"),
            Items = v0.RS:WaitForChild("Items"),
            Variants = v0.RS:WaitForChild("Variants")
        }
        
        referencesInitialized = true
    end)
    
    return success
end

local v8 = {
    selectedName = {},
    selectedRarity = {},
    selectedVariant = {},
    autoFavEnabled = false
}

local function toSet(arr)
    local set = {}
    for _, v in ipairs(arr) do
        set[v] = true
    end
    return set
end

local v11 = {}
local function BuildFishList()
    v11 = {}
    
    if not referencesInitialized then
        InitializeReferences()
    end
    
    if not v7 or not v7.Items then return v11 end
    
    pcall(function()
        for _, itemFolder in ipairs(v7.Items:GetChildren()) do
            if itemFolder:IsA("Folder") then
                for _, fishModule in ipairs(itemFolder:GetChildren()) do
                    if fishModule:IsA("ModuleScript") then
                        local success, fishData = pcall(require, fishModule)
                        if success and fishData and fishData.Data then
                            local displayName = fishData.Data.DisplayName or fishData.Data.Name
                            if displayName and not table.find(v11, displayName) then
                                table.insert(v11, displayName)
                            end
                        end
                    end
                end
            elseif itemFolder:IsA("ModuleScript") then
                local success, fishData = pcall(require, itemFolder)
                if success and fishData and fishData.Data then
                    local displayName = fishData.Data.DisplayName or fishData.Data.Name
                    if displayName and not table.find(v11, displayName) then
                        table.insert(v11, displayName)
                    end
                end
            end
        end
        table.sort(v11)
    end)
    
    return v11
end

local variantList = {}
local function BuildVariantList()
    variantList = {}
    
    if not referencesInitialized then
        InitializeReferences()
    end
    
    if not v7 or not v7.Variants then return variantList end
    
    pcall(function()
        for _, variantModule in ipairs(v7.Variants:GetChildren()) do
            if variantModule:IsA("ModuleScript") then
                local variantName = variantModule.Name
                if variantName and variantName ~= "1x1x1x1" and not table.find(variantList, variantName) then
                    table.insert(variantList, variantName)
                end
            end
        end
        table.sort(variantList)
    end)
    
    return variantList
end

local function scanInventory()
    if not v8.autoFavEnabled then return end
    if not referencesInitialized then return end
    if isScanning then return end
    
    local hasNameFilter = next(v8.selectedName) ~= nil
    local hasVariantFilter = next(v8.selectedVariant) ~= nil
    local hasRarityFilter = next(v8.selectedRarity) ~= nil
    
    if not hasNameFilter and not hasVariantFilter and not hasRarityFilter then
        return
    end
    
    isScanning = true
    
    pcall(function()
        local inventory = v7.Data:GetExpect({"Inventory", "Items"})
        
        for _, item in ipairs(inventory) do
            if not v8.autoFavEnabled then break end
            
            if item.Favorited then continue end
            
            local fishData = v5.ItemUtility:GetItemData(item.Id)
            if not fishData or not fishData.Data then continue end
            
            local fishName = fishData.Data.DisplayName or fishData.Data.Name
            local fishTier = fishData.Data.Tier
            local variantId = item.Metadata and item.Metadata.VariantId or "None"
            local tierName = TIER_NAMES[fishTier]
            
            local shouldFavorite = true
            
            if hasNameFilter then
                if not fishName or not v8.selectedName[fishName] then
                    shouldFavorite = false
                end
            end
            
            if shouldFavorite and hasVariantFilter then
                if variantId == "None" or not v8.selectedVariant[variantId] then
                    shouldFavorite = false
                end
            end
            
            if shouldFavorite and hasRarityFilter then
                if not tierName or not v8.selectedRarity[tierName] then
                    shouldFavorite = false
                end
            end
            
            if shouldFavorite then
                pcall(function()
                    v6.Events.REFav:FireServer(item.UUID)
                end)
                task.wait(0.15)
            end
        end
    end)
    
    isScanning = false
end

function AutoFavoriteModule.GetAllFishNames()
    if #v11 == 0 then
        BuildFishList()
    end
    return #v11 > 0 and v11 or {"No Fish Found"}
end

function AutoFavoriteModule.GetAllVariants()
    if #variantList == 0 then
        BuildVariantList()
    end
    return #variantList > 0 and variantList or {"No Variants Found"}
end

function AutoFavoriteModule.GetAllTiers()
    return {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret"}
end

function AutoFavoriteModule.SetSelectedNames(names)
    v8.selectedName = toSet(names)
    if v8.autoFavEnabled then
        task.spawn(scanInventory)
    end
end

function AutoFavoriteModule.SetSelectedRarity(rarities)
    v8.selectedRarity = toSet(rarities)
    if v8.autoFavEnabled then
        task.spawn(scanInventory)
    end
end

function AutoFavoriteModule.SetSelectedVariants(variants)
    v8.selectedVariant = toSet(variants)
    if v8.autoFavEnabled then
        task.spawn(scanInventory)
    end
end

function AutoFavoriteModule.GetCurrentMode()
    local hasNames = next(v8.selectedName) ~= nil
    local hasVariants = next(v8.selectedVariant) ~= nil
    local hasRarity = next(v8.selectedRarity) ~= nil
    
    local parts = {}
    if hasNames then table.insert(parts, "Name") end
    if hasVariants then table.insert(parts, "Variant") end
    if hasRarity then table.insert(parts, "Rarity") end
    
    if #parts == 0 then
        return "No Filter Selected"
    end
    
    return table.concat(parts, " + ") .. " (AND)"
end

function AutoFavoriteModule.Start()
    if not referencesInitialized then
        local success = InitializeReferences()
        if not success then
            return false, "Failed to initialize"
        end
    end
    
    v8.autoFavEnabled = true
    
    task.spawn(scanInventory)
    
    if v7 and v7.Data and not onChangeConnected then
        onChangeConnected = true
        v7.Data:OnChange({"Inventory", "Items"}, function()
            if v8.autoFavEnabled then
                task.spawn(function()
                    task.wait(0.3)
                    scanInventory()
                end)
            end
        end)
    end
    
    return true, "Started"
end

function AutoFavoriteModule.Stop()
    v8.autoFavEnabled = false
    return true, "Stopped"
end

function AutoFavoriteModule.RefreshLists()
    v11 = {}
    variantList = {}
    BuildFishList()
    BuildVariantList()
    return {
        FishCount = #v11,
        VariantCount = #variantList
    }
end

function AutoFavoriteModule.IsEnabled()
    return v8.autoFavEnabled
end

function AutoFavoriteModule.GetStatus()
    return {
        Enabled = v8.autoFavEnabled,
        Mode = AutoFavoriteModule.GetCurrentMode(),
        FishCount = #v11,
        VariantCount = #variantList,
        SelectedNames = v8.selectedName,
        SelectedRarity = v8.selectedRarity,
        SelectedVariants = v8.selectedVariant
    }
end

task.spawn(function()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    
    task.wait(1)
    
    local success = InitializeReferences()
    if success then
        BuildFishList()
        BuildVariantList()
    else
        task.wait(2)
        InitializeReferences()
        BuildFishList()
        BuildVariantList()
    end
end)

return AutoFavoriteModule
end)()

--AUTOMATION PAGE

CombinedModules.AutoSpawnTotem = (function()

    local AutoSpawnTotem = {}

    local RS = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")

    local SpawnTotemRemote = nil
    local clientData = nil
    local lastSpawnTime = nil
    
    local function InitializeRemotes()
        local success = pcall(function()
            SpawnTotemRemote = EventResolver and EventResolver:GetRE("SpawnTotem")
            if not SpawnTotemRemote then
                local Net = RS:WaitForChild("Packages", 5)
                    :WaitForChild("_Index", 5)
                    :WaitForChild("sleitnick_net@0.2.0", 5)
                    :WaitForChild("net", 5)
                SpawnTotemRemote = Net:WaitForChild("RE/SpawnTotem", 5)
            end
            
            local Replion = require(RS:WaitForChild("Packages", 5):WaitForChild("Replion", 5))
            clientData = Replion.Client:WaitReplion("Data")
        end)
        return success
    end

    -- ── Dynamic totem scan (pola sama seperti BuyCharm ← RS.Charms) ────────
    AutoSpawnTotem.TotemList = {} -- { { Name, Id, Price } }

    local function BuildTotemList()
        AutoSpawnTotem.TotemList = {}
        local ok, err = pcall(function()
            local totemsFolder = RS:WaitForChild("Totems", 8)
            if not totemsFolder then return end
            for _, totemModule in ipairs(totemsFolder:GetChildren()) do
                if totemModule:IsA("ModuleScript") then
                    local s, data = pcall(require, totemModule)
                    if s and type(data) == "table" and data.Data then
                        table.insert(AutoSpawnTotem.TotemList, {
                            Name  = tostring(data.Data.Name or totemModule.Name),
                            Id    = data.Data.Id,
                            Price = data.Price or 0
                        })
                    else
                        -- Fallback: pakai nama dari ModuleScript
                        table.insert(AutoSpawnTotem.TotemList, {
                            Name  = totemModule.Name,
                            Id    = nil,
                            Price = 0
                        })
                    end
                end
            end
            table.sort(AutoSpawnTotem.TotemList, function(a, b)
                return (a.Id or 9999) < (b.Id or 9999)
            end)
        end)
        if not ok then
            warn("[AutoSpawnTotem] Scan gagal: " .. tostring(err))
            -- Hardcoded fallback jika RS.Totems tidak ada
            AutoSpawnTotem.TotemList = {
                { Name = "Luck Totem",     Id = 1, Price = 0 },
                { Name = "Mutation Totem", Id = 2, Price = 0 },
                { Name = "Shiny Totem",    Id = 3, Price = 0 },
            }
        end
        return AutoSpawnTotem.TotemList
    end

    function AutoSpawnTotem.GetTotemNames()
        local names = {}
        for _, t in ipairs(AutoSpawnTotem.TotemList) do
            table.insert(names, t.Name)
        end
        return #names > 0 and names or {"Luck Totem", "Mutation Totem", "Shiny Totem"}
    end

    function AutoSpawnTotem.GetTotemList()
        return AutoSpawnTotem.TotemList
    end

    AutoSpawnTotem.Settings = {
        SelectedTotem  = nil,
        IsRunning      = false,
        SpawnInterval  = 3605  -- ~60 menit 5 detik
    }
    
    local AUTO_SPAWN_THREAD = nil

    local function GetTotemUUIDByName(totemName)
        if not clientData then return nil end
        local success, inv = pcall(function()
            return clientData:Get("Inventory")
        end)
        if not success or not inv then return nil end

        -- Cari Id dari TotemList
        local targetId = nil
        for _, t in ipairs(AutoSpawnTotem.TotemList) do
            if t.Name == totemName then
                targetId = t.Id
                break
            end
        end
        if not targetId then return nil end

        -- Cek di inv.Totems
        local totems = inv.Totems or inv.totems
        if not totems then return nil end
        for _, item in pairs(totems) do
            if item and item.UUID and tonumber(item.Id) == targetId then
                if (item.Count or 1) >= 1 then
                    return item.UUID
                end
            end
        end
        return nil
    end

    local function SpawnSingleTotem()
        local name = AutoSpawnTotem.Settings.SelectedTotem
        if not name then
            warn("[AutoSpawnTotem] Belum pilih totem!")
            return false
        end

        local uuid = GetTotemUUIDByName(name)
        if not uuid then
            warn(string.format("[AutoSpawnTotem] %s tidak ada di inventory!", name))
            return false
        end
        if not SpawnTotemRemote then
            warn("[AutoSpawnTotem] Remote belum siap!")
            return false
        end

        local ok = pcall(function()
            SpawnTotemRemote:FireServer(uuid)
        end)
        if ok then
            lastSpawnTime = os.time()
            return true
        else
            warn(string.format("[AutoSpawnTotem] Gagal spawn %s", name))
            return false
        end
    end

    local function RunAutoSpawnLoop()
        if AUTO_SPAWN_THREAD then
            pcall(task.cancel, AUTO_SPAWN_THREAD)
        end
        AUTO_SPAWN_THREAD = task.spawn(function()
            SpawnSingleTotem()
            while AutoSpawnTotem.Settings.IsRunning do
                task.wait(AutoSpawnTotem.Settings.SpawnInterval)
                if AutoSpawnTotem.Settings.IsRunning then
                    SpawnSingleTotem()
                end
            end
        end)
    end

    function AutoSpawnTotem.SetTotem(totemName)
        AutoSpawnTotem.Settings.SelectedTotem = totemName
        return true
    end

    function AutoSpawnTotem.GetCurrentTotem()
        return AutoSpawnTotem.Settings.SelectedTotem
    end

    function AutoSpawnTotem.SetInterval(seconds)
        seconds = tonumber(seconds)
        if seconds and seconds > 0 then
            AutoSpawnTotem.Settings.SpawnInterval = seconds
            return true
        end
        return false
    end

    function AutoSpawnTotem.GetInterval()
        return AutoSpawnTotem.Settings.SpawnInterval
    end

    function AutoSpawnTotem.Start()
        if AutoSpawnTotem.Settings.IsRunning then
            warn("[AutoSpawnTotem] Already running!")
            return false
        end
        if not SpawnTotemRemote then
            if not InitializeRemotes() then
                warn("[AutoSpawnTotem] Gagal init remotes!")
                return false
            end
        end
        AutoSpawnTotem.Settings.IsRunning = true
        RunAutoSpawnLoop()
        return true
    end

    function AutoSpawnTotem.Stop()
        if not AutoSpawnTotem.Settings.IsRunning then return false end
        AutoSpawnTotem.Settings.IsRunning = false
        if AUTO_SPAWN_THREAD then
            pcall(task.cancel, AUTO_SPAWN_THREAD)
            AUTO_SPAWN_THREAD = nil
        end
        return true
    end

    function AutoSpawnTotem.IsRunning()
        return AutoSpawnTotem.Settings.IsRunning
    end

    function AutoSpawnTotem.SpawnNow()
        return SpawnSingleTotem()
    end

    -- Untuk GUI status paragraph
    function AutoSpawnTotem.GetStatus()
        if not AutoSpawnTotem.Settings.IsRunning then
            return "Idle"
        end
        local interval = AutoSpawnTotem.Settings.SpawnInterval
        if lastSpawnTime then
            local elapsed = os.time() - lastSpawnTime
            local remaining = math.max(0, interval - elapsed)
            local mins = math.floor(remaining / 60)
            local secs = remaining % 60
            return string.format("Running | Next spawn in: %dm %ds", mins, secs)
        end
        return "Running | Menunggu spawn pertama..."
    end

    -- Refresh TotemList
    function AutoSpawnTotem.Refresh()
        return BuildTotemList()
    end

    -- Init saat module load
    task.spawn(function()
        task.wait(1)
        InitializeRemotes()
        BuildTotemList()
        -- Set default ke totem pertama
        if #AutoSpawnTotem.TotemList > 0 and not AutoSpawnTotem.Settings.SelectedTotem then
            AutoSpawnTotem.Settings.SelectedTotem = AutoSpawnTotem.TotemList[1].Name
        end
    end)

    return AutoSpawnTotem

end)()

-- Module: AutoClaimPirateChest
CombinedModules.AutoClaimPirateChest = {}

-- Variables
local AutoClaimEnabled = false
local ClaimInterval = 0.3
local LastClaimTime = 0
local ClaimConnection
local NewChestConnection

-- Get Remote Event
local ClaimPirateChestRemote = EventResolver and EventResolver:GetRE("ClaimPirateChest")
if not ClaimPirateChestRemote then
    pcall(function()
        ClaimPirateChestRemote = ReplicatedStorage:WaitForChild("Packages")
            :WaitForChild("_Index")
            :WaitForChild("sleitnick_net@0.2.0")
            :WaitForChild("net")
            :WaitForChild("RE/ClaimPirateChest")
    end)
end

-- Function to get all Pirate Chests
local function GetPirateChests()
    local chests = {}
    local chestStorage = Workspace:FindFirstChild("PirateChestStorage")
    
    if chestStorage then
        for _, chest in pairs(chestStorage:GetChildren()) do
            if chest:IsA("Model") then
                table.insert(chests, chest.Name)
            end
        end
    end
    
    return chests
end

-- Function to claim Pirate Chest
local function ClaimPirateChest(chestId)
    pcall(function()
        ClaimPirateChestRemote:FireServer(chestId)
    end)
end

-- Auto Claim Loop
local function AutoClaimLoop()
    local currentTime = tick()
    
    if currentTime - LastClaimTime >= ClaimInterval then
        LastClaimTime = currentTime
        
        local chests = GetPirateChests()
        
        for _, chestId in ipairs(chests) do
            ClaimPirateChest(chestId)
            task.wait(1.0)
        end
    end
end

-- Start Auto Claim
function CombinedModules.AutoClaimPirateChest.Start()
    if AutoClaimEnabled then return end
    
    AutoClaimEnabled = true
    
    -- Gunakan task loop biasa, bukan Heartbeat yang jalan setiap frame
    ClaimConnection = task.spawn(function()
        while AutoClaimEnabled do
            local chests = GetPirateChests()
            for _, chestId in ipairs(chests) do
                if not AutoClaimEnabled then break end
                ClaimPirateChest(chestId)
                task.wait(1.0)
            end
            task.wait(ClaimInterval)
        end
    end)
    
    -- Monitor for new chests
    NewChestConnection = Workspace.DescendantAdded:Connect(function(descendant)
        if AutoClaimEnabled and descendant.Parent and descendant.Parent.Name == "PirateChestStorage" then
            task.wait(0.2)
            if descendant:IsA("Model") then
                ClaimPirateChest(descendant.Name)
            end
        end
    end)
end

-- Stop Auto Claim
function CombinedModules.AutoClaimPirateChest.Stop()
    if not AutoClaimEnabled then return end
    
    AutoClaimEnabled = false
    
    if ClaimConnection then
        pcall(function() task.cancel(ClaimConnection) end)
        ClaimConnection = nil
    end
    
    if NewChestConnection then
        NewChestConnection:Disconnect()
        NewChestConnection = nil
    end
end

-- Check if running
function CombinedModules.AutoClaimPirateChest.IsRunning()
    return AutoClaimEnabled
end

CombinedModules.AutoLochNessEvent = {}

local LOCHNESS_CONFIG = {
    Coords = CFrame.lookAt(
        Vector3.new(6096.14, -585.92, 4669.50),
        Vector3.new(6096.14, -585.92, 4669.50) + Vector3.new(-0.8317, -0.4007, 0.3842)
    ),
    EventDuration = 600,
    
    ScheduleWIB = {
        {hour = 3, minute = 0},
        {hour = 7, minute = 0},
        {hour = 11, minute = 0},
        {hour = 15, minute = 0},
        {hour = 19, minute = 0},
        {hour = 23, minute = 0}
    }
}

local TIMEZONE_OFFSETS = {
    WIB = 7,
    WITA = 8,
    WIT = 9
}

local function getUserTimezoneOffset()
    local localTime = os.time()
    local utcTime = os.time(os.date("!*t"))
    local offsetSeconds = os.difftime(localTime, utcTime)
    return math.floor(offsetSeconds / 3600)
end

local function convertScheduleToLocal(scheduleWIB)
    local userOffset = getUserTimezoneOffset()
    local wibOffset = TIMEZONE_OFFSETS.WIB
    local hourDiff = userOffset - wibOffset
    
    local localSchedule = {}
    
    for _, event in ipairs(scheduleWIB) do
        local localHour = (event.hour + hourDiff) % 24
        table.insert(localSchedule, {
            hour = localHour,
            minute = event.minute
        })
    end
    
    table.sort(localSchedule, function(a, b)
        if a.hour == b.hour then
            return a.minute < b.minute
        end
        return a.hour < b.hour
    end)
    
    return localSchedule
end

local function getTimezoneName(offset)
    for name, tz_offset in pairs(TIMEZONE_OFFSETS) do
        if tz_offset == offset then
            return name
        end
    end
    return string.format("UTC%+d", offset)
end

local function getCurrentTime()
    local now = os.date("*t")
    return {
        hour = now.hour,
        minute = now.min,
        second = now.sec
    }
end

local function timeToSeconds(time)
    return (time.hour * 3600) + (time.minute * 60) + (time.second or 0)
end

local function getNextEvent(schedule)
    local currentTime = getCurrentTime()
    local currentSeconds = timeToSeconds(currentTime)
    
    for _, event in ipairs(schedule) do
        local eventSeconds = timeToSeconds(event)
        if eventSeconds > currentSeconds then
            return event, eventSeconds - currentSeconds
        end
    end
    
    local firstEvent = schedule[1]
    local secondsUntilMidnight = 86400 - currentSeconds
    local secondsToFirstEvent = timeToSeconds(firstEvent)
    
    return firstEvent, secondsUntilMidnight + secondsToFirstEvent
end

local function isEventActive(schedule)
    local currentTime = getCurrentTime()
    local currentSeconds = timeToSeconds(currentTime)
    
    for _, event in ipairs(schedule) do
        local eventStart = timeToSeconds(event)
        local eventEnd = eventStart + LOCHNESS_CONFIG.EventDuration
        
        if eventEnd >= 86400 then
            if currentSeconds >= eventStart or currentSeconds < (eventEnd - 86400) then
                return true, event
            end
        else
            if currentSeconds >= eventStart and currentSeconds < eventEnd then
                return true, event
            end
        end
    end
    
    return false, nil
end

local function formatTime(time)
    return string.format("%02d:%02d", time.hour, time.minute)
end

local function formatCountdown(seconds)
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    
    if hours > 0 then
        return string.format("%dh %dm %ds", hours, mins, secs)
    elseif mins > 0 then
        return string.format("%dm %ds", mins, secs)
    else
        return string.format("%ds", secs)
    end
end

local savedPositionBeforeEvent = nil

local function saveCurrentPosition()
    if not Character then return false end
    
    local hrp = Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    savedPositionBeforeEvent = hrp.CFrame
    return true
end

local function restoreSavedPosition()
    if not savedPositionBeforeEvent then return false end
    if not Character then return false end
    
    local hrp = Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local success = pcall(function()
        hrp.CFrame = savedPositionBeforeEvent
    end)
    
    if success then
        savedPositionBeforeEvent = nil
        return true
    end
    
    return false
end

local function teleportToLochNess()
    if not Character then return false end
    
    local hrp = Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local success = pcall(function()
        hrp.CFrame = LOCHNESS_CONFIG.Coords
    end)
    
    return success
end

local AutoLochNessEnabled = false
local LochNessTask = nil
local LocalSchedule = {}
local CurrentEventStart = nil

local function runAutoLochNess()
    if LochNessTask then
        task.cancel(LochNessTask)
        LochNessTask = nil
    end
    
    LochNessTask = task.spawn(function()
        LocalSchedule = convertScheduleToLocal(LOCHNESS_CONFIG.ScheduleWIB)
        
        while AutoLochNessEnabled do
            local isActive, activeEvent = isEventActive(LocalSchedule)
            
            if isActive then
                saveCurrentPosition()
                task.wait(0.5)
                teleportToLochNess()
                
                CurrentEventStart = os.time()
                
                local countdown = LOCHNESS_CONFIG.EventDuration
                while countdown > 0 and AutoLochNessEnabled do
                    task.wait(1)
                    countdown = countdown - 1
                end
                
                if AutoLochNessEnabled then
                    task.wait(1)
                    restoreSavedPosition()
                end
                
                CurrentEventStart = nil
            end
            
            task.wait(1)
        end
    end)
end

function CombinedModules.AutoLochNessEvent.Start()
    if AutoLochNessEnabled then return end
    
    AutoLochNessEnabled = true
    runAutoLochNess()
end

function CombinedModules.AutoLochNessEvent.Stop()
    if not AutoLochNessEnabled then return end
    
    AutoLochNessEnabled = false
    
    if LochNessTask then
        task.cancel(LochNessTask)
        LochNessTask = nil
    end
end

function CombinedModules.AutoLochNessEvent.IsRunning()
    return AutoLochNessEnabled
end

function CombinedModules.AutoLochNessEvent.GetScheduleInfo()
    local userOffset = getUserTimezoneOffset()
    local timezoneName = getTimezoneName(userOffset)
    local localSchedule = convertScheduleToLocal(LOCHNESS_CONFIG.ScheduleWIB)
    
    return {
        timezone = timezoneName,
        offset = userOffset,
        schedule = localSchedule
    }
end

function CombinedModules.AutoLochNessEvent.GetStatus()
    if not AutoLochNessEnabled then
        return {
            active = false,
            message = "Disabled"
        }
    end
    
    local localSchedule = convertScheduleToLocal(LOCHNESS_CONFIG.ScheduleWIB)
    local isActive, activeEvent = isEventActive(localSchedule)
    
    if isActive then
        local elapsed = os.time() - (CurrentEventStart or os.time())
        local remaining = LOCHNESS_CONFIG.EventDuration - elapsed
        
        return {
            active = true,
            inEvent = true,
            message = "Event Active",
            timeLeft = formatCountdown(remaining)
        }
    else
        local nextEvent, secondsUntil = getNextEvent(localSchedule)
        
        return {
            active = true,
            inEvent = false,
            message = "Waiting",
            nextEvent = formatTime(nextEvent),
            countdown = formatCountdown(secondsUntil)
        }
    end
end

function CombinedModules.AutoLochNessEvent.TeleportNow()
    saveCurrentPosition()
    task.wait(0.5)
    return teleportToLochNess()
end

function CombinedModules.AutoLochNessEvent.ReturnToSaved()
    return restoreSavedPosition()
end

localPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid", 5)
    
    if AutoLochNessEnabled then
        task.wait(3)
        
        local localSchedule = convertScheduleToLocal(LOCHNESS_CONFIG.ScheduleWIB)
        local isActive = isEventActive(localSchedule)
        
        if isActive then
            task.wait(1)
            teleportToLochNess()
        end
    end
end)

CombinedModules.AutoEnchant = (function()
    local AutoEnchant = {}
    
    local RS = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer
    
    local Net = RS.Packages._Index["sleitnick_net@0.2.0"].net
    local Replion = require(RS.Packages.Replion)
    local PlayerStatsUtility = require(RS.Shared.PlayerStatsUtility)
    local ItemUtility = require(RS.Shared.ItemUtility)
    
    -- Remotes
    local REEquipItem = (EventResolver and EventResolver:GetRE("EquipItem")) or Net["RE/EquipItem"]
    local REEquipToolFromHotbar = (EventResolver and EventResolver:GetRE("EquipToolFromHotbar")) or Net["RE/EquipToolFromHotbar"]
    local REActivateEnchantingAltar = (EventResolver and EventResolver:GetRE("ActivateEnchantingAltar")) or Net["RE/ActivateEnchantingAltar"]
    local REActivateSecondEnchantingAltar = (EventResolver and EventResolver:GetRE("ActivateSecondEnchantingAltar")) or Net["RE/ActivateSecondEnchantingAltar"]
    local RERollEnchant = (EventResolver and EventResolver:GetRE("RollEnchant")) or Net["RE/RollEnchant"]
    local UpdateRemote = RS.Packages._Index["ytrev_replion@2.0.0-rc.3"].replion.Remotes.Update
    
    local Client = Replion.Client
    local Data = Client:WaitReplion("Data")
    
    -- Enchant Mapping (dynamically built from ReplicatedStorage.Enchants)
    local enchantMapping = {}
    
    local function buildEnchantMapping()
        enchantMapping = {}
        pcall(function()
            local enchantFolder = RS:WaitForChild("Enchants", 10)
            if enchantFolder then
                for _, child in ipairs(enchantFolder:GetChildren()) do
                    if child:IsA("ModuleScript") then
                        local ok, data = pcall(require, child)
                        if ok and data and data.Data and data.Data.Name and data.Data.Id then
                            enchantMapping[data.Data.Name] = data.Data.Id
                        end
                    end
                end
            end
        end)
    end
    
    buildEnchantMapping()
    
    -- Configuration
    local config = {
        enabled = false,
        targetEnchantId = 10,
        targetEnchantName = "XPerienced I",
        rollCount = 0,
        waitingForUpdate = false,
        currentCycleRunning = false,
        currentTask = nil,
        enchantType = 1,  -- 1 = Normal Altar (Level 10+), 2 = Second Altar (Level 200+)
        enchantStoneItemId = 10  -- 10 = Normal, 246 = Double, 558 = Evolved
    }
    
    -- Helper: Teleport to Enchant Altar (supports both altars)
    local function teleportToEnchant()
        local character = LP.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            if config.enchantType == 2 then
                -- Second Altar (for Double Stone - Level 200+)
                character.HumanoidRootPart.CFrame = CFrame.new(1478.29846, 126.044891, -613.519653)
            else
                -- Normal Altar (for Normal/Evolved Stone)
                character.HumanoidRootPart.CFrame = CFrame.new(3245, -1301, 1394)
            end
            task.wait(2)
            return true
        end
        return false
    end
    
    -- Helper: Find enchant stone UUID from inventory (for auto-detection)
    local function findEnchantStoneUUIDs(enchantStoneItemId)
        local uuids = {}
        pcall(function()
            for _, item in pairs(Data:GetExpect({"Inventory", "Items"})) do
                -- Check if this is an enchant stone with matching Item ID
                if item.Id == enchantStoneItemId then
                    table.insert(uuids, item.UUID)
                end
            end
        end)
        return uuids
    end
    
    -- Helper: Equip Enchant Stone and get its hotbar slot key
    -- (Same pattern as EnchantFeatures.lua v370/Click Enchant)
    local function equipEnchantStoneAndGetSlot()
        -- Auto-detect stone UUID from inventory based on config.enchantStoneItemId
        local stoneUUIDs = findEnchantStoneUUIDs(config.enchantStoneItemId)
        if #stoneUUIDs == 0 then 
            return nil 
        end
        
        local stoneUUID = stoneUUIDs[1]  -- Use first found stone
        local slotKey = nil
        local timeout = tick()
        
        -- Loop: Fire REEquipItem until the stone appears in EquippedItems
        while tick() - timeout < 5 do
            if not config.enabled then return nil end
            
            local equippedItems = Data:Get("EquippedItems") or {}
            for key, uuid in pairs(equippedItems) do
                if uuid == stoneUUID then
                    slotKey = key
                end
            end
            
            if not slotKey then
                pcall(function()
                    REEquipItem:FireServer(stoneUUID, "Enchant Stones")
                end)
                task.wait(0.3)
            else
                break
            end
        end
        
        return slotKey
    end
    
    -- Helper: Equip Tool from Hotbar using the slot key from EquippedItems
    -- (Same pattern as EnchantFeatures.lua: REEquip:FireServer(slotKey))
    local function equipTool(slotKey)
        if not slotKey then return false end
        
        pcall(function()
            REEquipToolFromHotbar:FireServer(slotKey)
        end)
        task.wait(0.2)
        
        return true
    end
    
    -- Helper: Activate Enchanting Altar
    local function activateAltar()
        for i = 1, 3 do
            pcall(function()
                if config.enchantType == 2 then
                    REActivateSecondEnchantingAltar:FireServer()
                else
                    REActivateEnchantingAltar:FireServer()
                end
            end)
            task.wait(0.5)
        end
        return true
    end
    
    -- Helper: Roll Enchant
    local function rollEnchant()
        config.waitingForUpdate = true
        
        pcall(function()
            RERollEnchant:FireServer()
        end)
        
        -- Timeout checker
        local startTime = tick()
        while config.waitingForUpdate and tick() - startTime < 3.5 do
            task.wait(0.1)
        end
        
        -- If timeout and still enabled, retry
        if config.waitingForUpdate and config.enabled then
            config.waitingForUpdate = false
            config.currentCycleRunning = false
            return false
        end
        
        return true
    end
    
    -- Main enchant cycle
    local function startEnchantCycle()
        if not config.enabled or config.currentCycleRunning then
            return
        end
        
        config.currentCycleRunning = true
        
        -- Step 1: Teleport to altar
        if not teleportToEnchant() then
            config.currentCycleRunning = false
            return
        end
        
        -- Step 2: Equip enchant stone and find its hotbar slot key
        -- (Same pattern as EnchantFeatures.lua: REEquipItem → check EquippedItems → get slotKey)
        local slotKey = equipEnchantStoneAndGetSlot()
        if not slotKey then
            config.currentCycleRunning = false
            return
        end
        
        -- Step 3: Equip tool from hotbar using the slot key
        if not equipTool(slotKey) then
            config.currentCycleRunning = false
            return
        end
        
        -- Step 4: Activate altar
        if not activateAltar() then
            config.currentCycleRunning = false
            return
        end
        
        -- Step 5: Roll enchant
        if not rollEnchant() then
            -- Timeout occurred, retry
            task.wait(1)
            if config.enabled then
                startEnchantCycle()
            end
        end
    end
    
    -- Update listener
    if UpdateRemote then
        UpdateRemote.OnClientEvent:Connect(function(dataString, path, data)
            if not config.enabled or not config.waitingForUpdate then
                return
            end
            
            config.waitingForUpdate = false
            config.currentCycleRunning = false
            
            -- Check if this is enchant update
            if path and type(path) == "table" and #path >= 4 then
                if path[1] == "Inventory" and path[2] == "Fishing Rods" and path[4] == "Metadata" then
                    if data and data.EnchantId then
                        local enchantId = data.EnchantId
                        config.rollCount = config.rollCount + 1
                        
                        -- Check if target enchant achieved
                        if enchantId == config.targetEnchantId then
                            config.enabled = false
                            -- Target achieved, stop
                        else
                            -- Wait and continue rolling
                            task.wait(8)
                            if config.enabled then
                                startEnchantCycle()
                            end
                        end
                    end
                end
            end
        end)
    end
    
    -- Public: Start Auto Enchant
    function AutoEnchant.Start()
        if config.enabled then
            return false, "Auto Enchant sudah berjalan"
        end
        
        if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then
            return false, "Character tidak ditemukan"
        end
        
        -- Check if rod already has target enchant
        local currentEnchantId = nil
        pcall(function()
            local equippedItems = Data:Get("EquippedItems") or {}
            local fishingRods = Data:Get({"Inventory", "Fishing Rods"}) or {}
            
            for _, uuid in pairs(equippedItems) do
                for _, rod in ipairs(fishingRods) do
                    if rod.UUID == uuid then
                        if rod.Metadata and rod.Metadata.EnchantId then
                            currentEnchantId = rod.Metadata.EnchantId
                        end
                        break
                    end
                end
            end
        end)
        
        -- If rod already has target enchant, don't start
        if currentEnchantId == config.targetEnchantId then
            return false, "Rod sudah memiliki enchant: " .. config.targetEnchantName
        end
        
        config.enabled = true
        config.rollCount = 0
        config.waitingForUpdate = false
        config.currentCycleRunning = false
        
        config.currentTask = task.spawn(function()
            startEnchantCycle()
        end)
        
        return true, "Auto Enchant dimulai untuk: " .. config.targetEnchantName
    end
    
    -- Public: Stop Auto Enchant
    function AutoEnchant.Stop()
        if not config.enabled then
            return false, "Auto Enchant tidak sedang berjalan"
        end
        
        config.enabled = false
        config.waitingForUpdate = false
        config.currentCycleRunning = false
        
        if config.currentTask then
            task.cancel(config.currentTask)
            config.currentTask = nil
        end
        
        return true, "Auto Enchant dihentikan (Total rolls: " .. config.rollCount .. ")"
    end
    
    -- Public: Check if running
    function AutoEnchant.IsRunning()
        return config.enabled
    end
    
    -- Public: Set target enchant
    function AutoEnchant.SetTargetEnchant(enchantName)
        local enchantId = enchantMapping[enchantName]
        if enchantId then
            config.targetEnchantId = enchantId
            config.targetEnchantName = enchantName
            return true
        end
        return false
    end
    
    -- Public: Get roll count
    function AutoEnchant.GetRollCount()
        return config.rollCount
    end
    
    -- Public: Get available enchants
    function AutoEnchant.GetEnchantList()
        local enchants = {}
        for name, _ in pairs(enchantMapping) do
            table.insert(enchants, name)
        end
        table.sort(enchants)
        return enchants
    end
    
    -- Public: Set enchant type (1 = Normal Altar, 2 = Second Altar)
    function AutoEnchant.SetEnchantType(enchantType)
        if enchantType == 1 or enchantType == 2 then
            config.enchantType = enchantType
            return true
        end
        return false
    end
    
    -- Public: Set enchant stone type (10 = Normal, 246 = Double, 558 = Evolved, 714 = Candy)
    function AutoEnchant.SetEnchantStoneType(stoneItemId)
        if stoneItemId == 10 or stoneItemId == 246 or stoneItemId == 558 or stoneItemId == 714 then
            config.enchantStoneItemId = stoneItemId
            return true
        end
        return false
    end
    
    -- Public: Teleport to Altar (uses config.enchantType to determine location)
    function AutoEnchant.TeleportToAltar()
        return teleportToEnchant()
    end
    
    -- Public: Get Enchant Status (same as EnchantFeatures.lua v370)
    function AutoEnchant.GetEnchantStatus(enchantStoneItemId)
        enchantStoneItemId = enchantStoneItemId or config.enchantStoneItemId
        local rodName = "None"
        local enchantName = "None"
        local stoneCount = 0
        local stoneUUIDs = {}
        
        pcall(function()
            local equippedItems = Data:Get("EquippedItems") or {}
            local fishingRods = Data:Get({"Inventory", "Fishing Rods"}) or {}
            
            for _, uuid in pairs(equippedItems) do
                for _, rod in ipairs(fishingRods) do
                    if rod.UUID == uuid then
                        local itemData = ItemUtility:GetItemData(rod.Id)
                        rodName = itemData and itemData.Data.Name or rod.ItemName or "None"
                        if rod.Metadata and rod.Metadata.EnchantId then
                            local enchantData = ItemUtility:GetEnchantData(rod.Metadata.EnchantId)
                            if enchantData and enchantData.Data and enchantData.Data.Name then
                                enchantName = enchantData.Data.Name
                            end
                        end
                    end
                end
            end
            
            -- Count enchant stones
            for _, item in pairs(Data:GetExpect({"Inventory", "Items"})) do
                local itemData = ItemUtility:GetItemData(item.Id)
                if itemData and itemData.Data and itemData.Data.Type == "Enchant Stones" then
                    if not enchantStoneItemId or item.Id == enchantStoneItemId then
                        stoneCount = stoneCount + 1
                        table.insert(stoneUUIDs, item.UUID)
                    end
                end
            end
        end)
        
        return rodName, enchantName, stoneCount, stoneUUIDs
    end
    
    -- Public: Click Enchant (same pattern as EnchantFeatures.lua "Click Enchant" button)
    function AutoEnchant.ClickEnchant(enchantStoneItemId)
        enchantStoneItemId = enchantStoneItemId or config.enchantStoneItemId
        local rodName, enchantName, stoneCount, stoneUUIDs = AutoEnchant.GetEnchantStatus(enchantStoneItemId)
        if rodName == "None" or stoneCount <= 0 then
            return false, rodName, enchantName, stoneCount
        end
        
        -- Use the first available stone UUID
        local stoneUUID = stoneUUIDs[1]
        local slotKey = nil
        local timeout = tick()
        
        -- Loop: Fire REEquipItem until the stone appears in EquippedItems
        while tick() - timeout < 5 do
            local equippedItems = Data:Get("EquippedItems") or {}
            for key, uuid in pairs(equippedItems) do
                if uuid == stoneUUID then
                    slotKey = key
                end
            end
            
            if not slotKey then
                pcall(function()
                    REEquipItem:FireServer(stoneUUID, "Enchant Stones")
                end)
                task.wait(0.3)
            else
                break
            end
        end
        
        if not slotKey then
            return false, rodName, enchantName, stoneCount
        end
        
        -- Equip tool from hotbar
        pcall(function()
            REEquipToolFromHotbar:FireServer(slotKey)
        end)
        task.wait(0.2)
        
        -- Activate altar
        pcall(function()
            REActivateEnchantingAltar:FireServer()
        end)
        task.wait(1.5)
        
        -- Get updated status
        local _, newEnchant = AutoEnchant.GetEnchantStatus(enchantStoneItemId)
        return true, rodName, newEnchant, stoneCount - 1
    end
    
    -- Public: Click Double Enchant (second altar)
    function AutoEnchant.ClickDoubleEnchant(enchantStoneItemId)
        enchantStoneItemId = enchantStoneItemId or config.enchantStoneItemId
        local REAltar2 = (EventResolver and EventResolver:GetRE("ActivateSecondEnchantingAltar")) or Net["RE/ActivateSecondEnchantingAltar"]
        local rodName, enchantName, stoneCount, stoneUUIDs = AutoEnchant.GetEnchantStatus(enchantStoneItemId)
        if rodName == "None" or stoneCount <= 0 then
            return false, rodName, enchantName, stoneCount
        end
        
        local stoneUUID = stoneUUIDs[1]
        local slotKey = nil
        local timeout = tick()
        
        while tick() - timeout < 5 do
            local equippedItems = Data:Get("EquippedItems") or {}
            for key, uuid in pairs(equippedItems) do
                if uuid == stoneUUID then
                    slotKey = key
                end
            end
            
            if not slotKey then
                pcall(function()
                    REEquipItem:FireServer(stoneUUID, "Enchant Stones")
                end)
                task.wait(0.3)
            else
                break
            end
        end
        
        if not slotKey then
            return false, rodName, enchantName, stoneCount
        end
        
        pcall(function()
            REEquipToolFromHotbar:FireServer(slotKey)
        end)
        task.wait(0.2)
        
        pcall(function()
            REAltar2:FireServer()
        end)
        task.wait(1.5)
        
        local _, newEnchant = AutoEnchant.GetEnchantStatus(enchantStoneItemId or 246)
        return true, rodName, newEnchant, stoneCount - 1
    end
    
    -- Public: Teleport to Enchant Altar  
    function AutoEnchant.TeleportToAltar()
        local character = LP.Character or LP.CharacterAdded:Wait()
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if hrp and humanoid then
            hrp.CFrame = CFrame.new(Vector3.new(3258, -1301, 1391))
            humanoid:ChangeState(Enum.HumanoidStateType.Physics)
            task.wait(0.1)
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
            return true
        end
        return false
    end
    
    return AutoEnchant
end)()

--TELEPORT PAGE
local function LoadExternalModule(url)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if success then
        return result
    else
        return nil
    end
end

CombinedModules.TeleportModule = LoadExternalModule(
    "https://raw.githubusercontent.com/habibrodriguez7-art/TeleportModule/refs/heads/main/TeleportModule.lua"
)

CombinedModules.TeleportToPlayer = (function()
local TeleportToPlayer = {}

function TeleportToPlayer.TeleportTo(playerName)
    local target = Players:FindFirstChild(playerName)
    local myChar = localPlayer.Character
    if not target or not target.Character then return end

    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

    if targetHRP and myHRP then
        myHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
        print("[Teleport] ðŸš€ Teleported to player: " .. playerName)
    else
        warn("[Teleport] âŒ Gagal teleport, HRP tidak ditemukan.")
    end
end

return TeleportToPlayer
end)()

CombinedModules.SavedLocation = (function()
local SaveLocation = {}
local FileName = "LynxSavedLocation.json"

local function SavePosition(cframe)
    local components = {cframe:GetComponents()}
    pcall(function()
        writefile(FileName, HttpService:JSONEncode(components))
    end)
end

local function LoadPosition()
    if isfile(FileName) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(FileName))
        end)
        if success and typeof(result) == "table" then
            return CFrame.new(unpack(result))
        end
    end
    return nil
end

local autoTeleportEnabled = false
local autoTeleportConnection = nil

local function TeleportLastPos(character)
    task.spawn(function()
        local HumanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
        if not HumanoidRootPart then return end
        
        local savedCFrame = LoadPosition()
        if savedCFrame then
            task.wait(1) -- Delay agar character ter-load sempurna
            HumanoidRootPart.CFrame = savedCFrame
            -- Notify
            pcall(function()
                game.StarterGui:SetCore("SendNotification", {
                    Title = "Teleported";
                    Text = "Teleported to saved location";
                    Duration = 3;
                })
            end)
        end
    end)
end

function SaveLocation.EnableAutoTeleport()
    if autoTeleportEnabled then return end
    autoTeleportEnabled = true
    
    autoTeleportConnection = localPlayer.CharacterAdded:Connect(TeleportLastPos)
    
    if localPlayer.Character then
        TeleportLastPos(localPlayer.Character)
    end
end

function SaveLocation.DisableAutoTeleport()
    if not autoTeleportEnabled then return end
    autoTeleportEnabled = false
    
    if autoTeleportConnection then
        autoTeleportConnection:Disconnect()
        autoTeleportConnection = nil
    end
end

function SaveLocation.Save()
    local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    SavePosition(hrp.CFrame)
    
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = "Saved Location";
            Text = "Position saved successfully!";
            Duration = 3;
        })
    end)
end

function SaveLocation.Teleport()
    local savedCFrame = LoadPosition()
    if not savedCFrame then
        pcall(function()
            game.StarterGui:SetCore("SendNotification", {
                Title = "Error";
                Text = "No saved position found!";
                Duration = 3;
            })
        end)
        return false
    end
    
    local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    hrp.CFrame = savedCFrame

    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = "Teleported";
            Text = "Teleport berhasil!";
            Duration = 3;
        })
    end)
    return true
end

function SaveLocation.Reset()
    if isfile(FileName) then
        delfile(FileName)
    end
    
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = "Location Reset";
            Text = "Last position has been reset.";
            Duration = 3;
        })
    end)
end

return SaveLocation
end)()

CombinedModules.AutoEvent = (function()
    local module = {}

    local EventSearchPatterns = {
        ["Shark Hunt"] = {"Shark Hunt"},
        ["Megalodon Hunt"] = {"Megalodon Hunt"}, 
        ["Worm Hunt"] = {"BlackHole", "Model"},
        ["Ghost Shark Hunt"] = {"Ghost Shark Hunt", "Ghost"},
        ["Treasure Hunt"] = {"Treasure"},
        ["Black Hole"] = {"Black Hole"}
    }

    module.FallbackCoords = {
        ["Shark Hunt"] = {
            Vector3.new(1.64999, -1.3500, 2095.72),
            Vector3.new(1369.94, -1.3500, 930.125),
            Vector3.new(-1585.5, -1.3500, 1242.87),
            Vector3.new(-1896.8, -1.3500, 2634.37),
        },
        ["Worm Hunt"] = {
            Vector3.new(2190.85, -1.3999, 97.5749),
            Vector3.new(-2450.6, -1.3999, 139.731),
            Vector3.new(-267.47, -1.3999, 5188.53),
        },
        ["Megalodon Hunt"] = {
            Vector3.new(-1076.3, -1.3999, 1676.19),
            Vector3.new(-1191.8, -1.3999, 3597.30),
            Vector3.new(412.700, -1.3999, 4134.39),
        },
        ["Ghost Shark Hunt"] = {
            Vector3.new(489.558, -1.3500, 25.4060),
            Vector3.new(-1358.2, -1.3500, 4100.55),
            Vector3.new(627.859, -1.3500, 3798.08),
        },
    }

    module.TeleportCheckInterval = 8
    module.HeightOffset = 15
    module.SafeZoneRadius = 150
    module.RequireEventActive = true
    module.WaitForEventTimeout = 300
    module.ScanCooldown = 5

    local running = false
    local currentEventName = nil
    local cachedEventPosition = nil
    local cachedEventObject = nil
    local eventIsActive = false
    local lastScanTime = 0
    local loopThread = nil

    local function getHRP()
        local c = game.Players.LocalPlayer.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end

    local function applyOffset(v)
        return Vector3.new(v.X, v.Y + module.HeightOffset, v.Z)
    end

    local function safeCharacter()
        return game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
    end

    local function isNearTarget(targetPos)
        local hrp = getHRP()
        if not hrp then return false end
        
        local distance = (hrp.Position - targetPos).Magnitude
        return distance <= module.SafeZoneRadius
    end

    local function doTeleport(pos)
        if isNearTarget(pos) then
            return true
        end
        
        local ok = pcall(function()
            local c = safeCharacter()
            if not c then return end

            local hrp = c:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            if c.PrimaryPart then
                c:PivotTo(CFrame.new(pos))
            else
                hrp.CFrame = CFrame.new(pos)
            end
            
            hrp.Anchored = false
            hrp.Velocity = Vector3.zero
        end)
        return ok
    end

    local function IsEventAlive(obj)
        if not obj then return false end
        
        local success = pcall(function()
            return obj.Parent ~= nil and obj:IsDescendantOf(workspace)
        end)
        
        return success
    end

    local function SearchInAllProps(eventName)
        local patterns = EventSearchPatterns[eventName]
        if not patterns then
            return false, nil, nil
        end
        
        local allProps = {}
        for _, child in ipairs(workspace:GetChildren()) do
            if child.Name == "Props" and child:IsA("Model") then
                table.insert(allProps, child)
            end
        end
        
        for _, props in ipairs(allProps) do
            for _, pattern in ipairs(patterns) do
                for _, child in ipairs(props:GetChildren()) do
                    if child.Name == pattern and IsEventAlive(child) then
                        local position = nil
                        
                        if child:IsA("Model") then
                            if child.PrimaryPart then
                                position = child.PrimaryPart.Position
                            else
                                local cf, size = child:GetBoundingBox()
                                local adjustedY = cf.Position.Y - (size.Y / 4)
                                position = Vector3.new(cf.Position.X, adjustedY, cf.Position.Z)
                            end
                        elseif child:IsA("BasePart") then
                            position = child.Position
                        end
                        
                        if position then
                            return true, position, child
                        end
                    end
                end
            end
        end
        
        return false, nil, nil
    end

    local function scanEvent(eventName)
        local now = tick()
        
        if now - lastScanTime < module.ScanCooldown then
            if cachedEventPosition and cachedEventObject and IsEventAlive(cachedEventObject) then
                return cachedEventPosition
            end
        end
        
        lastScanTime = now
        
        local found, position, obj = SearchInAllProps(eventName)
        
        if found and position then
            cachedEventPosition = applyOffset(position)
            cachedEventObject = obj
            eventIsActive = true
            return cachedEventPosition
        end
        
        local coords = module.FallbackCoords[eventName]
        if coords and #coords > 0 then
            for _, coord in ipairs(coords) do
                local region = Region3.new(
                    coord - Vector3.new(30, 30, 30),
                    coord + Vector3.new(30, 30, 30)
                ):ExpandToGrid(4)

                local ok, parts = pcall(function()
                    return workspace:FindPartsInRegion3(region, nil, 50)
                end)

                if ok and parts and #parts > 0 then
                    for _, p in ipairs(parts) do
                        if typeof(p) == "Instance" and p:IsA("BasePart") and IsEventAlive(p) then
                            local ps = p.Position
                            if (ps - coord).Magnitude <= 25 then
                                cachedEventPosition = applyOffset(ps)
                                cachedEventObject = p
                                eventIsActive = true
                                return cachedEventPosition
                            end
                        end
                    end
                end
            end
        end
        
        eventIsActive = false
        return nil
    end

    local function waitActive(eventName)
        local start = tick()
        while tick() - start < module.WaitForEventTimeout do
            local p = scanEvent(eventName)
            if p then 
                return p 
            end
            task.wait(5)
        end
        return nil
    end

    function module.TeleportNow(name)
        if cachedEventPosition and eventIsActive then
            return doTeleport(cachedEventPosition)
        end
        return false
    end

    function module.Start(name)
        if running then 
            return false 
        end
        
        if not EventSearchPatterns[name] and not module.FallbackCoords[name] then
            return false
        end

        running = true
        currentEventName = name
        cachedEventPosition = nil
        cachedEventObject = nil
        eventIsActive = false
        lastScanTime = 0

        loopThread = task.spawn(function()
            if module.RequireEventActive then
                local pos = waitActive(name)
                if not pos then
                    module.Stop()
                    return
                end
                doTeleport(pos)
            end

            local failCount = 0
            while running do
                if cachedEventObject and not IsEventAlive(cachedEventObject) then
                    cachedEventPosition = nil
                    cachedEventObject = nil
                    eventIsActive = false
                end

                local newPos = scanEvent(name)
                
                if newPos then
                    doTeleport(newPos)
                    failCount = 0
                else
                    failCount = failCount + 1
                    
                    if failCount >= 3 then
                        module.Stop()
                        break
                    end
                end
                
                task.wait(module.TeleportCheckInterval)
            end
        end)
        
        return true
    end

    function module.Stop()
        running = false
        cachedEventPosition = nil
        cachedEventObject = nil
        currentEventName = nil
        eventIsActive = false
        
        if loopThread then
            if loopThread ~= coroutine.running() then
                task.cancel(loopThread)
            end
            loopThread = nil
        end
        
        return true
    end

    function module.GetEventNames()
        local list = {}
        for name, _ in pairs(EventSearchPatterns) do
            table.insert(list, name)
        end
        table.sort(list)
        return list
    end

    function module.HasEventPattern(eventName)
        return EventSearchPatterns[eventName] ~= nil
    end

    function module.IsEventActive(eventName)
        if currentEventName == eventName and eventIsActive then
            return true
        end
        return false
    end

    function module.GetCachedPosition()
        return cachedEventPosition
    end

    function module.ForceScan(eventName)
        lastScanTime = 0
        return scanEvent(eventName or currentEventName)
    end

    return module
end)()

--SHOP PAGE
CombinedModules.AutoSellSystem = (function()
    local AutoSellSystem = {}
    AutoSellSystem.Timer = {}
    AutoSellSystem.Count = {}
    
    local sellRemote = nil
    
    local function initializeSellRemote()
        local success = pcall(function()
            sellRemote = EventResolver and EventResolver:GetRF("SellAllItems")
            if not sellRemote then
                local Net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
                sellRemote = Net["RF/SellAllItems"]
            end
        end)
        
        return success and sellRemote ~= nil
    end
    
    initializeSellRemote()
    
    local function parseNumber(text)
        if not text or text == "" then return 0 end
        local cleaned = tostring(text):gsub("%D", "")
        if cleaned == "" then return 0 end
        return tonumber(cleaned) or 0
    end
    
    local function getBagCount()
        local gui = localPlayer:FindFirstChild("PlayerGui")
        if not gui then return 0, 0 end
        
        local inv = gui:FindFirstChild("Inventory")
        if not inv then return 0, 0 end
        
        local label = inv:FindFirstChild("Main")
            and inv.Main:FindFirstChild("Top")
            and inv.Main.Top:FindFirstChild("Options")
            and inv.Main.Top.Options:FindFirstChild("Fish")
            and inv.Main.Top.Options.Fish:FindFirstChild("Label")
            and inv.Main.Top.Options.Fish.Label:FindFirstChild("BagSize")
        
        if not label or not label:IsA("TextLabel") then return 0, 0 end
        
        local curText, maxText = label.Text:match("(.+)%/(.+)")
        if not curText or not maxText then return 0, 0 end
        
        return parseNumber(curText), parseNumber(maxText)
    end
    
    local state = {
        totalSells = 0,
        lastSellTime = 0
    }
    
    local timerMode = {
        enabled = false,
        interval = 5,
        task = nil,
        sellCount = 0
    }
    
    local countMode = {
        enabled = false,
        target = 235,
        checkDelay = 1.5,
        lastSell = 0,
        task = nil
    }
    
    local function executeSell()
        if not sellRemote then return false end
        
        local success, result = pcall(function()
            return sellRemote:InvokeServer()
        end)
        
        if success then
            state.totalSells = state.totalSells + 1
            state.lastSellTime = tick()
            return true
        end
        
        return false
    end
    
    function AutoSellSystem.SellOnce()
        if not sellRemote then return false end
        if tick() - state.lastSellTime < 0.5 then return false end
        return executeSell()
    end
    
    function AutoSellSystem.Timer.Start(interval)
        if timerMode.enabled then return false end
        if not sellRemote then return false end
        
        if interval and tonumber(interval) and tonumber(interval) >= 1 then
            timerMode.interval = tonumber(interval)
        end
        
        timerMode.enabled = true
        timerMode.sellCount = 0
        
        timerMode.task = task.spawn(function()
            while timerMode.enabled do
                task.wait(timerMode.interval)
                
                if not timerMode.enabled then break end
                
                if executeSell() then
                    timerMode.sellCount = timerMode.sellCount + 1
                end
            end
        end)
        
        return true
    end
    
    function AutoSellSystem.Timer.Stop()
        if not timerMode.enabled then return false end
        timerMode.enabled = false
        
        if timerMode.task then
            task.cancel(timerMode.task)
            timerMode.task = nil
        end
        
        return true
    end
    
    function AutoSellSystem.Timer.SetInterval(seconds)
        if tonumber(seconds) and seconds >= 1 then
            timerMode.interval = tonumber(seconds)
            return true
        end
        return false
    end
    
    function AutoSellSystem.Timer.GetStatus()
        return {
            enabled = timerMode.enabled,
            interval = timerMode.interval,
            sellCount = timerMode.sellCount
        }
    end
    
    function AutoSellSystem.Timer.IsEnabled()
        return timerMode.enabled
    end
    
    function AutoSellSystem.Count.Start(target)
        if countMode.enabled then return false end
        if not sellRemote then return false end
        
        if target and tonumber(target) and tonumber(target) > 0 then
            countMode.target = tonumber(target)
        end
        
        countMode.enabled = true
        
        countMode.task = task.spawn(function()
            while countMode.enabled do
                task.wait(countMode.checkDelay)
                
                if not countMode.enabled then break end
                
                local current, max = getBagCount()
                
                if countMode.target > 0 and current >= countMode.target then
                    if tick() - countMode.lastSell < 3 then
                        continue
                    end
                    
                    countMode.lastSell = tick()
                    executeSell()
                    task.wait(2)
                end
            end
        end)
        
        return true
    end
    
    function AutoSellSystem.Count.Stop()
        if not countMode.enabled then return false end
        countMode.enabled = false
        
        if countMode.task then
            task.cancel(countMode.task)
            countMode.task = nil
        end
        
        return true
    end
    
    function AutoSellSystem.Count.SetTarget(count)
        if tonumber(count) and tonumber(count) > 0 then
            countMode.target = tonumber(count)
            return true
        end
        return false
    end
    
    function AutoSellSystem.Count.GetStatus()
        local cur, max = getBagCount()
        return {
            enabled = countMode.enabled,
            target = countMode.target,
            current = cur,
            max = max
        }
    end
    
    function AutoSellSystem.Count.IsEnabled()
        return countMode.enabled
    end
    
    function AutoSellSystem.GetStats()
        return {
            totalSells = state.totalSells,
            lastSellTime = state.lastSellTime,
            remoteFound = sellRemote ~= nil,
            timerStatus = AutoSellSystem.Timer.GetStatus(),
            countStatus = AutoSellSystem.Count.GetStatus()
        }
    end
    
    function AutoSellSystem.ResetStats()
        state.totalSells = 0
        state.lastSellTime = 0
        timerMode.sellCount = 0
    end
    
    function AutoSellSystem.IsRemoteAvailable()
        return sellRemote ~= nil
    end
    
    return AutoSellSystem
end)()

CombinedModules.MerchantSystem = (function()


    local LocalPlayer = localPlayer
    local PlayerGui = localPlayer:WaitForChild("PlayerGui", 5)

local MerchantUI = nil
pcall(function()
    MerchantUI = PlayerGui:FindFirstChild("Merchant") or PlayerGui:WaitForChild("Merchant", 3)
end)

local function OpenMerchant()
    if MerchantUI then
        MerchantUI.Enabled = true
    end
end

local function CloseMerchant()
    if MerchantUI then
        MerchantUI.Enabled = false
    end
end

return {
    Open = OpenMerchant,
    Close = CloseMerchant
}
end)()

CombinedModules.AutoBuyWeather = (function()
    local AutoBuyWeather = {}
    
    local NetPackage = nil
    local RFPurchaseWeatherEvent = nil
    
    pcall(function()
        RFPurchaseWeatherEvent = EventResolver and EventResolver:GetRF("PurchaseWeatherEvent")
        if not RFPurchaseWeatherEvent then
            NetPackage = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"]
            RFPurchaseWeatherEvent = NetPackage.net["RF/PurchaseWeatherEvent"]
        end
    end)
    
    local isRunning = false
    local selected = {}
    local loopThread = nil
    
    AutoBuyWeather.AllWeathers = {
        "Cloudy",
        "Storm",
        "Wind",
        "Snow",
        "Radiant",
        "Shark Hunt"
    }
    
    function AutoBuyWeather.SetSelected(list)
        selected = list or {}
    end
    
    function AutoBuyWeather.Start()
        if isRunning then return false end
        if not RFPurchaseWeatherEvent then return false end
        if #selected == 0 then return false end
        
        isRunning = true
        
        loopThread = task.spawn(function()
            while isRunning do
                for _, weather in ipairs(selected) do
                    if not isRunning then break end
                    
                    local success = pcall(function()
                        RFPurchaseWeatherEvent:InvokeServer(weather)
                    end)
                    
                    task.wait(0.1)
                end
                
                task.wait(10)
            end
        end)
        
        return true
    end
    
    function AutoBuyWeather.Stop()
        if not isRunning then return false end
        
        isRunning = false
        
        if loopThread then
            task.cancel(loopThread)
            loopThread = nil
        end
        
        return true
    end
    
    function AutoBuyWeather.GetStatus()
        return {
            Running = isRunning,
            Selected = selected
        }
    end
    
    function AutoBuyWeather.IsAvailable()
        return RFPurchaseWeatherEvent ~= nil
    end
    
    return AutoBuyWeather
end)()

CombinedModules.BuyCharm = (function()
    local BuyCharm = {}
    BuyCharm.IsBuying = false
    BuyCharm.AutoLoop = false
    BuyCharm.Settings = {
        CharmId = nil, -- Data.Id dari charm yang dipilih
        Amount = 1,
        Delay = 0.5
    }
    
    local RS = game:GetService("ReplicatedStorage")
    
    -- ── Pola persis sama dengan AutoFavorite ───────────────────────────────
    local v0 = { RS = RS }
    local v7 = nil
    local referencesInitialized = false
    
    local function InitializeReferences()
        if referencesInitialized then return true end
        local success = pcall(function()
            -- RS.Charms adalah Folder langsung di ReplicatedStorage
            local charmsFolder = v0.RS:WaitForChild("Charms", 10)
            v7 = { Charm = charmsFolder }
        end)
        if v7 and v7.Charm then
            warn("[BuyCharm] RS.Charm.Charms ditemukan: " .. v7.Charm.Name .. " (" .. #v7.Charm:GetChildren() .. " children)")
        else
            warn("[BuyCharm] RS.Charm.Charms TIDAK ditemukan! Pakai fallback.")
        end
        referencesInitialized = success and v7 ~= nil and v7.Charm ~= nil
        return referencesInitialized
    end
    
    -- ── List charm: diisi saat BuildCharmList() dipanggil ──────────────────
    BuyCharm.CharmList = {}
    
    local function BuildCharmList()
        BuyCharm.CharmList = {}
        
        if not referencesInitialized then
            InitializeReferences()
        end
        
        if not v7 or not v7.Charm then
            warn("[BuyCharm] RS.Charms tidak ditemukan! Dropdown akan kosong.")
            return BuyCharm.CharmList
        end
        
        -- Scan children RS.Charms, hanya masukkan yang punya Price > 0
        pcall(function()
            for _, charmModule in ipairs(v7.Charm:GetChildren()) do
                if charmModule:IsA("ModuleScript") then
                    local ok, charmData = pcall(require, charmModule)
                    if ok and type(charmData) == "table" and charmData.Data then
                        local price = charmData.Price or 0
                        -- Filter: hanya charm yang punya harga
                        if price > 0 then
                            table.insert(BuyCharm.CharmList, {
                                Name  = tostring(charmData.Data.Name or charmModule.Name),
                                Id    = charmData.Data.Id,
                                Price = price
                            })
                        else
                            warn("[BuyCharm] Skip (no price): " .. charmModule.Name)
                        end
                    else
                        warn("[BuyCharm] Require gagal, skip: " .. charmModule.Name)
                    end
                end
            end
            table.sort(BuyCharm.CharmList, function(a, b)
                return (a.Id or 9999) < (b.Id or 9999)
            end)
        end)
        
        warn("[BuyCharm] BuildCharmList: " .. #BuyCharm.CharmList .. " charm dengan harga.")
        return BuyCharm.CharmList
    end

    
    -- Helper: cari entry berdasarkan nama
    function BuyCharm.FindByName(name)
        for _, entry in ipairs(BuyCharm.CharmList) do
            if entry.Name == name then
                return entry
            end
        end
        return nil
    end
    
    -- Helper: ambil semua nama (untuk dropdown)
    function BuyCharm.GetCharmNames()
        local names = {}
        for _, entry in ipairs(BuyCharm.CharmList) do
            table.insert(names, entry.Name)
        end
        if #names == 0 then
            table.insert(names, "No Charms Found")
        end
        return names
    end
    
    -- Helper: set charm berdasarkan nama (dipanggil dari GUI dropdown)
    function BuyCharm.SetCharmByName(name)
        local entry = BuyCharm.FindByName(name)
        if entry then
            BuyCharm.Settings.CharmId = entry.Id
            return entry
        end
        return nil
    end
    
    -- Set charm langsung via Id (backward compat / internal)
    function BuyCharm.SetCharmType(charmID)
        BuyCharm.Settings.CharmId = charmID
        return true
    end
    
    -- Set amount
    function BuyCharm.SetAmount(amount)
        amount = tonumber(amount)
        if amount and amount > 0 and amount <= 1000 then
            BuyCharm.Settings.Amount = math.floor(amount)
            return true
        end
        return false
    end
    
    -- Set delay
    function BuyCharm.SetDelay(delay)
        delay = tonumber(delay)
        if delay and delay >= 0 and delay <= 10 then
            BuyCharm.Settings.Delay = delay
            return true
        end
        return false
    end
    
    -- Get Remote Function
    local function getPurchaseRemote()
        -- Coba via EventResolver dulu
        if EventResolver then
            local resolved = EventResolver:GetRF("PurchaseCharm")
            if resolved then return resolved end
        end
        -- Fallback ke path lama
        local success, remote = pcall(function()
            return RS:WaitForChild("Packages", 5)
                :WaitForChild("_Index", 5)
                :WaitForChild("sleitnick_net@0.2.0", 5)
                :WaitForChild("net", 5)
                :WaitForChild("RF/PurchaseCharm", 5)
        end)
        if success and remote then
            return remote
        end
        return nil
    end
    
    -- Purchase single charm (gunakan Data.Id)
    local function purchaseCharm(charmId)
        local remote = getPurchaseRemote()
        if not remote then return false end
        local success, result = pcall(function()
            return remote:InvokeServer(charmId)
        end)
        return success and result ~= false
    end
    
    -- Start buying (single batch)
    function BuyCharm.Start(amount, charmId)
        if BuyCharm.IsBuying then return false end
        
        if amount then BuyCharm.SetAmount(amount) end
        if charmId then BuyCharm.Settings.CharmId = charmId end
        
        if not BuyCharm.Settings.CharmId then
            warn("[BuyCharm] Pilih charm terlebih dahulu!")
            return false
        end
        
        if not getPurchaseRemote() then return false end
        
        BuyCharm.IsBuying = true
        task.spawn(function()
            local targetAmount = BuyCharm.Settings.Amount
            local cId = BuyCharm.Settings.CharmId
            for i = 1, targetAmount do
                if not BuyCharm.IsBuying then break end
                purchaseCharm(cId)
                if i < targetAmount and BuyCharm.IsBuying then
                    task.wait(BuyCharm.Settings.Delay)
                end
            end
            BuyCharm.IsBuying = false
        end)
        return true
    end
    
    -- Stop buying
    function BuyCharm.Stop()
        BuyCharm.IsBuying = false
        BuyCharm.AutoLoop = false
        return true
    end
    
    -- Enable auto loop
    function BuyCharm.EnableAutoLoop()
        if BuyCharm.AutoLoop then return false end
        if not getPurchaseRemote() then return false end
        
        BuyCharm.AutoLoop = true
        task.spawn(function()
            while BuyCharm.AutoLoop do
                if not BuyCharm.IsBuying then
                    BuyCharm.Start()
                end
                while BuyCharm.IsBuying and BuyCharm.AutoLoop do
                    task.wait(0.5)
                end
                if BuyCharm.AutoLoop then
                    task.wait(1)
                end
            end
        end)
        return true
    end
    
    -- Disable auto loop
    function BuyCharm.DisableAutoLoop()
        BuyCharm.AutoLoop = false
        BuyCharm.IsBuying = false
        return true
    end
    
    -- Refresh charm list (bisa dipanggil dari tombol Refresh di GUI)
    function BuyCharm.Refresh()
        return BuildCharmList()
    end
    
    -- Test connection
    function BuyCharm.TestConnection()
        return getPurchaseRemote() ~= nil
    end
    
    return BuyCharm
end)()

--CAMERA PAGE
CombinedModules.FreecamModule = (function()

local FreecamModule = {}

local UIS = UserInputService

local Player = localPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = Player:WaitForChild("PlayerGui")

local freecam = false
local camPos = Vector3.new()
local camRot = Vector3.new()
local speed = 50
local sensitivity = 0.3
local hiddenGuis = {}

local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

local mobileJoystickInput = Vector3.new(0, 0, 0)
local joystickConnections = {}
local dynamicThumbstick = nil
local thumbstickCenter = Vector2.new(0, 0)
local thumbstickRadius = 60

local cameraTouch = nil
local cameraTouchStartPos = nil
local joystickTouch = nil
local renderConnection = nil
local inputChangedConnection = nil
local inputEndedConnection = nil
local inputBeganConnection = nil

local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = Character:WaitForChild("Humanoid")
end)


local function LockCharacter(state)
    if not Humanoid then return end
    
    if state then
        Humanoid.WalkSpeed = 0
        Humanoid.JumpPower = 0
        Humanoid.AutoRotate = false
        if Character:FindFirstChild("HumanoidRootPart") then
            Character.HumanoidRootPart.Anchored = true
        end
    else
        Humanoid.WalkSpeed = 16
        Humanoid.JumpPower = 50
        Humanoid.AutoRotate = true
        if Character:FindFirstChild("HumanoidRootPart") then
            Character.HumanoidRootPart.Anchored = false
        end
    end
end

local function HideAllGuis()
    hiddenGuis = {}
    
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            if mainGuiName and gui.Name == mainGuiName then
                continue
            end
            
            local guiName = gui.Name:lower()
            if guiName:find("main") or guiName:find("hub") or guiName:find("menu") or guiName:find("ui") then
                continue
            end
            
            table.insert(hiddenGuis, gui)
            gui.Enabled = false
        end
    end
end

local function ShowAllGuis()
    for _, gui in pairs(hiddenGuis) do
        if gui and gui:IsA("ScreenGui") then
            gui.Enabled = true
        end
    end
    
    hiddenGuis = {}
end

local function GetMovement()
    local move = Vector3.zero
    
    if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0, 0, 1) end
    if UIS:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0, 0, -1) end
    if UIS:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1, 0, 0) end
    if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1, 0, 0) end
    if UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.E) then 
        move = move + Vector3.new(0, 1, 0) 
    end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.Q) then 
        move = move + Vector3.new(0, -1, 0) 
    end
    
    if isMobile then
        move = move + mobileJoystickInput
    end
    
    return move
end


local function DetectDynamicThumbstick()
    if not isMobile then return end
    
    local function searchForThumbstick(parent, depth)
        depth = depth or 0
        if depth > 10 then return end
        
        for _, child in pairs(parent:GetChildren()) do
            local name = child.Name:lower()
            if name:find("thumbstick") or name:find("joystick") then
                if child:IsA("Frame") then
                    return child
                end
            end
            local result = searchForThumbstick(child, depth + 1)
            if result then return result end
        end
        return nil
    end
    
    pcall(function()
        dynamicThumbstick = searchForThumbstick(PlayerGui)
        
        if dynamicThumbstick then
            local pos = dynamicThumbstick.AbsolutePosition
            local size = dynamicThumbstick.AbsoluteSize
            thumbstickCenter = pos + (size / 2)
            thumbstickRadius = math.min(size.X, size.Y) / 2
        end
    end)
end

local function IsPositionInThumbstick(pos)
    if not dynamicThumbstick then return false end
    
    local thumbPos = dynamicThumbstick.AbsolutePosition
    local thumbSize = dynamicThumbstick.AbsoluteSize
    
    local isWithinX = pos.X >= thumbPos.X - 50 and pos.X <= (thumbPos.X + thumbSize.X + 50)
    local isWithinY = pos.Y >= thumbPos.Y - 50 and pos.Y <= (thumbPos.Y + thumbSize.Y + 50)
    
    return isWithinX and isWithinY
end

local function GetJoystickInput(touchPos)
    if not dynamicThumbstick then return Vector3.new(0, 0, 0) end
    
    local touchPos2D = Vector2.new(touchPos.X, touchPos.Y)
    local delta = touchPos2D - thumbstickCenter
    local magnitude = delta.Magnitude
    
    if magnitude < 5 then
        return Vector3.new(0, 0, 0)
    end
    
    local maxDist = thumbstickRadius
    local normalized = delta / maxDist
    
    normalized = Vector2.new(
        math.max(-1, math.min(1, normalized.X)),
        math.max(-1, math.min(1, normalized.Y))
    )
    
    return Vector3.new(normalized.X, 0, normalized.Y)
end


function FreecamModule.Start()
    if freecam then return end
    
    freecam = true
    
    local currentCF = Camera.CFrame
    camPos = currentCF.Position
    local x, y, z = currentCF:ToEulerAnglesYXZ()
    camRot = Vector3.new(x, y, z)
    
    LockCharacter(true)
    HideAllGuis()
    Camera.CameraType = Enum.CameraType.Scriptable
    
    task.wait()
    
    if not isMobile then
        UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
        UIS.MouseIconEnabled = false
    else
        DetectDynamicThumbstick()
    end
    
    if isMobile then
        inputBeganConnection = UIS.InputBegan:Connect(function(input, gameProcessed)
            if not freecam then return end
            
            if input.UserInputType == Enum.UserInputType.Touch then
                local pos = input.Position
                
                local isInThumbstick = false
                pcall(function()
                    isInThumbstick = IsPositionInThumbstick(pos)
                end)
                
                if isInThumbstick then
                    joystickTouch = input
                else
                    cameraTouch = input
                    cameraTouchStartPos = input.Position
                end
            end
        end)
        
        inputChangedConnection = UIS.InputChanged:Connect(function(input, gameProcessed)
            if not freecam then return end
            
            if input.UserInputType == Enum.UserInputType.Touch then
                if input == joystickTouch then
                    pcall(function()
                        mobileJoystickInput = GetJoystickInput(input.Position)
                    end)
                end
                
                if input == cameraTouch and cameraTouch then
                    local delta = input.Position - cameraTouchStartPos
                    
                    if delta.Magnitude > 0 then
                        camRot = camRot + Vector3.new(
                            -delta.Y * sensitivity * 0.003,
                            -delta.X * sensitivity * 0.003,
                            0
                        )
                        
                        cameraTouchStartPos = input.Position
                    end
                end
            end
        end)
        
        inputEndedConnection = UIS.InputEnded:Connect(function(input, gameProcessed)
            if not freecam then return end
            
            if input.UserInputType == Enum.UserInputType.Touch then
                if input == joystickTouch then
                    joystickTouch = nil
                    mobileJoystickInput = Vector3.new(0, 0, 0)
                end
                
                if input == cameraTouch then
                    cameraTouch = nil
                    cameraTouchStartPos = nil
                end
            end
        end)
    end
    
    renderConnection = RunService.RenderStepped:Connect(function(dt)
        if not freecam then return end
        
        if not isMobile then
            local mouseDelta = UIS:GetMouseDelta()
            
            if mouseDelta.Magnitude > 0 then
                camRot = camRot + Vector3.new(
                    -mouseDelta.Y * sensitivity * 0.01,
                    -mouseDelta.X * sensitivity * 0.01,
                    0
                )
            end
        end
        
        local rotationCF = CFrame.new(camPos) * CFrame.fromEulerAnglesYXZ(camRot.X, camRot.Y, camRot.Z)
        
        local moveInput = GetMovement()
        if moveInput.Magnitude > 0 then
            moveInput = moveInput.Unit
            
            local moveCF = CFrame.new(camPos) * CFrame.fromEulerAnglesYXZ(camRot.X, camRot.Y, camRot.Z)
            local velocity = (moveCF.LookVector * moveInput.Z) +
                             (moveCF.RightVector * moveInput.X) +
                             (moveCF.UpVector * moveInput.Y)
            
            camPos = camPos + velocity * speed * dt
        end
        
        Camera.CFrame = CFrame.new(camPos) * CFrame.fromEulerAnglesYXZ(camRot.X, camRot.Y, camRot.Z)
    end)
    
    return true
end

function FreecamModule.Stop()
    if not freecam then return end
    
    freecam = false
    
    if UserInputService.KeyboardEnabled and F3_NOTIFICATION_SHOWN then
        F3_NOTIFICATION_SHOWN = false
    end
    
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
    
    if inputChangedConnection then
        inputChangedConnection:Disconnect()
        inputChangedConnection = nil
    end
    
    if inputEndedConnection then
        inputEndedConnection:Disconnect()
        inputEndedConnection = nil
    end
    
    if inputBeganConnection then
        inputBeganConnection:Disconnect()
        inputBeganConnection = nil
    end
    
    for _, conn in pairs(joystickConnections) do
        if conn then
            conn:Disconnect()
        end
    end
    joystickConnections = {}
    
    LockCharacter(false)
    ShowAllGuis()
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CameraSubject = Humanoid
    
    UIS.MouseBehavior = Enum.MouseBehavior.Default
    UIS.MouseIconEnabled = true
    
    cameraTouch = nil
    cameraTouchStartPos = nil
    joystickTouch = nil
    mobileJoystickInput = Vector3.new(0, 0, 0)
    
    return true
end

function FreecamModule.Toggle()
    if freecam then
        return FreecamModule.Stop()
    else
        return FreecamModule.Start()
    end
end

function FreecamModule.IsActive()
    return freecam
end

function FreecamModule.SetSpeed(newSpeed)
    speed = math.max(1, newSpeed)
end

function FreecamModule.SetSensitivity(newSensitivity)
    sensitivity = math.max(0.01, math.min(5, newSensitivity))
end

function FreecamModule.GetSpeed()
    return speed
end

function FreecamModule.GetSensitivity()
    return sensitivity
end

local mainGuiName = nil

function FreecamModule.SetMainGuiName(guiName)
    mainGuiName = guiName
end

function FreecamModule.GetMainGuiName()
    return mainGuiName
end

local f3KeybindActive = false

function FreecamModule.EnableF3Keybind(enable)
    f3KeybindActive = enable
    
    if not enable and freecam then
        FreecamModule.Stop()
    end
    
    if not isMobile then
        local status = f3KeybindActive and "ENABLED (Press F3 to activate)" or "DISABLED"
    end
end

function FreecamModule.IsF3KeybindActive()
    return f3KeybindActive
end

if not isMobile then
    UIS.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.F3 and f3KeybindActive then
            FreecamModule.Toggle()
            
            if freecam then
            else
            end
        end
    end)
end


return FreecamModule
end)()

CombinedModules.UnlimitedZoom = (function()
local UnlimitedZoomModule = {}

local originalMinZoom = localPlayer.CameraMinZoomDistance
local originalMaxZoom = localPlayer.CameraMaxZoomDistance

local unlimitedZoomActive = false

function UnlimitedZoomModule.Enable()
    if unlimitedZoomActive then return false end
    
    unlimitedZoomActive = true
    
    localPlayer.CameraMinZoomDistance = 0.5
    localPlayer.CameraMaxZoomDistance = 9999
    
    return true
end

function UnlimitedZoomModule.Disable()
    if not unlimitedZoomActive then return false end
    
    unlimitedZoomActive = false
    
    localPlayer.CameraMinZoomDistance = originalMinZoom or 0.5
    localPlayer.CameraMaxZoomDistance = originalMaxZoom or 128 -- Default Roblox limit
    
    return true
end

function UnlimitedZoomModule.IsActive()
    return unlimitedZoomActive
end


return UnlimitedZoomModule
end)()

--WEBHOOK PAGE
CombinedModules.Webhook = (function()
local WebhookModule = {}

local function getHTTPRequest()
    local requestFunctions = {
        request,
        http_request,
        (syn and syn.request),
        (fluxus and fluxus.request),
        (http and http.request),
        (solara and solara.request),
        (game and game.HttpGet and function(opts)
            if opts.Method == "GET" then
                return {Body = game:HttpGet(opts.Url)}
            end
        end)
    }
    
    for _, func in ipairs(requestFunctions) do
        if func and type(func) == "function" then
            return func
        end
    end
    
    return nil
end

local httpRequest = getHTTPRequest()

WebhookModule.FishConfig = {
    WebhookURL = "",
    DiscordUserID = "",
    HideIdentity = "",
    DebugMode = false,
    EnabledRarities = {},
    EnabledNames = {},
    EnabledVariants = {},
    UseSimpleMode = false
}

WebhookModule.DisconnectConfig = {
    WebhookURL = "",
    DiscordUserID = "",
    HideIdentity = "",
    Enabled = false
}

local Items, Variants
local function loadGameModules()
    local success = pcall(function()
        -- Try require first (if Items is a ModuleScript)
        local itemsObj = ReplicatedStorage:WaitForChild("Items", 10)
        local variantsObj = ReplicatedStorage:WaitForChild("Variants", 10)
        
        if itemsObj and itemsObj:IsA("ModuleScript") then
            Items = require(itemsObj)
        elseif itemsObj then
            -- Items is a Folder — iterate children and require each
            Items = {}
            for _, child in ipairs(itemsObj:GetChildren()) do
                if child:IsA("ModuleScript") then
                    local ok, data = pcall(require, child)
                    if ok and data and data.Data then
                        table.insert(Items, data)
                    end
                end
            end
        end
        
        if variantsObj and variantsObj:IsA("ModuleScript") then
            Variants = require(variantsObj)
        elseif variantsObj then
            -- Variants is a Folder
            Variants = {}
            for _, child in ipairs(variantsObj:GetChildren()) do
                if child:IsA("ModuleScript") then
                    local ok, data = pcall(require, child)
                    if ok and data and data.Data then
                        table.insert(Variants, data)
                    end
                end
            end
        end
    end)
    
    return success and Items ~= nil
end

local TIER_NAMES = {
    [1] = "Common",
    [2] = "Uncommon", 
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Mythic",
    [7] = "SECRET"
}

local TIER_COLORS = {
    [1] = 9807270,
    [2] = 3066993,
    [3] = 3447003,
    [4] = 10181046,
    [5] = 15844367,
    [6] = 16711680,
    [7] = 65535
}

local isFishRunning = false
local fishEventConnection = nil
local isDisconnectEnabled = false
local disconnectSetup = false

local function getPlayerDisplayName()
    if WebhookModule.FishConfig.HideIdentity and WebhookModule.FishConfig.HideIdentity ~= "" then
        return WebhookModule.FishConfig.HideIdentity
    end
    return LocalPlayer.DisplayName or LocalPlayer.Name
end

local function getDiscordImageUrl(assetId)
    if not assetId then return nil end
    
    local thumbnailUrl = string.format(
        "https://thumbnails.roblox.com/v1/assets?assetIds=%s&returnPolicy=PlaceHolder&size=420x420&format=Png&isCircular=false",
        tostring(assetId)
    )
    
    local rbxcdnUrl = string.format(
        "https://tr.rbxcdn.com/180DAY-%s/420/420/Image/Png",
        tostring(assetId)
    )
    
    if httpRequest then
        -- Method 1: Roblox Thumbnail API
        local success, result = pcall(function()
            local response = httpRequest({
                Url = thumbnailUrl,
                Method = "GET"
            })
            
            if response and response.Body then
                local data = HttpService:JSONDecode(response.Body)
                if data and data.data and data.data[1] and data.data[1].imageUrl then
                    return data.data[1].imageUrl
                end
            end
        end)
        
        if success and result then
            return result
        end
        
        -- Method 2: Try rbxcdn direct URL
        local cdnSuccess, cdnResult = pcall(function()
            local response = httpRequest({
                Url = rbxcdnUrl,
                Method = "GET"
            })
            if response and response.StatusCode == 200 then
                return rbxcdnUrl
            end
        end)
        
        if cdnSuccess and cdnResult then
            return cdnResult
        end
    end
    
    -- Return nil so getFishImageUrl uses default image
    return nil
end

local function getFishImageUrl(fish)
    local assetId = nil
    
    if fish.Data.Icon then
        assetId = tostring(fish.Data.Icon):match("%d+")
    elseif fish.Data.ImageId then
        assetId = tostring(fish.Data.ImageId)
    elseif fish.Data.Image then
        assetId = tostring(fish.Data.Image):match("%d+")
    end
    
    if assetId then
        local discordUrl = getDiscordImageUrl(assetId)
        if discordUrl then
            return discordUrl
        end
    end
    
    return "https://i.imgur.com/UMWNYK7.png"
end

local function getFish(itemId)
    if not Items then return nil end
    
    for _, f in pairs(Items) do
        if f.Data and f.Data.Id == itemId then
            return f
        end
    end
end

local function getVariant(id)
    if not id or not Variants then return nil end
    
    local idStr = tostring(id)
    
    for _, v in pairs(Variants) do
        if v.Data then
            if tostring(v.Data.Id) == idStr or tostring(v.Data.Name) == idStr then
                return v
            end
        end
    end
    
    return nil
end

local function sendFishWebhook(fish, meta, extra)
    if not WebhookModule.FishConfig.WebhookURL or WebhookModule.FishConfig.WebhookURL == "" then
        return
    end
    
    if not httpRequest then
        return
    end
    
    local tier = TIER_NAMES[fish.Data.Tier] or "Unknown"
    local color = TIER_COLORS[fish.Data.Tier] or 3447003
    
    -- Rarity filter
    if WebhookModule.FishConfig.EnabledRarities then
        local hasFilter = false
        local isEnabled = false
        
        for key, value in pairs(WebhookModule.FishConfig.EnabledRarities) do
            if type(key) == "string" then
                hasFilter = true
                if key == tier and value == true then
                    isEnabled = true
                    break
                end
            elseif type(key) == "number" and type(value) == "string" then
                hasFilter = true
                if value == tier then
                    isEnabled = true
                    break
                end
            end
        end
        
        if hasFilter and not isEnabled then
            return
        end
    end
    
    -- Name filter
    if WebhookModule.FishConfig.EnabledNames then
        local hasFilter = false
        local isEnabled = false
        local fishName = fish.Data.DisplayName or fish.Data.Name
        
        for key, value in pairs(WebhookModule.FishConfig.EnabledNames) do
            if type(key) == "string" then
                hasFilter = true
                if key == fishName and value == true then
                    isEnabled = true
                    break
                end
            elseif type(key) == "number" and type(value) == "string" then
                hasFilter = true
                if value == fishName then
                    isEnabled = true
                    break
                end
            end
        end
        
        if hasFilter and not isEnabled then
            return
        end
    end
    
    -- Variant filter
    if WebhookModule.FishConfig.EnabledVariants then
        local hasFilter = false
        local isEnabled = false
        
        local checkVariantId = nil
        if extra then
            checkVariantId = extra.Variant or extra.Mutation or extra.VariantId or extra.MutationId
        end
        if not checkVariantId and meta then
            checkVariantId = meta.Variant or meta.Mutation or meta.VariantId or meta.MutationId
        end
        
        for key, value in pairs(WebhookModule.FishConfig.EnabledVariants) do
            if type(key) == "string" then
                hasFilter = true
                if checkVariantId and key == tostring(checkVariantId) and value == true then
                    isEnabled = true
                    break
                end
            elseif type(key) == "number" and type(value) == "string" then
                hasFilter = true
                if checkVariantId and value == tostring(checkVariantId) then
                    isEnabled = true
                    break
                end
            end
        end
        
        if hasFilter and not isEnabled then
            return
        end
    end
    
    local mutationText = "None"
    local finalPrice = fish.SellPrice or 0
    local variantId = nil
    
    if extra then
        variantId = extra.Variant or extra.Mutation or extra.VariantId or extra.MutationId
    end
    
    if not variantId and meta then
        variantId = meta.Variant or meta.Mutation or meta.VariantId or meta.MutationId
    end
    
    local isShiny = (meta and meta.Shiny) or (extra and extra.Shiny)
    if isShiny then
        mutationText = "Shiny"
        finalPrice = finalPrice * 2
    end
    
    if variantId then
        local v = getVariant(variantId)
        if v then
            mutationText = v.Data.Name .. " (" .. v.SellMultiplier .. "x)"
            finalPrice = finalPrice * v.SellMultiplier
        else
            mutationText = variantId
        end
    end
    
    local imageUrl = getFishImageUrl(fish)
    local playerDisplayName = getPlayerDisplayName()
    local mention = WebhookModule.FishConfig.DiscordUserID ~= "" and "<@" .. WebhookModule.FishConfig.DiscordUserID .. "> " or ""
    
    local congratsMsg = string.format(
        "%s **%s** You have obtained a new **%s** fish!",
        mention,
        playerDisplayName,
        tier
    )
    
    local fields = {
        {
            name = "Fish Name :",
            value = "> " .. fish.Data.Name,
            inline = false
        },
        {
            name = "Fish Tier :",
            value = "> " .. tier,
            inline = false
        },
        {
            name = "Weight :",
            value = string.format("> %.2f Kg", meta.Weight or 0),
            inline = false
        },
        {
            name = "Mutation :",
            value = "> " .. mutationText,
            inline = false
        },
        {
            name = "Sell Price :",
            value = "> $" .. math.floor(finalPrice),
            inline = false
        }
    }
    
    local payload = {
        embeds = {{
            author = {
                name = "Lynxx Webhook | Fish Caught"
            },
            description = congratsMsg,
            color = color,
            fields = fields,
            image = {
                url = imageUrl
            },
            footer = {
                text = "Lynxx Webhook • " .. os.date("%m/%d/%Y %H:%M"),
                icon_url = "https://i.imgur.com/UMWNYK7.png"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    
    pcall(function()
        httpRequest({
            Url = WebhookModule.FishConfig.WebhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

local function sendDisconnectWebhook(reason)
    if not isDisconnectEnabled then
        return
    end
    
    local webhookURL = WebhookModule.DisconnectConfig.WebhookURL
    if not webhookURL or webhookURL == "" or not webhookURL:match("discord") then
        return
    end
    
    if not httpRequest then
        return
    end
    
    local playerName = "Unknown"
    if WebhookModule.DisconnectConfig.HideIdentity and WebhookModule.DisconnectConfig.HideIdentity ~= "" then
        playerName = WebhookModule.DisconnectConfig.HideIdentity
    elseif LocalPlayer and LocalPlayer.Name then
        playerName = LocalPlayer.Name
    end
    
    local mention = WebhookModule.DisconnectConfig.DiscordUserID ~= "" 
        and "<@" .. WebhookModule.DisconnectConfig.DiscordUserID:gsub("%D", "") .. ">" 
        or "Anonymous"
    
    local dateInfo = os.date("*t")
    local hour12 = dateInfo.hour > 12 and dateInfo.hour - 12 or dateInfo.hour
    local ampm = dateInfo.hour >= 12 and "PM" or "AM"
    local formattedTime = string.format(
        "%02d/%02d/%04d %02d.%02d %s",
        dateInfo.day,
        dateInfo.month,
        dateInfo.year,
        hour12,
        dateInfo.min,
        ampm
    )
    
    local disconnectReason = reason and reason ~= "" and reason or "Disconnected from server"
    
    local payload = {
        content = "Lekk Akun lu Disconnect noh! " .. mention .. " your account got disconnected from server!",
        embeds = {{
            title = "DETAIL ACCOUNT",
            color = 16744448,
            fields = {
                {
                    name = "〢Username :",
                    value = "> " .. playerName
                },
                {
                    name = "〢Time got disconnected :",
                    value = "> " .. formattedTime
                },
                {
                    name = "〢Reason :",
                    value = "> " .. disconnectReason
                }
            },
            thumbnail = {
                url = "https://media.tenor.com/PzM6FF__0tYAAAAi/fjsyun-%E7%86%8F%E7%86%8F.gif"
            }
        }},
        username = "Lynxx Notification!",
        avatar_url = "https://i.imgur.com/UMWNYK7.png"
    }
    
    task.spawn(function()
        pcall(function()
            httpRequest({
                Url = webhookURL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end)
end

local function setupDisconnectDetection()
    if disconnectSetup then return end
    disconnectSetup = true
    
    local hasDisconnected = false
    
    local function handleDisconnect(reason)
        if not hasDisconnected and isDisconnectEnabled then
            hasDisconnected = true
            
            local disconnectReason = reason or "Disconnected from server"
            sendDisconnectWebhook(disconnectReason)
            
            task.wait(2)
            
            -- Auto rejoin
            local TeleportService = game:GetService("TeleportService")
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end
    
    -- Method 1: GuiService ErrorMessageChanged
    game:GetService("GuiService").ErrorMessageChanged:Connect(function(message)
        if message and message ~= "" then
            handleDisconnect(message)
        end
    end)
    
    -- Method 2: CoreGui RobloxPromptGui
    local success, CoreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    
    if success and CoreGui then
        pcall(function()
            local RobloxPromptGui = CoreGui:FindFirstChild("RobloxPromptGui")
            if RobloxPromptGui then
                local promptOverlay = RobloxPromptGui:FindFirstChild("promptOverlay")
                if promptOverlay then
                    promptOverlay.ChildAdded:Connect(function(child)
                        if child.Name == "ErrorPrompt" then
                            task.wait(1)
                            local textLabel = child:FindFirstChildWhichIsA("TextLabel", true)
                            local reason = textLabel and textLabel.Text or "Disconnected"
                            handleDisconnect(reason)
                        end
                    end)
                end
            end
        end)
    end
end

function WebhookModule:SetFishWebhookURL(url)
    self.FishConfig.WebhookURL = url
end

function WebhookModule:SetFishDiscordUserID(id)
    self.FishConfig.DiscordUserID = id
end

function WebhookModule:SetFishDebugMode(enabled)
    self.FishConfig.DebugMode = enabled
end

function WebhookModule:SetFishEnabledRarities(rarities)
    self.FishConfig.EnabledRarities = rarities
end

function WebhookModule:SetFishSimpleMode(enabled)
    self.FishConfig.UseSimpleMode = enabled
end

function WebhookModule:SetFishEnabledNames(names)
    self.FishConfig.EnabledNames = names
end

function WebhookModule:SetFishEnabledVariants(variants)
    self.FishConfig.EnabledVariants = variants
end

function WebhookModule:SetFishHideIdentity(name)
    self.FishConfig.HideIdentity = name
end

function WebhookModule:SetDisconnectWebhookURL(url)
    self.DisconnectConfig.WebhookURL = url
end

function WebhookModule:SetDisconnectDiscordUserID(id)
    self.DisconnectConfig.DiscordUserID = id
end

function WebhookModule:SetDisconnectHideIdentity(name)
    self.DisconnectConfig.HideIdentity = name
end

function WebhookModule:EnableDisconnectWebhook(enabled)
    self.DisconnectConfig.Enabled = enabled
    isDisconnectEnabled = enabled
    
    if enabled then
        setupDisconnectDetection()
    end
end

function WebhookModule:StartFishWebhook()
    if isFishRunning then
        return false
    end
    
    if not self.FishConfig.WebhookURL or self.FishConfig.WebhookURL == "" then
        return false
    end
    
    if not httpRequest then
        return false
    end
    
    -- Load game modules
    if not loadGameModules() then
        return false
    end
    
    local success, Event = pcall(function()
        local resolved = EventResolver and EventResolver:GetRE("ObtainedNewFishNotification")
        if resolved then return resolved end
        return ReplicatedStorage.Packages
            ._Index["sleitnick_net@0.2.0"]
            .net["RE/ObtainedNewFishNotification"]
    end)
    
    if not success or not Event then
        return false
    end
    
    fishEventConnection = Event.OnClientEvent:Connect(function(itemId, metadata, extraData)
        local fish = getFish(itemId)
        if fish then
            task.spawn(function()
                sendFishWebhook(fish, metadata, extraData)
            end)
        end
    end)
    
    isFishRunning = true
    return true
end

function WebhookModule:StopFishWebhook()
    if not isFishRunning then
        return false
    end
    
    if fishEventConnection then
        fishEventConnection:Disconnect()
        fishEventConnection = nil
    end
    
    isFishRunning = false
    return true
end

-- Test Methods
function WebhookModule:TestDisconnectWebhook()
    if not httpRequest then
        return false, "HTTP request not supported"
    end
    
    if not self.DisconnectConfig.WebhookURL or self.DisconnectConfig.WebhookURL == "" then
        return false, "Webhook URL not set"
    end
    
    sendDisconnectWebhook("Test Successfully :3")
    
    task.wait(2)
    local TeleportService = game:GetService("TeleportService")
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
    
    return true
end

-- Status Methods
function WebhookModule:IsFishRunning()
    return isFishRunning
end

function WebhookModule:IsDisconnectEnabled()
    return isDisconnectEnabled
end

function WebhookModule:GetTierNames()
    return TIER_NAMES
end

function WebhookModule:GetFishConfig()
    return self.FishConfig
end

function WebhookModule:GetDisconnectConfig()
    return self.DisconnectConfig
end

function WebhookModule:IsSupported()
    return httpRequest ~= nil
end

return WebhookModule
end)()

--SETTINGS PAGE
CombinedModules.AntiAFK = (function()
    local AntiAFK = {
        Enabled = false,
        Connection = nil,
        IdledConnectionsDisabled = false
    }

    local function DisableIdledConnections()
        pcall(function()
            local player = game:GetService("Players").LocalPlayer
            
            for i, v in pairs(getconnections(player.Idled)) do
                if v.Disable then
                    v:Disable()
                end
            end
            
            AntiAFK.IdledConnectionsDisabled = true
            print("[Anti-AFK] Disabled existing Idled connections")
        end)
    end

    local function EnableIdledConnections()
        pcall(function()
            local player = game:GetService("Players").LocalPlayer
            
            for i, v in pairs(getconnections(player.Idled)) do
                if v.Enable then
                    v:Enable()
                end
            end
            
            AntiAFK.IdledConnectionsDisabled = false
            print("[Anti-AFK] Re-enabled existing Idled connections")
        end)
    end

    function AntiAFK.Start()
        if AntiAFK.Enabled then return end
        AntiAFK.Enabled = true

        DisableIdledConnections()

        local VirtualUser = game:GetService("VirtualUser")
        local localPlayer = game:GetService("Players").LocalPlayer

        AntiAFK.Connection = localPlayer.Idled:Connect(function()
            if AntiAFK.Enabled then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
                print("[Anti-AFK] Prevented idle kick")
            end
        end)

        print("[Anti-AFK] Started successfully")
    end

    function AntiAFK.Stop()
        if not AntiAFK.Enabled then return end
        AntiAFK.Enabled = false

        if AntiAFK.Connection then
            AntiAFK.Connection:Disconnect()
            AntiAFK.Connection = nil
        end

        if AntiAFK.IdledConnectionsDisabled then
            EnableIdledConnections()
        end

        print("[Anti-AFK] Stopped")
    end

    return AntiAFK
end)()

CombinedModules.AntiStaff = (function()
    local AntiStaff = {}
    AntiStaff.Active = false
    
    local GROUP_ID = 35102746
    local STAFF_RANKS = {
        [2] = "OG",
        [3] = "Tester",
        [4] = "Moderator",
        [75] = "Community Staff",
        [79] = "Analytics",
        [145] = "Divers / Artist",
        [250] = "Devs",
        [252] = "Partner",
        [254] = "Talon",
        [255] = "Wildes",
        [55] = "Swimmer",
        [30] = "Contrib",
        [35] = "Contrib 2",
        [100] = "Scuba",
        [76] = "CC"
    }
    
    local function checkPlayers()
        while AntiStaff.Active do
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer then
                    local rank = player:GetRankInGroup(GROUP_ID)
                    if STAFF_RANKS[rank] then
                        localPlayer:Kick("Staff Detected! Auto Kicked for Safety.")
                        return
                    end
                end
            end
            task.wait(1)
        end
    end
    
    function AntiStaff.Start()
        if AntiStaff.Active then
            return
        end
        
        AntiStaff.Active = true
        task.spawn(checkPlayers)
    end
    
    function AntiStaff.Stop()
        AntiStaff.Active = false
    end
    
    return AntiStaff
end)()

CombinedModules.PotatoMode = (function()
    local PotatoMode = {}
    PotatoMode.Enabled = false

    -- Services
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local Lighting = game:GetService("Lighting")
    local StarterGui = game:GetService("StarterGui")
    
    local Terrain = Workspace:FindFirstChildOfClass("Terrain")
    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera

    local originalStates = {
        lighting = {},
        waterProperties = {},
        camera = {}
    }

    local connections = {}
    local processedObjects = setmetatable({}, {__mode = "k"})
    
    local DESTROY_CLASSES = {
        ParticleEmitter = true, Trail = true, Beam = true, Fire = true, 
        Smoke = true, Sparkles = true, PointLight = true, SpotLight = true, 
        SurfaceLight = true, ForceField = true, Explosion = true,
        BloomEffect = true, BlurEffect = true, ColorCorrectionEffect = true,
        SunRaysEffect = true, DepthOfFieldEffect = true, Atmosphere = true,
        Decal = true, Texture = true, SurfaceAppearance = true,
        SpecialMesh = true, BlockMesh = true, CylinderMesh = true,
        Accessory = true, Hat = true, Shirt = true, Pants = true,
        ShirtGraphic = true, CharacterMesh = true, BodyColors = true,
        Clothing = true, HumanoidDescription = true
    }

    local function shouldDestroy(obj)
        return DESTROY_CLASSES[obj.ClassName]
    end
    local function optimizeCharacter(character)
        if not character or processedObjects[character] then return end
        processedObjects[character] = true
        
        pcall(function()
            local descendants = character:GetDescendants()
            
            for i = 1, #descendants do
                local obj = descendants[i]
                
                if shouldDestroy(obj) then
                    obj:Destroy()
                    
                elseif obj:IsA("BasePart") then
                    if obj.Name == "Head" then
                        obj.Transparency = 1
                    end
                    
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.CastShadow = false
                    obj.CanCollide = obj.Name == "HumanoidRootPart" or obj.Name == "Head"
                    obj.Reflectance = 0
                    
                    obj.TopSurface = Enum.SurfaceType.SmoothNoOutlines
                    obj.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
                    obj.LeftSurface = Enum.SurfaceType.SmoothNoOutlines
                    obj.RightSurface = Enum.SurfaceType.SmoothNoOutlines
                    obj.FrontSurface = Enum.SurfaceType.SmoothNoOutlines
                    obj.BackSurface = Enum.SurfaceType.SmoothNoOutlines
                    
                elseif obj:IsA("Humanoid") then
                    for _, track in ipairs(obj:GetPlayingAnimationTracks()) do
                        track:Stop()
                    end
                    obj.HealthDisplayDistance = 0
                    obj.NameDisplayDistance = 0
                    
                elseif obj:IsA("Sound") then
                    obj.Volume = 0
                end
            end
        end)
    end

    local function optimizeObject(obj)
        if not PotatoMode.Enabled or processedObjects[obj] then return end
        processedObjects[obj] = true
        
        if shouldDestroy(obj) then
            obj:Destroy()
            return
        end
        
        pcall(function()
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.CastShadow = false
                obj.Reflectance = 0
                
                obj.TopSurface = Enum.SurfaceType.SmoothNoOutlines
                obj.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
                obj.LeftSurface = Enum.SurfaceType.SmoothNoOutlines
                obj.RightSurface = Enum.SurfaceType.SmoothNoOutlines
                obj.FrontSurface = Enum.SurfaceType.SmoothNoOutlines
                obj.BackSurface = Enum.SurfaceType.SmoothNoOutlines
                
            elseif obj:IsA("Sound") then
                obj.Volume = 0
            end
        end)
    end

    function PotatoMode.Enable()
        if PotatoMode.Enabled then return false end
        PotatoMode.Enabled = true
        task.spawn(function()
            local allObjects = Workspace:GetDescendants()
            local batchSize = 200
            
            for i = 1, #allObjects, batchSize do
                if not PotatoMode.Enabled then break end
                
                for j = i, math.min(i + batchSize - 1, #allObjects) do
                    optimizeObject(allObjects[j])
                end
                
                task.wait() -- Minimal wait
            end
        end)

        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                optimizeCharacter(player.Character)
            end
        end

        table.insert(connections, Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function(character)
                if PotatoMode.Enabled then
                    task.wait(0.2)
                    optimizeCharacter(character)
                end
            end)
            
            if player.Character then
                optimizeCharacter(player.Character)
            end
        end))

        if LocalPlayer then
            table.insert(connections, LocalPlayer.CharacterAdded:Connect(function(character)
                if PotatoMode.Enabled then
                    task.wait(0.2)
                    optimizeCharacter(character)
                end
            end))
            
            if LocalPlayer.Character then
                optimizeCharacter(LocalPlayer.Character)
            end
        end

        if Terrain then
            pcall(function()
                originalStates.waterProperties = {
                    WaterReflectance = Terrain.WaterReflectance,
                    WaterWaveSize = Terrain.WaterWaveSize,
                    WaterWaveSpeed = Terrain.WaterWaveSpeed,
                    WaterTransparency = Terrain.WaterTransparency
                }
                
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
                Terrain.WaterReflectance = 0
                Terrain.WaterTransparency = 1
                Terrain.Decoration = false
            end)
        end

        for _, sky in ipairs(Lighting:GetChildren()) do
            if sky:IsA("Sky") then
                sky.SkyboxBk = ""
                sky.SkyboxDn = ""
                sky.SkyboxFt = ""
                sky.SkyboxLf = ""
                sky.SkyboxRt = ""
                sky.SkyboxUp = ""
                sky.StarCount = 0
                sky.SunAngularSize = 0
                sky.MoonAngularSize = 0
                sky.CelestialBodiesShown = false
            end
        end

        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmosphere then atmosphere:Destroy() end
        
        local clouds = Terrain:FindFirstChildOfClass("Clouds")
        if clouds then clouds:Destroy() end

        originalStates.lighting = {
            GlobalShadows = Lighting.GlobalShadows,
            Brightness = Lighting.Brightness,
            Technology = Lighting.Technology
        }
        
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.FogStart = 0
        Lighting.Brightness = 0
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.Technology = Enum.Technology.Legacy
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        Lighting.ShadowSoftness = 0

        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then
                effect.Enabled = false
            end
        end

        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        
        pcall(function()
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
            settings().Rendering.EditQualityLevel = Enum.QualityLevel.Level01
            UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
            UserSettings():GetService("UserGameSettings").GraphicsQualityLevel = 1
        end)

        pcall(function()
            if Camera then
                originalStates.camera = {FieldOfView = Camera.FieldOfView}
                Camera.FieldOfView = 70
            end
        end)

        table.insert(connections, Workspace.DescendantAdded:Connect(function(obj)
            if PotatoMode.Enabled then
                if shouldDestroy(obj) then
                    obj:Destroy()
                else
                    task.defer(optimizeObject, obj)
                end
            end
        end))
        
        task.spawn(function()
            while PotatoMode.Enabled do
                task.wait(30)
                collectgarbage("collect")
            end
        end)
        
        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
        end)
        
        return true
    end

    function PotatoMode.Disable()
        if not PotatoMode.Enabled then return false end
        PotatoMode.Enabled = false

        if Terrain and originalStates.waterProperties then
            pcall(function()
                Terrain.WaterReflectance = originalStates.waterProperties.WaterReflectance
                Terrain.WaterWaveSize = originalStates.waterProperties.WaterWaveSize
                Terrain.WaterWaveSpeed = originalStates.waterProperties.WaterWaveSpeed
                Terrain.WaterTransparency = originalStates.waterProperties.WaterTransparency
                Terrain.Decoration = true
            end)
        end

        if originalStates.lighting.GlobalShadows ~= nil then
            Lighting.GlobalShadows = originalStates.lighting.GlobalShadows
            Lighting.Brightness = originalStates.lighting.Brightness
            Lighting.Technology = originalStates.lighting.Technology
        end
        
        if originalStates.camera.FieldOfView then
            pcall(function()
                Camera.FieldOfView = originalStates.camera.FieldOfView
            end)
        end
        
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        pcall(function()
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.DistanceBased
            UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.Automatic
        end)
        
        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true)
        end)
        
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        connections = {}
        
        processedObjects = setmetatable({}, {__mode = "k"})
        originalStates = {lighting = {}, waterProperties = {}, camera = {}}
        
        collectgarbage("collect")
        
        return true
    end

    function PotatoMode.IsEnabled()
        return PotatoMode.Enabled
    end

    return PotatoMode
end)()

CombinedModules.DisableRendering = (function()
local DisableRendering = {}

DisableRendering.Settings = {
    AutoPersist = true -- Keep active after respawn
}

local State = {
    RenderingDisabled = false,
    RenderConnection = nil
}

function DisableRendering.Start()
    if State.RenderingDisabled then
        return false, "Already disabled"
    end
    
    local success, err = pcall(function()
        -- Disable 3D rendering
        State.RenderConnection = RunService.RenderStepped:Connect(function()
            pcall(function()
                RunService:Set3dRenderingEnabled(false)
            end)
        end)
        
        State.RenderingDisabled = true
    end)
    
    if not success then
        warn("[DisableRendering] Failed to start:", err)
        return false, "Failed to start"
    end
    
    return true, "Rendering disabled"
end

function DisableRendering.Stop()
    if not State.RenderingDisabled then
        return false, "Already enabled"
    end
    
    local success, err = pcall(function()
        -- Disconnect render loop
        if State.RenderConnection then
            State.RenderConnection:Disconnect()
            State.RenderConnection = nil
        end
        
        -- Re-enable rendering
        RunService:Set3dRenderingEnabled(true)
        
        State.RenderingDisabled = false
    end)
    
    if not success then
        warn("[DisableRendering] Failed to stop:", err)
        return false, "Failed to stop"
    end
    
    return true, "Rendering enabled"
end

function DisableRendering.Toggle()
    if State.RenderingDisabled then
        return DisableRendering.Stop()
    else
        return DisableRendering.Start()
    end
end

function DisableRendering.IsDisabled()
    return State.RenderingDisabled
end

if DisableRendering.Settings.AutoPersist then
    LocalPlayer.CharacterAdded:Connect(function()
        if State.RenderingDisabled then
            task.wait(0.5)
            pcall(function()
                RunService:Set3dRenderingEnabled(false)
            end)
        end
    end)
end

function DisableRendering.Cleanup()
    if State.RenderingDisabled then
        pcall(function()
            RunService:Set3dRenderingEnabled(true)
        end)
    end
    
    if State.RenderConnection then
        State.RenderConnection:Disconnect()
    end
end

return DisableRendering
end)()

CombinedModules.UnlockFPS = (function()
    local UnlockFPS = {
        Enabled = false,
        CurrentCap = 60,
    }

    UnlockFPS.AvailableCaps = {60, 90, 120, 240}

    function UnlockFPS.SetCap(fps)
        if setfpscap then
            setfpscap(fps)
            UnlockFPS.CurrentCap = fps
        else
            warn("âš ï¸ setfpscap() tidak tersedia di executor kamu.")
        end
    end

    -- Override SetCap to fix auto-run issue
    function UnlockFPS.SetCap(fps)
        UnlockFPS.CurrentCap = fps
        if UnlockFPS.Enabled and setfpscap then
            setfpscap(fps)
        end
    end

    function UnlockFPS.Start()
        if UnlockFPS.Enabled then return end
        UnlockFPS.Enabled = true
        UnlockFPS.SetCap(UnlockFPS.CurrentCap)
    end

    function UnlockFPS.Stop()
        if not UnlockFPS.Enabled then return end
        UnlockFPS.Enabled = false
        if setfpscap then
            setfpscap(60)
        end
    end

    return UnlockFPS
end)()

CombinedModules.HideStats = (function()
local HideStatsModule = {}

local HideStatsEnabled = false
local FakeName = "LynX"
local FakeLevel = "501"
local ScriptName = "discord.gg/lynxx"

local OriginalTexts = {}


local function createScriptNameLabel(nameLabel, billboard)
    if not nameLabel or not billboard then return end
    
    local existingFrame = billboard:FindFirstChild("LynxFrame")
    if existingFrame then 
        return existingFrame
    end
    
    local nameFrame = nameLabel.Parent
    if not nameFrame or not nameFrame:IsA("Frame") then return end
    
    local originalNamePos = nameFrame.Position
    nameFrame.Position = UDim2.new(
        originalNamePos.X.Scale,
        originalNamePos.X.Offset,
        originalNamePos.Y.Scale + 0.25,
        originalNamePos.Y.Offset
    )
    
    local lynxFrame = Instance.new("Frame")
    lynxFrame.Name = "LynxFrame"
    lynxFrame.Size = nameFrame.Size
    lynxFrame.Position = originalNamePos
    lynxFrame.BackgroundTransparency = 1
    lynxFrame.Parent = billboard
    
    local scriptLabel = nameLabel:Clone()
    scriptLabel.Name = "LynxLabel"
    scriptLabel.Text = ScriptName
    scriptLabel.TextScaled = true
    scriptLabel.Font = Enum.Font.GothamBold
    scriptLabel.TextStrokeTransparency = 0.5
    scriptLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    scriptLabel.TextColor3 = Color3.fromRGB(255, 140, 0) -- Solid Orange
    scriptLabel.Parent = lynxFrame
    
    
    return lynxFrame
end

local function removeAllScriptNames()
    local character = LocalPlayer.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local overhead = hrp:FindFirstChild("Overhead")
    if not overhead then return end
    
    local lynxFrame = overhead:FindFirstChild("LynxFrame")
    if lynxFrame then
        for threadId, _ in pairs(ActiveGradientThreads) do
            ActiveGradientThreads[threadId] = nil
        end
        
        local nameLabel = overhead:FindFirstChild("Header", true)
        if nameLabel then
            local nameFrame = nameLabel.Parent
            if nameFrame and nameFrame:IsA("Frame") then
                local currentPos = nameFrame.Position
                nameFrame.Position = UDim2.new(
                    currentPos.X.Scale,
                    currentPos.X.Offset,
                    currentPos.Y.Scale - 0.25,
                    currentPos.Y.Offset
                )
            end
        end
        
        lynxFrame:Destroy()
    end
end

local function updateStats()
    if not HideStatsEnabled then 
        removeAllScriptNames()
        return 
    end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local overhead = hrp:FindFirstChild("Overhead")
    if not overhead or not overhead:IsA("BillboardGui") then return end
    
    for _, obj in pairs(overhead:GetDescendants()) do
        if obj:IsA("TextLabel") then
            local fullPath = obj:GetFullName()
            
            if not OriginalTexts[fullPath] then
                OriginalTexts[fullPath] = obj.Text
            end
            
            local originalText = OriginalTexts[fullPath]
            
            if originalText and originalText ~= "" then
                if obj.Name == "Header" then
                    if not overhead:FindFirstChild("LynxFrame") then
                        createScriptNameLabel(obj, overhead)
                    end
                    obj.Text = FakeName
                elseif string.find(string.lower(originalText), "lvl") then
                    obj.Text = string.gsub(originalText, "%d+", FakeLevel)
                end
            end
        end
    end
end

local updateLoop
local function startUpdateLoop()
    if updateLoop then return end
    updateLoop = true
    spawn(function()
        while updateLoop and wait(0.2) do
            if HideStatsEnabled then
                updateStats()
            end
        end
    end)
end

function HideStatsModule.Enable()
    HideStatsEnabled = true
    startUpdateLoop()
    updateStats()
end

function HideStatsModule.Disable()
    HideStatsEnabled = false
    
    for path, originalText in pairs(OriginalTexts) do
        local obj = game
        for part in string.gmatch(path, "[^.]+") do
            obj = obj:FindFirstChild(part)
            if not obj then break end
        end
        if obj and obj:IsA("TextLabel") then
            obj.Text = originalText
        end
    end
    
    removeAllScriptNames()
end

function HideStatsModule.SetFakeName(name)
    FakeName = name or "Guest"
    if HideStatsEnabled then
        updateStats()
    end
end

function HideStatsModule.SetFakeLevel(level)
    FakeLevel = tostring(level or "1")
    if HideStatsEnabled then
        updateStats()
    end
end

function HideStatsModule.IsEnabled()
    return HideStatsEnabled
end

function HideStatsModule.GetSettings()
    return {
        enabled = HideStatsEnabled,
        fakeName = FakeName,
        fakeLevel = FakeLevel
    }
end

LocalPlayer.CharacterAdded:Connect(function(character)
    OriginalTexts = {}
    ActiveGradientThreads = {}
    wait(1)
    if HideStatsEnabled then
        updateStats()
    end
end)

if LocalPlayer.Character then
    LocalPlayer.Character.DescendantAdded:Connect(function(descendant)
        if HideStatsEnabled and descendant:IsA("BillboardGui") then
            wait(0.1)
            updateStats()
        end
    end)
end

if LocalPlayer.Character then
    wait(1)
    if HideStatsEnabled then
        updateStats()
    end
end

return HideStatsModule
end)()

CombinedModules.MovementModule = (function()
local MovementModule = {}

local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

MovementModule.Settings = {
    SprintSpeed = 50,
    DefaultSpeed = 16,
    SprintEnabled = false,
    InfiniteJumpEnabled = false
}

local connections = {}
local jumpConnection = nil
local sprintConnection = nil

local function cleanup()
    for _, conn in pairs(connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    connections = {}
    
    if jumpConnection then
        jumpConnection:Disconnect()
        jumpConnection = nil
    end
    
    if sprintConnection then
        sprintConnection:Disconnect()
        sprintConnection = nil
    end
end

local function maintainSprintSpeed()
    if sprintConnection then
        sprintConnection:Disconnect()
    end
    
    sprintConnection = RunService.Heartbeat:Connect(function()
        if MovementModule.Settings.SprintEnabled and humanoid and humanoid.WalkSpeed ~= MovementModule.Settings.SprintSpeed then
            humanoid.WalkSpeed = MovementModule.Settings.SprintSpeed
        end
    end)
end

function MovementModule.SetSprintSpeed(speed)
    MovementModule.Settings.SprintSpeed = math.clamp(speed, 16, 200)
    
    if MovementModule.Settings.SprintEnabled and humanoid then
        humanoid.WalkSpeed = MovementModule.Settings.SprintSpeed
    end
end

function MovementModule.EnableSprint()
    if MovementModule.Settings.SprintEnabled then return false end
    
    MovementModule.Settings.SprintEnabled = true
    
    if humanoid then
        humanoid.WalkSpeed = MovementModule.Settings.SprintSpeed
    end
    
    maintainSprintSpeed()
    
    return true
end

function MovementModule.DisableSprint()
    if not MovementModule.Settings.SprintEnabled then return false end
    
    MovementModule.Settings.SprintEnabled = false
    
    if sprintConnection then
        sprintConnection:Disconnect()
        sprintConnection = nil
    end
    
    if humanoid then
        humanoid.WalkSpeed = MovementModule.Settings.DefaultSpeed
    end
    
    return true
end

function MovementModule.IsSprintEnabled()
    return MovementModule.Settings.SprintEnabled
end

function MovementModule.GetSprintSpeed()
    return MovementModule.Settings.SprintSpeed
end

local function enableInfiniteJump()
    if jumpConnection then
        jumpConnection:Disconnect()
    end
    
    jumpConnection = UserInputService.JumpRequest:Connect(function()
        if MovementModule.Settings.InfiniteJumpEnabled and humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

function MovementModule.EnableInfiniteJump()
    if MovementModule.Settings.InfiniteJumpEnabled then return false end
    
    MovementModule.Settings.InfiniteJumpEnabled = true
    enableInfiniteJump()
    
    return true
end

function MovementModule.DisableInfiniteJump()
    if not MovementModule.Settings.InfiniteJumpEnabled then return false end
    
    MovementModule.Settings.InfiniteJumpEnabled = false
    
    if jumpConnection then
        jumpConnection:Disconnect()
        jumpConnection = nil
    end
    
    return true
end

function MovementModule.IsInfiniteJumpEnabled()
    return MovementModule.Settings.InfiniteJumpEnabled
end

table.insert(connections, player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    
    if MovementModule.Settings.SprintEnabled then
        task.wait(0.1)
        humanoid.WalkSpeed = MovementModule.Settings.SprintSpeed
        maintainSprintSpeed() 
    end
    
    if MovementModule.Settings.InfiniteJumpEnabled then
        enableInfiniteJump()
    end
end))

function MovementModule.Start()
    MovementModule.Settings.SprintEnabled = false
    MovementModule.Settings.InfiniteJumpEnabled = false
    enableInfiniteJump()
    return true
end

function MovementModule.Stop()
    MovementModule.DisableSprint()
    MovementModule.DisableInfiniteJump()
    cleanup()
    return true
end

MovementModule.Start()

return MovementModule
end)()

-- =====================================================
-- COMBINED MODULES: AUTO TRADE
-- =====================================================

CombinedModules.AutoTrade = (function()
    local AutoTrade = {}
    
    local RS = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer
    
    local Net = RS.Packages._Index["sleitnick_net@0.2.0"].net
    local Replion = require(RS.Packages.Replion)
    local ItemUtility = require(RS.Shared.ItemUtility)
    local VendorUtility = require(RS.Shared.VendorUtility)
    local PlayerStatsUtility = require(RS.Shared.PlayerStatsUtility)
    
    local RF_InitiateTrade = (EventResolver and EventResolver:GetRF("InitiateTrade")) or Net["RF/InitiateTrade"]
    
    local Data = Replion.Client:WaitReplion("Data")
    local Items = RS:WaitForChild("Items")
    
    local TierFish = {
        [1] = "Common",
        [2] = "Uncommon",
        [3] = "Rare",
        [4] = "Epic",
        [5] = "Legendary",
        [6] = "Mythic",
        [7] = "Secret"
    }
    
    local EnchantStoneIds = {
        ["Normal"] = 10,
        ["Double"] = 246,
        ["Evolved"] = 558
    }
    
    local config = {
        enabled = false,
        targetPlayer = nil,
        tradeMode = "ByName",
        selectedItem = nil,
        itemAmount = 1,
        targetCoins = 0,
        selectedRarity = "Common",
        rarityAmount = 1,
        selectedStoneType = "Normal",
        stoneAmount = 1,
        currentTask = nil,
        playerManuallySelected = false,
    }
    
    local stats = {
        totalAttempted = 0,
        totalSuccess = 0,
        totalFailed = 0,
        targetAmount = 0,
        currentItem = "",
        status = "Idle",
        lastTradedItem = "",
        coinTraded = 0,
    }
    
    AutoTrade.OnStatsChanged = nil
    AutoTrade.OnCompleted = nil
    
    local function updateStats()
        if AutoTrade.OnStatsChanged then
            pcall(AutoTrade.OnStatsChanged, stats)
        end
    end
    
    local function setStatus(newStatus)
        stats.status = newStatus
        updateStats()
    end
    
    local function playerExists(playerName)
        return Players:FindFirstChild(playerName) ~= nil
    end
    
    local function itemStillExists(uuid)
        for _, item in pairs(Data:GetExpect({"Inventory", "Items"})) do
            if item.UUID == uuid then
                return true
            end
        end
        return false
    end
    
    local function executeTrade(playerName, itemUUID, itemName, coinValue)
        if not config.enabled then return false end
        
        local targetPlayer = Players:FindFirstChild(playerName)
        if not targetPlayer then return false end
        
        stats.currentItem = itemName or "Unknown"
        stats.totalAttempted = stats.totalAttempted + 1
        setStatus(string.format("Trading: %s (%d/%d)", itemName or "?", stats.totalSuccess + 1, stats.targetAmount))
        
        local success = false
        local attempts = 0
        local maxAttempts = 3
        
        while attempts < maxAttempts and config.enabled do
            local tradeSuccess = pcall(function()
                RF_InitiateTrade:InvokeServer(targetPlayer.UserId, itemUUID)
            end)
            
            if tradeSuccess then
                local startTime = tick()
                while config.enabled do
                    if not itemStillExists(itemUUID) then
                        success = true
                        break
                    elseif tick() - startTime > 5 then
                        break
                    end
                    task.wait(0.2)
                end
                
                if success then
                    stats.totalSuccess = stats.totalSuccess + 1
                    stats.lastTradedItem = itemName or "Unknown"
                    stats.coinTraded = stats.coinTraded + (coinValue or 0)
                    setStatus(string.format("Success: %s (%d/%d)", itemName or "?", stats.totalSuccess, stats.targetAmount))
                    task.wait(5)
                    return true
                end
            end
            
            attempts = attempts + 1
            task.wait(0.5)
        end
        
        stats.totalFailed = stats.totalFailed + 1
        setStatus(string.format("Failed: %s (attempt %d)", itemName or "?", stats.totalAttempted))
        updateStats()
        return false
    end
    
    local function getGroupedByType(itemType)
        local inventory = Data:GetExpect({"Inventory", "Items"})
        local grouped = {}
        
        for _, item in ipairs(inventory) do
            local itemData = ItemUtility.GetItemDataFromItemType("Items", item.Id)
            if itemData and itemData.Data.Type == itemType and not item.Favorited then
                local name = itemData.Data.Name
                grouped[name] = grouped[name] or {count = 0, uuids = {}}
                grouped[name].count = grouped[name].count + (item.Quantity or 1)
                table.insert(grouped[name].uuids, item.UUID)
            end
        end
        
        return grouped
    end
    
    local function chooseFishesByRange(fishList, targetCoins)
        table.sort(fishList, function(a, b) return a.Price > b.Price end)
        
        local selected = {}
        local totalValue = 0
        
        for _, fish in ipairs(fishList) do
            if totalValue + fish.Price <= targetCoins then
                table.insert(selected, fish)
                totalValue = totalValue + fish.Price
            end
            if totalValue >= targetCoins then break end
        end
        
        if totalValue < targetCoins and #fishList > 0 then
            table.insert(selected, fishList[#fishList])
        end
        
        return selected, totalValue
    end
    
    local function autoTradeByName()
        if not config.targetPlayer or not config.selectedItem then
            setStatus("Error: Target/Item not set")
            return
        end
        if not playerExists(config.targetPlayer) then
            setStatus("Error: Player not found")
            return
        end
        
        stats.targetAmount = config.itemAmount
        setStatus("Starting ByName trade...")
        
        local grouped = getGroupedByType("Fish")
        local itemData = grouped[config.selectedItem]
        
        if not itemData or #itemData.uuids == 0 then
            setStatus("Error: Item not found in inventory")
            return
        end
        
        local maxToTrade = math.min(config.itemAmount, #itemData.uuids)
        stats.targetAmount = maxToTrade
        
        for i = 1, maxToTrade do
            if not config.enabled then break end
            executeTrade(config.targetPlayer, itemData.uuids[i], config.selectedItem)
        end
    end
    
    local function autoTradeByCoin()
        if not config.targetPlayer or config.targetCoins <= 0 then
            setStatus("Error: Target/Coins not set")
            return
        end
        if not playerExists(config.targetPlayer) then
            setStatus("Error: Player not found")
            return
        end
        
        setStatus("Starting ByCoin trade...")
        
        local fishList = {}
        local inventory = Data:GetExpect({"Inventory", "Items"})
        local playerMods = PlayerStatsUtility:GetPlayerModifiers(LP)
        
        for _, item in ipairs(inventory) do
            if not item.Favorited then
                local itemData = ItemUtility:GetItemData(item.Id)
                if itemData and itemData.Data and itemData.Data.Type == "Fish" then
                    local sellPrice = VendorUtility:GetSellPrice(item) or itemData.SellPrice or 0
                    local finalPrice = math.ceil(sellPrice * (playerMods and playerMods.CoinMultiplier or 1))
                    
                    if finalPrice > 0 then
                        table.insert(fishList, {
                            UUID = item.UUID,
                            Name = itemData.Data.Name,
                            Price = finalPrice
                        })
                    end
                end
            end
        end
        
        if #fishList == 0 then
            setStatus("Error: No fish found in inventory")
            return
        end
        
        local selectedFish, totalValue = chooseFishesByRange(fishList, config.targetCoins)
        stats.targetAmount = #selectedFish
        
        for _, fish in ipairs(selectedFish) do
            if not config.enabled then break end
            executeTrade(config.targetPlayer, fish.UUID, fish.Name, fish.Price)
        end
    end
    
    local function autoTradeByRarity()
        if not config.targetPlayer or not config.selectedRarity then
            setStatus("Error: Target/Rarity not set")
            return
        end
        if not playerExists(config.targetPlayer) then
            setStatus("Error: Player not found")
            return
        end
        
        stats.targetAmount = config.rarityAmount
        setStatus("Starting ByRarity trade...")
        
        local rarityFish = {}
        local inventory = Data:GetExpect({"Inventory", "Items"})
        
        for _, item in ipairs(inventory) do
            if not item.Favorited then
                local itemData = ItemUtility.GetItemDataFromItemType("Items", item.Id)
                if itemData and itemData.Data and itemData.Data.Type == "Fish" then
                    local tier = itemData.Data.Tier
                    local rarity = TierFish[tier]
                    
                    if rarity == config.selectedRarity then
                        table.insert(rarityFish, {
                            UUID = item.UUID,
                            Name = itemData.Data.Name or "Unknown",
                            Rarity = rarity
                        })
                    end
                end
            end
        end
        
        if #rarityFish == 0 then
            setStatus("Error: No fish with rarity " .. config.selectedRarity)
            return
        end
        
        local maxToTrade = math.min(config.rarityAmount, #rarityFish)
        stats.targetAmount = maxToTrade
        
        for i = 1, maxToTrade do
            if not config.enabled then break end
            executeTrade(config.targetPlayer, rarityFish[i].UUID, rarityFish[i].Name)
        end
    end
    
    local function autoTradeByEnchantStone()
        if not config.targetPlayer or not config.selectedStoneType then
            setStatus("Error: Target/Stone Type not set")
            return
        end
        if not playerExists(config.targetPlayer) then
            setStatus("Error: Player not found")
            return
        end
        
        local stoneItemId = EnchantStoneIds[config.selectedStoneType]
        if not stoneItemId then
            setStatus("Error: Invalid stone type")
            return
        end
        
        -- Find the stacked enchant stone UUID
        local stoneUUID = nil
        local stoneName = config.selectedStoneType .. " Enchant Stone"
        local inventory = Data:GetExpect({"Inventory", "Items"})
        
        for _, item in pairs(inventory) do
            if item.Id == stoneItemId then
                stoneUUID = item.UUID
                local itemData = ItemUtility.GetItemDataFromItemType("Items", item.Id)
                if itemData and itemData.Data and itemData.Data.Name then
                    stoneName = itemData.Data.Name
                end
                break
            end
        end
        
        if not stoneUUID then
            setStatus("Error: No " .. config.selectedStoneType .. " Enchant Stone found")
            return
        end
        
        stats.targetAmount = config.stoneAmount
        setStatus(string.format("Trading %s x%d...", stoneName, config.stoneAmount))
        
        local targetPlayer = Players:FindFirstChild(config.targetPlayer)
        if not targetPlayer then
            setStatus("Error: Player not found")
            return
        end
        
        -- Trade same UUID repeatedly (stacked item)
        for i = 1, config.stoneAmount do
            if not config.enabled then break end
            
            stats.currentItem = stoneName
            stats.totalAttempted = stats.totalAttempted + 1
            setStatus(string.format("Trading: %s (%d/%d)", stoneName, i, config.stoneAmount))
            
            local tradeSuccess, tradeResult = pcall(function()
                return RF_InitiateTrade:InvokeServer(targetPlayer.UserId, stoneUUID)
            end)
            
            if tradeSuccess and tradeResult then
                stats.totalSuccess = stats.totalSuccess + 1
                stats.lastTradedItem = stoneName
                setStatus(string.format("Success: %s (%d/%d)", stoneName, stats.totalSuccess, config.stoneAmount))
                updateStats()
                task.wait(5)
            else
                stats.totalFailed = stats.totalFailed + 1
                setStatus(string.format("Failed: %s (%d/%d)", stoneName, i, config.stoneAmount))
                updateStats()
                task.wait(1)
            end
        end
    end
    
    function AutoTrade.Start()
        if config.enabled then
            return false, "Auto Trade sudah berjalan"
        end
        
        if not config.targetPlayer or not config.playerManuallySelected then
            return false, "Target player belum dipilih"
        end
        
        if not playerExists(config.targetPlayer) then
            return false, "Target player tidak ditemukan"
        end
        
        config.enabled = true
        
        stats.totalAttempted = 0
        stats.totalSuccess = 0
        stats.totalFailed = 0
        stats.currentItem = ""
        stats.lastTradedItem = ""
        stats.coinTraded = 0
        stats.status = "Starting..."
        updateStats()
        
        config.currentTask = task.spawn(function()
            if config.tradeMode == "ByName" then
                autoTradeByName()
            elseif config.tradeMode == "ByCoin" then
                autoTradeByCoin()
            elseif config.tradeMode == "ByRarity" then
                autoTradeByRarity()
            elseif config.tradeMode == "ByEnchantStone" then
                autoTradeByEnchantStone()
            end
            
            if config.enabled then
                config.enabled = false
                if stats.totalSuccess >= stats.targetAmount then
                    setStatus(string.format("Completed! %d/%d trades successful", stats.totalSuccess, stats.targetAmount))
                else
                    setStatus(string.format("Finished: %d/%d successful, %d failed", stats.totalSuccess, stats.targetAmount, stats.totalFailed))
                end
                
                if AutoTrade.OnCompleted then
                    pcall(AutoTrade.OnCompleted, stats)
                end
            else
                setStatus(string.format("Stopped: %d/%d successful", stats.totalSuccess, stats.targetAmount))
            end
        end)
        
        return true, "Auto Trade dimulai"
    end
    
    function AutoTrade.Stop()
        if not config.enabled then
            return false, "Auto Trade tidak sedang berjalan"
        end
        
        config.enabled = false
        
        if config.currentTask then
            task.cancel(config.currentTask)
            config.currentTask = nil
        end
        
        setStatus(string.format("Stopped: %d/%d successful", stats.totalSuccess, stats.targetAmount))
        
        return true, "Auto Trade dihentikan"
    end
    
    function AutoTrade.IsRunning()
        return config.enabled
    end
    
    function AutoTrade.GetStats()
        return {
            totalAttempted = stats.totalAttempted,
            totalSuccess = stats.totalSuccess,
            totalFailed = stats.totalFailed,
            targetAmount = stats.targetAmount,
            currentItem = stats.currentItem,
            status = stats.status,
            lastTradedItem = stats.lastTradedItem,
            coinTraded = stats.coinTraded,
            isRunning = config.enabled,
        }
    end
    
    function AutoTrade.ResetStats()
        stats.totalAttempted = 0
        stats.totalSuccess = 0
        stats.totalFailed = 0
        stats.targetAmount = 0
        stats.currentItem = ""
        stats.status = "Idle"
        stats.lastTradedItem = ""
        stats.coinTraded = 0
        updateStats()
    end
    
    function AutoTrade.SetTargetPlayer(playerName)
        config.targetPlayer = playerName
        config.playerManuallySelected = true
    end
    
    function AutoTrade.SetTradeMode(mode)
        if mode == "ByName" or mode == "ByCoin" or mode == "ByRarity" or mode == "ByEnchantStone" then
            config.tradeMode = mode
            return true
        end
        return false
    end
    
    function AutoTrade.SetItem(itemName)
        config.selectedItem = itemName
    end
    
    function AutoTrade.SetItemAmount(amount)
        config.itemAmount = tonumber(amount) or 1
    end
    
    function AutoTrade.SetTargetCoins(coins)
        config.targetCoins = tonumber(coins) or 0
    end
    
    function AutoTrade.SetRarity(rarity)
        config.selectedRarity = rarity
    end
    
    function AutoTrade.SetRarityAmount(amount)
        config.rarityAmount = tonumber(amount) or 1
    end
    
    function AutoTrade.GetPlayers()
        local playerList = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP then
                table.insert(playerList, player.Name)
            end
        end
        return playerList
    end
    
    function AutoTrade.GetFishItems()
        local grouped = getGroupedByType("Fish")
        local displayList = {}
        
        for name, data in pairs(grouped) do
            table.insert(displayList, string.format("%s x%d", name, data.count))
        end
        
        return displayList
    end
    
    function AutoTrade.SetStoneType(stoneType)
        if EnchantStoneIds[stoneType] then
            config.selectedStoneType = stoneType
            return true
        end
        return false
    end
    
    function AutoTrade.SetStoneAmount(amount)
        config.stoneAmount = tonumber(amount) or 1
    end
    
    function AutoTrade.GetEnchantStoneItems()
        local displayList = {}
        local inventory = Data:GetExpect({"Inventory", "Items"})
        local stoneCounts = {}
        
        for stoneType, stoneId in pairs(EnchantStoneIds) do
            stoneCounts[stoneType] = 0
            for _, item in pairs(inventory) do
                if item.Id == stoneId then
                    stoneCounts[stoneType] = stoneCounts[stoneType] + (item.Quantity or 1)
                end
            end
            if stoneCounts[stoneType] > 0 then
                table.insert(displayList, string.format("%s x%d", stoneType, stoneCounts[stoneType]))
            end
        end
        
        return displayList
    end
    
    return AutoTrade
end)()

CombinedModules.AutoAcceptTrade = (function()
    local AutoAcceptTrade = {}
    
    local Players = game:GetService("Players")
    local VIM = game:GetService("VirtualInputManager")
    local LP = Players.LocalPlayer
    
    local isRunning = false
    local currentTask = nil
    
    -- Helper: Click button using VirtualInputManager
    local function clickButton(button)
        if not button then return false end
        
        local success = pcall(function()
            local absPos = button.AbsolutePosition
            local absSize = button.AbsoluteSize
            local centerX = absPos.X + absSize.X / 2
            local centerY = absPos.Y + absSize.Y / 2 + 50
            
            VIM:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
            task.wait(0.03)
            VIM:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
        end)
        
        return success
    end
    
    -- Main auto accept loop
    local function autoAcceptLoop()
        while isRunning do
            task.wait(1)
            
            pcall(function()
                local playerGui = LP.PlayerGui
                local promptGui = playerGui:FindFirstChild("Prompt")
                
                if promptGui then
                    local blackout = promptGui:FindFirstChild("Blackout")
                    
                    if blackout then
                        local options = blackout:FindFirstChild("Options")
                        
                        if options then
                            local yesButton = options:FindFirstChild("Yes")
                            
                            if yesButton then
                                clickButton(yesButton)
                            end
                        end
                    end
                end
            end)
        end
    end
    
    -- Public: Start Auto Accept
    function AutoAcceptTrade.Start()
        if isRunning then
            return false, "Auto Accept Trade sudah berjalan"
        end
        
        if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then
            return false, "Character tidak ditemukan"
        end
        
        isRunning = true
        
        currentTask = task.spawn(function()
            local success, err = pcall(autoAcceptLoop)
            
            if not success then
                warn("[AutoAcceptTrade] Error: " .. tostring(err))
            end
            
            isRunning = false
            currentTask = nil
        end)
        
        return true, "Auto Accept Trade dimulai"
    end
    
    -- Public: Stop Auto Accept
    function AutoAcceptTrade.Stop()
        if not isRunning then
            return false, "Auto Accept Trade tidak sedang berjalan"
        end
        
        isRunning = false
        
        if currentTask then
            task.cancel(currentTask)
            currentTask = nil
        end
        
        return true, "Auto Accept Trade dihentikan"
    end
    
    -- Public: Check if running
    function AutoAcceptTrade.IsRunning()
        return isRunning
    end
    
    return AutoAcceptTrade
end)()

--AUTO RECONNECT & AUTO EXECUTE MODULE
CombinedModules.AutoReconnect = (function()
local AutoReconnectModule = {}

-- Get queue_on_teleport function
local function getQueueOnTeleport()
    if queue_on_teleport then
        return queue_on_teleport
    elseif syn and syn.queue_on_teleport then
        return syn.queue_on_teleport
    elseif fluxus and fluxus.queue_on_teleport then
        return fluxus.queue_on_teleport
    end
    return nil
end

local queueTeleport = getQueueOnTeleport()

-- Config
AutoReconnectModule.Config = {
    Enabled = false,
    AutoExecuteEnabled = false,
    ExecuteDelay = 3,
    ScriptURL = "",
    MaxReconnectAttempts = 10,
    ReconnectAttempts = 0,
    OnReconnectCallback = nil,
}

-- Status
local isSetup = false
local hasDisconnected = false
local reconnectData = {
    lastDisconnectTime = 0,
    lastReason = "",
    totalReconnects = 0
}

-- Setup auto execute
local function setupAutoExecute()
    if not AutoReconnectModule.Config.AutoExecuteEnabled then
        return false
    end
    
    local scriptURL = AutoReconnectModule.Config.ScriptURL
    
    if not scriptURL or scriptURL == "" then
        return false
    end
    
    local executeDelay = AutoReconnectModule.Config.ExecuteDelay or 3
    
    local autoExecCode = string.format([[
        if _G.LynxScriptLoaded then return end
        _G.LynxScriptLoaded = true
        task.wait(%d)
        pcall(function()
            loadstring(game:HttpGet("%s"))()
        end)
    ]], executeDelay, scriptURL)
    
    if queueTeleport then
        -- PENTING: Bersihkan queue lama dulu supaya tidak double execute
        pcall(function()
            queueTeleport("")
        end)
        
        task.wait(0.1)
        
        local success = pcall(function()
            queueTeleport(autoExecCode)
        end)
        
        if success then
            pcall(function()
                if writefile then
                    writefile("LynxxAutoExec.lua", autoExecCode)
                end
            end)
            return true
        else
            return false
        end
    else
        return false
    end
end

-- Clear auto execute
local function clearAutoExecute()
    if queueTeleport then
        pcall(function()
            queueTeleport("")
        end)
    end
    
    pcall(function()
        if delfile and isfile and isfile("LynxxAutoExec.lua") then
            delfile("LynxxAutoExec.lua")
        end
    end)
    
    -- Reset flag agar script bisa di-execute ulang jika diaktifkan kembali
    _G.LynxScriptLoaded = nil
end

-- Handle reconnect
local function handleReconnect(reason)
    if not AutoReconnectModule.Config.Enabled then
        return
    end
    
    if hasDisconnected then
        return
    end
    
    hasDisconnected = true
    
    reconnectData.totalReconnects = reconnectData.totalReconnects + 1
    reconnectData.lastDisconnectTime = os.time()
    reconnectData.lastReason = reason or "Unknown"
    
    if AutoReconnectModule.Config.OnReconnectCallback then
        pcall(function()
            AutoReconnectModule.Config.OnReconnectCallback(reason, AutoReconnectModule.Config.ReconnectAttempts)
        end)
    end
    
    if AutoReconnectModule.Config.AutoExecuteEnabled then
        setupAutoExecute()
    end
    
    task.wait(2)
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end

-- Setup disconnect detection
local function setupDisconnectDetection()
    if isSetup then
        return
    end
    
    isSetup = true
    
    -- Method 1: GuiService
    game:GetService("GuiService").ErrorMessageChanged:Connect(function(message)
        if message and message ~= "" then
            handleReconnect(message)
        end
    end)
    
    -- Method 2: CoreGui
    pcall(function()
        local RobloxPromptGui = CoreGui:FindFirstChild("RobloxPromptGui")
        if RobloxPromptGui then
            local promptOverlay = RobloxPromptGui:FindFirstChild("promptOverlay")
            if promptOverlay then
                promptOverlay.ChildAdded:Connect(function(child)
                    if child.Name == "ErrorPrompt" then
                        task.wait(0.5)
                        local textLabel = child:FindFirstChildWhichIsA("TextLabel", true)
                        local reason = textLabel and textLabel.Text or "Disconnected"
                        handleReconnect(reason)
                    end
                end)
            end
        end
    end)
    
    -- Method 3: Idled
    LocalPlayer.Idled:Connect(function(time)
        if time > 1200 then
            handleReconnect("Kicked for idling")
        end
    end)
end

-- Public Methods

function AutoReconnectModule:Enable()
    self.Config.Enabled = true
    setupDisconnectDetection()
    return true
end

function AutoReconnectModule:Disable()
    self.Config.Enabled = false
    return true
end

function AutoReconnectModule:EnableAutoExecute()
    if not self.Config.ScriptURL or self.Config.ScriptURL == "" then
        return false
    end
    
    self.Config.AutoExecuteEnabled = true
    
    -- Queue script sekarang (proaktif) supaya siap kalau disconnect
    -- setupAutoExecute() sudah otomatis clear queue lama dulu, jadi tidak akan double
    local success = setupAutoExecute()
    
    if not success then
        self.Config.AutoExecuteEnabled = false
        return false
    end
    
    return true
end

function AutoReconnectModule:DisableAutoExecute()
    self.Config.AutoExecuteEnabled = false
    clearAutoExecute()
    return true
end

function AutoReconnectModule:SetScriptURL(url)
    if type(url) == "string" and url ~= "" then
        self.Config.ScriptURL = url
        return true
    end
    return false
end

function AutoReconnectModule:SetExecuteDelay(seconds)
    if type(seconds) == "number" and seconds >= 0 then
        self.Config.ExecuteDelay = seconds
        return true
    end
    return false
end

function AutoReconnectModule:SetMaxAttempts(max)
    if type(max) == "number" and max > 0 then
        self.Config.MaxReconnectAttempts = max
        return true
    end
    return false
end

function AutoReconnectModule:SetOnReconnectCallback(callback)
    if type(callback) == "function" then
        self.Config.OnReconnectCallback = callback
        return true
    end
    return false
end

function AutoReconnectModule:ResetAttempts()
    self.Config.ReconnectAttempts = 0
    return true
end

function AutoReconnectModule:GetStatus()
    return {
        enabled = self.Config.Enabled,
        autoExecuteEnabled = self.Config.AutoExecuteEnabled,
        scriptURL = self.Config.ScriptURL,
        attempts = self.Config.ReconnectAttempts,
        maxAttempts = self.Config.MaxReconnectAttempts,
        totalReconnects = reconnectData.totalReconnects,
        lastReason = reconnectData.lastReason,
        lastDisconnectTime = reconnectData.lastDisconnectTime,
        isSetup = isSetup,
        queueSupported = queueTeleport ~= nil
    }
end

function AutoReconnectModule:GetConfig()
    return self.Config
end

function AutoReconnectModule:ForceReconnect(reason)
    handleReconnect(reason or "Manual reconnect")
    return true
end

function AutoReconnectModule:IsSupported()
    return queueTeleport ~= nil
end

function AutoReconnectModule:Initialize(config)
    if config then
        for key, value in pairs(config) do
            if self.Config[key] ~= nil then
                self.Config[key] = value
            end
        end
    end
    
    if self.Config.Enabled then
        self:Enable()
    end
    
    if self.Config.AutoExecuteEnabled then
        self:EnableAutoExecute()
    end
    
    return true
end

return AutoReconnectModule
end)()

-- ═══════════════════════════════════════════════════════════════════════════
-- GUI BUILDER - Menggunakan Library Lynx (Complete Edition)
-- ═══════════════════════════════════════════════════════════════════════════
CombinedModules.BuildGUI = function(Lynx)
    if not Lynx then
        warn("[Lynx GUI] Library Lynx tidak ditemukan!")
        return nil
    end

    local Window = Lynx:Window({
        Title = "Lynx",
        Footer = "| Free Not For Sale",
        Color = Color3.fromRGB(255, 140, 0),
        ["Tab Width"] = 130,
        Version = 1,
        Image = "118176705805619"  -- Logo minimize dari ContohGui.lua
    })

    -- Config variables
    local CURRENT_VERSION = "2.5"
    local ConfigData = {}

    -- State variables
    local fishingDelayValue = 1.30
    local cancelDelayValue = 0.19
    local currentInstantMode = "Fast"
    local isInstantFishingEnabled = false

    -- ═════════════════════════════════════════
    -- TAB: MAIN DASHBOARD (Auto Fishing)
    -- ═══════════════════════════════════════════
    local MainTab = Window:AddTab({Name = "Dashboard", Icon = "home"})

     -- Section: Support Features
    local SupportSection = MainTab:AddSection("Support Features", false)
    
    SupportSection:AddToggle({
        Title = "No Fishing Animation",
        Default = false,
        Callback = function(on)
            if CombinedModules.NoFishingAnimation then
                if on then CombinedModules.NoFishingAnimation.StartWithDelay() else CombinedModules.NoFishingAnimation.Stop() end
            end
        end
    })
    

    -- GUI Toggle dengan cek kompatibilitas
    SupportSection:AddToggle({
        Title = "Auto Equip Rod" .. (CombinedModules.AutoEquipRod.isSupported and "" or " (Not Supported)"),
        Default = false,
        Callback = function(on)
            if CombinedModules.AutoEquipRod and CombinedModules.AutoEquipRod.isSupported then
                if on then 
                    CombinedModules.AutoEquipRod.Start() 
                else 
                    CombinedModules.AutoEquipRod.Stop() 
                end
            elseif on then
                -- Optional: Berikan notifikasi ke user
                warn("Auto Equip Rod tidak support di executor ini")
            end
        end
    })
    
    SupportSection:AddToggle({
        Title = "Lock Position",
        Default = false,
        Callback = function(on)
            if CombinedModules.LockPosition then
                if on then CombinedModules.LockPosition.Start() else CombinedModules.LockPosition.Stop() end
            end
        end
    })
    
    SupportSection:AddToggle({
        Title = "Disable Cutscenes",
        Default = false,
        Callback = function(on)
            if CombinedModules.DisableCutscenes then
                if on then 
                    CombinedModules.DisableCutscenes.Start()
                else 
                    CombinedModules.DisableCutscenes.Stop()
                end
            end
        end
    })
        
    SupportSection:AddToggle({
        Title = "Show Real Ping Panel",
        Default = false,
        Callback = function(on)
            if CombinedModules.PingPanel then
                if on then CombinedModules.PingPanel:Show() else CombinedModules.PingPanel:Hide() end
            end
        end
    })
    
    SupportSection:AddToggle({
        Title = "Disable Obtained Fish Notification",
        Default = false,
        Callback = function(on)
            if CombinedModules.DisableExtras then
                if on then CombinedModules.DisableExtras.StartSmallNotification() else CombinedModules.DisableExtras.StopSmallNotification() end
            end
        end
    })
    
    SupportSection:AddToggle({
        Title = "Disable Skin Effect",
        Default = false,
        Callback = function(on)
            if CombinedModules.DisableExtras then
                if on then CombinedModules.DisableExtras.StartSkinEffect() else CombinedModules.DisableExtras.StopSkinEffect() end
            end
        end
    })
    
    SupportSection:AddToggle({
        Title = "Walk On Water",
        Default = false,
        Callback = function(on)
            if CombinedModules.WalkOnWater then
                if on then CombinedModules.WalkOnWater.Start() else CombinedModules.WalkOnWater.Stop() end
            end
        end
    })

    -- Updated GUI Section untuk Legit Fishing
    local LegitSection = MainTab:AddSection("Legit Fishing", false)

    -- Mode Selector
    LegitSection:AddDropdown({
        Title = "Legit Mode",
        Options = {"AlwaysPerfect", "Normal"},
        Default = "AlwaysPerfect",
        Callback = function(value)
            if CombinedModules.legit then
                CombinedModules.legit.SetMode(value)
            end
        end
    })

    -- Complete Delay
    LegitSection:AddInput({
        Title = "Complete Delay",
        Default = "0.8",
        Callback = function(value)
            local v = tonumber(value)
            if v and v > 0 and CombinedModules.legit then 
                CombinedModules.legit.Settings.CompleteDelay = v 
                print("[Legit GUI] Complete Delay set to:", v)
            end
        end
    })
    -- Shake Delay
    LegitSection:AddInput({
        Title = "Shake Delay",
        Default = "0.05",
        Callback = function(value)
            local v = tonumber(value)
            if v and v >= 0 and CombinedModules.legit then 
                CombinedModules.legit.Settings.ShakeDelay = v 
                print("[Legit GUI] Shake Delay set to:", v)
            end
        end
    })
        -- Auto Shake Toggle
    LegitSection:AddToggle({
        Title = "Auto Shake",
        Default = false,
        Callback = function(on)
            if CombinedModules.legit then
                if on then 
                    CombinedModules.legit.StartAutoShake() 
                else 
                    CombinedModules.legit.StopAutoShake() 
                end
            end
        end
    })
     -- Main Toggle
    LegitSection:AddToggle({
        Title = "Enable Legit Fishing",
        Default = false,
        Callback = function(on)
            if CombinedModules.legit then
                if on then 
                    CombinedModules.legit.Start() 
                else 
                    CombinedModules.legit.Stop() 
                end
            end
        end
    })
    
    -- Section: Auto Fishing
    local AutoFishingSection = MainTab:AddSection("Instant Fishing Perfect!")
    
    AutoFishingSection:AddToggle({
        Title = "Enable Instant V1",
        Default = false,
        Callback = function(on)
            if CombinedModules.InstantV1 then
                if on then CombinedModules.InstantV1.Start() else CombinedModules.InstantV1.Stop() end
            end
        end
    })

    AutoFishingSection:AddInput({
        Title = "Fishing Delay V1",
        Default = "0.3",
        Callback = function(value)
            local v = tonumber(value)
            if v and CombinedModules.InstantV1 then CombinedModules.InstantV1.Settings.CompleteDelay = v end
        end
    })
    -- Section: Stable Result
    local StableSection = MainTab:AddSection("Stable Result", false)
    StableSection:AddToggle({
        Title = "Enable Auto Good/Perfection",
        Default = false,
        Callback = function(on)
            if CombinedModules.StableResult then
                if on then CombinedModules.StableResult.Start() else CombinedModules.StableResult.Stop() end
            end
        end
    })

	local FishSection = MainTab:AddSection("Stuck Detector [BETA]", false)

	local stuckThresholdValue = 15
	FishSection:AddInput({
		Title = "Stuck Threshold (seconds)",
		Default = "15",
		Callback = function(value)
			local v = tonumber(value)
			if v and v >= 3 and v <= 60 then
				stuckThresholdValue = v
				if CombinedModules.StuckDetector then
					CombinedModules.StuckDetector:SetThreshold(v)
				end
			end
		end
	})

	FishSection:AddToggle({
		Title = "Enable Stuck Detector",
		Default = false,
		Callback = function(on)
			if CombinedModules.StuckDetector then
				if on then 
					CombinedModules.StuckDetector:Start(stuckThresholdValue)
				else 
					CombinedModules.StuckDetector:Stop()
				end
			end
		end
	})

	local BlatantV1Section = MainTab:AddSection("Blatant V1 [BETA]", false)

    BlatantV1Section:AddToggle({
        Title = "Enable Blatant V1",
        Default = false,
        Callback = function(on)
            if CombinedModules.blatantV1 then
                if on then CombinedModules.blatantV1.Start() else CombinedModules.blatantV1.Stop() end
            end
        end
    })

    BlatantV1Section:AddInput({
        Title = "Talon Delay V1",
        Default = "0.3",
        Callback = function(value)
            local v = tonumber(value)
            if v and CombinedModules.blatantV1 then CombinedModules.blatantV1.Settings.SpamCastDelay = v end
        end
    })

    BlatantV1Section:AddInput({
        Title = "Wildes Delay V1",
        Default = "0.3",
        Callback = function(value)
            local v = tonumber(value)
            if v and CombinedModules.blatantV1 then CombinedModules.blatantV1.Settings.CompleteDelay = v end
        end
    })


    local BlatantV2Section = MainTab:AddSection("Blatant V2 New [BETA]", false)

    BlatantV2Section:AddToggle({
        Title = "Enable Blatant V2",
        Default = false,
        Callback = function(on)
            if CombinedModules.blatantV2 then
                if on then CombinedModules.blatantV2.Start() else CombinedModules.blatantV2.Stop() end
            end
        end
    })

    BlatantV2Section:AddInput({
        Title = "Talon Delay V2",
        Default = "0.3",
        Callback = function(value)
            local v = tonumber(value)
            if v and CombinedModules.blatantV2 then CombinedModules.blatantV2.Settings.SpamCastDelay = v end
        end
    })

    BlatantV2Section:AddInput({
        Title = "Wildes Delay V2",
        Default = "0.3",
        Callback = function(value)
            local v = tonumber(value)
            if v and CombinedModules.blatantV2 then CombinedModules.blatantV2.Settings.CompleteDelay = v end
        end
    })

    -- Section: Skin Animation
    local SkinSection = MainTab:AddSection("Skin Animation", false)
    
    local skinNames = {"Eclipse Katana", "Holy Trident", "Soul Scythe", "Oceanic Harpoon", "Binary Edge", "The Vanquisher", "Frozen Krampus Scythe", "1x1x1x1 Ban Hammer", "Corruption Edge", "Princess Parasol"}
    local skinInfo = {
        ["Eclipse Katana"] = "Eclipse",
        ["Holy Trident"] = "HolyTrident",
        ["Soul Scythe"] = "SoulScythe",
        ["Oceanic Harpoon"] = "OceanicHarpoon",
        ["Binary Edge"] = "BinaryEdge",
        ["The Vanquisher"] = "Vanquisher",
        ["Frozen Krampus Scythe"] = "KrampusScythe",
        ["1x1x1x1 Ban Hammer"] = "BanHammer",
        ["Corruption Edge"] = "CorruptionEdge",
        ["Princess Parasol"] = "PrincessParasol"
    }
    local selectedSkin = nil
    local skinAnimEnabled = false
    
    SkinSection:AddDropdown({
        Title = "Select Skin",
        Options = skinNames,
        Default = "Eclipse Katana",
        Callback = function(selected)
            selectedSkin = selected
            if skinAnimEnabled and CombinedModules.SkinSwapAnimation and skinInfo[selected] then
                CombinedModules.SkinSwapAnimation.SwitchSkin(skinInfo[selected])
            end
        end
    })
    
    SkinSection:AddToggle({
        Title = "Enable Skin Animation",
        Default = false,
        Callback = function(on)
            skinAnimEnabled = on
            if CombinedModules.SkinSwapAnimation then
                if on and selectedSkin and skinInfo[selectedSkin] then
                    CombinedModules.SkinSwapAnimation.SwitchSkin(skinInfo[selectedSkin])
                    CombinedModules.SkinSwapAnimation.Enable()
                else
                    CombinedModules.SkinSwapAnimation.Disable()
                end
            end
        end
    })
    local TotemSection = MainTab:AddSection("Auto Totem", false)
    
    TotemSection:AddButton({
        Title = "Auto Totem 3X",
        Callback = function()
            if CombinedModules.AutoTotem3X then
                if CombinedModules.AutoTotem3X.IsRunning() then
                    CombinedModules.AutoTotem3X.Stop()
                else
                    CombinedModules.AutoTotem3X.Start()
                end
            end
        end
    })

    local TradeTab = Window:AddTab({Name = "Trading", Icon = "payment"})

    local TradeGeneralSection = TradeTab:AddSection("Select Player", false)

    local playerDropdown = TradeGeneralSection:AddDropdown({
        Title = "Target Player",
        Options = {},
        Default = nil,
        NoSave = true,
        Callback = function(value)
            if CombinedModules.AutoTrade then
                CombinedModules.AutoTrade.SetTargetPlayer(value)
            end
        end
    })

    TradeGeneralSection:AddButton({
        Title = "Refresh Players",
        Callback = function()
            if CombinedModules.AutoTrade then
                local players = CombinedModules.AutoTrade.GetPlayers()
                playerDropdown:SetOptions(players)
            end
        end
    })

    -- Auto-load players on script start
    task.spawn(function()
        task.wait(1) -- Wait for things to initialize
        if CombinedModules.AutoTrade then
             local players = CombinedModules.AutoTrade.GetPlayers()
             playerDropdown:SetOptions(players)
        end
    end)

    local activeMonitor = nil
    local activeToggle = nil

    -- ByName Section
    local ByNameSection = TradeTab:AddSection("Trade By Name", false)

    local ByNameMonitor = ByNameSection:AddParagraph({
        Title = "Status",
        Content = "Idle"
    })

    local itemDropdown = ByNameSection:AddDropdown({
        Title = "Select Item",
        Options = {},
        Default = nil,
        Callback = function(value)
            if CombinedModules.AutoTrade then
                local itemName = value and (value:match("^(.-) x") or value)
                CombinedModules.AutoTrade.SetItem(itemName)
            end
        end
    })

    ByNameSection:AddButton({
        Title = "Refresh Fish Items",
        Callback = function()
            if CombinedModules.AutoTrade then
                local items = CombinedModules.AutoTrade.GetFishItems()
                itemDropdown:SetOptions(items)
            end
        end
    })

    ByNameSection:AddInput({
        Title = "Amount",
        Default = "1",
        Callback = function(value)
            if CombinedModules.AutoTrade then
                CombinedModules.AutoTrade.SetItemAmount(value)
            end
        end
    })

    local byNameToggle = ByNameSection:AddToggle({
        Title = "Start Trade ByName",
        Default = false,
        NoSave = true,
        Callback = function(on)
            if CombinedModules.AutoTrade then
                if on then
                    activeMonitor = ByNameMonitor
                    activeToggle = byNameToggle
                    CombinedModules.AutoTrade.SetTradeMode("ByName")
                    CombinedModules.AutoTrade.Start()
                else
                    CombinedModules.AutoTrade.Stop()
                end
            end
        end
    })

    ByNameSection:AddButton({
        Title = "Reset Stats",
        Callback = function()
            if CombinedModules.AutoTrade then
                CombinedModules.AutoTrade.ResetStats()
                ByNameMonitor:SetContent("Idle")
            end
        end
    })

    -- ByCoin Section
    local ByCoinSection = TradeTab:AddSection("Trade By Coin", false)

    local ByCoinMonitor = ByCoinSection:AddParagraph({
        Title = "Status",
        Content = "Idle"
    })

    ByCoinSection:AddInput({
        Title = "Target Coins",
        Default = "0",
        Callback = function(value)
            if CombinedModules.AutoTrade then
                CombinedModules.AutoTrade.SetTargetCoins(value)
            end
        end
    })

    local byCoinToggle = ByCoinSection:AddToggle({
        Title = "Start Trade ByCoin",
        Default = false,
        NoSave = true,
        Callback = function(on)
            if CombinedModules.AutoTrade then
                if on then
                    activeMonitor = ByCoinMonitor
                    activeToggle = byCoinToggle
                    CombinedModules.AutoTrade.SetTradeMode("ByCoin")
                    CombinedModules.AutoTrade.Start()
                else
                    CombinedModules.AutoTrade.Stop()
                end
            end
        end
    })

    ByCoinSection:AddButton({
        Title = "Reset Stats",
        Callback = function()
            if CombinedModules.AutoTrade then
                CombinedModules.AutoTrade.ResetStats()
                ByCoinMonitor:SetContent("Idle")
            end
        end
    })

    -- ByRarity Section
    local ByRaritySection = TradeTab:AddSection("Trade By Rarity", false)

    local ByRarityMonitor = ByRaritySection:AddParagraph({
        Title = "Status",
        Content = "Idle"
    })

    ByRaritySection:AddDropdown({
        Title = "Select Rarity",
        Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret"},
        Default = "Common",
        Callback = function(value)
            if CombinedModules.AutoTrade then
                CombinedModules.AutoTrade.SetRarity(value)
            end
        end
    })

    ByRaritySection:AddInput({
        Title = "Amount",
        Default = "1",
        Callback = function(value)
            if CombinedModules.AutoTrade then
                CombinedModules.AutoTrade.SetRarityAmount(value)
            end
        end
    })

    local byRarityToggle = ByRaritySection:AddToggle({
        Title = "Start Trade ByRarity",
        Default = false,
        NoSave = true,
        Callback = function(on)
            if CombinedModules.AutoTrade then
                if on then
                    activeMonitor = ByRarityMonitor
                    activeToggle = byRarityToggle
                    CombinedModules.AutoTrade.SetTradeMode("ByRarity")
                    CombinedModules.AutoTrade.Start()
                else
                    CombinedModules.AutoTrade.Stop()
                end
            end
        end
    })

    ByRaritySection:AddButton({
        Title = "Reset Stats",
        Callback = function()
            if CombinedModules.AutoTrade then
                CombinedModules.AutoTrade.ResetStats()
                ByRarityMonitor:SetContent("Idle")
            end
        end
    })

    -- ByEnchantStone Section
    local ByEnchantStoneSection = TradeTab:AddSection("Trade Enchant Stone", false)

    local ByEnchantStoneMonitor = ByEnchantStoneSection:AddParagraph({
        Title = "Status",
        Content = "Idle"
    })

    ByEnchantStoneSection:AddDropdown({
        Title = "Stone Type",
        Options = {"Normal", "Double", "Evolved"},
        Default = "Normal",
        Callback = function(value)
            if CombinedModules.AutoTrade then
                CombinedModules.AutoTrade.SetStoneType(value)
            end
        end
    })

    ByEnchantStoneSection:AddInput({
        Title = "Amount",
        Default = "1",
        Callback = function(value)
            if CombinedModules.AutoTrade then
                CombinedModules.AutoTrade.SetStoneAmount(value)
            end
        end
    })

    ByEnchantStoneSection:AddButton({
        Title = "Check Enchant Stones",
        Callback = function()
            if CombinedModules.AutoTrade then
                local stones = CombinedModules.AutoTrade.GetEnchantStoneItems()
                if #stones > 0 then
                    ByEnchantStoneMonitor:SetContent("Inventory: " .. table.concat(stones, ", "))
                else
                    ByEnchantStoneMonitor:SetContent("No enchant stones found")
                end
            end
        end
    })

    local byEnchantStoneToggle = ByEnchantStoneSection:AddToggle({
        Title = "Start Trade EnchantStone",
        Default = false,
        NoSave = true,
        Callback = function(on)
            if CombinedModules.AutoTrade then
                if on then
                    activeMonitor = ByEnchantStoneMonitor
                    activeToggle = byEnchantStoneToggle
                    CombinedModules.AutoTrade.SetTradeMode("ByEnchantStone")
                    CombinedModules.AutoTrade.Start()
                else
                    CombinedModules.AutoTrade.Stop()
                end
            end
        end
    })

    ByEnchantStoneSection:AddButton({
        Title = "Reset Stats",
        Callback = function()
            if CombinedModules.AutoTrade then
                CombinedModules.AutoTrade.ResetStats()
                ByEnchantStoneMonitor:SetContent("Idle")
            end
        end
    })

    -- Wire up stats and completion callbacks
    if CombinedModules.AutoTrade then
        CombinedModules.AutoTrade.OnStatsChanged = function(s)
            pcall(function()
                if not activeMonitor then return end
                
                local coinInfo = ""
                if s.coinTraded > 0 then
                    coinInfo = string.format("\nCoins Traded: %d", s.coinTraded)
                end
                activeMonitor:SetContent(string.format(
                    "%s\nProgress: %d/%d | Success: %d | Failed: %d%s",
                    s.status or "?",
                    s.totalSuccess or 0,
                    s.targetAmount or 0,
                    s.totalSuccess or 0,
                    s.totalFailed or 0,
                    coinInfo
                ))
            end)
        end
        
        CombinedModules.AutoTrade.OnCompleted = function(s)
            pcall(function()
                if activeToggle then
                    activeToggle:SetValue(false)
                end
            end)
        end
    end

    -- Section: Auto Accept Trade
    local AutoAcceptSection = TradeTab:AddSection("Auto Accept Trade", false)

    AutoAcceptSection:AddToggle({
        Title = "Auto Accept Trade",
        Default = false,
        NoSave = true,
        Callback = function(on)
            if CombinedModules.AutoAcceptTrade then
                if on then 
                    CombinedModules.AutoAcceptTrade.Start() 
                else 
                    CombinedModules.AutoAcceptTrade.Stop() 
                end
            end
        end
    })

    local FavoriteTab = Window:AddTab({Name = "Favorite", Icon = "star"})
    local AutoFavSection = FavoriteTab:AddSection("Auto Favorite", false)

    if CombinedModules.AutoFavorite then
        local isAutoFavRunning = false
        
        AutoFavSection:AddParagraph({
            Title = "How it works",
            Content = "All selected filters work together (AND logic):\n• Name + Rarity = Fish must match BOTH name AND rarity\n• Name + Variant = Fish must match BOTH name AND variant\n• All three = Fish must match ALL filters\n• Single filter = Only that filter applies"
        })
        
        -- Fish Names Dropdown
        local nameDropdown = AutoFavSection:AddDropdown({
            Title = "Name",
            Content = "Select specific fish names",
            Multi = true,
            Options = CombinedModules.AutoFavorite.GetAllFishNames(),
            Default = {},
            Callback = function(selected)
                CombinedModules.AutoFavorite.SetSelectedNames(selected)
            end
        })
        
        -- Variants Dropdown
        local variantDropdown = AutoFavSection:AddDropdown({
            Title = "Variant",
            Content = "Combined with other filters (AND)",
            Multi = true,
            Options = CombinedModules.AutoFavorite.GetAllVariants(),
            Default = {},
            Callback = function(selected)
                CombinedModules.AutoFavorite.SetSelectedVariants(selected)
            end
        })
        
        -- Rarity Dropdown
        AutoFavSection:AddDropdown({
            Title = "Rarity",
            Content = "Combined with other filters (AND)",
            Multi = true,
            Options = CombinedModules.AutoFavorite.GetAllTiers(),
            Default = {},
            Callback = function(selected)
                CombinedModules.AutoFavorite.SetSelectedRarity(selected)
            end
        })
        
        -- Toggle Auto Favorite
        AutoFavSection:AddToggle({
            Title = "Auto Favorite",
            Default = false,
            Callback = function(on)
                if on then
                    -- Load saved selections from config
                    if Lynx and Lynx.ConfigSystem then
                        local savedNames = Lynx.ConfigSystem.Get("MultiDropdowns.Name", {})
                        local savedVariants = Lynx.ConfigSystem.Get("MultiDropdowns.Variant", {})
                        local savedRarity = Lynx.ConfigSystem.Get("MultiDropdowns.Rarity", {})
                        
                        if savedNames and type(savedNames) == "table" then
                            CombinedModules.AutoFavorite.SetSelectedNames(savedNames)
                        end
                        if savedVariants and type(savedVariants) == "table" then
                            CombinedModules.AutoFavorite.SetSelectedVariants(savedVariants)
                        end
                        if savedRarity and type(savedRarity) == "table" then
                            CombinedModules.AutoFavorite.SetSelectedRarity(savedRarity)
                        end
                    end
                    CombinedModules.AutoFavorite.Start()
                    isAutoFavRunning = true
                else
                    CombinedModules.AutoFavorite.Stop()
                    isAutoFavRunning = false
                end
            end
        })
        
        -- Refresh Lists Button
        AutoFavSection:AddButton({
            Title = "Refresh Lists",
            Callback = function()
                local result = CombinedModules.AutoFavorite.RefreshLists()
                if nameDropdown and nameDropdown.SetOptions then
                    nameDropdown:SetOptions(CombinedModules.AutoFavorite.GetAllFishNames())
                end
                if variantDropdown and variantDropdown.SetOptions then
                    variantDropdown:SetOptions(CombinedModules.AutoFavorite.GetAllVariants())
                end
            end
        })
    end

    -- ══════════════════════════════════════════
    -- TAB: AUTOMATION
    -- ══════════════════════════════════════════
    local AutomationTab = Window:AddTab({Name = "Automation", Icon = "next"})
    
    if CombinedModules.AutoSpawnTotem then
        local AutoSpawnSection = AutomationTab:AddSection("Auto Spawn Totem", false)

        -- Status paragraph (update real-time)
        local totemStatusParagraph = AutoSpawnSection:AddParagraph({
            Title = "Status",
            Content = "Idle"
        })

        -- Dropdown totem (akan di-update async setelah scan)
        local totemDropdown = AutoSpawnSection:AddDropdown({
            Title = "Totem Type",
            Content = "Loading...",
            Options = {"Loading..."},
            Default = "Loading...",
            Callback = function(selected)
                CombinedModules.AutoSpawnTotem.SetTotem(selected)
            end
        })

        -- Async: populate dropdown setelah scan
        task.spawn(function()
            task.wait(2)
            local names = CombinedModules.AutoSpawnTotem.GetTotemNames()
            if totemDropdown and totemDropdown.SetOptions then
                totemDropdown:SetOptions(names)
            end
            -- Set default ke totem pertama
            local current = CombinedModules.AutoSpawnTotem.GetCurrentTotem()
            if not current and #names > 0 then
                CombinedModules.AutoSpawnTotem.SetTotem(names[1])
            end
        end)

        -- Toggle Enable
        AutoSpawnSection:AddToggle({
            Title = "Enable Auto Spawn",
            Default = false,
            NoSave = true,
            Callback = function(on)
                if on then
                    CombinedModules.AutoSpawnTotem.Start()
                else
                    CombinedModules.AutoSpawnTotem.Stop()
                end
            end
        })

        -- Spawn Now button
        AutoSpawnSection:AddButton({
            Title = "Spawn Now",
            Callback = function()
                CombinedModules.AutoSpawnTotem.SpawnNow()
            end
        })

        -- Real-time status updater setiap 5 detik
        task.spawn(function()
            while task.wait(5) do
                if totemStatusParagraph and totemStatusParagraph.SetContent then
                    totemStatusParagraph:SetContent(CombinedModules.AutoSpawnTotem.GetStatus())
                end
            end
        end)
    end

    -- Auto Claim Pirate Chest Section
    if CombinedModules.AutoClaimPirateChest then
        local AutoClaimSection = AutomationTab:AddSection("Auto Claim Pirate Chest", false)
        
        -- Info Paragraph
        AutoClaimSection:AddParagraph({
            Title = "How it works",
            Content = "Automatically claims all Pirate Chests in the game.\n• Monitors workspace.PirateChestStorage\n• Instantly claims new chests\n• Runs every 0.3 seconds"
        })
        
        -- Toggle Auto Claim
        AutoClaimSection:AddToggle({
            Title = "Enable Auto Claim",
            Default = false,
            NoSave = true,
            Callback = function(on)
                if on then
                    CombinedModules.AutoClaimPirateChest.Start()
                else
                    CombinedModules.AutoClaimPirateChest.Stop()
                end
            end
        })
    end

    -- Auto Loch Ness Event Section
    if CombinedModules.AutoLochNessEvent then
        local LochNessSection = AutomationTab:AddSection("Auto Ancient Lochness Monster", false)
        
        -- Schedule Info Paragraph (akan di-update real-time)
        local LochNessScheduleParagraph = LochNessSection:AddParagraph({
            Title = "Event Schedule",
            Content = "Loading schedule..."
        })
        
        -- Status Paragraph (real-time status)
        local LochNessStatusParagraph = LochNessSection:AddParagraph({
            Title = "💤 Status",
            Content = "Idle..."
        })
        
        -- Update schedule info on load
        task.spawn(function()
            task.wait(0.5)
            
            local scheduleInfo = CombinedModules.AutoLochNessEvent.GetScheduleInfo()
            local scheduleText = "Timezone: " .. scheduleInfo.timezone .. "\n\nEvent Times:\n"
            for i, event in ipairs(scheduleInfo.schedule) do
                scheduleText = scheduleText .. string.format("%d. %02d:%02d\n", i, event.hour, event.minute)
            end
            scheduleText = scheduleText .. "\nDuration: 10 minutes per event"
            
            LochNessScheduleParagraph:SetContent(scheduleText)
        end)
        
        -- Real-time status updater (countdown)
        task.spawn(function()
            while task.wait(1) do
                local status = CombinedModules.AutoLochNessEvent.GetStatus()
                
                if status.active then
                    if status.inEvent then
                        LochNessStatusParagraph:SetTitle("EVENT ACTIVE")
                        LochNessStatusParagraph:SetContent(
                            "Location: Loch Ness Monster\nTime Left: " .. status.timeLeft
                        )
                    else
                        LochNessStatusParagraph:SetTitle("Waiting for Event")
                        LochNessStatusParagraph:SetContent(
                            "Next Event: " .. status.nextEvent .. "\nStarts in: " .. status.countdown
                        )
                    end
                else
                    LochNessStatusParagraph:SetTitle("💤 Status")
                    LochNessStatusParagraph:SetContent("Idle...")
                end
            end
        end)
        
        LochNessSection:AddParagraph({
            Title = "How it works",
            Content = "Automatically teleports to Loch Ness Monster event.\n• Saves your position before teleport\n• Stays for 10 minutes\n• Returns to saved position after\n• 6 events per day"
        })
        
        -- Manual Controls
        LochNessSection:AddButton({
            Title = "Teleport Now",
            Callback = function()
                CombinedModules.AutoLochNessEvent.TeleportNow()
            end
        })
        
        LochNessSection:AddButton({
            Title = "Return to Saved Position",
            Callback = function()
                CombinedModules.AutoLochNessEvent.ReturnToSaved()
            end
        })
        
        -- Toggle Auto Event
        LochNessSection:AddToggle({
            Title = "Enable Auto Event",
            Default = false,
            Callback = function(on)
                if on then
                    CombinedModules.AutoLochNessEvent.Start()
                else
                    CombinedModules.AutoLochNessEvent.Stop()
                end
            end
        })
    end

    local EnchantSection = AutomationTab:AddSection("Enchant Features", false)
    
    -- Status Paragraph (auto-updates like EnchantFeatures.lua)
    local EnchantStatusParagraph = EnchantSection:AddParagraph({
        Title = "Enchant Status",
        Content = "Current Rod : None\nCurrent Enchant : None\nEnchant Stones Left : 0"
    })
    
    -- Update status periodically
    if CombinedModules.AutoEnchant then
        task.spawn(function()
            while true do
                task.wait(2)
                pcall(function()
                    local rodName, enchantName, stoneCount = CombinedModules.AutoEnchant.GetEnchantStatus(10)
                    EnchantStatusParagraph:SetContent(
                        ("Current Rod : %s\nCurrent Enchant : %s\nEnchant Stones Left : %d"):format(
                            rodName,
                            enchantName,
                            stoneCount
                        )
                    )
                end)
            end
        end)
    end
    
    -- Stone Type Dropdown (sets both stone and altar automatically)
    EnchantSection:AddDropdown({
        Title = "Enchant Type",
        Options = {
            "Normal Enchant",
            "Second Enchant",
            "Evolved Enchant",
            "Candy Enchant"
        },
        Default = "Normal Enchant",
        Callback = function(value)
            if CombinedModules.AutoEnchant then
                if value == "Evolved Enchant" then
                    -- Evolved Stone: ID 558, Altar 1 (normal altar)
                    CombinedModules.AutoEnchant.SetEnchantStoneType(558)
                    CombinedModules.AutoEnchant.SetEnchantType(1)
                elseif value == "Second Enchant" then
                    -- Double Stone: ID 246, Altar 2 (second altar - Level 200+)
                    CombinedModules.AutoEnchant.SetEnchantStoneType(246)
                    CombinedModules.AutoEnchant.SetEnchantType(2)
                elseif value == "Candy Enchant" then
                    -- Candy Stone: ID 714, Altar 1 (normal altar)
                    CombinedModules.AutoEnchant.SetEnchantStoneType(714)
                    CombinedModules.AutoEnchant.SetEnchantType(1)
                else
                    -- Normal Stone: ID 10, Altar 1 (normal altar)
                    CombinedModules.AutoEnchant.SetEnchantStoneType(10)
                    CombinedModules.AutoEnchant.SetEnchantType(1)
                end
            end
        end
    })
    
    -- Target Enchant Dropdown (includes normal + evolved enchants)
    EnchantSection:AddDropdown({
        Title = "Target Enchant",
        Options = CombinedModules.AutoEnchant.GetEnchantList(),
        Default = "XPerienced I",
        Callback = function(value)
            if CombinedModules.AutoEnchant then
                CombinedModules.AutoEnchant.SetTargetEnchant(value)
            end
        end
    })
    
    -- Auto Enchant Toggle
    EnchantSection:AddToggle({
        Title = "Auto Enchant Reroll",
        Default = false,
        NoSave = true,
        Callback = function(on)
            if CombinedModules.AutoEnchant then
                if on then 
                    CombinedModules.AutoEnchant.Start() 
                else 
                    CombinedModules.AutoEnchant.Stop() 
                end
            end
        end
    })

    -- Teleport to Altar 1 Button (Normal/Evolved Enchant)
    EnchantSection:AddButton({
        Title = "Teleport to Altar 1",
        Callback = function()
            local LP = game.Players.LocalPlayer
            local character = LP.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                character.HumanoidRootPart.CFrame = CFrame.new(3245, -1301, 1394)
            end
        end
    })
    
    -- Teleport to Altar 2 Button (Second Enchant)
    EnchantSection:AddButton({
        Title = "Teleport to Altar 2",
        Callback = function()
            local LP = game.Players.LocalPlayer
            local character = LP.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                character.HumanoidRootPart.CFrame = CFrame.new(1478.29846, 126.044891, -613.519653)
            end
        end
    })
    -- ══════════════════════════════════════════
    -- TAB: TELEPORT
    -- ══════════════════════════════════════════
    local TeleportTab = Window:AddTab({Name = "Teleport", Icon = "gps"})
    
    -- Section: Location Teleport
    local LocationSection = TeleportTab:AddSection("Teleport to Location")
    
    if CombinedModules.TeleportModule then
        local locationItems = {}
        for name, _ in pairs(CombinedModules.TeleportModule.Locations or {}) do
            table.insert(locationItems, name)
        end
        table.sort(locationItems)
        
        -- Variable untuk menyimpan lokasi yang dipilih
        local selectedLocation = nil
        
        LocationSection:AddDropdown({
        Title = "Select Location",
            Options = locationItems,
            Default = nil,
            Callback = function(selected)
                selectedLocation = selected
            end
        })
        
        LocationSection:AddButton({
            Title = "Teleport Now",
            Callback = function()
                if selectedLocation then
                    CombinedModules.TeleportModule.TeleportTo(selectedLocation)
                else
                    warn("[Teleport] Please select a location first!")
                end
            end
        })
    end

    -- Section: Saved Location
    local SavedLocSection = TeleportTab:AddSection("Saved Location", false)
    
    SavedLocSection:AddButton({
        Title = "Save Current Location",
        Callback = function()
            if CombinedModules.SavedLocation then CombinedModules.SavedLocation.Save() end
        end
    })
    
    SavedLocSection:AddButton({
        Title = "Teleport to Saved",
        Callback = function()
            if CombinedModules.SavedLocation then CombinedModules.SavedLocation.Teleport() end
        end
    })
    
    SavedLocSection:AddButton({
        Title = "Reset Saved Location",
        Callback = function()
            if CombinedModules.SavedLocation then CombinedModules.SavedLocation.Reset() end
        end
    })
    
    SavedLocSection:AddToggle({
        Title = "Enable Auto Teleport",
        Default = false,
        Callback = function(on)
            if CombinedModules.SavedLocation then
                if on then
                    CombinedModules.SavedLocation.EnableAutoTeleport()
                else
                    CombinedModules.SavedLocation.DisableAutoTeleport()
                end
            end
        end
    })

    -- Section: Teleport to Player
    local PlayerTPSection = TeleportTab:AddSection("Teleport to Player", false)
    
    local playerItems = {}
    local selectedPlayer = nil
    local playerDropdown = nil
    
    local function updatePlayerList()
        table.clear(playerItems)
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                table.insert(playerItems, player.Name)
            end
        end
        table.sort(playerItems)
    end
    updatePlayerList()
    
    playerDropdown = PlayerTPSection:AddDropdown({
        Title = "Select Player",
        Options = playerItems,
        Default = nil,
        Callback = function(selected)
            selectedPlayer = selected
        end
    })
    
    PlayerTPSection:AddButton({
        Title = "Teleport Now",
        Callback = function()
            if selectedPlayer then
                if CombinedModules.TeleportToPlayer then
                    CombinedModules.TeleportToPlayer.TeleportTo(selectedPlayer)
                end
            else
                warn("[Teleport] Please select a player first!")
            end
        end
    })
    
    PlayerTPSection:AddButton({
        Title = "Refresh Player List",
        Callback = function()
            updatePlayerList()
            if playerDropdown and playerDropdown.SetOptions then
                playerDropdown:SetOptions(playerItems)
            end
        end
    })

   local EventTPSection = TeleportTab:AddSection("Event Teleport", false)

    local selectedEventName = nil
    local eventNames = {}
    local autoEventToggle = nil

    if CombinedModules.AutoEvent and CombinedModules.AutoEvent.GetEventNames then
        eventNames = CombinedModules.AutoEvent.GetEventNames()
    end

    EventTPSection:AddDropdown({
        Title = "Select Event",
        Options = eventNames,
        Default = nil,
        Callback = function(selected)
            selectedEventName = selected
            
            -- Jika toggle sedang aktif, langsung restart dengan event baru
            if autoEventToggle and autoEventToggle.Value then
                if CombinedModules.AutoEvent then
                    -- Stop dulu event yang lama
                    CombinedModules.AutoEvent.Stop()
                    
                    -- Delay kecil agar stop selesai
                    task.wait(0.1)
                    
                    -- Start dengan event baru jika valid
                    if selected and CombinedModules.AutoEvent.HasEventPattern(selected) then
                        CombinedModules.AutoEvent.Start(selected)
                    end
                end
            end
        end
    })

    autoEventToggle = EventTPSection:AddToggle({
        Title = "Enable Auto Teleport",
        Default = false,
        Callback = function(on)
            if CombinedModules.AutoEvent then
                if on then
                    -- Load saved event from config if not set
                    if Lynx and Lynx.ConfigSystem and (selectedEventName == nil or selectedEventName == "") then
                        selectedEventName = Lynx.ConfigSystem.Get("Dropdowns.Select_Event", nil)
                    end
                    
                    if selectedEventName and CombinedModules.AutoEvent.HasEventPattern(selectedEventName) then
                        CombinedModules.AutoEvent.Start(selectedEventName)
                    else
                        -- Matikan toggle jika tidak ada event yang dipilih
                        if autoEventToggle and autoEventToggle.SetValue then
                            autoEventToggle:SetValue(false)
                        end
                    end
                else
                    CombinedModules.AutoEvent.Stop()
                end
            end
        end
    })

    -- ══════════════════════════════════════════
    -- TAB: SHOP
    -- ══════════════════════════════════════════
    local ShopTab = Window:AddTab({Name = "Shop", Icon = "cart"})
    
    -- Section: Sell
    local SellSection = ShopTab:AddSection("Auto Sell")

    if CombinedModules.AutoSellSystem then
        
        -- Button: Sell All Now
        SellSection:AddButton({
            Title = "Sell All Now",
            Callback = function()
                CombinedModules.AutoSellSystem.SellOnce()
            end
        })
        
        -- State
        local autoSellMode = "Timer"
        local autoSellToggle = nil
        
        -- Dropdown: Auto Sell Mode
        SellSection:AddDropdown({
            Title = "Auto Sell Mode",
            Options = {"Timer", "By Count"},
            Default = "Timer",
            Callback = function(selected)
                local previousMode = autoSellMode
                autoSellMode = selected
                
                -- If toggle is active, restart with new mode
                if autoSellToggle and autoSellToggle.Value then
                    -- Stop old mode
                    if previousMode == "Timer" then
                        CombinedModules.AutoSellSystem.Timer.Stop()
                    else
                        CombinedModules.AutoSellSystem.Count.Stop()
                    end
                    
                    task.wait(0.1)
                    
                    -- Start new mode
                    if selected == "Timer" then
                        CombinedModules.AutoSellSystem.Timer.Start()
                    else
                        CombinedModules.AutoSellSystem.Count.Start()
                    end
                end
            end
        })
        
        -- Input: Value (Seconds / Fish Count)
        SellSection:AddInput({
            Title = "Value (Seconds / Fish Count)",
            Default = "5",
            Callback = function(value)
                local numValue = tonumber(value)
                if numValue then
                    CombinedModules.AutoSellSystem.Timer.SetInterval(numValue)
                    CombinedModules.AutoSellSystem.Count.SetTarget(numValue)
                end
            end
        })
        
        -- Toggle: Enable Auto Sell
        autoSellToggle = SellSection:AddToggle({
            Title = "Enable Auto Sell",
            Default = false,
            Callback = function(on)
                if not CombinedModules.AutoSellSystem then return end
                
                if on then
                    -- Load saved mode from config if available
                    if Lynx and Lynx.ConfigSystem then
                        local savedMode = Lynx.ConfigSystem.Get("Dropdowns.Auto_Sell_Mode", "Timer")
                        if savedMode then
                            autoSellMode = savedMode
                        end
                    end
                    
                    -- Start appropriate mode
                    if autoSellMode == "Timer" then
                        CombinedModules.AutoSellSystem.Timer.Start()
                    else
                        CombinedModules.AutoSellSystem.Count.Start()
                    end
                else
                    -- Stop both modes to ensure cleanup
                    CombinedModules.AutoSellSystem.Timer.Stop()
                    CombinedModules.AutoSellSystem.Count.Stop()
                end
            end
        })
    end

    -- Section: Merchant
    local MerchantSection = ShopTab:AddSection("Remote Merchant", false)
    
    MerchantSection:AddButton({
        Title = "Open Merchant",
        Callback = function()
            if CombinedModules.MerchantSystem then CombinedModules.MerchantSystem.Open() end
        end
    })
    
    MerchantSection:AddButton({
        Title = "Close Merchant",
        Callback = function()
            if CombinedModules.MerchantSystem then CombinedModules.MerchantSystem.Close() end
        end
    })

    -- Section: Auto Buy Weather
    local WeatherSection = ShopTab:AddSection("Auto Buy Weather", false)

    if CombinedModules.AutoBuyWeather then
        local selectedWeathers = {}
        local autoWeatherToggle = nil
        local isWeatherRunning = false
        
        WeatherSection:AddDropdown({
            Title = "Select Weather Types",
            Multi = true,
            Options = CombinedModules.AutoBuyWeather.AllWeathers,
            Default = {},
            Callback = function(selected)
                selectedWeathers = selected
                
                if CombinedModules.AutoBuyWeather.SetSelected then
                    CombinedModules.AutoBuyWeather.SetSelected(selectedWeathers)
                end
                
                -- If toggle is already on, restart with new selection (real-time update)
                if isWeatherRunning and #selectedWeathers > 0 then
                    CombinedModules.AutoBuyWeather.Stop()
                    task.wait(0.1)
                    CombinedModules.AutoBuyWeather.Start()
                end
            end
        })
        
        autoWeatherToggle = WeatherSection:AddToggle({
            Title = "Enable Auto Weather",
            Default = false,
            Callback = function(on)
                if CombinedModules.AutoBuyWeather then
                    if on then
                        -- Load saved weathers from config if local variable is empty
                        if Lynx and Lynx.ConfigSystem and #selectedWeathers == 0 then
                            local savedWeathers = Lynx.ConfigSystem.Get("MultiDropdowns.Select_Weather_Types", {})
                            if savedWeathers and type(savedWeathers) == "table" and #savedWeathers > 0 then
                                selectedWeathers = savedWeathers
                                if CombinedModules.AutoBuyWeather.SetSelected then
                                    CombinedModules.AutoBuyWeather.SetSelected(selectedWeathers)
                                end
                            end
                        end
                        
                        if not CombinedModules.AutoBuyWeather.IsAvailable() then
                            print("Weather remote not available")
                            if autoWeatherToggle and autoWeatherToggle.SetValue then
                                autoWeatherToggle:SetValue(false)
                            end
                            return
                        end
                        
                        if #selectedWeathers == 0 then
                            print("Please select at least one weather type")
                            if autoWeatherToggle and autoWeatherToggle.SetValue then
                                autoWeatherToggle:SetValue(false)
                            end
                            return
                        end
                        
                        local success = CombinedModules.AutoBuyWeather.Start()
                        if success then
                            isWeatherRunning = true
                            print("Auto Buy Weather started")
                        else
                            print("Failed to start Auto Buy Weather")
                            if autoWeatherToggle and autoWeatherToggle.SetValue then
                                autoWeatherToggle:SetValue(false)
                            end
                        end
                    else
                        CombinedModules.AutoBuyWeather.Stop()
                        isWeatherRunning = false
                        print("Auto Buy Weather stopped")
                    end
                end
            end
        })
    end

local CharmSection = ShopTab:AddSection("Auto Buy Charm", false)

    if CombinedModules.BuyCharm then
        local selectedCharmEntry = nil
        local charmDropdown = nil
        
        -- Paragraph: harga charm yang dipilih
        local charmPriceParagraph = CharmSection:AddParagraph({
            Title = "Charm Info",
            Content = "Memuat daftar charm..."
        })
        
        -- Dropdown: awalnya kosong, diisi oleh task.spawn di bawah
        charmDropdown = CharmSection:AddDropdown({
            Title = "Charm Type",
            Options = {"Loading..."},
            Default = "Loading...",
            Callback = function(selected)
                local entry = CombinedModules.BuyCharm.SetCharmByName(selected)
                if entry then
                    selectedCharmEntry = entry
                    if charmPriceParagraph and charmPriceParagraph.SetContent then
                        charmPriceParagraph:SetContent(
                            "Name: " .. entry.Name .. "\nPrice: " .. tostring(entry.Price) .. " coins"
                        )
                    end
                end
            end
        })
        
        -- Scan charm secara async setelah game fully loaded
        task.spawn(function()
            task.wait(2) -- beri waktu RS.Charm terload sempurna
            local newList = CombinedModules.BuyCharm.Refresh()
            local names = CombinedModules.BuyCharm.GetCharmNames()
            
            -- Update dropdown dengan list nyata
            if charmDropdown and charmDropdown.SetOptions then
                charmDropdown:SetOptions(names)
            end
            
            -- Set default ke charm pertama
            if #newList > 0 then
                selectedCharmEntry = newList[1]
                CombinedModules.BuyCharm.SetCharmType(selectedCharmEntry.Id)
                if charmPriceParagraph and charmPriceParagraph.SetContent then
                    charmPriceParagraph:SetContent(
                        "Name: " .. selectedCharmEntry.Name ..
                        "\nPrice: " .. tostring(selectedCharmEntry.Price) .. " coins"
                    )
                end
            else
                if charmPriceParagraph and charmPriceParagraph.SetContent then
                    charmPriceParagraph:SetContent("Tidak ada charm ditemukan di game.")
                end
            end
        end)
        
        -- Input: Amount
        CharmSection:AddInput({
            Title = "Amount",
            Default = "1",
            Callback = function(value)
                local numValue = tonumber(value)
                if numValue and numValue > 0 and numValue <= 1000 then
                    CombinedModules.BuyCharm.SetAmount(numValue)
                end
            end
        })
        
        -- Input: Delay
        CharmSection:AddInput({
            Title = "Delay (seconds)",
            Default = "0.5",
            Callback = function(value)
                local numValue = tonumber(value)
                if numValue and numValue >= 0 and numValue <= 10 then
                    CombinedModules.BuyCharm.SetDelay(numValue)
                end
            end
        })
        
        -- Button: Buy Charm
        CharmSection:AddButton({
            Title = "Buy Charm",
            Callback = function()
                if CombinedModules.BuyCharm.IsBuying then return end
                if not selectedCharmEntry then
                    warn("[BuyCharm] Pilih charm terlebih dahulu!")
                    return
                end
                if not CombinedModules.BuyCharm.TestConnection() then
                    warn("[BuyCharm] Remote tidak tersedia!")
                    return
                end
                CombinedModules.BuyCharm.Start()
            end
        })
        
        -- Button: Refresh Charm List (manual)
        CharmSection:AddButton({
            Title = "Refresh Charm List",
            Callback = function()
                local newList = CombinedModules.BuyCharm.Refresh()
                local names = CombinedModules.BuyCharm.GetCharmNames()
                if charmDropdown and charmDropdown.SetOptions then
                    charmDropdown:SetOptions(names)
                end
                if #newList > 0 then
                    selectedCharmEntry = newList[1]
                    CombinedModules.BuyCharm.SetCharmType(selectedCharmEntry.Id)
                    if charmPriceParagraph and charmPriceParagraph.SetContent then
                        charmPriceParagraph:SetContent(
                            "Name: " .. selectedCharmEntry.Name ..
                            "\nPrice: " .. tostring(selectedCharmEntry.Price) .. " coins"
                        )
                    end
                end
                warn("[BuyCharm] Refresh manual: " .. #newList .. " charm.")
            end
        })
    end

    -- ══════════════════════════════════════════
    -- TAB: CAMERA
    -- ══════════════════════════════════════════
    local CameraTab = Window:AddTab({Name = "Camera", Icon = "eyes"})
    
    -- Section: Unlimited Zoom
    local ZoomSection = CameraTab:AddSection("Unlimited Zoom")
    
    ZoomSection:AddToggle({
        Title = "Enable Unlimited Zoom",
        Default = false,
        Callback = function(on)
            if CombinedModules.UnlimitedZoom then
                if on then CombinedModules.UnlimitedZoom.Enable() else CombinedModules.UnlimitedZoom.Disable() end
            end
        end
    })

    -- Section: Freecam
    local FreecamSection = CameraTab:AddSection("Freecam", false)
    
    FreecamSection:AddToggle({
        Title = "Enable Freecam (F3 Toggle)",
        Default = false,
        Callback = function(on)
            if CombinedModules.FreecamModule then
                CombinedModules.FreecamModule.EnableF3Keybind(on)
                if not on and CombinedModules.FreecamModule.IsActive() then
                    CombinedModules.FreecamModule.Stop()
                end
            end
        end
    })
    
    FreecamSection:AddInput({
        Title = "Movement Speed",
        Default = "50",
        Callback = function(value)
            local v = tonumber(value)
            if v and CombinedModules.FreecamModule and CombinedModules.FreecamModule.SetSpeed then
                CombinedModules.FreecamModule.SetSpeed(v)
            end
        end
    })
    
    FreecamSection:AddInput({
        Title = "Mouse Sensitivity",
        Default = "0.5",
        Callback = function(value)
            local v = tonumber(value)
            if v and CombinedModules.FreecamModule and CombinedModules.FreecamModule.SetSensitivity then
                CombinedModules.FreecamModule.SetSensitivity(v)
            end
        end
    })

    -- ══════════════════════════════════════════
    -- TAB: WEBHOOK
    -- ══════════════════════════════════════════
    local WebhookTab = Window:AddTab({Name = "Webhook", Icon = "send"})
    
    -- ══════════════════════════════════════════
    -- Section: Fish Caught Webhook
    -- ══════════════════════════════════════════
    local FishCaughtSection = WebhookTab:AddSection("Fish Caught Webhook")
    
    local currentWebhookURL = ""
    local currentDiscordID = ""
    local fishWebhookToggle = nil
    
    FishCaughtSection:AddInput({
        Title = "Webhook URL",
        Default = "",
        Placeholder = "https://discord.com/api/webhooks/...",
        Callback = function(value)
            currentWebhookURL = value:gsub("^%s*(.-)%s*$", "%1")
            if CombinedModules.Webhook and CombinedModules.Webhook.SetFishWebhookURL then
                pcall(function()
                    CombinedModules.Webhook:SetFishWebhookURL(currentWebhookURL)
                end)
            end
        end
    })
    
    FishCaughtSection:AddInput({
        Title = "Discord User ID (for mention)",
        Default = "",
        Placeholder = "123456789012345678",
        Callback = function(value)
            currentDiscordID = value:gsub("^%s*(.-)%s*$", "%1")
            if CombinedModules.Webhook and CombinedModules.Webhook.SetFishDiscordUserID then
                pcall(function()
                    CombinedModules.Webhook:SetFishDiscordUserID(currentDiscordID)
                end)
            end
        end
    })
    
    local currentFishHideIdentity = ""
    FishCaughtSection:AddInput({
        Title = "Hide Identity (Custom Name)",
        Default = "",
        Placeholder = "Enter custom name...",
        Callback = function(value)
            currentFishHideIdentity = value:gsub("^%s*(.-)%s*$", "%1")
            if CombinedModules.Webhook and CombinedModules.Webhook.SetFishHideIdentity then
                pcall(function()
                    CombinedModules.Webhook:SetFishHideIdentity(currentFishHideIdentity)
                end)
            end
        end
    })
    
    -- Fish Name Filter Dropdown
    local webhookFishNameOptions = {"Loading..."}
    if CombinedModules.AutoFavorite and CombinedModules.AutoFavorite.GetAllFishNames then
        webhookFishNameOptions = CombinedModules.AutoFavorite.GetAllFishNames()
    end
    
    FishCaughtSection:AddDropdown({
        Title = "Name Filter",
        Content = "Only send webhook for specific fish",
        Options = webhookFishNameOptions,
        Multi = true,
        Default = {},
        Callback = function(selected)
            if CombinedModules.Webhook and CombinedModules.Webhook.SetFishEnabledNames then
                pcall(function()
                    CombinedModules.Webhook:SetFishEnabledNames(selected)
                end)
            end
        end
    })
    
    -- Variant Filter Dropdown
    local webhookVariantOptions = {"Loading..."}
    if CombinedModules.AutoFavorite and CombinedModules.AutoFavorite.GetAllVariants then
        webhookVariantOptions = CombinedModules.AutoFavorite.GetAllVariants()
    end
    
    FishCaughtSection:AddDropdown({
        Title = "Variant Filter",
        Content = "Only send webhook for specific variants",
        Options = webhookVariantOptions,
        Multi = true,
        Default = {},
        Callback = function(selected)
            if CombinedModules.Webhook and CombinedModules.Webhook.SetFishEnabledVariants then
                pcall(function()
                    CombinedModules.Webhook:SetFishEnabledVariants(selected)
                end)
            end
        end
    })
    
    FishCaughtSection:AddDropdown({
        Title = "Rarity Filter",
        Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET"},
        Multi = true,
        Default = {},
        Callback = function(selected)
            if CombinedModules.Webhook then
                if CombinedModules.Webhook.SetFishEnabledRarities then
                    pcall(function()
                        CombinedModules.Webhook:SetFishEnabledRarities(selected)
                    end)
                end
            end
        end
    })
    
    fishWebhookToggle = FishCaughtSection:AddToggle({
        Title = "Enable Fish Webhook",
        Default = false,
        Callback = function(on)
            if CombinedModules.Webhook then
                if on then
                    -- Load saved values from config if local variables are empty
                    if Lynx and Lynx.ConfigSystem then
                        if currentWebhookURL == "" then
                            currentWebhookURL = Lynx.ConfigSystem.Get("Inputs.Webhook_URL", "") or ""
                        end
                        if currentDiscordID == "" then
                            currentDiscordID = Lynx.ConfigSystem.Get("Inputs.Discord_User_ID_(for_mention)", "") or ""
                        end
                        if currentFishHideIdentity == "" then
                            currentFishHideIdentity = Lynx.ConfigSystem.Get("Inputs.Hide_Identity_(Custom_Name)", "") or ""
                        end
                    end
                    
                    if currentWebhookURL == "" then
                        if fishWebhookToggle and fishWebhookToggle.SetValue then
                            fishWebhookToggle:SetValue(false)
                        end
                        return
                    end
                    
                    pcall(function()
                        -- Set URL and Discord ID
                        if CombinedModules.Webhook.SetFishWebhookURL then
                            CombinedModules.Webhook:SetFishWebhookURL(currentWebhookURL)
                        end
                        if CombinedModules.Webhook.SetFishDiscordUserID and currentDiscordID ~= "" then
                            CombinedModules.Webhook:SetFishDiscordUserID(currentDiscordID)
                        end
                        -- Set Hide Identity
                        if CombinedModules.Webhook.SetFishHideIdentity and currentFishHideIdentity ~= "" then
                            CombinedModules.Webhook:SetFishHideIdentity(currentFishHideIdentity)
                        end
                        -- Load saved rarity filter from config
                        if CombinedModules.Webhook.SetFishEnabledRarities and Lynx and Lynx.ConfigSystem then
                            local savedRarities = Lynx.ConfigSystem.Get("MultiDropdowns.Rarity_Filter", {})
                            if savedRarities and type(savedRarities) == "table" then
                                CombinedModules.Webhook:SetFishEnabledRarities(savedRarities)
                            end
                        end
                        -- Load saved name filter from config
                        if CombinedModules.Webhook.SetFishEnabledNames and Lynx and Lynx.ConfigSystem then
                            local savedNames = Lynx.ConfigSystem.Get("MultiDropdowns.Name_Filter", {})
                            if savedNames and type(savedNames) == "table" then
                                CombinedModules.Webhook:SetFishEnabledNames(savedNames)
                            end
                        end
                        -- Load saved variant filter from config
                        if CombinedModules.Webhook.SetFishEnabledVariants and Lynx and Lynx.ConfigSystem then
                            local savedVariants = Lynx.ConfigSystem.Get("MultiDropdowns.Variant_Filter", {})
                            if savedVariants and type(savedVariants) == "table" then
                                CombinedModules.Webhook:SetFishEnabledVariants(savedVariants)
                            end
                        end
                        -- Start webhook
                        if CombinedModules.Webhook.StartFishWebhook then
                            CombinedModules.Webhook:StartFishWebhook()
                        end
                    end)
                else
                    pcall(function()
                        if CombinedModules.Webhook.StopFishWebhook then
                            CombinedModules.Webhook:StopFishWebhook()
                        end
                    end)
                end
            end
        end
    })
    
    FishCaughtSection:AddButton({
        Title = "Test Webhook",
        Callback = function()
            if currentWebhookURL == "" then return end

            local requestFunc = nil
            pcall(function()
                requestFunc = (syn and syn.request) or (http and http.request) or http_request or request
            end)
            
            if requestFunc then
                pcall(function()
                    requestFunc({
                        Url = currentWebhookURL,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = HttpService:JSONEncode({
                            embeds = {{
                                title = "✅ Webhook Test Successful!",
                                description = "Lynx GUI is ready to send fish notifications.",
                                color = 65280,
                                footer = {
                                    text = "Lynx Fish Webhook Test",
                                    icon_url = "https://i.imgur.com/shnNZuT.png"
                                },
                                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                            }}
                        })
                    })
                end)
            end
        end
    })

    -- ══════════════════════════════════════════
    -- Section: Disconnect Webhook
    -- ══════════════════════════════════════════
    local DisconnectWebhookSection = WebhookTab:AddSection("Disconnect Webhook", false)
    
    local disconnectWebhookURL = ""
    local disconnectDiscordID = ""
    local disconnectHideIdentity = ""
    
    DisconnectWebhookSection:AddParagraph({
        Title = "Info",
        Content = "Kirim notifikasi ke Discord saat Roblox disconnect, dan otomatis rejoin."
    })
    
    DisconnectWebhookSection:AddInput({
        Title = "Disconnect Webhook URL",
        Default = "",
        Placeholder = "https://discord.com/api/webhooks/...",
        Callback = function(value)
            disconnectWebhookURL = value:gsub("^%s*(.-)%s*$", "%1")
            if CombinedModules.Webhook and CombinedModules.Webhook.SetDisconnectWebhookURL then
                pcall(function()
                    CombinedModules.Webhook:SetDisconnectWebhookURL(disconnectWebhookURL)
                end)
            end
        end
    })
    
    DisconnectWebhookSection:AddInput({
        Title = "Discord User ID (for mention)",
        Default = "",
        Placeholder = "123456789012345678",
        Callback = function(value)
            disconnectDiscordID = value:gsub("^%s*(.-)%s*$", "%1")
            if CombinedModules.Webhook and CombinedModules.Webhook.SetDisconnectDiscordUserID then
                pcall(function()
                    CombinedModules.Webhook:SetDisconnectDiscordUserID(disconnectDiscordID)
                end)
            end
        end
    })
    
    DisconnectWebhookSection:AddInput({
        Title = "Hide Identity (Custom Name)",
        Default = "",
        Placeholder = "Enter custom name...",
        Callback = function(value)
            disconnectHideIdentity = value:gsub("^%s*(.-)%s*$", "%1")
            if CombinedModules.Webhook and CombinedModules.Webhook.SetDisconnectHideIdentity then
                pcall(function()
                    CombinedModules.Webhook:SetDisconnectHideIdentity(disconnectHideIdentity)
                end)
            end
        end
    })
    
    DisconnectWebhookSection:AddToggle({
        Title = "Enable Disconnect Alert",
        Default = false,
        Callback = function(on)
            if CombinedModules.Webhook and CombinedModules.Webhook.EnableDisconnectWebhook then
                pcall(function()
                    CombinedModules.Webhook:EnableDisconnectWebhook(on)
                end)
            end
        end
    })
    
    DisconnectWebhookSection:AddButton({
        Title = "Test Disconnect Webhook",
        Callback = function()
            if disconnectWebhookURL == "" then return end
            
            if CombinedModules.Webhook and CombinedModules.Webhook.TestDisconnectWebhook then
                pcall(function()
                    CombinedModules.Webhook:TestDisconnectWebhook()
                end)
            end
        end
    })

    -- ══════════════════════════════════════════
    -- TAB: SETTINGS
    -- ══════════════════════════════════════════
    local SettingsTab = Window:AddTab({Name = "Settings", Icon = "settings"})
    
    -- Section: Protection
    local ProtectionSection = SettingsTab:AddSection("Protection")
    
    ProtectionSection:AddToggle({
        Title = "Anti-AFK",
        Default = false,
        Callback = function(on)
            if CombinedModules.AntiAFK then
                if on then CombinedModules.AntiAFK.Start() else CombinedModules.AntiAFK.Stop() end
            end
        end
    })
    
    ProtectionSection:AddToggle({
        Title = "Anti Staff (Auto Kick)",
        Default = false,
        Callback = function(on)
            if CombinedModules.AntiStaff then
                if on then CombinedModules.AntiStaff.Start() else CombinedModules.AntiStaff.Stop() end
            end
        end
    })

        -- AUTO RECONNECT SECTION (CLEAN VERSION)

    local ReconnectSection = SettingsTab:AddSection("Auto Reconnect & Execute")

    -- Setup Auto Execute Function
    local function setupAutoExecute(state)
        if not CombinedModules.AutoReconnect then
            return
        end
        
        if state then
            -- GANTI URL INI DENGAN URL SCRIPT KAMU
            local scriptURL = "https://raw.githubusercontent.com/4LynxX/Lynx/refs/heads/main/LynxxMain.lua"
            
            CombinedModules.AutoReconnect:SetScriptURL(scriptURL)
            CombinedModules.AutoReconnect:SetExecuteDelay(3)
            CombinedModules.AutoReconnect:SetMaxAttempts(10)
            CombinedModules.AutoReconnect:EnableAutoExecute()
        else
            CombinedModules.AutoReconnect:DisableAutoExecute()
        end
    end

    -- Toggle: Auto Reconnect
    ReconnectSection:AddToggle({
        Title = "Enable Auto Reconnect",
        Default = false,
        Callback = function(on)
            if CombinedModules.AutoReconnect then
                if on then 
                    CombinedModules.AutoReconnect:Enable()
                else 
                    CombinedModules.AutoReconnect:Disable()
                end
            end
        end
    })

    -- Toggle: Auto Execute
    ReconnectSection:AddToggle({
        Title = "Enable Auto Execute",
        Default = false,
        Callback = function(on)
            setupAutoExecute(on)
        end
    })

    -- Section: Performance
    local PerformanceSection = SettingsTab:AddSection("Performance", false)
    
    PerformanceSection:AddToggle({
        Title = "FPS Booster",
        Default = false,
        Callback = function(on)
            if CombinedModules.PotatoMode then
                if on then 
                    CombinedModules.PotatoMode.Enable() 
                else 
                    CombinedModules.PotatoMode.Disable() 
                end
            end
        end
    })
    
    PerformanceSection:AddToggle({
        Title = "Disable 3D Rendering",
        Default = false,
        Callback = function(on)
            if CombinedModules.DisableRendering then
                if on then CombinedModules.DisableRendering.Start() else CombinedModules.DisableRendering.Stop() end
            end
        end
    })

    local selectedFpsCap = 60
    
    PerformanceSection:AddDropdown({
        Title = "FPS Cap",
        Options = {"60", "90", "120", "240"},
        Default = "60",
        Callback = function(value)
            selectedFpsCap = tonumber(value) or 60
            if CombinedModules.UnlockFPS then
                CombinedModules.UnlockFPS.SetCap(selectedFpsCap)
            end
        end
    })
    
    PerformanceSection:AddToggle({
        Title = "Enable FPS Unlock",
        Default = false,
        Callback = function(on)
            if CombinedModules.UnlockFPS then
                if on then
                    -- Load from config if not set
                    if Lynx and Lynx.ConfigSystem then
                        local savedCap = Lynx.ConfigSystem.Get("Dropdowns.FPS_Cap", "60")
                        if savedCap then
                            selectedFpsCap = tonumber(savedCap) or 60
                        end
                    end
                    CombinedModules.UnlockFPS.CurrentCap = selectedFpsCap
                    CombinedModules.UnlockFPS.Start()
                else
                    CombinedModules.UnlockFPS.Stop()
                end
            end
        end
    })

    -- Section: Hide Stats
    local HideStatsSection = SettingsTab:AddSection("Hide Stats", false)
    
    HideStatsSection:AddToggle({
        Title = "Enable Hide Stats",
        Default = false,
        Callback = function(on)
            if CombinedModules.HideStats then
                if on then CombinedModules.HideStats.Enable() else CombinedModules.HideStats.Disable() end
            end
        end
    })
    
    HideStatsSection:AddInput({
        Title = "Fake Name",
        Default = "Guest",
        Callback = function(value)
            if CombinedModules.HideStats and CombinedModules.HideStats.SetFakeName then
                CombinedModules.HideStats.SetFakeName(value)
            end
        end
    })
    
    HideStatsSection:AddInput({
        Title = "Fake Level",
        Default = "1",
        Callback = function(value)
            if CombinedModules.HideStats and CombinedModules.HideStats.SetFakeLevel then
                CombinedModules.HideStats.SetFakeLevel(value)
            end
        end
    })

    -- Section: Server
    local ServerSection = SettingsTab:AddSection("Server", false)
    
    ServerSection:AddButton({
        Title = "Rejoin Server",
        Callback = function()
            pcall(function()
                TeleportService:Teleport(game.PlaceId, localPlayer)
            end)
        end
    })

    -- Section: Player Utility
    local UtilitySection = SettingsTab:AddSection("Player Utility", false)
    
    UtilitySection:AddInput({
        Title = "Sprint Speed",
        Default = "50",
        Callback = function(value)
            local v = tonumber(value)
            if v and CombinedModules.MovementModule then
                CombinedModules.MovementModule.SetSprintSpeed(v)
            end
        end
    })
    
    UtilitySection:AddToggle({
        Title = "Enable Sprint",
        Default = false,
        Callback = function(on)
            if CombinedModules.MovementModule then
                if on then CombinedModules.MovementModule.EnableSprint() else CombinedModules.MovementModule.DisableSprint() end
            end
        end
    })
    
    UtilitySection:AddToggle({
        Title = "Enable Infinite Jump",
        Default = false,
        Callback = function(on)
            if CombinedModules.MovementModule then
                if on then CombinedModules.MovementModule.EnableInfiniteJump() else CombinedModules.MovementModule.DisableInfiniteJump() end
            end
        end
    })

        -- ══════════════════════════════════════════
    -- Section: Config Management
    -- ══════════════════════════════════════════
    local ConfigSection = SettingsTab:AddSection("Config Management", false)
    
    -- Get game name for config folder
    local gameName = tostring(game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name)
    gameName = gameName:gsub("[^%w_ ]", "")
    gameName = gameName:gsub("%s+", "_")
    local configFolder = "Lynx/Configs/" .. gameName
    
    -- Ensure config folder exists
    pcall(function()
        if not isfolder("Lynx") then makefolder("Lynx") end
        if not isfolder("Lynx/Configs") then makefolder("Lynx/Configs") end
        if not isfolder(configFolder) then makefolder(configFolder) end
    end)
    
    -- Function to get list of saved configs
    local function GetSavedConfigs()
        local configs = {}
        pcall(function()
            if isfolder and listfiles and isfolder(configFolder) then
                local files = listfiles(configFolder)
                for _, file in ipairs(files) do
                    local name = file:match("([^/\\]+)%.json$")
                    if name then
                        table.insert(configs, name)
                    end
                end
            end
        end)
        if #configs == 0 then
            table.insert(configs, "No configs saved")
        end
        return configs
    end
    
    -- Variables for config management
    local customConfigName = ""
    local selectedConfig = ""
    local configDropdown = nil
    
    -- Auto-save control
    if _G.AutoSaveEnabled == nil then
        _G.AutoSaveEnabled = true
    end
    
    ConfigSection:AddToggle({
        Title = "Auto Save Enabled",
        Default = true,
        NoSave = true,
        Callback = function(on)
            _G.AutoSaveEnabled = on
            if Lynx and Lynx.MakeNotify then
                Lynx:MakeNotify({
                    Title = "Config",
                    Description = on and "Auto-save enabled" or "Auto-save disabled",
                    Content = on and "Settings akan disimpan otomatis." or "Settings TIDAK akan disimpan otomatis.",
                    Color = on and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 165, 0),
                    Delay = 3
                })
            end
        end
    })
    
    -- Input for custom config name
    ConfigSection:AddInput({
        Title = "Config Name",
        Default = "",
        Placeholder = "Enter config name...",
        Callback = function(value)
            customConfigName = value:gsub("[^%w_ ]", ""):gsub("%s+", "_")
        end
    })
    
    -- Save config with custom name
    ConfigSection:AddButton({
        Title = "Save Config",
        Callback = function()
            if customConfigName == "" then
                if Lynx and Lynx.MakeNotify then
                    Lynx:MakeNotify({
                        Title = "Config",
                        Description = "Error",
                        Content = "Masukkan nama config terlebih dahulu!",
                        Color = Color3.fromRGB(255, 100, 100),
                        Delay = 3
                    })
                end
                return
            end
            
            pcall(function()
                if writefile then
                    local filePath = configFolder .. "/" .. customConfigName .. ".json"
                    local fullConfig = (_G.GetFullConfig and _G.GetFullConfig()) or {}
                    fullConfig._version = CURRENT_VERSION
                    writefile(filePath, HttpService:JSONEncode(fullConfig))
                    
                    if Lynx and Lynx.MakeNotify then
                        Lynx:MakeNotify({
                            Title = "Config",
                            Description = "Saved!",
                            Content = "Config '" .. customConfigName .. "' berhasil disimpan!",
                            Color = Color3.fromRGB(0, 255, 100),
                            Delay = 3
                        })
                    end
                    
                    -- Update dropdown options
                    if configDropdown and configDropdown.SetOptions then
                        configDropdown:SetOptions(GetSavedConfigs())
                    end
                end
            end)
        end
    })
    
    -- Divider/Separator
    ConfigSection:AddParagraph({
        Title = "Load/Delete Config",
        Content = "Pilih config dari dropdown lalu klik Load atau Delete"
    })
    
    -- Dropdown to select config
    configDropdown = ConfigSection:AddDropdown({
        Title = "Select Config",
        Options = GetSavedConfigs(),
        Default = "",
        NoSave = true,
        Callback = function(value)
            if value ~= "No configs saved" then
                selectedConfig = value
            else
                selectedConfig = ""
            end
        end
    })
    
    -- Load selected config
    ConfigSection:AddButton({
        Title = "Load Config",
        Callback = function()
            if selectedConfig == "" then
                if Lynx and Lynx.MakeNotify then
                    Lynx:MakeNotify({
                        Title = "Config",
                        Description = "Error",
                        Content = "Pilih config dari dropdown terlebih dahulu!",
                        Color = Color3.fromRGB(255, 100, 100),
                        Delay = 3
                    })
                end
                return
            end
            
            pcall(function()
                local filePath = configFolder .. "/" .. selectedConfig .. ".json"
                if isfile and readfile and isfile(filePath) then
                    local success, data = pcall(function()
                        return HttpService:JSONDecode(readfile(filePath))
                    end)
                    
                    if success and type(data) == "table" then
                        -- Update ConfigData (Legacy support)
                        for k, v in pairs(data) do
                            ConfigData[k] = v
                        end

                        -- Update UI via Library
                        if Window and Window.LoadConfig then
                            Window:LoadConfig(data)
                        end
                        
                        if Lynx and Lynx.MakeNotify then
                            Lynx:MakeNotify({
                                Title = "Config",
                                Description = "Loaded!",
                                Content = "Config '" .. selectedConfig .. "' berhasil dimuat! Beberapa setting mungkin perlu rejoin.",
                                Color = Color3.fromRGB(0, 200, 255),
                                Delay = 4
                            })
                        end
                    else
                        if Lynx and Lynx.MakeNotify then
                            Lynx:MakeNotify({
                                Title = "Config",
                                Description = "Error",
                                Content = "Gagal memuat config. File mungkin corrupt.",
                                Color = Color3.fromRGB(255, 100, 100),
                                Delay = 3
                            })
                        end
                    end
                else
                    if Lynx and Lynx.MakeNotify then
                        Lynx:MakeNotify({
                            Title = "Config",
                            Description = "Error",
                            Content = "Config file tidak ditemukan!",
                            Color = Color3.fromRGB(255, 100, 100),
                            Delay = 3
                        })
                    end
                end
            end)
        end
    })
    
    -- Delete selected config
    ConfigSection:AddButton({
        Title = "Delete Config",
        Callback = function()
            if selectedConfig == "" then
                if Lynx and Lynx.MakeNotify then
                    Lynx:MakeNotify({
                        Title = "Config",
                        Description = "Error",
                        Content = "Pilih config dari dropdown terlebih dahulu!",
                        Color = Color3.fromRGB(255, 100, 100),
                        Delay = 3
                    })
                end
                return
            end
            
            pcall(function()
                local filePath = configFolder .. "/" .. selectedConfig .. ".json"
                if isfile and delfile and isfile(filePath) then
                    delfile(filePath)
                    
                    if Lynx and Lynx.MakeNotify then
                        Lynx:MakeNotify({
                            Title = "Config",
                            Description = "Deleted!",
                            Content = "Config '" .. selectedConfig .. "' berhasil dihapus!",
                            Color = Color3.fromRGB(255, 200, 0),
                            Delay = 3
                        })
                    end
                    
                    selectedConfig = ""
                    
                    -- Update dropdown options
                    if configDropdown and configDropdown.SetOptions then
                        configDropdown:SetOptions(GetSavedConfigs())
                    end
                else
                    if Lynx and Lynx.MakeNotify then
                        Lynx:MakeNotify({
                            Title = "Config",
                            Description = "Error",
                            Content = "Config file tidak ditemukan!",
                            Color = Color3.fromRGB(255, 100, 100),
                            Delay = 3
                        })
                    end
                end
            end)
        end
    })
    
    -- Refresh configs list button
    ConfigSection:AddButton({
        Title = "Refresh List",
        Callback = function()
            if configDropdown and configDropdown.SetOptions then
                configDropdown:SetOptions(GetSavedConfigs())
                if Lynx and Lynx.MakeNotify then
                    Lynx:MakeNotify({
                        Title = "Config",
                        Description = "Refreshed!",
                        Content = "Daftar config berhasil di-refresh.",
                        Color = Color3.fromRGB(100, 200, 255),
                        Delay = 2
                    })
                end
            end
        end
    })
    
    -- Reset current settings to default
    ConfigSection:AddButton({
        Title = "Reset Current Settings",
        Callback = function()
            pcall(function()
                -- Use the global ResetToDefaults function from Library
                if ResetToDefaults then
                    ResetToDefaults()
                end
                
                -- Stop all active modules
                if CombinedModules and CombinedModules.CleanupAllModules then
                    pcall(function()
                        CombinedModules.CleanupAllModules()
                    end)
                end
                
                if Lynx and Lynx.MakeNotify then
                    Lynx:MakeNotify({
                        Title = "Config",
                        Description = "Reset!",
                        Content = "Semua setting telah direset ke default.",
                        Color = Color3.fromRGB(255, 200, 0),
                        Delay = 4
                    })
                end
            end)
        end
    })

      -- ══════════════════════════════════════════
    -- TAB: ABOUT
    -- ══════════════════════════════════════════
    local AboutTab = Window:AddTab({Name = "About", Icon = "player"})
    
    local InfoSection = AboutTab:AddSection("About Lynx", true)
    
    InfoSection:AddParagraph({
        Title = "Lynx Discord",
        Content = "Official link discord Lynx!"
    })
    
    InfoSection:AddButton({
        Title = "COPY LINK DISCORD",
        Callback = function()
            pcall(function()
                if setclipboard then
                    setclipboard("https://discord.gg/lynxx")
                end
            end)
        end
    })

    -- GUI Built
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CLEANUP HOOK - Monitor GUI destroy using AncestryChanged
    -- ═══════════════════════════════════════════════════════════════════════════
    task.spawn(function()
        local LynxGui = CoreGui:WaitForChild("LynxGui", 5)
        if LynxGui then
            LynxGui.AncestryChanged:Connect(function(_, parent)
                if parent == nil then
                    -- GUI sedang di-destroy, jalankan cleanup
                    CombinedModules.CleanupAllModules()
                end
            end)
        end
    end)
    
    return Window
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CLEANUP ALL MODULES - Menghentikan semua module yang aktif
-- ═══════════════════════════════════════════════════════════════════════════
CombinedModules.CleanupAllModules = function()
    -- List SEMUA modules yang ada di CombinedModules
    local allModules = {
        -- Fishing Modules
        "legit",
        "InstantV1",
        "StableResult",
        "blatantV1",
        "blatantV2",
        
        -- Support Features
        "NoFishingAnimation",
        "AutoEquipRod",
        "LockPosition",
        "DisableCutscenes",
        "PingPanel",
        "DisableExtras",
        "WalkOnWater",
        "SkinSwapAnimation",
        "StuckDetector",
        
        -- Auto Features
        "AutoTotem3X",
        "AutoFavorite",
        "AutoSpawnTotem",
        "AutoEnchant",
        "AutoEvent",
        "AutoSellSystem",
        "AutoBuyWeather",
        "AutoTrade",
        "AutoAcceptTrade",
        
        -- Merchant & Economy
        "MerchantSystem",
        "BuyCharm",
        
        -- Teleport & Navigation
        "TeleportToPlayer",
        "SavedLocation",
        
        -- Webhook & Protection
        "Webhook",
        "AntiAFK",
        "AntiStaff",
        
        -- Performance & Visual
        "PotatoMode",
        "DisableRendering",
        "UnlockFPS",
        "HideStats",
        "FreecamModule",
        "UnlimitedZoom",
        "MovementModule",
    }
    
    -- Universal cleanup: coba semua metode Stop/Disable/Hide untuk setiap module
    for _, moduleName in ipairs(allModules) do
        pcall(function()
            local mod = CombinedModules[moduleName]
            if not mod or type(mod) ~= "table" then return end
            
            -- Coba .Stop() (paling umum)
            if type(mod.Stop) == "function" then
                pcall(mod.Stop)
            end
            
            -- Coba .Disable()
            if type(mod.Disable) == "function" then
                pcall(mod.Disable)
            end
            
            -- Coba :Hide() (untuk PingPanel, dll)
            if type(mod.Hide) == "function" then
                pcall(function() mod:Hide() end)
            end
            
            -- Handle nested sub-modules (AutoSellSystem.Timer, AutoSellSystem.Count, dll)
            if type(mod.Timer) == "table" and type(mod.Timer.Stop) == "function" then
                pcall(mod.Timer.Stop)
            end
            if type(mod.Count) == "table" and type(mod.Count.Stop) == "function" then
                pcall(mod.Count.Stop)
            end
        end)
    end
    
    -- Special cleanup: FreecamModule keybind
    pcall(function()
        if CombinedModules.FreecamModule then
            if CombinedModules.FreecamModule.EnableF3Keybind then
                CombinedModules.FreecamModule.EnableF3Keybind(false)
            end
        end
    end)
    
    -- Special cleanup: AutoReconnect (uses : method syntax)
    pcall(function()
        if CombinedModules.AutoReconnect then
            CombinedModules.AutoReconnect:DisableAutoExecute()
            CombinedModules.AutoReconnect:Disable()
        end
    end)
    
    -- Cleanup global fishing scripts
    pcall(function()
        if _G.FishingScriptFast then
            _G.FishingScriptFast.Stop()
            _G.FishingScriptFast = nil
        end
    end)
    
    pcall(function()
        if _G.FishingScript then
            _G.FishingScript.Stop()
            _G.FishingScript = nil
        end
    end)
    
    -- Clear NetEvents & shared refs
    pcall(function()
        _G.NetEvents = nil
        _G.SharedCharacter = nil
        _G.SharedHumanoid = nil
    end)

end

-- Register global cleanup: langsung setelah CleanupAllModules didefinisikan
-- Supaya _G.LynxCleanup selalu tersedia dari awal, bukan hanya setelah cleanup dipanggil
_G.LynxCleanup = function()
    pcall(function()
        if CombinedModules.CleanupAllModules then
            CombinedModules.CleanupAllModules()
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- BUILD GUI OTOMATIS
-- ═══════════════════════════════════════════════════════════════════════════
if Lynx then
    CombinedModules.BuildGUI(Lynx)
end

return CombinedModules
