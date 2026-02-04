-- Flash Plugin v2 for ARM Embedded Development
--
-- Supports multiple backends: PyOCD, OpenOCD
-- Family-based MCU detection, automatic pack installation
--

-- Load flash targets database
local function load_flash_database()
    import("core.base.json")
    
    local plugin_dir = path.directory(os.scriptdir())
    local db_file = path.join(plugin_dir, "database", "flash-targets-v2.json")
    
    if os.isfile(db_file) then
        return json.loadfile(db_file)
    end
    
    -- Fallback to old database
    db_file = path.join(plugin_dir, "database", "flash-targets.json")
    if os.isfile(db_file) then
        return json.loadfile(db_file)
    end
    
    raise("Flash database not found")
end

-- Detect MCU family from device name
local function detect_family(device)
    local patterns = {
        {"^stm32f0", "stm32f0"},
        {"^stm32f1", "stm32f1"},
        {"^stm32f4", "stm32f4"},
        {"^stm32f7", "stm32f7"},
        {"^stm32g0", "stm32g0"},
        {"^stm32g4", "stm32g4"},
        {"^stm32h5", "stm32h5"},
        {"^stm32h7", "stm32h7"},
        {"^stm32l4", "stm32l4"},
        {"^stm32l5", "stm32l5"},
        {"^stm32u5", "stm32u5"},
        {"^stm32wb", "stm32wb"},
        {"^nrf52", "nrf52"},
        {"^nrf53", "nrf53"},
        {"^lpc", "lpc"},
        {"^samd", "samd"},
        {"^rp2040", "rp2040"},
    }
    
    local lower_device = device:lower()
    for _, p in ipairs(patterns) do
        if lower_device:match(p[1]) then
            return p[2]
        end
    end
    return nil
end

-- Resolve MCU configuration
local function resolve_mcu_config(device, database, target_values, cmdline_opts)
    local config = {}
    
    -- 1. Apply alias if exists
    if database.aliases and database.aliases[device] then
        device = database.aliases[device]
    end
    
    -- 2. Detect family and apply family config
    local family = detect_family(device)
    if family and database.mcu_families and database.mcu_families[family] then
        for k, v in pairs(database.mcu_families[family]) do
            config[k] = v
        end
    end
    
    -- 3. Apply MCU-specific overrides
    if database.mcu_overrides and database.mcu_overrides[device] then
        for k, v in pairs(database.mcu_overrides[device]) do
            config[k] = v
        end
    end
    
    -- 4. Apply target values
    if target_values then
        for k, v in pairs(target_values) do
            local key = k:gsub("^flash%.", "")
            if type(v) == "table" then v = v[1] end
            config[key] = v
        end
    end
    
    -- 5. Apply command line options (highest priority)
    if cmdline_opts then
        for k, v in pairs(cmdline_opts) do
            if v ~= nil then
                config[k] = v
            end
        end
    end
    
    -- Set device
    config.device = config.pyocd_target or device
    
    return config
end

-- Main flash task
task("flash")
    set_category("plugin")
    set_menu {
        usage = "xmake flash [options] [target]",
        description = "Flash ARM embedded target",
        options = {
            {'t', "target",   "kv", nil,      "Target to flash"},
            {'d', "device",   "kv", nil,      "MCU device name (e.g., stm32f407vg)"},
            {'b', "backend",  "kv", "auto",   "Backend [pyocd|openocd|auto]"},
            {'a', "address",  "kv", nil,      "Base address (for bin files)"},
            {'f', "file",     "kv", nil,      "Binary file to flash"},
            {nil, "format",   "kv", "elf",    "File format [elf|bin|hex]"},
            {'e', "erase",    "kv", "sector", "Erase mode [chip|sector|none]"},
            {'v', "verify",   "k",  nil,      "Verify after programming"},
            {'r', "reset",    "kv", "hw",     "Reset mode [hw|sw|none]"},
            {'p', "probe",    "kv", nil,      "Probe UID/serial"},
            {'s', "speed",    "kv", nil,      "Communication speed (e.g., 4M)"},
            {nil, "connect",  "kv", nil,      "Connection mode [halt|pre-reset|under-reset]"},
            {nil, "unlock",   "k",  nil,      "Unlock read protection"},
            {'y', "yes",      "k",  nil,      "Auto-confirm prompts"},
            {nil, "dry-run",  "k",  nil,      "Show commands without executing"},
            {nil, "interface","kv", nil,      "OpenOCD interface config"},
        }
    }
    
    on_run(function()
        import("core.base.option")
        import("core.project.project")
        import("core.project.config")
        import("lib.detect.find_tool")
        
        -- Import backends (inside on_run)
        local tool_registry = import("utils.tool_registry", {rootdir = path.directory(path.directory(os.scriptdir()))})
        
        -- Auto-detect backend function
        local function auto_detect_backend()
            if tool_registry.find_pyocd() then
                return "pyocd"
            end
            if tool_registry.find_openocd() then
                return "openocd"
            end
            return nil
        end
        
        -- Load configuration
        config.load()
        
        -- Get target
        local targetname = option.get("target")
        local target_obj = nil
        
        if targetname then
            target_obj = project.target(targetname)
            if not target_obj then
                raise("Target not found: " .. targetname)
            end
        else
            -- Find first embedded target
            for _, target in pairs(project.targets()) do
                if target:rule("embedded") then
                    target_obj = target
                    break
                end
            end
            
            if not target_obj then
                raise("No embedded target found. Specify with -t/--target")
            end
        end
        
        print("=> Target: " .. target_obj:name())
        
        -- Build if needed
        local targetfile = option.get("file") or target_obj:targetfile()
        if not option.get("file") then
            if not targetfile or not os.isfile(targetfile) then
                print("=> Building target...")
                os.execv("xmake", {"build", target_obj:name()})
                targetfile = target_obj:targetfile()
            end
        end
        
        if not os.isfile(targetfile) then
            raise("Binary file not found: " .. (targetfile or "nil"))
        end
        
        -- Load database
        local database = load_flash_database()
        
        -- Get device name
        local device = option.get("device")
        if not device then
            local mcu = target_obj:values("embedded.mcu")
            device = type(mcu) == "table" and mcu[1] or mcu
        end
        
        if not device then
            raise([[
No device specified. Set it using:
  1. In xmake.lua: set_values("embedded.mcu", "stm32f407vg")
  2. Command line: xmake flash -d stm32f407vg
]])
        end
        
        -- Gather target values
        local target_values = {}
        for _, key in ipairs({"flash.backend", "flash.speed", "flash.probe", "flash.address", 
                              "flash.verify", "flash.reset", "flash.interface"}) do
            local v = target_obj:values(key)
            if v then
                target_values[key] = v
            end
        end
        
        -- Gather command line options
        local cmdline_opts = {
            backend = option.get("backend"),
            speed = option.get("speed"),
            probe = option.get("probe"),
            address = option.get("address"),
            verify = option.get("verify"),
            reset = option.get("reset"),
            erase = option.get("erase"),
            format = option.get("format"),
            connect = option.get("connect"),
            interface = option.get("interface"),
        }
        
        -- Resolve configuration
        local flash_config = resolve_mcu_config(device, database, target_values, cmdline_opts)
        flash_config.file = targetfile
        
        -- Auto-detect backend
        local backend_name = flash_config.backend
        if backend_name == "auto" or not backend_name then
            backend_name = auto_detect_backend()
            if not backend_name then
                raise("No flash tool found. Install PyOCD or OpenOCD.")
            end
        end
        
        print("=> Device: " .. flash_config.device)
        print("=> Backend: " .. backend_name)
        print("=> File: " .. targetfile .. " (" .. math.floor(os.filesize(targetfile) / 1024) .. " KB)")
        
        -- Dry-run mode
        if option.get("dry-run") then
            print("")
            print("Dry-run mode - commands that would be executed:")
            print("  Backend: " .. backend_name)
            print("  Device: " .. flash_config.device)
            print("  File: " .. flash_config.file)
            if flash_config.speed then print("  Speed: " .. flash_config.speed) end
            if flash_config.probe then print("  Probe: " .. flash_config.probe) end
            if flash_config.erase then print("  Erase: " .. flash_config.erase) end
            if flash_config.verify then print("  Verify: yes") end
            if flash_config.reset then print("  Reset: " .. flash_config.reset) end
            return
        end
        
        -- Get backend module
        local backend
        if backend_name == "pyocd" then
            backend = import("plugins.flash.backends.pyocd", {rootdir = path.directory(path.directory(os.scriptdir()))})
            
            -- Check/install pack if needed
            if flash_config.pack and flash_config.pack_auto_install then
                backend.check_and_install_pack(flash_config.device, flash_config.pack, option.get("yes"))
            end
        elseif backend_name == "openocd" then
            backend = import("plugins.flash.backends.openocd", {rootdir = path.directory(path.directory(os.scriptdir()))})
            
            -- Handle unlock request
            if option.get("unlock") then
                print("")
                print("=> Unlocking read protection...")
                backend.unlock(flash_config)
                print("=> Power cycle the target and run flash again")
                return
            end
        else
            raise("Unknown backend: " .. backend_name)
        end
        
        -- Execute flash
        print("")
        local ok = backend.flash(flash_config)
        
        if ok then
            print("")
            print("=> Flash completed successfully")
        else
            print("")
            raise("Flash operation failed")
        end
    end)
task_end()

-- Flash list-probes task
task("flash.probes")
    set_category("plugin")
    set_menu {
        usage = "xmake flash.probes",
        description = "List connected debug probes"
    }
    
    on_run(function()
        import("lib.detect.find_tool")
        local tool_registry = import("utils.tool_registry", {rootdir = path.directory(path.directory(os.scriptdir()))})
        
        local pyocd = tool_registry.find_pyocd()
        if pyocd then
            print("=== PyOCD Probes ===")
            os.execv(pyocd.program, {"list"})
            print("")
        end
        
        local openocd = tool_registry.find_openocd()
        if openocd then
            print("=== OpenOCD (checking ST-Link) ===")
            os.execv(openocd.program, {"-f", "interface/stlink.cfg", "-c", "init", "-c", "exit"})
        end
        
        if not pyocd and not openocd then
            print("No flash tools found. Install PyOCD or OpenOCD.")
        end
    end)
task_end()

-- Flash status task
task("flash.status")
    set_category("plugin")
    set_menu {
        usage = "xmake flash.status",
        description = "Show flash tool status"
    }
    
    on_run(function()
        import("lib.detect.find_tool")
        local tool_registry = import("utils.tool_registry", {rootdir = path.directory(path.directory(os.scriptdir()))})
        
        -- Auto-detect backend function (defined inside on_run)
        local function auto_detect_backend()
            if tool_registry.find_pyocd() then
                return "pyocd"
            end
            if tool_registry.find_openocd() then
                return "openocd"
            end
            return nil
        end
        
        print("Flash Tool Status:")
        print("")
        
        local pyocd = tool_registry.find_pyocd()
        if pyocd then
            print("  PyOCD:   " .. pyocd.program .. " (" .. pyocd.source .. ")")
        else
            print("  PyOCD:   not found")
            print("           Install: xmake require pyocd")
        end
        
        local openocd = tool_registry.find_openocd()
        if openocd then
            print("  OpenOCD: " .. openocd.program .. " (" .. openocd.source .. ")")
        else
            print("  OpenOCD: not found")
            print("           Install: xmake require openocd")
        end
        
        print("")
        print("Recommended backend: " .. (auto_detect_backend() or "none"))
    end)
task_end()
