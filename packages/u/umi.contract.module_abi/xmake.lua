includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umi.contract.module_abi", {"packages", "contract", "module-abi"}, {
    description = "UMI module ABI and substrate binary contracts",
    main_header = "umicore/substrate/abi.hh",
    release = {
        repo = "tekitounix/synthernet-xmake-repo",
        artifact = "umi-module-abi",
        tag_prefix = "umi-module-abi-v",
        versions = {
            ["0.3.1"] = "fdd37469dfafc0f266117ba10aa8d53a9e4c70e70df3b519ada86e468a37b529",
        },
    },
    deps = {"umi.primitive.base_types", "umi.primitive.error"},
})
