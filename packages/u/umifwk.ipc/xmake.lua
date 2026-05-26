includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umifwk.ipc", {"packages", "runtime", "framework", "ipc"}, {
    deps = {"umiutil"},
})
