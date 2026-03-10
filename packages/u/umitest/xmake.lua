package("umitest")
    set_homepage("https://github.com/tekitounix/umitest")
    set_description("Zero-macro lightweight test framework for C++23")
    set_license("MIT")

    set_kind("library", {headeronly = true})

    add_urls("https://github.com/tekitounix/umitest/releases/download/v$(version)/umitest-$(version).tar.gz")
    add_versions("dev", "git:../../../../lib/umitest")
    add_versions("0.3.0", "4f919fd70aeed2ed7183015af2e98af60f22775dc22d2785b6817818596c58d0")

    on_install(function(package)
        os.cp("include", package:installdir())
    end)

    on_test(function(package)
        assert(package:check_cxxsnippets({test = [[
            #include <umitest/test.hh>
            void test() {
                umi::test::Suite s("pkg_test");
            }
        ]]}, {configs = {languages = "c++23"}}))
    end)
package_end()
