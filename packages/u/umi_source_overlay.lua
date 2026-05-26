local function joined(root, segments)
    local result = root
    for _, segment in ipairs(segments) do
        result = path.join(result, segment)
    end
    return result
end

function umi_source_overlay_package(name, segments, opts)
    opts = opts or {}

    package(name)
        set_homepage("https://github.com/tekitounix/umi")
        set_description(opts.description or ("UMI source-overlay package: " .. name))
        set_license("MIT")

        if opts.headeronly == false then
            set_kind("library")
        else
            set_kind("library", {headeronly = true})
        end

        if os.getenv("UMI_SOURCE") then
            add_versions("dev", "dummy")
        end

        for _, dep in ipairs(opts.deps or {}) do
            add_deps(dep)
        end

        on_install(function(package)
            local env_root = os.getenv("UMI_SOURCE")
            if not env_root or env_root == "" then
                raise("%s has no released archive yet; set UMI_SOURCE for source overlay", name)
            end

            local source = joined(env_root, segments)
            local copied = false
            for _, dir_name in ipairs(opts.copy_dirs or {"include"}) do
                local dir = path.join(source, dir_name)
                if os.isdir(dir) then
                    os.cp(dir, package:installdir())
                    copied = true
                end
            end
            for _, file_name in ipairs(opts.copy_files or {}) do
                local file = path.join(source, file_name)
                if os.isfile(file) then
                    os.cp(file, path.join(package:installdir(), file_name))
                    copied = true
                end
            end
            if copied then
                return
            end
            raise("UMI_SOURCE does not contain %s: %s", table.concat(segments, "/"), env_root)
        end)
    package_end()
end
