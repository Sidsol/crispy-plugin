---
name: create-contracts
description: "Generate API/interface contract documents"
user-invocable: false
---

# Create API & Interface Contracts

Generate contract documents that define the API boundaries and interface agreements for the feature. Contracts live in a `contracts/` subdirectory within the feature's spec folder.

## Process

1. Read `spec.md` and `intent.md` to identify all API boundaries and integration points.
2. For each boundary, create a contract markdown file.
3. Write files to `crispy-docs/specs/NNN-feature-name/contracts/`.

## Contract File Structure

Create one file per API boundary (e.g., `auth-api.md`, `user-service.md`).

```markdown
# Contract: {API/Service Name}

## Overview
Brief description of this API boundary and its role in the feature.

## Base URL / Entry Point
`{protocol}://{host}:{port}/{base-path}`

## Authentication
- Type: {Bearer token / API key / OAuth2 / None}
- Header: `Authorization: Bearer {token}`

## Endpoints

### {METHOD} {/path}
**Description:** {What this endpoint does}

**Request:**
- Headers: {required headers}
- Query Parameters:
  | Param | Type | Required | Description |
  |---|---|---|---|
  | {name} | {type} | {yes/no} | {description} |
- Body:
  ```json
  {
    "field": "type — description"
  }
  ```

**Response (200):**
```json
{
  "field": "type — description"
}
```

**Error Responses:**
| Status | Code | Description |
|---|---|---|
| 400 | VALIDATION_ERROR | {When this occurs} |
| 401 | UNAUTHORIZED | {When this occurs} |
| 404 | NOT_FOUND | {When this occurs} |

---

## Data Models

### {ModelName}
| Field | Type | Required | Description |
|---|---|---|---|
| id | string (UUID) | yes | Unique identifier |
| {field} | {type} | {yes/no} | {description} |

## Events / Messages
If the API publishes or subscribes to events:

### Event: {event.name}
- **Channel/Topic:** {channel name}
- **Payload:**
  ```json
  {
    "field": "type — description"
  }
  ```

## Versioning
- Current version: {v1}
- Backward compatibility policy: {description}
```

## Guidelines

- One contract file per distinct API boundary or service interface.
- Include all HTTP methods, not just the happy path.
- Error responses must cover validation errors, auth failures, and not-found cases at minimum.
- Data models should match the schemas in `research.md` where they overlap.
- If the API uses pagination, document the pagination contract explicitly.
- If the API uses WebSockets or event-driven patterns, document the message contracts.
- Contracts are agreements — both provider and consumer teams should review them.
