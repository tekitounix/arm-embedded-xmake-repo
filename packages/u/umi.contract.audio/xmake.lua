includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umi.contract.audio", {"packages", "contract", "audio"}, {
    deps = {"umi.primitive.base_types", "umi.primitive.error", "umi.contract.param_state", "umiutil"},
})
