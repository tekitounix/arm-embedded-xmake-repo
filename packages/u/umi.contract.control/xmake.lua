includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umi.contract.control", {"packages", "contract", "control"}, {
    deps = {"umi.primitive.base_types", "umi.primitive.time", "umi.contract.module_abi"},
})
