--!Debugger Task for ARM Embedded Development
--
-- Provides unified debugging interface for embedded and host targets
--

task("debugger")
    set_category("action")
    
    on_run(function()
        import("core.base.option")
        import("core.project.config")
        import("core.project.project")
        import("core.project.task")
        import("lib.detect.find_tool")
        
        -- Load configuration
        config.load()
        
        -- Get target name
        local targetname = option.get("target")
        if not targetname then
            -- Try to find default target
            for _, target in pairs(project.targets()) do
                if target:get("default") ~= false then
                    targetname = target:name()
                    break
                end
            end
        end
        
        if not targetname then
            raise("No target specified. Use: xmake debugger --target=targetname")
        end
        
        local target = project.target(targetname)
        if not target then
            raise("Unknown target: " .. targetname)
        end
        
        -- Check if debug build exists
        if not is_mode("debug") then
            print("Warning: Not in debug mode. Switching to debug configuration...")
            os.exec("xmake config -m debug")
            print("Building " .. targetname .. " in debug mode...")
            task.run("build", {target = targetname})
        elseif not os.isfile(target:targetfile()) then
            print("Building " .. targetname .. "...")
            task.run("build", {target = targetname})
        end
        
        -- Get debug options
        local debug_profile = option.get("profile") or target:values("debug.profile")
        local gdb_init = option.get("init") or target:values("debug.init")
        
        -- Check if it's an embedded target
        if target:rule("embedded") or target:rule("embedded.test") then
            debug_embedded_target(target, debug_profile, gdb_init)
        else
            debug_host_target(target)
        end
    end)
    
    -- Debug embedded target with GDB
    function debug_embedded_target(target, profile, gdb_init)
        print("Starting embedded debug session for: " .. target:name())
        
        -- Detect toolchain
        local toolchain = detect_embedded_toolchain(target)
        local gdb_cmd = toolchain == "gcc-arm" and "arm-none-eabi-gdb" or "lldb"
        
        -- Find GDB
        local gdb = find_tool(gdb_cmd)
        if not gdb then
            raise("GDB not found. Please ensure " .. gdb_cmd .. " is in your PATH")
        end
        
        -- Determine debug profile
        profile = profile or "openocd"
        
        local debug_commands = {}
        
        if profile == "openocd" then
            -- OpenOCD configuration
            table.insert(debug_commands, "target extended-remote :3333")
            table.insert(debug_commands, "monitor reset halt")
            table.insert(debug_commands, "load")
            table.insert(debug_commands, "monitor reset init")
            table.insert(debug_commands, "break main")
            table.insert(debug_commands, "continue")
            
            print("Make sure OpenOCD is running with appropriate configuration")
            print("Example: openocd -f interface/stlink.cfg -f target/stm32f4x.cfg")
            
        elseif profile == "jlink" then
            -- J-Link configuration
            table.insert(debug_commands, "target remote :2331")
            table.insert(debug_commands, "monitor reset")
            table.insert(debug_commands, "load")
            table.insert(debug_commands, "monitor reset")
            table.insert(debug_commands, "break main")
            table.insert(debug_commands, "continue")
            
            print("Make sure J-Link GDB Server is running")
            print("Example: JLinkGDBServer -device STM32F407VG -if SWD")
            
        elseif profile == "stlink" then
            -- ST-Link configuration (using st-util)
            table.insert(debug_commands, "target extended-remote :4242")
            table.insert(debug_commands, "load")
            table.insert(debug_commands, "break main")
            table.insert(debug_commands, "continue")
            
            print("Make sure st-util is running")
            print("Example: st-util")
            
        elseif profile == "pyocd" then
            -- PyOCD configuration
            table.insert(debug_commands, "target remote :3333")
            table.insert(debug_commands, "monitor reset halt")
            table.insert(debug_commands, "load")
            table.insert(debug_commands, "monitor reset")
            table.insert(debug_commands, "break main")
            table.insert(debug_commands, "continue")
            
            local mcu = target:values("embedded.mcu")
            local mcu_name = mcu and (type(mcu) == "table" and mcu[1] or mcu) or "unknown"
            
            print("Make sure PyOCD is running")
            print("Example: pyocd gdbserver -t " .. mcu_name)
            
        elseif profile == "blackmagic" then
            -- Black Magic Probe configuration
            local port = is_host("windows") and "COM3" or "/dev/ttyACM0"
            table.insert(debug_commands, "target extended-remote " .. port)
            table.insert(debug_commands, "monitor swdp_scan")
            table.insert(debug_commands, "attach 1")
            table.insert(debug_commands, "load")
            table.insert(debug_commands, "break main")
            table.insert(debug_commands, "run")
            
            print("Using Black Magic Probe on " .. port)
        else
            raise("Unknown debug profile: " .. profile)
        end
        
        -- Build GDB command
        local cmd_args = {target:targetfile()}
        
        -- Add initialization commands
        for _, cmd in ipairs(debug_commands) do
            table.insert(cmd_args, "-ex")
            table.insert(cmd_args, cmd)
        end
        
        -- Add custom init file if specified
        if gdb_init and os.isfile(gdb_init) then
            table.insert(cmd_args, "-x")
            table.insert(cmd_args, gdb_init)
        end
        
        -- Add TUI mode for better interface
        if not is_host("windows") then
            table.insert(cmd_args, "-tui")
        end
        
        -- Execute GDB
        print("")
        print("Launching GDB...")
        os.execv(gdb.program, cmd_args)
    end
    
    -- Debug host target
    function debug_host_target(target)
        print("Starting host debug session for: " .. target:name())
        
        local debugger = nil
        local cmd_args = {}
        
        if is_host("windows") then
            -- Windows: Try to find appropriate debugger
            debugger = find_tool("gdb") or find_tool("lldb")
            if not debugger then
                raise("No debugger found. Please install GDB or LLDB")
            end
            
        elseif is_host("macosx") then
            -- macOS: Prefer LLDB
            debugger = find_tool("lldb")
            if debugger then
                cmd_args = {"--", target:targetfile()}
            else
                debugger = find_tool("gdb")
                cmd_args = {target:targetfile()}
            end
            
        else
            -- Linux: Prefer GDB
            debugger = find_tool("gdb")
            if debugger then
                cmd_args = {target:targetfile(), "-tui"}
            else
                debugger = find_tool("lldb")
                cmd_args = {"--", target:targetfile()}
            end
        end
        
        if not debugger then
            raise("No debugger found. Please install GDB or LLDB")
        end
        
        print("Using debugger: " .. debugger.program)
        os.execv(debugger.program, cmd_args)
    end
    
    -- Detect embedded toolchain
    function detect_embedded_toolchain(target)
        local toolchain = target:values("embedded.toolchain")
        if toolchain then
            return type(toolchain) == "table" and toolchain[1] or toolchain
        end
        
        -- Try to detect from compiler
        local cc = target:tool("cc")
        if cc and cc:find("arm%-none%-eabi%-gcc") then
            return "gcc-arm"
        elseif cc and cc:find("clang") then
            return "clang-arm"
        end
        
        return "gcc-arm" -- default
    end
    
    -- Define menu
    set_menu {
        usage = "xmake debugger [options] [target]",
        description = "Debug embedded or host targets with GDB/LLDB",
        options = {
            {'p', "profile",   "kv", nil, "Debug profile (openocd|jlink|stlink|pyocd|blackmagic)"},
            {'i', "init",      "kv", nil, "GDB init file"},
            {},
            {nil, "target",    "v",  nil, "Target to debug"}
        }
    }