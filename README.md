# Server Setup Resources

`server-setup` 的公开发布资源仓库。此仓库只保存由主代码仓库构建的版本化执行器、Docker Compose 模板包和校验清单，不在此处维护源代码或模板源文件。

主代码仓库：<https://github.com/qozi/sever-setup>

## 目录结构

```text
installers/
  v1.0.0/
    server-setup.run
    server-setup.run.sha256
templates/
  v1.0.0/
    certimate.tar.gz
    mysql57.tar.gz
    mysql8.tar.gz
    nginx.tar.gz
    redis6.tar.gz
    manifest.sha256
manifests/
  v1.0.0.yml
```

- `installers/<版本>/server-setup.run`：自解压 Bash 单文件执行器，不包含 Compose 模板包。
- `installers/<版本>/server-setup.run.sha256`：执行器 SHA-256 校验值。
- `templates/<版本>/`：对应执行器版本的 Compose 模板包和 SHA-256 校验清单。
- `manifests/<版本>.yml`：版本、执行器校验值与模板文件列表。

## 使用资源

### 聚合安装

一行命令下载、校验并启动执行器：

```bash
curl -fsSL https://raw.githubusercontent.com/qozi/server-setup-resources/main/bootstrap.sh | bash
```

指定版本或透传参数给执行器：

```bash
curl -fsSL https://raw.githubusercontent.com/qozi/server-setup-resources/main/bootstrap.sh \
  | bash -s -- --version v1.0.0 other-software
```

`bootstrap.sh` 会下载指定版本（默认 `v1.0.0`）的执行器与 SHA-256 校验值，校验通过后赋权并执行，其余参数透传给 `server-setup.run`。`curl|bash` 模式下会自动重新指向 `/dev/tty` 以支持执行器内的交互式菜单。

### 手动下载与校验

不使用聚合脚本时，可手动下载并校验：

```bash
VERSION=v1.0.0
URL="https://raw.githubusercontent.com/qozi/server-setup-resources/main/installers/$VERSION"
curl -fLO "$URL/server-setup.run"{,.sha256} && \
  shasum -a 256 --check server-setup.run.sha256 && \
  chmod 700 server-setup.run && \
  ./server-setup.run
```

### 离线或受限网络

预先下载同版本模板目录，随后在控制端运行：

```bash
./server-setup.run other-software \
  --template-source local \
  --template-dir /opt/server-setup-resources/templates/v1.0.0
```

本地模板目录必须同时包含应用的 `<应用名>.tar.gz` 和 `manifest.sha256`。远程安装时，执行器会将控制端模板复制到目标服务器，并在目标服务器校验 SHA-256 后部署。

## 发布

不要直接手工修改版本目录。进入主代码仓库后执行：

```bash
./publish-resources.sh --version v1.0.0
```

发布脚本从主代码仓库已跟踪的模板源文件构建归档，生成校验清单和单文件执行器，创建版本目录，提交并推送到本仓库的 `main` 分支。脚本默认使用相邻目录 `../server-setup-resources` 作为本地资源仓库；若该目录不存在，会自动克隆临时副本到临时目录完成发布，发布完成后清理。也可以通过 `--resource-repo` 或 `SERVER_SETUP_RESOURCES_REPOSITORY` 显式指定本地资源仓库路径（此时路径必须存在）。推送认证使用 SSH agent 或本机 Git 凭据，不应将 Token、密码或私钥写入仓库。

## 版本管理

- **不可变承诺**：版本目录一旦发布，其执行器、模板包、校验清单与 manifest 应保持不变，确保已引用该版本的目标机在任意时间重新部署都能得到一致的结果与校验值。正式发布勿覆盖已存在版本。
- **--force 选项**：开发期可用 `./publish-resources.sh --version v1.0.0 --force` 覆盖已存在的版本目录，用于迭代尚未正式对外发布的版本。覆盖会重写归档与校验值；GitHub raw CDN 缓存刷新前，目标机可能因 manifest 与 tarball 不一致导致 SHA-256 校验失败，请谨慎使用。
- **bootstrap.sh 维护**：`bootstrap.sh` 的默认版本写死在脚本中。发布新的默认版本后，需更新 `bootstrap.sh` 顶部的 `VERSION` 默认值并提交到 `main` 分支。
