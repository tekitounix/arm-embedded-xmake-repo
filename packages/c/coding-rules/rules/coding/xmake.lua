-- Coding style management
-- Provides coding.style rule for build-time formatting/linting
--
-- Note: The 'xmake coding' task must be defined in a project's xmake.lua
-- For the task, include coding_task.lua from this directory.

-- ============================================================================
-- coding.style rule
-- ============================================================================

rule("coding.style")

    on_config(function (target)
        import("core.base.global")

        local format_config = nil
        local tidy_config = nil

        local project_format = path.join(os.projectdir(), ".clang-format")
        local project_tidy = path.join(os.projectdir(), ".clang-tidy")

        if os.isfile(project_format) then
            format_config = project_format
        end
        if os.isfile(project_tidy) then
            tidy_config = project_tidy
        end

        if not format_config then
            local global_format = path.join(global.directory(), "rules", "coding", "configs", ".clang-format")
            if os.isfile(global_format) then
                format_config = global_format
            end
        end
        if not tidy_config then
            local global_tidy = path.join(global.directory(), "rules", "coding", "configs", ".clang-tidy")
            if os.isfile(global_tidy) then
                tidy_config = global_tidy
            end
        end

        target:set("coding_style_config", format_config)
        target:set("coding_style_tidy_config", tidy_config)
    end)

    before_build(function (target)
        import("lib.detect.find_program")

        local enable_format = target:get("coding.style.format") == true
        local enable_check = target:get("coding.style.check") == true
        local enable_fix = target:get("coding.style.fix") == true

        if not enable_format and not enable_check and not enable_fix then
            return
        end

        local clang_format = find_program("clang-format")
        local clang_tidy = find_program("clang-tidy")

        local format_config = target:get("coding_style_config")
        local tidy_config = target:get("coding_style_tidy_config")

        if not format_config and enable_format then
            print("warning: .clang-format not found, skipping format")
            return
        end

        for _, sourcefile in ipairs(target:sourcefiles()) do
            if not (sourcefile:endswith(".cc") or sourcefile:endswith(".cpp") or
                    sourcefile:endswith(".c") or sourcefile:endswith(".hh") or
                    sourcefile:endswith(".hpp") or sourcefile:endswith(".h")) then
                goto continue
            end

            if enable_format and clang_format and format_config then
                local before = io.readfile(sourcefile)
                os.execv(clang_format, {"-i", "--style=file:" .. format_config, sourcefile}, {try = true})
                local after = io.readfile(sourcefile)
                if before ~= after then
                    print("  Formatted: %s", path.filename(sourcefile))
                end
            end

            if (enable_check or enable_fix) and clang_tidy and tidy_config then
                local includes = {}
                for _, dir in ipairs(target:get("includedirs") or {}) do
                    table.insert(includes, "-I" .. dir)
                end

                local defines = {}
                for _, def in ipairs(target:get("defines") or {}) do
                    table.insert(defines, "-D" .. def)
                end

                local args = {sourcefile, "--config-file=" .. tidy_config, "--quiet", "--"}
                if enable_fix then
                    table.insert(args, 3, "--fix")
                end

                local is_c = sourcefile:endswith(".c") or sourcefile:endswith(".h")
                table.insert(args, "-x")
                table.insert(args, is_c and "c" or "c++")
                table.insert(args, is_c and "-std=c23" or "-std=c++23")

                for _, inc in ipairs(includes) do table.insert(args, inc) end
                for _, def in ipairs(defines) do table.insert(args, def) end

                os.execv(clang_tidy, args, {try = true, stdout = "/dev/null", stderr = "/dev/null"})
            end

            ::continue::
        end
    end)
rule_end()

-- ============================================================================
-- coding.style.ci rule (for CI/CD)
-- ============================================================================

rule("coding.style.ci")

    on_config(function (target)
        import("core.base.global")

        local format_config = path.join(os.projectdir(), ".clang-format")
        if not os.isfile(format_config) then
            format_config = path.join(global.directory(), "rules", "coding", "configs", ".clang-format")
        end

        target:set("coding_style_config", format_config)
        target:set("coding_style_ci_mode", true)
    end)

    before_build(function (target)
        if not target:get("coding_style_ci_mode") then
            return
        end

        import("lib.detect.find_program")

        local clang_format = find_program("clang-format")
        if not clang_format then
            raise("clang-format not found")
        end

        local format_config = target:get("coding_style_config")
        if not format_config or not os.isfile(format_config) then
            raise(".clang-format not found. Run 'xmake coding init' first.")
        end

        local needs_formatting = false

        for _, file in ipairs(target:sourcefiles()) do
            if file:endswith(".cc") or file:endswith(".cpp") or
               file:endswith(".c") or file:endswith(".hh") or
               file:endswith(".hpp") or file:endswith(".h") then
                local _, errdata = os.iorunv(clang_format, {
                    "--dry-run", "--Werror",
                    "--style=file:" .. format_config,
                    file
                })
                if errdata and #errdata > 0 then
                    needs_formatting = true
                    print("  Needs formatting: %s", file)
                end
            end
        end

        if needs_formatting then
            raise("Code style check failed. Run 'xmake coding format' locally.")
        end
    end)
rule_end()
