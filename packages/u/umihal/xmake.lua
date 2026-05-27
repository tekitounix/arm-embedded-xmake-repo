includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umihal", {"packages", "platform", "hal"}, {
    description = "UMI portable hardware abstraction contracts",
    main_header = "umihal/hal.hh",
    release = {
        repo = "tekitounix/synthernet-xmake-repo",
        artifact = "umi-hal",
        tag_prefix = "umi-hal-v",
        versions = {
            ["0.3.1"] = "58d23f45a40b3deef115def96360e55dee1782d68e8dd9057e9f4384d5afd37d",
        },
    },
})
