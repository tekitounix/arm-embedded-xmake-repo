package("umimmio")
    set_homepage("https://github.com/tekitounix/umi")
    set_description("UMI type-safe memory-mapped I/O abstraction library")
    set_license("MIT")

    set_kind("library", {headeronly = true})

    add_versions("dev", "git:../../../../lib/umimmio")

    on_install(function(package)
        os.cp("include", package:installdir())
    end)

    on_test(function(package)
        assert(package:check_cxxsnippets({test = [[
            #include <umimmio/mmio.hh>
            void test() {}
        ]]}, {configs = {languages = "c++23"}}))
    end)
package_end()
