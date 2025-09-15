#!/bin/bash
#set -x -e

echo "###################### WARNING!!! ######################"
echo "###  This script will install all required Software  ###"
echo "###  build Solana CLI from Sources and               ###"
echo "###  set new releas as active.                       ###"
echo "########################################################"

build_cli () {

  read -e -p "Please enter a type of release to build (agave, jito, paladin): " -i "agave" RELEASE_TYPE
  read -e -p "Which version you want to build? " CLI_VERSION
  read -e -p "Please enter the full path where to clone repo: " -i "/tmp/" CLONE_PATH

  read -e -p "Which user is running the validator?: " -i "solana" SOLANA_USER
  read -e -p "Where to store binaries?: " -i "~/.local/share/solana/install/releases" RELEASE_DIR
  read -e -p "Which path to use for active_release link?: " -i "~/.local/share/solana/install/active_release" ACTIVE_RELEASE_DIR
 
  #DEBUG
  echo $RELEASE_TYPE $CLONE_PATH $SOLANA_USER $RELEASE_DIR $ACTIVE_RELEASE_DIR
  #exit

  rm -rf sv_manager/

  echo "Updating packages..."
  apt update
  echo "Installing ansible, curl, unzip..."
  apt install ansible curl unzip --yes

  ansible-galaxy collection install ansible.posix
  ansible-galaxy collection install community.general

  echo "Downloading Solana validator manager version $1"
  cmd="https://github.com/rossignolskier/sv-manager/archive/refs/tags/$1.zip"
  cmd="https://github.com/Rossignolskier/sv-manager/archive/refs/heads/develop.zip"
  echo "starting $cmd"
  curl -fsSL "$cmd" --output sv_manager.zip
  echo "Unpacking"
  unzip ./sv_manager.zip -d .

  mv sv-manager* sv_manager
  rm ./sv_manager.zip
  cd ./sv_manager || exit
  cp -r ./inventory_example ./inventory

  # shellcheck disable=SC2154
  #echo "pwd: $(pwd)"
  #ls -lah ./

  if [ ! -z $solana_version ]
  then
    SOLANA_VERSION="--extra-vars {'solana_version':$solana_version}"
  fi

  if [ ! -z $RELEASE_TYPE ]
  then
    RELEASE="--extra-vars '$RELEASE_TYPE=true'"
  fi

  if [ $SOLANA_USER=="root" ]
  then
    SOLANA_HOME="--extra-vars 'solana_home=/root'"
  fi


  ansible-playbook --connection=local --inventory ./inventory/$inventory --limit localhost  playbooks/pb_config.yaml $RELEASE $SOLANA_HOME --extra-vars "{ \
  'git_clone_target':'$CLONE_PATH', \
  'releases_dir': '$RELEASE_DIR', \
  'active_release_dir': $ACTIVE_RELEASE_DIR, \
  'cli_version': $CLI_VERSION, \
  'solana_user': $SOLANA_USER \
  }"

  echo "### 'Uninstall ansible ###"

  $pkg_manager remove ansible --yes



}

version=${1:-latest}
solana_version=$2
#echo "installing sv manager version $sv_version"
echo "Do you want to buil Solana CLI binaries?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) build_cli "$version" "$solana_version"; break;;
        No ) echo "Aborting install. No changes will be made."; exit;;
    esac
done
