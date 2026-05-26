includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umi.contract.application", {"packages", "contract", "application"}, {
    deps = {"umi.primitive.base_types", "umi.contract.audio", "umi.contract.control", "umi.contract.param_state"},
})
