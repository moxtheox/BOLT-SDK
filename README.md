# BOLT API Client (TypeScript)

This repository contains a TypeScript client for interacting with the BOLT API. It provides a structured, extensible, and type-safe way to make API requests, manage authentication, and handle various data retrieval operations.

## Table of Contents

-   [Features](#features)
-   [Getting Started](#getting-started)
    -   [Prerequisites](#prerequisites)
    -   [Installation](#installation)
    -   [Configuration](#configuration)
-   [Usage](#usage)
    -   [Instantiation](#instantiation)
    -   [Authentication](#authentication)
    -   [Making API Calls](#making-api-calls)
    -   [Example](#example)
-   [Architecture & Key Concepts](#architecture--key-concepts)
    -   [`BOLTApi` Class](#boltapi-class)
    -   [`BoltApiRoutes` Configuration](#boltapiroutes-configuration)
    -   [`BOLTCookieManager` (Singleton)](#boltcookiemanager-singleton)
    -   https://construo.io/tags/parameters(#url-construction--parameter-handling)
    -   [Error Handling](#error-handling)
-   [Extensibility](#extensibility)
-   [Future Considerations](#future-considerations)
-   [License](#license)

---

## Features

* **Type-Safe API Interactions:** Leverages TypeScript for strong typing of API responses and parameters.
* **Centralized Route Definitions:** All API endpoints are defined in a single, easy-to-manage `BoltApiRoutes.ts` file.
* **Authentication & Session Management:** Handles login and manages the authentication cookie, including expiration checks.
* **Modular Design:** Clearly separates API request logic, route definitions, and cookie management.
* **Dynamic Query String Generation:** Automatically constructs query strings based on defined parameters.
* **Robust Error Handling:** Includes checks for missing configuration and invalid parameters.
* **Comprehensive Endpoint Coverage:** Provides methods for fetching various data types like loads, shipments, users, equipment, and more.

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

* **Node.js**: (LTS version recommended)
* **npm** or **Yarn**: Package manager (comes with Node.js)
* **TypeScript**: `npm install -g typescript`

### Installation

1.  **Clone the repository:**
    ```bash
    git clone BOLT-SDK
    cd BOLT-SDK
    ```
2.  **Install dependencies:**
    ```bash
    npm install
    # or
    yarn install
    ```

### Configuration

This client relies on environment variables for sensitive information like the API tenant URL, username, and password.

1.  **Create a `.env` file** in the root of your project.
2.  **Add the following variables** to your `.env` file:

    ```
    BOLT_TENANT_URL=[https://your-tenant.bolt.com] # Replace with your actual BOLT tenant URL
    BOLT_USER_NAME=your_username               # Your BOLT API username
    BOLT_USER_PASSWORD=your_password           # Your BOLT API password
    ```
    * **Important:** The `.env` file should **NEVER** be committed to Git. Ensure it's listed in your `.gitignore` file.

## Usage

### Instantiation

Create an instance of the `BOLTApi` class. You can either let it pick up credentials from environment variables or pass them directly to the constructor.

```typescript
import { BOLTApi } from './BOLTApi';

// Option 1: Use environment variables (recommended)
const api = new BOLTApi();

// Option 2: Pass credentials directly (less secure for production)
// const api = new BOLTApi('myusername', 'mypassword');