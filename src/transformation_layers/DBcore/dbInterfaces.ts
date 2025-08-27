import type { iCoreCreatedAt, iCoreDeactivatable, iCoreIdentifiable, iCoreAddress, iCoreCommonAuditFields } from "./coreDbInterfaces"

export interface iStopType extends iCoreCommonAuditFields {
    stop_type_name:string,
}

export interface iAddressType extends iCoreCommonAuditFields {
    address_type_name:string,
}

export interface iLocationSource extends iCoreCommonAuditFields {
    location_source_name:string,
}

export interface iContactType extends iCoreCommonAuditFields {
    contact_type_name:string,
}

export interface iContact extends iCoreCommonAuditFields {
    contact_type:number,
    email?:string,
    mobile_phone?:string,
}

export interface iGeoLocation extends iCoreIdentifiable, iCoreDeactivatable, iCoreCreatedAt {
    location_source:number,
    latitude:number,
    longitude:number,
    recorded_at?:Date,
}

export interface iAddress extends iCoreCommonAuditFields, iCoreAddress {
    address_contact_ids?:number[],
    postal_code:string,
    country:string,
    address_type:number,
    location_id:number,
}

export interface iAuthority extends iCoreCommonAuditFields {
    authority_name:string,
    dot_number:string,
    address_id:number,
}

export interface iDivision extends iCoreCommonAuditFields {
    division_name:string,
    tms_terminal_id:number,
    authority_id:number,
    address_id:number,
}

export interface iTerminal extends iCoreCommonAuditFields {
    tms_id:number,
    terminal_name:string,
    division_id:number,
    address_id:number,
}

export interface iTrailer extends iCoreCommonAuditFields {
    tms_id:number,
    trailer_name:string,
    terminal_id:number,
    division_id:number,
}

export interface iTruck extends iCoreCommonAuditFields {
    tms_id:number,
    telematic_id?:string,
    truck_name:string,
    division_id:number,
    terminal_id:number,
    current_driver_id?:number,
    trailer_1_id?:number,
    trailer_2_id?:number,
    current_location_id:number,
    vin?:string,
    license_plate?:string,
    license_plate_state?:string,
}

export interface iDriver extends iCoreCommonAuditFields {
    first_name:string,
    last_name:string,
    license_number:string,
    license_state:string,
    division_id:number,
    terminal_id:number,
    tms_id:number,
    telematic_id?:string,
    current_truck_serial_id?:number,
    contact_id?:number,
}

export interface iStops extends iCoreCommonAuditFields {
    address_id:number,
    stop_type_id:number,
    stop_purchase_orders?:string[],
    stop_sequence:number,
    tms_pro_number?:string,
    stop_driver_id:number,
    stop_truck_id:number,
    sched_arrival?:Date,
    actl_arrival?:Date,
    sched_dept?:Date,
    actl_dept?:Date,
    is_completed:boolean,
}

export interface iLoad extends iCoreCommonAuditFields {
    load_purchase_orders?:string[],
    load_stop_ids?:number[],
    tms_pro_number?:string,
    assigned_driver_ids?:number[],
    assigned_truck_ids?:number[],
    trailer_ids?:number[],
    terminal_id:number,
    division_id:number,
}