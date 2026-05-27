includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umi.contract.host_service", {"packages", "contract", "host-service"}, {
    description = "UMI host service transaction contracts",
    main_header = "umifwk/host_service.hh",
    release = {
        repo = "tekitounix/synthernet-xmake-repo",
        artifact = "umi-host-service",
        tag_prefix = "umi-host-service-v",
        versions = {
            ["0.3.1"] = "67a275e5255528f594e1fdc76f56112467612ff140ab6a603787d0b95f4f907d",
        },
    },
    deps = {"umi.contract.surface", "umi.primitive.base_types"},
})
