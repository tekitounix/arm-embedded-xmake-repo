includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umimath", {"packages", "primitive", "math"}, {
    description = "UMI constexpr math primitives",
    main_header = "umimath/math.hh",
    release = {
        repo = "tekitounix/synthernet-xmake-repo",
        artifact = "umi-math",
        tag_prefix = "umi-math-v",
        versions = {
            ["0.3.1"] = "77bb1be3091a1dc75eeb8b6986aa370d4d10beb282a2765c14b584979c3195c5",
        },
    },
})
