package("arm-embedded")
    set_kind("library")
    set_description("ARM embedded development environment with toolchains, rules, and flashing support")
    set_homepage("https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm")
    
    -- Dependencies
    add_deps("gcc-arm", "llvm-arm-embedded")
    add_deps("python3", "pyocd")
    
    -- Development version
    add_versions("0.1.0-dev", "dummy")
    
    
    on_load(function (package)
        -- Install rule and task definitions to user's xmake directory during on_load
        import("core.base.global")
        
        -- Install embedded rule
        local rule_content = io.readfile(path.join(os.scriptdir(), "rules", "embedded_simple.lua"))
        if rule_content then
            local user_rule_dir = path.join(global.directory(), "rules", "embedded")
            local dest_file = path.join(user_rule_dir, "xmake.lua")
            
            local need_update = true
            if os.isfile(dest_file) then
                local dst_content = io.readfile(dest_file)
                if rule_content == dst_content then
                    need_update = false
                end
            end
            
            if need_update then
                os.mkdir(user_rule_dir)
                io.writefile(dest_file, rule_content)
                print("=> Embedded rule installed to: %s", user_rule_dir)
            end
        end
        
        -- Install flash task
        local task_content = io.readfile(path.join(os.scriptdir(), "tasks", "flash.lua"))
        if task_content then
            local user_task_dir = path.join(global.directory(), "plugins", "flash")
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
        end
    end)
    
    on_install(function (package)
        -- Copy linker scripts to package directory for runtime access
        local packagedir = os.scriptdir()
        local linker_dir = path.join(packagedir, "linker")
        
        if os.isdir(linker_dir) then
            os.cp(path.join(linker_dir, "*"), package:installdir("linker"))
        end
    end)
    
    
    on_test(function (package)
        -- Test if dependencies are available
        local llvm = package:dep("llvm-arm-embedded")
        local gcc = package:dep("gcc-arm")
        local pyocd = package:dep("pyocd")
        
        if llvm then
            print("LLVM ARM Embedded: OK")
        end
        if gcc then
            print("GCC ARM: OK")
        end
        if pyocd then
            print("PyOCD: OK")
        end
    end)

