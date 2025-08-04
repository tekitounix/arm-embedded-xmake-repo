--!ARM Embedded Project Plugin
--
-- Registers custom project tasks for embedded development
--

-- register vscode_settings task
task("project")
    set_menu {
        usage = "xmake project -k vscode_settings [options]"
    ,   description = "Generate project files."
    ,   options = {
            {'k', "kind",       "kv", nil,          "Set the project kind."
                                                 ,   "    - vscode_settings"   }
        ,   {nil, "outputdir",  "kv", nil,          "Set the output directory." }
        }
    }

    on_run(function()
        import("core.base.option")
        local kind = option.get("kind")
        
        if kind == "vscode_settings" then
            import("vscode.settings", {rootdir = os.scriptdir()})
            settings.make(option.get("outputdir"))
        else
            -- fall back to default project task
            import("project", {rootdir = os.programdir()})
        end
    end)