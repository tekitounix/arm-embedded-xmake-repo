package("arm-embedded")
    set_kind("library")
    set_description("ARM embedded development environment with toolchains, rules, and flashing support")
    set_homepage("https://github.com/arm/arm-toolchain")
    
    -- Dependencies (let user choose specific versions)
    add_deps("clang-arm")
    add_deps("gcc-arm")
    -- Python3 and PyOCD are optional dependencies for flash functionality
    -- Users can install them separately if needed: xmake require python3 pyocd
    
    -- Development version
    add_versions("0.1.0-dev", "dummy")
    add_versions("0.1.1", "dummy")
    add_versions("0.1.2", "dummy")
    add_versions("0.1.3", "dummy")
    add_versions("0.1.4", "dummy")
    add_versions("0.1.5", "dummy")
    add_versions("0.1.6", "dummy")
    add_versions("0.1.7", "dummy")
    add_versions("0.1.8", "dummy")
    add_versions("0.1.9", "dummy")
    add_versions("0.1.10", "dummy")
    add_versions("0.2.0", "dummy")
    add_versions("0.3.0", "dummy")  -- 2026-02: clang-arm 21.1.1, gcc-arm 15.2.1
    
    
    on_load(function (package)
        -- Install rule and task definitions to user's xmake directory during on_load
        import("core.base.global")
        
        -- Install embedded rule and database modules
        local user_rule_dir = path.join(global.directory(), "rules", "embedded")
        local user_database_dir = path.join(user_rule_dir, "database")
        os.mkdir(user_rule_dir)
        os.mkdir(user_database_dir)
        
        -- Copy main rule file
        local rule_content = io.readfile(path.join(os.scriptdir(), "rules", "embedded", "xmake.lua"))
        if rule_content then
            local dest_file = path.join(user_rule_dir, "xmake.lua")
            
            local need_update = true
            if os.isfile(dest_file) then
                local dst_content = io.readfile(dest_file)
                if rule_content == dst_content then
                    need_update = false
                end
            end
            
            if need_update then
                io.writefile(dest_file, rule_content)
                print("=> Embedded rule installed to: %s", user_rule_dir)
            end
        end
        
        -- Copy database modules (JSON files for new system)
        local db_files = {"cortex-m.json", "mcu-database.json", "build-options.json", "toolchain-configs.json"}
        for _, filename in ipairs(db_files) do
            local content = io.readfile(path.join(os.scriptdir(), "rules", "embedded", "database", filename))
            if content then
                io.writefile(path.join(user_database_dir, filename), content)
            end
        end
        
        -- Copy linker directory
        local user_linker_dir = path.join(user_rule_dir, "linker")
        os.mkdir(user_linker_dir)
        local linker_content = io.readfile(path.join(os.scriptdir(), "rules", "embedded", "linker", "common.ld"))
        if linker_content then
            io.writefile(path.join(user_linker_dir, "common.ld"), linker_content)
        end
        
        -- Install VSCode integration rules (rule name: embedded.vscode)
        local user_vscode_dir = path.join(global.directory(), "rules", "embedded.vscode")
        os.mkdir(user_vscode_dir)
        local vscode_content = io.readfile(path.join(os.scriptdir(), "rules", "vscode", "xmake.lua"))
        if vscode_content then
            local dest_file = path.join(user_vscode_dir, "xmake.lua")
            
            local need_update = true
            if os.isfile(dest_file) then
                local dst_content = io.readfile(dest_file)
                if vscode_content == dst_content then
                    need_update = false
                end
            end
            
            if need_update then
                io.writefile(dest_file, vscode_content)
                print("=> VSCode integration rules installed to: %s", user_vscode_dir)
            end
        end
        
        -- Install host.test rule
        local user_host_test_dir = path.join(global.directory(), "rules", "host.test")
        os.mkdir(user_host_test_dir)
        local host_test_content = io.readfile(path.join(os.scriptdir(), "rules", "host.test", "xmake.lua"))
        if host_test_content then
            local dest_file = path.join(user_host_test_dir, "xmake.lua")
            
            local need_update = true
            if os.isfile(dest_file) then
                local dst_content = io.readfile(dest_file)
                if host_test_content == dst_content then
                    need_update = false
                end
            end
            
            if need_update then
                io.writefile(dest_file, host_test_content)
                print("=> Host test rule installed to: %s", user_host_test_dir)
            end
        end
        
        -- Install embedded.test rule
        local user_embedded_test_dir = path.join(global.directory(), "rules", "embedded.test")
        os.mkdir(user_embedded_test_dir)
        local embedded_test_content = io.readfile(path.join(os.scriptdir(), "rules", "embedded.test", "xmake.lua"))
        if embedded_test_content then
            local dest_file = path.join(user_embedded_test_dir, "xmake.lua")
            
            local need_update = true
            if os.isfile(dest_file) then
                local dst_content = io.readfile(dest_file)
                if embedded_test_content == dst_content then
                    need_update = false
                end
            end
            
            if need_update then
                io.writefile(dest_file, embedded_test_content)
                print("=> Embedded test rule installed to: %s", user_embedded_test_dir)
            end
        end
        
        -- Install flash task
        local task_content = io.readfile(path.join(os.scriptdir(), "plugins", "flash", "xmake.lua"))
        if task_content then
            local user_task_dir = path.join(global.directory(), "plugins", "flash")
            local user_flash_db_dir = path.join(user_task_dir, "database")
            local dest_file = path.join(user_task_dir, "xmake.lua")
            
            local need_update = true
            if os.isfile(dest_file) then
                local dst_content = io.readfile(dest_file)
                if task_content == dst_content then
                    need_update = false
                end
            end
            
            if need_update then
                os.mkdir(user_task_dir)
                io.writefile(dest_file, task_content)
                print("=> Flash task installed to: %s", user_task_dir)
            end
            
            -- Install flash database
            os.mkdir(user_flash_db_dir)
            local flash_db_content = io.readfile(path.join(os.scriptdir(), "plugins", "flash", "database", "flash-targets.json"))
            if flash_db_content then
                io.writefile(path.join(user_flash_db_dir, "flash-targets.json"), flash_db_content)
            end
        end
        
        -- Note: 'debug' plugin removed - use 'xmake f -m debug && xmake' instead
        -- Note: 'test' plugin removed - use project-defined task or xmake standard 'xmake test'
        
        -- Install debugger task
        local debugger_content = io.readfile(path.join(os.scriptdir(), "plugins", "debugger", "xmake.lua"))
        if debugger_content then
            local user_debugger_dir = path.join(global.directory(), "plugins", "debugger")
            local dest_file = path.join(user_debugger_dir, "xmake.lua")
            
            local need_update = true
            if os.isfile(dest_file) then
                local dst_content = io.readfile(dest_file)
                if debugger_content == dst_content then
                    need_update = false
                end
            end
            
            if need_update then
                os.mkdir(user_debugger_dir)
                io.writefile(dest_file, debugger_content)
                print("=> Debugger task installed to: %s", user_debugger_dir)
            end
        end
        
        -- Install emulator task
        local emulator_content = io.readfile(path.join(os.scriptdir(), "plugins", "emulator", "xmake.lua"))
        if emulator_content then
            local user_emulator_dir = path.join(global.directory(), "plugins", "emulator")
            local dest_file = path.join(user_emulator_dir, "xmake.lua")
            
            local need_update = true
            if os.isfile(dest_file) then
                local dst_content = io.readfile(dest_file)
                if emulator_content == dst_content then
                    need_update = false
                end
            end
            
            if need_update then
                os.mkdir(user_emulator_dir)
                io.writefile(dest_file, emulator_content)
                print("=> Emulator task installed to: %s", user_emulator_dir)
            end
        end
        
        -- Install deploy task
        local deploy_content = io.readfile(path.join(os.scriptdir(), "plugins", "deploy", "xmake.lua"))
        if deploy_content then
            local user_deploy_dir = path.join(global.directory(), "plugins", "deploy")
            local dest_file = path.join(user_deploy_dir, "xmake.lua")
            
            local need_update = true
            if os.isfile(dest_file) then
                local dst_content = io.readfile(dest_file)
                if deploy_content == dst_content then
                    need_update = false
                end
            end
            
            if need_update then
                os.mkdir(user_deploy_dir)
                io.writefile(dest_file, deploy_content)
                print("=> Deploy task installed to: %s", user_deploy_dir)
            end
        end
        
        -- Install serve task
        local serve_content = io.readfile(path.join(os.scriptdir(), "plugins", "serve", "xmake.lua"))
        if serve_content then
            local user_serve_dir = path.join(global.directory(), "plugins", "serve")
            local dest_file = path.join(user_serve_dir, "xmake.lua")
            
            local need_update = true
            if os.isfile(dest_file) then
                local dst_content = io.readfile(dest_file)
                if serve_content == dst_content then
                    need_update = false
                end
            end
            
            if need_update then
                os.mkdir(user_serve_dir)
                io.writefile(dest_file, serve_content)
                print("=> Serve task installed to: %s", user_serve_dir)
            end
        end
        
        -- Install utils modules
        local utils_dir = path.join(os.scriptdir(), "utils")
        if os.isdir(utils_dir) then
            local user_utils_dir = path.join(global.directory(), "modules", "utils")
            os.mkdir(user_utils_dir)
            
            for _, util_file in ipairs(os.files(path.join(utils_dir, "*.lua"))) do
                local filename = path.filename(util_file)
                local util_content = io.readfile(util_file)
                if util_content then
                    io.writefile(path.join(user_utils_dir, filename), util_content)
                end
            end
        end
        
        -- Install debugger server_manager module
        local server_manager_content = io.readfile(path.join(os.scriptdir(), "plugins", "debugger", "server_manager.lua"))
        if server_manager_content then
            local user_debugger_dir = path.join(global.directory(), "plugins", "debugger")
            os.mkdir(user_debugger_dir)
            io.writefile(path.join(user_debugger_dir, "server_manager.lua"), server_manager_content)
        end
        
        -- Install flash backends
        local flash_backends_dir = path.join(os.scriptdir(), "plugins", "flash", "backends")
        if os.isdir(flash_backends_dir) then
            local user_backends_dir = path.join(global.directory(), "plugins", "flash", "backends")
            os.mkdir(user_backends_dir)
            
            for _, backend_file in ipairs(os.files(path.join(flash_backends_dir, "*.lua"))) do
                local filename = path.filename(backend_file)
                local backend_content = io.readfile(backend_file)
                if backend_content then
                    io.writefile(path.join(user_backends_dir, filename), backend_content)
                end
            end
        end
        
        -- Install flash-targets-v2.json
        local flash_db_v2 = io.readfile(path.join(os.scriptdir(), "plugins", "flash", "database", "flash-targets-v2.json"))
        if flash_db_v2 then
            local user_flash_db_dir = path.join(global.directory(), "plugins", "flash", "database")
            os.mkdir(user_flash_db_dir)
            io.writefile(path.join(user_flash_db_dir, "flash-targets-v2.json"), flash_db_v2)
        end
        
        -- Note: 'show' plugin removed - use xmake standard 'xmake show' instead
        -- For embedded-specific info, use 'xmake info' task defined in the project
    end)
    
    on_install(function (package)
        -- Linker scripts are now part of the embedded rule
        -- No separate installation needed
        -- The actual installation happens in on_load to ensure rules are available early
        
        -- Verify that all required files were installed
        import("core.base.global")
        
        -- Check embedded rule
        local embedded_rule = path.join(global.directory(), "rules", "embedded", "xmake.lua")
        if not os.isfile(embedded_rule) then
            raise("Embedded rule not installed correctly")
        end
        
        -- Check flash task
        local flash_task = path.join(global.directory(), "plugins", "flash", "xmake.lua")
        if not os.isfile(flash_task) then
            raise("Flash task not installed correctly")
        end
        
        print("ARM Embedded package installed successfully")
    end)
    
    
    on_test(function (package)
        -- Test if dependencies are available and functional
        local clang = package:dep("clang-arm")
        local pyocd = package:dep("pyocd")
        
        -- Test if embedded rule was properly installed
        import("core.base.global")
        local embedded_rule = path.join(global.directory(), "rules", "embedded", "xmake.lua")
        assert(os.isfile(embedded_rule), "Embedded rule not found")
        
        -- Test if flash task was properly installed
        local flash_task = path.join(global.directory(), "plugins", "flash", "xmake.lua")
        assert(os.isfile(flash_task), "Flash task not found")
        
        -- Test if database files were properly installed
        local mcu_db = path.join(global.directory(), "rules", "embedded", "database", "mcu-database.json")
        assert(os.isfile(mcu_db), "MCU database not found")
        
        -- Test if linker script was properly installed
        local linker_script = path.join(global.directory(), "rules", "embedded", "linker", "common.ld")
        assert(os.isfile(linker_script), "Linker script not found")
        
        -- Test dependency functionality if available
        if clang then
            local clang_bin = path.join(clang:installdir(), "bin", "clang")
            if clang:is_plat("windows") then
                clang_bin = clang_bin .. ".exe"
            end
            if os.isfile(clang_bin) then
                local ok = try { function()
                    os.vrunv(clang_bin, {"--version"})
                    return true
                end }
                if ok then
                    print("Clang ARM: OK")
                end
            end
        end
        
        if pyocd then
            local pyocd_bin = path.join(pyocd:installdir(), "bin", "pyocd")
            if pyocd:is_plat("windows") then
                pyocd_bin = pyocd_bin .. ".bat"
            end
            if os.isfile(pyocd_bin) then
                local ok = try { function()
                    os.vrunv(pyocd_bin, {"--version"})
                    return true
                end }
                if ok then
                    print("PyOCD: OK")
                end
            end
        end
        
        print("ARM Embedded environment: OK")
    end)

