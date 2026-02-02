# Dotfiles for Hyprland on Arch Linux

[![Arch Linux](https://img.shields.io/badge/Arch-Linux-1793D1?logo=arch-linux&logoColor=white)](https://archlinux.org/)

Dotfiles setup with static and dynamic themes and plenty of useful scripts.

<table>
  <tr>
    <td><img src="demo/1.png" width="400"/></td>
    <td><img src="demo/8.png" width="400"/></td>
  </tr>
  <tr>
    <td><img src="demo/4.png" width="400"/></td>
    <td><img src="demo/2.png" width="400"/></td>
  </tr>
  <tr>
    <td><img src="demo/6.png" width="400"/></td>
    <td><img src="demo/3.png" width="400"/></td>
  </tr>
</table>

Quick info:

- [bin](bin) - all scripts live here, it is added to path in uwsm config
- [install](install/install) - main installation script
- [pkgs.txt](install/pkgs.txt) - packages to be installed
- [setup-applications](install/setup-applications) - hides some annoying applications from launcher
- [setup-by-hardware](install/setup-by-hardware) - sets up monitors, keybindings, hypr enviroments
- [setup-config](install/setup-config) - copies full config into ~/.config
- [setup-lazyvim](install/setup-lazyvim) - lazyvim setup
- [setup-nvidia](install/setup-nvidia) - nvidia specific setup
- [setup-system](install/setup-system) - ufw, pacman.conf, triggers nvidia-setup if on nvidia gpu, git, ly login manager (if exists), enables gcr agent for ssh, disables systemd-networkd-wait-online.service that causes extremly long boot time
- [setup-theme](install/setup-theme) - theming setup and symlinks
- [setup-zsh](install/setup-zsh) - full zsh config with oh-my-zsh, plugins, nice features
