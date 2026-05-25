package("umiport")
    set_homepage("https://github.com/tekitounix/umi")
    set_description("UMI shared platform infrastructure (STM32F4 startup, linker, UART)")
    set_license("MIT")

    set_kind("library", {headeronly = false})

    if os.getenv("UMI_SOURCE") then
        add_versions("dev", "dummy")
    end

    add_deps("umimmio")

    on_install(function(package)
        local env_root = os.getenv("UMI_SOURCE")
        if env_root and env_root ~= "" then
            local source = path.join(env_root, "packages", "platform", "port")
            if os.isdir(path.join(source, "include")) then
                os.cp(path.join(source, "include"), package:installdir())
                if os.isdir(path.join(source, "src")) then
                    os.cp(path.join(source, "src"), package:installdir())
                end
                if os.isdir(path.join(source, "tests", "renode")) then
                    os.cp(path.join(source, "tests", "renode"), path.join(package:installdir(), "renode"))
                end
                return
            end
            raise("UMI_SOURCE does not contain packages/platform/port: %s", env_root)
        end

        if os.isdir("include") then
            os.cp("include", package:installdir())
            if os.isdir("src") then
                os.cp("src", package:installdir())
            end
            if os.isdir("renode") then
                os.cp("renode", package:installdir())
            end
            return
        end
        local subdirs = os.dirs("umiport-*")
        if subdirs and #subdirs > 0 and os.isdir(path.join(subdirs[1], "include")) then
            os.cp(path.join(subdirs[1], "include"), package:installdir())
            if os.isdir(path.join(subdirs[1], "src")) then
                os.cp(path.join(subdirs[1], "src"), package:installdir())
            end
            if os.isdir(path.join(subdirs[1], "renode")) then
                os.cp(path.join(subdirs[1], "renode"), package:installdir())
            end
            return
        end
        raise("umiport source root not found")
    end)

    on_test(function(package)
        assert(os.isfile(path.join(package:installdir(), "src", "stm32f4", "startup.cc")))
        assert(os.isfile(path.join(package:installdir(), "renode", "stm32f4_test.repl")))
    end)
package_end()
