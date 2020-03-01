# OCA CONTRIB 0.7.0 - Shell Script for BASH
This is a simple tool for development environments focused to avoid repetitive tasks when work with docker (doodba scaffolding) and git.
You can see it like a recopilation of usefull snippets.

**This is NOT an official OCA tool**

The script uses awesome Odoo projects!
- Doodba by Tecnactiva
- OCA Mantainer Tools Wiki

**/!\ This script can be dangerous (for your local branch) if you don't know what you're doing!**

## SYSTEM DEPENDENCIES
- bash
- git
- docker _https://docs.docker.com/install/linux/linux-postinstall/_
- docker-compose

---

## INSTALLATION
```sh
sudo wget https://raw.githubusercontent.com/Tardo/oca_contrib/master/oca_contrib.sh -O /usr/local/bin/oca_contrib && sudo chmod +x /usr/local/bin/oca_contrib
```
If you don't want/can't use root privileges to install, only download and use it. The better option is use ```~/.local/bin``` folder... but some distros haven't set these folder into $PATH

---

## EXAMPLE USAGE
Odoo 12.0 + Add OCA/web repository (all modules enabled)
```sh
oca_contrib docker create myproject 12
cd myproject
oca_contrib docker add_modules web
oca_contrib docker build
docker-compose up
```

---

## Table of Parameters
- [Docker](#-docker-management-doodba) (Scaffolding & Docker operations)
  - [create](#-create)
  - [build](#-build)
  - [add_modules](#-add-modules)
  - [del_modules](#-delete-modules)
  - [test_modules](#-test-modules)
  - [resync_modules](#-resync-modules)
  - [install_modules](#-install-modules)
  - [update_modules](#-update-modules)
  - [shell](#-odoo-shell)
  - [bash](#-odoo-docker-bash)
  - [psql](#-db-docker-psql)
  - [repair](#-docker-repair-folder)
- [Git](#-git-management)
  - [migrate](#-migrate)
  - [use_pr](#-use-pr)
  - [fix_history](#-fix-history)
  - [show_conflict_files](#-show-conflicting-files)

---

## DETAILED USAGE
_Odoo version can be written using MAJOR.MINOR notation or only MAJOR (example: 12.0 or 12)_

### + DOCKER MANAGEMENT (DOODBA)
For more information see https://github.com/Tecnativa/doodba
##### ⚫ Create
Download & prepare a generic doodba scaffolding

```sh
oca_contrib docker create <proj_name> <version>
```
- proj_name > The name of the project
- version > The Odoo version to use

** Example, create myproject using Odoo 10.0:

```sh
oca_contrib docker create myproject 10
```

##### ⚫ Build
Build the docker (in devel mode). _Run this command inside the docker project folder._

```sh
oca_contrib docker build
```

##### ⚫ Add Modules
Add repository and enable modules to be installed. _Run this command inside the docker project folder._

```sh
oca_contrib docker add_modules <repo_url / OCA_repo_name> [modules (separated by comma without spaces)]
```
- repo > Git repository
- modules > _Optional_. A list of module names to enable separated by comma

** Example, add OCA/web repository with web_responsive and web_widget_color

```sh
oca_contrib docker add_modules web web_responsive,web_widget_color
```

** Example, add OCA/l10n-spain repository with all modules

```sh
oca_contrib docker add_modules l10n-spain
```

** Example, add Tardo/web repository with all modules

```sh
oca_contrib docker add_modules https://github.com/Tardo/web.git
```

##### ⚫ Delete Modules
Remove repository and modules from repos.yaml and addons.yaml. _Run this command inside the docker project folder._

```sh
oca_contrib docker del_modules <repo_name>
```

** Example, remove OCA/l10n-spain repository with all modules

```sh
oca_contrib docker del_modules l10n-spain
```

##### ⚫ Test Modules
Launch unittest of selected modules. _Run this command inside the docker project folder._

```sh
oca_contrib docker test_modules <modules (separated by comma without spaces)>
```

** Example, test web_responsive and web_notify modules

```sh
oca_contrib docker test_modules web_responsive,web_notify
```

##### ⚫ Resync Modules
Re-launch git_aggregator. _Run this command inside the docker project folder._

**/!\ This command can be dangerous!**

```sh
oca_contrib docker resync_modules
```

##### ⚫ Install Modules
Install Odoo modules. _Run this command inside the docker project folder._

```sh
oca_contrib docker install_modules <modules (separated by comma without spaces)>
```

##### ⚫ Update Modules
Update Odoo modules. _Run this command inside the docker project folder._

```sh
oca_contrib docker update_modules <modules (separated by comma without spaces)>
```

##### ⚫ Odoo Shell
Run Odoo shell. _Run this command inside the docker project folder._

```sh
oca_contrib docker shell
```

##### ⚫ Odoo Docker Bash
Run Odoo Docker bash. _Run this command inside the docker project folder._

```sh
oca_contrib docker bash
```

##### ⚫ DB Docker psql
Run docker bash. _Run this command inside the docker project folder._

```sh
oca_contrib docker psql [database]
```
- database > _Optional_. Postgres Database (By default is 'postgres')

Example for devel:
```sh
oca_contrib docker psql devel
```

##### ⚫ Docker Repair Folder
Restore docker to have a clean folder to rebuild. _Run this command inside the docker project folder._

**/!\ This command can be dangerous!**

```sh
oca_contrib docker repair <version>
```
- version > The Odoo version to use

Example to restore a docker folder to rebuild it with version 12.0:
```sh
oca_contrib docker repair 12.0
```

### + GIT MANAGEMENT
For more information see https://github.com/OCA/maintainer-tools/wiki
##### ⚫ Migrate
Preapare a new branch to start a migration of a module. _Run this command inside the repository folder._

```sh
oca_contrib git migrate <module> <version_to> [version_from]
```
- module > Module names
- version > Odoo version (avoid .0)

** Example, migrate web_shortcut to v11.0. (from v10.0)

```sh
oca_contrib git migrate web_shortcut 11
```

** Example, migrate web_shortcut to v12.0. (from v10.0)

```sh
oca_contrib git migrate web_shortcut 12 10
```

##### ⚫ Use PR
Fetch a pull request to new branch and use it

```sh
oca_contrib git use_pr <pr_number>
```
- pr_number > Pull request ID

** Example, use pull request with id 283

```sh
oca_contrib git use_pr 283
```

##### ⚫ Fix History
Restore git commits history on migration module. **Only usefull if you missed it.** _Run this command inside the repository folder. Using the branch to fix._

**/!\ This command can be dangerous!**

```sh
oca_contrib git fix_history <module> <hash> <version_to> [version_from]
```
- module > Module name
- version > Odoo version (avoid .0)
- hash > Hash of commit to restore your work

To use this you need squash your commits first and get the hash of these commit.

** Example, restore history to web_shortcut migration. Previously squashed in 1234abc567de

```sh
oca_contrib git fix_history web_shortcut 1234abc567de 12 10
```

** Perhaps needs resolve some conflicts to finish the operation.

##### ⚫ Show Conflicting Files
Show files with conflicts in a merge/rebase operation. _Run this command inside the repository folder._

```sh
oca_contrib git show_conflict_files
```

---

## ROADMAP

* **MOVE TO PYTHON!!**
* Improve modules management
* Add dependencies management
* Enable/Disable docker network visibility
* Enable/Disable internal network

---

## KNOWN ISSUES

* Can't detect wildcard on addons.yaml when add modules
* Can't select modules to delete
