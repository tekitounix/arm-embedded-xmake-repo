--!Emulator Plugin v2 - Unified Renode interface

-- Main emulator task (help/dispatch)
task("emulator")
    set_category("action")
    on_run(function()
        import("lib.detect.find_tool")
        
        print("Emulator tasks:")
        print("")
        print("  xmake emulator.run [options]   Start Renode emulator")
        print("  xmake emulator.test [options]  Run automated tests")
        print("")
        print("Options:")
        print("  -t, --target=TARGET    Target to emulate")
        print("  -s, --script=FILE      Renode script (.resc)")
        print("  -p, --platform=FILE    Platform description (.repl)")
        print("      --headless         Headless mode (no GUI)")
        print("      --gdb              Enable GDB server")
        print("      --gdb-port=PORT    GDB port (default: 3333)")
        print("      --generate         Generate .resc script from target")
        print("")
        print("Tool status:")
        
        local renode = find_tool("renode")
        if not renode then
            -- Check macOS app location
            local app_path = "/Applications/Renode.app/Contents/MacOS/renode"
            if os.isfile(app_path) then
                renode = {program = app_path}
            end
        end
        
        if renode then
            print("  Renode: " .. renode.program)
        else
            print("  Renode: not found")
            print("          Install with: xmake require renode")
        end
    end)
    set_menu {
        usage = "xmake emulator",
        description = "Show emulator help and status"
    }
task_end()

-- Interactive Renode session
task("emulator.run")
    set_category("action")
    on_run(function()
        import("core.base.option")
        import("core.project.config")
        import("core.project.project")
        import("lib.detect.find_tool")
        
        config.load()
        
        -- Find Renode
        local renode = find_tool("renode")
        if not renode then
            local app_path = "/Applications/Renode.app/Contents/MacOS/renode"
            if os.isfile(app_path) then
                renode = {program = app_path}
            end
        end
        
        if not renode then
            raise("Renode not found. Install with: xmake require renode")
        end
        
        print("Using Renode: " .. renode.program)
        
        -- Get options
        local script = option.get("script")
        local platform = option.get("platform")
        local headless = option.get("headless")
        local gdb_enabled = option.get("gdb")
        local gdb_port = option.get("gdb-port") or "3333"
        local generate = option.get("generate")
        local targetname = option.get("target")
        
        -- Get target if specified
        local target = nil
        if targetname then
            target = project.target(targetname)
            if not target then
                raise("Target not found: " .. targetname)
            end
        elseif not script then
            for _, t in pairs(project.targets()) do
                if t:rule("embedded") then
                    target = t
                    break
                end
            end
        end
        
        -- Get configuration from target values
        if target then
            script = script or target:values("emulator.script")
            platform = platform or target:values("emulator.platform")
            gdb_enabled = gdb_enabled or target:values("emulator.gdb")
            
            if type(script) == "table" then script = script[1] end
            if type(platform) == "table" then platform = platform[1] end
        end
        
        -- Generate script if requested
        if generate and target then
            local firmware = target:targetfile()
            local mcu = target:values("embedded.mcu")
            if type(mcu) == "table" then mcu = mcu[1] end
            mcu = mcu or "stm32f4"
            
            if not platform then
                local search_paths = {
                    path.join(os.projectdir(), "renode", mcu:lower() .. ".repl"),
                    path.join(os.projectdir(), "renode", "platform.repl"),
                }
                for _, p in ipairs(search_paths) do
                    if os.isfile(p) then
                        platform = p
                        break
                    end
                end
                if not platform then
                    raise("No platform file (.repl) found. Specify with --platform=FILE")
                end
            end
            
            local script_content = string.format([[
# Auto-generated Renode script for %s
mach create "%s"
machine LoadPlatformDescription @%s
sysbus LoadELF @%s
showAnalyzer sysbus.uart1
]], target:name(), target:name(), platform, firmware)
            
            if gdb_enabled then
                script_content = script_content .. string.format("\nmachine StartGdbServer %s\n", gdb_port)
            end
            script_content = script_content .. "\nstart\n"
            
            local script_dir = path.join(os.projectdir(), "build", "renode")
            os.mkdir(script_dir)
            script = path.join(script_dir, target:name() .. ".resc")
            io.writefile(script, script_content)
            print("Generated script: " .. script)
        end
        
        -- Build Renode arguments
        local args = {}
        
        if headless then
            table.insert(args, "--disable-xwt")
            table.insert(args, "--console")
        end
        
        if script then
            if not os.isfile(script) then
                raise("Renode script not found: " .. script)
            end
            table.insert(args, script)
        end
        
        print("")
        print("Starting Renode...")
        if gdb_enabled then
            print("GDB server will be available on port " .. gdb_port)
        end
        
        os.execv(renode.program, args)
    end)
    set_menu {
        usage = "xmake emulator.run [options]",
        description = "Start Renode emulator",
        options = {
            {'t', "target",   "kv", nil,    "Target to emulate"},
            {'s', "script",   "kv", nil,    "Renode script (.resc)"},
            {'p', "platform", "kv", nil,    "Platform description (.repl)"},
            {nil, "headless", "k",  nil,    "Headless mode (no GUI)"},
            {nil, "gdb",      "k",  nil,    "Enable GDB server"},
            {nil, "gdb-port", "kv", "3333", "GDB server port"},
            {nil, "generate", "k",  nil,    "Generate .resc script"}
        }
    }
task_end()

-- Automated Renode tests
task("emulator.test")
    set_category("action")
    on_run(function()
        import("core.base.option")
        import("core.project.config")
        import("lib.detect.find_tool")
        
        config.load()
        
        local renode_test = find_tool("renode-test")
        if not renode_test then
            local app_path = "/Applications/Renode.app/Contents/MacOS/renode-test"
            if os.isfile(app_path) then
                renode_test = {program = app_path}
            end
        end
        
        if not renode_test then
            raise("renode-test not found. Install with: xmake require renode")
        end
        
        local robot_file = option.get("robot")
        local output_dir = option.get("output") or path.join(os.projectdir(), "build", "renode-test")
        local timeout = option.get("timeout")
        
        if not robot_file then
            local search_paths = {
                path.join(os.projectdir(), "tests"),
                path.join(os.projectdir(), "renode"),
                os.projectdir()
            }
            
            for _, search_path in ipairs(search_paths) do
                local robots = os.files(path.join(search_path, "*.robot"))
                if #robots > 0 then
                    robot_file = robots[1]
                    break
                end
            end
        end
        
        if not robot_file then
            raise("No .robot file specified or found. Use --robot=FILE")
        end
        
        if not os.isfile(robot_file) then
            raise("Robot file not found: " .. robot_file)
        end
        
        print("Using renode-test: " .. renode_test.program)
        print("Running: " .. robot_file)
        
        local args = {robot_file}
        
        if output_dir then
            os.mkdir(output_dir)
            table.insert(args, "-r")
            table.insert(args, output_dir)
        end
        
        if timeout then
            table.insert(args, "-t")
            table.insert(args, tostring(timeout))
        end
        
        os.execv(renode_test.program, args)
        
        print("")
        print("Test results in: " .. output_dir)
    end)
    set_menu {
        usage = "xmake emulator.test [options]",
        description = "Run Renode Robot Framework tests",
        options = {
            {'r', "robot",   "kv", nil, "Robot Framework test file (.robot)"},
            {'o', "output",  "kv", nil, "Output directory for results"},
            {'t', "timeout", "kv", nil, "Test timeout in seconds"}
        }
    }
task_end()

