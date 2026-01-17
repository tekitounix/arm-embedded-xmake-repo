-- clangd configuration rule
-- プロジェクトルートに.clangdファイルを自動生成

rule("clangd.config")
    set_kind("project")

    after_build(function (opt)
        import("core.project.config")
        import("core.project.project")
        import("core.base.global")
        import("lib.detect.find_program")

        -- xmakeパッケージインストール中は実行しない
        if os.getenv("XMAKE_IN_XREPO") then
            return
        end

        -- ロックファイルで重複実行を防止
        local tmpfile = path.join(config.builddir(), ".gens", "rules", "clangd.config")
        local lockfile = io.openlock(tmpfile .. ".lock")
        if not lockfile:trylock() then
            return
        end

        -- ツールチェーンパスを収集
        local query_drivers = {}
        local seen = {}

        for _, target in pairs(project.targets()) do
            local compiler = target:compiler("cxx") or target:compiler("cc")
            if compiler then
                local compiler_path = compiler:program()
                if compiler_path and not seen[compiler_path] then
                    seen[compiler_path] = true

                    -- ARM クロスコンパイラを検出
                    if compiler_path:find("arm%-none%-eabi") or
                       (compiler_path:find("clang") and target:get("arch") == "arm") then
                        -- 実際のパスを解決
                        local real_path = os.realpath(compiler_path)
                        if real_path and os.isfile(real_path) then
                            table.insert(query_drivers, real_path)
                        else
                            -- ワイルドカードパターンとして追加
                            table.insert(query_drivers, compiler_path)
                        end
                    end
                end
            end
        end

        -- .clangd ファイルを生成
        local clangd_file = path.join(os.projectdir(), ".clangd")

        -- ベース設定を読み込み
        local base_config = path.join(global.directory(), "rules", "coding", "configs", ".clangd")
        local content = ""
        if os.isfile(base_config) then
            content = io.readfile(base_config)
        else
            content = [[CompileFlags:
  CompilationDatabase: .build/
]]
        end

        -- query-driver を追加（ARMクロスコンパイラがある場合）
        if #query_drivers > 0 then
            -- YAMLとしてquery-driverを追加
            local drivers_str = table.concat(query_drivers, ",")

            -- 既存のCompileFlags:セクションにAddを追加
            if content:find("CompileFlags:") then
                -- Addセクションがあれば追記、なければ新規作成
                if content:find("Add:") then
                    -- 既存のAddセクションに追加
                    content = content:gsub("(Add:%s*\n)",
                        "%1    - \"--query-driver=" .. drivers_str .. "\"\n")
                else
                    -- CompileFlags:の後にAddセクションを挿入
                    content = content:gsub("(CompileFlags:%s*\n)",
                        "%1  Add:\n    - \"--query-driver=" .. drivers_str .. "\"\n")
                end
            end
        end

        -- 変更があれば書き込み
        local need_update = true
        if os.isfile(clangd_file) then
            local existing = io.readfile(clangd_file)
            if existing == content then
                need_update = false
            end
        end

        if need_update then
            io.writefile(clangd_file, content)
            print(".clangd generated with %d query-driver(s)", #query_drivers)
        end

        lockfile:close()
    end)
