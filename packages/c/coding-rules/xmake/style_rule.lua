-- Coding style enforcement rule
-- This rule automatically formats and checks code before building

rule("coding.rules")
    
    -- Configure style settings when rule is loaded
    on_config(function (target)
        target:set("coding_style_config", path.join(os.projectdir(), "coding_rules/.clang-format"))
        target:set("coding_style_tidy_config", path.join(os.projectdir(), "coding_rules/.clang-tidy"))
    end)
    
    -- Run style checks on each file before it's compiled
    on_build_file(function (target, sourcefile, opt)
        -- Only process source files, not object files
        if not (sourcefile:endswith(".cc") or sourcefile:endswith(".cpp") or 
                sourcefile:endswith(".c") or sourcefile:endswith(".hh") or 
                sourcefile:endswith(".hpp") or sourcefile:endswith(".h")) then
            return
        end
        
        import("lib.detect.find_program")
        import("core.base.option")
        
        -- Find required tools
        local clang_format = find_program("clang-format")
        local clang_tidy = find_program("clang-tidy")
        
        if not clang_format then
            return
        end
        
        -- Get config paths
        local format_config = target:get("coding_style_config")
        local tidy_config = target:get("coding_style_tidy_config")
        
        -- Only print header once per target
        local header_key = target:name() .. "_style_header"
        if not target:data(header_key) then
            target:data_set(header_key, true)
            print("=== Applying coding style for target: " .. target:name() .. " ===")
        end
        
        -- Step 1: Format the file
        if option.get("verbose") then
            print("  Formatting: %s", sourcefile)
        end
        
        os.execv(clang_format, {
            "-i",
            "--style=file:" .. format_config,
            sourcefile
        }, {try = true})
        
        -- Step 2: Apply naming convention fixes
        if clang_tidy then
            if option.get("verbose") then
                print("  Checking naming: %s", sourcefile)
            end
            
            -- Redirect output to null device (portable)
            local null_device = os.is_host("windows") and "nul" or "/dev/null"
            os.execv(clang_tidy, {
                sourcefile,
                "--config-file=" .. tidy_config,
                "--checks=readability-identifier-naming",
                "--fix",
                "--quiet",
                "--",
                "-x", "c++",
                "-std=c++23",
                "-I" .. path.join(os.projectdir(), "include")
            }, {try = true, stdout = null_device, stderr = null_device})
            
            -- Format again after clang-tidy changes
            os.execv(clang_format, {
                "-i",
                "--style=file:" .. format_config,
                sourcefile
            }, {try = true})
        end
        
        -- Let the default build continue
        return false
    end)
    
    -- Also process header files that might not be in the build list
    before_build(function (target)
        -- Skip if already processed
        if target:data("headers_processed") then
            return
        end
        target:data_set("headers_processed", true)
        
        import("lib.detect.find_program")
        
        local clang_format = find_program("clang-format")
        local clang_tidy = find_program("clang-tidy")
        
        if not clang_format then
            return
        end
        
        -- Get all header files from include directories
        local headerfiles = {}
        for _, dir in ipairs(target:get("includedirs")) do
            local headers = os.files(path.join(dir, "**.hh"))
            for _, h in ipairs(headers) do
                table.insert(headerfiles, h)
            end
            headers = os.files(path.join(dir, "**.h"))
            for _, h in ipairs(headers) do
                table.insert(headerfiles, h)
            end
        end
        
        if #headerfiles > 0 then
            print("Processing %d header files...", #headerfiles)
            local format_config = target:get("coding_style_config")
            local tidy_config = target:get("coding_style_tidy_config")
            
            for _, file in ipairs(headerfiles) do
                -- Step 1: Format with clang-format
                os.execv(clang_format, {
                    "-i",
                    "--style=file:" .. format_config,
                    file
                }, {try = true})
                
                -- Step 2: Apply clang-tidy fixes
                if clang_tidy then
                    -- Redirect output to null device (portable)
                    local null_device = os.is_host("windows") and "nul" or "/dev/null"
                    os.execv(clang_tidy, {
                        file,
                        "--config-file=" .. tidy_config,
                        "--checks=readability-identifier-naming",
                        "--fix",
                        "--quiet",
                        "--",
                        "-x", "c++",
                        "-std=c++23",
                        "-I" .. path.join(os.projectdir(), "include")
                    }, {try = true, stdout = null_device, stderr = null_device})
                    
                    -- Format again after clang-tidy changes
                    os.execv(clang_format, {
                        "-i",
                        "--style=file:" .. format_config,
                        file
                    }, {try = true})
                end
            end
        end
    end)

-- Rule for CI/CD with auto-fix disabled
rule("coding.rules.ci")
    add_deps("coding.rules")
    
    on_config(function (target)
        target:set("coding_style_ci_mode", true)
    end)
    
    before_build(function (target)
        if not target:get("coding_style_ci_mode") then
            return
        end
        
        import("lib.detect.find_program")
        
        local clang_format = find_program("clang-format")
        if not clang_format then
            return
        end
        
        print("=== CI Mode: Checking code style (no auto-fix) ===")
        
        local format_config = path.join(os.projectdir(), "coding_rules/.clang-format")
        local sourcefiles = target:sourcefiles()
        local needs_formatting = false
        
        for _, file in ipairs(sourcefiles) do
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