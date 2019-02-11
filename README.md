# OCA CONTRIB Shell Script
This is a simple tool for development envirionments focused to avoid repetitive tasks.
You can see it like a recopilation of usefull snippets.

**This is NOT an official OCA tool**

The script uses awesome Odoo projects!
- Doodba by Tecnactiva
- OCA Mantainer Tools Wiki

**/!\ This script can be dangerous if you don't know what you're doing!**

## INSTALLATION
```
$ wget https://raw.github.com/Tardo/oca_contrib/oca_contrib.sh -o /usr/local/bin/oca_contrib && chmod +x /usr/local/bin/oca_contrib
```

## USAGE

#### + DOCKER MANAGEMENT (DOODBA)
For more information see https://github.com/Tecnativa/doodba
###### Create
Create a odoo docker in devel mode

```$ oca_contrib docker create <proj_name> <version>```
- proj_name > The name of the project
- version > The Odoo version to use (avoid .0)

** Example, create myproject using Odoo 10.0:

```$ oca_contrib docker create myproject 10```

###### Add Modules
Add repository and enable modules to be installed. _Run this command inside the docker project folder._

```$ oca_contrib docker add_modules <repo> [modules (separated by comma without spaces)]```
- repo > Git repository
- modules > _Optional_. A list of module names to enable separated by comma

** Example, add OCA/web repository with web_responsive and web_widget_color

```$ oca_contrib docker add_modules https://github.com/OCA/web.git web_responsive,web_widget_color```

*** Example, add OCA/l10n-spain repository with all modules

```$ oca_contrib docker add_modules https://github.com/OCA/l10n-spain.git```

###### Resync Modules
Re-launch git_aggregator. _Run this command inside the docker project folder._

**/!\ This command can be dangerous!**

```$ oca_contrib docker resync_modules```

#### + GIT MANAGEMENT
For more information see https://github.com/OCA/maintainer-tools/wiki
###### Migrate
Preapare a new branch to start a migration of a module. _Run this command inside the repository folder._

```$ oca_contrib git migrate <module> <version>```
- module > Module names
- version > Odoo version (avoid .0)

*** Example, migrate web_shortcut to v11.0.

```$ oca_contrib git migrate web_shortcut 11```

###### Fix History
Restore git commits history on migration module. **Only usefull if you missed it.** _Run this command inside the repository folder. Using the branch to fix._

**/!\ This command can be dangerous!**

```$ oca_contrib git fix_history <module> <version> <hash>```
- module > Module name
- version > Odoo version (avoid .0)
- hash > Hash of commit to restore your work

To use this you need squash your commits first and get the hash of these commit.

** Example, restore history to web_shortcut migration. Previously squashed in 1234abc567de

```$ oca_contrib git fix_history web_shortcut 11 1234abc567de```
