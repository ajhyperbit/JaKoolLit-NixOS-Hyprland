#!/usr/bin/env bash

#set -e
#TODO: look into if I can make this automatically symlink into ~/ or /home/ajhyperbit/

# cd to config dir
#pushd ~/dotfiles/nixos/

#fetch = $(git fetch)
#
#    if [[ -z "$fetch" ]] 
#    then
#        echo "Local Repo up to date, no git pull needed"
#    else 
#        git pull || echo "git pull failed, please see log." ; exit 1 

echo "NixOS Rebuilding..."

# Rebuild, output simplified errors, log trackebacks
sudo nixos-rebuild switch --upgrade --show-trace --flake &>nixos-switch.log || (cat nixos-switch.log | grep --color error && exit 1) || grep -P -n "dotfiles\/nixos\/([a-zA-Z]+).nix:[0-9]+:[0-9]+|\/home\/ajhyperbit\/dotfiles\/nixos\/([a-zA-Z]+).nix" nixos-switch.log | sed 's/:[[:blank:]]*/: /'

#grab current generation number
current_tag=$(nixos-rebuild list-generations | grep current | grep -Eo '[0-9]+' | head -1)

#increment current gen
#current=$(($current+1))

#tag the current generation
git tag Gen-$current_tag

#push current gen tag to github
git push origin tag Gen-$current_tag

# Back to where you were
#popd

# Notify all OK!
#notify-send -e "NixOS Rebuilt OK!" --icon=software-update-available