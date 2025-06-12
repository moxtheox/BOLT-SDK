import { BoltApiRoutes, type BoltApiRoute } from "./BoltAPIRoutes";
import { BOLTCookieManager, eCookieResults } from "./BOLTCookieManager";


interface ApiResponse<T> {
  message: string;
  data: T;
  type: string;
}

enum BOLTApiLoadBoardShipmentStatus {
  ALL = 'all',
  IN_TRANSIT = 'intransit',
  PENDING = 'pending',
  RECENTLY_COMPLETED = 'recently_completed',
  SCHEDULED = 'scheduled',
}

export class BOLTApi {
    // Base URL for the BOLT API
    private static tenantUrl :string | null = null;
    // Username for authentication
    private static username :string | null = null; 
    // Password for authentication
    private static password :string | null = null; 
    // API version
    static readonly version = 'v1';
    /**
     * 
     * @param username Optional username for authentication. If not provided, it will use the environment variable BOLT_USERNAME.
     * @param password Optional password for authentication. If not provided, it will use the environment variable BOLT_PASSWORD.
     * @throws {Error} If the required variables are not present.
     * @description
     * 
     */
    constructor(username?: string, password?: string) {
        if(!BOLTApi.username){
            BOLTApi.username = username ?? process.env.BOLT_USER_NAME ?? ''
        }
        if(!BOLTApi.tenantUrl) {
            BOLTApi.tenantUrl = process.env.BOLT_TENANT_URL ?? '';
        }
        if(!BOLTApi.password) {
            BOLTApi.password = password ?? process.env.BOLT_USER_PASSWORD ?? '';
        }
        // Validate that the required variables are set
        if (!BOLTApi.tenantUrl || !BOLTApi.username || !BOLTApi.password) {
            throw new Error('Missing required variables: BOLT_TENANT_URL, BOLT_USER_NAME || username, BOLT_USER_PASSWORD || password');
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
     * Authenticate verifies that the BOLT Authorization cookie is set.
     * If the cookie is not set, it attempts to authenticate using the provided username and password.
     * @returns A promise that resolves to an eCookieResults enum value indicating the result of the authentication.
     */
    public async authenticate(): Promise<eCookieResults> {
        if(!BOLTCookieManager.isValid()){
            const body = {
                username: BOLTApi.username,
                password: BOLTApi.password,
            };
            const authAt = new Date();
            const resp = await this.makeApiRequest<any>(BoltApiRoutes.login, body);
            const setCookieHeader = resp.headers.get('set-cookie');
            if (setCookieHeader) {
                return BOLTCookieManager.setCookie(setCookieHeader, authAt);
            }
        } else {
            const cookie = BOLTCookieManager.getCookie();
            if (cookie) {
                // If the cookie is already set, we can return success
                return eCookieResults.SET;
            }
        }
        return eCookieResults.FAILURE;
    }
    /**
     * Method to retrieve the currently authenticated user's data.
     * @returns A promise that resolves to the user data of the currently authenticated user.
     */
    public async getMe(): Promise<ApiResponse<any>> {
        const r = await this.makeApiRequest<any>(BoltApiRoutes.me);
        return await r.json() as ApiResponse<any>;
    }
    /**
     * Fetches loads by ID from the BOLT API.
     * @param loadId - This corresponds to the PRO number in the BOLT system.
     * It must be a positive number.
     * @returns A promise that resolves to the load data.
     */
    public async getLoadsById(loadId: number): Promise<ApiResponse<any>> {
        if(!this.validateIdNumber(loadId)) {
            throw new Error('Invalid loadId. It must be a positive number.');
        }
        const r = await this.makeApiRequest<any>(BoltApiRoutes.loadsById, undefined, loadId);
        return await r.json() as ApiResponse<any>;
    }
    /**
     * @unsupported - Currently not implemented in the BOLT API. A call will return an 
     * error and error reference with a status code of 500.
     * @param loadId - This corresponds to the PRO number in the BOLT system.
     * It must be a positive number.
     * @returns 
     */
    public async getLoadBreadcrumbs(loadId: number): Promise<ApiResponse<any>> {
        if(!this.validateIdNumber(loadId)) {
            throw new Error('Invalid loadId. It must be a positive number.'+`  ${loadId} was provided.`);
        }
        const r = await this.makeApiRequest<any>(BoltApiRoutes.gpsBreadcrumbsByLoadId, undefined, loadId);
        return await r.json() as ApiResponse<any>;
    }
    /**
     * Retrieves all load board shipments from the BOLT API.
     * @param status - The status of the load board shipments to retrieve.
     * The default is BOLTApiLoadBoardShipmentStatus.ALL, which retrieves all shipments.
     * @returns 
     */
    public async getLoadBoardShipments(
        status: BOLTApiLoadBoardShipmentStatus = BOLTApiLoadBoardShipmentStatus.ALL): Promise<ApiResponse<any>> {
        const r = await this.makeApiRequest<any>(BoltApiRoutes.loadBoardShipments, undefined, status);
        return await r.json() as ApiResponse<any>;
    }
    /**
     * Retrieves the load board shipments from the BOLT API.
     * @param status - The status of the load board shipments to retrieve.
     * The default is BOLTApiLoadBoardShipmentStatus.ALL, which retrieves all shipments.
     * @returns API response containing the load board shipments.
     */
    public async GetLoadBoard(
        status: BOLTApiLoadBoardShipmentStatus = BOLTApiLoadBoardShipmentStatus.ALL): Promise<ApiResponse<any>> {
        const r = await this.makeApiRequest<any>(BoltApiRoutes.loadBoardShipments, undefined, status);
        return await r.json() as ApiResponse<any>;
    }
    /**
     * Retrieves user data by user ID from the BOLT API.
     * @param userId - The ID of the user to retrieve.
     * It must be a positive number.
     * @returns User data for the specified user ID.
     * @throws {Error} If the userId is not a positive number.
     */
    public async getUsersById(userId: number): Promise<ApiResponse<any>> {
        if(this.validateIdNumber(userId)) {
            const r = await this.makeApiRequest<any>(BoltApiRoutes.usersById, undefined, userId);
            return await r.json() as ApiResponse<any>;
        }
        throw new Error('Invalid userId. It must be a positive number.');
    }
    /**
     * Retrieves load segments from the BOLT API.
     * @returns A promise that resolves to the load segments data.
     */
    public async getLoadSegments(): Promise<ApiResponse<any>> {
        const r = await this.makeApiRequest<any>(BoltApiRoutes.loadSegments);
        return await r.json() as ApiResponse<any>;
    }
    /**
     * Retrieves shipments associated with a specific load ID from the BOLT API.
     * @param loadId - The ID of the load for which to retrieve shipments.
     * It must be a positive number.
     * @returns Shipments associated with the specified load ID.
     * @throws {Error} If the loadId is not a positive number.
     */
    public async getShipmentsByLoadId(loadId: number): Promise<ApiResponse<any>> {
        if(!this.validateIdNumber(loadId)) {
            throw new Error('Invalid loadId. It must be a positive number.');
        }
        const r = await this.makeApiRequest<any>(BoltApiRoutes.shipmentsByLoadId, undefined, loadId);
        return await r.json() as ApiResponse<any>;
    }
    /**
     * Retrieves the shipTo data from the BOLT API.
     * @returns A promise that resolves to the shipTo data from the BOLT API.
     */
    public async getShipTo(): Promise<ApiResponse<any>> {
        const r = await this.makeApiRequest<any>(BoltApiRoutes.shipTo);
        return await r.json() as ApiResponse<any>;
    }
    /**
     * Retrieves specific shipTo data by shipToId from the BOLT API.
     * @param shipToId - The ID of the shipTo to retrieve.
     * It must be a positive number.
     * @returns Specific shipTo data for the given shipToId.
     * @throws {Error} If the shipToId is not a positive number.
     */
    public async getShipToById(shipToId: number): Promise<ApiResponse<any>> {
        if(!this.validateIdNumber(shipToId)) {
            throw new Error('Invalid shipToId. It must be a positive number.');
        }
        const r = await this.makeApiRequest<any>(BoltApiRoutes.shipToById, undefined, shipToId);
        return await r.json() as ApiResponse<any>;
    }
    /**
     * Retrieves the billTo locations data from the BOLT API.
     * @returns A promise that resolves to the billTo locations data from the BOLT API.
     */
    public async getBillToLocations(): Promise<ApiResponse<any>> {
        const r = await this.makeApiRequest<any>(BoltApiRoutes.billToLocations);
        return await r.json() as ApiResponse<any>;
    }
    /**
     * Retrieves all Equipment, such as dollies, from the BOLT API.
     * @returns A promise that resolves to the billTo location data for the specified ID.
     */
    public async getEquipment(): Promise<ApiResponse<any>> {
        const r = await this.makeApiRequest<any>(BoltApiRoutes.equipment);
        return await r.json() as ApiResponse<any>;
    }
    /**
     * Retrieves all segments for a specific load from the BOLT API.
     * @param loadId - The ID of the load for which to retrieve segments.
     * It must be a positive number.
     * @returns Load segments for the specified load ID.
     * @throws {Error} If the loadId is not a positive number.
     */
    public async getSegments(loadId: number): Promise<ApiResponse<any>> {
        if(!this.validateIdNumber(loadId)) {
            throw new Error('Invalid loadId. It must be a positive number.');
        }
        const r = await this.makeApiRequest<any>(BoltApiRoutes.segments, undefined, loadId);
        return await r.json() as ApiResponse<any>;
    }
    /**
     * Retrieves all trailers from the BOLT API.
     * @returns A promise that resolves to the trailers data from the BOLT API.
     */
    public async getTrailers(): Promise<ApiResponse<any>> {
        const r = await this.makeApiRequest<any>(BoltApiRoutes.trailers);
        return await r.json() as ApiResponse<any>;
    }
    /**
     * Retrieves a specific trailer by ID from the BOLT API.
     * @param trailerId - The ID of the trailer to retrieve.
     * It must be a positive number.
     * @returns Trailer data for the specified trailer ID.
     * @throws {Error} If the trailerId is not a positive number.
     */
    public async getTrailersById(trailerId:number): Promise<ApiResponse<any>> {
        if(!this.validateIdNumber(trailerId)) {
            throw new Error('Invalid trailerId. It must be a positive number.');
        }
        const r = await this.makeApiRequest<any>(BoltApiRoutes.trailers, undefined, trailerId);
        return await r.json() as ApiResponse<any>;
    }
    /**
     * Retrieves all trucks from the BOLT API.
     * @returns A promise that resolves to the trucks data from the BOLT API.
     */
    public async getTrucks(): Promise<ApiResponse<any>> {
        const r = await this.makeApiRequest<any>(BoltApiRoutes.trucks);
        return await r.json() as ApiResponse<any>;
    }
    /**
     * Retrieves a specific truck by ID from the BOLT API.
     * @param truckId - The ID of the truck to retrieve.
     * It must be a positive number.
     * @returns Truck data for the specified truck ID.
     */
    public async getTrucksById(truckId:number): Promise<ApiResponse<any>> {
        if(!this.validateIdNumber(truckId)) {
            throw new Error('Invalid truckId. It must be a positive number.');
        }
        const r = await this.makeApiRequest<any>(BoltApiRoutes.trucksById, undefined, truckId);
        return await r.json() as ApiResponse<any>;
    }
    /**
     * Retrieves all users from the BOLT API.
     * @returns A promise that resolves to the users data from the BOLT API.
     */
    public async getUsers(): Promise<ApiResponse<any>> {
        const r = await this.makeApiRequest<any>(BoltApiRoutes.users);
        return await r.json() as ApiResponse<any>;
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
    private async makeApiRequest<T>(bar: BoltApiRoute, body?: any, ...args: any):Promise<Response> {
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
     * The headers include 'Content-Type', 'Accept', and optionally 'Cookie' if includeAuth is true.
     */
    private makeStdHeaders(includeAuth:boolean = true): Headers {
        const headers = new Headers();
        headers.set('Content-Type', 'application/json');
        headers.set('Accept', '*/*');
        if (includeAuth) {
            const cookie = BOLTCookieManager.getCookie();
            if (cookie) {
                headers.set('Cookie', cookie);
            }
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

const api = new BOLTApi();
if(await api.authenticate() === eCookieResults.SET) {
    console.log(await api.GetLoadBoard(BOLTApiLoadBoardShipmentStatus.IN_TRANSIT));
}
