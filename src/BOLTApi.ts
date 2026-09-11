import type { iBOLTLoadBoardEntry, iLocation } from "./interfaces/BOLTInterfaces";
import type { iLoadSegment } from "./interfaces/boltLoadSegment"
import { BoltApiRoutes, type BoltApiRoute } from "./BoltAPIRoutes";
import type { iEquipment, iUserMe, iUserStandard } from "./interfaces/BOLTUserInfo";


export interface BOLTApiResponse<T> {
  message: string;
  data: T[];
  type: string;
}

export enum BOLTApiLoadBoardShipmentStatus {
  ALL = 'all',
  IN_TRANSIT = 'intransit',
  PENDING = 'pending',
  RECENTLY_COMPLETED = 'recently_completed',
  SCHEDULED = 'scheduled',
  ALL_ASSIGNED = 'intransit,scheduled',
}

export class BOLTApi {
    // Base URL for the BOLT API
    private static tenantUrl :string | null = null;
    // API version
    static readonly version = 'v1';
    /**
     * @throws {Error} If the required variables are not present.
     * @description
     * 
     */
    constructor() {
        if(!BOLTApi.tenantUrl) {
            BOLTApi.tenantUrl = process.env.BOLT_TENANT_URL ?? '';
        }
        // Validate that the required variables are set
        if (!BOLTApi.tenantUrl || process.env.BOLT_TOKEN === undefined) {
            throw new Error('Missing required variables: BOLT_TENANT_URL, BOLT_TOKEN');
        }
    }
    /**
     * @private
     * Returns the API root path for the BOLT API.
     * This is constructed using the tenant URL, the API root path, and API version.
     * @returns The full API root path as a string.
     */
    private getApiRootPath(): string {
        return `${BOLTApi.tenantUrl}${BoltApiRoutes.apiRoot.path}${BOLTApi.version}`;
    }
    /**
     * @private
     * Validates that an ID is a positive number.
     * @param id - The ID to validate.
     */
    private validateIdNumber(id: number):boolean {
        return typeof id === 'number' && id > 0;
    }
    /**
     * Method to retrieve the currently authenticated user's data.
     * @returns A promise that resolves to the user data of the currently authenticated user.
     */
    public async getMe(): Promise<BOLTApiResponse<iUserMe>> {
        const r = await this.makeApiRequest<undefined>(BoltApiRoutes.me);
        return await r.json() as BOLTApiResponse<iUserMe>;
    }
    /**
     * Fetches loads by ID from the BOLT API.
     * @param loadId - This corresponds to the PRO number in the BOLT system.
     * It must be a positive number.
     * @returns A promise that resolves to the load data.
     */
    public async getLoadsById(loadId: number): Promise<BOLTApiResponse<any>> {
        if(!this.validateIdNumber(loadId)) {
            throw new Error('Invalid loadId. It must be a positive number.');
        }
        const r = await this.makeApiRequest<undefined>(BoltApiRoutes.loadsById, undefined, loadId);
        return await r.json() as BOLTApiResponse<any>;
    }
    /**
     * @unsupported - Currently not implemented in the BOLT API. A call will return an 
     * error and error reference with a status code of 500.
     * @param loadId - This corresponds to the PRO number in the BOLT system.
     * It must be a positive number.
     * @returns 
     */
    public async getLoadBreadcrumbs(loadId: number): Promise<BOLTApiResponse<any>> {
        if(!this.validateIdNumber(loadId)) {
            throw new Error('Invalid loadId. It must be a positive number.'+`  ${loadId} was provided.`);
        }
        const r = await this.makeApiRequest<undefined>(BoltApiRoutes.gpsBreadcrumbsByLoadId, undefined, loadId);
        return await r.json() as BOLTApiResponse<any>;
    }
    /**
     * Retrieves all load board shipments from the BOLT API.
     * @param status - The status of the load board shipments to retrieve.
     * The default is BOLTApiLoadBoardShipmentStatus.ALL, which retrieves all shipments.
     * @returns 
     */
    public async getLoadBoardShipments(
        status: BOLTApiLoadBoardShipmentStatus = BOLTApiLoadBoardShipmentStatus.ALL): Promise<BOLTApiResponse<any>> {
        const r = await this.makeApiRequest<undefined>(BoltApiRoutes.loadBoardShipments, undefined, status);
        return await r.json() as BOLTApiResponse<any>;
    }
    /**
     * Retrieves the load board shipments from the BOLT API.
     * @param status - The status of the load board shipments to retrieve.
     * The default is BOLTApiLoadBoardShipmentStatus.ALL, which retrieves all shipments.
     * @returns API response containing the load board shipments.
     */
    public async GetLoadBoard(
        status: BOLTApiLoadBoardShipmentStatus = BOLTApiLoadBoardShipmentStatus.ALL): Promise<BOLTApiResponse<iBOLTLoadBoardEntry>> {
        const r = await this.makeApiRequest<undefined>(BoltApiRoutes.loadBoardShipments, undefined, status);
        return await r.json() as BOLTApiResponse<iBOLTLoadBoardEntry>;
    }
    /**
     * Retrieves user data by user ID from the BOLT API.
     * @param userId - The ID of the user to retrieve.
     * It must be a positive number.
     * @returns User data for the specified user ID.
     * @throws {Error} If the userId is not a positive number.
     */
    public async getUsersById(userId: number): Promise<BOLTApiResponse<iUserStandard>> {
        if(this.validateIdNumber(userId)) {
            const r = await this.makeApiRequest<undefined>(BoltApiRoutes.usersById, undefined, userId);
            return await r.json() as BOLTApiResponse<iUserStandard>;
        }
        throw new Error('Invalid userId. It must be a positive number.');
    }
    /**
     * Retrieves load segments from the BOLT API.
     * @returns A promise that resolves to the load segments data.
     */
    public async getLoadSegments(): Promise<BOLTApiResponse<any>> {
        const r = await this.makeApiRequest<undefined>(BoltApiRoutes.loadSegments);
        return await r.json() as BOLTApiResponse<any>;
    }
    /**
     * Retrieves shipments associated with a specific load ID from the BOLT API.
     * @param loadId - The ID of the load for which to retrieve shipments.
     * It must be a positive number.
     * @returns Shipments associated with the specified load ID.
     * @throws {Error} If the loadId is not a positive number.
     */
    public async getShipmentsByLoadId(loadId: number): Promise<BOLTApiResponse<any>> {
        if(!this.validateIdNumber(loadId)) {
            throw new Error('Invalid loadId. It must be a positive number.');
        }
        const r = await this.makeApiRequest<undefined>(BoltApiRoutes.shipmentsByLoadId, undefined, loadId);
        return await r.json() as BOLTApiResponse<any>;
    }
    /**
     * Retrieves the shipTo data from the BOLT API.
     * @returns A promise that resolves to the shipTo data from the BOLT API.
     */
    public async getShipTo(): Promise<BOLTApiResponse<iLocation>> {
        const r = await this.makeApiRequest<undefined>(BoltApiRoutes.shipTo);
        return await r.json() as BOLTApiResponse<iLocation>;
    }
    /**
     * Retrieves specific shipTo data by shipToId from the BOLT API.
     * @param shipToId - The ID of the shipTo to retrieve.
     * It must be a positive number.
     * @returns Specific shipTo data for the given shipToId.
     * @throws {Error} If the shipToId is not a positive number.
     */
    public async getShipToById(shipToId: number): Promise<BOLTApiResponse<iLocation>> {
        if(!this.validateIdNumber(shipToId)) {
            throw new Error('Invalid shipToId. It must be a positive number.');
        }
        const r = await this.makeApiRequest<undefined>(BoltApiRoutes.shipToById, undefined, shipToId);
        return await r.json() as BOLTApiResponse<iLocation>;
    }
    /**
     * Retrieves the billTo locations data from the BOLT API.
     * @returns A promise that resolves to the billTo locations data from the BOLT API.
     */
    public async getBillToLocations(): Promise<BOLTApiResponse<iLocation>> {
        const r = await this.makeApiRequest<undefined>(BoltApiRoutes.billToLocations);
        return await r.json() as BOLTApiResponse<iLocation>;
    }
    /**
     * Retrieves all Equipment, such as dollies, from the BOLT API.
     * @returns A promise that resolves to the billTo location data for the specified ID.
     */
    public async getEquipment(): Promise<BOLTApiResponse<iEquipment>> {
        const r = await this.makeApiRequest<undefined>(BoltApiRoutes.equipment);
        return await r.json() as BOLTApiResponse<iEquipment>;
    }
    /**
     * Retrieves all segments for a specific load from the BOLT API.
     * @param loadId - The ID of the load for which to retrieve segments.
     * It must be a positive number.
     * @returns Load segments for the specified load ID.
     * @throws {Error} If the loadId is not a positive number.
     */
    public async getLoadSegmentsById(loadId: number): Promise<BOLTApiResponse<iLoadSegment>> {
        if(!this.validateIdNumber(loadId)) {
            throw new Error('Invalid loadId. It must be a positive number.');
        }
        const r = await this.makeApiRequest<undefined>(BoltApiRoutes.segments, undefined, loadId);
        return await r.json() as BOLTApiResponse<iLoadSegment>;
    }
    /**
     * Retrieves all trailers from the BOLT API.
     * @returns A promise that resolves to the trailers data from the BOLT API.
     */
    public async getTrailers(): Promise<BOLTApiResponse<iEquipment>> {
        const r = await this.makeApiRequest<undefined>(BoltApiRoutes.trailers);
        return await r.json() as BOLTApiResponse<any>;
    }
    /**
     * Retrieves a specific trailer by ID from the BOLT API.
     * @param trailerId - The ID of the trailer to retrieve.
     * It must be a positive number.
     * @returns Trailer data for the specified trailer ID.
     * @throws {Error} If the trailerId is not a positive number.
     */
    public async getTrailersById(trailerId:number): Promise<BOLTApiResponse<any>> {
        if(!this.validateIdNumber(trailerId)) {
            throw new Error('Invalid trailerId. It must be a positive number.');
        }
        const r = await this.makeApiRequest<undefined>(BoltApiRoutes.trailers, undefined, trailerId);
        return await r.json() as BOLTApiResponse<any>;
    }
    /**
     * Retrieves all trucks from the BOLT API.
     * @returns A promise that resolves to the trucks data from the BOLT API.
     */
    public async getTrucks(): Promise<BOLTApiResponse<any>> {
        const r = await this.makeApiRequest<undefined>(BoltApiRoutes.trucks);
        return await r.json() as BOLTApiResponse<any>;
    }
    /**
     * Retrieves a specific truck by ID from the BOLT API.
     * @param truckId - The ID of the truck to retrieve.
     * It must be a positive number.
     * @returns Truck data for the specified truck ID.
     */
    public async getTrucksById(truckId:number): Promise<BOLTApiResponse<any>> {
        if(!this.validateIdNumber(truckId)) {
            throw new Error('Invalid truckId. It must be a positive number.');
        }
        const r = await this.makeApiRequest<any>(BoltApiRoutes.trucksById, undefined, truckId);
        return await r.json() as BOLTApiResponse<any>;
    }
    /**
     * Retrieves all users from the BOLT API.
     * @returns A promise that resolves to the users data from the BOLT API.
     */
    public async getUsers(): Promise<BOLTApiResponse<iUserStandard>> {
        const r = await this.makeApiRequest<undefined>(BoltApiRoutes.users);
        return await r.json() as BOLTApiResponse<iUserStandard>;
    }
    /**
     * @private
     * Makes a generic API request to the BOLT API.
     * @param bar  - The API route to call.
     * @param body Optional body to send with the request.
     * If the route is not a POST or PUT request, this parameter can be omitted.
     * @param args These are the values to be placed into the URL query string.
     * The number of arguments must match the number of parameters defined in the route.
     * @returns Promise<Response> - The response from the API call.
     * @throws {Error} If the parameter count does not match the expected count for the route.
     */
    private async makeApiRequest<T>(bar: BoltApiRoute, body?: T, ...args: any):Promise<Response> {
        const includeAuth = bar.path !== BoltApiRoutes.login.path;
        const queryString = this.makeQueryString(bar, ...args);
        const url = `${this.getApiRootPath()}${bar.path}${queryString}`;
        const opts: RequestInit = this.makeStdOptions(bar, includeAuth);
        if (body) {
            opts.body = JSON.stringify(body);
        }
        const response = await fetch(url, opts);
        return response;
    }
    /**
     * @private
     * Constructs a query string for the API route based on the provided arguments.
     * @param rte - The API route to call.
     * @param args - These are the values to be placed into the URL query string.
     * The number of arguments must match the number of parameters defined in the route.
     * @returns - The constructed query string.
     * @throws {Error} If the parameter count does not match the expected count for the route,
     * or if a parameter in the BoltApiRoute is not a string.
     */
    private makeQueryString(rte:BoltApiRoute, ...args:any):string {
        let params = rte?.params;
        if (!params || params.length === 0) {
            return '';
        }
        const plen = params.length;
        if (plen !== args.length) {
            throw new Error(`Parameter count mismatch: expected ${plen} parameters, but got ${args.length} arguments.`);
        }
        const memoArray = new Array();
        for(let i = 0; i < plen; i++){
            if (typeof params[i] !== 'string' || (params[i] === undefined )) {
                throw new Error(`Invalid parameter at index ${i}: expected string, got ${typeof params[i]}`);
            }
            let key = params[i]?.startsWith(':') ? params[i]?.substring(1) : params[i];
            let param = `${key}=${args[i].toString()}`;
            memoArray.push(param);
        }
        return memoArray.length > 0 ?  '?' + memoArray.join('&'): '';
    }
    /**
     * @private
     * Constructs standard headers for the BOLT API requests.
     * @param includeAuth - Whether to include the authentication cookie in the headers.
     * If true, the authentication cookie will be included in the request headers.
     * @returns A headers object with standard headers for the BOLT API.
     * The headers include 'Content-Type', 'Accept', and optionally 'Authorization' if includeAuth is true.
     */
    private makeStdHeaders(includeAuth:boolean = true): Headers {
        const headers = new Headers();
        headers.set('Content-Type', 'application/json');
        headers.set('Accept', '*/*');
        if (includeAuth) {
            headers.set('Authorization',`Bearer ${process.env.BOLT_TOKEN}`);
        }
        return headers;
    }
    /**
     * @private
     * Constructs standard options for the BOLT API requests.
     * @param rte - The BOLT API route to call.
     * @param includeAuth - Whether to include the authentication cookie in the request headers.
     * @returns RequestInit object with standard options for the BOLT API request.
     * The options include the HTTP method and headers.
     */
    private makeStdOptions(rte:BoltApiRoute, includeAuth:boolean = true): RequestInit {
        return {
            method: rte.method,
            headers: this.makeStdHeaders(includeAuth)
        };
    }

    
}
