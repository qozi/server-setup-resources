# Server Setup Resources

![Public resources](https://img.shields.io/badge/resources-public-0f766e) ![Integrity checks](https://img.shields.io/badge/integrity-SHA--256-2563eb)

[中文](README.md) | [English](README_EN.md)

Public Server Setup resources: versioned single-file executors, Compose template archives, manifests, and bootstrap. Use a **macOS/Linux control machine to manage VPS hosts over SSH**; do not select local installation. Supported targets are CentOS, Rocky Linux, Oracle Linux 9, Debian, and Ubuntu.

## Quick Use

Start from an interactive terminal on the control machine. The default version is `latest`:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/qozi/server-setup-resources/main/bootstrap.sh)
```

Pin a version and enter other-software, using only one separator:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/qozi/server-setup-resources/main/bootstrap.sh) \
  --version v1.0.0 -- other-software
```

Put `--version` before `--`; later arguments go to the executor. Check pinned release directories and supported options before use. `latest` changes with releases. Inspect bootstrap before executing it; process substitution preserves terminal input.

The executor uses a temporary working directory. To keep remote targets, supply a persistent control-machine inventory instead of relying on the temporary default file:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/qozi/server-setup-resources/main/bootstrap.sh) \
  -- setup -i /path/to/hosts.ini --limit web-01
```

The target account needs root or sudo privileges. Prefer an SSH agent/key. Append `--ask-pass --ask-become-pass` if passwords are needed; `--ask-pass` disables host key checking for that Ansible invocation. Never store passwords in inventory or presets.

## Resources and Restricted Networks

| Path | Contents |
| --- | --- |
| `installers/<version>/` | `server-setup.run` and adjacent `.sha256` |
| `templates/<version>/` | Application `.tar.gz` archives and `manifest.sha256` |
| `manifests/<version>.yml` | Release version and resource inventory |

The executor does not bundle template archives. With matching-version templates on the control machine, copy them to the VPS for deployment:

```bash
./server-setup.run other-software -i /path/to/hosts.ini --limit web-01 \
  --template-source local --template-dir /path/to/templates/latest
```

The directory must contain matching archives and `manifest.sha256`. This is not a fully offline installation: the VPS may still need network access for images, system packages, and development tools.

## Security and Documentation

Public downloads require no token. SHA-256 checks integrity and **is not a digital signature**. Same-source checksums do not authenticate the publisher and do not verify bootstrap itself before execution. Data archives may contain credentials and business data; they are unencrypted and require secure handling.

- [Source repository](https://github.com/qozi/sever-setup): `sever-setup` is the actual remote spelling.
- [Planned documentation repository](https://github.com/qozi/server-setup-docs): **not yet created; bilingual Mintlify hosting is pending**. The link may currently return 404.
- Until the site is live, consult executor `--help` and the actual source argument documentation.
