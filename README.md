# Server Setup Resources

![公开资源](https://img.shields.io/badge/资源-公开-0f766e) ![完整性校验](https://img.shields.io/badge/完整性-SHA--256-2563eb)

[中文](README.md) | [English](README_EN.md)

Server Setup 的公开资源仓库：版本化单文件执行器、Compose 模板包、校验清单与引导器。用于 **macOS/Linux 控制端通过 SSH 管理 VPS**，不要选择本机安装。目标支持 CentOS、Rocky Linux、Oracle Linux 9、Debian、Ubuntu。

## 快速使用

在控制端交互式终端启动，默认版本为 `latest`：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/qozi/server-setup-resources/main/bootstrap.sh)
```

固定版本并进入其他软件入口，只有一个参数分隔符：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/qozi/server-setup-resources/main/bootstrap.sh) \
  --version v1.0.0 -- other-software
```

`--version` 必须在 `--` 前；后面的参数传给执行器。固定版本需核对目录和支持的参数；`latest` 随发布更新。建议先下载审查引导器，进程替换用于保留终端输入。

执行器工作目录是临时目录。需要保存远程目标时，使用控制端持久化 inventory，不依赖临时目录中的默认文件：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/qozi/server-setup-resources/main/bootstrap.sh) \
  -- setup -i /path/to/hosts.ini --limit web-01
```

目标账户需 root 或 sudo 权限；推荐 SSH agent/密钥。需要密码时追加 `--ask-pass --ask-become-pass`，其中 `--ask-pass` 会为本次 Ansible 调用关闭主机密钥检查。不要在 inventory 或预设保存密码。

## 资源与受限网络

| 路径 | 内容 |
| --- | --- |
| `installers/<version>/` | `server-setup.run` 与相邻 `.sha256` |
| `templates/<version>/` | 应用 `.tar.gz` 与 `manifest.sha256` |
| `manifests/<version>.yml` | 发布版本与资源清单 |

执行器不包含模板归档。控制端已备好同版本模板时，可复制到 VPS 部署：

```bash
./server-setup.run other-software -i /path/to/hosts.ini --limit web-01 \
  --template-source local --template-dir /path/to/templates/latest
```

目录必须包含对应归档和 `manifest.sha256`。这不是完整离线安装，VPS 仍可能需要联网拉取镜像、系统软件和开发工具。

## 安全与文档

公开下载不需要 Token。SHA-256 检查完整性，**不是数字签名**；同源校验值不能认证发布者，且不校验先执行的引导器本身。数据归档可能包含凭据与业务数据，不加密，须妥善保管。

- [源码仓库](https://github.com/qozi/sever-setup)：实际远程拼写为 `sever-setup`。
- [规划文档仓库](https://github.com/qozi/server-setup-docs)：**尚未创建，Mintlify 双语文档站待上线**，链接目前可能返回 404。
- 站点上线前，请结合执行器 `--help` 和源码中的实际参数说明使用。
