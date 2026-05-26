includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umi.base", {"packages", "preset", "base"}, {
    copy_dirs = {"src"},
    deps = {
        "umi.primitive.base_types",
        "umi.primitive.error",
        "umi.primitive.time",
        "umi.primitive.crc",
        "umi.contract.module_abi",
        "umi.contract.param_state",
        "umi.contract.control",
        "umi.contract.audio",
        "umi.contract.application",
        "umicoro",
        "umidsp",
        "umidi",
    },
})
