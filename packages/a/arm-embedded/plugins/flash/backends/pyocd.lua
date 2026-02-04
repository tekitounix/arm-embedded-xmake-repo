-- PyOCD Backend for Flash Plugin
--
-- Provides flash functionality using PyOCD
--

--- Flash firmware using PyOCD
-- @param config table Flash configuration
-- @return boolean Success
function flash(config)
    local tool_registry = import("utils.tool_registry", {rootdir = path.directory(path.directory(path.directory(os.scriptdir())))})
    local pyocd = tool_registry.find_pyocd()
    
    if not pyocd then
        raise("PyOCD not found. Install with: xmake require pyocd")
    end
    
    -- Build command arguments
    local args = {"flash", "-t", config.device}
    
    -- Format
    local format = config.format or "elf"
    table.insert(args, "--format")
    table.insert(args, format)
    
    -- Speed
    if config.speed then
        table.insert(args, "-f")
        table.insert(args, config.speed)
    end
    
    -- Base address (for bin files)
    if config.address and format == "bin" then
        table.insert(args, "--base-address")
        table.insert(args, config.address)
    end
    
    -- Erase mode
    if config.erase == "chip" then
        table.insert(args, "-e")
        table.insert(args, "chip")
    elseif config.erase == "sector" then
        table.insert(args, "-e")
        table.insert(args, "sector")
    end
    
    -- Verify
    if config.verify then
        table.insert(args, "--verify")
    end
    
    -- Probe selection
    if config.probe then
        table.insert(args, "--probe")
        table.insert(args, config.probe)
    end
    
    -- Connection mode
    if config.connect then
        table.insert(args, "--connect")
        table.insert(args, config.connect)
    end
    
    -- Reset mode
    if config.reset == "none" then
        table.insert(args, "--no-reset")
    elseif config.reset == "hw" then
        table.insert(args, "--reset-type")
        table.insert(args, "hw")
    elseif config.reset == "sw" then
        table.insert(args, "--reset-type")
        table.insert(args, "sw")
    end
    
    -- Add verbose for progress
    if not config.quiet then
        table.insert(args, "--verbose")
    end
    
    -- Add the file
    table.insert(args, config.file)
    
    -- Execute
    print("=> PyOCD: " .. pyocd.program)
    print("=> Device: " .. config.device)
    print("=> File: " .. config.file)
    
    local ok = os.execv(pyocd.program, args)
    return ok == 0 or ok == true
end

--- Check and install device pack if needed
-- @param device string Device name
-- @param pack_name string Pack name
-- @param auto_confirm boolean Auto-confirm installation
-- @return boolean Success
function check_and_install_pack(device, pack_name, auto_confirm)
    local tool_registry = import("utils.tool_registry", {rootdir = path.directory(path.directory(path.directory(os.scriptdir())))})
    local pyocd = tool_registry.find_pyocd()
    
    if not pyocd then
        return false
    end
    
    -- Check if pack is installed
    local pack_list = os.iorunv(pyocd.program, {"pack", "show"})
    if pack_list and pack_list:upper():find(pack_name:upper()) then
        return true  -- Already installed
    end
    
    print("=> Device pack '" .. pack_name .. "' not installed")
    
    local do_install = auto_confirm
    if not auto_confirm then
        -- Check for interactive mode
        local is_interactive = os.getenv("CI") == nil and os.getenv("GITHUB_ACTIONS") == nil
        if is_interactive then
            io.write("Install pack automatically? [Y/n]: ")
            io.flush()
            local input = io.read()
            do_install = input == "" or input:lower() == "y" or input:lower() == "yes"
        end
    end
    
    if do_install then
        print("=> Installing pack: " .. pack_name)
        local ok = os.execv(pyocd.program, {"pack", "--install", pack_name})
        if ok == 0 or ok == true then
            print("=> Pack installed successfully")
            return true
        else
            print("=> Failed to install pack")
            return false
        end
    end
    
    print("=> Continuing without pack installation")
    print("   Manual installation: pyocd pack --install " .. pack_name)
    return false
end

--- List available probes
-- @return table|nil List of probes
function list_probes()
    local tool_registry = import("utils.tool_registry", {rootdir = path.directory(path.directory(path.directory(os.scriptdir())))})
    local pyocd = tool_registry.find_pyocd()
    
    if not pyocd then
        return nil
    end
    
    local output = os.iorunv(pyocd.program, {"list"})
    if output then
        print(output)
    end
    return output
end

--- Start GDB server
-- @param config table Server configuration
-- @return number|nil PID of server process
function start_gdb_server(config)
    local tool_registry = import("utils.tool_registry", {rootdir = path.directory(path.directory(path.directory(os.scriptdir())))})
    local pyocd = tool_registry.find_pyocd()
    
    if not pyocd then
        raise("PyOCD not found")
    end
    
    local args = {"gdbserver", "-t", config.device}
    
    if config.port then
        table.insert(args, "-p")
        table.insert(args, tostring(config.port))
    end
    
    if config.probe then
        table.insert(args, "--probe")
        table.insert(args, config.probe)
    end
    
    if config.speed then
        table.insert(args, "-f")
        table.insert(args, config.speed)
    end
    
    -- Start in background
    local pid = os.execv(pyocd.program, args, {detach = true})
    return pid
end
