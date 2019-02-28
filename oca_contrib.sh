#!/usr/bin/sh
##########################################################
# OCA Contrib
# 'Copyright' 2019 Alexandre Díaz - <dev@redneboa.es>
#
# This script is powered by:
# - Doodba by Tecnativa - https://github.com/Tecnativa/doodba
# - OCA Mantainer Tools Wiki's - https://github.com/OCA/maintainer-tools/wiki/
#
# License GPL-3.0 or later (http://www.gnu.org/licenses/gpl).
##########################################################

GIT_DEF_REMOTE="origin"
REGEX_NUMBER='^[0-9]+$'

print_help()
{
  echo -e "\nUsage: $0 <tool> <action> [options]"
  echo "Available Tools & Actions:"
  echo "  - docker"
  echo "    · create <proj_name> <version>"
  echo "    · add_modules <repo> [modules (separated by comma without spaces)]"
  echo "    · del_modules <repo>"
  echo "    · resync_modules"
  echo "    · test_modules <modules (separated by comma without spaces)>"
  echo "  - git"
  echo "    · migrate <module> <version>"
  echo "    · fix-history <module> <version> <hash>"
  echo "Example: $0 docker create my_project 12"

}

#== DOCKER

# Code from https://github.com/Tecnativa/doodba#skip-the-boring-parts
create_docker()
{
  PROJ_NAME=$1
  ODOO_VER=$2


  if [ -z $PROJ_NAME ] || [ -z $ODOO_VER ]; then
    echo "ERROR: Invalid params!  Aborting."
    echo "Syntaxis: docker create <proj_name> <version>"
  elif ! [[ $ODOO_VER =~ $REGEX_NUMBER ]]; then
    echo "Invalid Odoo Version.  Aborting."
    echo "TIP: Pay attention that the script doesn't use x.0 version notation. If you want 11.0 type 11 (without .0 sufix)"
  else
    git clone https://github.com/Tecnativa/doodba-scaffolding.git $PROJ_NAME --depth=1 &&
    cd $PROJ_NAME &&
    sed -i "s/\(ODOO_MAJOR *= *\).*/\1$ODOO_VER/" .env &&
    sed -i "s/\(ODOO_MINOR *= *\).*/\1$ODOO_VER.0/" .env &&
    ln -s devel.yaml docker-compose.yml &&
    chown -R $USER:1000 odoo/auto &&
    chmod -R ug+rwX odoo/auto &&
    export UID GID="$(id -g $USER)" UMASK="$(umask)" &&
    docker-compose build --pull &&
    docker-compose -f setup-devel.yaml run --rm odoo &&
    echo -e "\nDocker created successfully."
  fi
}

resync_modules()
{
  if [ -f "setup-devel.yaml" ]; then
    export UID GID="$(id -g $USER)" UMASK="$(umask)" &&
    docker-compose -f setup-devel.yaml run --rm odoo &&
    echo -e "\nModules resynced successfully."
  else
    echo "ERROR: Can't found setup-devel.yaml.  Aborting."
  fi
}

add_modules()
{
  if [ ! -f "src/repos.yaml" ]; then
    echo "ERROR: Can't found repos.yaml.  Aborting."
    exit 1
  fi

  if [ ! -f "src/addons.yaml" ]; then
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
    if grep -Fxq "./${REPO_NAME_ARR[0]}:" src/repos.yaml; then
      echo "This repo already exists.  Aborting."
      exit 1
    else
      cat <<EOT >> src/repos.yaml
./${REPO_NAME_ARR[0]}:
    defaults:
        depth: \$DEPTH_DEFAULT
    remotes:
        $GIT_DEF_REMOTE: $REPO
    target:
        $GIT_DEF_REMOTE \$ODOO_VERSION
    merges:
        - $GIT_DEF_REMOTE \$ODOO_VERSION
EOT
      echo "${REPO_NAME_ARR[0]}:" >> src/addons.yaml
      if [ -z $MODULES ]; then
        echo "  - \"*\"" >> src/addons.yaml
      else
        IFS=',' read -ra MODULES_ARR <<< "$MODULES"
        for MODULE_NAME in "${MODULES_ARR[@]}"
        do
          echo "  - \"$MODULE_NAME\"" >> src/addons.yaml
        done
      fi
      echo -e "\nModules added successfully."
    fi
  fi
}

del_modules()
{
  REPO=$1

  IFS='/' read -ra REPO_ARR <<< "$REPO"
  IFS='.' read -ra REPO_NAME_ARR <<< "${REPO_ARR[-1]}"
  if grep -Fxq "./${REPO_NAME_ARR[0]}:" src/repos.yaml; then
    echo "This repo is not present on repos.yaml.  Aborting."
    exit 1
  else
    sed -n "/^\.\/$REPO_NAME_ARR[0]:(?:\s\s.|.)*$/!p" src/repos.yaml &&
    sed -n "/^$REPO_NAME_ARR[0]:(?:\s\s.|.)*$/!p" src/addons.yaml &&
    echo -e "\nModules deleted successfully."
  fi
}

# Code from https://github.com/Tecnativa/doodba#run-unit-tests-for-some-addon
test_modules()
{
  MODULES=$1
  docker-compose run --rm odoo odoo --stop-after-init --init $MODULES &&
  docker-compose run --rm odoo unittest $MODULES &&
  echo -e "\nTests launched successfully."
}


#== GIT

# Code from @simahawk: https://github.com/OCA/web/pull/1173#issuecomment-461885122
fix_history()
{
  MODULE=$1
  ODOO_VER=$2
  HASH=$3
  ODOO_FROM_VER=`expr $ODOO_VER - 1`

  if [ -z $MODULE ] || [ -z $ODOO_VER ] || [ -z $HASH ]; then
    echo "ERROR: Invalid params!  Aborting."
    echo "Syntaxis: git fix-history <module> <version> <hash>"
  elif ! [[ $ODOO_VER =~ $REGEX_NUMBER ]]; then
    echo "Invalid Odoo Version.  Aborting."
    echo "TIP: Pay attention that the script doesn't use x.0 version notation. If you want 11.0 type 11 (without .0 sufix)"
  else
    git fetch $GIT_DEF_REMOTE &&
    git reset --hard $GIT_DEF_REMOTE/$ODOO_VER.0 &&
    git format-patch --keep-subject --stdout $GIT_DEF_REMOTE/$ODOO_VER.0..$GIT_DEF_REMOTE/$ODOO_FROM_VER.0 -- $MODULE | git am -3 --keep &&
    git cherry-pick $HASH &&
    echo -e "\nModule git history fixed successfully."
  fi
}

mig_module()
{
  MODULE=$1
  ODOO_VER=$2
  ODOO_FROM_VER=`expr $ODOO_VER - 1`

  if [ -z $MODULE ] || [ -z $ODOO_VER ]; then
    echo "ERROR: Invalid params!  Aborting."
    echo "Syntaxis: git migrate <module> <version>"
  elif ! [[ $ODOO_VER =~ $REGEX_NUMBER ]]; then
    echo "Invalid Odoo Version.  Aborting."
    echo "TIP: Pay attention that the script doesn't use x.0 version notation. If you want 11.0 type 11 (without .0 sufix)"
  else
    git fetch $GIT_DEF_REMOTE &&
    git checkout -b $ODOO_VER.0-mig-$MODULE $GIT_DEF_REMOTE/$ODOO_VER.0 &&
    git format-patch --keep-subject --stdout $GIT_DEF_REMOTE/$ODOO_VER.0..$GIT_DEF_REMOTE/$ODOO_FROM_VER.0 -- $MODULE | git am -3 --keep &&
    echo -e "\nModule migration initialized successfully. Now can start the hard work!"
  fi
}


#== MAIN
TOOL=$1
ACTION=$2

if [ -z $TOOL ] || [ -z $ACTION ]; then
  echo "Invalid parameters!  Aborting."
  print_help
fi

ACTION_ERROR=0

if [ "$TOOL" = "docker" ]; then
  if [ "$ACTION" = "create" ]; then
    create_docker $3 $4
  elif [ "$ACTION" = "add_modules" ]; then
    add_modules $3 $4
  elif [ "$ACTION" = "del_modules" ]; then
    del_modules $3 $4
  elif [ "$ACTION" = "resync_modules" ]; then
    resync_modules
  elif [ "$ACTION" = "test_modules" ]; then
    test_modules $3
  else
    ACTION_ERROR=1
  fi
elif [ "$TOOL" = "git" ]; then
  if [ "$ACTION" = "migrate" ]; then
    mig_module $3 $4
  elif [ "$ACTION" = "fix-history" ]; then
    fix_history $3 $4 $5
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
