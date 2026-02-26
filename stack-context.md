# Stack Context

Assumed technology landscape for projects using workspace-standards.

## Backend

- **Kotlin** -- Primary language for new microservices
- **Spring Boot** -- Web framework, dependency injection, configuration
- **Axon Framework** -- Event sourcing and CQRS for domain-heavy services
- **Groovy/Java** -- Legacy monolith (`pax8/console`)
- **PostgreSQL** -- Primary relational database
- **Redis** -- Caching and session storage
- **Gradle** -- Build tool (`./gradlew check` for tests, PMD, CodeNarc)

## Frontend

- **Vue 3** -- UI framework (Composition API, `<script setup>`)
- **TypeScript** -- Type safety for frontend code
- **Pinia** -- State management
- **Module Federation** -- Micro-frontend composition
- **Vitest** -- Unit testing
- **Testing Library** -- Component testing
- **Playwright** -- E2E testing with Page Object Model

## Infrastructure

- **Terraform** -- Infrastructure as Code
- **Docker** -- Containerisation
- **AWS** -- Cloud provider

## Quality Tools

- **PMD** -- Java/Groovy static analysis
- **CodeNarc** -- Groovy static analysis
- **ESLint** -- JavaScript/TypeScript linting
- **Spock** -- Groovy testing framework
- **MockK** -- Kotlin mocking
- **Testcontainers** -- Container-based integration tests
- **AggregateTestFixture / SagaTestFixture** -- Axon testing

## Project Management

- **Jira** -- Issue tracking (HRZN project)
- **GitHub** -- Source control and pull requests
