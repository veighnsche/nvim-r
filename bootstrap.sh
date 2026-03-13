#!/bin/sh
set -eu

MARKSMAN_VERSION="2026-02-08"
TREE_SITTER_CLI_VERSION="0.26.6"

log() {
	printf '%s\n' "$*" >&2
}

die() {
	log "bootstrap.sh: $*"
	exit 1
}

as_root() {
	if command -v doas >/dev/null 2>&1; then
		doas "$@"
		return
	fi

	if command -v sudo >/dev/null 2>&1; then
		sudo "$@"
		return
	fi

	die "need doas or sudo to install host packages"
}

repo_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
xdg_data_home=${XDG_DATA_HOME:-"$HOME/.local/share"}
nvim_data_dir="$xdg_data_home/nvim"
tool_root="$nvim_data_dir/mason"
bin_dir="$tool_root/bin"

mkdir -p "$bin_dir"

install_apk_packages() {
	as_root apk add --no-cache build-base cargo curl git rust
}

install_dnf_packages() {
	as_root dnf install -y curl gcc gcc-c++ git gzip make tar
}

install_host_packages() {
	if command -v apk >/dev/null 2>&1; then
		install_apk_packages
		return
	fi

	if command -v dnf >/dev/null 2>&1; then
		install_dnf_packages
		return
	fi

	die "unsupported host package manager; expected apk or dnf"
}

tree_sitter_asset_name() {
	arch=$(uname -m)
	case "$arch" in
		x86_64|amd64)
			printf 'tree-sitter-linux-x64.gz\n'
			;;
		aarch64|arm64)
			printf 'tree-sitter-linux-arm64.gz\n'
			;;
		*)
			die "unsupported architecture for tree-sitter: $arch"
			;;
	esac
}

install_tree_sitter_cli() {
	if command -v apk >/dev/null 2>&1; then
		command -v recipe >/dev/null 2>&1 || die "recipe command is required for Alpine bootstrap"
		log "Installing tree-sitter-cli $TREE_SITTER_CLI_VERSION via recipe"
		recipe install --no-persist-ctx --json-output /dev/null "$repo_dir/recipes/alpine/nvim-markdown/tree-sitter-cli.rhai"
		return
	fi

	if [ -x "$bin_dir/tree-sitter" ] && [ "$("$bin_dir/tree-sitter" --version 2>/dev/null || true)" = "tree-sitter $TREE_SITTER_CLI_VERSION" ]; then
		return
	fi

	asset=$(tree_sitter_asset_name)
	url="https://github.com/tree-sitter/tree-sitter/releases/download/v$TREE_SITTER_CLI_VERSION/$asset"
	tmp=$(mktemp -p "${TMPDIR:-/tmp}" tree-sitter-XXXXXX)

	log "Installing tree-sitter-cli $TREE_SITTER_CLI_VERSION from $asset"
	curl -fsSL "$url" -o "$tmp"
	gunzip -c "$tmp" > "$bin_dir/tree-sitter"
	chmod +x "$bin_dir/tree-sitter"
	rm -f "$tmp"
}

marksman_asset_name() {
	arch=$(uname -m)
	case "$arch" in
		x86_64|amd64)
			arch_suffix="x64"
			;;
		aarch64|arm64)
			arch_suffix="arm64"
			;;
		*)
			die "unsupported architecture for marksman: $arch"
			;;
	esac

	if find /lib /lib64 -maxdepth 1 -name 'ld-musl-*.so.1' 2>/dev/null | grep -q .; then
		printf 'marksman-linux-musl-%s\n' "$arch_suffix"
		return
	fi

	printf 'marksman-linux-%s\n' "$arch_suffix"
}

install_marksman() {
	if command -v apk >/dev/null 2>&1; then
		command -v recipe >/dev/null 2>&1 || die "recipe command is required for Alpine bootstrap"
		log "Installing marksman $MARKSMAN_VERSION via recipe"
		recipe install --no-persist-ctx --json-output /dev/null "$repo_dir/recipes/alpine/nvim-markdown/marksman.rhai"
		return
	fi

	if [ -x "$bin_dir/marksman" ] && [ "$("$bin_dir/marksman" --version 2>/dev/null || true)" = "$MARKSMAN_VERSION" ]; then
		return
	fi

	asset=$(marksman_asset_name)
	url="https://github.com/artempyanykh/marksman/releases/download/$MARKSMAN_VERSION/$asset"
	tmp=$(mktemp -p "${TMPDIR:-/tmp}" marksman-XXXXXX)

	log "Installing marksman $MARKSMAN_VERSION from $asset"
	curl -fsSL "$url" -o "$tmp"
	chmod +x "$tmp"
	mv "$tmp" "$bin_dir/marksman"
}

bootstrap_neovim() {
	export PATH="$bin_dir:$HOME/.cargo/bin:$PATH"

	log "Syncing Neovim plugins"
	nvim --headless "+Lazy! sync" +qall

	log "Installing Mason tools and tree-sitter parsers"
	nvim --headless "+MasonToolsInstallSync" "+lua require('vince.bootstrap').install_treesitter_parsers(300000)" +qall
}

verify_neovim() {
	export PATH="$bin_dir:$HOME/.cargo/bin:$PATH"
	tmp_markdown="$repo_dir/.bootstrap-verify.$$.md"
	trap 'rm -f "$tmp_markdown"' EXIT INT TERM
	printf '# bootstrap verify\n\n- markdown\n' > "$tmp_markdown"

	log "Verifying markdown tooling"
	nvim --headless "$tmp_markdown" \
		"+lua local ok, err = pcall(require('vince.bootstrap').verify_markdown_buffer, 10000); if not ok then vim.api.nvim_err_writeln(err); vim.cmd('cquit 1') end" \
		"+lua vim.lsp.stop_client(vim.lsp.get_clients({ bufnr = 0 }))" \
		"+sleep 250m" \
		+qall
	rm -f "$tmp_markdown"
	trap - EXIT INT TERM
}

main() {
	cd "$repo_dir"
	install_host_packages
	install_tree_sitter_cli
	install_marksman
	bootstrap_neovim
	verify_neovim
	log "Bootstrap complete"
}

main "$@"
