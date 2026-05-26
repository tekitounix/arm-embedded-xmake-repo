includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umi.contract.module_abi", {"packages", "contract", "module-abi"}, {
    deps = {"umi.primitive.base_types", "umi.primitive.error"},
})
