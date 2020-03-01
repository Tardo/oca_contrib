#!/usr/bin/env bash
##########################################################
# OCA Contrib 0.7.0
# 'Copyright' 2019 Alexandre Díaz - <dev@redneboa.es>
#
# This script is powered by:
# - Doodba by Tecnativa - https://github.com/Tecnativa/doodba
# - OCA Mantainer Tools Wiki's - https://github.com/OCA/maintainer-tools/wiki/
#
# License GPL-3.0 or later (http://www.gnu.org/licenses/gpl).
##########################################################
set -e

GIT_DEF_REMOTE="origin"
REGEX_NUMBER='^[0-9]{1,2}\.[0-9]{1,2}[a-Z]?$'
REGEX_URL='^https?:\/\/'
PATH_REPOS="odoo/custom/src/repos.yaml"
PATH_ADDONS="odoo/custom/src/addons.yaml"

print_help()
{
  echo -e "\nUsage: $0 <tool> <action> [options]"
  echo "Available Tools & Actions:"
  echo "  - docker"
  echo "    · create <proj_name> <version>"
  echo "    · build"
  echo "    · add_modules <repo_name/repo> [modules (separated by comma without spaces)]"
  echo "    · del_modules <repo_name> [modules (separated by comma without spaces)]"
  echo "    · resync_modules"
  echo "    · test_modules <modules (separated by comma without spaces)>"
  echo "    · install_modules <modules (separated by comma without spaces)>"
  echo "    · update_modules <modules (separated by comma without spaces)>"
  echo "    · shell"
  echo "    · bash"
  echo "    · psql [database (by default is 'postgres')]"
  echo "    · repair <version>"
  echo "  - git"
  echo "    · migrate <module> <version_to> [version_from]"
  echo "    · use_pr <pr_number>"
  echo "    · fix_history <module> <hash> <version_to> [version_from]"
  echo "    · show_conflict_files"
  echo "Example: $0 docker create my_project 12"
}


#== HELPER FUNCTIONS

sanitize_odoo_version()
{
  ODOO_VER=$1

  if ! [[ $ODOO_VER =~ $REGEX_NUMBER ]]; then
    ODOO_VER="$ODOO_VER.0"
    if ! [[ $ODOO_VER =~ $REGEX_NUMBER ]]; then
      ODOO_VER=$1
    fi
  fi
  echo $ODOO_VER
}


#== DOCKER

_prepare_docker_files()
{
  ODOO_VER=$1
  IFS='.' read -ra ODOO_VER_S <<< "$ODOO_VER"

  sed -i "s/\(ODOO_MAJOR *= *\).*/\1${ODOO_VER_S[0]}/" .env
  sed -i "s/\(ODOO_MINOR *= *\).*/\1$ODOO_VER/" .env
  if [ $(echo "$ODOO_VER < 9.0" | bc) -eq 1 ] ; then
    sed -i "s/\(- --dev=*\).*/ /" devel.yaml
  elif [ $ODOO_VER = "9.0" ]; then
    sed -i "s/\(- --dev*\).*/\1 /" devel.yaml
  fi

  if [ $(echo "$ODOO_VER > 12.0" | bc) -eq 1 ] ; then
    sed -i "s/\(DB_MAJOR *= *\).*/\112/" .env
  else
    sed -i "s/\(DB_MAJOR *= *\).*/\1${ODOO_VER_S[0]}/" .env
  fi
}

create_docker()
{
  PROJ_NAME=$1
  ODOO_VER=$(sanitize_odoo_version $2)

  if [ -z $PROJ_NAME ] || [ -z $ODOO_VER ]; then
    echo "ERROR: Invalid params!  Aborting."
    echo "Syntaxis: docker create <proj_name> <version>"
  else
    git clone https://github.com/Tecnativa/doodba-scaffolding.git $PROJ_NAME --depth=1
    cd $PROJ_NAME
    _prepare_docker_files $ODOO_VER
    echo -e "\nDocker created successfully."
  fi
}

# Code from https://github.com/Tecnativa/doodba#skip-the-boring-parts
build_docker()
{
  if [ ! -f "docker-compose.yml" ]; then
    ln -s devel.yaml docker-compose.yml
  fi
  chown -R $USER:1000 odoo/auto
  chmod -R ug+rwX odoo/auto
  export UID GID="$(id -g $USER)" UMASK="$(umask)"
  docker-compose build --pull
  docker-compose -f setup-devel.yaml run --rm odoo
  echo -e "\nDocker built successfully."
}

resync_modules()
{
  if [ -f "setup-devel.yaml" ]; then
    export UID GID="$(id -g $USER)" UMASK="$(umask)"
    docker-compose -f setup-devel.yaml run --rm odoo
    echo -e "\nModules resynced successfully."
  else
    echo "ERROR: Can't found setup-devel.yaml.  Aborting."
  fi
}

add_modules()
{
  if [ ! -f $PATH_REPOS ]; then
    echo "ERROR: Can't found repos.yaml.  Aborting."
    exit 1
  fi

  if [ ! -f $PATH_ADDONS ]; then
    echo "ERROR: Can't found addons.yaml.  Aborting."
    exit 1
  fi

  REPO=$1
  MODULES=$2

  if [ -z $REPO ]; then
    echo "ERROR: Invalid params!  Aborting."
    echo "Syntaxis: docker add_modules <repo> [modules (separated by comma without spaces)]"
  else
    IFS='/' read -ra REPO_ARR <<< "$REPO"
    IFS='.' read -ra REPO_NAME_ARR <<< "${REPO_ARR[-1]}"
    if grep -Fxq "./${REPO_NAME_ARR[0]}:" $PATH_REPOS; then
      echo "This repo already exists on repos.yaml.  Skipping."
    else
      if [[ $REPO =~ $REGEX_URL ]]; then
        cat <<EOF >> $PATH_REPOS
./${REPO_NAME_ARR[0]}:
    defaults:
        depth: \$DEPTH_DEFAULT
    remotes:
        $GIT_DEF_REMOTE: $REPO
    target:
        $GIT_DEF_REMOTE \$ODOO_VERSION
    merges:
        - $GIT_DEF_REMOTE \$ODOO_VERSION
EOF
      fi
    fi
    if grep -Fxq "${REPO_NAME_ARR[0]}:" $PATH_ADDONS; then
      if [ -z $MODULES ]; then
        echo "This repo already exists on addons.yaml.  Skipping."
      else
        IFS=',' read -ra MODULES_ARR <<< "$MODULES"
        for MODULE_NAME in "${MODULES_ARR[@]}"
        do
          sed -i "/${REPO_NAME_ARR[0]}:/a \ \ - ${MODULE_NAME}" $PATH_ADDONS
        done
      fi
    else
      echo "${REPO_NAME_ARR[0]}:" >> $PATH_ADDONS
      if [ -z $MODULES ]; then
        echo "  - \"*\"" >> $PATH_ADDONS
      else
        IFS=',' read -ra MODULES_ARR <<< "$MODULES"
        for MODULE_NAME in "${MODULES_ARR[@]}"
        do
          echo "  - $MODULE_NAME" >> $PATH_ADDONS
        done
      fi
    fi
    echo -e "\nModules added successfully."
  fi
}

del_modules()
{
  REPO_NAME=$1

  if grep -Fxq "./${REPO_NAME}:" $PATH_REPOS; then
    sed -i "/\.\/${REPO_NAME}:/,/^\./{//!d};/\.\/${REPO_NAME}:/d" $PATH_REPOS
  else
    echo "This repo is not present on repos.yaml.  Skipping."
  fi

  if grep -Fxq "${REPO_NAME}:" $PATH_ADDONS; then
    sed -i "/${REPO_NAME}:/, /^[^ ]/{//!d};/${REPO_NAME}:/d" $PATH_ADDONS
  else
    echo "This repo is not present on addons.yaml.  Skipping."
  fi

  echo -e "\nModules deleted successfully."
}

# Code from https://github.com/Tecnativa/doodba#run-unit-tests-for-some-addon
test_modules()
{
  MODULES=$1
  docker-compose run --rm odoo addons init -d -w $MODULES
  docker-compose run --rm odoo addons init -t -w $MODULES
  docker-compose run --rm odoo addons update -t -w $MODULES
  echo -e "\nTests launched successfully."
}

list_modules()
{
  REPO_NAME=$1

  if [ -z $REPO_NAME ]; then
    sed -i "/${REPO_NAME}:/, /^[^ ]/{//!d};/${REPO_NAME}:/d" $PATH_ADDONS
  fi
  sed -i "/${REPO_NAME}:/, /^[^ ]/{//!d};/${REPO_NAME}:/d" $PATH_ADDONS
}

install_modules()
{
  MODULES=$1
  docker-compose run --rm odoo odoo -i $MODULES --stop-after-init
}

update_modules()
{
  MODULES=$1
  docker-compose run --rm odoo odoo -u $MODULES --stop-after-init
}

run_shell()
{
  docker-compose run --rm odoo odoo shell
}

run_bash()
{
  docker-compose run --user root --rm -l traefik.enable=false odoo bash
}

run_psql()
{
  DB=$1
  if [ -z $DB ]; then
    DB="postgres"
  fi
  docker-compose run --rm odoo psql $DB
}

repair_folder()
{
  ODOO_VER=$(sanitize_odoo_version $1)
  CURDIR=$PWD
  CFNAME=$(basename $CURDIR)

  if [ -z $ODOO_VER ]; then
    echo "ERROR: Invalid params!  Aborting."
    echo "Syntaxis: docker repair <version>"
  else
    read -p "This will be erase all unstagged changes and database volume!! You want continue [y/N]? " USER_RESPONSE
    if [ "$USER_RESPONSE" = "y" ] || [ "$USER_RESPONSE" = "Y" ]; then
      echo "Removing volumes..."
      docker volume rm $CFNAME"_db" || true
      echo "Restoring base..."
      git checkout .
      git checkout $ODOO_VER
      echo "Restoring addons..."
      cd odoo/custom/src
      for file in */; do cd $file && git checkout . && cd ..; done
      echo "Building containers..."
      cd $CURDIR
      _prepare_docker_files $ODOO_VER
      build_docker
    else
      echo "Ok, action skiped!"
    fi
  fi
}
#== GIT

# Code from @simahawk: https://github.com/OCA/web/pull/1173#issuecomment-461885122
fix_history()
{
  MODULE=$1
  HASH=$2
  ODOO_VER=$(sanitize_odoo_version $3)
  ODOO_FROM_VER=$4

  if [ -z $ODOO_FROM_VER ]; then
    ODOO_FROM_VER=`expr $ODOO_VER - 1`
  else
    ODOO_FROM_VER=$(sanitize_odoo_version $ODOO_FROM_VER)
  fi

  if [ -z $ODOO_VER ]; then
    echo "ERROR: Invalid params!  Aborting."
    echo "Syntaxis: git fix-history <module> <hash> <version_to> [version_from]"
  else
    git fetch $GIT_DEF_REMOTE
    git reset --hard $GIT_DEF_REMOTE/$ODOO_VER
    git format-patch --keep-subject --stdout $GIT_DEF_REMOTE/$ODOO_VER..$GIT_DEF_REMOTE/$ODOO_FROM_VER -- $MODULE | git am -3 --keep
    git cherry-pick $HASH
    echo -e "\nModule git history fixed successfully."
  fi
}

fetch_pr()
{
  PRNUM=$1

  if [ -z $PRNUM ]; then
    echo "ERROR: Invalid params!  Aborting."
    echo "Syntaxis: git use_pr <pr_number>"
  else
    git fetch $GIT_DEF_REMOTE pull/$PRNUM/head:pr-$PRNUM
    git checkout pr-$PRNUM
  fi
}

mig_module()
{
  MODULE=$1
  ODOO_VER=$(sanitize_odoo_version $2)
  ODOO_FROM_VER=$(sanitize_odoo_version $3)
  GIT_FROM_REMOTE=$4

  echo $GIT_FROM_REMOTE

  if [ -z $ODOO_FROM_VER ]; then
    ODOO_FROM_VER=`expr $ODOO_VER - 1`
  fi
  if [ -z $GIT_FROM_REMOTE ]; then
    GIT_FROM_REMOTE=$GIT_DEF_REMOTE
  fi

  if [ -z $ODOO_VER ]; then
    echo "ERROR: Invalid params!  Aborting."
    echo "Syntaxis: git migrate <module> <version>"
  else
    git fetch $GIT_DEF_REMOTE
    git checkout -b $ODOO_VER-mig-$MODULE $GIT_DEF_REMOTE/$ODOO_VER
    git format-patch --keep-subject --stdout $GIT_DEF_REMOTE/$ODOO_VER..$GIT_FROM_REMOTE/$ODOO_FROM_VER -- $MODULE | git am -3 --keep
    echo -e "\nModule migration initialized successfully. Now can start the hard work!"
  fi
}

show_conflict_files()
{
  git diff --name-only --diff-filter=U
}

reset_branch()
{
  ORIGIN=$1
  BRANCH=$2

  if [ -z $BRANCH ]; then
    echo "ERROR: Invalid params!  Aborting."
    echo "Syntaxis: git reset_branch <branch>"
  else
    git fetch --all
    git reset --hard $ORIGIN/$BRANCH
  fi
}

show_log()
{
  git log --pretty=format:"%C(Yellow)%h%x09%C(Blue)%an%x09%Creset%s"
}


#== MAIN
TOOL=$1
ACTION=$2

if [ -z $TOOL ] || [ -z $ACTION ]; then
  echo "Invalid parameters!  Aborting."
  print_help
else
  ACTION_ERROR=0

  if [ "$TOOL" = "docker" ]; then
    if [ "$ACTION" = "create" ]; then
      create_docker $3 $4
    elif [ "$ACTION" = "build" ]; then
      build_docker
    elif [ "$ACTION" = "add_modules" ]; then
      add_modules $3 $4
    elif [ "$ACTION" = "del_modules" ]; then
      del_modules $3
    elif [ "$ACTION" = "resync_modules" ]; then
      resync_modules
    elif [ "$ACTION" = "test_modules" ]; then
      test_modules $3
    elif [ "$ACTION" = "install_modules" ]; then
      install_modules $3
    elif [ "$ACTION" = "update_modules" ]; then
      update_modules $3
    elif [ "$ACTION" = "shell" ]; then
      run_shell
    elif [ "$ACTION" = "bash" ]; then
      run_bash
    elif [ "$ACTION" = "psql" ]; then
      run_psql $3
    elif [ "$ACTION" = "repair" ]; then
      repair_folder $3
    else
      ACTION_ERROR=1
    fi
  elif [ "$TOOL" = "git" ]; then
    if [ "$ACTION" = "migrate" ]; then
      mig_module $3 $4 $5 $6
    elif [ "$ACTION" = "use_pr" ]; then
      fetch_pr $3
    elif [ "$ACTION" = "fix_history" ]; then
      fix_history $3 $4 $5 $6
    elif [ "$ACTION" = "show_conflict_files" ]; then
      show_conflict_files
    elif [ "$ACTION" = "reset_branch" ]; then
      reset_branch $3 $4
    elif [ "$ACTION" = "log" ]; then
      show_log
    else
      ACTION_ERROR=1
    fi
  else
    echo "Invalid '$TOOL' Tool!  Aborting."
    print_help
  fi

  if [ $ACTION_ERROR -eq 1 ]; then
    echo "Invalid '$ACTION' Action!  Aborting."
    print_help
  fi
fi
