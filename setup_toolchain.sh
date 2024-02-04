#!/bin/bash

# Verify the repo is up to date
check_submodule () {
    # Is this a Git repo? Does the remote url match the one specified?
    if [[ -d "$2"/.git ]] && [[ "$(git -C $2 config --get remote.origin.url)" == $1* ]] ; then
      # Is HEAD detached?
      if git -C $2 symbolic-ref HEAD 2>/dev/null; then
        git -C $2 pull
      # Are there any tags?
      elif [ -n "$(git -C $2 tag | tail -n1)" ]; then
        # Checkout to latest tag
        git -C $2 -c advice.DetachedHEAD=false checkout $(git -C $2 tag | tail -n1)
      fi
    else
      rm -rf $2/
      git clone $1 $2
    fi
}
check_compiler () {
    if [[ ! -e $2/bin/clang ]]; then
      rm -rf $2/
      wget $1 -nv -O llvm.tar.xz 1> /dev/null
      tar -xJf llvm.tar.xz && rm llvm.tar.xz
      mv llvm* $2/
    fi
}
echo "Setting up dependencies and toolchains"
set -x

sudo apt-get update -y 1> /dev/null
sudo apt-get install rsync curl wget xz-utils git p7zip-full -y 1> /dev/null

check_compiler https://cdn.kernel.org/pub/tools/llvm/files/llvm-18.1.0-x86_64.tar.xz llvm

check_submodule https://github.com/cachiusa/aosp-kernel-build build
git -C build checkout master
git -C build submodule update --init --recursive

check_submodule https://github.com/cachiusa/AnyKernel3 AnyKernel3
git -C AnyKernel3 checkout veux

check_submodule https://github.com/tiann/KernelSU KernelSU
. KernelSU/kernel/setup.sh

if [[ ! -e usr/ramdisk.cpio ]]; then
  wget https://github.com/cachiusa/AnyKernel3/releases/download/1.0.0/ramdisk.7z -nv -O ramdisk.7z
  (cd usr && 7z e ../ramdisk.7z)
  rm ramdisk.7z
fi