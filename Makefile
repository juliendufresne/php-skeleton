# do more actions on some target when the DEBUG var is set to true
DEBUG := false

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
	@echo ""
	@echo "\033[33m Install commands:\033[39m"
	@echo "\033[32m   clean            \033[39m   Clean everything generated by the application"
	@echo "\033[32m   install          \033[39m   Install everything needed to run this application"
	@echo ""
	@echo "\033[33m Meta commands:\033[39m"
	@echo "\033[32m   push             \033[39m   Run all checks and tests"

###> install commands ###
.PHONY: clean install
clean:
	@rm -f .env
	@rm -rf var vendor

install: .env
ifeq ($(DEBUG), true)
	@$(MAKE) -s clean
	@$(MAKE) -s .env
endif
	@$(MAKE) -s composer-install

.env: .env.dist
	@cp $< $@
###< install commands ###

###> meta ###
.PHONY: push

push: composer-validate
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
###< meta ###

###> composer commands ###
.PHONY: composer-*

composer-install:
	@echo "\n\033[33m    composer install --no-progress --prefer-dist --no-suggest\033[39m\n"
	@                    composer install --no-progress --prefer-dist --no-suggest

composer-outdated:
	@echo "\n\033[33m    composer outdated\033[39m\n"
	@                    composer outdated

composer-update:
	@echo "\n\033[33m    composer update\033[39m\n"
	@                    composer update

composer-validate:
	@echo "\n\033[33m    composer validate\033[39m\n"
	@                    composer validate
###< composer commands ###