FIG=docker-compose
NAME=todo
RUN=$(FIG) run --rm
SERVICE=web
SERVICE_DB=db
EXEC=$(FIG) exec
BACKUP_SQL=backup.sql
TMP_SQL=tmp.sql
MANAGE=python manage.py


.DEFAULT_GOAL := help
.PHONY: help start stop reset db test tu
.PHONY: build up tty db-migrate shell createsuperuser web/built

help:
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

##
## Project setup
##---------------------------------------------------------------------------

start:          ## Install and start the project
start: build up

restart:          ## Restart whole project
restart: down up

reset:          ## Reset the whole project
reset: stop start

tty:            ## Run django container in interactive mode
tty:
	$(RUN) /bin/bash

server:			## Run server maunaly
server:
	$(RUN) $(MANAGE)
shell:          ## Run django shell
shell:
	$(RUN) $(MANAGE) shell

dbshell:          ## Run django dbshell
dbshell:
	$(RUN) $(MANAGE) dbshell


##
## Command
##---------------------------------------------------------------------------

showcommand:	## show all personnal command
showcommand:
	$(RUN) $(MANAGE)

executecommand: ## usage: name=[command]
executecommand:
	$(RUN) $(SERVICE) $(MANAGE) $(name)

##
## Database
##---------------------------------------------------------------------------

db-migrate:     ## Migrate database schema to the latest available version
db-migrate:
	$(EXEC) $(SERVICE) $(MANAGE) migrate $(model)

db-diff:     ## Make migrations
db-diff:
	$(EXEC) $(SERVICE) $(MANAGE) makemigrations $(modelm)

db-populate:  ## Populate db
db-populate:
	$(EXEC) $(MANAGE) populate_db

db-delete:   ## delete all migrations files
db-delete:
	find . -path "*/migrations/*.py" -not -name "__init__.py" -delete

db-flush:
	$(RUN) $(MANAGE) flush --noinput

clean-pyc:	## Clean python cache
clean-pyc:
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	


##
## Internal rules
##---------------------------------------------------------------------------

build:
	$(FIG) build

up:	## Start project container
	$(FIG) up

down: ## Stop project container
	$(FIG) down

app:   ## make django app appname=[name]
app:
	$(EXEC) $(SERVICE) bash -c "cd apps && django-admin startapp $(appname)"

appermission:	## make django app with user right appname=[name]
appermission: app
	sudo chown -R ${USER}:${USER} ./apps/$(appname)

createsuperuser:	## Create Django super user
createsuperuser:
	$(EXEC) $(SERVICE) $(MANAGE) createsuperuser

project:	## Make django project with apps and data folders
project:
	$(RUN) $(SERVICE) django-admin startproject $(NAME) .
	mkdir apps
	sudo chown -R ${USER}:${USER} .

permissions:	## Give current user right on project
permissions:
	sudo chown -R ${USER}:${USER} ./$(NAME) ./apps

show-host:	## Allowed Host: Copy / Paste this line on init project 
show-host:
	@echo ALLOWED_HOSTS = [\"0.0.0.0\", \"127.0.0.0\", \"localhost\"]

db-dump:	## Make a database dump
db-dump:
	$(EXEC) $(SERVICE_DB) bash -c "pg_dumpall -U postgres > backup.sql"
	docker cp $(shell docker ps --no-trunc -aqf name=todo-rest-framework_db):/$(BACKUP_SQL) $(TMP_SQL)
	sed '/CREATE ROLE postgres;/d' ./$(TMP_SQL) > $(BACKUP_SQL)
	rm $(TMP_SQL)

force-clean:	## removes all images and containers
force-clean:
	docker container prune
	docker image prune
	docker rmi -f $(shell echo $(NAME) | tr A-Z a-z)_web postgres $(shell echo $(NAME) | tr A-Z a-z)_db
	docker ps
	docker ps -a
	docker images

force-restart:	## removes images and container, rebuild, and start project
force-restart: force-clean start

userproject: project permissions show-host
