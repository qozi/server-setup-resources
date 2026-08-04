#!/usr/bin/env bash
#
# server-setup 聚合安装入口。
#
# 从本仓库下载指定版本的 server-setup.run 执行器与 SHA-256 校验值，
# 校验通过后赋权并执行，参数透传给执行器。
#
# 用法：
#   curl -fsSL https://raw.githubusercontent.com/qozi/server-setup-resources/main/bootstrap.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/qozi/server-setup-resources/main/bootstrap.sh \
#     | bash -s -- --version v1.0.0 other-software
#
# 选项：
#   --version v主.次.修订   指定执行器版本，默认 v1.0.0
#   --                     此后的参数全部透传给 server-setup.run
#
# 维护说明：发布新的默认版本后，需更新下方 VERSION 默认值。

set -euo pipefail

REPO_BASE="https://raw.githubusercontent.com/qozi/server-setup-resources/main"
VERSION="v1.0.0"
PASS_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      [[ $# -ge 2 && -n "$2" ]] || { printf '错误：--version 缺少参数。\n' >&2; exit 1; }
      VERSION="$2"
      shift 2
      ;;
    --)
      shift
      PASS_ARGS+=("$@")
      break
      ;;
    *)
      PASS_ARGS+=("$1")
      shift
      ;;
  esac
done

INSTALLER_URL="$REPO_BASE/installers/$VERSION"

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/server-setup-bootstrap.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

# curl|bash 模式下 stdin 是管道，尝试重新指向 /dev/tty 以支持执行器内的交互式菜单
# /dev/tty 在纯 CI 环境可能不可用，失败时保持原 stdin 继续运行
if [ ! -t 0 ] && [ -t 1 ]; then
  exec </dev/tty 2>/dev/null || true
fi

printf '下载 server-setup 执行器 %s ...\n' "$VERSION"
curl -fsSL "$INSTALLER_URL/server-setup.run"         -o "$WORK_DIR/server-setup.run"
curl -fsSL "$INSTALLER_URL/server-setup.run.sha256"  -o "$WORK_DIR/server-setup.run.sha256"

cd "$WORK_DIR"
printf '校验 SHA-256 ...\n'
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum -c server-setup.run.sha256
elif command -v shasum >/dev/null 2>&1; then
  shasum -a 256 -c server-setup.run.sha256
else
  printf '错误：缺少 sha256sum 或 shasum，无法校验执行器完整性。\n' >&2
  exit 1
fi

chmod 700 server-setup.run
if ((${#PASS_ARGS[@]} > 0)); then
  printf '启动 server-setup（参数：%s）...\n' "${PASS_ARGS[*]}"
  ./server-setup.run "${PASS_ARGS[@]}"
else
  printf '启动 server-setup ...\n'
  ./server-setup.run
fi
