local library

if isfile("library.lua") then
    library = loadstring(readfile("library.lua"))()
else
    library = loadstring(game:HttpGet("https://raw.githubusercontent.com/tingoman/atlgg/refs/heads/main/library.lua"))()
end

local flags         = library.flags
local themes        = library.themes
local visible_flags = library.visible_flags
local run           = library.run
local uis           = library.uis
local players       = library.players
local ws            = library.ws
local camera        = library.camera
local lp            = library.lp
local tween_service = library.tween_service
local vec2          = library.vec2

getgenv().amethyst = {
    ['Aimbot'] = {
        ['Enabled']      = false,
        ['FOV']          = 0,
        ['FOVType']      = 'Circle',
        ['FOVBox']       = {2.4, 4.6},
        ['PreciseMouse'] = false,
        ['Easing']       = 'Linear',
        ['Smoothness']   = 0.5,
        ['Hitbox']        = { 'Head' },
        ['Multipoint']  = 50,
        ['Method']       = 'Camera',
    },
    ['Triggerbot'] = {
        ['Enabled']     = false,
        ['RequireTool'] = true,
        ['HoldTime']    = 0,
        ['Cooldown']    = 0,
        ['Hitbox']      = { 'Head' },
    },
    ['ABChecks'] = {
        ['IgnoreDead']      = false,
        ['CheckTeam']       = false,
        ['CheckForceField'] = false,
        ['WallCheck']       = false,
    },
    ['TBChecks'] = {
        ['IgnoreDead']      = false,
        ['CheckTeam']       = false,
        ['CheckForceField'] = false,
        ['WallCheck']       = false,
    },
    ['HCAbChecks'] = {
        ['IgnoreDead']      = false,
        ['IgnoreGrabbed']   = false,
        ['CheckForceField'] = false,
        ['WallCheck']       = false,
    },
    ['HCSaChecks'] = {
        ['IgnoreDead']      = false,
        ['IgnoreGrabbed']   = false,
        ['CheckForceField'] = false,
        ['WallCheck']       = false,
    },
    ['HCTbChecks'] = {
        ['IgnoreDead']      = false,
        ['IgnoreGrabbed']   = false,
        ['CheckForceField'] = false,
        ['WallCheck']       = false,
    },
}




local R6_PARTS = {
    Head  = { 'Head' },
    Torso = { 'Torso', 'HumanoidRootPart' },
    Arms  = { 'Left Arm', 'Right Arm' },
    Legs  = { 'Left Leg', 'Right Leg' },
}

local R15_PARTS = {
    Head  = { 'Head' },
    Torso = { 'UpperTorso', 'LowerTorso', 'HumanoidRootPart' },
    Arms  = { 'LeftUpperArm', 'LeftLowerArm', 'LeftHand', 'RightUpperArm', 'RightLowerArm', 'RightHand' },
    Legs  = { 'LeftUpperLeg', 'LeftLowerLeg', 'LeftFoot', 'RightUpperLeg', 'RightLowerLeg', 'RightFoot' },
}


local WS_PARTS = {
    Head  = { 'Head', 'Top', 'TPVBodyVanillaHead', 'Hitbox' },
    Torso = { 'Torso', 'UpperTorso', 'LowerTorso', 'Abdomen', 'Center', 'HumanoidRootPart' },
    Arms  = { 'Left Arm', 'Right Arm', 'LeftUpperArm', 'LeftLowerArm', 'LeftHand',
              'RightUpperArm', 'RightLowerArm', 'RightHand' },
    Legs  = { 'Left Leg', 'Right Leg', 'LeftUpperLeg', 'LeftLowerLeg', 'LeftFoot',
              'RightUpperLeg', 'RightLowerLeg', 'RightFoot' },
}

local function detect_rig(character)
    if character:FindFirstChild('UpperTorso') then return R15_PARTS
    elseif character:FindFirstChild('Torso')  then return R6_PARTS
    else                                           return WS_PARTS end
end


local function get_hitbox_part_names(character, groups)
    local rig   = detect_rig(character)
    local names = {}
    for _, group in ipairs(groups) do
        local parts = rig[group]
        if parts then
            for _, n in ipairs(parts) do names[n] = true end
        end
    end
    return names
end


local function get_hitbox_parts(character, groups)
    local allowed = get_hitbox_part_names(character, groups)
    local result  = {}
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA('BasePart') and allowed[part.Name] then
            table.insert(result, part)
        end
    end
    return result
end


local function get_closest_part_to_cursor(character, groups)
    local mouse              = uis:GetMouseLocation()
    local closest, min_dist  = nil, math.huge
    for _, part in ipairs(get_hitbox_parts(character, groups)) do
        if part.Transparency < 0.5 then
            local sp = camera:WorldToViewportPoint(part.Position)
            local d  = (vec2(sp.X, sp.Y) - mouse).Magnitude
            if d < min_dist then min_dist = d closest = part end
        end
    end
    return closest
end

local function get_closest_point_on_part(part, scale)
    if scale <= 0 then return part.Position end
    local cf   = part.CFrame
    local half = part.Size * (scale * 0.5)
    local mouse = uis:GetMouseLocation()
    local ray   = camera:ViewportPointToRay(mouse.X, mouse.Y)
    local local_pt = cf:PointToObjectSpace(ray.Origin + ray.Direction * ray.Direction:Dot(cf.Position - ray.Origin))
    return cf * Vector3.new(
        math.clamp(local_pt.X, -half.X, half.X),
        math.clamp(local_pt.Y, -half.Y, half.Y),
        math.clamp(local_pt.Z, -half.Z, half.Z)
    )
end

local MarketplaceService = game:GetService("MarketplaceService")
local GameProductInfo    = MarketplaceService:GetProductInfo(game.PlaceId)
local GameInformation    = {}
setmetatable(GameInformation, {
    __index = function(_, Key)
        Key = tostring(Key):lower()
        if Key == "name" then
            return GameProductInfo.Name
        elseif Key == "id" or Key == "identification" then
            return game.PlaceId
        elseif Key == "description" or Key == "desc" then
            return GameProductInfo.Description
        elseif Key == "created" then
            return GameProductInfo.Created
        elseif Key == "lastupdatedate" or Key == "lastupdated" then
            return GameProductInfo.Updated
        elseif Key == "isnew" then
            return GameProductInfo.IsNew
        elseif Key == "creator" then
            local Creator = {}
            setmetatable(Creator, {
                __index = function(_, K)
                    K = tostring(K):lower()
                    if K == "name" then
                        return GameProductInfo.Creator.Name
                    elseif K == "id" or K == "identification" then
                        return GameProductInfo.Creator.Id
                    elseif K == "type" then
                        return GameProductInfo.Creator.CreatorType
                    elseif K == "isverified" or K == "hasverifiedbadge" then
                        return GameProductInfo.Creator.HasVerifiedBadge
                    end
                end
            })
            table.freeze(Creator)
            return Creator
        end
    end
})
table.freeze(GameInformation)

local game_name       = GameInformation.name:lower()
local is_hood_customs = game_name:find("hood customs") ~= nil
library.supported_games[game.PlaceId] = GameInformation.name

local window = library:window({ name = os.date("amethyst | %b %d %Y"), size = UDim2.new(0, 750, 0, 530) })

local esp_preview_obj = nil
local hc_sa_gui       = nil
local sa_target       = nil
local sa_can_shoot    = false
local function esp_refresh() if esp_preview_obj and esp_preview_obj.refresh_elements then esp_preview_obj.refresh_elements() end end

local function build_esp_ui(section)
    section:toggle({ name = "Enabled",   flag = "Enabled",      default = false, callback = esp_refresh })
    section:toggle({ name = "Names",     flag = "Names",        default = true,  callback = esp_refresh })
    :colorpicker({ name = "Color", flag = "Name_Color", color = Color3.fromRGB(255, 255, 255), callback = esp_refresh })
    local box_tog = section:toggle({ name = "Boxes", flag = "Boxes", default = true, callback = esp_refresh })
    section:dropdown({ name = "Box Type", flag = "Box_Type", items = { "Corner", "Full" }, default = "Corner", callback = esp_refresh })
    box_tog:colorpicker({ name = "Color", flag = "Box_Color", color = Color3.fromRGB(255, 255, 255), callback = esp_refresh })
    section:toggle({ name = "Healthbar", flag = "Healthbar", default = true, callback = esp_refresh })
    :colorpicker({ name = "High HP", flag = "Health_High", color = Color3.fromRGB(0, 255, 0), callback = esp_refresh })
    :colorpicker({ name = "Low HP",  flag = "Health_Low",  color = Color3.fromRGB(255, 0, 0), callback = esp_refresh })
    section:toggle({ name = "Distance",  flag = "Distance",  default = true, callback = esp_refresh })
    :colorpicker({ name = "Color", flag = "Distance_Color", color = Color3.fromRGB(255, 255, 255), callback = esp_refresh })
    section:toggle({ name = "Weapon",    flag = "Weapon",    default = false, callback = esp_refresh })
    :colorpicker({ name = "Color", flag = "Weapon_Color", color = Color3.fromRGB(255, 255, 255), callback = esp_refresh })
    section:dropdown({ name = "Show", flag = "esp_show", items = { "Enemy", "Priority", "Neutral", "Friendly" }, multi = true, default = { "Enemy", "Priority", "Neutral", "Friendly" }, callback = esp_refresh })
    section:colorpicker({ name = "Enemy Color",    flag = "esp_enemy_color",    color = Color3.fromRGB(255, 0, 0),   callback = esp_refresh })
    section:colorpicker({ name = "Friendly Color", flag = "esp_friendly_color", color = Color3.fromRGB(0, 255, 255), callback = esp_refresh })
end

if is_hood_customs then
    shared.Saved = {
        ['Silent Aim'] = {
            ['Enabled']       = true,
            ['Acquisition']   = 'Always',
            ['Client Bullet'] = false,
            ['FOV'] = {
                ['Enabled']      = true,
                ['Visible']      = true,
                ['Type']         = 'Box',
                ['Size']         = 150,
                ['Box']          = {2.4, 4.6},
                ['Color']        = Color3.fromRGB(255, 255, 255),
                ['FocusedColor'] = Color3.fromRGB(255, 0, 0),
            },
            ['Multipoint'] = 50,
            ['Camera'] = {
                ['Closest Point'] = { ['Mode'] = 'Advanced', ['Scale'] = 0.6 },
            },
            ['Distance'] = { ['Enabled'] = false },
            ['Spread']   = { ['Enabled'] = true, ['MaxDistance'] = 200, ['Factor'] = 0.8, ['DistanceScale'] = 0.5, ['ShotgunSpread'] = 100 },
            ['Tracer']   = { ['Enabled'] = false, ['Visible'] = true, ['Thickness'] = 1, ['Outline'] = { ['Enabled'] = true, ['Color'] = Color3.fromRGB(0, 0, 0), ['Thickness'] = 1 } },
        },
        ['Triggerbot'] = {
            ['Enabled']  = false,
            ['FOV Type'] = 'Hitbox',
            ['Keybind']  = 'Q',
            ['HoldTime'] = 0,
            ['Cooldown'] = 0.15,
        },
    }
    local hc_silent = shared.Saved['Silent Aim']
    local hc_tb     = shared.Saved['Triggerbot']

    local Legitbot = window:tab({ name = "Legitbot" })
    local VIS      = window:tab({ name = "Visuals" })

    local col = Legitbot:column()
    local ab, sil = col:multi_section({ names = { "Aimbot", "Silent Aim" } })

    local function ab_fov_vis(v)
        local box = v == "Box"
        if visible_flags['ab_fov']   then visible_flags['ab_fov'](not box)   end
        if visible_flags['ab_fov_w'] then visible_flags['ab_fov_w'](box) end
        if visible_flags['ab_fov_h'] then visible_flags['ab_fov_h'](box) end
    end

    ab:toggle({ name = "Enabled", flag = "ab_enabled", default = amethyst['Aimbot']['Enabled'], callback = function(v) amethyst['Aimbot']['Enabled'] = v end }):keybind({ flag = "ab_key", mode = "hold", name = "Aimbot" })
    ab:dropdown({ name = "Method", flag = "ab_method", items = { "Camera", "Mouse" }, default = amethyst['Aimbot']['Method'], callback = function(v) amethyst['Aimbot']['Method'] = v end })
    ab:dropdown({ name = "FOV Type", flag = "ab_fov_type", items = { "Circle", "Box" }, default = amethyst['Aimbot']['FOVType'], callback = function(v) amethyst['Aimbot']['FOVType'] = v ab_fov_vis(v) end })
    ab:slider({ name = "FOV", flag = "ab_fov", min = 1, max = 800, default = amethyst['Aimbot']['FOV'], interval = 1, callback = function(v) amethyst['Aimbot']['FOV'] = v end })
    ab:slider({ name = "FOV Width", flag = "ab_fov_w", min = 0.1, max = 10, default = amethyst['Aimbot']['FOVBox'][1], interval = 0.1, callback = function(v) amethyst['Aimbot']['FOVBox'][1] = v end })
    ab:slider({ name = "FOV Height", flag = "ab_fov_h", min = 0.1, max = 10, default = amethyst['Aimbot']['FOVBox'][2], interval = 0.1, callback = function(v) amethyst['Aimbot']['FOVBox'][2] = v end })
    ab:slider({ name = "Smoothness", flag = "ab_smooth", min = 0.01, max = 1, default = amethyst['Aimbot']['Smoothness'], interval = 0.01, callback = function(v) amethyst['Aimbot']['Smoothness'] = v end })
    ab:dropdown({ name = "Easing", flag = "ab_easing", items = { "Linear", "Quad", "Cubic", "Circular", "Sine", "Bounce", "Elastic" }, default = amethyst['Aimbot']['Easing'], callback = function(v) amethyst['Aimbot']['Easing'] = v end })
    ab:toggle({ name = "Precise Mouse", flag = "ab_precise", default = amethyst['Aimbot']['PreciseMouse'], callback = function(v) amethyst['Aimbot']['PreciseMouse'] = v end })
    ab:dropdown({ name = "Hitbox", flag = "ab_hitbox", items = { "Head", "Torso", "Arms", "Legs" }, multi = true, default = amethyst['Aimbot']['Hitbox'], callback = function(v) amethyst['Aimbot']['Hitbox'] = v end })
    ab:slider({ name = "Multipoint", flag = "ab_closest_point", min = 0, max = 100, default = amethyst['Aimbot']['Multipoint'], interval = 1, suffix = "%", callback = function(v) amethyst['Aimbot']['Multipoint'] = v end })
    ab:dropdown({ name = "Filters", flag = "hc_ab_filters", items = { "Ignore Dead", "Ignore Grabbed", "Check FF", "Wall Check" }, multi = true, default = {}, callback = function(v)
        local ch = amethyst['HCAbChecks']
        ch['IgnoreDead'] = false ch['IgnoreGrabbed'] = false ch['CheckForceField'] = false ch['WallCheck'] = false
        for _, s in ipairs(v) do
            if s == "Ignore Dead" then ch['IgnoreDead'] = true
            elseif s == "Ignore Grabbed" then ch['IgnoreGrabbed'] = true
            elseif s == "Check FF" then ch['CheckForceField'] = true
            elseif s == "Wall Check" then ch['WallCheck'] = true end
        end
    end })
    ab_fov_vis(amethyst['Aimbot']['FOVType'])

    local function sa_fov_vis(v)
        local box = v == "Box"
        if visible_flags['hc_sa_fov_size'] then visible_flags['hc_sa_fov_size'](not box) end
        if visible_flags['hc_sa_fov_w']    then visible_flags['hc_sa_fov_w'](box)     end
        if visible_flags['hc_sa_fov_h']    then visible_flags['hc_sa_fov_h'](box)     end
    end

    sil:toggle({ name = "Enabled", flag = "hc_sa_enabled", default = hc_silent['Enabled'], callback = function(v) hc_silent['Enabled'] = v end }):keybind({ flag = "hc_sa_key", mode = "always", name = "Silent Aim" })
    sil:toggle({ name = "Client Bullet", flag = "hc_sa_client_bullet", default = hc_silent['Client Bullet'], callback = function(v) hc_silent['Client Bullet'] = v end })
    sil:toggle({ name = "FOV", flag = "hc_sa_fov", default = hc_silent['FOV']['Enabled'], callback = function(v) hc_silent['FOV']['Enabled'] = v end })
    sil:dropdown({ name = "FOV Type", flag = "hc_sa_fov_type", items = { "Circle", "Box" }, default = hc_silent['FOV']['Type'], callback = function(v) hc_silent['FOV']['Type'] = v sa_fov_vis(v) end })
    sil:slider({ name = "Size", flag = "hc_sa_fov_size", min = 1, max = 800, default = hc_silent['FOV']['Size'], interval = 1, callback = function(v) hc_silent['FOV']['Size'] = v end })
    sil:slider({ name = "Width", flag = "hc_sa_fov_w", min = 0.1, max = 10, default = hc_silent['FOV']['Box'][1], interval = 0.1, callback = function(v) hc_silent['FOV']['Box'][1] = v end })
    sil:slider({ name = "Height", flag = "hc_sa_fov_h", min = 0.1, max = 10, default = hc_silent['FOV']['Box'][2], interval = 0.1, callback = function(v) hc_silent['FOV']['Box'][2] = v end })
    sa_fov_vis(hc_silent['FOV']['Type'])
    sil:slider({ name = "Multipoint", flag = "hc_sa_closest_point", min = 0, max = 100, default = hc_silent['Multipoint'], interval = 1, suffix = "%", callback = function(v) hc_silent['Multipoint'] = v end })
    sil:slider({ name = "Shotgun Spread", flag = "hc_sa_shotgun_spread", min = 0, max = 100, default = hc_silent['Spread']['ShotgunSpread'], interval = 1, suffix = "%", callback = function(v) hc_silent['Spread']['ShotgunSpread'] = v end })
    sil:dropdown({ name = "Filters", flag = "hc_sa_filters", items = { "Ignore Dead", "Ignore Grabbed", "Check FF", "Wall Check" }, multi = true, default = {}, callback = function(v)
        local ch = amethyst['HCSaChecks']
        ch['IgnoreDead'] = false ch['IgnoreGrabbed'] = false ch['CheckForceField'] = false ch['WallCheck'] = false
        for _, s in ipairs(v) do
            if s == "Ignore Dead" then ch['IgnoreDead'] = true
            elseif s == "Ignore Grabbed" then ch['IgnoreGrabbed'] = true
            elseif s == "Check FF" then ch['CheckForceField'] = true
            elseif s == "Wall Check" then ch['WallCheck'] = true end
        end
    end })

    local col = Legitbot:column()
    local tb_sec = col:section({ name = "Triggerbot" })
    tb_sec:toggle({ name = "Enabled", flag = "hc_tb_enabled", default = hc_tb['Enabled'], callback = function(v) hc_tb['Enabled'] = v end }):keybind({ flag = "hc_tb_key", mode = "hold", name = "Triggerbot" })
    tb_sec:dropdown({ name = "FOV Type", flag = "hc_tb_fov_type", items = { "Hitbox", "Box" }, default = hc_tb['FOV Type'], callback = function(v) hc_tb['FOV Type'] = v end })
    tb_sec:slider({ name = "Hold Time", flag = "hc_tb_hold", min = 0, max = 500, default = hc_tb['HoldTime'] * 1000, interval = 10, suffix = "ms", callback = function(v) hc_tb['HoldTime'] = v / 1000 end })
    tb_sec:slider({ name = "Cooldown", flag = "hc_tb_cooldown", min = 0, max = 1000, default = hc_tb['Cooldown'] * 1000, interval = 10, suffix = "ms", callback = function(v) hc_tb['Cooldown'] = v / 1000 end })
    tb_sec:dropdown({ name = "Filters", flag = "hc_tb_filters", items = { "Ignore Dead", "Ignore Grabbed", "Check FF", "Wall Check" }, multi = true, default = {}, callback = function(v)
        local ch = amethyst['HCTbChecks']
        ch['IgnoreDead'] = false ch['IgnoreGrabbed'] = false ch['CheckForceField'] = false ch['WallCheck'] = false
        for _, s in ipairs(v) do
            if s == "Ignore Dead" then ch['IgnoreDead'] = true
            elseif s == "Ignore Grabbed" then ch['IgnoreGrabbed'] = true
            elseif s == "Check FF" then ch['CheckForceField'] = true
            elseif s == "Wall Check" then ch['WallCheck'] = true end
        end
    end })

    local col = VIS:column()
    local esp_sec, misc_sec = col:multi_section({ names = { "ESP", "Misc" } })

    build_esp_ui(esp_sec)
    if not esp_preview_obj then esp_preview_obj = window.esp_section:esp_preview({}) end
    esp_sec:toggle({ name = "Ignore Dead",    flag = "hc_esp_ignore_dead",    default = false })
    esp_sec:toggle({ name = "Ignore Grabbed", flag = "hc_esp_ignore_grabbed", default = false })
    esp_sec:toggle({ name = "Wall Check",     flag = "hc_esp_wallcheck",      default = false })

    misc_sec:toggle({ name = "Tracer", flag = "hc_tracer_enabled", default = hc_silent['Tracer']['Enabled'], callback = function(v) hc_silent['Tracer']['Enabled'] = v end })
    :colorpicker({ name = "Color", color = hc_silent['Tracer']['Outline']['Color'], flag = "hc_tracer_outline_color", callback = function(c) hc_silent['Tracer']['Outline']['Color'] = c end })
    misc_sec:slider({ name = "Thickness", flag = "hc_tracer_thickness", min = 1, max = 5, default = hc_silent['Tracer']['Thickness'], interval = 1, callback = function(v) hc_silent['Tracer']['Thickness'] = v end })
    misc_sec:toggle({ name = "Distance", flag = "hc_dist_enabled", default = hc_silent['Distance']['Enabled'], callback = function(v) hc_silent['Distance']['Enabled'] = v end })
    misc_sec:toggle({ name = "FOV", flag = "hc_fov_vis", default = hc_silent['FOV']['Visible'], callback = function(v) hc_silent['FOV']['Visible'] = v end })
    :colorpicker({ name = "Default", color = hc_silent['FOV']['Color'], flag = "hc_fov_color", callback = function(c) hc_silent['FOV']['Color'] = c end })
    :colorpicker({ name = "Focused", color = hc_silent['FOV']['FocusedColor'], flag = "hc_fov_focused", callback = function(c) hc_silent['FOV']['FocusedColor'] = c end })

    do
        local RepStore  = cloneref(game:GetService("ReplicatedStorage"))
        local sa_target_locked = false
        local sa_box_focused   = false
        local sa_last_hb_pos   = nil
        local sa_anti_kick     = false
        local sa_anti_kick_d   = 0
        local sa_rubberband    = false
        local sa_last_shot_pos = nil

        hc_sa_gui = Instance.new("ScreenGui")
        hc_sa_gui.IgnoreGuiInset = true
        hc_sa_gui.Parent = cloneref(game:GetService("CoreGui"))

        local fov_circle        = Instance.new("Frame")
        local fov_corner        = Instance.new("UICorner")
        local fov_stroke        = Instance.new("UIStroke")
        fov_circle.AnchorPoint            = Vector2.new(0.5, 0.5)
        fov_circle.BorderSizePixel        = 0
        fov_circle.BackgroundTransparency = 1
        fov_circle.Visible                = false
        fov_circle.Parent                 = hc_sa_gui
        fov_corner.CornerRadius = UDim.new(1, 0)
        fov_corner.Parent       = fov_circle
        fov_stroke.Thickness       = 1
        fov_stroke.Transparency    = 0.7
        fov_stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        fov_stroke.Parent          = fov_circle

        local fov_box        = Instance.new("Frame")
        local fov_box_stroke = Instance.new("UIStroke")
        fov_box.BorderSizePixel        = 0
        fov_box.BackgroundTransparency = 1
        fov_box.Visible                = false
        fov_box.Parent                 = hc_sa_gui
        fov_box_stroke.Thickness       = 1
        fov_box_stroke.LineJoinMode    = Enum.LineJoinMode.Miter
        fov_box_stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        fov_box_stroke.Parent          = fov_box

        local sa_tracer       = Instance.new("Frame")
        local sa_tracer_stroke = Instance.new("UIStroke")
        sa_tracer.AnchorPoint     = Vector2.one * 0.5
        sa_tracer.BorderSizePixel = 0
        sa_tracer.Visible         = false
        sa_tracer.Parent          = hc_sa_gui
        sa_tracer_stroke.Parent   = sa_tracer

        local dist_text = Instance.new("TextLabel")
        dist_text.AnchorPoint            = Vector2.new(0.5, 0.5)
        dist_text.BackgroundTransparency = 1
        dist_text.Font                   = Enum.Font.SourceSansBold
        dist_text.TextSize               = 16
        dist_text.TextColor3             = Color3.fromRGB(255, 255, 255)
        dist_text.TextStrokeTransparency = 0.5
        dist_text.Visible                = false
        dist_text.Parent                 = hc_sa_gui

        local Mouse = lp:GetMouse()

        local function sa_mpos() return uis:GetMouseLocation() end

        local function sa_raycast(part, origin, ignore)
            local dir = (part.Position - origin).Unit * 2000
            local hit = workspace:FindPartOnRayWithIgnoreList(Ray.new(origin, dir), ignore or {})
            return hit and hit:IsDescendantOf(part.Parent), hit
        end

        local function sa_is_knocked(char)
            local be = char and char:FindFirstChild("BodyEffects")
            return be and be:FindFirstChild("K.O") and be["K.O"].Value or false
        end
        local function sa_is_grabbed(char)   return char and char:FindFirstChild("GRABBING_CONSTRAINT") ~= nil end
        local function sa_has_ff(char)       return char and char:FindFirstChild("Forcefield") ~= nil end

        local function sa_check_antikick()
            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then sa_last_hb_pos = nil sa_anti_kick = false return end
            local cur = hrp.Position
            if not sa_last_hb_pos then sa_last_hb_pos = cur sa_anti_kick = false return end
            local d = (cur - sa_last_hb_pos).Magnitude
            sa_anti_kick_d = d
            sa_anti_kick   = d > 7
            sa_rubberband  = sa_anti_kick and d < 10
            sa_last_hb_pos = cur
        end

        local function sa_rubberband_tp()
            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if not hrp or not sa_last_hb_pos then return end
            hrp.CFrame      = CFrame.new(sa_last_hb_pos)
            sa_last_hb_pos  = hrp.Position
            sa_anti_kick    = false
            sa_rubberband   = false
        end

        local function sa_get_closest_to_cursor(char)
            local mouse = sa_mpos()
            local closest, min_d = nil, math.huge
            for _, part in ipairs(char:GetChildren()) do
                if not part:IsA("BasePart") then continue end
                local sp = camera:WorldToViewportPoint(part.Position)
                local d  = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                if d < min_d then min_d = d closest = part end
            end
            return closest
        end

        local function sa_get_closest_point_advanced(part, scale)
            local cf   = part.CFrame
            local half = part.Size * (scale / 2)
            local mpos = sa_mpos()
            local ray  = camera:ViewportPointToRay(mpos.X, mpos.Y)
            local transformed = cf:PointToObjectSpace(ray.Origin + ray.Direction * ray.Direction:Dot(cf.Position - ray.Origin))
            if Mouse.Target == part then return Vector3.new(Mouse.Hit.X, Mouse.Hit.Y, Mouse.Hit.Z) end
            return cf * Vector3.new(
                math.clamp(transformed.X, -half.X, half.X),
                math.clamp(transformed.Y, -half.Y, half.Y),
                math.clamp(transformed.Z, -half.Z, half.Z)
            )
        end

        local function sa_get_hit_pos()
            local char = sa_target and sa_target.Character
            if not char then return nil end
            local nearest = sa_get_closest_to_cursor(char)
            if not nearest then return nil end
            return sa_get_closest_point_advanced(nearest, hc_silent['Multipoint'] / 100)
        end

        local function sa_get_target()
            local fov   = hc_silent['FOV']
            local mouse = sa_mpos()
            local limit = fov['Enabled'] and fov['Size'] or math.huge
            local my_char = lp.Character
            local closest, min_d = nil, math.huge
            for _, player in ipairs(players:GetPlayers()) do
                if player == lp then continue end
                local char = player.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
                if amethyst['HCSaChecks']['CheckForceField'] and sa_has_ff(char) then continue end
                if amethyst['HCSaChecks']['IgnoreDead']    and sa_is_knocked(char) then continue end
                if amethyst['HCSaChecks']['IgnoreGrabbed'] and sa_is_grabbed(char) then continue end
                if amethyst['HCSaChecks']['IgnoreDead']    and sa_is_knocked(my_char) then continue end
                if amethyst['HCSaChecks']['IgnoreGrabbed'] and sa_is_grabbed(my_char) then continue end
                for _, part in ipairs(char:GetChildren()) do
                    if not part:IsA("BasePart") or part.Transparency >= 0.5 then continue end
                    local sp, on_screen = camera:WorldToViewportPoint(part.Position)
                    if not on_screen then continue end
                    local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                    if d >= limit then continue end
                    if not sa_raycast(part, camera.CFrame.Position, {my_char}) then continue end
                    if d < min_d then min_d = d closest = player end
                end
            end
            return closest
        end

        local hc_ray_params = RaycastParams.new()
        hc_ray_params.FilterType = Enum.RaycastFilterType.Exclude

        local function sa_should_shoot()
            local char    = sa_target and sa_target.Character
            local my_char = lp.Character
            local acq     = hc_silent['Acquisition']
            if not char
                or (amethyst['HCSaChecks']['CheckForceField'] and sa_has_ff(char))
                or (amethyst['HCSaChecks']['IgnoreDead']    and sa_is_knocked(char))
                or (amethyst['HCSaChecks']['IgnoreGrabbed'] and sa_is_grabbed(char))
                or (amethyst['HCSaChecks']['IgnoreDead']    and sa_is_knocked(my_char))
                or (amethyst['HCSaChecks']['IgnoreGrabbed'] and sa_is_grabbed(my_char)) then
                sa_can_shoot = false
                if acq ~= 'Always' then
                    sa_target = nil
                    sa_target_locked = false
                end
                return
            end
            sa_can_shoot = true
        end

        local function sa_update_fov()
            local fov = hc_silent['FOV']
            fov_circle.Visible = false
            fov_box.Visible    = false
            if not hc_silent['Enabled'] or not fov['Enabled'] then
                sa_box_focused = false
                return
            end
            fov_box.ZIndex = 1
            local mouse = sa_mpos()
            if fov['Type'] == 'Box' then
                local char = sa_target and sa_target.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then sa_box_focused = false return end
                local nearest = char and sa_get_closest_to_cursor(char)
                if amethyst['HCSaChecks']['WallCheck'] then
                    if not nearest then sa_box_focused = false return end
                    local filter = {}
                    if lp.Character then filter[#filter + 1] = lp.Character end
                    filter[#filter + 1] = camera
                    hc_ray_params.FilterDescendantsInstances = filter
                    local result = ws:Raycast(camera.CFrame.Position, (nearest.Position - camera.CFrame.Position).Unit * 1000, hc_ray_params)
                    if not result or not result.Instance or not result.Instance:IsDescendantOf(sa_target.Character) then
                        sa_box_focused = false return
                    end
                end
                local sp, visible = camera:WorldToViewportPoint(hrp.Position)
                if not visible then sa_box_focused = false return end
                local scale = (hrp.Size.Y * camera.ViewportSize.Y) / (sp.Z * 2) * 80 / camera.FieldOfView
                local bw, bh = fov['Box'][1] * scale, fov['Box'][2] * scale
                local bx, by = sp.X - bw / 2, sp.Y - bh / 2
                sa_box_focused = mouse.X >= bx and mouse.X <= bx + bw and mouse.Y >= by and mouse.Y <= by + bh
                fov_box.Size       = UDim2.fromOffset(bw, bh)
                fov_box.Position   = UDim2.fromOffset(bx, by)
                fov_box.Visible    = fov['Visible']
                fov_box_stroke.Color = sa_box_focused and fov['FocusedColor'] or fov['Color']
            else
                if sa_target and sa_target.Character then
                    local nearest = sa_get_closest_to_cursor(sa_target.Character)
                    if nearest then
                        local tp, on = camera:WorldToViewportPoint(nearest.Position)
                        sa_box_focused = on and (Vector2.new(tp.X, tp.Y) - mouse).Magnitude <= fov['Size']
                    else sa_box_focused = false end
                else sa_box_focused = false end
                fov_circle.Size     = UDim2.fromOffset(fov['Size'] * 2, fov['Size'] * 2)
                fov_circle.Position = UDim2.fromOffset(mouse.X, mouse.Y)
                fov_circle.Visible  = fov['Visible']
                fov_stroke.Color    = sa_box_focused and fov['FocusedColor'] or fov['Color']
            end
        end

        local function sa_hp_color(pct)
            local t = math.clamp(pct, 0, 1)
            return t < 0.5 and Color3.new(1, t * 2, 0) or Color3.new(2 - t * 2, 1, 0)
        end

        local function sa_update_tracer()
            local cfg = hc_silent
            if not cfg['Enabled'] or not cfg['Tracer']['Enabled'] or not cfg['Tracer']['Visible']
                or not sa_target or not sa_target.Character then
                sa_tracer.Visible = false dist_text.Visible = false return
            end
            local hrp = sa_target.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then sa_tracer.Visible = false dist_text.Visible = false return end
            local pos, on = camera:WorldToViewportPoint(hrp.Position)
            if not on then sa_tracer.Visible = false dist_text.Visible = false return end
            local from = sa_mpos()
            local to   = Vector2.new(pos.X, pos.Y)
            local dir  = to - from
            sa_tracer.Size             = UDim2.fromOffset(dir.Magnitude, cfg['Tracer']['Thickness'])
            sa_tracer.Position         = UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2)
            sa_tracer.Rotation         = math.deg(math.atan2(dir.Y, dir.X))
            local hum                  = sa_target.Character:FindFirstChildOfClass("Humanoid")
            sa_tracer.BackgroundColor3 = sa_hp_color(hum and hum.MaxHealth > 0 and hum.Health / hum.MaxHealth or 1)
            sa_tracer.Visible          = true
            local outline = cfg['Tracer']['Outline']
            sa_tracer_stroke.Transparency = outline['Enabled'] and 0 or 1
            if outline['Enabled'] then
                sa_tracer_stroke.Thickness = outline['Thickness']
                sa_tracer_stroke.Color     = outline['Color']
            end
            if cfg['Distance']['Enabled'] then
                local my_hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                if my_hrp then
                    dist_text.Text     = string.format("%.1f studs", (my_hrp.Position - hrp.Position).Magnitude)
                    dist_text.Position = UDim2.fromOffset(from.X, from.Y + 20)
                    dist_text.Visible  = true
                    return
                end
            end
            dist_text.Visible = false
        end

        local blood_particle = RepStore:WaitForChild("BloodParticle")
        local hit_sound      = RepStore:WaitForChild("HitSound")
        local main_event     = RepStore:WaitForChild("MainEvent")

        local cursor_params = RaycastParams.new()
        cursor_params.FilterType = Enum.RaycastFilterType.Include

        local function sa_cursor_on_target(part)
            local mouse = sa_mpos()
            local ray   = camera:ViewportPointToRay(mouse.X, mouse.Y)
            cursor_params.FilterDescendantsInstances = {part}
            return workspace:Raycast(ray.Origin, ray.Direction * 2000, cursor_params) ~= nil
        end

        local function sa_spawn_hit_effects(pos)
            task.spawn(function()
                local anchor = Instance.new("Part")
                anchor.Anchored    = true
                anchor.CanCollide  = false
                anchor.CanQuery    = false
                anchor.Size        = Vector3.new(0.05, 0.05, 0.05)
                anchor.Transparency = 1
                anchor.CFrame      = CFrame.new(pos)
                anchor.Parent      = workspace
                local emitter = blood_particle:Clone(); emitter.Parent = anchor; emitter:Emit(1)
                local sound   = hit_sound:Clone(); sound.Parent = anchor; sound:Play()
                game.Debris:AddItem(anchor, emitter.Lifetime.Max + 0.5)
            end)
        end

        local function sa_get_spread_mul(dist)
            local cfg = hc_silent['Spread']
            if not cfg or not cfg.Enabled then return 0 end
            local t = math.clamp(dist / (cfg.MaxDistance or 50), 0, 1)
            return (cfg.Factor or 1) * (1 + (t ^ 2.2) * (cfg.DistanceScale or 1) * 3)
        end

        local function sa_draw_client_tracer(origin, hit_pos, src)
            local p0 = Instance.new("Part")
            p0.Anchored = true p0.CanCollide = false p0.Transparency = 1
            p0.Size = Vector3.new(0.1, 0.1, 0.1) p0.CFrame = CFrame.new(origin) p0.Parent = workspace
            local p1 = Instance.new("Part")
            p1.Anchored = true p1.CanCollide = false p1.Transparency = 1
            p1.Size = Vector3.new(0.1, 0.1, 0.1) p1.CFrame = CFrame.new(hit_pos) p1.Parent = workspace
            local beam = Instance.new("Beam")
            beam:SetAttribute("ClientTracer", true)
            beam.Attachment0 = Instance.new("Attachment", p0)
            beam.Attachment1 = Instance.new("Attachment", p1)
            beam.Width0 = src.Width0; beam.Width1 = src.Width1
            beam.Color = src.Color; beam.Texture = src.Texture
            beam.LightEmission = src.LightEmission
            beam.Segments = src.Segments; beam.FaceCamera = true
            beam.Parent = p0
            local hb; hb = run.Heartbeat:Connect(function()
                if not src.Parent then hb:Disconnect() return end
                beam.Color = src.Color
            end)
            task.delay(0.25, function() hb:Disconnect() p0:Destroy() p1:Destroy() end)
        end

        local function sa_create_args(root)
            if not sa_target or not sa_target.Character or not root then return end
            local char        = sa_target.Character
            local part        = sa_get_closest_to_cursor(char)
            if not part then return end
            local desired_hit = sa_get_hit_pos()
            if not desired_hit then return end
            local distance    = (root.Position - desired_hit).Magnitude
            local spread_mul  = sa_get_spread_mul(distance)
            local is_shotgun  = false
            local tool        = lp.Character and lp.Character:FindFirstChildOfClass("Tool")
            if tool then
                local module = tool:FindFirstChild("GunData")
                if module then
                    local ok, data = pcall(require, module)
                    if ok and data and data.is_shotgun then is_shotgun = true end
                end
            end
            local rc, parts = {}, {}
            local normal = (root.Position - desired_hit).Unit
            local spread_patterns = {-1.35, -0.9, 0.25, 0.55, 1}
            local server_time = workspace:GetServerTimeNow()
            local rng = Random.new(server_time)
            local random_angle_z = rng:NextNumber(-90, 90)
            local z_rot = CFrame.Angles(0, 0, math.rad(random_angle_z))
            local spread_intensity = rng:NextNumber(0, 5.75)
            local sign = rng:NextInteger(0, 1) == 1 and 1 or -1
            spread_intensity = spread_intensity * sign
            if spread_intensity > -0.35 and spread_intensity < 0.35 then
                spread_intensity = 0.35 * sign
            end
            spread_intensity = spread_intensity * spread_mul
            if is_shotgun then
                local sg_mod = (hc_silent['Spread']['ShotgunSpread'] or 100) / 100
                spread_intensity = spread_intensity * sg_mod
            end
            local base_cf = CFrame.new(root.Position, desired_hit)
            local dist_to_target = (desired_hit - root.Position).Magnitude
            local ray_params = RaycastParams.new()
            ray_params.FilterType = Enum.RaycastFilterType.Include
            ray_params.FilterDescendantsInstances = {char}
            for i = 1, 5 do
                local world_hit = desired_hit
                if is_shotgun and spread_mul > 0 then
                    local pattern = spread_patterns[i] or 0
                    local unit = (base_cf * z_rot * CFrame.Angles(math.rad(pattern * spread_intensity), 0, 0)).LookVector
                    world_hit = root.Position + (unit * dist_to_target)
                end
                local result  = workspace:Raycast(root.Position, world_hit - root.Position, ray_params)
                local hit_part = result and result.Instance or nil
                local final_pos = result and result.Position or world_hit
                rc[i] = { Normal = normal, Instance = hit_part, Position = final_pos }
                parts[i] = {
                    thePart   = hit_part,
                    theOffset = hit_part and hit_part.CFrame:PointToObjectSpace(final_pos) or Vector3.zero
                }
            end
            local positions = {}
            for i = 1, 5 do positions[i] = rc[i].Position end
            sa_last_shot_pos = { origin = root.Position, positions = positions }
            return {"Shoot", {rc, parts, root.Position, root.Position, workspace:GetServerTimeNow()}}
        end

        local sa_last_hit_effects = 0
        local hooked_tools = {}
        local function sa_hook_tool(tool)
            if not tool:IsA("Tool") or hooked_tools[tool] then return end
            hooked_tools[tool] = true
            local conn
            local function activate()
                if sa_anti_kick then
                    if sa_rubberband then sa_rubberband_tp()
                    else library:notification({ text = "Anti Kick: Shot Blocked (" .. string.format("%.1f", sa_anti_kick_d) .. " studs)", time = 2 }) end
                    return
                end
                if not hc_silent['Enabled'] then return end
                if hc_silent['Acquisition'] == 'On Shot' then
                    sa_target = sa_get_target()
                    sa_should_shoot()
                end
                if not sa_can_shoot or not sa_target or not sa_target.Character then return end
                local my_char = lp.Character
                local root = my_char and my_char:FindFirstChild("HumanoidRootPart")
                local targ_hrp = sa_target.Character:FindFirstChild("HumanoidRootPart")
                if not root or not targ_hrp then return end
                local dist = (root.Position - targ_hrp.Position).Magnitude
                if dist > 200 then return end
                if hc_silent['FOV']['Enabled'] then
                    local fov = hc_silent['FOV']
                    if fov['Type'] == 'Box' then
                        if not sa_box_focused then return end
                    else
                        local sp = camera:WorldToViewportPoint(targ_hrp.Position)
                        if (Vector2.new(sp.X, sp.Y) - sa_mpos()).Magnitude >= fov['Size'] then return end
                    end
                end
                local shotguns = {"[DoubleBarrel]", "[Shotgun]", "[TacticalShotgun]", "[AutoShotgun]"}
                for _, name in ipairs(shotguns) do
                    if tool.Name == name and hc_silent['Spread']['Enabled'] and dist > hc_silent['Spread']['MaxDistance'] then return end
                end
                local wall_ok = true
                if amethyst['HCSaChecks']['WallCheck'] then
                    local nearest = sa_get_closest_to_cursor(sa_target.Character)
                    if nearest then
                        local filter = {}
                        if lp.Character then filter[#filter + 1] = lp.Character end
                        filter[#filter + 1] = camera
                        hc_ray_params.FilterDescendantsInstances = filter
                        local result = ws:Raycast(camera.CFrame.Position, (nearest.Position - camera.CFrame.Position).Unit * 1000, hc_ray_params)
                        wall_ok = result and result.Instance and result.Instance:IsDescendantOf(sa_target.Character)
                    else
                        wall_ok = false
                    end
                end
                if not wall_ok then return end
                local script_obj = tool:FindFirstChild("Script")
                if script_obj then
                    local ammo = script_obj:FindFirstChild("Ammo")
                    if ammo then
                        local client = ammo:FindFirstChild("CLIENT")
                        if client and client:IsA("NumberValue") and client.Value <= 0 then return end
                    end
                end
                local sa_args = sa_create_args(root)
                if not sa_args then return end
                main_event:FireServer(unpack(sa_args))
                task.delay(0.3, function() sa_last_shot_pos = nil end)
                if not sa_cursor_on_target(targ_hrp) then
                    local can_spawn_effects = true
                    local script_obj = tool:FindFirstChild("Script")
                    if script_obj then
                        local ammo = script_obj:FindFirstChild("Ammo")
                        if ammo then
                            local client = ammo:FindFirstChild("CLIENT")
                            if client and client:IsA("NumberValue") and client.Value <= 0 then
                                can_spawn_effects = false
                            end
                        end
                    end
                    if can_spawn_effects then
                        local hit_cooldown = 0.4
                        local gun_data = tool:FindFirstChild("GunData")
                        if gun_data then
                            local gd_ok, gd = pcall(require, gun_data)
                            if gd_ok and gd and gd.cooldown then hit_cooldown = gd.cooldown end
                        end
                        local now = tick()
                        if now - sa_last_hit_effects >= hit_cooldown then
                            sa_last_hit_effects = now
                            for i = 1, #sa_args[2][1] do
                                sa_spawn_hit_effects(sa_args[2][1][i].Position)
                            end
                        end
                    end
                end
            end
            library:connection(tool.Equipped, function()
                if conn then conn:Disconnect() end
                conn = tool.Activated:Connect(activate)
            end)
            library:connection(tool.Unequipped, function()
                if conn then conn:Disconnect() conn = nil end
            end)
            if tool.Parent == lp.Character then
                conn = tool.Activated:Connect(activate)
            end
        end

        local pellet_index = 0
        local hidden_beams = {}
        local function hide_all_beams()
            for i = #hidden_beams, 1, -1 do
                local data = hidden_beams[i]
                if not data or not data.beam or not data.beam.Parent then
                    table.remove(hidden_beams, i)
                else
                    data.beam.Transparency = NumberSequence.new(1)
                    if data.frameCount then
                        data.beam.Enabled = false
                        table.remove(hidden_beams, i)
                    else
                        data.frameCount = true
                    end
                end
            end
        end
        library:connection(run.PreRender, hide_all_beams)
        library:connection(workspace.DescendantAdded, function(obj)
            if not obj:IsA("Beam") or obj:GetAttribute("ClientTracer") then return end
            if not sa_last_shot_pos or hc_silent['Client Bullet'] then return end
            task.spawn(function()
                obj.Transparency = NumberSequence.new(1)
                table.insert(hidden_beams, { beam = obj, frameCount = false })
                task.wait(0.01)
                if not sa_last_shot_pos then return end
                local a0 = obj.Attachment0
                if not a0 then return end
                if (a0.WorldPosition - sa_last_shot_pos.origin).Magnitude > 8 then return end
                pellet_index = (pellet_index % 5) + 1
                local hit_pos = sa_last_shot_pos.positions[pellet_index]
                if not hit_pos then return end
                sa_draw_client_tracer(a0.WorldPosition, hit_pos, obj)
            end)
        end)

        library:connection(lp.Backpack.ChildAdded, function(c)
            if c:IsA("Tool") then sa_hook_tool(c) end
        end)
        for _, tool in ipairs(lp.Backpack:GetChildren()) do sa_hook_tool(tool) end
        if lp.Character then
            local t = lp.Character:FindFirstChildOfClass("Tool")
            if t then sa_hook_tool(t) end
        end
        library:connection(lp.CharacterAdded, function(char)
            library:connection(char.ChildAdded, function(c)
                if c:IsA("Tool") then sa_hook_tool(c) end
            end)
        end)

        library:connection(run.Heartbeat, function()
            sa_check_antikick()
        end)

        library:connection(uis.InputBegan, function(key, processed)
            if processed then return end
            local cfg = hc_silent
            local acq = cfg['Acquisition']
            if acq ~= 'Toggle' then return end
            local f = flags['hc_sa_key']
            if not f or not f.key or f.key == "none" then return end
            local key_name = type(f.key) == "string" and f.key or (f.key and f.key.Name)
            if not key_name then return end
            local ok, kc = pcall(function() return Enum.KeyCode[key_name:upper()] end)
            if not ok or key.KeyCode ~= kc then return end
            if sa_target_locked then
                sa_target_locked = false sa_target = nil sa_can_shoot = false
            else
                sa_target = sa_get_target()
                sa_target_locked = sa_target ~= nil
                sa_should_shoot()
            end
        end)

        library:connection(run.PreRender, function()
            local acq = hc_silent['Acquisition']
            if acq == 'Always' then
                sa_target = sa_get_target()
            elseif acq == 'Hold' then
                local f = flags['hc_sa_key']
                local holding = false
                if f and f.key and f.key ~= "none" then
                    local key_name = type(f.key) == "string" and f.key or (f.key and f.key.Name)
                    if key_name then
                        local ok, kc = pcall(function() return Enum.KeyCode[key_name:upper()] end)
                        if ok then holding = uis:IsKeyDown(kc) end
                    end
                end
                if holding then
                    sa_target = sa_get_target()
                else
                    sa_target = nil sa_can_shoot = false
                end
            end
            task.spawn(sa_should_shoot)
            task.spawn(sa_update_fov)
            task.spawn(sa_update_tracer)
        end)
    end

    library:connection(run.PreRender, function()
        local f = flags['hc_sa_key']
        if f and f.mode then
            local mode_map = { hold = 'Hold', toggle = 'Toggle', always = 'Always' }
            hc_silent['Acquisition'] = mode_map[f.mode] or 'Always'
        end
        local ft = flags['hc_tb_key']
        if ft and ft.key and ft.key ~= "none" then
            local name = type(ft.key) == "string" and ft.key or (ft.key and ft.key.Name)
            if name then hc_tb['Keybind'] = name end
        end
    end)

    Legitbot.open_tab()
else
    local Aiming = window:tab({ name = "Legitbot" })
    do
        local column = Aiming:column()
        local ab, tb = column:multi_section({ names = { "Aimbot", "Triggerbot" } })

        ab:toggle({ name = "Enabled", flag = "ab_enabled", default = amethyst['Aimbot']['Enabled'], callback = function(v)
            amethyst['Aimbot']['Enabled'] = v
        end }):keybind({ flag = "ab_key", mode = "hold", name = "Aimbot" })
        ab:dropdown({ name = "Method", flag = "ab_method", items = { "Camera", "Mouse" }, default = amethyst['Aimbot']['Method'], callback = function(v) amethyst['Aimbot']['Method'] = v end })
        ab:slider({ name = "FOV", flag = "ab_fov", min = 1, max = 800, default = amethyst['Aimbot']['FOV'], interval = 1, callback = function(v)
            amethyst['Aimbot']['FOV'] = v
        end })
        ab:slider({ name = "Smoothness", flag = "ab_smooth", min = 0.01, max = 1, default = amethyst['Aimbot']['Smoothness'], interval = 0.01, callback = function(v)
            amethyst['Aimbot']['Smoothness'] = v
        end })
        ab:dropdown({ name = "Easing", flag = "ab_easing", items = { "Linear", "Quad", "Cubic", "Circular", "Sine", "Bounce", "Elastic" }, default = amethyst['Aimbot']['Easing'], callback = function(v)
            amethyst['Aimbot']['Easing'] = v
        end })
        ab:toggle({ name = "Precise Mouse", flag = "ab_precise", default = amethyst['Aimbot']['PreciseMouse'], callback = function(v)
            amethyst['Aimbot']['PreciseMouse'] = v
        end })
        ab:dropdown({ name = "Hitbox", flag = "ab_hitbox", items = { "Head", "Torso", "Arms", "Legs" }, multi = true, default = amethyst['Aimbot']['Hitbox'], callback = function(v)
            amethyst['Aimbot']['Hitbox'] = v
        end })
        ab:slider({ name = "Multipoint", flag = "ab_closest_point", min = 0, max = 100, default = amethyst['Aimbot']['Multipoint'], interval = 1, suffix = "%", callback = function(v)
            amethyst['Aimbot']['Multipoint'] = v
        end })

        tb:toggle({ name = "Enabled", flag = "tb_enabled", default = amethyst['Triggerbot']['Enabled'], callback = function(v)
            amethyst['Triggerbot']['Enabled'] = v
        end }):keybind({ flag = "tb_key", mode = "hold", name = "Triggerbot" })
        tb:toggle({ name = "Require Tool", flag = "tb_tool", default = amethyst['Triggerbot']['RequireTool'], callback = function(v)
            amethyst['Triggerbot']['RequireTool'] = v
        end })
        tb:slider({ name = "Hold Time", flag = "tb_hold", min = 0, max = 500, default = amethyst['Triggerbot']['HoldTime'] * 1000, interval = 10, suffix = "ms", callback = function(v)
            amethyst['Triggerbot']['HoldTime'] = v / 1000
        end })
        tb:slider({ name = "Cooldown", flag = "tb_cooldown", min = 0, max = 1000, default = amethyst['Triggerbot']['Cooldown'] * 1000, interval = 10, suffix = "ms", callback = function(v)
            amethyst['Triggerbot']['Cooldown'] = v / 1000
        end })
        tb:dropdown({ name = "Hitbox", flag = "tb_hitbox", items = { "Head", "Torso", "Arms", "Legs" }, multi = true, default = amethyst['Triggerbot']['Hitbox'], callback = function(v)
            amethyst['Triggerbot']['Hitbox'] = v
        end })
    end
    do
        local column = Aiming:column()
        local ab_f, tb_f = column:multi_section({ names = { "AB Checks", "TB Checks" } })

        ab_f:toggle({ name = "Ignore Dead",     flag = "ab_ignore_dead", default = amethyst['ABChecks']['IgnoreDead'],      callback = function(v) amethyst['ABChecks']['IgnoreDead']      = v end })
        ab_f:toggle({ name = "Check Team",      flag = "ab_check_team",  default = amethyst['ABChecks']['CheckTeam'],       callback = function(v) amethyst['ABChecks']['CheckTeam']       = v end })
        ab_f:toggle({ name = "ForceField",      flag = "ab_check_ff",    default = amethyst['ABChecks']['CheckForceField'], callback = function(v) amethyst['ABChecks']['CheckForceField'] = v end })
        ab_f:toggle({ name = "Wall Check",      flag = "ab_wall_check",  default = amethyst['ABChecks']['WallCheck'],       callback = function(v) amethyst['ABChecks']['WallCheck']       = v end })

        tb_f:toggle({ name = "Ignore Dead",     flag = "tb_ignore_dead", default = amethyst['TBChecks']['IgnoreDead'],      callback = function(v) amethyst['TBChecks']['IgnoreDead']      = v end })
        tb_f:toggle({ name = "Check Team",      flag = "tb_check_team",  default = amethyst['TBChecks']['CheckTeam'],       callback = function(v) amethyst['TBChecks']['CheckTeam']       = v end })
        tb_f:toggle({ name = "ForceField",      flag = "tb_check_ff",    default = amethyst['TBChecks']['CheckForceField'], callback = function(v) amethyst['TBChecks']['CheckForceField'] = v end })
        tb_f:toggle({ name = "Wall Check",      flag = "tb_wall_check",  default = amethyst['TBChecks']['WallCheck'],       callback = function(v) amethyst['TBChecks']['WallCheck']       = v end })
    end

    local Visuals = window:tab({ name = "Visuals" })
    do
        local col = Visuals:column()
        build_esp_ui(col:section({ name = "ESP" }))
        if not esp_preview_obj then esp_preview_obj = window.esp_section:esp_preview({}) end
    end

    Aiming.open_tab()
end

local is_arsenal        = game_name:find("arsenal") ~= nil
local is_phantom        = game_name:find("phantom forces") ~= nil
local is_battlebit      = game_name:find("battlebit") ~= nil
local is_frontlines     = game_name:find("frontlines") ~= nil
local is_badlands       = game_name:find("badlands") ~= nil
local is_overwatch      = game_name:find("overwatch") ~= nil
local is_arms           = game_name:find("arms of solitaire") ~= nil
local is_workspace_game = is_phantom or is_battlebit or is_frontlines or is_badlands or is_overwatch or is_arms

local RayParams = RaycastParams.new()
RayParams.FilterType  = Enum.RaycastFilterType.Blacklist
RayParams.IgnoreWater = true

local triggerbot_state = {
    can_fire       = true,
    last_fire_time = 0,
    is_holding     = false,
    hold_task      = nil,
}




local player_cache = {}

local function cache_player(player)
    if player == lp then return end
    local function on_char(character)
        task.spawn(function()
            task.wait(1.5)
            if not character.Parent then return end
            pcall(function()
                if not character.Parent then return end
                local head, hrp
                if is_battlebit then
                    local body = character:FindFirstChild("Body")
                    if body then
                        head = body:FindFirstChild("Head")
                        hrp  = body:FindFirstChild("Abdomen")
                    end
                else
                    head = character:FindFirstChild("Head")
                    hrp  = character:FindFirstChild("HumanoidRootPart")
                end
                local parts = {}
                for _, p in ipairs(character:GetChildren()) do
                    if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                        parts[#parts + 1] = p
                    end
                end
                player_cache[character] = { player = player, character = character, head = head, hrp = hrp, humanoid = character:FindFirstChildOfClass("Humanoid"), parts = parts }
            end)
        end)
    end
    if player.Character then on_char(player.Character) end
    library:connection(player.CharacterAdded, on_char)
    library:connection(player.CharacterRemoving, function(character)
        player_cache[character] = nil
    end)
end

local function rebuild_workspace_cache()
    pcall(function()
        local new_cache = {}

        if is_phantom then
            local teams_folder = ws:FindFirstChild("Players")
            if not teams_folder then return end
            local teams = teams_folder:GetChildren()
            if #teams ~= 2 then return end
            for _, team in ipairs(teams) do
                for _, model in ipairs(team:GetChildren()) do
                    pcall(function()
                        if model.ClassName ~= "Model" then return end
                        new_cache[model] = { player = nil, character = model, head = model:FindFirstChild("Head"), hrp = model:FindFirstChild("HumanoidRootPart"), humanoid = model:FindFirstChildOfClass("Humanoid") }
                    end)
                end
            end

        elseif is_battlebit then
            local folder = ws:GetChildren()[6]
            if not folder then return end
            for _, model in ipairs(folder:GetChildren()) do
                pcall(function()
                    local body = model:FindFirstChild("Body")
                    if not body then return end
                    new_cache[model] = { player = nil, character = model, head = body:FindFirstChild("Head"), hrp = body:FindFirstChild("Abdomen"), humanoid = model:FindFirstChildOfClass("Humanoid") }
                end)
            end

        elseif is_badlands then
            for _, model in ipairs(ws:GetChildren()) do
                pcall(function()
                    if model.ClassName ~= "Model" or not model:FindFirstChild("Head") then return end
                    new_cache[model] = { player = nil, character = model, head = model:FindFirstChild("Head"), hrp = model:FindFirstChild("HumanoidRootPart"), humanoid = model:FindFirstChildOfClass("Humanoid") }
                end)
            end

        elseif is_frontlines then
            for _, model in ipairs(ws:GetChildren()) do
                pcall(function()
                    if model.Name ~= "soldier_model" then return end
                    if amethyst['Checks']['CheckTeam'] and model:FindFirstChild("friendly_marker") then return end
                    new_cache[model] = { player = nil, character = model, head = model:FindFirstChild("TPVBodyVanillaHead"), hrp = model:FindFirstChild("HumanoidRootPart"), humanoid = model:FindFirstChildOfClass("Humanoid") }
                end)
            end

        elseif is_overwatch then
            local folder = ws:FindFirstChild("Characters")
            if not folder then return end
            for _, model in ipairs(folder:GetChildren()) do
                pcall(function()
                        new_cache[model] = { player = nil, character = model, head = model:FindFirstChild("Top"), hrp = model:FindFirstChild("Center"), humanoid = model:FindFirstChildOfClass("Humanoid") }
                end)
            end

        elseif is_arms then
            local players_folder = ws:FindFirstChild("Game") and ws.Game:FindFirstChild("Players")
            if not players_folder then return end
            local teams = players_folder:GetChildren()
            if #teams ~= 2 then return end
            local function add_team(team)
                for _, model in ipairs(team:GetChildren()) do
                    pcall(function()
                        if model.ClassName ~= "Model" then return end
                        local hitbox = model:FindFirstChild("Hitbox")
                        new_cache[model] = { player = nil, character = model, head = hitbox, hrp = hitbox, humanoid = model:FindFirstChildOfClass("Humanoid") }
                    end)
                end
            end
            if amethyst['Checks']['CheckTeam'] then
                local enemy_team
                for _, team in ipairs(teams) do
                    for _, model in ipairs(team:GetChildren()) do
                        pcall(function()
                            if model.ClassName == "Model" and model.Name == lp.Name then
                                enemy_team = teams[1] == team and teams[2] or teams[1]
                            end
                        end)
                    end
                end
                if enemy_team then add_team(enemy_team) end
            else
                for _, team in ipairs(teams) do add_team(team) end
            end
        end

        for k, v in pairs(player_cache) do
            if v.player == nil then player_cache[k] = nil end
        end
        for k, v in pairs(new_cache) do
            player_cache[k] = v
        end
    end)
end

if is_workspace_game then
    rebuild_workspace_cache()
    local accum = 0
    library:connection(run.Heartbeat, function(dt)
        accum += dt
        if accum >= 3 then
            accum = 0
            rebuild_workspace_cache()
        end
    end)
else
    for _, player in ipairs(players:GetPlayers()) do cache_player(player) end
    library:connection(players.PlayerAdded, cache_player)
    library:connection(players.PlayerRemoving, function(player)
        if player.Character then player_cache[player.Character] = nil end
    end)
end




local esp_drawings = {}

local function esp_make_line()
    local l = Drawing.new("Line")
    l.Thickness = 1
    l.Visible   = false
    return l
end

local function esp_make_text()
    local t = Drawing.new("Text")
    t.Size         = 13
    t.Font         = Drawing.Fonts.UI
    t.Outline      = true
    t.OutlineColor = Color3.fromRGB(0, 0, 0)
    t.Center       = true
    t.Visible      = false
    return t
end

local function esp_make_square()
    local s = Drawing.new("Square")
    s.Thickness = 1
    s.Filled    = false
    s.Visible   = false
    return s
end

local function esp_create(character)
    if esp_drawings[character] then return end
    local d = {
        corners   = {},
        box       = esp_make_square(),
        hbar_bg   = esp_make_square(),
        hbar_fill = esp_make_square(),
        name      = esp_make_text(),
        distance  = esp_make_text(),
        weapon    = esp_make_text(),
    }
    for i = 1, 8 do d.corners[i] = esp_make_line() end
    d.hbar_bg.Filled   = true
    d.hbar_fill.Filled = true
    esp_drawings[character] = d
end

local function esp_destroy(character)
    local d = esp_drawings[character]
    if not d then return end
    for _, l in ipairs(d.corners) do l:Remove() end
    d.box:Remove(); d.hbar_bg:Remove(); d.hbar_fill:Remove()
    d.name:Remove(); d.distance:Remove(); d.weapon:Remove()
    esp_drawings[character] = nil
end

local function esp_hide(d)
    for _, l in ipairs(d.corners) do l.Visible = false end
    d.box.Visible = false; d.hbar_bg.Visible = false; d.hbar_fill.Visible = false
    d.name.Visible = false; d.distance.Visible = false; d.weapon.Visible = false
end

local HP_BAR_BG_COLOR = Color3.fromRGB(30, 30, 30)
local cached_focal    = 500
local esp_ray_params  = RaycastParams.new()
esp_ray_params.FilterType = Enum.RaycastFilterType.Exclude

local m_max   = math.max
local m_floor = math.floor

local function fc(flag, r, g, b)
    return (flags[flag] and flags[flag].Color) or Color3.fromRGB(r, g, b)
end

local function esp_get_bbox(entry)
    local char = entry.character
    if not char then return nil end

    local wx0, wy0, wz0 =  math.huge,  math.huge,  math.huge
    local wx1, wy1, wz1 = -math.huge, -math.huge, -math.huge

    local parts = entry.parts
    if parts then
        for i = 1, #parts do
            local p = parts[i]
            local pos, s = p.Position, p.Size
            local hx, hy, hz = s.X * 0.5, s.Y * 0.5, s.Z * 0.5
            if pos.X - hx < wx0 then wx0 = pos.X - hx end
            if pos.Y - hy < wy0 then wy0 = pos.Y - hy end
            if pos.Z - hz < wz0 then wz0 = pos.Z - hz end
            if pos.X + hx > wx1 then wx1 = pos.X + hx end
            if pos.Y + hy > wy1 then wy1 = pos.Y + hy end
            if pos.Z + hz > wz1 then wz1 = pos.Z + hz end
        end
    else
        for _, p in ipairs(char:GetChildren()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                local pos, s = p.Position, p.Size
                local hx, hy, hz = s.X * 0.5, s.Y * 0.5, s.Z * 0.5
                if pos.X - hx < wx0 then wx0 = pos.X - hx end
                if pos.Y - hy < wy0 then wy0 = pos.Y - hy end
                if pos.Z - hz < wz0 then wz0 = pos.Z - hz end
                if pos.X + hx > wx1 then wx1 = pos.X + hx end
                if pos.Y + hy > wy1 then wy1 = pos.Y + hy end
                if pos.Z + hz > wz1 then wz1 = pos.Z + hz end
            end
        end
    end
    if wx0 == math.huge then return nil end

    local min_x, min_y =  math.huge,  math.huge
    local max_x, max_y = -math.huge, -math.huge
    local v3 = Vector3.new
    local corners = {
        v3(wx0, wy0, wz0), v3(wx0, wy0, wz1),
        v3(wx0, wy1, wz0), v3(wx0, wy1, wz1),
        v3(wx1, wy0, wz0), v3(wx1, wy0, wz1),
        v3(wx1, wy1, wz0), v3(wx1, wy1, wz1),
    }
    for i = 1, 8 do
        local sp, on = camera:WorldToViewportPoint(corners[i])
        if on and sp.Z > 0 then
            if sp.X < min_x then min_x = sp.X end
            if sp.Y < min_y then min_y = sp.Y end
            if sp.X > max_x then max_x = sp.X end
            if sp.Y > max_y then max_y = sp.Y end
        end
    end
    if min_x == math.huge then return nil end

    local x_pad = m_max(1, m_floor((max_y - min_y) * 0.08))
    return m_floor(min_x) - x_pad, m_floor(min_y), m_floor(max_x) + x_pad, m_floor(max_y)
end

local CORNER_F = 0.25
local function esp_draw_corners(d, x1, y1, x2, y2, color)
    local cw = math.max(4, math.floor((x2 - x1) * CORNER_F))
    local ch = math.max(4, math.floor((y2 - y1) * CORNER_F))
    local v2 = Vector2.new
    d.corners[1].From = v2(x1, y1);   d.corners[1].To = v2(x1 + cw, y1)
    d.corners[2].From = v2(x1, y1);   d.corners[2].To = v2(x1, y1 + ch)
    d.corners[3].From = v2(x2, y1);   d.corners[3].To = v2(x2 - cw, y1)
    d.corners[4].From = v2(x2, y1);   d.corners[4].To = v2(x2, y1 + ch)
    d.corners[5].From = v2(x1, y2);   d.corners[5].To = v2(x1 + cw, y2)
    d.corners[6].From = v2(x1, y2);   d.corners[6].To = v2(x1, y2 - ch)
    d.corners[7].From = v2(x2, y2);   d.corners[7].To = v2(x2 - cw, y2)
    d.corners[8].From = v2(x2, y2);   d.corners[8].To = v2(x2, y2 - ch)
    for _, l in ipairs(d.corners) do l.Color = color; l.Visible = true end
end

local function hp_color(t)
    if t > 0.5 then
        return Color3.fromRGB(math.floor(255 * (2 * (1 - t))), 255, 0)
    else
        return Color3.fromRGB(255, math.floor(255 * (2 * t)), 0)
    end
end

local function esp_update(d, entry)
    local character = entry.character
    if not entry.hrp      then entry.hrp      = character:FindFirstChild("HumanoidRootPart") end
    if not entry.head     then entry.head     = character:FindFirstChild("Head") end
    if not entry.humanoid then entry.humanoid = character:FindFirstChildOfClass("Humanoid") end
    local player_priority = (entry.player and library.get_priority(entry.player)) or "Neutral"
    local show_list = flags["esp_show"]
    if show_list and type(show_list) == "table" and #show_list > 0 and #show_list < 4 then
        local ok = false
        for _, p in ipairs(show_list) do if p == player_priority then ok = true break end end
        if not ok then esp_hide(d) return end
    end
    local priority_color
    if player_priority == "Enemy" then
        priority_color = flags["esp_enemy_color"] or Color3.fromRGB(255, 0, 0)
    elseif player_priority == "Friendly" or player_priority == "Priority" then
        priority_color = flags["esp_friendly_color"] or Color3.fromRGB(0, 255, 255)
    end
    if is_hood_customs then
        if flags["hc_esp_ignore_dead"] then
            local be = character:FindFirstChild("BodyEffects")
            if be then
                local ko = be:FindFirstChild("K.O")
                if ko and ko.Value then esp_hide(d) return end
            end
        end
        if flags["hc_esp_ignore_grabbed"] then
            if character:FindFirstChild("GRABBING_CONSTRAINT") then esp_hide(d) return end
        end
        if flags["hc_esp_wallcheck"] and entry.hrp then
            esp_ray_params.FilterDescendantsInstances = { lp.Character, camera }
            local origin = camera.CFrame.Position
            local result = ws:Raycast(origin, (entry.hrp.Position - origin).Unit * 1000, esp_ray_params)
            if not result or not result.Instance or not result.Instance:IsDescendantOf(character) then
                esp_hide(d) return
            end
        end
    end
    local x1, y1, x2, y2 = esp_get_bbox(entry)
    if not x1 then esp_hide(d) return end
    local w, h = x2 - x1, y2 - y1
    local cx   = math.floor((x1 + x2) * 0.5)

    if flags["Boxes"] then
        local box_c = priority_color or fc("Box_Color", 255, 255, 255)
        if flags["Box_Type"] == "Full" then
            d.box.Position = Vector2.new(x1, y1)
            d.box.Size     = Vector2.new(w, h)
            d.box.Color    = box_c
            d.box.Visible  = true
            for _, l in ipairs(d.corners) do l.Visible = false end
        else
            esp_draw_corners(d, x1, y1, x2, y2, box_c)
            d.box.Visible = false
        end
    else
        d.box.Visible = false
        for _, l in ipairs(d.corners) do l.Visible = false end
    end

    if flags["Healthbar"] then
        local hum = entry.humanoid
        local hp  = hum and math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1) or 1
        local bx  = x1 - 6
        d.hbar_bg.Filled   = true
        d.hbar_bg.Position = Vector2.new(bx, y1 - 1)
        d.hbar_bg.Size     = Vector2.new(4, h + 2)
        d.hbar_bg.Color    = HP_BAR_BG_COLOR
        d.hbar_bg.Visible  = true
        local fh = math.max(1, math.floor(h * hp))
        d.hbar_fill.Filled   = true
        d.hbar_fill.Position = Vector2.new(bx + 1, y2 - fh)
        d.hbar_fill.Size     = Vector2.new(2, fh)
        local low_c  = flags["Health_Low"]  and flags["Health_Low"].Color
        local high_c = flags["Health_High"] and flags["Health_High"].Color
        d.hbar_fill.Color = (low_c and high_c) and low_c:Lerp(high_c, hp) or hp_color(hp)
        d.hbar_fill.Visible  = true
    else
        d.hbar_bg.Visible = false; d.hbar_fill.Visible = false
    end

    if flags["Names"] then
        local player = entry.player
        d.name.Text     = player and player.DisplayName or character.Name
        d.name.Position = Vector2.new(cx, math.floor(y1) - 15)
        d.name.Color    = priority_color or fc("Name_Color", 255, 255, 255)
        d.name.Visible  = true
    else
        d.name.Visible = false
    end

    if flags["Distance"] then
        local lpc  = lp.Character
        local lhrp = lpc and lpc:FindFirstChild("HumanoidRootPart")
        local hrp  = entry.hrp
        local dist = (lhrp and hrp) and math.floor((hrp.Position - lhrp.Position).Magnitude) or 0
        d.distance.Text     = dist .. "m"
        d.distance.Position = Vector2.new(cx, math.floor(y2) + 3)
        d.distance.Color    = fc("Distance_Color", 255, 255, 255)
        d.distance.Visible  = true
    else
        d.distance.Visible = false
    end

    if flags["Weapon"] then
        local player = entry.player
        local wep    = "[ No Weapon ]"
        if player and player.Character then
            local tool = player.Character:FindFirstChildOfClass("Tool")
            if tool then wep = "[ " .. tool.Name .. " ]" end
        end
        local y_off = flags["Distance"] and 16 or 3
        d.weapon.Text     = wep
        d.weapon.Position = Vector2.new(cx, math.floor(y2) + y_off)
        d.weapon.Color    = fc("Weapon_Color", 255, 255, 255)
        d.weapon.Visible  = true
    else
        d.weapon.Visible = false
    end
end

library.on_unload = function()
    for char in pairs(esp_drawings) do esp_destroy(char) end
    if hc_sa_gui then hc_sa_gui:Destroy() end
end

local function get_eased_delta(delta, easing_style)
    local alpha = tween_service:GetValue(1, Enum.EasingStyle[easing_style], Enum.EasingDirection.Out)
    return delta * alpha
end

local function is_valid(entry, checks)
    local player    = entry.player
    local character = entry.character
    if not character then return false end

    if is_hood_customs then
        if checks['IgnoreDead'] then
            local be = character:FindFirstChild("BodyEffects")
            if be then
                local ko = be:FindFirstChild("K.O")
                if ko and ko.Value then return false end
            end
        end
        if checks['IgnoreGrabbed']   and character:FindFirstChild("GRABBING_CONSTRAINT") then return false end
        if checks['CheckForceField'] and character:FindFirstChild("Forcefield")           then return false end
        if checks['IgnoreDead'] or checks['IgnoreGrabbed'] then
            local local_char = lp.Character
            if local_char then
                if checks['IgnoreDead'] then
                    local local_be = local_char:FindFirstChild("BodyEffects")
                    if local_be then
                        local local_ko = local_be:FindFirstChild("K.O")
                        if local_ko and local_ko.Value then return false end
                    end
                end
                if checks['IgnoreGrabbed'] and local_char:FindFirstChild("GRABBING_CONSTRAINT") then return false end
            end
        end
        return true
    end

    if checks['IgnoreDead'] then
        if is_arsenal and player then
            local nrpbs = player:FindFirstChild("NRPBS")
            if not nrpbs then return false end
            local health_obj = nrpbs:FindFirstChild("Health")
            if not health_obj or health_obj.Value <= 0 then return false end
            local root = character:FindFirstChild("HumanoidRootPart")
            if root and root.Position.Y < 0 then return false end
        elseif not is_workspace_game then
            local humanoid = character:FindFirstChildWhichIsA("Humanoid")
            if not humanoid or humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead then return false end
        end
    end

    if player and checks['CheckTeam'] and not is_arsenal and game.PlaceId ~= 85788627530413 then
        if game_name:find("bronx") and game_name:find("duels") then
            if character:FindFirstChildOfClass("Highlight") then
                local local_char = lp.Character
                if local_char and local_char:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("HumanoidRootPart") then
                    if (character.HumanoidRootPart.Position - local_char.HumanoidRootPart.Position).Magnitude <= 75 then return false end
                else
                    return false
                end
            end
        else
            if lp.Team and player.Team and lp.Team == player.Team then return false end
            if lp.TeamColor and player.TeamColor and lp.TeamColor == player.TeamColor then return false end
        end
    end

    if checks['CheckForceField'] and character:FindFirstChildOfClass("ForceField") then return false end

    return true
end




local function get_closest_visible_player()
    local mouse_pos     = uis:GetMouseLocation()
    local closest_entry = nil
    local closest_part  = nil
    local closest_dist  = math.huge
    local origin        = camera.CFrame.Position

    RayParams.FilterDescendantsInstances = { lp.Character, camera }

    for _, entry in pairs(player_cache) do
        pcall(function()
            if not is_valid(entry, is_hood_customs and amethyst['HCAbChecks'] or amethyst['ABChecks']) then return end

            local part = get_closest_part_to_cursor(entry.character, amethyst['Aimbot']['Hitbox'])
            if not part then return end

            if is_hood_customs and part.Transparency >= 0.5 then return end

            local sp, on_screen = camera:WorldToViewportPoint(part.Position)
            if not on_screen then return end

            local dist = (vec2(sp.X, sp.Y) - mouse_pos).Magnitude
            if is_hood_customs and amethyst['Aimbot']['FOVType'] == 'Box' then
                local hrp = entry.character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local hrp_sp = camera:WorldToViewportPoint(hrp.Position)
                local scale = (hrp.Size.Y * camera.ViewportSize.Y) / (hrp_sp.Z * 2) * 80 / camera.FieldOfView
                local bw = amethyst['Aimbot']['FOVBox'][1] * scale
                local bh = amethyst['Aimbot']['FOVBox'][2] * scale
                local bx = hrp_sp.X - bw / 2
                local by = hrp_sp.Y - bh / 2
                if mouse_pos.X < bx or mouse_pos.X > bx + bw or mouse_pos.Y < by or mouse_pos.Y > by + bh then return end
                if dist >= closest_dist then return end
            else
                if dist > amethyst['Aimbot']['FOV'] or dist >= closest_dist then return end
            end

            local result = ws:Raycast(origin, (part.Position - origin).Unit * 1000, RayParams)
            if amethyst['ABChecks']['WallCheck'] then
                if not result or not result.Instance or not result.Instance:IsDescendantOf(entry.character) then return end
            end

            closest_dist  = dist
            closest_entry = entry
            closest_part  = part
        end)
    end

    if not closest_part then return nil, nil, nil end

    local aim_pos = get_closest_point_on_part(closest_part, amethyst['Aimbot']['Multipoint'] / 100)
    local sp = camera:WorldToViewportPoint(aim_pos)
    return closest_entry, vec2(sp.X, sp.Y), aim_pos
end




local function get_target_from_center()
    local screen_center = vec2(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local unit_ray      = camera:ViewportPointToRay(screen_center.X, screen_center.Y)
    local wallcheck    = is_hood_customs and amethyst['HCTbChecks']['WallCheck'] or amethyst['TBChecks']['WallCheck']

    local result
    if wallcheck then
        RayParams.FilterType = Enum.RaycastFilterType.Exclude
        RayParams.FilterDescendantsInstances = { lp.Character, camera }
        result = ws:Raycast(unit_ray.Origin, unit_ray.Direction * 1000, RayParams)
        if not result or not result.Instance then return nil end
        local hit_part = result.Instance
        local character = hit_part:FindFirstAncestorOfClass("Model")
        if not character then return nil end
        local player = players:GetPlayerFromCharacter(character)
        if not player or player == lp then return nil end
        local entry = player_cache[character] or { player = player, character = character, head = character:FindFirstChild("Head"), hrp = character:FindFirstChild("HumanoidRootPart") }
        if not is_valid(entry, is_hood_customs and amethyst['HCTbChecks'] or amethyst['TBChecks']) then return nil end
        local allowed = get_hitbox_part_names(character, amethyst['Triggerbot']['Hitbox'])
        if not allowed[hit_part.Name] then return nil end
        return entry
    else
        local player_chars = {}
        for _, p in ipairs(players:GetPlayers()) do
            if p ~= lp and p.Character then
                player_chars[#player_chars + 1] = p.Character
            end
        end
        if #player_chars == 0 then return nil end
        local tb_params = RaycastParams.new()
        tb_params.FilterType = Enum.RaycastFilterType.Include
        tb_params.FilterDescendantsInstances = player_chars
        result = ws:Raycast(unit_ray.Origin, unit_ray.Direction * 1000, tb_params)
        if not result or not result.Instance then return nil end
        local hit_part = result.Instance
        local character = hit_part:FindFirstAncestorOfClass("Model")
        if not character then return nil end
        local player = players:GetPlayerFromCharacter(character)
        if not player or player == lp then return nil end
        local entry = player_cache[character] or { player = player, character = character, head = character:FindFirstChild("Head"), hrp = character:FindFirstChild("HumanoidRootPart") }
        if not is_valid(entry, is_hood_customs and amethyst['HCTbChecks'] or amethyst['TBChecks']) then return nil end
        local allowed = get_hitbox_part_names(character, amethyst['Triggerbot']['Hitbox'])
        if not allowed[hit_part.Name] then return nil end
        return entry
    end
end




local function triggerbot_fire()
    if not triggerbot_state.can_fire then return end

    if amethyst['Triggerbot']['RequireTool'] then
        local char = lp.Character
        if not char or not char:FindFirstChildOfClass("Tool") then return end
    end

    if is_hood_customs then
        local char = lp.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool and tool.Name:lower():find("knife") then return end
        end
    end

    if game.PlaceId == 85788627530413 and amethyst['TBChecks']['CheckForceField'] then
        local char = lp.Character
        if char and char:FindFirstChildOfClass("ForceField") then return end
    end

    local now = tick()
    if now - triggerbot_state.last_fire_time < amethyst['Triggerbot']['Cooldown'] then return end

    local target = get_target_from_center()
    if not target then return end

    triggerbot_state.can_fire       = false
    triggerbot_state.last_fire_time = now

    mouse1press()
    triggerbot_state.is_holding = true

    if triggerbot_state.hold_task then
        triggerbot_state.hold_task:Cancel()
    end

    triggerbot_state.hold_task = task.delay(amethyst['Triggerbot']['HoldTime'], function()
        if triggerbot_state.is_holding then
            mouse1release()
            triggerbot_state.is_holding = false
            triggerbot_state.hold_task  = nil
            triggerbot_state.can_fire   = true
        end
    end)
end




local function aimbot_update()
    local aim_pos_3d
    local screen_pos
    if is_hood_customs then
        if not sa_target or not sa_target.Character then return end
        local part = get_closest_part_to_cursor(sa_target.Character, amethyst['Aimbot']['Hitbox'])
        if not part then return end
        if amethyst['HCAbChecks']['WallCheck'] then
            RayParams.FilterDescendantsInstances = { lp.Character, camera }
            local origin = camera.CFrame.Position
            local result = ws:Raycast(origin, (part.Position - origin).Unit * 1000, RayParams)
            if not result or not result.Instance or not result.Instance:IsDescendantOf(sa_target.Character) then return end
        end
        aim_pos_3d = get_closest_point_on_part(part, amethyst['Aimbot']['Multipoint'] / 100)
        local sp = camera:WorldToViewportPoint(aim_pos_3d)
        if sp.Z <= 0 then return end
        local vx, vy = camera.ViewportSize.X, camera.ViewportSize.Y
        if sp.X < 0 or sp.X > vx or sp.Y < 0 or sp.Y > vy then return end
        screen_pos = vec2(sp.X, sp.Y)
    else
        local _, sp, ap = get_closest_visible_player()
        screen_pos = sp
        aim_pos_3d = ap
    end
    if not screen_pos then return end

    local method = amethyst['Aimbot']['Method'] or 'Camera'
    if method == 'Camera' and aim_pos_3d then
        local sm = amethyst['Aimbot']['Smoothness']
        local stickiness = 0.02 + (sm ^ 1.5) * 0.98
        local alpha = tween_service:GetValue(math.clamp(stickiness, 0.01, 1), Enum.EasingStyle[amethyst['Aimbot']['Easing'] or 'Circular'], Enum.EasingDirection.InOut)
        local mouse = uis:GetMouseLocation()
        local delta_x = (mouse.X / camera.ViewportSize.X - 0.5) * 0.8
        local target_cframe = CFrame.new(camera.CFrame.Position, aim_pos_3d) * CFrame.Angles(0, delta_x, 0)
        camera.CFrame = camera.CFrame:Lerp(target_cframe, alpha)
        return
    end

    local mouse_pos   = uis:GetMouseLocation()
    local raw_delta   = screen_pos - mouse_pos
    local eased_delta = get_eased_delta(raw_delta, amethyst['Aimbot']['Easing'])

    if amethyst['Aimbot']['PreciseMouse'] then
        mousemoveabs(
            mouse_pos.X + (raw_delta.X * amethyst['Aimbot']['Smoothness']) + eased_delta.X,
            mouse_pos.Y + (raw_delta.Y * amethyst['Aimbot']['Smoothness']) + eased_delta.Y
        )
    else
        local delta = (raw_delta * amethyst['Aimbot']['Smoothness']) + (eased_delta * 0.1)
        mousemoverel(delta.X, delta.Y)
    end
end




library:connection(run.PreRender, function()
    cached_focal = camera.ViewportSize.Y * 0.5 / math.tan(math.rad(camera.FieldOfView * 0.5))
    local ab_key = flags['ab_key']
    local tb_key = flags['tb_key']
    local ab_active = amethyst['Aimbot']['Enabled']     and (not ab_key or not ab_key.key or ab_key.active)
    local tb_active = amethyst['Triggerbot']['Enabled'] and (not tb_key or not tb_key.key or tb_key.active)

    task.spawn(function()
        if ab_active then aimbot_update() end
    end)
    task.spawn(function()
        if not is_hood_customs and tb_active then triggerbot_fire() end
    end)
    task.spawn(function()
        if flags["Enabled"] then
            for character, entry in pairs(player_cache) do
                if not esp_drawings[character] then esp_create(character) end
                local d = esp_drawings[character]
                if d then pcall(esp_update, d, entry) end
            end
            for character in pairs(esp_drawings) do
                if not player_cache[character] then esp_destroy(character) end
            end
        else
            for _, d in pairs(esp_drawings) do esp_hide(d) end
        end
    end)
end)

library:config_list_update()
for index, value in themes.preset do
    pcall(function() library:update_theme(index, value) end)
end
task.wait()
library.old_config = library:get_config()
