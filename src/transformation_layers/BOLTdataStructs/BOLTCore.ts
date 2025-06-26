import type { CoreAddress, Identifiable } from "../DBcore/coreDbInterfaces";

export interface BOLTdbEntity {}

export interface BOLTCoreIdentifiable extends BOLTdbEntity, Identifiable {}

export interface BOLTCoreGeoLocation extends BOLTdbEntity{
    longitude:number,
    latitude:number
}

export interface TerminalIdentifiable extends BOLTdbEntity {
    terminal_id:number,
}

export interface BOLTCoreAddress extends CoreAddress,
BOLTCoreIdentifiable {
    postal_code?:number | string,
    geo:BOLTCoreGeoLocation,
}

export interface BOLTCodeable extends BOLTdbEntity {
    code:string,
}

export interface BOLTNamed extends BOLTdbEntity {
    name:string,
}

export interface BOLTCommentable extends BOLTdbEntity {
    comments?:string,
}

export interface BOLTActive extends BOLTdbEntity {
    is_active:boolean,
}

export interface BOLTLocalDirections extends BOLTdbEntity {
    local_directions?:string,
}

export interface BOLTrelationalAddress extends BOLTdbEntity {
    parent_address_id?:number,
    child_address_ids:number [],
}

export interface BOLTCoreArrivalTimes extends BOLTdbEntity {
    arrive_at?:string,
    depart_at?:string,
}

export interface BOLTCoreCodeIdNamed extends BOLTCoreIdentifiable,
BOLTCodeable,
BOLTNamed {
    code:string,
    id:number,
    name:string,
}

export interface BOLTCoreCurrentLocationRecord extends BOLTCoreIdentifiable {
    geo?:BOLTCoreGeoLocation,
    speed?:number,
    heading?:number,
    data_supplier?:number,
    temperature?:number,
    description?:number,
    recorded_at?:string,
    is_ignition_on:boolean,
    odometer?:number,
}

export interface BOLTCoreTruckSpecification extends BOLTdbEntity {
    year?:number | string,
    price?:number | string,
    vin?:string,
    model?:string,
    make?:string
}

export interface BOLTCoreVehicleRegistration extends BOLTdbEntity {
    expiration?:string,
    country?:string,
    state?:string,
    tag?:string
}

export interface BOLTCoreEquipmentDimensions extends BOLTdbEntity {
    length?:number | string,
    width?: number | string,
    height?: number| string
}

export interface BOLTCoreEquipmentRules extends BOLTdbEntity {
    is_container:boolean,
    has_fifth_wheel:boolean,
    is_power_unit:boolean,
    is_chassis:boolean,
    is_trailer:boolean
}

export interface BOLTCoreEquipmentDetails extends BOLTCoreIdentifiable,
BOLTNamed {
    dimensions:BOLTCoreEquipmentDetails,
    rules:BOLTCoreEquipmentRules,
}

export interface BOLTCoreLoadTruck extends BOLTCoreIdentifiable,
BOLTActive,
BOLTNamed {
    last_dot_inspection:string,
    last_in_service?:string,
    is_cross_terminal:boolean,
    owned_by?: any,
    last_out_of_service?:string,
    last_breadcrumb?:string,
    primary_terminal:Object
    is_ifta:boolean,
    registration:BOLTCoreVehicleRegistration,
    insurance_expiration?:string,
    type:BOLTCoreEquipmentDetails
}   