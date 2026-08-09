
<p align="center">
  <img src="slogan_bootc_manager.png" alt="Bootc Manager slogan" width="100%">
</p>

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Fedora Atomic](https://img.shields.io/badge/Fedora-Atomic_&_bootc-blueviolet.svg)](https://fedoraproject.org/)
[![Shell Script](https://img.shields.io/badge/Language-Bash-4EAA25.svg)](https://www.gnu.org/software/bash/)
[![Release](https://img.shields.io/github/v/release/diogopessoa/bootc-manager?color=orange)](https://github.com/diogopessoa/bootc-manager/releases)

**Bootc Manager** is not intended to replace `bootc` or introduce redundant features. Instead, it provides a user-friendly menu-driven interface to simplify daily maintenance tasks—making container-based OS management accessible and straightforward.


## Key Features

- **Dual-Backend Support:** Native support for `bootc` (Fedora Atomic 45+) with seamless fallback to `rpm-ostree`.
- **System Upgrades & Rollbacks:** Trigger image updates or safely roll back to a previous deployment with confirmation prompts.
- **Image Switching (`bootc switch`):** Easily switch between desktop environments or custom OCI container images.
- **Layering Detection:** Automatically inspects and warns about local package layering (`rpm-ostree` mutations) that might conflict with `bootc` updates.
- **Configurable of bootc-manager.conf:** Allows you to configure the Bootc-Manager without complicating the standard workflow.
- **Desktop Integration:** Includes a `.desktop` shortcut for seamless execution directly from your application launcher.

## Requirements

* **Operating System:** Operating System:** Fedora Atomic 45+ and derivatives (Silverblue, Kinoite, Sericea, Aurora, Bazzite, etc.).
* **Core Tooling:** `bootc` and/or `rpm-ostree`.
  
## Quick Installation

Run the automated installer script in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/diogopessoa/bootc-manager/main/install.sh | bash

```

Once installed, you can launch the application by:

1. Running `bootc-manager` in any terminal window, or
2. Searching for **Bootc-Manager** in your system application menu.


## Configuration of bootc-manager.conf (still under development)

The `bootc-manager.conf` file can be used to configure Bootc-Manager without complicating the standard workflow. Can be configured in `/etc/bootc-manager.conf`, it will allow for options such as:

- choosing a preferred backend (bootc vs. rpm-ostree);
- enabling/disabling layering warnings;
- enable check-only

Example:

```bash
# Enable check-only / dry-run mode by default
PREFER_DRY_RUN=1

```

## File Destination Tree

This map shows where each file is placed on your system after running the installer:

```text
Destination Path
├── /usr/local/bin/bootc-manager                      # Main executable script
├── /etc/bootc-manager.conf                           # System-wide configuration file (optional)
├── ~/.local/share/icons/bootc-manager.svg            # User application icon
└── ~/.local/share/applications/bootc-manager.desktop # Application Menu shortcut
```

## Uninstallation

If you wish to completely remove **Bootc Manager** from your system, run the following command in your terminal:

```bash
sudo rm -f /usr/local/bin/bootc-manager /usr/share/applications/bootc-manager.desktop /etc/bootc-manager.conf && \
rm -f ~/.local/share/applications/bootc-manager.desktop \
     ~/.local/share/icons/bootc-manager.svg && \
echo "Bootc Manager has been successfully uninstalled."
```

## References & Links

* **Repository:** [github.com/diogopessoa/bootc-manager](https://github.com/diogopessoa/bootc-manager)
* **Documentation & Wiki:** [github.com/diogopessoa/bootc-manager/wiki](https://github.com/diogopessoa/bootc-manager/wiki)
* **Fedora User Guide:** [docs.fedoraproject.org/en-US/bootc](https://docs.fedoraproject.org/en-US/bootc/)


## License

This project is licensed under the [MIT License](https://www.google.com/search?q=LICENSE).
