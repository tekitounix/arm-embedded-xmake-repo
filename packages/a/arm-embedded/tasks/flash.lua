-- Flash task for ARM embedded targets using PyOCD

task("flash")
    set_category("plugin")
    set_menu {
        usage = "xmake flash [options] [target]",
        description = "Flash ARM embedded target using PyOCD",
        options = {
            {'t', "target", "kv", nil, "Specify target to flash"},
            {'d', "device", "kv", nil, "Override target device (e.g., stm32f407vg)"},
            {'f', "frequency", "kv", nil, "Set SWD clock frequency (e.g., 1M, 4M)"},
            {'e', "erase", "k", nil, "Perform chip erase before programming"},
            {'r', "reset", "k", nil, "Reset target after programming"},
            {'n', "no-reset", "k", nil, "Do not reset target after programming"},
            {nil, "probe", "kv", nil, "Specify debug probe to use"},
            {nil, "connect", "kv", nil, "Connection mode (halt, pre-reset, under-reset)"}
        }
    }
    
    on_run(function()
        import("core.base.option")
        import("core.project.project")
        import("core.project.target")
        import("core.project.config")
        
        -- Load project configuration
        config.load()
        project.load()
        
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
                raise("No embedded target found. Please specify a target.")
            end
        end
        
        -- Build target first if needed
        import("core.base.task")
        task.run("build", {target = target_obj:name()})
        
        -- Get binary file
        local binfile = target_obj:data("embedded.binfile")
        if not binfile or not os.isfile(binfile) then
            -- Try to find binary file
            local targetfile = target_obj:targetfile()
            binfile = path.join(path.directory(targetfile), path.basename(targetfile) .. ".bin")
            
            if not os.isfile(binfile) then
                raise("Binary file not found. Make sure the target was built successfully.")
            end
        end
        
        -- Get device
        local device = option.get("device") or target_obj:data("embedded.mcu")
        if not device then
            raise([[
No target device specified. Please specify the device using one of:

1. In your xmake.lua:
   set_values("embedded.mcu", "stm32f407vg")

2. Via command line:
   $ xmake flash -d stm32f407vg

For a full list of supported targets, run:
$ pyocd list --targets
]])
        end
        
        -- Check if pyocd is available (prioritize package version)
        import("core.base.global")
        local pyocd = nil
        
        -- First, try to use pyocd from package
        local pyocd_path = path.join(global.directory(), "packages", "p", "pyocd")
        if os.isdir(pyocd_path) then
            local versions = os.dirs(path.join(pyocd_path, "*"))
            if #versions > 0 then
                table.sort(versions)
                local latest = versions[#versions]
                local installs = os.dirs(path.join(latest, "*"))
                if #installs > 0 then
                    local install_dir = installs[1]
                    local pyocd_bin = path.join(install_dir, "bin", "pyocd")
                    if os.isfile(pyocd_bin) then
                        pyocd = {program = pyocd_bin}
                        print("Using PyOCD from package: " .. pyocd_bin)
                    end
                end
            end
        end
        
        -- Fallback to system pyocd
        if not pyocd then
            import("lib.detect.find_tool")
            pyocd = find_tool("pyocd")
            if pyocd then
                print("Using system PyOCD: " .. pyocd.program)
            end
        end
        
        if not pyocd then
            raise([[
PyOCD not found. Please install PyOCD using one of the following methods:

1. Install via xmake (recommended):
   $ xmake require pyocd

2. Install via pip:
   $ pip install pyocd==0.34.2

3. Install via your package manager:
   - macOS: brew install pyocd
   - Ubuntu: apt install python3-pyocd
   
Note: The flash task requires PyOCD to communicate with the target device.
Make sure your debug probe is connected and drivers are installed.
]])
        end
        
        -- Build pyocd command
        local argv = {"flash", "-t", device}
        
        -- Add optional arguments
        if option.get("frequency") then
            table.insert(argv, "-f")
            table.insert(argv, option.get("frequency"))
        end
        
        if option.get("erase") then
            table.insert(argv, "-e")
            table.insert(argv, "chip")
        end
        
        if option.get("probe") then
            table.insert(argv, "--probe")
            table.insert(argv, option.get("probe"))
        end
        
        if option.get("connect") then
            table.insert(argv, "--connect")
            table.insert(argv, option.get("connect"))
        end
        
        -- Add binary file
        table.insert(argv, binfile)
        
        -- Reset behavior
        if option.get("no-reset") then
            table.insert(argv, "--no-reset")
        elseif option.get("reset") then
            table.insert(argv, "--reset-type")
            table.insert(argv, "hw")
        end
        
        -- Execute pyocd
        print("=> Flashing %s to %s", path.filename(binfile), device)
        local ok, errors = os.execv(pyocd.program, argv, {try = true})
        
        if ok then
            print("=> Flash completed successfully")
        else
            print("")
            print("Error: Flash operation failed")
            print("Details: " .. (errors or "unknown error"))
            print("")
            print("Troubleshooting:")
            print("1. Check debug probe connection")
            print("2. Verify target power supply")
            print("3. Try different USB port/cable")
            print("4. Update probe firmware if needed")
            print("5. Run with elevated privileges if necessary")
            print("")
            print("For more verbose output, run:")
            print("  $ pyocd flash --verbose " .. binfile)
            os.exit(1)
        end
    end)