.PHONY: help setup build test deploy clean docs phase1-setup

help:
	@echo "CODITECT Next Generation - Development Tasks"
	@echo ""
	@echo "Setup & Installation:"
	@echo "  make setup             - Install all dependencies"
	@echo "  make phase1-setup      - Setup Phase 1 development environment"
	@echo ""
	@echo "Build & Test:"
	@echo "  make build             - Build all components"
	@echo "  make test              - Run all tests (unit + integration)"
	@echo "  make test-unit         - Run unit tests only"
	@echo "  make test-integration  - Run integration tests only"
	@echo "  make test-e2e          - Run end-to-end tests only"
	@echo "  make coverage          - Generate test coverage report"
	@echo ""
	@echo "Development:"
	@echo "  make dev               - Start local development environment"
	@echo "  make dev-down          - Stop development environment"
	@echo "  make dev-logs          - View development environment logs"
	@echo ""
	@echo "Deployment:"
	@echo "  make deploy-staging    - Deploy to staging environment"
	@echo "  make deploy-prod       - Deploy to production"
	@echo "  make deploy-rollback   - Rollback last deployment"
	@echo ""
	@echo "Documentation:"
	@echo "  make docs              - Generate documentation"
	@echo "  make docs-view         - Open documentation in browser"
	@echo ""
	@echo "Utilities:"
	@echo "  make clean             - Clean build artifacts"
	@echo "  make lint              - Run linters and formatters"
	@echo "  make format            - Format code"

setup:
	@echo "Installing dependencies..."
	cargo build --release
	pip install -r requirements.txt
	@echo "✅ Dependencies installed"

phase1-setup:
	@echo "Setting up Phase 1 development environment..."
	@echo ""
	@echo "1. Starting infrastructure (Docker)..."
	docker compose -f deployments/docker/docker-compose.dev.yml up -d
	@echo "   ✅ Redis, NATS, ClickHouse ready"
	@echo ""
	@echo "2. Building core components..."
	cargo build --all
	@echo "   ✅ All components built"
	@echo ""
	@echo "3. Running tests..."
	cargo test --lib
	@echo "   ✅ Tests passing"
	@echo ""
	@echo "Phase 1 setup complete! You can now:"
	@echo "  - Run: cargo run -p orchestrator"
	@echo "  - Test: cargo test --all"
	@echo "  - Deploy: docker compose up"

build:
	@echo "Building all components..."
	cargo build --release --all
	@echo "✅ Build complete"

test:
	@echo "Running all tests..."
	cargo test --all --verbose
	pytest tests/ -v
	@echo "✅ All tests passed"

test-unit:
	@echo "Running unit tests..."
	cargo test --lib --verbose

test-integration:
	@echo "Running integration tests..."
	cargo test --test '*/integration_*' --verbose
	pytest tests/integration -v

test-e2e:
	@echo "Running end-to-end tests..."
	cargo test --test '*/e2e_*' --verbose
	pytest tests/e2e -v

coverage:
	@echo "Generating test coverage report..."
	cargo tarpaulin --out Html --output-dir coverage --exclude-files tests/*
	@echo "✅ Coverage report in coverage/index.html"
	@echo "Opening in browser..."
	open coverage/index.html

dev:
	@echo "Starting development environment..."
	docker compose -f deployments/docker/docker-compose.dev.yml up -d
	@echo "✅ Development environment running"
	@echo ""
	@echo "Services:"
	@echo "  Redis:     localhost:6379"
	@echo "  NATS:      localhost:4222"
	@echo "  ClickHouse: localhost:9000"
	@echo ""
	@echo "To view logs: make dev-logs"

dev-down:
	@echo "Stopping development environment..."
	docker compose -f deployments/docker/docker-compose.dev.yml down
	@echo "✅ Development environment stopped"

dev-logs:
	docker compose -f deployments/docker/docker-compose.dev.yml logs -f

deploy-staging:
	@echo "Deploying to staging..."
	@echo "1. Building images..."
	docker build -t coditect:latest .
	@echo "2. Pushing to registry..."
	docker push coditect:latest
	@echo "3. Deploying to K8s..."
	kubectl apply -f deployments/kubernetes/staging/
	@echo "✅ Staging deployment complete"
	@echo "Status: kubectl get pods -n coditect-staging"

deploy-prod:
	@echo "⚠️  Production deployment requires approval"
	@echo "1. Are all tests passing? (make test)"
	@echo "2. Is staging working? (kubectl get pods -n coditect-staging)"
	@echo "3. Code reviewed? (PR approved)"
	@echo ""
	@echo "To proceed: make deploy-prod-confirm"

deploy-prod-confirm:
	@echo "Deploying to production..."
	kubectl apply -f deployments/kubernetes/production/
	@echo "✅ Production deployment complete"
	@echo "Status: kubectl get pods -n coditect-prod"
	@echo "Rollback: make deploy-rollback"

deploy-rollback:
	@echo "Rolling back to previous version..."
	kubectl rollout undo deployment/orchestrator -n coditect-prod
	kubectl rollout undo deployment/task-queue -n coditect-prod
	kubectl rollout undo deployment/agents -n coditect-prod
	@echo "✅ Rollback complete"

docs:
	@echo "Documentation is already generated:"
	@echo "  - EXECUTIVE-SUMMARY.md"
	@echo "  - SDD-SOFTWARE-DESIGN-DOCUMENT.md"
	@echo "  - TDD-TEST-DESIGN-DOCUMENT.md"
	@echo "  - ADRS-ARCHITECTURE-DECISION-RECORDS.md"
	@echo "  - COMPLETE-RESEARCH-ANALYSIS.md"
	@echo ""
	@echo "To view: make docs-view"

docs-view:
	open docs/EXECUTIVE-SUMMARY.md

clean:
	@echo "Cleaning build artifacts..."
	cargo clean
	rm -rf coverage/
	rm -rf dist/
	docker compose -f deployments/docker/docker-compose.dev.yml down
	@echo "✅ Clean complete"

lint:
	@echo "Running linters..."
	cargo clippy --all --all-targets -- -D warnings
	cargo fmt -- --check
	@echo "✅ Lint complete"

format:
	@echo "Formatting code..."
	cargo fmt --all
	@echo "✅ Format complete"

.PHONY: check-all
check-all: lint test coverage
	@echo ""
	@echo "✅ All checks passed!"
	@echo ""
	@echo "Ready to commit:"
	@echo "  git add ."
	@echo "  git commit -m 'Feature/fix description'"
	@echo "  git push origin feature/my-feature"
