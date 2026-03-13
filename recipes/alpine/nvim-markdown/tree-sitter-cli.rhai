let ctx = #{
    name: "tree-sitter-cli",
    version: "0.26.6",
    url: "https://github.com/tree-sitter/tree-sitter/archive/refs/tags/v0.26.6.tar.gz",
    sha256: "b4218185a48a791d4022ab3969709e271a70a0253e94792abbcf18d7fcf4291c",
    archive: "",
    src_dir: "",
    built_binary: "",
};

fn data_home() {
    let xdg = env("XDG_DATA_HOME");
    if xdg != "" {
        return xdg;
    }
    join_path(join_path(env("HOME"), ".local"), "share")
}

fn nvim_mason_bin_dir() {
    join_path(join_path(join_path(data_home(), "nvim"), "mason"), "bin")
}

fn install_path() {
    join_path(nvim_mason_bin_dir(), "tree-sitter")
}

fn is_installed(ctx) {
    let dst = install_path();
    if !is_file(dst) {
        throw "tree-sitter is not installed";
    }

    let version = trim(shell_output(dst + " --version"));
    if version != "tree-sitter " + ctx.version {
        throw "tree-sitter version mismatch: " + version;
    }

    ctx
}

fn is_acquired(ctx) {
    if ctx.archive == "" || !is_file(ctx.archive) {
        throw "tree-sitter source archive is missing";
    }
    ctx
}

fn is_built(ctx) {
    if ctx.built_binary == "" || !is_file(ctx.built_binary) {
        throw "tree-sitter binary has not been built";
    }

    let version = trim(shell_output(ctx.built_binary + " --version"));
    if version != "tree-sitter " + ctx.version {
        throw "tree-sitter build version mismatch: " + version;
    }

    ctx
}

fn acquire(ctx) {
    mkdir(BUILD_DIR);
    let archive = join_path(BUILD_DIR, "tree-sitter-" + ctx.version + ".tar.gz");
    download(ctx.url, archive);
    verify_sha256(archive, ctx.sha256);
    ctx.archive = archive;
    ctx
}

fn build(ctx) {
    extract(ctx.archive, BUILD_DIR);
    let src_dir = join_path(BUILD_DIR, "tree-sitter-" + ctx.version);
    let cargo_toml = join_path(src_dir, "Cargo.toml");
    let original = "tree-sitter-generate = { version = \"" + ctx.version + "\", path = \"./crates/generate\" }";
    let patched = "tree-sitter-generate = { version = \"" + ctx.version + "\", path = \"./crates/generate\", default-features = false, features = [\"load\"] }";
    replace_in_file(cargo_toml, original, patched);
    shell_in(src_dir, "cargo build --release -p tree-sitter-cli --no-default-features");
    ctx.src_dir = src_dir;
    ctx.built_binary = join_path(join_path(src_dir, "target/release"), "tree-sitter");
    ctx
}

fn install(ctx) {
    mkdir(nvim_mason_bin_dir());
    copy_file(ctx.built_binary, install_path());
    chmod(install_path(), 0o755);
    ctx
}

fn remove(ctx) {
    if is_file(install_path()) {
        rm(install_path());
    }
    ctx
}

fn cleanup(ctx, reason) {
    ctx
}
