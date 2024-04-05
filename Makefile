# This Makefile requires GNU Make.
MAKEFLAGS += --silent

# Settings
C_BLU='\033[0;34m'
C_GRN='\033[0;32m'
C_RED='\033[0;31m'
C_YEL='\033[0;33m'
C_END='\033[0m'

include .env

DOCKER_TITLE=$(PROJECT_TITLE)

CURRENT_DIR=$(patsubst %/,%,$(dir $(realpath $(firstword $(MAKEFILE_LIST)))))
DIR_BASENAME=$(shell basename $(CURRENT_DIR))
ROOT_DIR=$(CURRENT_DIR)

help: ## shows this Makefile help message
	echo 'usage: make [target]'
	echo
	echo 'targets:'
	egrep '^(.+)\:\ ##\ (.+)' ${MAKEFILE_LIST} | column -t -c 2 -s ':#'

# -------------------------------------------------------------------------------------------------
#  System
# -------------------------------------------------------------------------------------------------
.PHONY: hostname fix-permission host-check

hostname: ## shows local machine ip
	echo $(word 1,$(shell hostname -I))

fix-permission: ## sets project directory permission
	$(DOCKER_USER) chown -R ${USER}: $(ROOT_DIR)/

host-check: ## shows this project ports availability on local machine
	cd docker/nginx-php && $(MAKE) port-check

# -------------------------------------------------------------------------------------------------
#  Drupal Service
# -------------------------------------------------------------------------------------------------
.PHONY: drupal-ssh drupal-set drupal-build drupal-start drupal-stop drupal-destroy

drupal-ssh: ## enters the Drupal container shell
	cd docker/nginx-php && $(MAKE) ssh

drupal-set: ## sets the Drupal PHP enviroment file to build the container
	cd docker/nginx-php && $(MAKE) env-set

drupal-build: ## builds the Drupal PHP container from Docker image
	cd docker/nginx-php && $(MAKE) build

drupal-start: ## starts up the Drupal PHP container running
	cd docker/nginx-php && $(MAKE) start

drupal-stop: ## stops the Drupal PHP container but data won't be destroyed
	cd docker/nginx-php && $(MAKE) stop

drupal-destroy: ## removes the Drupal PHP from Docker network destroying its data and Docker image
	cd docker/nginx-php && $(MAKE) clear destroy

drupal-install: ## installs set version of Laravel into container
	cd docker/nginx-php && $(MAKE) app-install

drupal-update: ## updates set version of Laravel into container
	cd docker/nginx-php && $(MAKE) app-update

# -------------------------------------------------------------------------------------------------
#  Database Container Service
# -------------------------------------------------------------------------------------------------
.PHONY: database-install database-replace database-backup

database-install: ## installs into container database the init sql file from resources/database
	sudo docker exec -i $(DB_CAAS) sh -c 'exec mysql $(DB_NAME) -uroot -p"$(DB_ROOT)"' < $(DB_BACKUP_PATH)/$(DB_BACKUP_NAME)-init.sql
	echo ${C_YEL}"DATABASE"${C_END}" has been installed."

database-replace: ## replaces container database with the latest sql backup file from resources/database
	sudo docker exec -i $(DB_CAAS) sh -c 'exec mysql $(DB_NAME) -uroot -p"$(DB_ROOT)"' < $(DB_BACKUP_PATH)/$(DB_BACKUP_NAME)-backup.sql
	echo ${C_YEL}"DATABASE"${C_END}" has been replaced."

database-backup: ## creates / replace a sql backup file from container database in resources/database
	sudo docker exec $(DB_CAAS) sh -c 'exec mysqldump $(DB_NAME) -uroot -p"$(DB_ROOT)"' > $(DB_BACKUP_PATH)/$(DB_BACKUP_NAME)-backup.sql
	echo ${C_YEL}"DATABASE"${C_END}" backup has been created."

# -------------------------------------------------------------------------------------------------
#  Repository Helper
# -------------------------------------------------------------------------------------------------
repo-flush: ## clears local git repository cache specially to update .gitignore
	git rm -rf --cached .
	git add .
	git commit -m "fix: cache cleared for untracked files"
