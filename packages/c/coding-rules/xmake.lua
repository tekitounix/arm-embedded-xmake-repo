package("coding-rules")
    set_kind("library")
    set_description("C++ coding style and testing automation for embedded development")

    -- Version management
    add_versions("0.1.0", "dummy")
    add_versions("0.1.1", "dummy")
    add_versions("0.1.2", "dummy")
    add_versions("0.1.3", "dummy")
    add_versions("0.1.4", "dummy")
    add_versions("0.2.0", "dummy")
    add_versions("0.3.0", "dummy")  -- xmake coding command, project-local config support

    on_load(function (package)
        -- Install rule and config files to user's xmake directory during on_load
        import("core.base.global")

        -- Helper function to install rule file
        local function install_rule(src_dir, dest_dir, filename)
            os.mkdir(dest_dir)
            local content = io.readfile(path.join(src_dir, filename))
            if content then
                local dest_file = path.join(dest_dir, filename)
                local need_update = true
                if os.isfile(dest_file) then
                    local dst_content = io.readfile(dest_file)
                    if content == dst_content then
                        need_update = false
                    end
                end
                if need_update then
                    io.writefile(dest_file, content)
                    return true
                end
            end
            return false
        end

        -- Install coding rule (includes xmake coding task)
        local user_rule_dir = path.join(global.directory(), "rules", "coding")
        local user_configs_dir = path.join(user_rule_dir, "configs")
        os.mkdir(user_rule_dir)
        os.mkdir(user_configs_dir)

        -- Copy main rule file
        if install_rule(path.join(os.scriptdir(), "rules", "coding"), user_rule_dir, "xmake.lua") then
            print("=> Coding rule installed to: %s", user_rule_dir)
        end

        -- Copy config templates
        -- These serve as templates for 'xmake coding init' and fallback for coding.style rule
        local config_files = {".clang-format", ".clangd", ".clang-tidy"}
        for _, filename in ipairs(config_files) do
            local content = io.readfile(path.join(os.scriptdir(), "rules", "coding", "configs", filename))
            if content then
                local dest_file = path.join(user_configs_dir, filename)
                local need_update = true
                if os.isfile(dest_file) then
                    local dst_content = io.readfile(dest_file)
                    if content == dst_content then
                        need_update = false
                    end
                end
                if need_update then
                    io.writefile(dest_file, content)
                end
            end
        end

        -- Install testing rule
        local user_testing_dir = path.join(global.directory(), "rules", "testing")
        if install_rule(path.join(os.scriptdir(), "rules", "testing"), user_testing_dir, "xmake.lua") then
            print("=> Testing rule installed to: %s", user_testing_dir)
        end
    end)

    on_install(function (package)
        -- Verify that all required files were installed
        import("core.base.global")

        local rules_to_check = {
            {path.join(global.directory(), "rules", "coding", "xmake.lua"), "Coding rule"},
            {path.join(global.directory(), "rules", "coding", "configs", ".clang-format"), "Clang-format config"},
            {path.join(global.directory(), "rules", "coding", "configs", ".clangd"), "Clangd config"},
            {path.join(global.directory(), "rules", "coding", "configs", ".clang-tidy"), "Clang-tidy config"},
            {path.join(global.directory(), "rules", "testing", "xmake.lua"), "Testing rule"},
        }

        for _, rule in ipairs(rules_to_check) do
            if not os.isfile(rule[1]) then
                raise(rule[2] .. " not installed correctly")
            end
        end

        print("Coding rules package installed successfully")
    end)

    on_test(function (package)
        import("core.base.global")

        local rules_to_check = {
            {path.join(global.directory(), "rules", "coding", "xmake.lua"), "Coding rule"},
            {path.join(global.directory(), "rules", "coding", "configs", ".clang-format"), "Clang-format config"},
            {path.join(global.directory(), "rules", "coding", "configs", ".clangd"), "Clangd config"},
            {path.join(global.directory(), "rules", "coding", "configs", ".clang-tidy"), "Clang-tidy config"},
            {path.join(global.directory(), "rules", "testing", "xmake.lua"), "Testing rule"},
        }

        for _, rule in ipairs(rules_to_check) do
            assert(os.isfile(rule[1]), rule[2] .. " not found")
        end

        print("Coding rules environment: OK")
    end)
