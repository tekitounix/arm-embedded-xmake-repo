includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umi.contract.control", {"packages", "contract", "control"}, {
    description = "UMI control plane and UI message contracts",
    main_header = "umicore/message.hh",
    release = {
        repo = "tekitounix/synthernet-xmake-repo",
        artifact = "umi-control",
        tag_prefix = "umi-control-v",
        versions = {
            ["0.3.1"] = "a0dbcf8d504aed1a053ff54a8c2ebc8ceb0f8e3db648c7754eb9b7b77c7b6c76",
        },
    },
    deps = {"umi.primitive.base_types", "umi.primitive.time", "umi.contract.module_abi"},
})
