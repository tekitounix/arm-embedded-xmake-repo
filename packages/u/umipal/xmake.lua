package("umipal")
    set_homepage("https://github.com/tekitounix/umipal")
    set_description("Type-safe header-only C++23 Peripheral Access Layer (PAL) generator for ARM Cortex-M MCUs")
    set_license("MIT")

    set_kind("library", {headeronly = true})

    add_urls("https://github.com/tekitounix/umipal/releases/download/v$(version)/umipal-$(version).tar.gz")
    -- dev: umi リポ内 submodule (external/umipal) を参照。
    -- xmake-repo/synthernet/packages/u/umipal/ から見た相対 path:
    --   ../../../../umipal    → packages/u/
    --   ../../../umipal       → packages/
    --   ../../umipal          → synthernet/
    --   ../umipal             → xmake-repo/
    --   umipal                → umi root
    --   external/umipal       → submodule
    add_versions("dev", "git:../../../../../external/umipal")
    add_versions("1.0.0", "e4e12ee2ed470b3bce6581f51e2156eeca3277d3183655166964d15bf568c39e")
    add_versions("1.1.0", "346f41ff20cd38ecdede64428cbed48c8223e88806d0d395737b6e7715717a25")
    add_versions("2.3.0", "65fea26219e62e483277cce3bd64ab26456cd272970b4de23173529b7ced0b63")

    add_deps("umimmio")

    on_install(function(package)
        -- xmake の autostrip が tarball root を剥がさない場合 (CI の fresh
        -- install 等) に備え、tarball root subdirectory を fallback で cd。
        if not os.isdir("include") then
            local subdirs = os.dirs("umipal-*")
            if subdirs and #subdirs > 0 then
                os.cd(subdirs[1])
            end
        end
        os.cp("include", package:installdir())
        if os.isdir("share") then
            os.cp("share", package:installdir())
        end
    end)

    -- on_test omitted: umipal headers require C++23 deducing-this (umimmio
    -- dependency) and ARM cross-toolchain, so host-side test gives no signal.
    -- Coverage lives upstream in tekitounix/umipal CI (cargo / xmake / Renode
    -- / hardware gates) and downstream in firmware projects that consume
    -- this package via embedded toolchains.
package_end()
