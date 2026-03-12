package("umimmio")
    set_homepage("https://github.com/tekitounix/umimmio")
    set_description("Type-safe memory-mapped I/O abstraction library")
    set_license("MIT")

    set_kind("library", {headeronly = true})

    add_urls("https://github.com/tekitounix/umimmio/releases/download/v$(version)/umimmio-$(version).tar.gz")
    add_versions("dev", "git:../../../../lib/umimmio")
    add_versions("0.1.0", "2a077c0e7f31f712451e367040cb273abc99a76968e4b87780ff292202a88295")

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
