-- Coding style enforcement rule
-- This rule automatically formats and checks code before building

rule("coding.style")
    
    -- Configure style settings when rule is loaded
    on_config(function (target)
        import("core.base.global")
        
        -- Use config files from the rule's install directory
        local rule_dir = path.join(global.directory(), "rules", "coding")
        local config_dir = path.join(rule_dir, "configs")
        
        target:set("coding_style_config", path.join(config_dir, ".clang-format"))
        target:set("coding_style_tidy_config", path.join(config_dir, ".clang-tidy"))
    end)
    
    -- Process all source files before build
    before_build(function (target)
        import("lib.detect.find_program")
        import("core.base.option")
        
        -- Get feature flags (default: all enabled)
        local enable_format = target:get("coding.style.format") ~= false
        local enable_check = target:get("coding.style.check") ~= false
        local enable_fix = target:get("coding.style.fix") ~= false
        
        -- Skip if all features are disabled
        if not enable_format and not enable_check and not enable_fix then
            return
        end
        
        -- Find required tools
        local clang_format = find_program("clang-format")
        local clang_tidy = find_program("clang-tidy")
        
        if not clang_format and enable_format then
            return
        end
        
        -- Get config paths
        local format_config = target:get("coding_style_config")
        local tidy_config = target:get("coding_style_tidy_config")
        
        -- Buffer all output for atomic display (prevents parallel build interleaving)
        local output_buffer = {}
        local function add_output(msg)
            table.insert(output_buffer, msg)
        end
        
        -- Track issues across all files
        local has_issues = false
        local processed_files = 0
        
        -- Process all source files
        for _, sourcefile in ipairs(target:sourcefiles()) do
            -- Only process source files, not object files
            if not (sourcefile:endswith(".cc") or sourcefile:endswith(".cpp") or 
                    sourcefile:endswith(".c") or sourcefile:endswith(".hh") or 
                    sourcefile:endswith(".hpp") or sourcefile:endswith(".h")) then
                goto continue
            end
            
            processed_files = processed_files + 1
            
            -- Step 1: Format the file
            if enable_format and clang_format then
                local before_hash = os.iorunv("shasum", {"-a", "256", sourcefile})
                
                os.execv(clang_format, {
                    "-i",
                    "--style=file:" .. format_config,
                    sourcefile
                }, {try = true})
                
                local after_hash = os.iorunv("shasum", {"-a", "256", sourcefile})
                if before_hash ~= after_hash then
                    has_issues = true
                    add_output("  🎨 Formatted: " .. path.filename(sourcefile))
                end
            end
            
            -- Step 2: Check and optionally fix naming conventions
            if (enable_check or enable_fix) and clang_tidy then
                -- Get include directories from target
                local includes = {}
                for _, dir in ipairs(target:get("includedirs")) do
                    table.insert(includes, "-I" .. dir)
                end
                
                -- Get compile definitions  
                local defines = {}
                for _, def in ipairs(target:get("defines")) do
                    table.insert(defines, "-D" .. def)
                end
            
                -- Build clang-tidy arguments
                local args = {
                    sourcefile,
                    "--config-file=" .. tidy_config,
                    "--checks=readability-identifier-naming",
                    "--quiet",
                    "--"
                }

                -- Add --fix flag only if auto-fix is enabled
                if enable_fix then
                    table.insert(args, 4, "--fix")
                end

                -- Determine language based on file extension
                local is_c_file = sourcefile:endswith(".c") or sourcefile:endswith(".h")
                local language = is_c_file and "c" or "c++"
                local std_flag = is_c_file and "-std=c23" or "-std=c++23"

                -- Add compilation flags
                table.insert(args, "-x")
                table.insert(args, language)
                table.insert(args, std_flag)
            
                -- Add includes and defines
                for _, inc in ipairs(includes) do
                    table.insert(args, inc)
                end
                for _, def in ipairs(defines) do
                    table.insert(args, def)
                end
            
                if enable_check and not enable_fix then
                    -- Check-only mode: capture output to show warnings
                    local outdata, errdata = os.iorunv(clang_tidy, args)
                    if errdata and #errdata > 0 then
                        has_issues = true
                        add_output("  ⚠ Issues in: " .. path.filename(sourcefile))
                        -- Show key issues only
                        local lines = errdata:split('\n')
                        local issue_count = 0
                        for _, line in ipairs(lines) do
                            if line:find("warning:") and issue_count < 2 then
                                local clean_line = line:gsub("^.*warning: ", ""):gsub(" %[.*%]$", "")
                                add_output("      • " .. clean_line)
                                issue_count = issue_count + 1
                            end
                        end
                        if issue_count == 2 then
                            add_output("      • ...")
                        end
                    end
                else
                    -- Fix mode: check if changes were made
                    local before_hash = os.iorunv("shasum", {"-a", "256", sourcefile})
                    
                    local null_device = os.is_host("windows") and "nul" or "/dev/null"
                    os.execv(clang_tidy, args, {try = true, stdout = null_device, stderr = null_device})
                    
                    local after_hash = os.iorunv("shasum", {"-a", "256", sourcefile})
                    if before_hash ~= after_hash then
                        has_issues = true
                        add_output("  🔧 Fixed issues in: " .. path.filename(sourcefile))
                        
                        -- Format again after clang-tidy changes
                        if enable_format and clang_format then
                            os.execv(clang_format, {
                                "-i",
                                "--style=file:" .. format_config,
                                sourcefile
                            }, {try = true})
                        end
                    end
                end
            end
            
            ::continue::
        end
        
        -- Only display output if there were issues or in verbose mode
        if has_issues or processed_files > 0 then
            local separator = string.rep("=", 80)
            print(separator)
            print("Coding Style Configuration")
            print(separator)
            print("Target:         " .. target:name())
            local status_format = enable_format and "enabled" or "disabled"
            local status_check = enable_check and "enabled" or "disabled"  
            local status_fix = enable_fix and "enabled" or "disabled"
            print("Auto-format:    " .. status_format)
            print("Auto-check:     " .. status_check)
            print("Auto-fix:       " .. status_fix)
            print(separator)
            
            if has_issues then
                -- Show buffered output atomically
                for _, msg in ipairs(output_buffer) do
                    print(msg)
                end
            else
                print("  ✓ All " .. processed_files .. " files are compliant")
            end
            print(separator)
        end
    end)

-- Rule for CI/CD with auto-fix disabled
rule("coding.style.ci")
    
    on_config(function (target)
        import("core.base.global")
        
        -- Use config files from the rule's install directory
        local rule_dir = path.join(global.directory(), "rules", "coding")
        local config_dir = path.join(rule_dir, "configs")
        
        target:set("coding_style_config", path.join(config_dir, ".clang-format"))
        target:set("coding_style_ci_mode", true)
    end)
    
    before_build(function (target)
        if not target:get("coding_style_ci_mode") then
            return
        end
        
        import("lib.detect.find_program")
        
        local clang_format = find_program("clang-format")
        if not clang_format then
            raise("clang-format not found. Please install it to use coding.style.ci rule.")
        end
        
        print("=== CI Mode: Checking code style (no auto-fix) ===")
        
        local format_config = target:get("coding_style_config")
        local needs_formatting = false
        local files_to_check = {}
        
        -- Collect all source files
        for _, file in ipairs(target:sourcefiles()) do
            if file:endswith(".cc") or file:endswith(".cpp") or 
               file:endswith(".c") or file:endswith(".hh") or 
               file:endswith(".hpp") or file:endswith(".h") then
                table.insert(files_to_check, file)
            end
        end
        
        -- Check all header files
        for _, dir in ipairs(target:get("includedirs")) do
            for _, pattern in ipairs({"**.hh", "**.hpp", "**.h"}) do
                local headers = os.files(path.join(dir, pattern))
                for _, h in ipairs(headers) do
                    table.insert(files_to_check, h)
                end
            end
        end
        
        -- Check each file
        for _, file in ipairs(files_to_check) do
            -- Check if file needs formatting (dry-run)
            local _, errdata = os.iorunv(clang_format, {
                "--dry-run",
                "--Werror",
                "--style=file:" .. format_config,
                file
            })
            
            if errdata and #errdata > 0 then
                needs_formatting = true
                print("  ✗ File needs formatting: %s", file)
            end
        end
        
        if needs_formatting then
            raise("Code formatting check failed. Please run 'xmake format' locally before committing.")
        end
        
        print("✓ All files are properly formatted")
    end)