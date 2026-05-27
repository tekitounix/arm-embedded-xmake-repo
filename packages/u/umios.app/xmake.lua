includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umios.app", {"packages", "runtime", "os", "app"}, {
    headeronly = false,
    copy_dirs = {"include", "src"},
    deps = {"umios.runtime", "umiport"},
})
