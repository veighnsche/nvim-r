let ctx = #{
    name: "marksman",
    version: "2026-02-08",
    sha256_x64: "d33df4544bb1f9f1b93b862ea78375ca8c04cd467ed2bcee354d605fc483ceee",
    sha256_arm64: "cd3b91b630042cc09b20505583203f875fbb4bf2fdf74dd6d87fddc3238d2798",
    downloaded: "",
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
    join_path(nvim_mason_bin_dir(), "marksman")
}

fn machine_arch() {
    trim(shell_output("uname -m"))
}

fn arch_suffix() {
    let arch = machine_arch();
    if arch == "x86_64" || arch == "amd64" {
        return "x64";
    }
    if arch == "aarch64" || arch == "arm64" {
        return "arm64";
    }
    throw "unsupported Alpine marksman architecture: " + arch;
}

fn marksman_url(ctx) {
    "https://github.com/artempyanykh/marksman/releases/download/" + ctx.version + "/marksman-linux-musl-" + arch_suffix()
}

fn marksman_sha256(ctx) {
    if arch_suffix() == "x64" {
        return ctx.sha256_x64;
    }
    if arch_suffix() == "arm64" {
        return ctx.sha256_arm64;
    }
    throw "unsupported Alpine marksman architecture: " + machine_arch();
}

fn is_installed(ctx) {
    let dst = install_path();
    if !is_file(dst) {
        throw "marksman is not installed";
    }

    let version = trim(shell_output(dst + " --version"));
    if version != ctx.version {
        throw "marksman version mismatch: " + version;
    }

    ctx
}

fn is_acquired(ctx) {
    if ctx.downloaded == "" || !is_file(ctx.downloaded) {
        throw "marksman download is missing";
    }
    ctx
}

fn acquire(ctx) {
    mkdir(BUILD_DIR);
    let downloaded = join_path(BUILD_DIR, "marksman-linux-musl-" + arch_suffix());
    download(marksman_url(ctx), downloaded);
    verify_sha256(downloaded, marksman_sha256(ctx));
    ctx.downloaded = downloaded;
    ctx
}

fn install(ctx) {
    mkdir(nvim_mason_bin_dir());
    copy_file(ctx.downloaded, install_path());
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
