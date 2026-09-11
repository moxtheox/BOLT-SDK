import type { iLocation, iRegistration, iType } from "./BOLTInterfaces";

/**
 * Represents an emergency contact person.
 */
export interface iEmergencyContact {
    phone: string;
    name: string;
}

/**
 * Represents workers' compensation details.
 */
export interface iWorkersCompensation {
    expiration: string | null;
    account: string | null;
}

/**
 * Represents secondary terminal IDs categorized by permissions/actions.
 */
export interface iTerminalSecondaries {
    modify: number[];
    view: number[];
}

/**
 * Represents terminal assignments and details, utilizing iLocation.
 */
export interface iUserTerminalInfo {
    primary_id: number;
    primary: iLocation; //
    secondaries: iTerminalSecondaries;
}

/**
 * Represents work-related details, dates, and organizational assignments for the user.
 */
export interface iWorkInformation {
    mobile_phone: string;
    terminal: iUserTerminalInfo;
    termination_date: string | null;
    hire_date: string;
    desk_phone: string;
    workers_compensation: iWorkersCompensation;
    review_date: string | null;
    email: string;
    rehire_date: string | null;
}

/**
 * Represents personal details for the user, reusing iLocation for the address structure.
 */
export interface iPersonalInformation {
    mobile_phone: string | null;
    emergency_contact: iEmergencyContact;
    home_phone: string;
    email: string | null;
    birthday: string;
    address: iLocation; //
}

/**
 * Represents the BOLT return object for the /me API endpoint (User Profile).
 */
export interface iUserMe {
    /** Optional name suffix (e.g., Jr., Sr.) */
    suffix: string | null;
    
    /** List of permissions granted to the user */
    permissions: PermissionValue[];
    
    /** Unique employee identifier code */
    employee_id: string;
    
    /** System username */
    user_name: string;
    
    /** Indicates whether the user account is active */
    is_active: boolean;
    
    /** User's last name */
    last_name: string;
    
    /** Default landing route path */
    landing_path: string;
    
    /** User's first name */
    first_name: string;
    
    /** Full display name */
    name: string;
    
    /** Personal information object containing contact and address details */
    personal: iPersonalInformation;
    
    /** Work information object containing employment and terminal details */
    work: iWorkInformation;
    
    /** Optional middle name */
    middle_name: string | null;
    
    /** Unique database identifier */
    id: number;
}

/**
 * Represents geographic coordinates for breadcrumbs, allowing null values.
 */
export interface iBreadcrumbGeo {
    latitude: number | null;
    longitude: number | null;
}

/**
 * Represents the last recorded tracking breadcrumb for the equipment.
 */
export interface iLastBreadcrumb {
    geo: iBreadcrumbGeo | null;
    speed: number | null;
    heading: number | null;
    data_supplier: string | null;
    temperature: number | null;
    description: string | null;
    recorded_at: string | null;
    received_at: string | null;
    is_ignition_on: boolean;
    id: number | null;
    odometer: number | null;
}

/**
 * Represents detailed specifications of the equipment.
 */
export interface iEquipmentSpecification {
    vin: string | null;
    model: string | null;
    year: number | string | null;
    price: number | null;
    make: string | null;
}

/**
 * Represents the BOLT return object for equipment endpoints.
 */
export interface iEquipment {
    /** Last Department of Transportation (DOT) inspection date/string */
    last_dot_inspection: string;
    
    /** Timestamp when the equipment was last put into service */
    last_in_service: string | null;
    
    /** Indicates if the equipment operates across multiple terminals */
    is_cross_terminal: boolean;
    
    /** Technical specifications of the equipment */
    specification: iEquipmentSpecification;
    
    /** Indicates whether the equipment item is active */
    is_active: boolean;
    
    /** Equipment unit name or number */
    name: string;
    
    /** Owner identifier or name */
    owned_by: string | number | null;
    
    /** Timestamp when the equipment was last taken out of service */
    last_out_of_service: string | null;
    
    /** Last tracking telemetry breadcrumb */
    last_breadcrumb: iLastBreadcrumb;
    
    /** Primary terminal location details utilizing iLocation */
    primary_terminal: iLocation;
    
    /** Indicates whether the equipment is subject to IFTA */
    is_ifta: boolean;
    
    /** Unique database identifier for the equipment */
    id: number;
    
    /** Registration details for the equipment */
    registration: iRegistration;
    
    /** Insurance expiration date */
    insurance_expiration: string | null;
    
    /** Equipment type, dimensions, and operational rules */
    type: iType;
}

/**
 * Represents driver certification and document expiration dates.
 */
export interface iDriverExpirations {
    usa_hazmat: string | null;
    visa: string | null;
    twic: string | null;
    license: string | null;
    canada_hazmat: string | null;
    passport: string | null;
    medical: string | null;
}

/**
 * Represents the data supplier details for hours of service.
 */
export interface iHssDataSupplier {
    id: number;
    name: string;
}

/**
 * Represents hours of service (HOS) metrics and duty status.
 */
export interface iHoursOfService {
    data_supplier: iHssDataSupplier;
    drive_remaining: number;
    updated_at: string;
    duty_status: string;
    on_duty_remaining: number;
}

/**
 * Represents driver's license details.
 */
export interface iDriverLicense {
    expiration: string | null;
    state: string | null;
    code: string | null;
    class: string | null;
    endorsements: string[];
}

/**
 * Represents specific driver-related profile properties.
 */
export interface iDriverProfile {
    expiration: iDriverExpirations;
    primary_dispatcher: string | number | null;
    last_drug_test: string | null;
    hours_of_service: iHoursOfService;
    last_mvr: string | null;
    license: iDriverLicense;
    type: string;
}

/**
 * Represents terminal assignments for a user, handling optional full location objects.
 */
export interface iStandardUserTerminalInfo {
    primary_id: number;
    primary?: iLocation;
    secondaries: {
        modify: number[];
        view: number[];
    };
}

/**
 * Represents work information for a standard user, supporting optional fields.
 */
export interface iStandardWorkInformation {
    mobile_phone: string | null;
    terminal: iStandardUserTerminalInfo;
    termination_date: string | null;
    hire_date: string | null;
    desk_phone: string | null;
    workers_compensation: {
        expiration: string | null;
        account: string | null;
    };
    review_date: string | null;
    email: string | null;
    rehire_date: string | null;
}

/**
 * Represents a standard user return object (e.g., from /users endpoints), 
 * which includes driver-specific tracking attributes and optional fields compared to iUserMe.
 */
export interface iUserStandard {
    /** Optional name suffix */
    suffix: string | null;
    
    /** List of permissions granted to the user */
    permissions: PermissionValue[];
    
    /** Unique employee identifier code */
    employee_id: string;
    
    /** Optional driver profile metrics and qualifications */
    driver?: iDriverProfile;
    
    /** System username (can be null for non-login driver records) */
    user_name: string | null;
    
    /** Indicates whether the user account is active */
    is_active: boolean;
    
    /** User's last name */
    last_name: string;
    
    /** Default landing route path */
    landing_path: string;
    
    /** User's first name */
    first_name: string;
    
    /** Full display name */
    name: string;
    
    /** Personal information including address */
    personal: {
        mobile_phone: string | null;
        emergency_contact: {
            phone: string | null;
            name: string | null;
        };
        home_phone: string | null;
        email: string | null;
        birthday: string | null;
        address: iLocation;
    };
    
    /** Work information and terminal mapping */
    work: iStandardWorkInformation;
    
    /** Optional middle name */
    middle_name: string | null;
    
    /** Unique database identifier */
    id: number;
}

export const Permissions = Object.freeze({
    EQUIPMENT_EDIT: "equipment:edit",
    INVOICE_APPROVE: "invoice:approve",
    INVOICE_CREATE: "invoice:create",
    INVOICE_DELETE: "invoice:delete",
    INVOICE_TRANSFER: "invoice:transfer",
    EDI_INVOICE_TRANSFER: "edi:invoice:transfer",
    INVOICE_PRINT: "invoice:print",
    INVOICE_EMAIL: "invoice:email",
    INVOICE_REBILL: "invoice:rebill",
    PO_BILLING_EDIT: "purchase_order:billing:edit",
    LOAD_EDIT: "load:edit",
    PO_BILLING_VIEW: "purchase_order:billing:view",
    SETTLEMENT_APPROVE: "settlement:approve",
    SETTLEMENT_EDIT: "settlement:edit",
    SETTLEMENT_PAY: "settlement:pay",
    SETTLEMENT_PRINT: "settlement:print",
    USER_EDIT: "user:edit",
    USER_SAFETY_COMMENT_EDIT: "user:safety_comment:edit",
    USER_COMPENSATION_EDIT: "user:compensation:edit",
    USER_CONTACT_EDIT: "user:contact:edit",
    USER_CREDENTIAL_EDIT: "user:credential:edit",
    USER_DOCUMENT_EDIT: "user:document:edit",
    USER_DRIVER_EDIT: "user:driver:edit",
    USER_EMPLOYEE_EDIT: "user:employee:edit",
    USER_PERMISSION_EDIT: "user:permission:edit",
    USER_TERMINAL_EDIT: "user:terminal:edit",
    USER_TIMEOFF_EDIT: "user:timeoff:edit"
});

export type PermissionValue = typeof Permissions[keyof typeof Permissions];