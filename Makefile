test:
	./gradlew test

lint:
	./gradlew spotlessCheck
	ansible-lint ansible

smoke:
	curl --fail --silent --show-error "$${APP_URL:-http://localhost:8080}/api/bulletins" >/dev/null
	curl --fail --silent --show-error "$${APP_URL:-http://localhost:8080}/actuator/health" >/dev/null
	curl --fail --silent --show-error "$${PROMETHEUS_URL:-http://localhost:9090}/-/ready" >/dev/null

start: run

run:
	./gradlew bootRun

update-gradle:
	./gradlew wrapper --gradle-version 9.2.1

update-deps:
	./gradlew versionCatalogUpdate

install:
	./gradlew dependencies

ansible-install:
	ansible-galaxy role install -r ansible/requirements.yml
	ansible-galaxy collection install -r ansible/requirements.yml

build:
	./gradlew build

docker-build:
	docker build -t bulletin-board:local .

docker-run:
	docker run --rm -p 8080:8080 -p 9090:9090 bulletin-board:local

deploy:
	ansible-playbook -i ansible/inventory ansible/deploy.yml -e image=$(IMAGE)

monitoring-deploy:
	ansible-playbook -i ansible/inventory ansible/monitoring.yml

lint-fix:
	./gradlew spotlessApply

.PHONY: build docker-build docker-run deploy monitoring-deploy ansible-install lint lint-fix smoke
