-- GDB Server Manager for ARM Embedded Development
-- Manages GDB server process lifecycle

-- Server state
local _server_state = {
    pid = nil,
    port = nil,
    backend = nil,
    start_time = nil
}

-- Get PID file path
local function pid_file_path()
    return path.join(os.tmpdir(), "xmake_gdb_server.pid")
end

-- Check if a process is alive
local function is_process_alive(pid)
    if not pid then return false end
    
    if is_host("windows") then
        local ok = try { function()
            local output = os.iorunv("tasklist", {"/FI", "PID eq " .. pid})
            return output and output:find(tostring(pid))
        end }
        return ok == true
    else
        local ok = os.exec("kill -0 " .. pid .. " 2>/dev/null")
        return ok == 0
    end
end

-- Check if a port is in use
local function is_port_in_use(port)
    if is_host("windows") then
        local output = os.iorunv("netstat", {"-an"})
        return output and output:find(":" .. port .. "%s")
    else
        local ok = os.exec("lsof -i:" .. port .. " >/dev/null 2>&1")
        return ok == 0
    end
end

-- Kill a process by PID
local function kill_process(pid, force)
    if not pid then return end
    
    if is_host("windows") then
        os.exec("taskkill /PID " .. pid .. (force and " /F" or ""))
    else
        local signal = force and "KILL" or "TERM"
        os.exec("kill -" .. signal .. " " .. pid .. " 2>/dev/null")
    end
end

-- Load server state from PID file
function load_state()
    local pid_file = pid_file_path()
    if not os.isfile(pid_file) then
        return nil
    end
    
    import("core.base.json")
    local content = io.readfile(pid_file)
    if not content then
        return nil
    end
    
    local state = try { function()
        return json.decode(content)
    end }
    
    if not state then
        os.rm(pid_file)
        return nil
    end
    
    if state.pid and is_process_alive(state.pid) then
        _server_state = state
        return state
    else
        os.rm(pid_file)
        return nil
    end
end

-- Save server state to PID file
function save_state()
    if _server_state.pid then
        import("core.base.json")
        local state = {
            pid = _server_state.pid,
            port = _server_state.port,
            backend = _server_state.backend,
            start_time = os.time()
        }
        io.writefile(pid_file_path(), json.encode(state))
    end
end

-- Get current server status
function status()
    local state = load_state()
    if state then
        state.alive = is_process_alive(state.pid)
        state.port_active = is_port_in_use(state.port)
        return state
    end
    return nil
end

-- Stop GDB server
function stop(force)
    local state = load_state()
    if state and state.pid then
        print("Stopping GDB server (PID: " .. state.pid .. ")...")
        
        if not force then
            kill_process(state.pid, false)
            os.sleep(500)
            
            if is_process_alive(state.pid) then
                kill_process(state.pid, true)
            end
        else
            kill_process(state.pid, true)
        end
        
        os.rm(pid_file_path())
        _server_state = {}
        print("Server stopped")
    else
        print("No GDB server is running")
    end
end

-- Start GDB server
function start(config)
    import("lib.detect.find_tool")
    
    local port = config.port or 3333
    local backend_name = config.backend or "pyocd"
    
    -- Check for existing server
    local existing = load_state()
    if existing then
        if existing.port == port and existing.backend == backend_name then
            print("GDB server already running (PID: " .. existing.pid .. ")")
            return existing.pid
        else
            stop()
        end
    end
    
    -- Check if port is already in use
    if is_port_in_use(port) then
        raise("Port " .. port .. " is already in use")
    end
    
    -- Start server based on backend
    local pid = nil
    local device = config.device or "cortex_m"
    
    if backend_name == "pyocd" then
        local pyocd = find_tool("pyocd")
        if not pyocd then
            raise("PyOCD not found")
        end
        
        local args = {"gdbserver", "-t", device, "-p", tostring(port)}
        print("Starting PyOCD GDB server...")
        print("  " .. pyocd.program .. " " .. table.concat(args, " "))
        
        -- Start in background
        pid = os.execv(pyocd.program, args, {detach = true})
        
    elseif backend_name == "openocd" then
        local openocd = find_tool("openocd")
        if not openocd then
            raise("OpenOCD not found")
        end
        
        local args = {"-c", "gdb_port " .. port}
        if config.interface then
            table.insert(args, "-f")
            table.insert(args, "interface/" .. config.interface .. ".cfg")
        end
        if config.openocd_target then
            table.insert(args, "-f")
            table.insert(args, "target/" .. config.openocd_target .. ".cfg")
        end
        
        print("Starting OpenOCD GDB server...")
        pid = os.execv(openocd.program, args, {detach = true})
    else
        raise("Unknown backend: " .. backend_name)
    end
    
    -- Wait for port
    local timeout = 5000
    local start_time = os.mclock()
    while (os.mclock() - start_time) < timeout do
        if is_port_in_use(port) then
            break
        end
        os.sleep(100)
    end
    
    if not is_port_in_use(port) then
        if pid then kill_process(pid, true) end
        raise("GDB server failed to start")
    end
    
    -- Save state
    _server_state = {
        pid = pid,
        port = port,
        backend = backend_name,
        start_time = os.time()
    }
    save_state()
    
    print("GDB server started (PID: " .. (pid or "unknown") .. ", Port: " .. port .. ")")
    return pid
end

-- Cleanup orphaned processes
function cleanup()
    local killed = 0
    
    if is_host("windows") then
        return killed
    end
    
    local output = os.iorun("pgrep -f 'pyocd gdbserver|openocd.*gdb_port' 2>/dev/null")
    if output then
        for pid_str in output:gmatch("(%d+)") do
            local pid = tonumber(pid_str)
            if pid then
                kill_process(pid, true)
                killed = killed + 1
            end
        end
    end
    
    os.rm(pid_file_path())
    _server_state = {}
    
    return killed
end
