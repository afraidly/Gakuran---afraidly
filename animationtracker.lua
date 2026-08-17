local HttpService = game:GetService("HttpService")
local offsets

for _, url in ipairs({"https://offsets.imtheo.lol/Offsets.json", "https://artxficial.dev/misc/theo"}) do
    local success, result = pcall(function()
        local data = HttpService:JSONDecode(game:HttpGet(url))
        return data.Offsets or data
    end)

    if success and type(result) == "table" and next(result) then
        print("[DEBUG] Successfully using offsets from: " .. url)
        offsets = result
        break
    end
end

offsets = offsets or (print("[DEBUG] Both endpoints failed. Defaulting to empty table.") or {})

local KnownOffsets = {
    ["AnimationId"] = offsets.Misc.AnimationId,
    ["ClassDescriptor"] = offsets.Instance.ClassDescriptor,
    ["ClassDescriptorToClassName"] = offsets.Instance.ClassName,
    ["Name"] = offsets.Instance.Name,
    ["TimePosition"] = offsets.AnimationTrack.TimePosition,
    ["ActiveAnimations"] = offsets.Animator.ActiveAnimations,
    ["Animation"] = offsets.AnimationTrack.Animation,
    ["Speed"] = offsets.AnimationTrack.Speed,
    ["IsPlaying"] = offsets.AnimationTrack.IsPlaying,
    ["NodeNext"] = 0x10,
}

local function GetAnimatorAddress(Character)
    if not Character or Character.Address == 0 then return nil end
    local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
    if not Humanoid then return nil end
    local Animator = Humanoid:FindFirstChildWhichIsA("Animator")
    return Animator and Animator.Address or nil
end

local function GetPlayingAnimationTracks(Character)
    local AnimatorAddress = GetAnimatorAddress(Character)
    if not AnimatorAddress then return nil end

    local ListHead_Ptr = memory_read("uintptr_t", AnimatorAddress + KnownOffsets.ActiveAnimations)
    if not ListHead_Ptr or ListHead_Ptr == 0 then return nil end

    local firstNode = memory_read("uintptr_t", ListHead_Ptr)
    if not firstNode or firstNode == 0 or firstNode == ListHead_Ptr then return {} end

    local AnimationTracks = {}
    local currentNode = firstNode
    local foundCount = 0

    while currentNode and currentNode ~= 0 and currentNode ~= ListHead_Ptr do
        local track = memory_read("uintptr_t", currentNode + KnownOffsets.NodeNext)
        if track then
            foundCount = foundCount + 1
            AnimationTracks[foundCount] = track
        end
        if foundCount >= 50 then break end
        local nextNode = memory_read("uintptr_t", currentNode)
        if nextNode == ListHead_Ptr then break
        elseif nextNode == 0 or not nextNode then break
        end
        currentNode = nextNode
    end

    return AnimationTracks
end

local function GetTimePosition(AnimationTrackAddress)
    if not AnimationTrackAddress or AnimationTrackAddress == 0 then return nil end
    return memory_read("float", AnimationTrackAddress + KnownOffsets.TimePosition)
end

local function ExtractAnimationTrackInfo(AnimationTrackAddress)
    if not AnimationTrackAddress or AnimationTrackAddress == 0 then return nil end

    local Animation = memory_read("uintptr_t", AnimationTrackAddress + KnownOffsets.Animation)
    local AnimationIdPointer = memory_read("uintptr_t", Animation + KnownOffsets.AnimationId)
    local AnimationId = memory_read("string", AnimationIdPointer)

    local NamePtr = memory_read("uintptr_t", AnimationTrackAddress + KnownOffsets.Name)
    local Name = memory_read("string", NamePtr)
    local TimePosition = memory_read("float", AnimationTrackAddress + KnownOffsets.TimePosition)
    local Speed = memory_read("float", AnimationTrackAddress + KnownOffsets.Speed)
    local IsPlaying = memory_read("byte", AnimationTrackAddress + KnownOffsets.IsPlaying)

    return {
        Address = AnimationTrackAddress,
        Name = Name,
        AnimationId = AnimationId,
        TimePosition = TimePosition,
        Speed = Speed,
        IsPlaying = IsPlaying,
    }
end

local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({ _listeners = {} }, Signal)
end

function Signal:Connect(callback)
    table.insert(self._listeners, callback)
    return {
        Disconnect = function()
            for i = 1, #self._listeners do
                if self._listeners[i] == callback then
                    table.remove(self._listeners, i)
                    break
                end
            end
        end,
    }
end

function Signal:Fire(...)
    for i = 1, #self._listeners do
        self._listeners[i](...)
    end
end

local AnimationTracker = {}
AnimationTracker.__index = AnimationTracker

function AnimationTracker.new(IgnoreIds)
    local self = setmetatable({}, AnimationTracker)
    self.AnimationAdded = Signal.new()
    self.AnimationUpdated = Signal.new()
    self.AnimationRemoved = Signal.new()
    self.IgnoreIds = IgnoreIds or {}
    self._cachedTracks = {}
    return self
end

function AnimationTracker:Update(character)
    local tracksPlaying = GetPlayingAnimationTracks(character)
    if not tracksPlaying then return {} end

    local currentAddresses = {}
    local activeSnapshot = {}

    for i = 1, #tracksPlaying do
        local address = tracksPlaying[i]
        currentAddresses[address] = true

        local info = self._cachedTracks[address]
        local newlyExtracted = false

        if not info then
            info = ExtractAnimationTrackInfo(address)
            if info then
                self._cachedTracks[address] = info
                newlyExtracted = true
            end
        end

        if info then
            local assetId = info.AnimationId
            local numericId = assetId and tonumber(string.match(tostring(assetId), "%d+"))
            if numericId and table.find(self.IgnoreIds, numericId) then continue end

            if newlyExtracted then
                self.AnimationAdded:Fire(info)
            end

            local liveTime = GetTimePosition(address) or info.TimePosition
            info.TimePosition = liveTime
            self.AnimationUpdated:Fire(info, liveTime)
            table.insert(activeSnapshot, info)
        end
    end

    for address, cachedInfo in pairs(self._cachedTracks) do
        if not currentAddresses[address] then
            self.AnimationRemoved:Fire(cachedInfo)
            self._cachedTracks[address] = nil
        end
    end

    return activeSnapshot
end

print("[AnimationTracker] Functions were imported v1.1")

_G.AnimationTracker = AnimationTracker
return AnimationTracker
