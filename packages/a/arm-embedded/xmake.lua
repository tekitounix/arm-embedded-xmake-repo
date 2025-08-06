package("arm-embedded")
    set_kind("library")
    set_description("ARM embedded development environment with toolchains, rules, and flashing support")
    set_homepage("https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm")
    
    -- Dependencies (let user choose specific versions)
    add_deps("clang-arm")
    -- Python3 and PyOCD are optional dependencies for flash functionality
    -- Users can install them separately if needed: xmake require python3 pyocd
    
    -- Development version
    add_versions("0.1.0-dev", "dummy")
    add_versions("0.1.1", "dummy")
    add_versions("0.1.2", "dummy")
    add_versions("0.1.3", "dummy")
    add_versions("0.1.4", "dummy")
    add_versions("0.1.5", "dummy")
    
    
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
        
        -- Install VSCode integration rules
        local user_vscode_dir = path.join(global.directory(), "rules", "vscode")
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
        
        -- Install debug task
        local debug_content = io.readfile(path.join(os.scriptdir(), "plugins", "debug", "xmake.lua"))
        if debug_content then
            local user_debug_dir = path.join(global.directory(), "plugins", "debug")
            local dest_file = path.join(user_debug_dir, "xmake.lua")
            
            local need_update = true
            if os.isfile(dest_file) then
                local dst_content = io.readfile(dest_file)
                if debug_content == dst_content then
                    need_update = false
                end
            end
            
            if need_update then
                os.mkdir(user_debug_dir)
                io.writefile(dest_file, debug_content)
                print("=> Debug task installed to: %s", user_debug_dir)
            end
        end
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

