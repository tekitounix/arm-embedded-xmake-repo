-- Debug build task for ARM embedded development

task("debug")
    set_category("build")
    on_run(function ()
        -- Set build configuration
        print("Building with debug configuration...")
        
        -- Clean and build in debug mode
        os.exec("xmake clean -a")
        os.exec("xmake config --mode=debug")
        os.exec("xmake")
    end)
    set_menu {
        usage = "xmake debug",
        description = "Build with debug configuration (no optimization, maximum debug info)"
    }