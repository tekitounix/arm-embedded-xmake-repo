package("umibuild")
    set_homepage("https://github.com/tekitounix/umi")
    set_description("UMI build rules, target profiles, MCU database, and operator tooling")
    set_license("MIT")

    set_kind("library")

    add_versions("dev", "dummy")

    on_load(function(package)
        import("core.base.global")

        local rule_names = {
            "umi.target",
            "embedded.compdb",
            "embedded.vscode",
            "coding.style",
            "coding.test",
        }

        local support_dirs = {
            "modules",
            "data",
            "database",
            "profile",
            "templates",
            "sections",
            "scripts",
        }

        local function sync_tree(src_dir, dest_dir)
            if not os.isdir(src_dir) then
                return 0
            end
            if os.isdir(dest_dir) then
                os.rmdir(dest_dir)
            end
            local count = 0
            for _, file in ipairs(os.files(path.join(src_dir, "**"))) do
                local rel = path.relative(file, src_dir)
                io.writefile(path.join(dest_dir, rel), io.readfile(file))
                count = count + 1
            end
            return count
        end

        local function umibuild_source_root()
            local env_root = os.getenv("UMI_SOURCE")
            if env_root and env_root ~= "" then
                local source = path.join(env_root, "build-rules", "umibuild")
                if os.isdir(path.join(source, "rules")) then
                    return source
                end
                raise("UMI_SOURCE does not contain build-rules/umibuild: %s", env_root)
            end

            local install_root = package:installdir()
            if install_root and os.isdir(path.join(install_root, "rules")) then
                return install_root
            end

            raise("umibuild source root not found; set UMI_SOURCE or install a released umibuild archive")
        end

        local function install_rules(source, dest_root)
            for _, rule_name in ipairs(rule_names) do
                sync_tree(path.join(source, "rules", rule_name), path.join(dest_root, "rules", rule_name))
            end

            local umi_target_root = path.join(dest_root, "rules", "umi.target")
            for _, dir_name in ipairs(support_dirs) do
                sync_tree(path.join(source, dir_name), path.join(umi_target_root, dir_name))
            end

            local plugins_root = path.join(source, "plugins")
            if os.isdir(plugins_root) then
                for _, plugin_dir in ipairs(os.dirs(path.join(plugins_root, "*"))) do
                    local plugin_name = path.filename(plugin_dir)
                    sync_tree(plugin_dir, path.join(dest_root, "plugins", plugin_name))
                end
            end
        end

        install_rules(umibuild_source_root(), global.directory())
    end)

    on_install(function(package)
        local support_dirs = {
            "modules",
            "data",
            "database",
            "profile",
            "templates",
            "sections",
            "scripts",
        }

        local function sync_tree(src_dir, dest_dir)
            if not os.isdir(src_dir) then
                return 0
            end
            if os.isdir(dest_dir) then
                os.rmdir(dest_dir)
            end
            local count = 0
            for _, file in ipairs(os.files(path.join(src_dir, "**"))) do
                local rel = path.relative(file, src_dir)
                io.writefile(path.join(dest_dir, rel), io.readfile(file))
                count = count + 1
            end
            return count
        end

        local function umibuild_source_root()
            local env_root = os.getenv("UMI_SOURCE")
            if env_root and env_root ~= "" then
                local source = path.join(env_root, "build-rules", "umibuild")
                if os.isdir(path.join(source, "rules")) then
                    return source
                end
                raise("UMI_SOURCE does not contain build-rules/umibuild: %s", env_root)
            end

            if os.isdir("rules") then
                return os.curdir()
            end
            local subdirs = os.dirs("umibuild-*")
            if subdirs and #subdirs > 0 and os.isdir(path.join(subdirs[1], "rules")) then
                return subdirs[1]
            end

            raise("umibuild source root not found; set UMI_SOURCE or install a released umibuild archive")
        end

        local source = umibuild_source_root()
        for _, dir_name in ipairs(table.join({"rules", "plugins"}, support_dirs)) do
            sync_tree(path.join(source, dir_name), path.join(package:installdir(), dir_name))
        end
    end)

    on_test(function(package)
        import("core.base.global")
        assert(os.isfile(path.join(global.directory(), "rules", "umi.target", "xmake.lua")))
        assert(os.isfile(path.join(global.directory(), "rules", "umi.target", "modules", "context.lua")))
        assert(os.isfile(path.join(global.directory(), "plugins", "umi", "xmake.lua")))
    end)
package_end()
