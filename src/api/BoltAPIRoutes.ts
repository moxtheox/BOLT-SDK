// src/classes/BoltApiRoutes.ts

import path from "path";

export enum BOLTApiRouteMethods {
  GET = 'GET',
  POST = 'POST',
  PUT = 'PUT',
  DELETE = 'DELETE',
  PATCH = 'PATCH',
  NONE = 'NONE', // For routes that don't require a method
  ALL = 'ALL', // For routes that can accept any method
}

export interface BoltApiRoute {
  path: string;
  method: BOLTApiRouteMethods;
  description: string;
  params?: string[]; // Optional array of path parameters (e.g., [':id']).  
                    // Path parameter notation should be used. eg ':id'
                   // This allows for dynamic parameters in query strings.
}

// Tenant URL format: https://{tenant}.{domain}.com and is provided by the user via environment variables.
// The tenant URL is the base URL for the BOLT API and should be set in the environment variable {BOLT_TENANT_URL}.
// Example: https://some-tenant.bolt.com
// Full URL format is : {tenantUrl}/{apiRoot.path}/{apiVersion}/{route.path}?{?queryString}
// This complexity is handled by the BOLTApi class, which constructs the full URL for API requests.
// To add new routes, simply add them to the BoltApiRoutes object below as a BoltApiRoute.
// The API version is prepended to the path by the BOLTApi class, so it should not be included in the path.
// Updates to the API version should be reflected in the BOLTApi class.
export const BoltApiRoutes = {
  // Base API Route for tenant BOLT site.  This is the root of the API.  The tenant URL is still required.
  // The API version is prepended to the path by the BOLTApi class.
  apiRoot: {
    path:'/boltAppRoot/api/',
    method: BOLTApiRouteMethods.NONE,
    description: 'Base route for the Bolt API, returns API version and available endpoints.',
  } as BoltApiRoute,
  // Authentication & User
  login: {
    path: '/login/',
    method: BOLTApiRouteMethods.POST,
    description: 'Authenticates a user and establishes a session.',
  } as BoltApiRoute,
  me: {
    path: '/me/',
    method: BOLTApiRouteMethods.GET,
    description: 'Retrieves details about the currently authenticated user.',
  } as BoltApiRoute,
  usersById: {
    path: '/users/',
    method: BOLTApiRouteMethods.GET,
    description: 'Retrieves details for a specific user by ID.',
    params: [':id'], // Path parameter for user ID
  } as BoltApiRoute,

  // Core Data
  // Loads by ID has :id as a path parameter
  loadsById: {
    path: '/loads/',
    method: BOLTApiRouteMethods.GET,
    description: 'Retrieves details for a specific load by ID.',
    params: [':id'], // Path parameter for load ID
  } as BoltApiRoute,
  loadSegments: {
    path: '/load_segments/',
    method: BOLTApiRouteMethods.GET,
    description: 'Retrieves load segments, typically filtered by load ID.',
  } as BoltApiRoute,
  // Truck Breadcrumbs by ID has :load_id as a path parameter
  gpsBreadcrumbsByLoadId: {
    path: '/breadcrumbs/',
    method: BOLTApiRouteMethods.GET,
    description: 'Retrieves breadcrumb data for a specific load by ID.',
    params: [':load_id'], // Path parameter for truck ID
  } as BoltApiRoute,
  loadBoard:{
    path: '/load_board/',
    method: BOLTApiRouteMethods.GET,
    description: 'Retrieves the load board shipments, typically filtered by various parameters.',
    params: [ ':load_status'], // Parameter for load board shipment status
  } as BoltApiRoute,
  loadBoardShipments: {
    path: '/load_board/shipments/',
    method: BOLTApiRouteMethods.GET,
    description: 'Retrieves shipments from the load board, filtered by status.',
    params: [':load_status'], // Parameter for load board shipment status
  } as BoltApiRoute,
  shipmentsByLoadId: {
    path: '/shipments/',
    method: BOLTApiRouteMethods.GET,
    description: 'Retrieves shipment data for a specific load by ID.',
    params: [':load_id'], // Parameter for load ID
  } as BoltApiRoute,
  shipTo: {
    path: '/shipto/',
    method: BOLTApiRouteMethods.GET,
    description: 'Retrieves all shipping locations.'
  } as BoltApiRoute,
  shipToById: {
    path: '/shipto/',
    method: BOLTApiRouteMethods.GET,
    description: 'Retrieves a specific shipping location by ID.',
    params: [':id'], // Parameter for shipping location ID
  } as BoltApiRoute,
  billToLocations: {
    path: '/billto/',
    method: BOLTApiRouteMethods.GET,
    description: 'Retrieves all billing locations (Customers).',
  } as BoltApiRoute,
  equipment:{
    path: '/equipment/',
    method: BOLTApiRouteMethods.GET,
    description: 'Retrieves all equipment, dollies, containers, etc., in the database.',
  } as BoltApiRoute,
  segments:{
    path: '/segments/',
    method: BOLTApiRouteMethods.GET,
    description: 'Retrieves all segments for a specific load.',
    params: [':load_id'], // Parameter for load ID
  } as BoltApiRoute,
  trailers:{
    path: '/trailers/',
    method: BOLTApiRouteMethods.GET,
    description: 'Retrieves all trailers in the database.',
  } as BoltApiRoute,
  trailersById:{
    path: '/trailers/',
    method: BOLTApiRouteMethods.GET,
    description: 'Retrieves a specific trailer by ID.',
    params: [':id'], // Parameter for trailer ID
  } as BoltApiRoute,
  trucks:{
    path: '/trucks/',
    method: BOLTApiRouteMethods.GET,
    description: 'Retrieves all trucks in the database.',
  } as BoltApiRoute,
  trucksById: {
    path: '/trucks/',
    method: BOLTApiRouteMethods.GET,
    description: 'Retrieves a specific truck by ID.',
    params: [':id'], // Parameter for truck ID
  } as BoltApiRoute,
  users: {
    path: '/users/',
    method: BOLTApiRouteMethods.GET,
    description: 'Retrieves all users in the system.',
  } as BoltApiRoute,
  
  // Additional routes can be added here as needed
} as const;