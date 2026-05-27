includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umiutil", {"packages", "primitive", "util"}, {
    description = "UMI utility containers and small support types",
    main_header = "umiutil/result.hh",
    release = {
        repo = "tekitounix/synthernet-xmake-repo",
        artifact = "umi-util",
        tag_prefix = "umi-util-v",
        versions = {
            ["0.3.1"] = "7d18bc3fdcf72232566ef5504b9312fce7b62699019ff59d7d940108cfbc1302",
        },
    },
})
