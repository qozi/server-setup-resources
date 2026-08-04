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
    nginx.tar.gz
    mysql57.tar.gz
    mysql8.tar.gz
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

下载并校验执行器：

```bash
VERSION=v1.0.0
BASE_URL="https://raw.githubusercontent.com/qozi/server-setup-resources/main/installers/${VERSION}"
curl -fLO "${BASE_URL}/server-setup.run"
curl -fLO "${BASE_URL}/server-setup.run.sha256"
shasum -a 256 --check server-setup.run.sha256
chmod 700 server-setup.run
./server-setup.run
```

离线或受限网络环境可预先下载同版本模板目录，随后在控制端运行：

```bash
./server-setup.run other-software \
  --template-source local \
  --template-dir /opt/server-setup-resources/templates/v1.0.0
```

本地模板目录必须同时包含应用的 `<应用名>.tar.gz` 和 `manifest.sha256`。远程安装时，执行器会将控制端模板复制到目标服务器，并在目标服务器校验 SHA-256 后部署。

## 发布

不要直接手工修改版本目录。进入主代码仓库后执行：

```bash
./publish-resources.sh \
  --version v1.0.0 \
  --resource-repo /Users/qozi/Workspace/Project/p01_siidoo/server-setup-resources
```

发布脚本会从主代码仓库已跟踪的模板源文件构建归档，生成校验清单和单文件执行器，创建新的不可覆盖版本目录，提交并推送到本仓库的 `main` 分支。推送认证使用 SSH agent 或本机 Git 凭据，不应将 Token、密码或私钥写入仓库。
