-- xmake lint plugin
-- Runs clang-tidy checks on source files

task("lint")
    set_category("plugin")
    set_description("Run static analysis and style checks using clang-tidy")
    
    on_run(function ()
        import("core.base.option")
        import("core.project.project")
        import("lib.detect.find_program")
        import("core.base.global")
        
        -- Find tools
        local clang_tidy = find_program("clang-tidy")
        if not clang_tidy then
            raise("clang-tidy not found. Please install clang-tidy to use this command.")
        end
        
        -- Get config file path
        local rule_dir = path.join(global.directory(), "rules", "coding")
        local config_dir = path.join(rule_dir, "configs")
        local tidy_config = path.join(config_dir, ".clang-tidy")
        
        -- Check if config exists
        if not os.isfile(tidy_config) then
            raise("coding-rules package not properly installed. Config file not found: " .. tidy_config)
        end
        
        -- Get options
        local target_name = option.get("target")
        local fix_mode = option.get("fix")
        local checks = option.get("checks") or "readability-identifier-naming"
        
        -- Collect all files to check
        local files_to_check = {}
        local seen_files = {}
        
        -- Process each target
        for _, target in pairs(project.targets()) do
            if target_name and target:name() ~= target_name then
                goto continue
            end
            
            -- Get target compilation info
            local target_info = {
                includes = {},
                defines = {},
                cxxflags = {}
            }
            
            -- Collect include directories
            for _, dir in ipairs(target:get("includedirs")) do
                table.insert(target_info.includes, "-I" .. dir)
            end
            
            -- Collect defines
            for _, def in ipairs(target:get("defines")) do
                table.insert(target_info.defines, "-D" .. def)
            end
            
            -- Add source files with their compilation info
            for _, file in ipairs(target:sourcefiles()) do
                if file:endswith(".cc") or file:endswith(".cpp") or file:endswith(".c") then
                    if not seen_files[file] then
                        table.insert(files_to_check, {
                            file = file,
                            info = target_info
                        })
                        seen_files[file] = true
                    end
                end
            end
            
            -- Add header files
            for _, file in ipairs(target:headerfiles()) do
                if not seen_files[file] then
                    table.insert(files_to_check, {
                        file = file,
                        info = target_info
                    })
                    seen_files[file] = true
                end
            end
            
            -- Add headers from include directories
            for _, dir in ipairs(target:get("includedirs")) do
                if os.isdir(dir) then
                    for _, pattern in ipairs({"**.hh", "**.hpp", "**.h"}) do
                        local headers = os.files(path.join(dir, pattern))
                        for _, h in ipairs(headers) do
                            if not seen_files[h] then
                                table.insert(files_to_check, {
                                    file = h,
                                    info = target_info
                                })
                                seen_files[h] = true
                            end
                        end
                    end
                end
            end
            
            ::continue::
        end
        
        if #files_to_check == 0 then
            print("No files to check.")
            return
        end
        
        print("Checking %d files with clang-tidy...", #files_to_check)
        if fix_mode then
            print("Fix mode enabled - will attempt to fix issues automatically")
        end
        
        -- Check each file
        local issues_found = 0
        local files_with_issues = 0
        
        for _, item in ipairs(files_to_check) do
            local file = item.file
            local info = item.info
            
            if option.get("verbose") then
                print("  Checking: %s", file)
            end
            
            -- Build clang-tidy arguments
            local args = {
                file,
                "--config-file=" .. tidy_config,
                "--checks=" .. checks
            }
            
            if fix_mode then
                table.insert(args, "--fix")
            end
            
            if not option.get("verbose") then
                table.insert(args, "--quiet")
            end
            
            -- Add compilation database separator
            table.insert(args, "--")
            
            -- Add compilation flags
            table.insert(args, "-x")
            table.insert(args, file:endswith(".c") and "c" or "c++")
            table.insert(args, "-std=" .. (file:endswith(".c") and "c23" or "c++23"))
            
            -- Add includes and defines
            for _, inc in ipairs(info.includes) do
                table.insert(args, inc)
            end
            for _, def in ipairs(info.defines) do
                table.insert(args, def)
            end
            
            -- Run clang-tidy
            local outdata, errdata = os.iorunv(clang_tidy, args)
            
            -- Parse output for issues
            if outdata and #outdata > 0 then
                local has_issues = false
                for line in outdata:gmatch("[^\r\n]+") do
                    if line:find("warning:") or line:find("error:") then
                        has_issues = true
                        issues_found = issues_found + 1
                        if not option.get("verbose") then
                            print("  %s", line)
                        end
                    elseif option.get("verbose") then
                        print("  %s", line)
                    end
                end
                
                if has_issues then
                    files_with_issues = files_with_issues + 1
                    print("  ✗ Issues found in: %s", path.relative(file, os.projectdir()))
                elseif option.get("verbose") then
                    print("  ✓ No issues in: %s", path.relative(file, os.projectdir()))
                end
            end
        end
        
        -- Summary
        print("")
        if issues_found > 0 then
            print("Found %d issues in %d files.", issues_found, files_with_issues)
            if not fix_mode then
                print("Run 'xmake lint --fix' to automatically fix some issues.")
            else
                print("Some issues were automatically fixed. Please review the changes.")
            end
        else
            print("✓ No issues found. Code passes all lint checks.")
        end
    end)
    
    set_menu {
        usage = "xmake lint [options]",
        description = "Run static analysis and style checks using clang-tidy",
        options = {
            {'t', "target", "kv", nil, "Check only the specified target"},
            {'f', "fix", "k", nil, "Automatically fix issues where possible"},
            {'c', "checks", "kv", nil, "Specify checks to run (default: readability-identifier-naming)"},
            {'v', "verbose", "k", nil, "Show verbose output"}
        }
    }