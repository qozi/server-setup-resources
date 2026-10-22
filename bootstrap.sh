#!/usr/bin/env bash
#
# server-setup 聚合安装入口。
#
# 从本仓库下载指定版本的 server-setup.run 执行器与 SHA-256 校验值，
# 校验通过后赋权并执行，参数透传给执行器。
#
# 用法（推荐进程替换，stdin 保留终端以支持交互式菜单）：
#   bash <(curl -fsSL https://raw.githubusercontent.com/qozi/server-setup-resources/main/bootstrap.sh)
#   bash <(curl -fsSL https://raw.githubusercontent.com/qozi/server-setup-resources/main/bootstrap.sh) \
#     --version v1.0.0 -- other-software
#
# 选项：
#   --version 版本   指定执行器版本，默认 latest
#   --               此后的参数全部透传给 server-setup.run
#
# 维护说明：latest 版本每次发布自动覆盖，无需更新此文件。

set -euo pipefail

# REPO_BASE 是公开资源根地址，下载无需 Token；VERSION 选择执行器目录。
# latest 随发布更新，--version 可指定固定版本；这里不改变执行器内部的版本选择逻辑。
# PASS_ARGS 使用数组保留参数边界，避免路径空格或通配符被二次拆分。
REPO_BASE="https://raw.githubusercontent.com/qozi/server-setup-resources/main"
VERSION="latest"
PASS_ARGS=()

# 分隔符之前识别引导器的 --version，其余参数收集后交给执行器。
# 遇到唯一的 -- 后停止解析，后续内容原样透传；无需再增加一个 --。
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

# INSTALLER_URL 只定位执行器和其校验文件，Compose 模板由执行器另行获取。
# WORK_DIR 隔离本次下载，EXIT 清理仅作用于此临时目录，不保存用户 inventory。
INSTALLER_URL="$REPO_BASE/installers/$VERSION"

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/server-setup-bootstrap.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

# 下载设置连接/总时限和重试，任一下载失败均由严格模式终止。
# 执行器和校验文件必须来自同一版本目录，不能跳过校验继续执行。
printf '下载 server-setup 执行器 %s ...\n' "$VERSION"
curl -fsSL --connect-timeout 10 --max-time 120 --retry 3 --retry-delay 2 \
  "$INSTALLER_URL/server-setup.run"         -o "$WORK_DIR/server-setup.run"
curl -fsSL --connect-timeout 10 --max-time 120 --retry 3 --retry-delay 2 \
  "$INSTALLER_URL/server-setup.run.sha256"  -o "$WORK_DIR/server-setup.run.sha256"

# 在下载目录解析校验文件中的相对文件名，兼容 Linux 与 macOS 校验工具。
# SHA-256 仅检查完整性，不是签名；同源校验值不能认证发布者或保护本引导器。
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
# TTY_STDIN 控制执行器的输入来源：stdin 非终端而 stdout 是终端时尝试 /dev/tty。
# 仅重定向子进程，避免改变 bash 对本引导脚本的读取；无终端时沿用原 stdin。
# 推荐进程替换以保留终端输入，菜单中应选择 SSH 远程 VPS 而非控制端本机。
TTY_STDIN=""
if [ ! -t 0 ] && [ -t 1 ] && [ -r /dev/tty ] 2>/dev/null; then
  TTY_STDIN=/dev/tty
fi
# 有参数时逐项传递；无参数时让执行器进入默认 setup 入口。
# 执行器结束后触发清理；需要保留目标配置时应指定控制端持久化 inventory。
if ((${#PASS_ARGS[@]} > 0)); then
  printf '启动 server-setup（参数：%s）...\n' "${PASS_ARGS[*]}"
  if [ -n "$TTY_STDIN" ]; then
    ./server-setup.run "${PASS_ARGS[@]}" < "$TTY_STDIN"
  else
    ./server-setup.run "${PASS_ARGS[@]}"
  fi
else
  printf '启动 server-setup ...\n'
  if [ -n "$TTY_STDIN" ]; then
    ./server-setup.run < "$TTY_STDIN"
  else
    ./server-setup.run
  fi
fi
