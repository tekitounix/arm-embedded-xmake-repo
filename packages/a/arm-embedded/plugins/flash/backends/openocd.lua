-- OpenOCD Backend for Flash Plugin
--
-- Provides flash functionality using OpenOCD
--

--- Parse speed string to kHz
-- @param speed string e.g., "4M", "1000k", "1000"
-- @return number Speed in kHz
local function parse_speed(speed)
    local num, unit = speed:match("^(%d+)([MmKk]?)$")
    if num then
        num = tonumber(num)
        if unit:lower() == "m" then
            return num * 1000
        elseif unit:lower() == "k" then
            return num
        else
            return num
        end
    end
    return 4000  -- Default 4MHz
end

--- Flash firmware using OpenOCD
-- @param config table Flash configuration
-- @return boolean Success
function flash(config)
    local tool_registry = import("utils.tool_registry", {rootdir = path.directory(path.directory(path.directory(os.scriptdir())))})
    local openocd = tool_registry.find_openocd()
    
    if not openocd then
        raise("OpenOCD not found. Install with: xmake require openocd")
    end
    
    -- Build command arguments
    local args = {}
    
    -- Interface configuration
    local interface_cfg = config.interface or "stlink.cfg"
    table.insert(args, "-f")
    table.insert(args, "interface/" .. interface_cfg)
    
    -- Transport (if specified)
    if config.transport then
        table.insert(args, "-c")
        table.insert(args, "transport select " .. config.transport)
    end
    
    -- Target configuration
    local target_cfg = config.openocd_target
    if target_cfg then
        table.insert(args, "-f")
        table.insert(args, "target/" .. target_cfg)
    end
    
    -- Speed configuration
    if config.speed then
        local speed_khz = parse_speed(config.speed)
        table.insert(args, "-c")
        table.insert(args, "adapter speed " .. tostring(speed_khz))
    end
    
    -- Build program command
    local program_cmd = string.format("program %s", config.file)
    
    -- Add verify if requested
    if config.verify then
        program_cmd = program_cmd .. " verify"
    end
    
    -- Add reset if requested
    if config.reset ~= "none" then
        program_cmd = program_cmd .. " reset"
    end
    
    -- Add exit
    program_cmd = program_cmd .. " exit"
    
    -- Add base address for bin files
    if config.format == "bin" and config.address then
        program_cmd = string.format("program %s %s", config.file, config.address)
        if config.verify then program_cmd = program_cmd .. " verify" end
        if config.reset ~= "none" then program_cmd = program_cmd .. " reset" end
        program_cmd = program_cmd .. " exit"
    end
    
    table.insert(args, "-c")
    table.insert(args, program_cmd)
    
    -- Execute
    print("=> OpenOCD: " .. openocd.program)
    print("=> Interface: " .. interface_cfg)
    if target_cfg then
        print("=> Target: " .. target_cfg)
    end
    print("=> File: " .. config.file)
    
    local ok = os.execv(openocd.program, args)
    return ok == 0 or ok == true
end

--- Erase chip using OpenOCD
-- @param config table Configuration
-- @return boolean Success
function erase(config)
    local tool_registry = import("utils.tool_registry", {rootdir = path.directory(path.directory(path.directory(os.scriptdir())))})
    local openocd = tool_registry.find_openocd()
    
    if not openocd then
        raise("OpenOCD not found")
    end
    
    local args = {}
    
    -- Interface
    local interface_cfg = config.interface or "stlink.cfg"
    table.insert(args, "-f")
    table.insert(args, "interface/" .. interface_cfg)
    
    -- Target
    if config.openocd_target then
        table.insert(args, "-f")
        table.insert(args, "target/" .. config.openocd_target)
    end
    
    -- Erase command
    table.insert(args, "-c")
    table.insert(args, "init")
    table.insert(args, "-c")
    table.insert(args, "reset halt")
    table.insert(args, "-c")
    
    if config.erase == "chip" then
        table.insert(args, "flash erase_sector 0 0 last")
    else
        -- Sector erase would need specific sectors
        table.insert(args, "flash erase_sector 0 0 last")
    end
    
    table.insert(args, "-c")
    table.insert(args, "exit")
    
    local ok = os.execv(openocd.program, args)
    return ok == 0 or ok == true
end

--- Start GDB server using OpenOCD
-- @param config table Server configuration
-- @return number|nil PID of server process
function start_gdb_server(config)
    local tool_registry = import("utils.tool_registry", {rootdir = path.directory(path.directory(path.directory(os.scriptdir())))})
    local openocd = tool_registry.find_openocd()
    
    if not openocd then
        raise("OpenOCD not found")
    end
    
    local args = {}
    
    -- Interface
    local interface_cfg = config.interface or "stlink.cfg"
    table.insert(args, "-f")
    table.insert(args, "interface/" .. interface_cfg)
    
    -- Target
    if config.openocd_target then
        table.insert(args, "-f")
        table.insert(args, "target/" .. config.openocd_target)
    end
    
    -- GDB port
    if config.port and config.port ~= 3333 then
        table.insert(args, "-c")
        table.insert(args, "gdb_port " .. tostring(config.port))
    end
    
    -- Speed
    if config.speed then
        local speed_khz = parse_speed(config.speed)
        table.insert(args, "-c")
        table.insert(args, "adapter speed " .. tostring(speed_khz))
    end
    
    -- Log level
    table.insert(args, "-c")
    table.insert(args, "log_output /dev/null")
    
    print("Starting OpenOCD GDB server on port " .. (config.port or 3333))
    
    -- Start in background
    local pid = os.execv(openocd.program, args, {detach = true})
    return pid
end

--- Unlock read protection
-- @param config table Configuration
-- @return boolean Success
function unlock(config)
    local tool_registry = import("utils.tool_registry", {rootdir = path.directory(path.directory(path.directory(os.scriptdir())))})
    local openocd = tool_registry.find_openocd()
    
    if not openocd then
        raise("OpenOCD not found")
    end
    
    local args = {}
    
    -- Interface
    local interface_cfg = config.interface or "stlink.cfg"
    table.insert(args, "-f")
    table.insert(args, "interface/" .. interface_cfg)
    
    -- Use connect_under_reset for locked chips
    table.insert(args, "-c")
    table.insert(args, "reset_config srst_only")
    
    -- Target
    if config.openocd_target then
        table.insert(args, "-f")
        table.insert(args, "target/" .. config.openocd_target)
    end
    
    -- Unlock sequence (STM32 specific)
    table.insert(args, "-c")
    table.insert(args, "init")
    table.insert(args, "-c")
    table.insert(args, "reset halt")
    table.insert(args, "-c")
    table.insert(args, "stm32f4x unlock 0")  -- STM32F4 specific
    table.insert(args, "-c")
    table.insert(args, "reset halt")
    table.insert(args, "-c")
    table.insert(args, "exit")
    
    print("Attempting to unlock read protection...")
    local ok = os.execv(openocd.program, args)
    
    if ok == 0 or ok == true then
        print("Unlock successful. Power cycle the target.")
    end
    
    return ok == 0 or ok == true
end
