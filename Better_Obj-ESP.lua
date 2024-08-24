-- Author: anonymouspleb, IB_U_Z_Z_A_R_Dl
-- Description: Collectible/Object ESP
-- GitHub Repository: https://github.com/Illegal-Services/Better_Obj-ESP-2Take1-lua


-- Globals START
---- Global variables 1/2 START
local _FMAP = {}
local _CMAP = {}
local DRAW = require("Better_Obj-ESP\\draw")
local scriptExit_EventListener
local mainLoop_Thread
---- Global variables 1/2 END

---- Global constants 1/2 START
local SCRIPT_NAME <const> = "Better_Obj-ESP.lua"
local SCRIPT_TITLE <const> = "Better Object ESP"
local SCRIPT_SETTINGS__PATH <const> = "scripts\\Better_Obj-ESP\\Settings.ini"
local NATIVES <const> = require("lib\\natives2845")
local HOME_PATH <const> = utils.get_appdata_path("PopstarDevs", "2Take1Menu")
local TRUSTED_FLAGS <const> = {
    { name = "LUA_TRUST_STATS", menuName = "Trusted Stats", bitValue = 1 << 0, isRequiered = false },
    { name = "LUA_TRUST_SCRIPT_VARS", menuName = "Trusted Globals / Locals", bitValue = 1 << 1, isRequiered = false },
    { name = "LUA_TRUST_NATIVES", menuName = "Trusted Natives", bitValue = 1 << 2, isRequiered = true },
    { name = "LUA_TRUST_HTTP", menuName = "Trusted Http", bitValue = 1 << 3, isRequiered = false },
    { name = "LUA_TRUST_MEMORY", menuName = "Trusted Memory", bitValue = 1 << 4, isRequiered = false }
}
---- Global constants 1/2 END

---- Global variables 2/2 START
local INI = IniParser(SCRIPT_SETTINGS__PATH)
---- Global variables 2/2 END

---- Global functions 1/2 START
local function rgba_to_int(R, G, B, A)
    A = A or 255
    return ((R&0x0ff)<<0x00)|((G&0x0ff)<<0x08)|((B&0x0ff)<<0x10)|((A&0x0ff)<<0x18)
end
---- Global functions 1/2 END

---- Global constants 2/2 START
local COLOR <const> = {
    RED = rgba_to_int(255, 0, 0, 255),
    GREEN = rgba_to_int(0, 255, 0, 255),
    BLUE = rgba_to_int(0, 0, 255, 255),
    ORANGE = rgba_to_int(255, 165, 0, 255),
    GREY = rgba_to_int(128, 128, 128, 255),
    CYAN = rgba_to_int(0, 150, 255, 255),
    GREEN_FROM_WALLET_MONEY = rgba_to_int(114, 204, 114, 255),
}
COLOR.ENNEMY = COLOR.RED
COLOR.HACKABLE = COLOR.GREEN
COLOR.DEFAULT = COLOR.GREY
COLOR.PICKUP = COLOR.CYAN
COLOR.COLLECTIBLE = COLOR.GREEN_FROM_WALLET_MONEY
---- Global constants 2/2 END

---- Global functions 2/2 END
local function pluralize(word, count)
    return word .. (count > 1 and "s" or "")
end

local function startswith(str, prefix)
    return str:sub(1, #prefix) == prefix
end

local function create_tick_handler(handler, ms)
    return menu.create_thread(function()
        while true do
            handler()
            system.yield(ms)
        end
    end)
end

local function is_thread_running(threadId)
    if threadId and not menu.has_thread_finished(threadId) then
        return true
    end

    return false
end

local function remove_event_listener(eventType, listener)
    if listener and event.remove_event_listener(eventType, listener) then
        return
    end

    return listener
end

local function delete_thread(threadId)
    if threadId and menu.delete_thread(threadId) then
        return nil
    end

    return threadId
end

local function handle_script_exit(params)
    params = params or {}
    if params.clearAllNotifications == nil then
        params.clearAllNotifications = false
    end
    if params.hasScriptCrashed == nil then
        params.hasScriptCrashed = false
    end

    scriptExit_EventListener = remove_event_listener("exit", scriptExit_EventListener)

    if is_thread_running(mainLoop_Thread) then
        mainLoop_Thread = delete_thread(mainLoop_Thread)
    end

    -- This will delete notifications from other scripts too.
    -- Suggestion is open: https://discord.com/channels/1088976448452304957/1092480948353904752/1253065431720394842
    if params.clearAllNotifications then
        menu.clear_all_notifications()
    end

    if params.hasScriptCrashed then
        menu.notify("Oh no... Script crashed:(\nYou gotta restart it manually.", SCRIPT_NAME, 12, COLOR.RED)
    end

    menu.exit()
end

local function load_settings()
    if INI:read() then
        for key, feat in pairs(_FMAP) do
            if key ~= "max_dist" then -- pathetic
                local exists, val = INI:get_b("Toggles", key)
                if exists == true then
                    feat.on = val
                end
            end
        end

        local exists, val = INI:get_f("Floats", "max_dist")
        if exists == true then
            _FMAP["max_dist"].value = val
        end
        menu.notify("Settings successfully loaded and applied.", SCRIPT_TITLE, 6, COLOR.GREEN)
    end
end

local function save_settings()
    for key, feat in pairs(_FMAP) do
        if key ~= "max_dist" then -- pathetic
            INI:set_b("Toggles", key, feat.on)
        end
    end
    INI:set_f("Floats", "max_dist", _FMAP["max_dist"].value)
    INI:write()
    menu.notify("Settings successfully saved.", SCRIPT_TITLE, 6, COLOR.GREEN)
end

---- Load settings for the specific feature
--local function get_feature_setting_value(featName, section)
--    local type_map = {Toggles = "b", Integers = "i", Floats = "f", Strings = "s"}
--    local _type = type_map[section]
--    if _type and INI:read() then
--        local exists, val = INI["get_" .. _type](INI, section, featName)
--        if exists == true then
--            print(featName .. ":" .. tostring(val))
--            return val
--        end
--    end
--end

local function create_obj_feat(featName, featData_Table, parentFeat)
    local function init_feat_data()
        local initializedFeatData = {}
        for objectHashName, objectProperties_Table in pairs(featData_Table) do
            if not objectProperties_Table.color then
                objectProperties_Table.color = COLOR.DEFAULT
            end
            initializedFeatData[gameplay.get_hash_key(objectHashName)] = objectProperties_Table
        end
        return initializedFeatData
    end

    local initializedFeatData = init_feat_data()

    local feat = menu.add_feature(featName, "toggle", parentFeat.id, function(feat)
        if feat.on then
            for objectHash, objectProperties_Table in pairs(feat.data) do
                _CMAP[objectHash] = objectProperties_Table
            end
        else
            for objectHash, objectProperties_Table in pairs(feat.data) do
                _CMAP[objectHash] = nil
            end
        end
    end)

    feat.data = initializedFeatData
    _FMAP["obj_set_" .. featName:gsub('%W','')] = feat
    return feat
end

local function is_session_transition_active()
    return NATIVES.SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(gameplay.get_hash_key("maintransition")) > 0
end

local function is_session_started(params)
    params = params or {}
    if params.hasTransitionFinished == nil then
        params.hasTransitionFinished = false
    end

    return (
        network.is_session_started() and player.get_host() ~= -1
        and (not params.hasTransitionFinished or not is_session_transition_active()) -- Optional check
    )
end
---- Global functions 2/2 END

---- Global event listeners START
scriptExit_EventListener = event.add_event_listener("exit", function()
    handle_script_exit()
end)
---- Global event listeners END
-- Globals END


-- Permissions Startup Checking START
local unnecessaryPermissions = {}
local missingPermissions = {}

for _, flag in ipairs(TRUSTED_FLAGS) do
    if menu.is_trusted_mode_enabled(flag.bitValue) then
        if not flag.isRequiered then
            table.insert(unnecessaryPermissions, flag.menuName)
        end
    else
        if flag.isRequiered then
            table.insert(missingPermissions, flag.menuName)
        end
    end
end

if #unnecessaryPermissions > 0 then
    menu.notify("You do not require the following " .. pluralize("permission", #unnecessaryPermissions) .. ":\n" .. table.concat(unnecessaryPermissions, "\n"),
        SCRIPT_NAME, 6, COLOR.ORANGE)
end
if #missingPermissions > 0 then
    menu.notify(
        "You need to enable the following " .. pluralize("permission", #missingPermissions) .. ":\n" .. table.concat(missingPermissions, "\n"),
        SCRIPT_NAME, 6, COLOR.RED)
    handle_script_exit()
end
-- Permissions Startup Checking END


-- === Main Menu Features === --
local myRootMenu_Feat = menu.add_feature(SCRIPT_TITLE, "parent", 0)

_FMAP["enable"] = menu.add_feature("Enable Object ESP", "toggle", myRootMenu_Feat.id, function(feat)
    while feat.on do
        system.yield()

        DRAW(_FMAP["max_dist"].value, _CMAP)
    end
end)

-- === Settings === --
local settingsMenu_Feat = menu.add_feature("Settings", "parent", myRootMenu_Feat.id)

_FMAP["max_dist"] = menu.add_feature("Max Distance", "autoaction_value_i", settingsMenu_Feat.id)
_FMAP["max_dist"].min = 45.0
_FMAP["max_dist"].max = 500.0
_FMAP["max_dist"].mod = 5.0
_FMAP["max_dist"].hint = "The maximum distance for rendering ESP when an object is detected."

_FMAP["ipl_precision"] = menu.add_feature("IPL Precision", "toggle", settingsMenu_Feat.id)
_FMAP["ipl_precision"].hint = 'This setting hides objects that should only be visible in their designated IPL locations, like the "Buried Stash" in Cayo Perico. It ensures that ESP only displays these objects in their intended IPL locations.'

local loadSettings_Feat = menu.add_feature("Load Settings", "action", settingsMenu_Feat.id, function()
    load_settings()
end)
loadSettings_Feat.hint = 'Load saved settings from your file: "' .. HOME_PATH .. "\\" .. SCRIPT_SETTINGS__PATH .. '".\n\nDeleting this file will apply the default settings.'

local saveSettings_Feat = menu.add_feature("Save Settings", "action", settingsMenu_Feat.id, function()
    save_settings()
end)
saveSettings_Feat.hint = 'Save your current settings to the file: "' .. HOME_PATH .. "\\" .. SCRIPT_SETTINGS__PATH .. '".'


menu.add_feature("<- - - - - - - - -  Object ESPs  - - - - - - - - ->", "action", myRootMenu_Feat.id)

-- === Collectibles === --
local collectiblesMenu_Feat = menu.add_feature("Collectibles", "parent", myRootMenu_Feat.id)

-- === Collectibles > Grand Theft Auto V === --
local collectiblesVMenu_Feat = menu.add_feature("Grand Theft Auto V", "parent", collectiblesMenu_Feat.id)
create_obj_feat("Letter Scraps", {
    ["prop_ld_scrap"] = {label = "Letter Scrap"},
}, collectiblesVMenu_Feat)
create_obj_feat("Spaceship Parts", {
    ["prop_power_cell"]         = {label = "Spaceship Part", color = COLOR.COLLECTIBLE},
    ["sum_prop_sum_power_cell"] = {label = "Spaceship Part - Not Sure (sum_prop_sum_power_cell)", color = COLOR.COLLECTIBLE},
    ["prop_cs_power_cell"]      = {label = "Spaceship Part - Not Sure (prop_cs_power_cell)", color = COLOR.COLLECTIBLE},
}, collectiblesVMenu_Feat)
create_obj_feat("Submarine Pieces", {
    ["prop_sub_chunk_01"] = {label = "Submarine Piece", color = COLOR.COLLECTIBLE},
}, collectiblesVMenu_Feat)
create_obj_feat("Nuclear Waste", {
    ["prop_rad_waste_barrel_01"] = {label = "Nuclear Waste", color = COLOR.COLLECTIBLE},
}, collectiblesVMenu_Feat)
create_obj_feat("Epsilon Tracts", {
    ["prop_time_capsule_01"] = {label = "Epsilon Tract", color = COLOR.COLLECTIBLE},
}, collectiblesVMenu_Feat)
create_obj_feat("Hidden Packages (Briefcase)", {
    ["prop_security_case_01"] = {label = "Hidden Package (Briefcase)", color = COLOR.COLLECTIBLE},
}, collectiblesVMenu_Feat)
-- TODO: Rampages - I think it would be pointless considering the effort required to add all of them peds.
-- TODO: Monkey Mosaics - not sure if they are entitys or not, at first simple test: nope.
--[[ It's probably because the script is called "Object" and not "Ped/Entities" ESP. The way anonymouspleb coded it, the following animals don't show up in the ESP.
create_obj_feat("Wildlife Photographs", {
    ["a_c_husky"]       = {label = "Wildlife Photograph (Dog: Husky)", color = COLOR.COLLECTIBLE},
    ["a_c_poodle"]      = {label = "Wildlife Photograph (Dog: Poodle)", color = COLOR.COLLECTIBLE},
    ["a_c_pug"]         = {label = "Wildlife Photograph (Dog: Pug)", color = COLOR.COLLECTIBLE},
    ["a_c_retriever"]   = {label = "Wildlife Photograph (Dog: Golden Retriever)", color = COLOR.COLLECTIBLE},
    ["a_c_rottweiler"]  = {label = "Wildlife Photograph (Dog: Rottweiler)", color = COLOR.COLLECTIBLE},
    ["a_c_chop"]        = {label = "Wildlife Photograph (Dog: Chop)", color = COLOR.COLLECTIBLE},
    ["a_c_shepherd"]    = {label = "Wildlife Photograph (Dog: English Shepherd)", color = COLOR.COLLECTIBLE},
    ["a_c_westy"]       = {label = "Wildlife Photograph (Dog: Westy)", color = COLOR.COLLECTIBLE},
    ["a_c_chickenhawk"] = {label = "Wildlife Photograph (Bird: Chicken Hawk)", color = COLOR.COLLECTIBLE},
    ["a_c_cormorant"]   = {label = "Wildlife Photograph (Bird: Great Cormorant)", color = COLOR.COLLECTIBLE},
    ["a_c_crow"]        = {label = "Wildlife Photograph (Bird: Crow)", color = COLOR.COLLECTIBLE},
    ["a_c_hen"]         = {label = "Wildlife Photograph (Bird: Hen)", color = COLOR.COLLECTIBLE},
    ["a_c_seagull"]     = {label = "Wildlife Photograph (Bird: Seagull)", color = COLOR.COLLECTIBLE},
    ["a_c_boar"]        = {label = "Wildlife Photograph (Boar)", color = COLOR.COLLECTIBLE},
    ["a_c_cat_01"]      = {label = "Wildlife Photograph (Cat)", color = COLOR.COLLECTIBLE},
    ["a_c_cow"]         = {label = "Wildlife Photograph (Cow)", color = COLOR.COLLECTIBLE},
    ["a_c_coyote"]      = {label = "Wildlife Photograph (Coyote)", color = COLOR.COLLECTIBLE},
    ["a_c_deer"]        = {label = "Wildlife Photograph (Deer)", color = COLOR.COLLECTIBLE},
    ["a_c_mtlion"]      = {label = "Wildlife Photograph (Mountain Lion)", color = COLOR.COLLECTIBLE},
    ["a_c_pig"]         = {label = "Wildlife Photograph (Pig)", color = COLOR.COLLECTIBLE},
    ["a_c_rabbit_01"]   = {label = "Wildlife Photograph (Rabbit)", color = COLOR.COLLECTIBLE},

}, collectiblesVMenu_Feat)
]]

-- === Collectibles > Grand Theft Auto Online === --
local collectiblesOnlineMenu_Feat = menu.add_feature("Grand Theft Auto Online", "parent", collectiblesMenu_Feat.id)

-- === Collectibles > Grand Theft Auto Online > One Time Collections === --
local oneTimecollectionsOnlineMenu_Feat = menu.add_feature("One Time Collections", "parent", collectiblesOnlineMenu_Feat.id)
create_obj_feat("Action Figures", {
    ["vw_prop_vw_colle_alien"]      = {label = "Action Figure: Alien", color = COLOR.COLLECTIBLE},
    ["vw_prop_vw_colle_beast"]      = {label = "Action Figure: Beast", color = COLOR.COLLECTIBLE},
    ["vw_prop_vw_colle_imporage"]   = {label = "Action Figure: Impotent Rage", color = COLOR.COLLECTIBLE},
    ["vw_prop_vw_colle_pogo"]       = {label = "Action Figure: Pogo", color = COLOR.COLLECTIBLE},
    ["vw_prop_vw_colle_prbubble"]   = {label = "Action Figure: Princess Robot Bubblegum", color = COLOR.COLLECTIBLE},
    ["vw_prop_vw_colle_rsrcomm"]    = {label = "Action Figure: Republican Space Ranger (Commander)", color = COLOR.COLLECTIBLE},
    ["vw_prop_vw_colle_rsrgeneric"] = {label = "Action Figure: Republican Space Ranger (Generic)", color = COLOR.COLLECTIBLE},
    ["vw_prop_vw_colle_sasquatch"]  = {label = "Action Figure: Sasquatch (Bigfoot)", color = COLOR.COLLECTIBLE},
}, oneTimecollectionsOnlineMenu_Feat)
create_obj_feat("Ghosts Exposed", {
    ["m23_1_prop_m31_ghostrurmeth_01a"]  = {label = "Ghost Exposed (Rurmeth)", color = COLOR.COLLECTIBLE},
    ["m23_1_prop_m31_ghostskidrow_01a"]  = {label = "Ghost Exposed (Skidrow)", color = COLOR.COLLECTIBLE},
    ["m23_1_prop_m31_ghostzombie_01a"]   = {label = "Ghost Exposed (Zombie)", color = COLOR.COLLECTIBLE},
    ["m23_1_prop_m31_ghostsalton_01a"]   = {label = "Ghost Exposed (Salton)", color = COLOR.COLLECTIBLE},
    ["m23_1_prop_m31_ghostjohnny_01a"]   = {label = "Ghost Exposed (Johnny Klebitz)", color = COLOR.COLLECTIBLE},
    --[[ At this time I'm writing this, these are in the game files but not in "Ghosts Exposed" yet.
        ["m24_1_prop_m41_ghost_cop_01a"] = {label = "Ghost (Cop)", color = COLOR.COLLECTIBLE},
        ["m24_1_prop_m41_ghost_dom_01a"] = {label = "Ghost (Dom)", color = COLOR.COLLECTIBLE},
    --]]
}, oneTimecollectionsOnlineMenu_Feat)
create_obj_feat("LD Organics Product", {
    ["reh_prop_reh_bag_weed_01a"] = {label = "LD Organics Product", color = COLOR.COLLECTIBLE},
}, oneTimecollectionsOnlineMenu_Feat)
create_obj_feat("Movie Props", {
    ["sum_prop_ac_filmreel_01a"]     = {label = "Movie Prop #1: Meltdown Film Reel", color = COLOR.COLLECTIBLE},
    ["sum_prop_ac_wifaaward_01a"]    = {label = "Movie Prop #2: WIFA Award", color = COLOR.COLLECTIBLE},
    ["sum_prop_ac_headdress_01a"]    = {label = "Movie Prop #3: Indian Headdress", color = COLOR.COLLECTIBLE},
    ["sum_prop_ac_alienhead_01a"]    = {label = "Movie Prop #4: Alien Head", color = COLOR.COLLECTIBLE},
    ["sum_prop_ac_mummyhead_01a"]    = {label = "Movie Prop #5: Mummy Head", color = COLOR.COLLECTIBLE},
    ["sum_prop_ac_clapperboard_01a"] = {label = "Movie Prop #6: Clapperboard", color = COLOR.COLLECTIBLE},
    ["sum_prop_ac_monstermask_01a"]  = {label = "Movie Prop #7: Monster Mask", color = COLOR.COLLECTIBLE},
    ["sum_prop_ac_tigerrug_01a"]     = {label = "Movie Prop #8: Tiger Rug", color = COLOR.COLLECTIBLE},
    ["sum_prop_ac_sarcophagus_01a"]  = {label = "Movie Prop #9: Sarcophagus", color = COLOR.COLLECTIBLE},
    ["sum_prop_ac_drinkglobe_01a"]   = {label = "Movie Prop #10: Globe", color = COLOR.COLLECTIBLE},
}, oneTimecollectionsOnlineMenu_Feat)
create_obj_feat("Playing Cards", {
    ["vw_prop_vw_lux_card_01a"] = {label = "Playing Card", color = COLOR.COLLECTIBLE},
}, oneTimecollectionsOnlineMenu_Feat)
create_obj_feat("Signal Jammer", {
    ["ch_prop_ch_mobile_jammer_01x"] = {label = "Signal Jammer", color = COLOR.COLLECTIBLE},
}, oneTimecollectionsOnlineMenu_Feat)
create_obj_feat("Snowmen", {
    ["xm3_prop_xm3_snowman_01a"] = {label = "Snowman", color = COLOR.COLLECTIBLE},
    ["xm3_prop_xm3_snowman_01b"] = {label = "Snowman", color = COLOR.COLLECTIBLE},
    ["xm3_prop_xm3_snowman_01c"] = {label = "Snowman", color = COLOR.COLLECTIBLE},
}, oneTimecollectionsOnlineMenu_Feat)
create_obj_feat("Media Sticks", {
    ["sf_prop_sf_usb_drive_01a"] = {label = "Media Stick (Record A Studio)", color = COLOR.COLLECTIBLE},
    ["tr_prop_tr_usb_drive_02a"] = {label = "Media Stick (CircoLoco Records)", color = COLOR.COLLECTIBLE},
}, oneTimecollectionsOnlineMenu_Feat)

-- === Daily Collectibles === --
local dailyCollectiblesOnlineMenu_Feat = menu.add_feature("Daily Collectibles", "parent", collectiblesOnlineMenu_Feat.id)

-- === Collectibles > Grand Theft Auto Online > Seasonal Daily Collectibles === --
local seasonalDailyCollectiblesOnlineMenu_Feat = menu.add_feature("Seasonal Daily Collectibles", "parent", dailyCollectiblesOnlineMenu_Feat.id)
create_obj_feat("Trick Or Treat (Jack O' Lanterns)", {
    ["reh_prop_reh_lantern_pk_01a"] = {label = "Jack O' Lantern", color = COLOR.COLLECTIBLE},
    ["reh_prop_reh_lantern_pk_01b"] = {label = "Jack O' Lantern", color = COLOR.COLLECTIBLE},
    ["reh_prop_reh_lantern_pk_01c"] = {label = "Jack O' Lantern", color = COLOR.COLLECTIBLE},
}, seasonalDailyCollectiblesOnlineMenu_Feat)

-- === Collectibles > Grand Theft Auto Online > Daily Collectibles === --
create_obj_feat("Buried Stash", {
    ["tr_prop_tr_sand_01a"] = {label = "Buried Stash", color = COLOR.COLLECTIBLE, IPL = "Cayo Perico"},
}, dailyCollectiblesOnlineMenu_Feat)
create_obj_feat("Hidden Caches", {
    ["h4_prop_h4_box_ammo_02a"] = {label = "Hidden Cache", color = COLOR.COLLECTIBLE},
}, dailyCollectiblesOnlineMenu_Feat)
--[[ Too useless, it's showing up on the pause map.
create_obj_feat("Junk Energy Skydives", {
    ["reh_prop_reh_cabine_01a"] = {label = "Junk Energy Skydive", color = COLOR.COLLECTIBLE},
    ["reh_prop_reh_bag_para_01a"] = {label = "Junk Energy Skydive", color = COLOR.COLLECTIBLE},
}, dailyCollectiblesOnlineMenu_Feat)
]]
create_obj_feat("Shipwreck Chests", {
    ["tr_prop_tr_chest_01a"] = {label = "Shipwreck Chest", color = COLOR.COLLECTIBLE},
}, dailyCollectiblesOnlineMenu_Feat)
create_obj_feat("Treasure Chests", {
    ["h4_prop_h4_chest_01a"]      = {label = "Treasure Chest", color = COLOR.COLLECTIBLE},
}, dailyCollectiblesOnlineMenu_Feat)
create_obj_feat("LS Tags", {
    ["m24_1_prop_m41_bdgr_pstr_01a"]   = {label = "LS Tag", color = COLOR.COLLECTIBLE},
    ["m24_1_prop_m41_cnt_pstr_01a"]    = {label = "LS Tag", color = COLOR.COLLECTIBLE},
    ["m24_1_prop_m41_dg_pstr_01a"]     = {label = "LS Tag", color = COLOR.COLLECTIBLE},
    ["m24_1_prop_m41_life_pstr_01a"]   = {label = "LS Tag", color = COLOR.COLLECTIBLE},
    ["m24_1_prop_m41_weazel_pstr_01a"] = {label = "LS Tag", color = COLOR.COLLECTIBLE},
}, dailyCollectiblesOnlineMenu_Feat)
create_obj_feat("Spray Can Crate", {
    ["m24_1_prop_m41_crate_spraycan_01a"] = {label = "Spray Can Crate", color = COLOR.COLLECTIBLE},
    --["m24_1_prop_m41_spraycan_01a"]     = {label = "Spray Can", color = COLOR.COLLECTIBLE},
}, dailyCollectiblesOnlineMenu_Feat)
create_obj_feat("G's Cache", {
    ["prop_mp_drug_pack_blue"] = {label = "G's Cache", color = COLOR.COLLECTIBLE},
    ["prop_mp_drug_pack_red"]  = {label = "G's Cache", color = COLOR.COLLECTIBLE},
    ["prop_mp_drug_package"]   = {label = "G's Cache", color = COLOR.COLLECTIBLE},
}, dailyCollectiblesOnlineMenu_Feat)
create_obj_feat("Stash Houses (Safe, Safe Code)", {
    ["xm3_prop_xm3_safe_01a"]      = {label = "Safe", color = COLOR.COLLECTIBLE},
    ["xm3_prop_xm3_code_01_23_45"] = {label = "Safe Code (post-it note)", color = COLOR.COLLECTIBLE},
    ["xm3_prop_xm3_code_02_12_87"] = {label = "Safe Code (post-it note)", color = COLOR.COLLECTIBLE},
    ["xm3_prop_xm3_code_05_02_91"] = {label = "Safe Code (post-it note)", color = COLOR.COLLECTIBLE},
    ["xm3_prop_xm3_code_24_10_81"] = {label = "Safe Code (post-it note)", color = COLOR.COLLECTIBLE},
    ["xm3_prop_xm3_code_28_03_98"] = {label = "Safe Code (post-it note)", color = COLOR.COLLECTIBLE},
    ["xm3_prop_xm3_code_28_11_97"] = {label = "Safe Code (post-it note)", color = COLOR.COLLECTIBLE},
    ["xm3_prop_xm3_code_44_23_37"] = {label = "Safe Code (post-it note)", color = COLOR.COLLECTIBLE},
    ["xm3_prop_xm3_code_72_68_83"] = {label = "Safe Code (post-it note)", color = COLOR.COLLECTIBLE},
    ["xm3_prop_xm3_code_73_27_38"] = {label = "Safe Code (post-it note)", color = COLOR.COLLECTIBLE},
    ["xm3_prop_xm3_code_77_79_73"] = {label = "Safe Code (post-it note)", color = COLOR.COLLECTIBLE},
}, dailyCollectiblesOnlineMenu_Feat)

-- === Collectibles > Both of Them === --
menu.add_feature("<- - - - - - -  Both of Them  - - - - - - ->", "action", collectiblesMenu_Feat.id)
create_obj_feat("Peyotes", {
    -- (story mode) peyotes
    ["prop_peyote_gold_01"]     = {label = "Peyote Gold", color = COLOR.COLLECTIBLE},
    ["prop_peyote_lowland_01"]  = {label = "Peyote Lowland 1", color = COLOR.COLLECTIBLE},
    ["prop_peyote_lowland_02"]  = {label = "Peyote Lowland 2", color = COLOR.COLLECTIBLE},
    ["prop_peyote_water_01"]    = {label = "Peyote Water", color = COLOR.COLLECTIBLE},
    -- halloween event
    ["prop_peyote_highland_01"] = {label = "Peyote Highland 1", color = COLOR.COLLECTIBLE},
    ["prop_peyote_highland_02"] = {label = "Peyote Highland 2", color = COLOR.COLLECTIBLE},
}, collectiblesMenu_Feat)
--[[ So much false positives I prefer to comment this only one ...
create_obj_feat("Stunt Jumps", {
    ["prop_skip_08a"] = {label = "Stunt Jump", color = COLOR.COLLECTIBLE},
}, collectiblesMenu_Feat)
]]

-- === Random Events === --
local randomEventsMenu_Feat = menu.add_feature("Random Events", "parent", myRootMenu_Feat.id)

-- === Random Events > Grand Theft Auto Online === --
local randomEventsOnlineMenu_Feat = menu.add_feature("Grand Theft Auto Online", "parent", randomEventsMenu_Feat.id)

-- === Random Events > Grand Theft Auto Online > Seasonal Random Events === --
--[[ It's probably because the script is called "Object" and not "Ped/Entities" ESP. The way anonymouspleb coded it, the following animals don't show up in the ESP.
local seasonalrandomEventsOnlineMenu_Feat = menu.add_feature("Seasonal Random Events", "parent", randomEventsOnlineMenu_Feat.id)
create_obj_feat("Possessed Animals", {
    ["a_c_boar_02"]   = {label = "Possessed Animal", color = COLOR.ENNEMY},
    ["a_c_coyote_02"] = {label = "Possessed Animal", color = COLOR.ENNEMY},
    ["a_c_deer_02"]   = {label = "Possessed Animal", color = COLOR.ENNEMY},
    ["a_c_mtlion_02"] = {label = "Possessed Animal", color = COLOR.ENNEMY},
    ["a_c_pug_02"]    = {label = "Possessed Animal", color = COLOR.ENNEMY},
}, seasonalrandomEventsOnlineMenu_Feat)
--]]

-- === Random Events > Grand Theft Auto Online === --
--[[ It's probably because the script is called "Object" and not "Ped/Entities" ESP. The way anonymouspleb coded it, the following animals don't show up in the ESP.
create_obj_feat("Police Rescue (Transporter)", {
    ["policet"] = {label = "Police Transporter", color = COLOR.COLLECTIBLE},
}, randomEventsOnlineMenu_Feat)
--]]
create_obj_feat("Skeleton", {
    ["reh_prop_reh_skeleton_01a"] = {label = "Skeleton", color = COLOR.COLLECTIBLE},
}, randomEventsOnlineMenu_Feat)
create_obj_feat("Smuggler Plane", {
    ["prop_security_case_01"] = {label = "Smuggler Cache (Briefcase)", color = COLOR.COLLECTIBLE},
}, randomEventsOnlineMenu_Feat)
create_obj_feat("Smuggler Cache", {
    ["prop_flare_01"]               = {label = "Smuggler Flare", color = COLOR.COLLECTIBLE},
    ["sm_prop_smug_rsply_crate01a"] = {label = "Smuggler Cache - Not Sure (sm_prop_smug_rsply_crate01a)", color = COLOR.COLLECTIBLE},
    ["sm_prop_smug_rsply_crate02a"] = {label = "Smuggler Cache", color = COLOR.COLLECTIBLE},
}, randomEventsOnlineMenu_Feat)
create_obj_feat("Crime Scenes", {
    ["prop_cash_case_02"]            = {label = "Crime Scene (Briefcase)", color = COLOR.COLLECTIBLE},
    ["reh_prop_reh_sp_stock_01a"]    = {label = "Weapon Component (stock)", color = COLOR.COLLECTIBLE},
    ["reh_prop_reh_sp_mag_01a"]      = {label = "Weapon Component (mag)", color = COLOR.COLLECTIBLE},
    ["reh_prop_reh_sp_sights_01a"]   = {label = "Weapon Component (sights)", color = COLOR.COLLECTIBLE},
    ["reh_prop_reh_sp_barrel_01a"]   = {label = "Weapon Component (barrel)", color = COLOR.COLLECTIBLE},
    ["reh_prop_reh_sp_receiver_01a"] = {label = "Weapon Component (receiver)", color = COLOR.COLLECTIBLE},
}, randomEventsOnlineMenu_Feat)
-- TODO: Shop Robbery
create_obj_feat("Armored Trucks (Security Case)", {
    -- ["stockade"] = {label = "Armored Truck", color = COLOR.COLLECTIBLE}, -- It's probably because the script is called "Object" and not "Ped/Entities" ESP. The way anonymouspleb coded it, the following animals don't show up in the ESP.
    ["m23_1_prop_m31_cashbox_01a"] = {label = "Armored Truck (Security Case)", color = COLOR.COLLECTIBLE},
}, randomEventsOnlineMenu_Feat)

-- === Missions Helper === --
local missionsHelperMenu_Feat = menu.add_feature("Missions Helper", "parent", myRootMenu_Feat.id)

-- === Missions Helper > Grand Theft Auto Online === --
local missionsHelperOnlineMenu_Feat = menu.add_feature("Grand Theft Auto Online", "parent", missionsHelperMenu_Feat.id)

-- === Missions Helper > Grand Theft Auto Online > Freemode Side Missions === --
local freemodeSideMissionsHelperOnlineMenu_Feat = menu.add_feature("Freemode Side Missions", "parent", missionsHelperOnlineMenu_Feat.id)
create_obj_feat("Gang Attacks (Weapon Crates)", {
    ["prop_box_wood02a_pu"]  = {label = "Weapon Crate"},
    ["prop_box_wood02a_mws"] = {label = "Weapon Crate (Merryweather)"},
}, freemodeSideMissionsHelperOnlineMenu_Feat)

-- === Missions Helper > Grand Theft Auto Online === --
create_obj_feat("The Cayo Perico Heist/Preparations", {
    ["h4_prop_h4_cash_stack_01a"]   = {label = "Cash", color = COLOR.COLLECTIBLE, IPL = "Cayo Perico"},
    ["h4_prop_h4_coke_stack_01a"]   = {label = "Coke", color = COLOR.COLLECTIBLE, IPL = "Cayo Perico"},
    ["h4_prop_h4_weed_stack_01a"]   = {label = "Weed", color = COLOR.COLLECTIBLE, IPL = "Cayo Perico"},
    ["h4_prop_h4_gold_stack_01a"]   = {label = "Gold", color = COLOR.COLLECTIBLE, IPL = "Cayo Perico"},
    ["h4_prop_h4_painting_01a"]     = {label = "Painting", color = COLOR.COLLECTIBLE, IPL = "Cayo Perico"},
    ["h4_prop_h4_painting_01b"]     = {label = "Painting", color = COLOR.COLLECTIBLE, IPL = "Cayo Perico"},
    ["h4_prop_h4_painting_01c"]     = {label = "Painting", color = COLOR.COLLECTIBLE, IPL = "Cayo Perico"},
    ["h4_prop_h4_painting_01d"]     = {label = "Painting", color = COLOR.COLLECTIBLE, IPL = "Cayo Perico"},
    ["h4_prop_h4_painting_01e"]     = {label = "Painting", color = COLOR.COLLECTIBLE, IPL = "Cayo Perico"},
    ["h4_prop_h4_painting_01f"]     = {label = "Painting", color = COLOR.COLLECTIBLE, IPL = "Cayo Perico"},
    ["h4_prop_h4_painting_01g"]     = {label = "Painting", color = COLOR.COLLECTIBLE, IPL = "Cayo Perico"},
    ["h4_prop_h4_painting_01h"]     = {label = "Painting", color = COLOR.COLLECTIBLE, IPL = "Cayo Perico"},
    ["h4_prop_door_safe_01"]        = {label = "El Rubio's Safe", color = COLOR.COLLECTIBLE, IPL = "Cayo Perico"},
    ["h4_prop_h4_bag_hook_01a"]     = {label = "Hook", color = COLOR.PICKUP, IPL = "Cayo Perico"},
    ["h4_prop_h4_bolt_cutter_01a"]  = {label = "Bolt Cutter", color = COLOR.PICKUP, IPL = "Cayo Perico"},
    ["h4_prop_h4_card_hack_01a"]    = {label = "Fingerprint Cloner", color = COLOR.PICKUP, IPL = "Cayo Perico"},
    ["h4_prop_h4_crate_cloth_01a"]  = {label = "Clothes", color = COLOR.PICKUP, IPL = "Cayo Perico"},
    ["h4_prop_h4_elecbox_01a"]      = {label = "Electrical Box", color = COLOR.PICKUP, IPL = "Cayo Perico"},
    ["h4_prop_h4_gascutter_01a"]    = {label = "Cutter", color = COLOR.PICKUP, IPL = "Cayo Perico"},
    ["h4_prop_h4_jammer_01a"]       = {label = "Sonar Jammer", color = COLOR.PICKUP, IPL = "Cayo Perico"},
    ["h4_prop_h4_securitycard_01a"] = {label = "Keycard", color = COLOR.PICKUP, IPL = "Cayo Perico"},
    ["h4_prop_h4_loch_monster"]     = {label = "Nessy", color = COLOR.RED, IPL = "Cayo Perico"},
}, missionsHelperOnlineMenu_Feat)
create_obj_feat("Agent ULP (U.L. Paper) - Operation Paper Trail", {
    ["h4_prop_h4_securitycard_01a"] = {label = "Elevator Keycard", color = COLOR.PICKUP},
    --["ig_agent_02"]                = {label = "Agent Johnson"}, -- It's probably because the script is called "Object" and not "Ped/Entities" ESP. The way anonymouspleb coded it, the following animals don't show up in the ESP.
    ["reh_prop_reh_box_metal_01a"]   = {label = "AI Hardware"},
    ["reh_prop_reh_desk_comp_01a"]   = {label = "Mason Duggan's computer"},
    ["reh_prop_reh_drone_02a"]       = {label = "Drone"},
    ["reh_prop_reh_folder_01b"]      = {label = "Clues (folder)"},
    ["reh_prop_reh_gadget_01a"]      = {label = "USB Drive"},
    ["reh_prop_reh_glasses_smt_01a"] = {label = "VR Headset"},
    ["reh_prop_reh_harddisk_01a"]    = {label = "Hard Drive"},
    ["reh_prop_reh_tablet_01a"]      = {label = "Tablet"},
    ["tr_prop_tr_fuse_box_01a"]      = {label = "Fusebox"},
    ["prop_security_case_01"]        = {label = "Briefcase", color = COLOR.PICKUP},
}, missionsHelperOnlineMenu_Feat)
create_obj_feat("ULP Fuses", {
    ["reh_prop_reh_fuse_01a"] = {label = "Fuse"},
}, missionsHelperOnlineMenu_Feat)
--[[ It's probably because the script is called "Object" and not "Ped/Entities" ESP. The way anonymouspleb coded it, the following animals don't show up in the ESP.
create_obj_feat("Madrazo Hits", {
    ["a_m_m_genbiker_01"]  = {label = "Madrazo Hit", color = COLOR.ENNEMY},
    ["g_f_y_families_01"]  = {label = "Madrazo Hit", color = COLOR.ENNEMY},
    ["g_m_m_armlieut_01"]  = {label = "Madrazo Hit", color = COLOR.ENNEMY},
    ["g_m_y_salvaboss_01"] = {label = "Madrazo Hit", color = COLOR.ENNEMY},
    ["s_m_m_ccrew_03"]     = {label = "Madrazo Hit", color = COLOR.ENNEMY},
}, missionsHelperOnlineMenu_Feat)
--]]
create_obj_feat("Agency Security Contracts", {
    ["sf_prop_sf_codes_01a"]       = {label = "Safe Code (post-it note)"},
    ["sf_prop_sf_crate_jugs_01a"]  = {label = "Moonshine"},
    ["sf_prop_v_43_safe_s_bk_01a"] = {label = "Safe"},
    ["vw_prop_vw_key_cabinet_01a"] = {label = "Key Cabinet"},
}, missionsHelperOnlineMenu_Feat)
create_obj_feat("Special Cargos", {
    ["ex_prop_adv_case_sm_02"]    = {label = "Special Cargo"},
    ["ex_prop_adv_case_sm_03"]    = {label = "Special Cargo"},
    ["ex_prop_adv_case_sm_flash"] = {label = "Special Cargo"},
    ["ex_prop_adv_case_sm"]       = {label = "Special Cargo"},
    ["ex_prop_adv_case"]          = {label = "Special Cargo"},
}, missionsHelperOnlineMenu_Feat)
create_obj_feat("Freakshop Missions", {
    ["xm3_prop_xm3_drug_pkg_01a"] = {label = "Meth"},
}, missionsHelperOnlineMenu_Feat)
create_obj_feat("Security Devices (Keypads, Fingerprints, ...)", {
    --["ch_prop_casino_keypad_01"]            = {label = "Keypad c844a6e2"},
    --["ch_prop_casino_keypad_02"]            = {label = "Keypad b662031d"},
    --["ch_prop_ch_usb_drive01x"]               = {label = "Security Scanner"},
    ["ch_prop_fingerprint_damaged_01"]        = {label = "Fingerprint Scanner"},
    --["ch_prop_fingerprint_scanner_01a"]     = {label = "Fingerprint Scanner (Casino)"},
    ["ch_prop_fingerprint_scanner_01b"]       = {label = "Fingerprint Scanner"},
    ["ch_prop_fingerprint_scanner_01c"]       = {label = "Fingerprint Scanner"},
    ["ch_prop_fingerprint_scanner_01d"]       = {label = "Fingerprint Scanner"},
    ["ch_prop_fingerprint_scanner_01e"]       = {label = "Fingerprint Scanner"},
    ["ch_prop_fingerprint_scanner_error_01b"] = {label = "Fingerprint Scanner"},
    ["h4_prop_h4_fingerkeypad_01a"]           = {label = "Keypad (to hack)", color = COLOR.HACKABLE}, -- It's probably one of the two but idk which one exactly.
    ["h4_prop_h4_fingerkeypad_01b"]           = {label = "Keypad (to hack)", color = COLOR.HACKABLE}, -- It's probably one of the two but idk which one exactly.
    --["h4_prop_h4_ld_keypad_01"]             = {label = "Keypad e8c9c338"},
    --["h4_prop_h4_ld_keypad_01b"]            = {label = "Keypad 7e417fdc"},
    --["h4_prop_h4_ld_keypad_01c"]            = {label = "Keypad 477f1258"},
    --["h4_prop_h4_ld_keypad_01d"]            = {label = "Keypad 2284c864"},
    --["hei_prop_hei_keypad_01"]              = {label = "Keypad 81784f01"},
    --["hei_prop_hei_keypad_02"]              = {label = "Keypad ac38a485"},
    --["hei_prop_hei_keypad_03"]              = {label = "Keypad 9d110636"},
    --["hei_prop_hei_securitypanel"]          = {label = "Security Panel hei_prop_hei_securitypanel"},
    --["m23_1_prop_m31_keypad_01a"]           = {label = "Keypad 686d262e"},
    ["m24_1_prop_m41_electricbox_01a"]        = {label = "Tower (to hack)"},
    ["m24_1_prop_m41_server_01a"]             = {label = "Server (to hack)"},
    --["prop_ld_keypad_01"]                   = {label = "Keypad prop_ld_keypad_01"},
    --["prop_ld_keypad_01b_lod"]              = {label = "Keypad 10856e55"},
    --["prop_ld_keypad_01b"]                  = {label = "Keypad 25286eb9"},
    --["reh_prop_reh_keypad_01a"]             = {label = "Keypad 2f85dbc7"},
    ["tr_prop_tr_fp_scanner_01a"]             = {label = "Fingerprint Scanner (to hack)"},
    --["v_41_keypad"]                         = {label = "Keypad d24b5e26"},
    --["vw_prop_casino_keypad_01"]            = {label = "Keypad 69bfee35"},
    --["vw_prop_casino_keypad_02"]            = {label = "Keypad 53e9c289"},
    --["xm_int_lev_silo_keypad_01"]           = {label = "Keypad 99a8865c"},
}, missionsHelperOnlineMenu_Feat)
create_obj_feat("Laptops", {
    ["as_prop_as_laptop_01a"]         = {label = "Laptop"},
    ["ba_prop_battle_laptop_dj"]      = {label = "Laptop"},
    ["ba_prop_club_laptop_dj_02"]     = {label = "Laptop"},
    ["ba_prop_club_laptop_dj"]        = {label = "Laptop"},
    ["bkr_prop_clubhouse_laptop_01a"] = {label = "Laptop"},
    ["bkr_prop_clubhouse_laptop_01b"] = {label = "Laptop"},
    ["bkr_ware05_laptop"]             = {label = "Laptop"},
    ["bkr_ware05_laptop1"]            = {label = "Laptop"},
    ["bkr_ware05_laptop2"]            = {label = "Laptop"},
    ["bkr_ware05_laptop3"]            = {label = "Laptop"},
    ["ch_prop_laptop_01a"]            = {label = "Laptop"},
    ["ex_prop_ex_laptop_01a"]         = {label = "Laptop"},
    ["gr_prop_gr_laptop_01a"]         = {label = "Laptop"},
    ["gr_prop_gr_laptop_01b"]         = {label = "Laptop"},
    ["gr_prop_gr_laptop_01c"]         = {label = "Laptop"},
    ["h4_prop_club_laptop_dj_02"]     = {label = "Laptop"},
    ["h4_prop_club_laptop_dj"]        = {label = "Laptop"},
    ["h4_prop_h4_laptop_01a"]         = {label = "Laptop"},
    ["hei_bank_heist_laptop"]         = {label = "Laptop"},
    ["hei_prop_hst_laptop"]           = {label = "Laptop"},
    ["m23_1_prop_m31_laptop_01a"]     = {label = "Laptop"},
    ["m23_2_prop_m32_laptop_01a"]     = {label = "Laptop"},
    ["m23_2_prop_m32_laptoplscm_01a"] = {label = "Laptop"},
    ["p_cs_laptop_02_w"]              = {label = "Laptop"},
    ["p_cs_laptop_02"]                = {label = "Laptop"},
    ["p_laptop_02_s"]                 = {label = "Laptop"},
    ["prop_laptop_01a"]               = {label = "Laptop"},
    ["prop_laptop_02_closed"]         = {label = "Laptop"},
    ["prop_laptop_jimmy"]             = {label = "Laptop"},
    ["prop_laptop_lester"]            = {label = "Laptop"},
    ["prop_laptop_lester2"]           = {label = "Laptop"},
    ["reh_prop_reh_laptop_01a"]       = {label = "Laptop"},
    ["sf_int1_laptop_armoury"]        = {label = "Laptop"},
    ["sf_prop_sf_art_laptop_01a"]     = {label = "Laptop"},
    ["sf_prop_sf_laptop_01a"]         = {label = "Laptop"},
    ["sf_prop_sf_laptop_01b"]         = {label = "Laptop"},
    ["tr_prop_tr_laptop_jimmy"]       = {label = "Laptop"},
    ["v_ind_ss_laptop"]               = {label = "Laptop"},
    ["xm_prop_x17_laptop_agent14_01"] = {label = "Laptop"},
    ["xm_prop_x17_laptop_avon"]       = {label = "Laptop"},
    ["xm_prop_x17_laptop_lester_01"]  = {label = "Laptop"},
    ["xm_prop_x17_laptop_mrsr"]       = {label = "Laptop"},
    ["xm3_prop_xm3_laptop_01a"]       = {label = "Laptop"},
}, missionsHelperOnlineMenu_Feat)
create_obj_feat("Cameras", {
    ["ba_prop_battle_cameradrone"] = {label = "Camera"},
    ["ch_prop_ch_camera_01"]       = {label = "Camera"},
    ["h4_prop_h4_camera_01"]       = {label = "Camera"},
    ["m24_1_prop_m41_camera_01a"]  = {label = "Camera"},
    ["p_tv_cam_02_s"]              = {label = "Camera"},
    ["prop_ing_camera_01"]         = {label = "Camera"},
    ["prop_pap_camera_01"]         = {label = "Camera"},
    ["prop_snow_cam_03"]           = {label = "Camera"},
    ["prop_snow_cam_03a"]          = {label = "Camera"},
    ["prop_tv_cam_02"]             = {label = "Camera"},
    ["v_ret_ta_camera"]            = {label = "Camera"},
}, missionsHelperOnlineMenu_Feat)
create_obj_feat("Security Cameras / CCTV", {
    ["v_serv_securitycam_1a"]                 = {label = "Security Camera"},
    ["v_serv_securitycam_03"]                 = {label = "Security Camera"},
    ["ba_prop_battle_cctv_cam_01a"]           = {label = "CCTV"},
    ["ba_prop_battle_cctv_cam_01b"]           = {label = "CCTV"},
    ["ch_prop_ch_cctv_cam_01a"]               = {label = "CCTV"},
    ["ch_prop_ch_cctv_cam_02a"]               = {label = "CCTV"},
    ["hei_prop_bank_cctv_01"]                 = {label = "CCTV"},
    ["hei_prop_bank_cctv_02"]                 = {label = "CCTV"},
    ["m24_1_prop_m24_1_carrier_bank_cctv_01"] = {label = "CCTV"},
    ["m24_1_prop_m24_1_carrier_bank_cctv_02"] = {label = "CCTV"},
    ["p_cctv_s"]                              = {label = "CCTV"},
    ["prop_cctv_cam_01a"]                     = {label = "CCTV"},
    ["prop_cctv_cam_01b"]                     = {label = "CCTV"},
    ["prop_cctv_cam_02a"]                     = {label = "CCTV"},
    ["prop_cctv_cam_03a"]                     = {label = "CCTV"},
    ["prop_cctv_cam_04a"]                     = {label = "CCTV"},
    ["prop_cctv_cam_04b"]                     = {label = "CCTV"},
    ["prop_cctv_cam_04c"]                     = {label = "CCTV"},
    ["prop_cctv_cam_05a"]                     = {label = "CCTV"},
    ["prop_cctv_cam_06a"]                     = {label = "CCTV"},
    ["prop_cctv_cam_07a"]                     = {label = "CCTV"},
    ["prop_cctv_pole_01a"]                    = {label = "CCTV"},
    ["prop_cctv_pole_02"]                     = {label = "CCTV"},
    ["prop_cctv_pole_03"]                     = {label = "CCTV"},
    ["prop_cctv_pole_04"]                     = {label = "CCTV"},
    ["prop_cs_cctv"]                          = {label = "CCTV"},
    ["rop_cctv_cam_06a"]                      = {label = "CCTV"},
    ["tr_prop_tr_camhedz_cctv_01a"]           = {label = "CCTV"},
    ["tr_prop_tr_cctv_cam_01a"]               = {label = "CCTV"},
    ["xm_prop_x17_cctv_01a"]                  = {label = "CCTV"},
    ["xm_prop_x17_server_farm_cctv_01"]       = {label = "CCTV"},
}, missionsHelperOnlineMenu_Feat)

-- === Others === --
local othersMenu_Feat = menu.add_feature("Others", "parent", myRootMenu_Feat.id)
create_obj_feat("Health / Armor", {
    ["prop_armour_pickup"]  = {label = "Armor Pickup", color = COLOR.PICKUP},
    ["prop_ld_health_pack"] = {label = "Health Pickup", color = COLOR.PICKUP},
}, othersMenu_Feat)
create_obj_feat("Chests", {
    ["ba_prop_battle_chest_closed"] = {label = "Chest - Not Sure (ba_prop_battle_chest_closed)"},
    ["xm_prop_x17_chest_closed"]    = {label = "Chest - Not Sure (xm_prop_x17_chest_closed)"},
    ["xm_prop_x17_chest_open"]      = {label = "Chest - Not Sure (xm_prop_x17_chest_open)"},
}, othersMenu_Feat)
create_obj_feat("Gun Van (GTA Online)", {
    ["xm3_prop_xm3_crate_ammo_01a"] = {label = "Gun Van"},
}, othersMenu_Feat)



-- === Startup Load Default Settings === --
load_settings()


-- === Main Loop === --
local function are_objects_equal(baseObjectHash, baseObjectProperties, targetObjectHash, targetObjectProperties)
    return (
        baseObjectHash == targetObjectHash
        and baseObjectProperties.label ==  targetObjectProperties.label
        and baseObjectProperties.color ==  targetObjectProperties.color
        and baseObjectProperties.IPL   ==  targetObjectProperties.IPL
    )
end

local function get_obj_feat(targetObjectHash, targetObjectProperties)
    for key, feat in pairs(_FMAP) do
        if startswith(key, "obj_set_") then
            for objectHash, objectProperties in pairs(feat.data) do
                if are_objects_equal(objectHash, objectProperties, targetObjectHash, targetObjectProperties) then
                    return feat
                end
            end
        end
    end
end

local function is_obj_hidden(hiddenObjectHashes, targetObjectHash, targetObjectProperties)
    for objectHash, objectProperties in pairs(hiddenObjectHashes) do
        if are_objects_equal(objectHash, objectProperties, targetObjectHash, targetObjectProperties) then
            return true
        end
    end
    return false
end

local function switch_duplicated_object_hashes(duplicatedObjectHashes, hiddenObjectHashes)
    local previousDuplicatedObjectHashes = {}

    if duplicatedObjectHashes then
        for objectHash, data in pairs(duplicatedObjectHashes) do
            previousDuplicatedObjectHashes[objectHash] = {
                selectedProperty = data.selectedProperty,
                objectPropertiesListLength = #data.objectPropertiesList
            }
        end
    end

    local duplicatedObjectHashes = {}

    for key, feat in pairs(_FMAP) do
        if feat.on and startswith(key, "obj_set_") then
            for objectHash, objectProperties in pairs(feat.data) do
                if not is_obj_hidden(hiddenObjectHashes, objectHash, objectProperties) then
                    if not duplicatedObjectHashes[objectHash] then
                        duplicatedObjectHashes[objectHash] = { objectPropertiesList = {} }
                    end
                    table.insert(duplicatedObjectHashes[objectHash].objectPropertiesList, objectProperties)
                end
            end
        end
    end

    for objectHash, data in pairs(duplicatedObjectHashes) do
        if #data.objectPropertiesList > 1 then
            if
                previousDuplicatedObjectHashes[objectHash]
                and previousDuplicatedObjectHashes[objectHash].selectedProperty > 0
                and previousDuplicatedObjectHashes[objectHash].selectedProperty < previousDuplicatedObjectHashes[objectHash].objectPropertiesListLength
            then
                data.selectedProperty = previousDuplicatedObjectHashes[objectHash].selectedProperty + 1
            else
                data.selectedProperty = 1
            end
        else
            if
                previousDuplicatedObjectHashes[objectHash]
                and previousDuplicatedObjectHashes[objectHash].objectPropertiesListLength > 1
            then
                _CMAP[objectHash] = data.objectPropertiesList[1]
            end
            duplicatedObjectHashes[objectHash] = nil
        end
    end

    for objectHash, data in pairs(duplicatedObjectHashes) do
        _CMAP[objectHash] = data.objectPropertiesList[data.selectedProperty]
    end

    return duplicatedObjectHashes
end

local function is_myself_in_cayo_perico()
    local playerId = player.player_id()
    local playerPos = player.get_player_coords(playerId)

    return (
        is_session_started()
        and NATIVES.STREAMING.IS_IPL_ACTIVE("island_lodlights")
        and NATIVES.STREAMING.IS_IPL_ACTIVE("island_distantlights")
        and NATIVES.ZONE.GET_NAME_OF_ZONE(playerPos.x, playerPos.y, playerPos.z) == "ISHEIST"
        and (playerPos.x >= 2000 and playerPos.x <= 6500 and playerPos.y >= -7000 and playerPos.y <= -3500)
    )
end


local duplicatedObjectHashes = {}
local hiddenObjectHashes = {}
mainLoop_Thread = create_tick_handler(function()
    if _FMAP["ipl_precision"].on then
        local inCayoPerico = is_myself_in_cayo_perico()

        for objectHash, objectProperties in pairs(_CMAP) do
            if objectProperties.IPL == "Cayo Perico" then
                if not inCayoPerico then
                    hiddenObjectHashes[objectHash] = objectProperties
                    _CMAP[objectHash] = nil
                end
            end
        end

        for objectHash, objectProperties in pairs(hiddenObjectHashes) do
            if inCayoPerico then
                hiddenObjectHashes[objectHash] = nil
                if get_obj_feat(objectHash, objectProperties).on then
                    _CMAP[objectHash] = objectProperties
                end
            end
        end
    else
        for objectHash, objectProperties in pairs(hiddenObjectHashes) do
            if get_obj_feat(objectHash, objectProperties).on then
                _CMAP[objectHash] = objectProperties
            end
        end
        hiddenObjectHashes = {}
    end

    -- Maybe to fix, there is a flicker of one second where the "ipl_precision" at obj toggling.
    -- It's too small of an issue for me to fixes it, has the code is extremely hard to maintain here...
    duplicatedObjectHashes = switch_duplicated_object_hashes(duplicatedObjectHashes, hiddenObjectHashes)
end, 1000)
