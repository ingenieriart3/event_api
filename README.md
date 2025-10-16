# Event API - Elixir/Phoenix

A high-performance, fault-tolerant event management API built with Elixir and Phoenix following Domain-Driven Design principles.

## 🚀 Features

- ✅ **Event Management** - Full CRUD with Bearer token authentication
- ✅ **Advanced Filtering** - Query by date ranges and multiple locations
- ✅ **Event Lifecycle** - DRAFT → PUBLISHED → CANCELLED with proper validations
- ✅ **Security** - Field-level security with public/private endpoints
- ✅ **AI-Powered Summaries** - Mock AI generation with Server-Sent Events streaming
- ✅ **Intelligent Caching** - In-memory ETS cache with automatic invalidation
- ✅ **Comprehensive Testing** - E2E, Security, and Validation test suites
- ✅ **Production Ready** - Structured logging, health checks, and telemetry

## 📋 API Quick Reference

### Authentication

```bash
# All protected endpoints require:
Authorization: Bearer admin-token-123
```

### Event Status Flow

```
DRAFT → PUBLISHED → CANCELLED
```

- Once PUBLISHED or CANCELLED, cannot return to DRAFT
- CANCELLED events can be re-published to PUBLISHED

## 🛠️ Development Setup

### Prerequisites

- **Elixir 1.16+** and **Erlang/OTP 25+**
- **PostgreSQL 15+**
- **Git**

### Database Configuration

The project is configured to use PostgreSQL with:

```elixir
hostname: "localhost"
username: "event_service_user"
password: "event_service_password"
database: "event_service_dev"
port: 5432
```

### Quick Start

```bash
# 1. Clone and setup
git clone <repository>
cd event_api

# 2. Install dependencies
mix deps.get

# 3. Create and setup database
mix ecto.create
mix ecto.migrate

# 4. Start the server
mix phx.server
```

The API will be available at `http://localhost:4000`

## 📚 API Documentation

### 🔐 Protected Endpoints (Require Authentication)

#### Create Event

```bash
curl -X POST http://localhost:4000/api/v1/events \
  -H "Authorization: Bearer admin-token-123" \
  -H "Content-Type: application/json" \
  -d '{
    "event": {
      "title": "Tech Conference 2024",
      "start_at": "2024-09-01T10:00:00Z",
      "end_at": "2024-09-01T17:00:00Z",
      "location": "San Francisco",
      "status": "DRAFT",
      "internal_notes": "VIP list pending",
      "created_by": "cto@example.com"
    }
  }'
```

#### List Events with Filtering

```bash
# Basic listing
curl "http://localhost:4000/api/v1/events" \
  -H "Authorization: Bearer admin-token-123"

# With date range and location filtering
curl "http://localhost:4000/api/v1/events?dateFrom=2024-09-01&dateTo=2024-09-30&locations=São Paulo,Rio&status=PUBLISHED&page=1&limit=20" \
  -H "Authorization: Bearer admin-token-123"
```

#### Update Event Status

```bash
# Publish an event
curl -X PATCH http://localhost:4000/api/v1/events/e3c1b8d9-3bd5-4c64-8c4d-0f6d9fb21c34 \
  -H "Authorization: Bearer admin-token-123" \
  -H "Content-Type: application/json" \
  -d '{
    "event": {
      "status": "PUBLISHED"
    }
  }'

# Cancel an event
curl -X PATCH http://localhost:4000/api/v1/events/e3c1b8d9-3bd5-4c64-8c4d-0f6d9fb21c34 \
  -H "Authorization: Bearer admin-token-123" \
  -H "Content-Type: application/json" \
  -d '{
    "event": {
      "status": "CANCELLED",
      "internal_notes": "Event cancelled due to weather conditions"
    }
  }'
```

### 🌐 Public Endpoints (No Authentication Required)

#### List Public Events

```bash
# Get all public events (PUBLISHED and CANCELLED only)
curl "http://localhost:4000/api/v1/public/events"

# With filtering
curl "http://localhost:4000/api/v1/public/events?dateFrom=2024-09-01&dateTo=2024-09-30&locations=San Francisco&page=1&limit=20"
```

#### Get AI Summary (Cached)

```bash
curl "http://localhost:4000/api/v1/public/events/e3c1b8d9-3bd5-4c64-8c4d-0f6d9fb21c34/summary"
```

#### Stream AI Summary (Server-Sent Events)

```bash
# Real-time streaming with chunked responses
curl -N "http://localhost:4000/api/v1/public/events/e3c1b8d9-3bd5-4c64-8c4d-0f6d9fb21c34/summary/stream"
```

### 🩺 Health Check

```bash
curl http://localhost:4000/health
```

### 📁 Insomnia V5 collection yaml

```bash
test/request/event_api.yaml
```

## 🎯 Response Formats

### Success Responses

**Event Created (201)**

```json
{
  "event": {
    "id": "e3c1b8d9-3bd5-4c64-8c4d-0f6d9fb21c34",
    "title": "Tech Conference 2024",
    "start_at": "2024-09-01T10:00:00Z",
    "end_at": "2024-09-01T17:00:00Z",
    "location": "San Francisco",
    "status": "DRAFT",
    "internal_notes": "VIP list pending",
    "created_by": "cto@example.com",
    "inserted_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

**Public Event (200)**

```json
{
  "events": [
    {
      "id": "e3c1b8d9-3bd5-4c64-8c4d-0f6d9fb21c34",
      "title": "Tech Conference 2024",
      "start_at": "2024-09-01T10:00:00Z",
      "end_at": "2024-09-01T17:00:00Z",
      "location": "San Francisco",
      "status": "PUBLISHED",
      "is_upcoming": true
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "total_pages": 1
  }
}
```

**AI Summary (200)**

```json
{
  "summary": "Join us for Tech Conference 2024, happening in San Francisco on September 01, 2024. This is a published event that promises engaging content and networking opportunities. Perfect for professionals looking to connect and learn. Don't miss out - mark your calendar!",
  "event_id": "e3c1b8d9-3bd5-4c64-8c4d-0f6d9fb21c34",
  "generated_at": "2024-01-15T10:30:00Z"
}
```

### Error Responses

**Authentication Error (401)**

```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid or missing authentication token"
  }
}
```

**Validation Error (422)**

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      {
        "field": "start_at",
        "message": "must be in the future"
      }
    ]
  }
}
```

**Not Found (404)**

```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Resource not found"
  }
}
```

## 🧪 Testing

### Run Test Suites

```bash
# Complete test suite
mix test

# End-to-end tests (event lifecycle, authentication)
mix test test/e2e/

# Security tests (field-level security, access control)
mix test test/security/

# Validation tests (input validation, business rules)
mix test test/validation/

# With test coverage report
mix test --cover
```

### Test Coverage

The test suite includes:

- ✅ **Event lifecycle flows** (DRAFT → PUBLISHED → CANCELLED)
- ✅ **Authentication enforcement** (401 responses)
- ✅ **Field-level security** (private fields never exposed publicly)
- ✅ **Validation rules** (date ranges, status transitions, required fields)
- ✅ **Cache behavior** (HIT/MISS scenarios)
- ✅ **Public/private endpoint separation**

## ⚙️ Configuration

### Environment Variables

```bash
# Authentication
STATIC_AUTH_TOKEN="admin-token-123"

# Database
DATABASE_URL="postgresql://event_service_user:event_service_password@localhost:5432/event_service_dev"

# Phoenix
SECRET_KEY_BASE="your-secret-key-base"

# Server
PORT=4000
```

### Development Configuration

The project includes development-specific settings:

- **Auto-reload** for development efficiency
- **Detailed error messages** with stack traces
- **SQL query logging** for debugging
- **Structured JSON logging** with request tracking

## 🏗️ Architecture

### Domain Contexts

- **`Events`** - Core event management business logic
- **`Summaries`** - AI summary generation and caching
- **`Web`** - Phoenix controllers, views, and routing

### Key Design Patterns

- **Domain-Driven Design** with bounded contexts
- **CQRS** for separate read/write models
- **Repository Pattern** with Ecto
- **GenServer** for cache management
- **Server-Sent Events** for real-time streaming

### Caching Strategy

- **In-memory ETS cache** for AI summaries
- **Cache keys** based on SHA256 hash of public fields
- **Automatic invalidation** when event title, location, or dates change
- **Cache headers** for HTTP caching (`X-Summary-Cache: HIT|MISS`)

## 🔧 Development Tools

### Code Quality

```bash
# Format code
mix format

# Static analysis
mix credo

# Type checking
mix dialyzer
```

### Database Operations

```bash
# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Rollback migrations
mix ecto.rollback

# Create new migration
mix ecto.gen.migration add_new_feature
```

### Interactive Development

```bash
# Start IEx with project context
iex -S mix

# Start IEx with Phoenix server
iex -S mix phx.server
```

## 📊 Monitoring & Observability

### Health Checks

```bash
curl http://localhost:4000/health
```

Response:

```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "1.0.0"
}
```

### Logging Features

- **Structured JSON logs** in production
- **Request ID tracking** across services
- **Cache hit/miss logging** for observability
- **Event lifecycle notifications**

## 🚀 Production Notes

### Performance Considerations

- Database indexes optimized for date/location queries
- Connection pooling for database operations
- ETS for fast in-memory caching
- Pagination to limit result sets
- Streaming responses for large datasets

### Security Features

- Bearer token authentication for protected endpoints
- Field-level security preventing private data exposure
- Input validation and sanitization
- Secure headers configuration

## 🤝 Contributing

### Development Workflow

1. Run tests: `mix test`
2. Format code: `mix format`
3. Check code quality: `mix credo`
4. Verify all tests pass: `mix test --cover`

### Code Standards

- Follow Elixir formatting rules
- Write comprehensive tests for new features
- Maintain API consistency
- Document new endpoints in README

## 📞 Support

For issues and questions:

1. Check the test suite for expected behavior
2. Review the API documentation above
3. Examine the structured error responses
4. Check server logs for detailed error information

---

**Built with ❤️ using Elixir and Phoenix** - A production-ready event management API following industry best practices and domain-driven design principles.
