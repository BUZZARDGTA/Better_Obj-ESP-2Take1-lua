local DRAW = require("obj-esp\\draw")
local INI = IniParser("scripts\\obj-esp\\Settings.ini")
local _D = 500.0
local _CMAP = {}
local _FMAP = {}


local function rgba_to_int(R, G, B, A)
    A = A or 255
    return ((R&0x0ff)<<0x00)|((G&0x0ff)<<0x08)|((B&0x0ff)<<0x10)|((A&0x0ff)<<0x18)
end

local COLOR <const> = {
    DEFAULT = rgba_to_int(128, 128, 128, 255),       -- GREY
    -- DESTROYABLE = rgba_to_int(255, 255, 0, 155),  -- YELLOW It was a good idea till I figured some entitys have god mod on/off
    HACKABLE = rgba_to_int(0, 255, 0, 255),          -- GREEN
    COLLECTIBLE = rgba_to_int(114, 204, 114, 255),   -- GREEN
    RED = rgba_to_int(255, 0, 0, 255),               -- RED
    ORANGE = rgba_to_int(255, 165, 0, 255),          -- ORANGE
}

local PARENT = menu.add_feature("Object ESP", "parent", 0)

_FMAP["enable"] = menu.add_feature("Enable Object ESP", "toggle", PARENT.id, function(f)
    while f.on do
        DRAW(_D, _CMAP)

        system.yield(0)
    end
end)

menu.add_feature("Save", "action", PARENT.id, function(f)
    menu.notify("Saving...", "Object ESP")
    for k,v in pairs(_FMAP) do
        INI:set_b("Toggles", k, v.on)
    end
    INI:set_f("Floats", "max_dist", _D)
    INI:write()
end)

local _DF = menu.add_feature("Max Dist", "autoaction_value_i", PARENT.id, function(f)
    _D = f.value
end)
_DF.min = 45.0
_DF.max = 500.0
_DF.mod = 5.0
_DF.value = _D


create_feat = function(n, d)
    local function process_keys(data)
        local processed_data = {}
        for k, v in pairs(data) do
            local hashKey = gameplay.get_hash_key(k)
            if not v.color then
                v.color = COLOR.DEFAULT
            end
            processed_data[hashKey] = v
        end
        return processed_data
    end

    local processed_data = process_keys(d)

    local f = menu.add_feature(n, "toggle", PARENT.id, function(f)
    if f.on then
        for k, v in pairs(f.data) do
        _CMAP[k] = v
        end
    else
        for k, v in pairs(f.data) do
        _CMAP[k] = nil
        end
    end
    end)

    f.data = processed_data
    _FMAP["obj_set_" .. n:gsub('%W','')] = f
    return f
end


create_feat("LD Organics", {
    ["reh_prop_reh_bag_weed_01a"] = {label = "LD Organics", color = COLOR.COLLECTIBLE},
})

create_feat("Peyotes", {
    --halloween event
    ["prop_peyote_highland_01"] = {label = "Peyote Highland 1"},
    ["prop_peyote_highland_02"] = {label = "Peyote Highland 2"},
    --(story mode) peyotes
    ["prop_peyote_gold_01"]    = {label = "Peyote Gold"},
    ["prop_peyote_lowland_01"] = {label = "Peyote Lowland 1"},
    ["prop_peyote_lowland_02"] = {label = "Peyote Lowland 2"},
    ["prop_peyote_water_01"]   = {label = "Peyote Water"},
})

create_feat("Jack O' Lanterns", {
    ["reh_prop_reh_lantern_pk_01a"] = {label = "Jack O' Lantern", color = COLOR.ORANGE},
    ["reh_prop_reh_lantern_pk_01b"] = {label = "Jack O' Lantern", color = COLOR.ORANGE},
    ["reh_prop_reh_lantern_pk_01c"] = {label = "Jack O' Lantern", color = COLOR.ORANGE},
})

create_feat("Movie Props", {
    ["sum_prop_ac_alienhead_01a"]    = {label = "Movie Prop: Alien Head", color = COLOR.COLLECTIBLE},
    ["sum_prop_ac_clapperboard_01a"] = {label = "Movie Prop: Clapper", color = COLOR.COLLECTIBLE},
    ["sum_prop_ac_filmreel_01a"]     = {label = "Movie Prop: Film Reel", color = COLOR.COLLECTIBLE},
    ["sum_prop_ac_headdress_01a"]    = {label = "Movie Prop: Head Dress", color = COLOR.COLLECTIBLE},
    ["sum_prop_ac_monstermask_01a"]  = {label = "Movie Prop: Monster Mask", color = COLOR.COLLECTIBLE},
    ["sum_prop_ac_mummyhead_01a"]    = {label = "Movie Prop: Mummy Head", color = COLOR.COLLECTIBLE},
    ["sum_prop_ac_wifaaward_01a"]    = {label = "Movie Prop: WIFA Award", color = COLOR.COLLECTIBLE},
})

create_feat("Buried Stash", {
    ["tr_prop_tr_sand_01a"] = {label = "Buried Stash"}, -- Seen it has a false positive in one of the Bottom Dollar Bounties mission. (Chaz Lieberman)
})

create_feat("Signal Jammer", {
    ["ch_prop_ch_mobile_jammer_01x"] = {label = "Signal Jammer", color = COLOR.COLLECTIBLE},
})

create_feat("Action Figures", {
    ["vw_prop_vw_colle_alien"]      = {label = "Action Figure: Alien", color = COLOR.COLLECTIBLE},
    ["vw_prop_vw_colle_beast"]      = {label = "Action Figure: Beast", color = COLOR.COLLECTIBLE},
    ["vw_prop_vw_colle_imporage"]   = {label = "Action Figure: Impotent Rage", color = COLOR.COLLECTIBLE},
    ["vw_prop_vw_colle_pogo"]       = {label = "Action Figure: Pogo", color = COLOR.COLLECTIBLE},
    ["vw_prop_vw_colle_prbubble"]   = {label = "Action Figure: Princess Robot Bubblegum", color = COLOR.COLLECTIBLE},
    ["vw_prop_vw_colle_rsrcomm"]    = {label = "Action Figure: RSR Comm", color = COLOR.COLLECTIBLE},
    ["vw_prop_vw_colle_rsrgeneric"] = {label = "Action Figure: RSR Generic", color = COLOR.COLLECTIBLE},
    ["vw_prop_vw_colle_sasquatch"]  = {label = "Action Figure: Sasquatch", color = COLOR.COLLECTIBLE},
})

create_feat("Playing Cards", {
    ["vw_prop_vw_lux_card_01a"] = {label = "Playing Card", color = COLOR.COLLECTIBLE},
})

create_feat("ULP FIB Hardware", {
    ["reh_prop_reh_box_metal_01a"]   = {label = "AI Hardware"},
    ["reh_prop_reh_drone_02a"]       = {label = "Drone"},
    ["reh_prop_reh_gadget_01a"]      = {label = "USB Drive"},
    ["reh_prop_reh_glasses_smt_01a"] = {label = "VR Headset"},
    ["reh_prop_reh_harddisk_01a"]    = {label = "Hard Drive"},
    ["reh_prop_reh_tablet_01a"]      = {label = "Tablet"},
    ["tr_prop_tr_fuse_box_01a"]      = {label = "Fusebox"},
})

create_feat("ULP Fuses", {
    ["reh_prop_reh_fuse_01a"] = {label = "Fuse"},
})

create_feat("Perico Heist Prep", {
    ["h4_prop_h4_cash_stack_01a"]   = {label = "Cash", color = COLOR.COLLECTIBLE},
    ["h4_prop_h4_coke_stack_01a"]   = {label = "Coke", color = COLOR.COLLECTIBLE},
    ["h4_prop_h4_weed_stack_01a"]   = {label = "Weed", color = COLOR.COLLECTIBLE},
    ["h4_prop_h4_gold_stack_01a"]   = {label = "Gold", color = COLOR.COLLECTIBLE},
    ["h4_prop_h4_painting_01a"]     = {label = "Painting", color = COLOR.COLLECTIBLE},
    ["h4_prop_h4_painting_01b"]     = {label = "Painting", color = COLOR.COLLECTIBLE},
    ["h4_prop_h4_painting_01c"]     = {label = "Painting", color = COLOR.COLLECTIBLE},
    ["h4_prop_h4_painting_01d"]     = {label = "Painting", color = COLOR.COLLECTIBLE},
    ["h4_prop_h4_painting_01e"]     = {label = "Painting", color = COLOR.COLLECTIBLE},
    ["h4_prop_h4_painting_01f"]     = {label = "Painting", color = COLOR.COLLECTIBLE},
    ["h4_prop_h4_painting_01g"]     = {label = "Painting", color = COLOR.COLLECTIBLE},
    ["h4_prop_h4_painting_01h"]     = {label = "Painting", color = COLOR.COLLECTIBLE},
    ["h4_prop_h4_bag_hook_01a"]     = {label = "Hook"},
    ["h4_prop_h4_bolt_cutter_01a"]  = {label = "Bolt Cutter"},
    ["h4_prop_h4_card_hack_01a"]    = {label = "Fingerprint Cloner"},
    ["h4_prop_h4_crate_cloth_01a"]  = {label = "Clothes"},
    ["h4_prop_h4_elecbox_01a"]      = {label = "Electrical Box"},
    ["h4_prop_h4_gascutter_01a"]    = {label = "Cutter"},
    ["h4_prop_h4_jammer_01a"]       = {label = "Sonar Jammer"},
    ["h4_prop_h4_loch_monster"]     = {label = "Nessy", color = COLOR.BLUE},
    ["h4_prop_h4_securitycard_01a"] = {label = "Keycard"},
})

create_feat("Agency Security Contracts", {
    ["sf_prop_sf_codes_01a"]       = {label = "Safe Code"},
    ["sf_prop_sf_crate_jugs_01a"]  = {label = "Moonshine"},
    ["sf_prop_v_43_safe_s_bk_01a"] = {label = "Safe"},
    ["vw_prop_vw_key_cabinet_01a"] = {label = "Key Cabinet"},
})

create_feat("Hidden Caches", {
    --["h4_prop_h4_chest_01a"]  = {label = "Hidden Cache Chest"},
    ["h4_prop_h4_box_ammo_02a"] = {label = "Hidden Cache"},
})

create_feat("Special Cargo", {
    ["ex_prop_adv_case_sm_02"]    = {label = "Special Cargo"},
    ["ex_prop_adv_case_sm_03"]    = {label = "Special Cargo"},
    ["ex_prop_adv_case_sm_flash"] = {label = "Special Cargo"},
    ["ex_prop_adv_case_sm"]       = {label = "Special Cargo"},
    ["ex_prop_adv_case"]          = {label = "Special Cargo"},
})

create_feat("Freakshop Missions", {
    ["xm3_prop_xm3_drug_pkg_01a"] = {label = "Meth"},
})

create_feat("Snowmen", {
    ["xm3_prop_xm3_snowman_01a"] = {label = "Snowman"},
    ["xm3_prop_xm3_snowman_01b"] = {label = "Snowman"},
    ["xm3_prop_xm3_snowman_01c"] = {label = "Snowman"},
})


-- these are probably the media collections
create_feat("USB Drives", {
    ["sf_prop_sf_usb_drive_01a"] = {label = "USB Drive (Record A Studio - not sure)"},
    ["tr_prop_tr_usb_drive_01a"] = {label = "USB Drive (hacking device)", color = COLOR.HACKABLE},
    ["tr_prop_tr_usb_drive_02a"] = {label = "USB Drive (CircoLoco Records)", color = COLOR.COLLECTIBLE},
})

create_feat("Chests", {
    ["ba_prop_battle_chest_closed"] = {label = "Chest - Not Sure"},
    ["h4_prop_h4_chest_01a_uw"]     = {label = "Chest - Not Sure"},
    ["h4_prop_h4_chest_01a"]        = {label = "Chest - Not Sure"},
    ["tr_prop_tr_chest_01a"]        = {label = "Chest - Not Sure"},
    ["xm_prop_x17_chest_closed"]    = {label = "Chest - Not Sure"},
    ["xm_prop_x17_chest_open"]      = {label = "Chest - Not Sure"},
})

create_feat("Health / Armor", {
    ["prop_armour_pickup"]  = {label = "Armor Pickup"},
    ["prop_ld_health_pack"] = {label = "Health Pickup"},
})

create_feat("Gang Attack Crates", {
    ["prop_box_wood02a_pu"] = {label = "Wood Crate"},
})

create_feat("Letter Scrap (Story)", {
    ["prop_ld_scrap"] = {label = "Letter Scrap"},
})

create_feat("G's Cache", {
    ["prop_mp_drug_pack_blue"] = {label = "G's Cache", color = COLOR.COLLECTIBLE},
    ["prop_mp_drug_pack_red"]  = {label = "G's Cache - Not sure"},
    ["prop_mp_drug_package"]   = {label = "G's Cache", color = COLOR.COLLECTIBLE},
})

create_feat("LS Tags", {
    ["m24_1_prop_m41_bdgr_pstr_01a"]   = {label = "LS Tag", color = COLOR.COLLECTIBLE},
    ["m24_1_prop_m41_cnt_pstr_01a"]    = {label = "LS Tag", color = COLOR.COLLECTIBLE},
    ["m24_1_prop_m41_dg_pstr_01a"]     = {label = "LS Tag", color = COLOR.COLLECTIBLE},
    ["m24_1_prop_m41_life_pstr_01a"]   = {label = "LS Tag", color = COLOR.COLLECTIBLE},
    ["m24_1_prop_m41_weazel_pstr_01a"] = {label = "LS Tag", color = COLOR.COLLECTIBLE},
})

create_feat("Security Devices (Keypads, Fingerprints, ...)", {
    --["ch_prop_casino_keypad_01"]            = {label = "Keypad c844a6e2"},
    --["ch_prop_casino_keypad_02"]            = {label = "Keypad b662031d"},
    ["ch_prop_ch_usb_drive01x"]               = {label = "Security Scanner"},
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
})

create_feat("Laptops", {
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
})

create_feat("Cameras", {
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
})

create_feat("Security Cameras / CCTV", {
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
})

create_feat("Tower", {
    ["m24_1_prop_m41_electricbox_01a"] = {label = "Tower (to hack)"},
})

if INI:read() then
    for k,v in pairs(_FMAP) do
        local exists, val = INI:get_b("Toggles", k)
        if exists == true then
            v.on = val
        end
    end

    local exists, val = INI:get_f("Floats", "max_dist")
    if exists == true then
        _D = val
        _DF.value = val
    end
end


--[[
event.add_event_listener("exit", function()
    for k,v in pairs(_FMAP) do
        INI:set_b("Toggles", k, v.on)
    end
    INI:set_f("Floats", "max_dist", _D)
    INI:write()
    INI = nil
end)
--]]
