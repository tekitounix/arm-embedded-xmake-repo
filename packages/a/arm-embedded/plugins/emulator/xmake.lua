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
        import("core.base.json")
        
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

        -- Detect MCU family for platform selection
        local function detect_family(mcu)
            if not mcu then return nil end
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
                {"^rp2040", "rp2040"}
            }
            local lower_mcu = mcu:lower()
            for _, p in ipairs(patterns) do
                if lower_mcu:match(p[1]) then
                    return p[2]
                end
            end
            return nil
        end

        local function find_platform_file(mcu, target_name)
            local family = detect_family(mcu or "")
            local roots = {
                path.join(os.projectdir(), "lib", "umi", "port", "platform", "renode")
            }
            local names = {}
            if family then
                if target_name and target_name:lower():find("test") then
                    table.insert(names, family .. "_test.repl")
                end
                table.insert(names, family .. "_umi.repl")
                table.insert(names, family .. ".repl")
            end
            for _, root in ipairs(roots) do
                for _, name in ipairs(names) do
                    local candidate = path.join(root, name)
                    if os.isfile(candidate) then
                        return candidate
                    end
                end
                local repls = os.files(path.join(root, "*.repl"))
                if #repls > 0 then
                    return repls[1]
                end
            end
            return nil
        end
        
        -- Generate script if requested
        if generate and target then
            local firmware = target:targetfile()
            local mcu = target:values("embedded.mcu")
            if type(mcu) == "table" then mcu = mcu[1] end
            mcu = mcu or "stm32f4"

            if not firmware or not os.isfile(firmware) then
                print("=> Building target...")
                os.execv("xmake", {"build", target:name()})
                firmware = target:targetfile()
            end
            if not firmware or not os.isfile(firmware) then
                raise("Target binary not found: " .. (firmware or "nil"))
            end
            
            if not platform then
                platform = find_platform_file(mcu, target:name())
                if not platform then
                    raise("No platform file (.repl) found. Specify with --platform=FILE")
                end
            end
            
            local script_content = string.format([[
# Auto-generated Renode script for %s
mach create "%s"
machine LoadPlatformDescription @%s
sysbus LoadELF @%s
showAnalyzer sysbus.usart2
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
        import("core.project.project")
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

        local function detect_family(mcu)
            if not mcu then return nil end
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
                {"^rp2040", "rp2040"}
            }
            local lower_mcu = mcu:lower()
            for _, p in ipairs(patterns) do
                if lower_mcu:match(p[1]) then
                    return p[2]
                end
            end
            return nil
        end

        local function find_platform_file(mcu, target_name)
            local family = detect_family(mcu or "")
            local roots = {
                path.join(os.projectdir(), "lib", "umi", "port", "platform", "renode")
            }
            local names = {}
            if family then
                if target_name and target_name:lower():find("test") then
                    table.insert(names, family .. "_test.repl")
                end
                table.insert(names, family .. "_umi.repl")
                table.insert(names, family .. ".repl")
            end
            for _, root in ipairs(roots) do
                for _, name in ipairs(names) do
                    local candidate = path.join(root, name)
                    if os.isfile(candidate) then
                        return candidate
                    end
                end
                local repls = os.files(path.join(root, "*.repl"))
                if #repls > 0 then
                    return repls[1]
                end
            end
            return nil
        end

        -- Ensure Robot Framework dependencies are available
        local function ensure_robotframework()
            local ok = os.execv("python3", {"-c", "import robot"}, {try = true})
            if ok == 0 then
                return true
            end

            local base_dir = path.directory(renode_test.program)
            local req_file = path.join(base_dir, "tests", "requirements.txt")
            if not os.isfile(req_file) then
                raise("Robot Framework not found and requirements.txt is missing: " .. req_file)
            end

            print("Robot Framework not found. Installing dependencies...")
            local pip_ok = os.execv("python3", {"-m", "pip", "install", "-r", req_file}, {try = true})
            if pip_ok ~= 0 then
                raise("Failed to install Robot Framework. Please run: python3 -m pip install -r " .. req_file)
            end

            return true
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

        local function prepare_umi_renode_test(robot_path)
            local test_dir = path.directory(robot_path)
            local build_dir = path.join(path.directory(test_dir), ".build")
            local elf_dst = path.join(build_dir, "renode_test.elf")
            local log_dst = path.join(build_dir, "renode_uart.log")
            local resc_dst = path.join(test_dir, "test.resc")
            local repl_dst = path.join(test_dir, "stm32f4_test.repl")

            os.mkdir(build_dir)
            local abs_log = path.absolute(log_dst)

            local target = project.target("renode_test")
            if not target then
                raise("Target renode_test not found. Ensure examples/renode_test is included.")
            end

            if not os.isfile(elf_dst) then
                print("Building renode_test...")
                os.execv("xmake", {"build", target:name()})
                local built_elf = target:targetfile()
                if not built_elf or not os.isfile(built_elf) then
                    raise("renode_test.elf not found after build")
                end
                os.cp(built_elf, elf_dst)
            end

            if not os.isfile(repl_dst) then
                local mcu = target:values("embedded.mcu")
                if type(mcu) == "table" then mcu = mcu[1] end
                local repl_src = find_platform_file(mcu or "stm32f4", target:name())
                if not repl_src then
                    raise("No platform file (.repl) found for renode tests")
                end
                os.cp(repl_src, repl_dst)
            end

            local script_content = string.format([[
# Auto-generated Renode script for umi_tests_simple
using sysbus
mach create "umi_test"
machine LoadPlatformDescription @%s
sysbus LoadELF @%s
sysbus WriteDoubleWord 0xE000ED08 0x08000000
logFile "%s"
usart2 CreateFileBackend "%s" true
emulation RunFor "2"
quit
]], repl_dst, elf_dst, abs_log, abs_log)
            io.writefile(resc_dst, script_content)

            if not os.isfile(log_dst) then
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

                print("Generating UART log via Renode...")
                os.execv(renode.program, {"--console", "--disable-xwt", resc_dst})
            end
        end

        if robot_file:find("/lib/umi/test/renode/")
            or robot_file:find("lib/umi/test/renode/") then
            prepare_umi_renode_test(robot_file)
        end

        ensure_robotframework()
        
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

