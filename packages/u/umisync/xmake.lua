includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umisync", {"packages", "primitive", "sync"}, {
    description = "UMI lock policy and protected value primitives",
    main_header = "umisync/protected.hh",
    release = {
        repo = "tekitounix/synthernet-xmake-repo",
        artifact = "umi-sync",
        tag_prefix = "umi-sync-v",
        versions = {
            ["0.3.1"] = "0f1e523fb420a5d37635fc5f0b6abbaa437efe06be441f32d549604b02046897",
        },
    },
})
