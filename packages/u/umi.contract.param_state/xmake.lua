includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umi.contract.param_state", {"packages", "contract", "param-state"}, {
    deps = {"umi.primitive.base_types", "umi.primitive.time"},
})
