# lpkg/rpkg
**lpkg/rpkg** are [fish](https://fishshell.com/) commands to backup linux packages you have installed with package manager commands.

**Note: This repository is still alpha version.**

## What can do?
- `lpkg`: list linux packages you have installed with package manager command.
- `rpkg`: re-install packages from list generated `lpkg`.

## Usage
**lpkg**  
If you want to list packages installed with `sudo apt` to `~/pkg.txt`, then:
```
$ lpkg "sudo apt" > ~/pkg.txt
```
or
```
$ lpkg sudo apt > ~/pkg.txt
```

**rpkg**  
If you want to re-install with `~/pkg.txt` made by `lpkg`, then:
```
$ rpkg ~/pkg.txt
```
You can also install with:
```
$ rpkg https://raw.githubusercontent.com/USERNAME/path/to/lpkg-list
```

## Following package managers
- `apt` (Debian, Ubuntu, etc)
- `apt-get` (Debian, Ubuntu, etc)
- `dnf` (CentOS, Fedora, RedHat, etc)
- `yum` (CentOS, Fedora, RedHat, etc)
- `pacman` (Arch Linux, Manjaro, etc)
- `yaourt` (Arch Linux, Manjaro, etc)
- `pkg` (Android Termux)

## Installation
Fisherman:
```
$ fisher rkbk60/lpkg
```

## TODO
- following other package manager
