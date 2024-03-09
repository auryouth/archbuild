#!/bin/bash

pkg=$INPUT_PKG
version=$INPUT_VERSION

# 初始化
useradd builder -m
echo "builder ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers
chmod -R a+rw .

cat <<EOM >>/etc/pacman.conf
[multilib]
Include = /etc/pacman.d/mirrorlist
EOM

pacman -Syu --noconfirm
pacman -S base-devel --noconfirm

cd $pkg || exit 1

# 用于后续 delete-asset
# old_pkgver=$(cat PKGBUILD | grep -n "^pkgver=" | awk -F= '{print $2}')

if ! grep -nq "^pkgver()" PKGBUILD; then
	sed -i "s/^pkgver=.*/pkgver=$version/" PKGBUILD
fi
sudo -u builder updpkgsums
sudo -u builder bash -c 'export MAKEFLAGS=j$(nproc) && makepkg -s --noconfirm'
asset=$(basename $(sudo -u builder makepkg --packagelist))

echo "asset=$asset" >>$GITHUB_OUTPUT