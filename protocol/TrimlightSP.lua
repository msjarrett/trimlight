-- Trimlight Select Plus LED (TRIMLIGHTSP)
local trimlightsp_proto = Proto("TRIMLIGHTSP", "Trimlight LED Select Plus Protocol")

local START_FLAG = 0x5a   -- decimal 90
local END_FLAG = 0xa5     -- decimal -91 (signed int8)
local MAX_DEVICE_NAME_CHARS = 15
local MAX_LIB_PATTERN_NAME_CHARS = 25
local MIN_DEVICE_DOT_COUNT = 30
local MAX_DEVICE_DOT_COUNT = 2048
local MAX_PATTERN_DOT_COUNT = 30

local request_types_table = {}
request_types_table[1] = "Sync"                     -- Obsolete?
request_types_table[2] = "Sync Detail"              -- HAS RESPONSE. Returns the list of pattern ID's the controller has saved.
request_types_table[3] = "Check Pattern"            -- Load pattern from library (sent from the Schedule page of the app, maybe others)
request_types_table[4] = "Delete Pattern"
request_types_table[5] = "Update Pattern"           -- Updates an existing pattern, e.g. "Cover"
request_types_table[6] = "Create Pattern"           -- Create new pattern, e.g. "Save As"
request_types_table[7] = "Create Schedule"          -- e.g. Save new calendar event
request_types_table[8] = "Delete Schedule"          -- e.g. Delete existing calendar event
request_types_table[9] = "Update Daily Schedule"
request_types_table[10] = "Check Preset Mode"       -- Display Preset
-- 11 is unused
request_types_table[12] = "Check Device"            -- HAS RESPONSE. Request Controllers Info. Used for Discovery.  Returns verification byte, controller name, pixel/dot count
request_types_table[13] = "Set Mode"                -- (trimlight calls this "Device On")
request_types_table[14] = "Set Device Name"
-- 15 is unused
request_types_table[16] = "Set RGB Sequence"
request_types_table[17] = "Set IC Model"
request_types_table[18] = "Set Dot Count"
request_types_table[19] = "Check Custom Pattern"    -- Custom patterns are those on the pattern creation page that aren't saved yet
request_types_table[20] = "Set Solid Color"         -- Sets all pixels to this single solid colid (used when setting a custom color)
request_types_table[21] = "Auto Mode"               -- Probably "Auto mode" network config (Pair your device to a Wi-Fi network with one click)
request_types_table[22] = "Sync Pattern Detail"     -- HAS RESPONSE. Returns the details of the given pattern ID (name, dot count, dot colors, brightness, speed)
request_types_table[23] = "Sync Schedule Detail"    -- HAS RESPONSE.
request_types_table[24] = "Update Schedule"
--25 is unused
request_types_table[26] = "AP Network Config"
request_types_table[27] = "AP Network Config OK"

local mode_table = {}
mode_table[0] = "Timer"
mode_table[1] = "Manual"

local week_days_table = {}
week_days_table[0] = "Sunday"
week_days_table[1] = "Monday"
week_days_table[2] = "Tuesday"
week_days_table[3] = "Wednesday"
week_days_table[4] = "Thursday"
week_days_table[5] = "Friday"
week_days_table[6] = "Saturday"

local rgb_seq_table = {}
rgb_seq_table[0] = "RGB (Red Green Blue)"
rgb_seq_table[1] = "RBG (Red Blue Green)"
rgb_seq_table[2] = "GRB (Green Red Blue)"
rgb_seq_table[3] = "GBR (Green Blue Red)"
rgb_seq_table[4] = "BRG (Blue Red Green)"
rgb_seq_table[5] = "BGR (Blue Green Red)"

local ic_model_table = {}
ic_model_table[0] = "SM16703"
ic_model_table[1] = "TM1804"
ic_model_table[2] = "UCS1903"
ic_model_table[3] = "WS2811"
ic_model_table[4] = "WS2801"
ic_model_table[5] = "SK6812"
ic_model_table[6] = "LPD6803"
ic_model_table[7] = "LPD8806"
ic_model_table[8] = "APA102"
ic_model_table[9] = "APA105"
ic_model_table[10] = "DMX512"
ic_model_table[11] = "TM1914"
ic_model_table[12] = "TM1913"
ic_model_table[13] = "P9813"
ic_model_table[14] = "INK1003"
ic_model_table[15] = "P943S"
ic_model_table[16] = "P9411"
ic_model_table[17] = "P9413"
ic_model_table[18] = "TX1812"
ic_model_table[19] = "TX1813"
ic_model_table[20] = "GS8206"
ic_model_table[21] = "GS8208"
ic_model_table[22] = "SK9822"
ic_model_table[23] = "TM1814"
ic_model_table[24] = "SK6812_RGBW"
ic_model_table[25] = "P9414"
ic_model_table[26] = "P9412"

local effect_table = {}
effect_table[0] = "Static"
effect_table[1] = "Chase Forward"
effect_table[2] = "Chase Backward"
effect_table[3] = "Chase Middle to Out"
effect_table[4] = "Chase Out to Middle"
effect_table[5] = "Strobe"
effect_table[6] = "Fade"
effect_table[7] = "Comet Forward"
effect_table[8] = "Come Backward"
effect_table[9] = "Wave Forward"
effect_table[10] = "Wave Backward"
effect_table[11] = "Solid Fade"

local state_table = {}
state_table[0] = "Off"
state_table[1] = "On"

local repetition_table = {}
repetition_table[0] = "Today Only"
repetition_table[1] = "Everyday"
repetition_table[2] = "Week Days"
repetition_table[3] = "Weekend"

local category_table = {}
category_table[1] = "Preset"
category_table[2] = "Custom"


-- Common Fields
trimlightsp_proto.fields.req_resp = ProtoField.string("trimlightsp.req_resp", "Request/Response")
trimlightsp_proto.fields.start_flag = ProtoField.uint8("trimlightsp.start_flag", "Start Flag", base.HEX)
trimlightsp_proto.fields.end_flag = ProtoField.uint8("trimlightsp.end_flag", "End Flag", base.HEX)
trimlightsp_proto.fields.request_type = ProtoField.uint8("trimlightsp.requestType", "Request Type", base.DEC, request_types_table)
trimlightsp_proto.fields.message_type = ProtoField.string("trimlightsp.message_type", "Message Type", base.ASCII)
trimlightsp_proto.fields.linked_request = ProtoField.framenum("trimlightsp.linked_request", "Linked Request")
trimlightsp_proto.fields.linked_response = ProtoField.framenum("trimlightsp.linked_response", "Linked Response")
trimlightsp_proto.fields.command_length = ProtoField.uint16("trimlightsp.command_length", "Commmand Length", base.DEC) -- length of command (excludes start/end flags, request_type, and length)
trimlightsp_proto.fields.payload = ProtoField.bytes("trimlightsp.data", "Data")
trimlightsp_proto.fields.unknown = ProtoField.bytes("trimlightsp.unknown", "Unknown")
trimlightsp_proto.fields.name = ProtoField.string("trimlightsp.name", "Name", base.ASCII)
trimlightsp_proto.fields.name_length = ProtoField.uint8("trimlightsp.name_length", "Name Length", base.DEC)  -- Not all name fields are preceeded by a length
trimlightsp_proto.fields.unused_string_padding = ProtoField.none("sple.unused_string_padding", "Unused String Padding")
trimlightsp_proto.fields.category = ProtoField.uint8("trimlightsp.category", "Category", base.DEC, category_table)
trimlightsp_proto.fields.speed = ProtoField.uint8("trimlightsp.speed", "Speed Level", base.DEC)
trimlightsp_proto.fields.brightness = ProtoField.uint8("trimlightsp.brightness", "Brightness Level", base.DEC)
trimlightsp_proto.fields.lib_pattern_id = ProtoField.uint8("trimlightsp.libPatternId", "Pattern Id", base.DEC)
trimlightsp_proto.fields.schedule_id = ProtoField.uint8("trimlightsp.schedule_id", "Schedule ID", base.DEC)
trimlightsp_proto.fields.start_hour = ProtoField.uint8("trimlightsp.start_hour", "Start Hour", base.DEC)
trimlightsp_proto.fields.start_minute = ProtoField.uint8("trimlightsp.start_minute", "Start Minute", base.DEC)
trimlightsp_proto.fields.off_hour = ProtoField.uint8("trimlightsp.off_hour", "Off Hour", base.DEC)
trimlightsp_proto.fields.off_minute = ProtoField.uint8("trimlightsp.off_minute", "Off Minute", base.DEC)
trimlightsp_proto.fields.num_lib_patterns = ProtoField.uint8("trimlightsp.num_lib_patterns", "Library Patterns Count", base.DEC)
trimlightsp_proto.fields.num_schedules = ProtoField.uint8("trimlightsp.num_schedules", "Schedules Count", base.DEC)
trimlightsp_proto.fields.start_month = ProtoField.uint8("trimlightsp.start_month", "Start Month", base.DEC)
trimlightsp_proto.fields.start_day = ProtoField.uint8("trimlightsp.start_day", "Start Day", base.DEC)
trimlightsp_proto.fields.off_month = ProtoField.uint8("trimlightsp.off_month", "Off Month", base.DEC)
trimlightsp_proto.fields.off_day = ProtoField.uint8("trimlightsp.off_day", "Off Day", base.DEC)
trimlightsp_proto.fields.daily_schedule_id = ProtoField.uint8("trimlightsp.daily_schedule_id", "Daily Schedule ID", base.DEC)
trimlightsp_proto.fields.daily_sched_state = ProtoField.uint8("trimlightsp.daily_sched_state", "State", base.DEC, state_table)
trimlightsp_proto.fields.daily_sched_repetition = ProtoField.uint8("trimlightsp.daily_sched_repetition", "Repetition", base.DEC, repetition_table)
trimlightsp_proto.fields.preset_pattern_id = ProtoField.uint8("trimlightsp.presetPatternId", "Preset Id", base.DEC) -- preset patterns are the built-in patterns on the colorwheel page
trimlightsp_proto.fields.verification = ProtoField.uint24("trimlightsp.verification", "Verification Bytes", base.HEX)
trimlightsp_proto.fields.verification_resp = ProtoField.uint8("trimlightsp.verification_resp", "Verification Response", base.HEX)
trimlightsp_proto.fields.year = ProtoField.uint8("trimlightsp.year", "Year", base.DEC)
trimlightsp_proto.fields.month = ProtoField.uint8("trimlightsp.month", "Month", base.DEC)
trimlightsp_proto.fields.day = ProtoField.uint8("trimlightsp.day", "Day", base.DEC)
trimlightsp_proto.fields.day_of_week = ProtoField.uint8("trimlightsp.day_of_week", "Day of Week", base.DEC, week_days_table)
trimlightsp_proto.fields.hour = ProtoField.uint8("trimlightsp.hour", "Hour", base.DEC)
trimlightsp_proto.fields.minute = ProtoField.uint8("trimlightsp.minute", "Minute", base.DEC)
trimlightsp_proto.fields.second = ProtoField.uint8("trimlightsp.second", "Second", base.DEC)
trimlightsp_proto.fields.mode = ProtoField.uint8("trimlightsp.mode", "Mode", base.DEC, mode_table)
trimlightsp_proto.fields.rgb_sequence = ProtoField.uint8("trimlightsp.rgb_seq", "RGB Sequence", base.DEC, rgb_seq_table)
trimlightsp_proto.fields.ic_model = ProtoField.uint8("trimlightsp.ic_model", "IC Model", base.DEC, ic_model_table)
trimlightsp_proto.fields.device_dot_count = ProtoField.uint16("trimlightsp.device_dot_count", "Device Dot Count (Num Pixels on String)", base.DEC)      -- Min: 30, Max: 2048
trimlightsp_proto.fields.pattern_rgb = ProtoField.uint24("trimlightsp.pattern_rgb", "  RGB", base.HEX)
trimlightsp_proto.fields.effect_mode = ProtoField.uint8("sple.effect_mode", "Effect Mode", base.DEC, effect_table)
trimlightsp_proto.fields.color1_count = ProtoField.uint8("trimlightsp.color1_count", "Color 1 Count", base.DEC)
trimlightsp_proto.fields.color2_count = ProtoField.uint8("trimlightsp.color2_count", "Color 2 Count", base.DEC)
trimlightsp_proto.fields.color3_count = ProtoField.uint8("trimlightsp.color3_count", "Color 3 Count", base.DEC)
trimlightsp_proto.fields.color4_count = ProtoField.uint8("trimlightsp.color4_count", "Color 4 Count", base.DEC)
trimlightsp_proto.fields.color5_count = ProtoField.uint8("trimlightsp.color5_count", "Color 5 Count", base.DEC)
trimlightsp_proto.fields.color6_count = ProtoField.uint8("trimlightsp.color6_count", "Color 6 Count", base.DEC)
trimlightsp_proto.fields.color7_count = ProtoField.uint8("trimlightsp.color7_count", "Color 7 Count", base.DEC)
trimlightsp_proto.fields.color1_rgb = ProtoField.uint24("trimlightsp.color1_rgb", "Color 1 RGB", base.HEX)
trimlightsp_proto.fields.color2_rgb = ProtoField.uint24("trimlightsp.color2_rgb", "Color 2 RGB", base.HEX)
trimlightsp_proto.fields.color3_rgb = ProtoField.uint24("trimlightsp.color3_rgb", "Color 3 RGB", base.HEX)
trimlightsp_proto.fields.color4_rgb = ProtoField.uint24("trimlightsp.color4_rgb", "Color 4 RGB", base.HEX)
trimlightsp_proto.fields.color5_rgb = ProtoField.uint24("trimlightsp.color5_rgb", "Color 5 RGB", base.HEX)
trimlightsp_proto.fields.color6_rgb = ProtoField.uint24("trimlightsp.color6_rgb", "Color 6 RGB", base.HEX)
trimlightsp_proto.fields.color7_rgb = ProtoField.uint24("trimlightsp.color7_rgb", "Color 7 RGB", base.HEX)

local request_map = {} -- a table of request info (with frame number as index)

function trimlightsp_proto.dissector(buffer, pinfo, tree)
    -- safety checks
    local length = buffer:len()
    print("buffer length: " .. length)
    if length < 2 then
        print("payload too short!")
        return
    end

    local first_payload_byte = buffer(0, 1):uint()
    if first_payload_byte ~= START_FLAG then
        print("packet missing start flag")
        return
    end

    local last_payload_byte = buffer(length - 1, 1):uint()
    if last_payload_byte ~= END_FLAG then
        print("packet missing end flag")
        return
    end

    pinfo.cols.protocol = trimlightsp_proto.name
    local subtree = tree:add(trimlightsp_proto, buffer(), "Trimlight LED Select Plus Protocol Data")

    local dst_port = pinfo.dst_port
    local is_request = dst_port == 8189
    local req_resp_text = is_request and "Request" or "Response"

    subtree:add(trimlightsp_proto.fields.req_resp, req_resp_text):set_generated(true)
    subtree:add(trimlightsp_proto.fields.start_flag, buffer(0, 1))

    if is_request then
        local request_type_id = buffer(1, 1):uint()
        local command_length = buffer(2, 2):uint()
        if not pinfo.visited then
            request_map[pinfo.number] = {request_type=request_type_id, response=nil, verification=nil}
        end

        subtree:add(trimlightsp_proto.fields.message_type, request_types_table[request_type_id]):set_generated(true)
        if request_map[pinfo.number].response then
            subtree:add(trimlightsp_proto.fields.linked_response, request_map[pinfo.number].response):set_generated(true)
        end
        subtree:add(trimlightsp_proto.fields.request_type, buffer(1, 1)):append_text(" (0x".. buffer(1, 1) .. ")")
        subtree:add(trimlightsp_proto.fields.command_length, buffer(2, 2))

        if request_type_id == 2 then -- Sync Detail
            -- No fields (empty payload)
        elseif request_type_id == 3 then -- Check Pattern
            subtree:add(trimlightsp_proto.fields.lib_pattern_id, buffer(4, 1))
        elseif request_type_id == 4 then -- Delete Pattern
            subtree:add(trimlightsp_proto.fields.lib_pattern_id, buffer(4, 1))
        elseif request_type_id == 5 then -- Update Pattern
            subtree:add(trimlightsp_proto.fields.lib_pattern_id, buffer(4, 1))
            local name_length = get_name_length(5, MAX_LIB_PATTERN_NAME_CHARS, buffer)
            subtree:add(trimlightsp_proto.fields.name, buffer(5, name_length))  -- Note: the app only allows limited characters: a-z, A-Z, 0-9, -, _, ', &
            subtree:add(trimlightsp_proto.fields.unused_string_padding, buffer(5 + name_length, MAX_LIB_PATTERN_NAME_CHARS - name_length))
            subtree:add(trimlightsp_proto.fields.category, buffer(30, 1))
            subtree:add(trimlightsp_proto.fields.effect_mode, buffer(31, 1))
            subtree:add(trimlightsp_proto.fields.speed, buffer(32, 1)):append_text(percentage(buffer(32, 1)))
            subtree:add(trimlightsp_proto.fields.brightness, buffer(33, 1)):append_text(percentage(buffer(33, 1)))
            subtree:add(trimlightsp_proto.fields.color1_count, buffer(34, 1))
            subtree:add(trimlightsp_proto.fields.color2_count, buffer(35, 1))
            subtree:add(trimlightsp_proto.fields.color3_count, buffer(36, 1))
            subtree:add(trimlightsp_proto.fields.color4_count, buffer(37, 1))
            subtree:add(trimlightsp_proto.fields.color5_count, buffer(38, 1))
            subtree:add(trimlightsp_proto.fields.color6_count, buffer(39, 1))
            subtree:add(trimlightsp_proto.fields.color7_count, buffer(40, 1))
            subtree:add(trimlightsp_proto.fields.color1_rgb, buffer(41, 3)):append_text((get_rgb(buffer(41, 3))))
            subtree:add(trimlightsp_proto.fields.color2_rgb, buffer(44, 3)):append_text((get_rgb(buffer(44, 3))))
            subtree:add(trimlightsp_proto.fields.color3_rgb, buffer(47, 3)):append_text((get_rgb(buffer(47, 3))))
            subtree:add(trimlightsp_proto.fields.color4_rgb, buffer(50, 3)):append_text((get_rgb(buffer(50, 3))))
            subtree:add(trimlightsp_proto.fields.color5_rgb, buffer(53, 3)):append_text((get_rgb(buffer(53, 3))))
            subtree:add(trimlightsp_proto.fields.color6_rgb, buffer(56, 3)):append_text((get_rgb(buffer(56, 3))))
            subtree:add(trimlightsp_proto.fields.color7_rgb, buffer(59, 3)):append_text((get_rgb(buffer(59, 3))))
        elseif request_type_id == 6 then -- Create Pattern
            subtree:add(trimlightsp_proto.fields.lib_pattern_id, buffer(4, 1))
            local name_length = get_name_length(5, MAX_LIB_PATTERN_NAME_CHARS, buffer)
            subtree:add(trimlightsp_proto.fields.name, buffer(5, name_length))  -- Note: only allows limited characters: a-z, A-Z, 0-9, -, _, ', &
            subtree:add(trimlightsp_proto.fields.unused_string_padding, buffer(5 + name_length, MAX_LIB_PATTERN_NAME_CHARS - name_length))
            subtree:add(trimlightsp_proto.fields.category, buffer(30, 1))
            subtree:add(trimlightsp_proto.fields.effect_mode, buffer(31, 1))
            subtree:add(trimlightsp_proto.fields.speed, buffer(32, 1)):append_text(percentage(buffer(32, 1)))
            subtree:add(trimlightsp_proto.fields.brightness, buffer(33, 1)):append_text(percentage(buffer(33, 1)))
            subtree:add(trimlightsp_proto.fields.color1_count, buffer(34, 1))
            subtree:add(trimlightsp_proto.fields.color2_count, buffer(35, 1))
            subtree:add(trimlightsp_proto.fields.color3_count, buffer(36, 1))
            subtree:add(trimlightsp_proto.fields.color4_count, buffer(37, 1))
            subtree:add(trimlightsp_proto.fields.color5_count, buffer(38, 1))
            subtree:add(trimlightsp_proto.fields.color6_count, buffer(39, 1))
            subtree:add(trimlightsp_proto.fields.color7_count, buffer(40, 1))
            subtree:add(trimlightsp_proto.fields.color1_rgb, buffer(41, 3)):append_text((get_rgb(buffer(41, 3))))
            subtree:add(trimlightsp_proto.fields.color2_rgb, buffer(44, 3)):append_text((get_rgb(buffer(44, 3))))
            subtree:add(trimlightsp_proto.fields.color3_rgb, buffer(47, 3)):append_text((get_rgb(buffer(47, 3))))
            subtree:add(trimlightsp_proto.fields.color4_rgb, buffer(50, 3)):append_text((get_rgb(buffer(50, 3))))
            subtree:add(trimlightsp_proto.fields.color5_rgb, buffer(53, 3)):append_text((get_rgb(buffer(53, 3))))
            subtree:add(trimlightsp_proto.fields.color6_rgb, buffer(56, 3)):append_text((get_rgb(buffer(56, 3))))
            subtree:add(trimlightsp_proto.fields.color7_rgb, buffer(59, 3)):append_text((get_rgb(buffer(59, 3))))
        elseif request_type_id == 7 then -- Create Schedule
            subtree:add(trimlightsp_proto.fields.schedule_id, buffer(4, 1))
            subtree:add(trimlightsp_proto.fields.lib_pattern_id, buffer(5, 1))
            subtree:add(trimlightsp_proto.fields.start_month, buffer(6, 1))
            subtree:add(trimlightsp_proto.fields.start_day, buffer(7, 1))
            subtree:add(trimlightsp_proto.fields.off_month, buffer(8, 1))
            subtree:add(trimlightsp_proto.fields.off_day, buffer(9, 1))
            subtree:add(trimlightsp_proto.fields.start_hour, buffer(10, 1))
            subtree:add(trimlightsp_proto.fields.start_minute, buffer(11, 1))
            subtree:add(trimlightsp_proto.fields.off_hour, buffer(12, 1))
            subtree:add(trimlightsp_proto.fields.off_minute, buffer(13, 1))
        elseif request_type_id == 8 then -- Delete Schedule
            subtree:add(trimlightsp_proto.fields.schedule_id, buffer(4, 1))
        elseif request_type_id == 9 then -- Update Daily Schedule
            subtree:add(trimlightsp_proto.fields.daily_schedule_id, buffer(4, 1))
            subtree:add(trimlightsp_proto.fields.daily_sched_state, buffer(5, 1))
            subtree:add(trimlightsp_proto.fields.lib_pattern_id, buffer(6, 1))
            subtree:add(trimlightsp_proto.fields.daily_sched_repetition, buffer(7, 1))
            subtree:add(trimlightsp_proto.fields.start_hour, buffer(8, 1))
            subtree:add(trimlightsp_proto.fields.start_minute, buffer(9, 1))
            subtree:add(trimlightsp_proto.fields.off_hour, buffer(10, 1))
            subtree:add(trimlightsp_proto.fields.off_minute, buffer(11, 1))
        elseif request_type_id == 10 then -- Check Preset Mode
            subtree:add(trimlightsp_proto.fields.preset_pattern_id, buffer(4, 1))
            subtree:add(trimlightsp_proto.fields.speed, buffer(5, 1)):append_text(percentage(buffer(5, 1)))
            subtree:add(trimlightsp_proto.fields.brightness, buffer(6, 1)):append_text(percentage(buffer(6, 1)))
        elseif request_type_id == 12 then -- Check Device
            if not pinfo.visited then
                request_map[pinfo.number].verification = { buffer(4, 1):uint(), buffer(5, 1):uint(), buffer(6, 1):uint() }
            end
            subtree:add(trimlightsp_proto.fields.verification, buffer(4, 3))
            subtree:add(trimlightsp_proto.fields.year, buffer(7, 1))
            subtree:add(trimlightsp_proto.fields.month, buffer(8, 1))
            subtree:add(trimlightsp_proto.fields.day, buffer(9, 1))
            subtree:add(trimlightsp_proto.fields.day_of_week, buffer(10, 1))
            subtree:add(trimlightsp_proto.fields.hour, buffer(11, 1))
            subtree:add(trimlightsp_proto.fields.minute, buffer(12, 1))
            subtree:add(trimlightsp_proto.fields.second, buffer(13, 1))
        elseif request_type_id == 13 then -- Set Mode
            subtree:add(trimlightsp_proto.fields.mode, buffer(4, 1))
        elseif request_type_id == 14 then -- Set Device Name
            subtree:add(trimlightsp_proto.fields.name, buffer(4, command_length))
        elseif request_type_id == 16 then -- Set RGB Sequence
            subtree:add(trimlightsp_proto.fields.rgb_sequence, buffer(4, 1))
        elseif request_type_id == 17 then -- Set IC Model
            subtree:add(trimlightsp_proto.fields.ic_model, buffer(4, 1))
        elseif request_type_id == 18 then -- Set Dot Count
            subtree:add(trimlightsp_proto.fields.device_dot_count, buffer(4, 2))
        elseif request_type_id == 19 then -- Check Custom Pattern
            subtree:add(trimlightsp_proto.fields.effect_mode, buffer(4, 1))
            subtree:add(trimlightsp_proto.fields.speed, buffer(5, 1)):append_text(percentage(buffer(5, 1)))
            subtree:add(trimlightsp_proto.fields.brightness, buffer(6, 1)):append_text(percentage(buffer(6, 1)))
            subtree:add(trimlightsp_proto.fields.color1_count, buffer(7, 1)):append_text(" (1st)")
            subtree:add(trimlightsp_proto.fields.color2_count, buffer(8, 1)):append_text(" (2nd)")
            subtree:add(trimlightsp_proto.fields.color3_count, buffer(9, 1)):append_text(" (3rd)")
            subtree:add(trimlightsp_proto.fields.color4_count, buffer(10, 1)):append_text(" (4th)")
            subtree:add(trimlightsp_proto.fields.color5_count, buffer(11, 1)):append_text(" (5th)")
            subtree:add(trimlightsp_proto.fields.color6_count, buffer(12, 1)):append_text(" (6th)")
            subtree:add(trimlightsp_proto.fields.color7_count, buffer(13, 1)):append_text(" (7th)")
            subtree:add(trimlightsp_proto.fields.color1_rgb, buffer(14, 3)):append_text(" (1st)" .. get_rgb(buffer(14, 3)))
            subtree:add(trimlightsp_proto.fields.color2_rgb, buffer(17, 3)):append_text(" (2nd)" .. get_rgb(buffer(17, 3)))
            subtree:add(trimlightsp_proto.fields.color3_rgb, buffer(20, 3)):append_text(" (3rd)" .. get_rgb(buffer(20, 3)))
            subtree:add(trimlightsp_proto.fields.color4_rgb, buffer(23, 3)):append_text(" (4th)" .. get_rgb(buffer(23, 3)))
            subtree:add(trimlightsp_proto.fields.color5_rgb, buffer(26, 3)):append_text(" (5th)" .. get_rgb(buffer(26, 3)))
            subtree:add(trimlightsp_proto.fields.color6_rgb, buffer(29, 3)):append_text(" (6th)" .. get_rgb(buffer(29, 3)))
            subtree:add(trimlightsp_proto.fields.color7_rgb, buffer(32, 3)):append_text(" (7th)" .. get_rgb(buffer(32, 3)))
        elseif request_type_id == 20 then -- Solid Color
            subtree:add(trimlightsp_proto.fields.pattern_rgb, buffer(4, 3)):append_text(get_rgb(buffer(4, 3)))
        elseif request_type_id == 21 then -- Auto Mode ?
        elseif request_type_id == 22 then -- Sync Pattern Detail
            subtree:add(trimlightsp_proto.fields.lib_pattern_id, buffer(4, 1))
        elseif request_type_id == 23 then -- Sync Schedule Detail
            subtree:add(trimlightsp_proto.fields.schedule_id, buffer(4, 1))
        elseif request_type_id == 24 then -- Update Schedule
            subtree:add(trimlightsp_proto.fields.schedule_id, buffer(4, 1))
            subtree:add(trimlightsp_proto.fields.lib_pattern_id, buffer(5, 1))
            subtree:add(trimlightsp_proto.fields.start_month, buffer(6, 1))
            subtree:add(trimlightsp_proto.fields.start_day, buffer(7, 1))
            subtree:add(trimlightsp_proto.fields.off_month, buffer(8, 1))
            subtree:add(trimlightsp_proto.fields.off_day, buffer(9, 1))
            subtree:add(trimlightsp_proto.fields.start_hour, buffer(10, 1))
            subtree:add(trimlightsp_proto.fields.start_minute, buffer(11, 1))
            subtree:add(trimlightsp_proto.fields.off_hour, buffer(12, 1))
            subtree:add(trimlightsp_proto.fields.off_minute, buffer(13, 1))
        elseif request_type_id == 26 then  -- AP Network Config
            -- unsure of the specific fields on this one
            subtree:add(trimlightsp_proto.fields.payload, buffer(4, command_length))
        elseif request_type_id == 27 then  -- AP Network Config OK
            -- unsure of the specific fields on this one
            subtree:add(trimlightsp_proto.fields.payload, buffer(4, 3))
        else
            -- Unknown message, just show generic payload
            print("Unable to parse request type " .. request_type_id)
            subtree:add(trimlightsp_proto.fields.payload, buffer(4, length - 5)):append_text(" (" .. length - 5 .. " bytes)")
        end
    else
        -- Response
        -- Find the most recent request (e.g. request with highest index that is less that response frame number)
        local request_index = -1
        for i in pairs(request_map) do
            if i < pinfo.number and i > request_index then
                request_index = i
            end
        end

        if not pinfo.visited then
            request_map[request_index].response = pinfo.number
        end

        local request_type = nil
        local verification = nil
        
        if request_map[request_index] then
            request_type = request_map[request_index].request_type
            verification = request_map[request_index].verification
        end

        subtree:add(trimlightsp_proto.fields.message_type, request_types_table[request_type] .. " Response"):set_generated(true)
        if request_index > 0 then
            subtree:add(trimlightsp_proto.fields.linked_request, request_index):set_generated(true)
        end

        if request_type == 12 then -- Check Device Response
            local verification_result = calc_verification(verification)
            local verification_text
            if buffer(1, 1):uint() == verification_result then
                verification_text = " (Verification matches!)"
            else
                verification_text = " (Verification failed - expected: " .. verification_result .. ")"
            end

            subtree:add(trimlightsp_proto.fields.verification_resp, buffer(1, 1)):append_text(verification_text)
            subtree:add(trimlightsp_proto.fields.mode, buffer(2, 1))
            subtree:add(trimlightsp_proto.fields.name_length, buffer(3,1))
            local length_of_name = buffer(3,1):uint()
            subtree:add(trimlightsp_proto.fields.name, buffer(4, length_of_name)):prepend_text("Controller ")
            subtree:add(trimlightsp_proto.fields.ic_model, buffer(4 + length_of_name, 1))
            subtree:add(trimlightsp_proto.fields.rgb_sequence, buffer(4 + length_of_name + 1, 1))
            subtree:add(trimlightsp_proto.fields.device_dot_count, buffer(4 + length_of_name + 2, 2))
            subtree:add(trimlightsp_proto.fields.unknown, buffer(4 + length_of_name + 4, 1))
            subtree:add(trimlightsp_proto.fields.unknown, buffer(4 + length_of_name + 5, 1))
        elseif request_type == 2 then -- Sync Detail Response
            subtree:add(trimlightsp_proto.fields.num_lib_patterns, buffer(1, 1))
            local num_patterns = buffer(1, 1):uint()
            local index = 2
            for i = index, index + (num_patterns - 1) do
                index = i
                subtree:add(trimlightsp_proto.fields.lib_pattern_id, buffer(index, 1))
            end

            index = index + 1
            subtree:add(trimlightsp_proto.fields.num_schedules, buffer(index, 1))
            local num_schedules = buffer(index, 1):uint()
            index = index + 1
            for i = index, index + (num_schedules - 1) do
                index = i
                subtree:add(trimlightsp_proto.fields.schedule_id, buffer(index, 1))
            end

            -- Daily schedules (there are two, first 7 bytes are schedule 1, last 7 are schedule 2)
            index = index + 1
            subtree:add(trimlightsp_proto.fields.daily_sched_state, buffer(index, 1)):prepend_text("Daily Schedule 1 ")
            subtree:add(trimlightsp_proto.fields.lib_pattern_id, buffer(index + 1, 1)):prepend_text("Daily Schedule 1 ")
            subtree:add(trimlightsp_proto.fields.daily_sched_repetition, buffer(index + 2, 1)):prepend_text("Daily Schedule 1 ")
            subtree:add(trimlightsp_proto.fields.start_hour, buffer(index + 3, 1)):prepend_text("Daily Schedule 1 ")
            subtree:add(trimlightsp_proto.fields.start_minute, buffer(index + 4, 1)):prepend_text("Daily Schedule 1 ")
            subtree:add(trimlightsp_proto.fields.off_hour, buffer(index + 5, 1)):prepend_text("Daily Schedule 1 ")
            subtree:add(trimlightsp_proto.fields.off_minute, buffer(index + 6, 1)):prepend_text("Daily Schedule 1 ")
            index = index + 7
            subtree:add(trimlightsp_proto.fields.daily_sched_state, buffer(index, 1)):prepend_text("Daily Schedule 2 ")
            subtree:add(trimlightsp_proto.fields.lib_pattern_id, buffer(index + 1, 1)):prepend_text("Daily Schedule 2 ")
            subtree:add(trimlightsp_proto.fields.daily_sched_repetition, buffer(index + 2, 1)):prepend_text("Daily Schedule 2 ")
            subtree:add(trimlightsp_proto.fields.start_hour, buffer(index + 3, 1)):prepend_text("Daily Schedule 2 ")
            subtree:add(trimlightsp_proto.fields.start_minute, buffer(index + 4, 1)):prepend_text("Daily Schedule 2 ")
            subtree:add(trimlightsp_proto.fields.off_hour, buffer(index + 5, 1)):prepend_text("Daily Schedule 2 ")
            subtree:add(trimlightsp_proto.fields.off_minute, buffer(index + 6, 1)):prepend_text("Daily Schedule 2 ")
        elseif request_type == 22 then -- Sync Pattern Detail Response
            local string_start_pos = 2
            local max_name_length = 25
            local length_of_name = get_name_length(string_start_pos, max_name_length, buffer)
            subtree:add(trimlightsp_proto.fields.lib_pattern_id, buffer(1, 1))
            subtree:add(trimlightsp_proto.fields.name, buffer(2, length_of_name)):prepend_text("Pattern ")
            subtree:add(trimlightsp_proto.fields.unused_string_padding, buffer(2 + length_of_name, max_name_length - length_of_name))
            subtree:add(trimlightsp_proto.fields.category, buffer(27, 1)) 
            subtree:add(trimlightsp_proto.fields.effect_mode, buffer(28, 1)) 
            subtree:add(trimlightsp_proto.fields.speed, buffer(29, 1)):append_text(percentage(buffer(29, 1)))
            subtree:add(trimlightsp_proto.fields.brightness, buffer(30, 1)):append_text(percentage(buffer(30, 1)))
            subtree:add(trimlightsp_proto.fields.color1_count, buffer(31, 1))
            subtree:add(trimlightsp_proto.fields.color2_count, buffer(32, 1))
            subtree:add(trimlightsp_proto.fields.color3_count, buffer(33, 1))
            subtree:add(trimlightsp_proto.fields.color4_count, buffer(34, 1))
            subtree:add(trimlightsp_proto.fields.color5_count, buffer(35, 1))
            subtree:add(trimlightsp_proto.fields.color6_count, buffer(36, 1))
            subtree:add(trimlightsp_proto.fields.color7_count, buffer(37, 1))
            subtree:add(trimlightsp_proto.fields.color1_rgb, buffer(38, 3)):append_text(get_rgb(buffer(38, 3)))
            subtree:add(trimlightsp_proto.fields.color2_rgb, buffer(41, 3)):append_text(get_rgb(buffer(41, 3)))
            subtree:add(trimlightsp_proto.fields.color3_rgb, buffer(44, 3)):append_text(get_rgb(buffer(44, 3)))
            subtree:add(trimlightsp_proto.fields.color4_rgb, buffer(47, 3)):append_text(get_rgb(buffer(47, 3)))
            subtree:add(trimlightsp_proto.fields.color5_rgb, buffer(50, 3)):append_text(get_rgb(buffer(50, 3)))
            subtree:add(trimlightsp_proto.fields.color6_rgb, buffer(53, 3)):append_text(get_rgb(buffer(53, 3)))
            subtree:add(trimlightsp_proto.fields.color7_rgb, buffer(56, 3)):append_text(get_rgb(buffer(56, 3)))
        elseif request_type == 23 then -- Sync Schedule Detail Response
            subtree:add(trimlightsp_proto.fields.schedule_id, buffer(1, 1))
            subtree:add(trimlightsp_proto.fields.lib_pattern_id, buffer(2, 1))
            subtree:add(trimlightsp_proto.fields.start_month, buffer(3, 1))
            subtree:add(trimlightsp_proto.fields.start_day, buffer(4, 1))
            subtree:add(trimlightsp_proto.fields.off_month, buffer(5, 1))
            subtree:add(trimlightsp_proto.fields.off_day, buffer(6, 1))
            subtree:add(trimlightsp_proto.fields.start_hour, buffer(7, 1))
            subtree:add(trimlightsp_proto.fields.start_minute, buffer(8, 1))
            subtree:add(trimlightsp_proto.fields.off_hour, buffer(9, 1))
            subtree:add(trimlightsp_proto.fields.off_minute, buffer(10, 1))
        else
            -- Unknown message, just show generic payload
            print("Unable to parse response")
            subtree:add(trimlightsp_proto.fields.payload, buffer(4, length - 5))
        end
    end

    subtree:add(trimlightsp_proto.fields.end_flag, buffer(length - 1, 1))
end

function get_name_length(start, max_chars, buffer)
    local length = max_chars
    for i = start, start + max_chars, 1 do
        local char = buffer(i, 1):uint()
        if (char == 0 or char == 0xff) then  -- can be terminated with 0x00 or 0xff
            length = i - start
            break
        end
    end

    return length
end

function get_rgb(buffer)
    local red = buffer(0, 1):uint()
    local green = buffer(1, 1):uint()
    local blue = buffer(2, 1):uint()
    return " (" .. red .. ", " .. green .. ", " .. blue .. ")"
end

function percentage(buffer)
    return string.format(" (%.1f%%)", buffer:uint() / 255.0 * 100)
end

function calc_verification(input)
    if not input then
        return nil
    end

    local byte1 = bit.rshift(input[1], 3)
    local byte2 = bit.band(input[2], 0x1f)
    local byte3 = bit.lshift(input[3], 5)
    return bit.band(bit.bor(byte3, bit.band(byte1, byte2)), 0xff)
end

local tcp_port = DissectorTable.get("tcp.port")
tcp_port:add(8189, trimlightsp_proto)
