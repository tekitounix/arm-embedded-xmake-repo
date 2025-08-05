package("coding-rules")
    set_kind("library")
    set_description("C++ coding style and testing automation for embedded development")
    
    -- Version management
    add_versions("0.1.0", "dummy")
    add_versions("0.1.1", "dummy")
    
    on_load(function (package)
        -- Install rule and config files to user's xmake directory during on_load
        import("core.base.global")
        
        -- Install coding rule
        local user_rule_dir = path.join(global.directory(), "rules", "coding")
        local user_configs_dir = path.join(user_rule_dir, "configs")
        os.mkdir(user_rule_dir)
        os.mkdir(user_configs_dir)
        
        -- Copy main rule file
        local rule_content = io.readfile(path.join(os.scriptdir(), "rules", "coding", "xmake.lua"))
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
                print("=> Coding rule installed to: %s", user_rule_dir)
            end
        end
        
        -- Copy config files
        local config_files = {".clang-format", ".clang-tidy", ".clangd"}
        for _, filename in ipairs(config_files) do
            local content = io.readfile(path.join(os.scriptdir(), "rules", "coding", "configs", filename))
            if content then
                io.writefile(path.join(user_configs_dir, filename), content)
            end
        end
        
        -- Install testing rule
        local user_testing_dir = path.join(global.directory(), "rules", "testing")
        os.mkdir(user_testing_dir)
        
        local testing_content = io.readfile(path.join(os.scriptdir(), "rules", "testing", "xmake.lua"))
        if testing_content then
            local dest_file = path.join(user_testing_dir, "xmake.lua")
            
            local need_update = true
            if os.isfile(dest_file) then
                local dst_content = io.readfile(dest_file)
                if testing_content == dst_content then
                    need_update = false
                end
            end
            
            if need_update then
                io.writefile(dest_file, testing_content)
                print("=> Testing rule installed to: %s", user_testing_dir)
            end
        end
    end)
    
    on_install(function (package)
        -- The actual installation happens in on_load to ensure rules are available early
        -- Verify that all required files were installed
        import("core.base.global")
        
        -- Check coding rule
        local coding_rule = path.join(global.directory(), "rules", "coding", "xmake.lua")
        if not os.isfile(coding_rule) then
            raise("Coding rule not installed correctly")
        end
        
        -- Check config files
        local clang_format = path.join(global.directory(), "rules", "coding", "configs", ".clang-format")
        if not os.isfile(clang_format) then
            raise("Clang-format config not installed correctly")
        end
        
        -- Check testing rule
        local testing_rule = path.join(global.directory(), "rules", "testing", "xmake.lua")
        if not os.isfile(testing_rule) then
            raise("Testing rule not installed correctly")
        end
        
        print("Coding rules package installed successfully")
    end)
    
    on_test(function (package)
        import("core.base.global")
        -- Test if rules were properly installed
        local coding_rule = path.join(global.directory(), "rules", "coding", "xmake.lua")
        assert(os.isfile(coding_rule), "Coding rule not found")
        
        -- Test if config files were properly installed
        local clang_format = path.join(global.directory(), "rules", "coding", "configs", ".clang-format")
        assert(os.isfile(clang_format), "Clang-format config not found")
        
        local clang_tidy = path.join(global.directory(), "rules", "coding", "configs", ".clang-tidy")
        assert(os.isfile(clang_tidy), "Clang-tidy config not found")
        
        local clangd = path.join(global.directory(), "rules", "coding", "configs", ".clangd")
        assert(os.isfile(clangd), "Clangd config not found")
        
        -- Test if testing rule was properly installed
        local testing_rule = path.join(global.directory(), "rules", "testing", "xmake.lua")
        assert(os.isfile(testing_rule), "Testing rule not found")
        
        print("Coding rules environment: OK")
    end)