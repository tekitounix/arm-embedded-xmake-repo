includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umifwk.router", {"packages", "runtime", "framework", "router"}, {
    deps = {"umifwk.ipc", "umi.contract.control", "umi.contract.param_state", "umi.primitive.base_types", "umidi"},
})
