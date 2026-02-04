--! Debugger Plugin v2 for ARM Embedded Development

-- Main debugger task
task("debugger")
    set_category("action")
    set_menu {
        usage = "xmake debugger [options] [target]",
        description = "Debug embedded or host targets",
        options = {
            {'t', "target",     "kv", nil,      "Target to debug"},
            {'b', "backend",    "kv", "auto",   "Debug backend [pyocd|openocd|jlink|auto]"},
            {'p', "port",       "kv", "3333",   "GDB server port"},
            {nil, "server-only","k",  nil,      "Start GDB server only"},
            {nil, "attach",     "k",  nil,      "Attach to running server"},
            {nil, "kill",       "k",  nil,      "Kill GDB server"},
            {nil, "status",     "k",  nil,      "Show server status"},
            {'i', "init",       "kv", nil,      "GDB init file"},
            {nil, "break",      "kv", "main",   "Initial breakpoint symbol"},
            {nil, "rtt",        "k",  nil,      "Enable RTT"},
            {nil, "rtt-port",   "kv", "19021",  "RTT TCP port"},
            {nil, "tui",        "k",  nil,      "Use GDB TUI mode"},
            {nil, "vscode",     "k",  nil,      "Generate VSCode launch.json"},
            {nil, "kill-on-exit","k", nil,      "Kill server when GDB exits"},
        }
    }
    
    on_run(function()
        import("core.base.option")
        import("core.project.config")
        import("core.project.project")
        import("core.base.json")
        import("lib.detect.find_tool")
        
        -- Load server_manager from same directory
        local server_manager = import("server_manager", {rootdir = os.scriptdir()})
        
        -- Load configuration
        config.load()
        
        -- Helper: detect embedded toolchain from target
        local function detect_embedded_toolchain(target)
            local toolchain = target:values("embedded.toolchain")
            if toolchain then
                return type(toolchain) == "table" and toolchain[1] or toolchain
            end
            
            local cc = target:tool("cc")
            if cc then
                if cc:find("arm%-none%-eabi%-gcc") then
                    return "gcc-arm"
                elseif cc:find("clang") then
                    return "clang-arm"
                end
            end
            
            return "gcc-arm"
        end
        
        -- Helper: find GDB for toolchain
        local function find_gdb_for_toolchain(toolchain)
            local gdb_names = {
                ["gcc-arm"] = {"arm-none-eabi-gdb"},
                ["clang-arm"] = {"lldb", "gdb-multiarch", "arm-none-eabi-gdb"},
                ["default"] = {"gdb"}
            }
            
            local names = gdb_names[toolchain] or gdb_names["default"]
            for _, name in ipairs(names) do
                local gdb = find_tool(name)
                if gdb then
                    return gdb
                end
            end
            return nil
        end
        
        -- Helper: find debug backend
        local function find_backend(backend_name)
            if backend_name == "auto" then
                local pyocd = find_tool("pyocd")
                if pyocd then return "pyocd", pyocd end
                
                local openocd = find_tool("openocd")
                if openocd then return "openocd", openocd end
                
                return nil, nil
            elseif backend_name == "pyocd" then
                return "pyocd", find_tool("pyocd")
            elseif backend_name == "openocd" then
                return "openocd", find_tool("openocd")
            elseif backend_name == "jlink" then
                return "jlink", find_tool("JLinkGDBServer") or find_tool("JLinkGDBServerCLExe")
            end
            return nil, nil
        end
        
        -- Helper: build GDB commands
        local function build_gdb_commands(cfg)
            local commands = {}
            local port = cfg.port or 3333
            
            if cfg.backend == "openocd" or cfg.backend == "pyocd" then
                table.insert(commands, "target extended-remote localhost:" .. port)
                table.insert(commands, "monitor reset halt")
                table.insert(commands, "load")
                table.insert(commands, "monitor reset init")
            elseif cfg.backend == "jlink" then
                table.insert(commands, "target remote localhost:" .. port)
                table.insert(commands, "monitor reset")
                table.insert(commands, "load")
                table.insert(commands, "monitor reset")
            end
            
            table.insert(commands, "break " .. (cfg.break_symbol or "main"))
            table.insert(commands, "continue")
            
            return commands
        end
        
        -- Handle server management commands
        if option.get("kill") then
            server_manager.stop()
            return
        end
        
        if option.get("status") then
            local status = server_manager.status()
            if status then
                print("GDB Server Status:")
                print("  PID: " .. status.pid)
                print("  Port: " .. status.port)
                print("  Backend: " .. status.backend)
                print("  Alive: " .. (status.alive and "yes" or "no"))
                print("  Port active: " .. (status.port_active and "yes" or "no"))
            else
                print("No GDB server is running")
            end
            return
        end
        
        -- Get target
        local targetname = option.get("target")
        local target_obj = nil
        
        if targetname then
            target_obj = project.target(targetname)
            if not target_obj then
                raise("Target not found: " .. targetname)
            end
        else
            for _, t in pairs(project.targets()) do
                if t:rule("embedded") then
                    target_obj = t
                    break
                end
            end
            
            if not target_obj then
                for _, t in pairs(project.targets()) do
                    if t:get("default") ~= false then
                        target_obj = t
                        break
                    end
                end
            end
        end
        
        if not target_obj then
            raise("No target found. Specify with --target")
        end
        
        print("=> Target: " .. target_obj:name())
        
        -- Build configuration
        local debug_config = {
            port = tonumber(option.get("port")) or 3333,
            backend = option.get("backend"),
            break_symbol = option.get("break"),
            rtt = option.get("rtt"),
            init_file = option.get("init"),
            kill_on_exit = option.get("kill-on-exit"),
        }
        
        -- Auto-detect backend
        local backend_name, backend_tool = find_backend(debug_config.backend)
        if not backend_name then
            raise("No debug backend found. Install PyOCD or OpenOCD.")
        end
        debug_config.backend = backend_name
        
        print("=> Backend: " .. debug_config.backend)
        
        -- Generate VSCode launch.json if requested
        if option.get("vscode") then
            local mcu = target_obj:values("embedded.mcu")
            if type(mcu) == "table" then mcu = mcu[1] end
            
            local launch = {
                version = "0.2.0",
                configurations = {{
                    name = "Debug " .. target_obj:name(),
                    type = "cortex-debug",
                    request = "launch",
                    servertype = debug_config.backend,
                    cwd = "${workspaceFolder}",
                    executable = "${workspaceFolder}/" .. path.relative(target_obj:targetfile() or "build/target", os.projectdir()),
                    device = mcu,
                    runToEntryPoint = debug_config.break_symbol or "main",
                }}
            }
            
            local vscode_dir = path.join(os.projectdir(), ".vscode")
            os.mkdir(vscode_dir)
            json.savefile(path.join(vscode_dir, "launch.json"), launch)
            print("Generated: .vscode/launch.json")
            return
        end
        
        -- Ensure target is built
        local targetfile = target_obj:targetfile()
        if not targetfile or not os.isfile(targetfile) then
            print("=> Building target...")
            os.execv("xmake", {"build", target_obj:name()})
            targetfile = target_obj:targetfile()
        end
        
        if not targetfile or not os.isfile(targetfile) then
            raise("Target binary not found")
        end
        
        -- Start server if not in attach mode
        local server_pid = nil
        if not option.get("attach") then
            server_pid = server_manager.start(debug_config)
        end
        
        -- Server-only mode
        if option.get("server-only") then
            print("")
            print("GDB server running. Connect with:")
            print("  arm-none-eabi-gdb " .. targetfile .. " -ex 'target remote localhost:" .. debug_config.port .. "'")
            print("")
            print("Press Ctrl+C to stop the server")
            
            while true do
                os.sleep(1000)
                local st = server_manager.status()
                if not st or not st.alive then break end
            end
            return
        end
        
        -- Find GDB
        local toolchain = detect_embedded_toolchain(target_obj)
        local gdb = find_gdb_for_toolchain(toolchain)
        
        if not gdb then
            print("GDB not found. Server is running at localhost:" .. debug_config.port)
            return
        end
        
        print("=> GDB: " .. gdb.program)
        
        -- Build GDB arguments
        local gdb_args = {targetfile}
        for _, cmd in ipairs(build_gdb_commands(debug_config)) do
            table.insert(gdb_args, "-ex")
            table.insert(gdb_args, cmd)
        end
        
        if option.get("tui") and not is_host("windows") then
            table.insert(gdb_args, "-tui")
        end
        
        print("")
        print("Starting GDB...")
        local exit_code = os.execv(gdb.program, gdb_args)
        
        if debug_config.kill_on_exit then
            server_manager.stop()
        end
        
        return exit_code
    end)
task_end()

-- Server cleanup task
task("debugger.cleanup")
    set_category("action")
    set_menu {
        usage = "xmake debugger.cleanup",
        description = "Kill all orphaned GDB server processes"
    }
    
    on_run(function()
        local server_manager = import("server_manager", {rootdir = os.scriptdir()})
        local killed = server_manager.cleanup()
        print("Cleaned up " .. killed .. " orphaned process(es)")
    end)
task_end()
