
export enum eCookieResults {
    FAILURE,
    NOT_FOUND,
    INVALID_COOKIE_STRUCT,
    EXPIRED,
    SET,
    SUCCESS
}
/**
 * @singleton
 * BOLTCookieManager is a singleton class that manages the authentication cookie for the BOLT API.
 */
export class BOLTCookieManager {
    private static instance: BOLTCookieManager | null = null;
    private static cookie: string | null = null;
    private static authenticatedAt: Date | null = null;
    /**
     * Private constructor to enforce singleton pattern.
     * Throws an error if an instance already exists.
     * @throws {Error} If an instance of BOLTCookieManager already exists.
     */
    constructor() {
        if( BOLTCookieManager.instance) {
            throw new Error("BOLTCookieManager is a singleton class. Use getInstance() to access it.");
        }
        console.log("BOLTCookieManager instance created.");
        BOLTCookieManager.instance = this;
    }
    /**
     * 
     * @returns The singleton instance of BOLTCookieManager.
     */
    public static getInstance(): BOLTCookieManager {
        if (!this.instance) {
            BOLTCookieManager.instance = new BOLTCookieManager();
        }
        return BOLTCookieManager.instance!;
    }

    public static setCookie(cookieValue:string, authenticatedAt: Date): eCookieResults {
        try{
            if (!this.instance) {
                BOLTCookieManager.getInstance(); // Ensure the singleton instance is created
            }
            if (!cookieValue || !authenticatedAt) {
                return eCookieResults.INVALID_COOKIE_STRUCT;
            }
            BOLTCookieManager.cookie = cookieValue;
            BOLTCookieManager.authenticatedAt = authenticatedAt;
            return eCookieResults.SET;
        } catch (error) {
            console.error("Error setting cookie:", error);
            return eCookieResults.FAILURE;
        }
    }

    public static getCookie(): string | null {
        if (!this.instance) {
            BOLTCookieManager.getInstance(); // Ensure the singleton instance is created
        }
        return BOLTCookieManager.cookie;
    }

    public static getAuthenticatedAt(): Date | null {
        if (!this.instance) {
            BOLTCookieManager.getInstance(); // Ensure the singleton instance is created
        }
        return BOLTCookieManager.authenticatedAt;
    }

    public static isExpired(hours:number = 8): boolean {
        if(!this.instance) {
            BOLTCookieManager.getInstance(); // Ensure the singleton instance is created
        }
        if (!BOLTCookieManager.authenticatedAt) {
            return true; // No authentication time means expired
        }
        const currentTime = new Date();
        const ageHours = (currentTime.getTime() - BOLTCookieManager.authenticatedAt.getTime()) / (1000 * 60 * 60);
        return ageHours > hours; // Assuming a cookie lifetime of `hours`
    }

    public static isValid(): boolean {
        if (!this.instance) {
            BOLTCookieManager.getInstance(); // Ensure the singleton instance is created
        }
        return BOLTCookieManager.cookie !== null && !BOLTCookieManager.isExpired();
    }

    public static deleteCookie(): eCookieResults {
        try{
            if (!this.instance) {
                BOLTCookieManager.getInstance(); // Ensure the singleton instance is created
            }
            BOLTCookieManager.cookie = null;
            BOLTCookieManager.authenticatedAt = null;
            return eCookieResults.SUCCESS;
        } catch (error) {
            console.error("Error deleting cookie:", error);
            return eCookieResults.FAILURE;
        }
    }
}