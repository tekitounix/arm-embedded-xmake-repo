package("umimmio")
    set_homepage("https://github.com/tekitounix/umimmio")
    set_description("Type-safe memory-mapped I/O abstraction library")
    set_license("MIT")

    set_kind("library", {headeronly = true})

    add_urls("https://github.com/tekitounix/umimmio/releases/download/v$(version)/umimmio-$(version).tar.gz")
    add_versions("dev", "git:../../../../lib/umimmio")
    add_versions("0.2.0", "f7611c0d25cd45470dcb55a8e5ccd05997487e7b809077e4a1f82ab09d5e9405")

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
