# no buildin rules and variables
MAKEFLAGS =+ -rR --warn-undefined-variables

.PHONY: *

CONFLUENT_VERSION ?= latest
CONFLUENT_NETWORK_SUBNET ?= 172.68.0.0/24
CONFLUENT_NETWORK_GATEWAY ?= 172.68.0.1
SCHEMA_REGISTRY_IPV4 ?= 172.68.0.103
KAFKA_BROKER_IPV4 ?= 172.68.0.102
ZOOKEEPER_IPV4 ?= 172.68.0.101
COMPOSER ?= bin/composer.phar
COMPOSER_VERSION ?= 2.1.12
COMPOSER_STABILITY ?= --prefer-stable
PHP_STAN ?= bin/phpstan.phar
PHP_STAN_VERSION ?= 1.1.2
PHP_CS_FIXER ?= bin/php-cs-fixer.phar
PHP_CS_FIXER_VERSION ?= 3.2.1
PHPUNIT ?= vendor/bin/phpunit
PHP ?= bin/php
PHP_VERSION ?= 7.4
XDEBUG_VERSION ?= 3.1.1
XDEBUG_OPTIONS ?= -d xdebug.mode=off
export

docker:
	DOCKER_BUILDKIT=1 docker build \
	  --build-arg PHP_VERSION=$(PHP_VERSION) \
	  --build-arg XDEBUG_VERSION=$(XDEBUG_VERSION) \
	  -t schema-registry-client:$(PHP_VERSION) \
	  -f Dockerfile \
	  .

composer-install:
	PHP_VERSION=$(PHP_VERSION) $(PHP) $(XDEBUG_OPTIONS) $(COMPOSER) install --no-interaction --no-progress --no-scripts

composer-update:
	PHP_VERSION=$(PHP_VERSION) $(PHP) $(XDEBUG_OPTIONS) $(COMPOSER) update --no-interaction --no-progress --no-scripts $(COMPOSER_STABILITY)

phpstan:
	PHP_VERSION=$(PHP_VERSION) $(PHP) -d memory_limit=-1 $(XDEBUG_OPTIONS) $(PHP_STAN) analyse

cs-fixer:
	PHP_VERSION=$(PHP_VERSION) $(PHP) $(XDEBUG_OPTIONS) $(PHP_CS_FIXER) fix --config=.php-cs-fixer.dist.php --diff -v --dry-run \
	  --path-mode=intersection --allow-risky=yes src test

cs-fixer-modify:
	PHP_VERSION=$(PHP_VERSION) $(PHP) $(XDEBUG_OPTIONS) $(PHP_CS_FIXER) fix --config=.php-cs-fixer.dist.php --diff -v \
	  --path-mode=intersection --allow-risky=yes src test

phpunit:
	PHP_VERSION=$(PHP_VERSION) $(PHP) $(XDEBUG_OPTIONS) $(PHPUNIT) --exclude-group integration

coverage:
	mkdir -p build
	PHP_VERSION=$(PHP_VERSION) $(PHP) -d xdebug.mode=coverage -d xdebug.coverage_enable=1 vendor/bin/phpunit --exclude-group integration \
	  --coverage-clover=build/coverage.clover --coverage-text

ci-local: cs-fixer phpstan phpunit

examples:
	PHP_VERSION=$(PHP_VERSION) $(PHP) examples/*

install-phars:
	curl https://github.com/FriendsOfPHP/PHP-CS-Fixer/releases/download/v$(PHP_CS_FIXER_VERSION)/php-cs-fixer.phar -o bin/php-cs-fixer.phar -LR -z bin/php-cs-fixer.phar
	chmod a+x bin/php-cs-fixer.phar
	curl https://getcomposer.org/download/$(COMPOSER_VERSION)/composer.phar -o bin/composer.phar -LR -z bin/composer.phar
	chmod a+x bin/composer.phar
	curl https://github.com/phpstan/phpstan/releases/download/$(PHP_STAN_VERSION)/phpstan.phar -o bin/phpstan.phar -LR -z bin/phpstan.phar
	chmod a+x bin/phpstan.phar

platform:
	docker compose down
	docker compose up -d
	bin/wait-for-all.sh

platform-logs:
	docker compose logs -f

clean:
	rm -rf build
	docker compose down
