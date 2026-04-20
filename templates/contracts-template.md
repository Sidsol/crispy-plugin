# API & Interface Contracts: [FEATURE_NAME]

<!-- Companion artifact for CRISPY features that introduce or modify APIs. -->
<!-- This document is the single source of truth for all interface boundaries. -->
<!-- Both provider and consumer teams should reference this document. -->

| Field              | Value                                   |
|--------------------|-----------------------------------------|
| **Contract Name**  | [FEATURE_NAME] API Contract             |
| **Version**        | [v1.0.0]                                |
| **Date**           | [DATE]                                  |
| **Status**         | Draft · In Review · Approved · Active   |
| **Spec Reference** | `[NNN-FEATURE-NAME]/spec.md`           |
| **Owner**          | [Team / Author]                         |

---

## 1. Overview

[Brief description of what this contract covers and which services are involved.]

### Services Involved

| Service            | Role       | Repository           | Notes                  |
|--------------------|------------|----------------------|------------------------|
| [Service A]        | Provider   | `[repo-name]`       | [Exposes the API]      |
| [Service B]        | Consumer   | `[repo-name]`       | [Calls the API]        |

---

## 2. Authentication & Authorization

| Aspect               | Detail                                          |
|----------------------|-------------------------------------------------|
| **Auth Method**      | [e.g., Bearer JWT, API Key, OAuth 2.0, mTLS]   |
| **Token Location**   | [e.g., `Authorization: Bearer <token>` header]  |
| **Required Scopes**  | [e.g., `read:resource`, `write:resource`]       |
| **Rate Limits**      | [e.g., 100 req/min per API key]                 |
| **CORS Policy**      | [e.g., Allowed origins: `https://app.example.com`] |

---

## 3. REST Endpoints

<!-- Document each endpoint. Add or remove endpoint sections as needed. -->

### 3.1 `POST /api/v1/[resource]`

**Description:** [What this endpoint does]
**Story:** [S-001]

#### Request

| Field          | Detail                                           |
|----------------|--------------------------------------------------|
| **Method**     | `POST`                                           |
| **Path**       | `/api/v1/[resource]`                             |
| **Auth**       | Required — scope: `write:[resource]`             |
| **Content-Type** | `application/json`                             |

**Headers:**

| Header          | Required | Description                              |
|-----------------|----------|------------------------------------------|
| `Authorization` | Yes      | `Bearer <token>`                         |
| `X-Request-Id`  | No       | Idempotency key for retries              |

**Request Body:**

```json
{
  "name": "string (required, max 255)",
  "description": "string (optional, max 2000)",
  "status": "string (enum: 'active' | 'inactive', default: 'active')",
  "metadata": {
    "key": "string (optional)"
  }
}
```

#### Response

**Success — `201 Created`:**

```json
{
  "id": "uuid",
  "name": "string",
  "description": "string | null",
  "status": "string",
  "metadata": {},
  "createdAt": "ISO 8601 datetime",
  "updatedAt": "ISO 8601 datetime"
}
```

**Validation Error — `400 Bad Request`:**

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      {
        "field": "name",
        "message": "Name is required",
        "code": "REQUIRED"
      }
    ]
  }
}
```

**Unauthorized — `401 Unauthorized`:**

```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid or expired token"
  }
}
```

---

### 3.2 `GET /api/v1/[resource]/:id`

**Description:** [What this endpoint does]
**Story:** [S-001]

#### Request

| Field      | Detail                                               |
|------------|------------------------------------------------------|
| **Method** | `GET`                                                |
| **Path**   | `/api/v1/[resource]/:id`                             |
| **Auth**   | Required — scope: `read:[resource]`                  |

**Path Parameters:**

| Parameter | Type | Description         |
|-----------|------|---------------------|
| `id`      | UUID | Resource identifier |

**Query Parameters:**

| Parameter  | Type    | Default | Description                          |
|------------|---------|---------|--------------------------------------|
| `include`  | string  | —       | Comma-separated related resources    |

#### Response

**Success — `200 OK`:**

```json
{
  "id": "uuid",
  "name": "string",
  "description": "string | null",
  "status": "string",
  "createdAt": "ISO 8601 datetime",
  "updatedAt": "ISO 8601 datetime"
}
```

**Not Found — `404 Not Found`:**

```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Resource with id '[id]' not found"
  }
}
```

---

### 3.3 `GET /api/v1/[resource]`

**Description:** [List resources with pagination and filtering]
**Story:** [S-001]

#### Request

| Field      | Detail                                               |
|------------|------------------------------------------------------|
| **Method** | `GET`                                                |
| **Path**   | `/api/v1/[resource]`                                 |
| **Auth**   | Required — scope: `read:[resource]`                  |

**Query Parameters:**

| Parameter  | Type    | Default | Description                          |
|------------|---------|---------|--------------------------------------|
| `page`     | integer | 1       | Page number (1-indexed)              |
| `limit`    | integer | 20      | Items per page (max 100)             |
| `sort`     | string  | `-createdAt` | Sort field (prefix `-` for desc) |
| `status`   | string  | —       | Filter by status                     |
| `search`   | string  | —       | Full-text search on name/description |

#### Response

**Success — `200 OK`:**

```json
{
  "data": [
    {
      "id": "uuid",
      "name": "string",
      "status": "string",
      "createdAt": "ISO 8601 datetime"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 142,
    "totalPages": 8,
    "hasNext": true,
    "hasPrev": false
  }
}
```

---

### 3.4 `PUT /api/v1/[resource]/:id`

**Description:** [Full update of a resource]
**Story:** [S-002]

#### Request

**Request Body:** [Same schema as POST, all fields required]

#### Response

**Success — `200 OK`:** [Same schema as GET single]

**Conflict — `409 Conflict`:**

```json
{
  "error": {
    "code": "CONFLICT",
    "message": "Resource was modified by another request",
    "details": {
      "currentVersion": "string",
      "yourVersion": "string"
    }
  }
}
```

---

### 3.5 `DELETE /api/v1/[resource]/:id`

**Description:** [Delete a resource]
**Story:** [S-002]

#### Response

**Success — `204 No Content`:** (empty body)

**Not Found — `404 Not Found`:** [Same as GET single]

---

## 4. Common Error Response Format

<!-- All errors follow this standard format. -->

```json
{
  "error": {
    "code": "string (machine-readable error code)",
    "message": "string (human-readable description)",
    "details": "object | array (optional, additional context)"
  }
}
```

### Error Codes

| HTTP Status | Code                | Description                                |
|-------------|---------------------|--------------------------------------------|
| 400         | `VALIDATION_ERROR`  | Request body or params failed validation   |
| 401         | `UNAUTHORIZED`      | Missing or invalid authentication          |
| 403         | `FORBIDDEN`         | Authenticated but insufficient permissions |
| 404         | `NOT_FOUND`         | Resource does not exist                    |
| 409         | `CONFLICT`          | Concurrent modification conflict           |
| 422         | `UNPROCESSABLE`     | Valid syntax but semantic error            |
| 429         | `RATE_LIMITED`      | Too many requests                          |
| 500         | `INTERNAL_ERROR`    | Unexpected server error                    |

---

## 5. Data Models

<!-- Canonical data model definitions shared across endpoints. -->

### [ResourceName]

| Field         | Type     | Required | Constraints            | Description            |
|---------------|----------|----------|------------------------|------------------------|
| `id`          | UUID     | Auto     | PK, immutable          | Unique identifier      |
| `name`        | string   | Yes      | max 255, non-empty     | Display name           |
| `description` | string   | No       | max 2000               | Optional description   |
| `status`      | enum     | Yes      | `active` \| `inactive` | Resource status        |
| `createdAt`   | datetime | Auto     | ISO 8601, immutable    | Creation timestamp     |
| `updatedAt`   | datetime | Auto     | ISO 8601               | Last update timestamp  |

### [RelatedResource]

| Field           | Type   | Required | Constraints            | Description            |
|-----------------|--------|----------|------------------------|------------------------|
| `id`            | UUID   | Auto     | PK, immutable          | Unique identifier      |
| `[resource]Id`  | UUID   | Yes      | FK → [Resource]        | Parent reference       |

---

## 6. Event Contracts

<!-- If this feature uses pub/sub, event-driven, or webhook patterns. -->
<!-- Remove this section if not applicable. -->

### Event: `[resource].created`

**Trigger:** When a new [resource] is created via `POST /api/v1/[resource]`
**Channel / Topic:** `[topic-name]`

```json
{
  "event": "[resource].created",
  "timestamp": "ISO 8601 datetime",
  "data": {
    "id": "uuid",
    "name": "string",
    "status": "string",
    "createdAt": "ISO 8601 datetime"
  },
  "metadata": {
    "correlationId": "uuid",
    "source": "[service-name]",
    "version": "1.0"
  }
}
```

### Event: `[resource].updated`

**Trigger:** When a [resource] is updated via `PUT /api/v1/[resource]/:id`
**Channel / Topic:** `[topic-name]`

```json
{
  "event": "[resource].updated",
  "timestamp": "ISO 8601 datetime",
  "data": {
    "id": "uuid",
    "changes": {
      "[field]": {
        "old": "previous value",
        "new": "new value"
      }
    }
  },
  "metadata": {
    "correlationId": "uuid",
    "source": "[service-name]",
    "version": "1.0"
  }
}
```

### Event: `[resource].deleted`

**Trigger:** When a [resource] is deleted via `DELETE /api/v1/[resource]/:id`
**Channel / Topic:** `[topic-name]`

```json
{
  "event": "[resource].deleted",
  "timestamp": "ISO 8601 datetime",
  "data": {
    "id": "uuid"
  },
  "metadata": {
    "correlationId": "uuid",
    "source": "[service-name]",
    "version": "1.0"
  }
}
```

---

## 7. Dependencies on Other Contracts

<!-- List any external APIs or contracts this feature depends on. -->

| Contract / API         | Version | Endpoints Used                    | Notes                    |
|------------------------|---------|-----------------------------------|--------------------------|
| [Auth Service]         | v2      | `POST /auth/validate-token`       | Token validation         |
| [Notification Service] | v1      | `POST /notifications/send`        | Triggered on create      |
| [External API]         | v3      | `GET /external/data`              | Data enrichment          |

---

## 8. Versioning & Deprecation

| Version | Status     | Sunset Date | Notes                              |
|---------|------------|-------------|------------------------------------|
| v1      | Active     | —           | Current version                    |

### Breaking Change Policy

- Breaking changes require a new API version (`v1` → `v2`)
- Non-breaking additions (new optional fields) can be added to current version
- Deprecated endpoints return `Sunset` header with deprecation date
- Minimum 90-day deprecation notice before removal

---

<!-- NOTE FOR AI AGENT: -->
<!-- This contract should be written AFTER intent.md and BEFORE implementation. -->
<!-- Both the API provider and consumer should agree on this contract. -->
<!-- During implementation, validate that actual request/response shapes match -->
<!-- these definitions exactly. Any deviation should update this contract first. -->
<!-- Use this document to generate API tests and client SDKs. -->
