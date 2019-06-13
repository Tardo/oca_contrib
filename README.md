# OCA CONTRIB Shell Script for BASH
This is a simple tool for development envirionments focused to avoid repetitive tasks.
You can see it like a recopilation of usefull snippets.

**This is NOT an official OCA tool**

The script uses awesome Odoo projects!
- Doodba by Tecnactiva
- OCA Mantainer Tools Wiki

**/!\ This script can be dangerous (for your local branch) if you don't know what you're doing!**

## SYSTEM DEPENDENCIES
- git
- docker _https://docs.docker.com/install/linux/linux-postinstall/_
- docker-compose

## INSTALLATION
```
$ sudo wget https://raw.githubusercontent.com/Tardo/oca_contrib/master/oca_contrib.sh -O /usr/local/bin/oca_contrib && sudo chmod +x /usr/local/bin/oca_contrib
```
If you don't want/can't use root privileges to install, only download and use it. The better option is use ```~/.local/bin``` folder... but some distros haven't set these folder into $PATH

## EXAMPLE USAGE
Odoo 12.0 + Add OCA/web repository (all modules enabled)
```
$ oca_contrib docker create myproject 12
$ cd myproject
$ oca_contrib docker add_modules https://github.com/OCA/web.git
$ oca_contrib docker build
$ docker-compose up
```

# DETAILED USAGE
_Pay attention that the script doesn't use x.0 version notation. If you want 11.0 type 11 (without .0 sufix)_

### + DOCKER MANAGEMENT (DOODBA)
For more information see https://github.com/Tecnativa/doodba
###### ⚫ Create
Download & prepare a generic doodba scaffolding

```$ oca_contrib docker create <proj_name> <version>```
- proj_name > The name of the project
- version > The Odoo version to use (avoid .0)

** Example, create myproject using Odoo 10.0:

```$ oca_contrib docker create myproject 10```

###### ⚫ Build
Build the docker (in devel mode). _Run this command inside the docker project folder._

```$ oca_contrib docker build```

###### ⚫ Add Modules
Add repository and enable modules to be installed. _Run this command inside the docker project folder._

```$ oca_contrib docker add_modules <repo> [modules (separated by comma without spaces)]```
- repo > Git repository
- modules > _Optional_. A list of module names to enable separated by comma

** Example, add OCA/web repository with web_responsive and web_widget_color

```$ oca_contrib docker add_modules https://github.com/OCA/web.git web_responsive,web_widget_color```

** Example, add OCA/l10n-spain repository with all modules

```$ oca_contrib docker add_modules https://github.com/OCA/l10n-spain.git```

###### ⚫ Delete Modules
Remove repository and modules from repos.yaml and addons.yaml. _Run this command inside the docker project folder._

```$ oca_contrib docker del_modules <repo_name>```

** Example, remove OCA/l10n-spain repository with all modules

```$ oca_contrib docker del_modules l10n-spain```

###### ⚫ Test Modules
Launch unittest of selected modules. _Run this command inside the docker project folder._

```$ oca_contrib docker test_modules <modules (separated by comma without spaces)>```

** Example, test web_responsive and web_notify modules

```$ oca_contrib docker test_modules web_responsive,web_notify```

###### ⚫ Resync Modules
Re-launch git_aggregator. _Run this command inside the docker project folder._

**/!\ This command can be dangerous!**

```$ oca_contrib docker resync_modules```

### + GIT MANAGEMENT
For more information see https://github.com/OCA/maintainer-tools/wiki
###### ⚫ Migrate
Preapare a new branch to start a migration of a module. _Run this command inside the repository folder._

```$ oca_contrib git migrate <module> <version_to> [version_from]```
- module > Module names
- version > Odoo version (avoid .0)

** Example, migrate web_shortcut to v11.0. (from v10.0)

```$ oca_contrib git migrate web_shortcut 11```

** Example, migrate web_shortcut to v12.0. (from v10.0)

```$ oca_contrib git migrate web_shortcut 12 10```

###### ⚫ Fix History
Restore git commits history on migration module. **Only usefull if you missed it.** _Run this command inside the repository folder. Using the branch to fix._

**/!\ This command can be dangerous!**

```$ oca_contrib git fix_history <module> <hash> <version_to> [version_from]```
- module > Module name
- version > Odoo version (avoid .0)
- hash > Hash of commit to restore your work

To use this you need squash your commits first and get the hash of these commit.

** Example, restore history to web_shortcut migration. Previously squashed in 1234abc567de

```$ oca_contrib git fix_history web_shortcut 1234abc567de 12 10```

** Perhaps needs resolve some conflicts to finish the operation.
