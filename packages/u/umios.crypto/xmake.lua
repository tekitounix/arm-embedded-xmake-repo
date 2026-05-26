includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umios.crypto", {"packages", "runtime", "os", "crypto"}, {
    headeronly = false,
    copy_dirs = {"include", "src"},
})
