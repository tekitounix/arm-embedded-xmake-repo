includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umifwk.loader", {"packages", "runtime", "framework", "loader"}, {
    headeronly = false,
    copy_dirs = {"include", "src"},
    deps = {"umifwk.service", "umios.crypto"},
})
