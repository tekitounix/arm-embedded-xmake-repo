includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umifwk.service", {"packages", "runtime", "framework", "service"}, {
    deps = {"umifwk.router", "umi.contract.audio", "umi.contract.param_state", "umi.primitive.crc", "umidi", "umios.kernel", "umihal"},
})
