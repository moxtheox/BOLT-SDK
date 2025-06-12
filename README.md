# BOLT-SDK

This repository contains a TypeScript client (SDK) for interacting with the BOLT API. It provides a structured, extensible, and type-safe way to make API requests, manage authentication, and handle various data retrieval operations.

## Table of Contents

-   [Features](#features)
-   [Getting Started](#getting-started)
    -   [Prerequisites](#prerequisites)
    -   [Installation](#installation)
    -   [Configuration](#configuration)
    -   [Running the SDK](#running-the-sdk)
-   [Usage](#usage)
    -   [Instantiation](#instantiation)
    -   [Authentication](#authentication)
    -   [Making API Calls](#making-api-calls)
    -   [Example](#example)
-   [Architecture & Key Concepts](#architecture--key-concepts)
    -   [`BOLTApi` Class](#boltapi-class)
    -   [`BoltApiRoutes` Configuration](#boltapiroutes-configuration)
    -   [`BOLTCookieManager` (Singleton)](#boltcookiemanager-singleton)
    -   [Error Handling](#error-handling)
-   [Extensibility](#extensibility)
-   [License](#license)

---

## Features

* **Type-Safe API Interactions:** Leverages TypeScript for strong typing of API responses and parameters.
* **Centralized Route Definitions:** All API endpoints are defined in a single, easy-to-manage `BoltAPIRoutes.ts` file.
* **Authentication & Session Management:** Handles login and manages the authentication cookie, including expiration checks.
* **Modular Design:** Clearly separates API request logic, route definitions, and cookie management.
* **Dynamic Query String Generation:** Automatically constructs query strings based on defined parameters.
* **Robust Error Handling:** Includes checks for missing configuration and invalid parameters.
* **Comprehensive Endpoint Coverage:** Provides methods for fetching various data types like loads, shipments, users, equipment, and more.

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

* **Node.js**: (LTS version recommended)
* **TypeScript**: You might need it for static analysis or if compiling for Node.js. You can install it globally via `npm install -g typescript` if needed.

### Installation

This project has no external package dependencies.

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/moxtheox/BOLT-SDK.git
    cd BOLT-SDK
    ```

### Configuration

This client relies on environment variables for sensitive information like the API tenant URL, username, and password.

1.  **Create a `.env` file** in the root of your project.
2.  **Add the following variables** to your `.env` file:

    ```
    BOLT_TENANT_URL=https://your-tenant.bolt.com # Replace with your actual BOLT tenant URL
    BOLT_USER_NAME=your_username               # Your BOLT API username
    BOLT_USER_PASSWORD=your_password           # Your BOLT API password
    ```
    * **Important:** The `.env` file should **NEVER** be committed to Git. Ensure it's listed in your `.gitignore` file.

### Running the SDK

The SDK is designed to be run within a Node.js environment. The `BOLTApi` class directly accesses environment variables using `process.env`. If you are running a simple script, you might need a package like `dotenv` to load the `.env` file, or ensure your execution environment handles loading it.

```bash
# To run TypeScript directly (requires ts-node or similar setup):
# Install ts-node globally if you don't have it: npm install -g ts-node
 node --loader ts-node/esm your_entry_point.ts # Replace 'your_entry_point.ts' with your main script file (e.g., BOLTApi.ts if running example)

# Or, compile the TypeScript files to JavaScript first:
 tsc BOLTApi.ts BoltAPIRoutes.ts BOLTCookieManager.ts # Compile all relevant .ts files
 node BOLTApi.js # Run the compiled JavaScript file (assuming BOLTApi.ts is your main entry point)
```

## Usage

### Instantiation

Create an instance of the `BOLTApi` class. You can either let it pick up credentials from environment variables or pass them directly to the constructor.

```typescript
import { BOLTApi } from './BOLTApi';

// Option 1: Use environment variables (recommended)
const api = new BOLTApi();

// Option 2: Pass credentials directly (less secure for production)
const api = new BOLTApi('myusername', 'mypassword');
```

### Authentication

Before making most API calls, you'll need to authenticate. The `authenticate()` method handles this by checking for an existing valid cookie or performing a login request if necessary.

```typescript
import { eCookieResults } from './BOLTCookieManager';

async function initializeApi() {
    const api = new BOLTApi();
    const authResult = await api.authenticate();

    if (authResult === eCookieResults.SET) {
        console.log('Successfully authenticated with BOLT API.');
        // Proceed with API calls
    } else {
        console.error('Authentication failed:', authResult);
    }
}

initializeApi();
```

### Making API Calls

The `BOLTApi` class provides methods corresponding to various API endpoints. Each method returns a `Promise<ApiResponse<T>>`, where `T` is the expected data type.

```typescript
import { BOLTApiLoadBoardShipmentStatus } from './BOLTApi';

async function fetchSomeData() {
    const api = new BOLTApi();
    if (await api.authenticate() === eCookieResults.SET) {
        try {
            // Example: Get currently authenticated user data
            const meData = await api.getMe();
            console.log('My User Data:', meData.data);

            // Example: Get a specific load by ID
            const loadId = 12345;
            const loadData = await api.getLoadsById(loadId);
            console.log(`Load ${loadId}:`, loadData.data);

            // Example: Get in-transit load board shipments
            const shipments = await api.GetLoadBoard(BOLTApiLoadBoardShipmentStatus.IN_TRANSIT);
            console.log('In-Transit Shipments:', shipments.data);

        } catch (error) {
            console.error('API call failed:', error);
        }
    }
}

fetchSomeData();
```

### Example


```typescript
import {BOLTApi} from './BOLTApi';
const api = new BOLTApi();
if(await api.authenticate() === eCookieResults.SET) {
    console.log(await api.GetLoadBoard(BOLTApiLoadBoardShipmentStatus.IN_TRANSIT));
}
```

## Architecture & Key Concepts

### `BOLTApi` Class

The `BOLTApi` class is the primary interface for making requests. It encapsulates all the logic for:

* **Configuration:** Manages `tenantUrl`, `username`, `password`, and `version`.
* **Request Construction:** The `makeApiRequest` private method builds the full URL, handles request options (HTTP method, headers), and sends the `fetch` request.
* **Authentication Flow:** The `authenticate` method uses `BOLTCookieManager` to manage session cookies.
* **Endpoint Methods:** Exposes public methods (e.g., `getLoadsById`, `getUsers`) that map to specific API routes.

### `BoltAPIRoutes` Configuration

The `BoltAPIRoutes.ts` file acts as a central manifest for all API endpoints.

* Each route is defined as a `BoltApiRoute` object, specifying its `path`, `method`, `description`, and optional `params`.
* The `path` is a relative path to the API version root (e.g., `/loads/`).
* `params` are defined using `':name'` notation (e.g., `[':id']`), intended for dynamic parts of the URL.
* This separation makes it easy to add, modify, or review API endpoints without touching the request logic.

### `BOLTCookieManager` (Singleton)

The `BOLTCookieManager` is implemented as a singleton to ensure a single, consistent source of truth for the authentication cookie across your application.

* It stores the authentication `cookie` string and the `authenticatedAt` timestamp.
* Provides static methods to `setCookie`, `getCookie`, `isExpired`, `isValid`, and `deleteCookie`.
* The `isValid()` method checks for both the presence and expiration of the cookie.

### URL Construction & Parameter Handling

The `makeQueryString` method dynamically constructs query parameters based on the `params` defined in `BoltAPIRoutes` and the `args` provided to the API methods.

* **Parameter Naming:** It strips the leading colon (`:`) from parameter names (e.g., `':id'` becomes `'id'`).
* **URI Encoding (Specific Behavior):** Critically, based on the observed behavior of the BOLT API, **parameter values are NOT URI-encoded** (e.g., spaces are sent as ` ` instead of `%20`). This adapts to the API's non-standard handling to ensure compatibility. The same principle is applied to parameter keys to maintain consistency with the API's requirements.

### Error Handling

* The constructor throws an `Error` if essential environment variables are missing.
* Individual API methods (e.g., `getLoadsById`, `getUsersById`) validate input parameters (e.g., positive numbers for IDs) and throw `Error`s for invalid input.
* The `makeApiRequest` method throws an `Error` if the number of arguments provided does not match the number of parameters defined in the route.
* API response status codes are currently not explicitly handled for errors; raw `Response` objects are returned and then parsed to `ApiResponse<T>`. Further error handling for non-2xx HTTP responses could be added in `makeApiRequest`.

## Extensibility

Adding new API routes is straightforward:

1.  **Define the new route** in `BoltAPIRoutes.ts` following the `BoltApiRoute` interface.
2.  **Add a new public async method** to the `BOLTApi` class that calls `this.makeApiRequest()` with the new route and any necessary arguments.

This design ensures that your API client can easily grow as the BOLT API evolves.


## License

[MIT License](LICENSE) (You would create a LICENSE file in your repository with the MIT license text)