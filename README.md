# BOLT-SDK

A lightweight, zero-dependency TypeScript client (SDK) for interacting with the BOLT API. This package provides a structured, type-safe interface for authenticating via Bearer token and querying BOLT platform entities—including loads, shipments, trucks, trailers, equipment, users, and location data.

---

## Features

* **Zero External Dependencies:** Built natively around the standard Web `fetch` and `Headers` APIs.
* **Strong Type Safety:** Complete TypeScript interface definitions covering user profiles, equipment specs, loads, stops, and HOS metrics.
* **Centralized Route Mapping:** Route definitions and HTTP methods managed via a structured manifest (`BoltAPIRoutes.ts`).
* **Automated Query Construction:** Dynamically maps route parameters to formatted URL query strings.
* **Bearer Token Auth:** Built-in authentication handling via `BOLT_TOKEN` authorization headers.

---

## Prerequisites

* **Node.js:** v18+ (or any runtime with modern native `fetch` support, such as Bun or Deno).
* **TypeScript:** Optional, but recommended for full response type checking.

---

## Configuration

The SDK expects the following environment variables to be configured:

```env
BOLT_TENANT_URL=https://your-tenant.bolt.com
BOLT_TOKEN=your_bearer_token_here
```

| Variable | Description |
| :--- | :--- |
| `BOLT_TENANT_URL` | Base URL of your BOLT tenant environment. |
| `BOLT_TOKEN` | Bearer token used for authorization in request headers. |

---

## Quick Start

### Instantiation

```typescript
import { BOLTApi } from "./BOLTApi";

// Reads process.env.BOLT_TENANT_URL and process.env.BOLT_TOKEN automatically
const api = new BOLTApi();
```

### Basic Usage Example

```typescript
import { BOLTApi, BOLTApiLoadBoardShipmentStatus } from "./BOLTApi";

async function main() {
  const api = new BOLTApi();

  try {
    // 1. Fetch current user profile
    const me = await api.getMe();
    console.log(`Authenticated as: ${me.data[0].name}`);

    // 2. Retrieve active load board shipments
    const loadBoard = await api.GetLoadBoard(BOLTApiLoadBoardShipmentStatus.IN_TRANSIT);
    console.log(`Active Shipments: ${loadBoard.data.length}`);

    // 3. Fetch specific load details
    const load = await api.getLoadsById(12345);
    console.log("Load Details:", load.data);
  } catch (error) {
    console.error("API Request Failed:", error);
  }
}

main();
```

---

## API Reference Overview

The `BOLTApi` class exposes strongly typed asynchronous methods corresponding to key system endpoints:

### Authentication & Users
* **`getMe()`**: Returns profile details (`iUserMe`) for the currently authenticated user.
* **`getUsers()`**: Returns a list of all system users (`iUserStandard`).
* **`getUsersById(userId: number)`**: Fetches details for a single user.

### Loads & Shipments
* **`getLoadsById(loadId: number)`**: Retrieves specific load info by PRO / Load ID.
* **`GetLoadBoard(status?)`**: Retrieves entries from the load board, filtered by `BOLTApiLoadBoardShipmentStatus`.
* **`getLoadSegments()` / `getLoadSegmentsById(loadId: number)`**: Fetches load segment breakdowns including assigned trucks, purchase orders, and stops.
* **`getShipmentsByLoadId(loadId: number)`**: Retrieves shipment entities attached to a load.

### Fleet & Equipment
* **`getEquipment()`**: Fetches general equipment records (dollies, containers, etc.).
* **`getTrucks()` / `getTrucksById(truckId: number)`**: Fetches power unit telemetry, specifications, and primary terminals.
* **`getTrailers()` / `getTrailersById(trailerId: number)`**: Retrieves trailer unit records.

### Locations & Billing
* **`getShipTo()` / `getShipToById(shipToId: number)`**: Fetches shipping location records (`iLocation`).
* **`getBillToLocations()`**: Retrieves customer billing location records.

---

## Repository Structure

```
.
├──src/
      ├── BOLTApi.ts                     # Core SDK client class
      ├── BoltAPIRoutes.ts               # Route manifest & HTTP method enums
      ├── BOLTApiResponseInterface.ts    # Standard API response wrappers
      └── interfaces/
          ├── BOLTInterfaces.ts          # Core entity models (Stops, Trucks, Locations, Rules)
          ├── boltLoadSegment.ts         # Load segment composite interfaces
          └── BOLTUserInfo.ts            # User profile, Equipment, HOS, and Permission models
```

---

## License

[MIT](LICENSE)
