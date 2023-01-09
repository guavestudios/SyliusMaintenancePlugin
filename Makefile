.DEFAULT_GOAL := help
SHELL=/bin/bash
COMPOSER_ROOT=composer
TEST_DIRECTORY=tests/Application
CONSOLE=cd tests/Application && php bin/console
COMPOSER=cd tests/Application && composer
YARN=cd tests/Application && yarn

SYLIUS_VERSION=1.12.0
SYMFONY_VERSION=6.1
PHP_VERSION=8.1
PLUGIN_NAME=synolia/sylius-maintenance-plugin

###
### DEVELOPMENT
### ¯¯¯¯¯¯¯¯¯¯¯

install: sylius ## Install Plugin on Sylius [SYLIUS_VERSION=1.12.0] [SYMFONY_VERSION=6.1] [PHP_VERSION=8.1]
.PHONY: install

reset: ## Remove dependencies
	rm -rf tests/Application
.PHONY: reset

phpunit: phpunit-configure phpunit-run ## Run PHPUnit
.PHONY: phpunit

###
### OTHER
### ¯¯¯¯¯¯

sylius: sylius-standard update-dependencies install-plugin install-sylius
.PHONY: sylius

sylius-standard:
	${COMPOSER_ROOT} create-project sylius/sylius-standard ${TEST_DIRECTORY} "~${SYLIUS_VERSION}" --no-install --no-scripts
	${COMPOSER} config allow-plugins true
	${COMPOSER} require sylius/sylius:"~${SYLIUS_VERSION}"

update-dependencies:
	${COMPOSER} config extra.symfony.require "~${SYMFONY_VERSION}"
	${COMPOSER} require --dev donatj/mock-webserver:^2.1 --no-scripts --no-update
ifeq ($(shell [[ $(SYMFONY_VERSION) == 4.4 && $(PHP_VERSION) == 7.4 ]] && echo true ),true)
	${COMPOSER} require sylius/admin-api-bundle:1.10 --no-scripts --no-update
endif
ifeq ($(SYLIUS_VERSION), 1.8.0)
	${COMPOSER} update --no-progress --no-scripts --prefer-dist -n
endif
	${COMPOSER} require symfony/asset:~${SYMFONY_VERSION} --no-scripts --no-update
	${COMPOSER} update --no-progress -n

install-plugin:
	${COMPOSER} config repositories.plugin '{"type": "path", "url": "../../"}'
	${COMPOSER} config extra.symfony.allow-contrib true
	${COMPOSER} config minimum-stability "dev"
	${COMPOSER} config prefer-stable true
	${COMPOSER} req ${PLUGIN_NAME}:* --prefer-source --no-scripts
	cp -r install/Application tests

install-sylius:
	${CONSOLE} sylius:install -n -s default
	${YARN} install
	${YARN} build
	${CONSOLE} cache:clear

phpunit-configure:
	cp phpunit.xml.dist ${TEST_DIRECTORY}/phpunit.xml

phpunit-run:
	cd ${TEST_DIRECTORY} && ./vendor/bin/phpunit --process-isolation --do-not-cache-result

grumphp:
	vendor/bin/grumphp run

help: SHELL=/bin/bash
help: ## Dislay this help
	@IFS=$$'\n'; for line in `grep -h -E '^[a-zA-Z_#-]+:?.*?##.*$$' $(MAKEFILE_LIST)`; do if [ "$${line:0:2}" = "##" ]; then \
	echo $$line | awk 'BEGIN {FS = "## "}; {printf "\033[33m    %s\033[0m\n", $$2}'; else \
	echo $$line | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m%s\n", $$1, $$2}'; fi; \
	done; unset IFS;
.PHONY: help
