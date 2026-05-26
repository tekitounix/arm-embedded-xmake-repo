includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umios.runtime", {"packages", "runtime", "os", "runtime"}, {
    deps = {
        "umios.kernel",
        "umi.contract.application",
        "umi.contract.audio",
        "umi.contract.param_state",
        "umi.primitive.base_types",
        "umihal",
        "umidbg",
        "umidi",
        "umiutil",
        "umifwk.ipc",
        "umifwk.router",
        "umifwk.service",
    },
})
