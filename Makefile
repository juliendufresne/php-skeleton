# do more actions on some target when the DEBUG var is set to true
DEBUG := false
# for checks and tests commands, we'll do our best to run those on modified files only
FAST := true
ifeq ($(DEBUG), true)
FAST := false
endif

ifeq ($(FAST), true)
PHP_FILES_CHANGED := $(shell bin/ls_changed_files --ext=.php src tests)
endif

HAS_BEHAT := false
ifneq ("$(wildcard vendor/bin/behat)","")
HAS_BEHAT := true
endif

HAS_TWIG := false
ifneq ("$(wildcard vendor/symfony/twig-bridge)","")
ifneq ("$(wildcard templates)","")
HAS_TWIG := true
endif
endif

DOCKERFILES := .provision/elasticsearch/Dockerfile \
               .provision/kibana/Dockerfile \
               .provision/mariadb/Dockerfile \
               .provision/php/Dockerfile \
               .provision/rabbitmq/Dockerfile

help:
	@echo "\033[33m Usage:\033[39m"
	@echo "  make COMMAND"
	@echo ""
	@echo "\033[33m Options:\033[39m"
	@echo "   Options can be passed to the make command like this:"
	@echo "       make DEBUG=true <command>"
	@echo ""
	@echo "\033[32m   DEBUG=true       \033[39m   In case the command you are running did not fix your"
	@echo "                       issue, this option will do more actions"
	@echo "\033[32m   FAST=false       \033[39m   For checks and tests commands, we'll do our best to run"
	@echo "                       those on modified files only. Putting FAST to false will"
	@echo "                       disable this behavior and run those commands on all files"
	@echo ""
	@echo "\033[33m Install commands:\033[39m"
	@echo "\033[32m   clean            \033[39m   Clean everything generated by the application"
	@echo "\033[32m   install          \033[39m   Install everything needed to run this application"
	@echo ""
	@echo "\033[33m Meta commands:\033[39m"
	@echo "\033[32m   push             \033[39m   Run all checks and tests"
	@echo "\033[32m   lint             \033[39m   Run all linters"
	@echo ""
	@echo "\033[33m Checks commands:\033[39m"
	@echo "\033[32m   lint-php         \033[39m   Checks PHP files syntax"
ifeq ($(HAS_TWIG), true)
	@echo "\033[32m   lint-twig        \033[39m   Checks twig files syntax"
endif
	@echo "\033[32m   lint-yaml        \033[39m   Checks yaml files syntax"
	@echo "\033[32m   php-cs-fixer     \033[39m   Fix code style in php files"
	@echo "\033[32m   phpstan          \033[39m   Find bugs in the code"
	@echo ""
	@echo "\033[33m Tests commands:\033[39m"
ifeq ($(HAS_BEHAT), true)
	@echo "\033[32m   behat            \033[39m   Run behat tests"
endif
	@echo "\033[32m   phpunit          \033[39m   Run phpunit tests"
	@echo "\033[32m   phpunit-coverage \033[39m   Run phpunit tests with code coverage"

###> install commands ###
.PHONY: clean install
clean:
	@[ -f docker-compose.yml ] && { docker-compose down; docker volume prune --force; } || true
	@rm -f .env docker-compose.yml $(DOCKERFILES)
	@rm -rf reports var vendor

install:
ifeq ($(DEBUG), true)
	@$(MAKE) -s clean
endif
	@$(MAKE) -s .env docker-compose.yml $(DOCKERFILES)
	@docker-compose build
	@docker-compose up --build -d
	@$(MAKE) -s composer-install

.env: .env.dist
	@cp $< $@

docker-compose.yml: docker-compose.yml.dist
	@cp $< $@

.provision/%/Dockerfile: .provision/%/Dockerfile.dist
	@sed -e "s/{USER_ID}/$(shell id -u)/g" -e "s/{GROUP_ID}/$(shell id -g)/g" $< > $@

###< install commands ###

###> meta ###
.PHONY: lint push

# priority matters: faster script should be run first for faster feedback
push: composer-validate lint php-cs-fixer-check phpstan phpunit behat
# $(make push) should print a warning message if the thing we are about to push is not the same thing the command has tested.
	@echo ""
	@echo "  \033[97;44m                                                                              \033[39;49m"
	@echo "  \033[97;44m    [OK] No errors found.                                                     \033[39;49m"
	@echo "  \033[97;44m                                                                              \033[39;49m"
	@echo ""
	@echo ""
ifeq ($(shell git status --porcelain),)
	@echo ""
	@echo "  \033[97;44m                                                                              \033[39;49m"
	@echo "  \033[97;44m    You may push your changes.                                                \033[39;49m"
	@echo "  \033[97;44m                                                                              \033[39;49m"
	@echo ""
else
	@echo "  \033[97;43m                                                                              \033[39;49m"
	@echo "  \033[97;43m    Your git working tree is not empty.                                       \033[39;49m"
	@echo "  \033[97;43m    This means the 'make push' command possibly runs on files that are not    \033[39;49m"
	@echo "  \033[97;43m    going to be part of your next 'git push' command.                         \033[39;49m"
	@echo "  \033[97;43m    Please consider commit/squash your changes and run this command again.    \033[39;49m"
	@echo "  \033[97;43m                                                                              \033[39;49m"
	@echo ""
endif

lint: lint-php lint-twig lint-yaml
###< meta ###

###> composer commands ###
.PHONY: composer-*

composer-install:
	@echo "\n\033[33m    docker-compose exec php composer install --no-progress --prefer-dist --no-suggest\033[39m\n"
	@                    docker-compose exec php composer install --no-progress --prefer-dist --no-suggest

composer-outdated:
	@echo "\n\033[33m    docker-compose exec php composer outdated\033[39m\n"
	@                    docker-compose exec php composer outdated

composer-update:
	@echo "\n\033[33m    docker-compose exec php composer update\033[39m\n"
	@                    docker-compose exec php composer update

composer-validate:
	@echo "\n\033[33m    docker-compose exec php composer validate\033[39m\n"
	@                    docker-compose exec php composer validate
###< composer commands ###

###> check commands ###
.PHONY: lint-* php-cs-fixer php-cs-fixer-check phpstan phpstan

ifeq ($(FAST), false)
lint-php:
	@echo "\n\033[33m    docker-compose exec php php vendor/bin/parallel-lint --exclude var --exclude vendor .\033[39m\n"
	@                    docker-compose exec php php vendor/bin/parallel-lint --exclude var --exclude vendor .
else ifneq ($(PHP_FILES_CHANGED),)
lint-php:
	@echo "\n\033[33m    docker-compose exec php php vendor/bin/parallel-lint $(PHP_FILES_CHANGED)\033[39m\n"
	@                    docker-compose exec php php vendor/bin/parallel-lint $(PHP_FILES_CHANGED)
else
lint-php:
	@echo "You have made no change in PHP files compared to master"
endif

lint-twig:
ifeq ($(HAS_TWIG), true)
	@echo "\n\033[33m    docker-compose exec php php bin/console lint:twig templates\033[39m\n"
	@                    docker-compose exec php php bin/console lint:twig templates
endif

lint-yaml:
	@echo "\n\033[33m    docker-compose exec php php bin/console lint:yaml config\033[39m\n"
	@                    docker-compose exec php php bin/console lint:yaml config

ifeq ($(FAST), false)
php-cs-fixer:
	@echo "\n\033[33m    docker-compose exec php php vendor/bin/php-cs-fixer fix -vvv\033[39m\n"
	@                    docker-compose exec php php vendor/bin/php-cs-fixer fix -vvv
else ifneq ($(PHP_FILES_CHANGED),)
php-cs-fixer:
	@echo "\n\033[33m    docker-compose exec php php vendor/bin/php-cs-fixer fix -vvv --config=.php_cs.dist --path-mode=intersection $(PHP_FILES_CHANGED)\033[39m\n"
	@                    docker-compose exec php php vendor/bin/php-cs-fixer fix -vvv --config=.php_cs.dist --path-mode=intersection $(PHP_FILES_CHANGED)
else
php-cs-fixer:
	@echo "You have made no change in PHP files compared to master"
endif

ifeq ($(FAST), false)
php-cs-fixer-check:
	@echo "\n\033[33m    docker-compose exec php php vendor/bin/php-cs-fixer fix -vvv --dry-run\033[39m\n"
	@                    docker-compose exec php php vendor/bin/php-cs-fixer fix -vvv --dry-run
else ifneq ($(PHP_FILES_CHANGED),)
php-cs-fixer-check:
	@echo "\n\033[33m    docker-compose exec php php vendor/bin/php-cs-fixer fix -vvv --dry-run --config=.php_cs.dist --path-mode=intersection $(PHP_FILES_CHANGED)\033[39m\n"
	@                    docker-compose exec php php vendor/bin/php-cs-fixer fix -vvv --dry-run --config=.php_cs.dist --path-mode=intersection $(PHP_FILES_CHANGED)
else
php-cs-fixer-check:
	@echo "You have made no change in PHP files compared to master"
endif


ifeq ($(FAST), false)
phpstan:
	@echo "\n\033[33m    docker-compose exec php php vendor/bin/phpstan analyse --no-progress --autoload-file=vendor/autoload.php --level=7 src tests\033[39m\n"
	@                    docker-compose exec php php vendor/bin/phpstan analyse --no-progress --autoload-file=vendor/autoload.php --level=7 src tests
else ifneq ($(PHP_FILES_CHANGED),)
phpstan:
	@echo "\n\033[33m    docker-compose exec php php vendor/bin/phpstan analyse --no-progress --autoload-file=vendor/autoload.php --level=7 $(PHP_FILES_CHANGED)\033[39m\n"
	@                    docker-compose exec php php vendor/bin/phpstan analyse --no-progress --autoload-file=vendor/autoload.php --level=7 $(PHP_FILES_CHANGED)
else
phpstan:
	@echo "You have made no change in PHP files compared to master"
endif
###< check commands ###

###> tests commands ###
.PHONY: behat phpunit phpunit-coverage

behat:
ifeq ($(HAS_BEHAT), true)
	@echo "\n\033[33m    docker-compose exec php php vendor/bin/behat -v\033[39m\n"
	@                    docker-compose exec php php vendor/bin/behat -v
endif

phpunit:
	@echo "\n\033[33m    SYMFONY_PHPUNIT_VERSION=6.5 docker-compose exec php php vendor/bin/simple-phpunit\033[39m\n"
	@                    SYMFONY_PHPUNIT_VERSION=6.5 docker-compose exec php php vendor/bin/simple-phpunit

phpunit-coverage:
	@echo "\n\033[33m    SYMFONY_PHPUNIT_VERSION=6.5 docker-compose exec php php -dzend_extension=xdebug.so vendor/bin/simple-phpunit --coverage-html reports/coverage --coverage-clover reports/clover.xml\033[39m\n"
	@                    SYMFONY_PHPUNIT_VERSION=6.5 docker-compose exec php php -dzend_extension=xdebug.so vendor/bin/simple-phpunit --coverage-html reports/coverage --coverage-clover reports/clover.xml
###< tests commands ###
