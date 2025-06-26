import type { CoreContact } from "../DBcore/coreDbInterfaces";
import type { BOLTActive, 
    BOLTCodeable, 
    BOLTCommentable, 
    BOLTCoreAddress, 
    BOLTCoreArrivalTimes, 
    BOLTCoreCodeIdNamed, 
    BOLTCoreCurrentLocationRecord, 
    BOLTCoreIdentifiable, 
    BOLTCoreLoadTruck, 
    BOLTdbEntity, 
    BOLTLocalDirections, 
    BOLTNamed, 
    BOLTrelationalAddress, 
    TerminalIdentifiable } from "./BOLTCore";

export interface LocationType extends BOLTCoreCodeIdNamed {
}

export interface Location extends BOLTCoreAddress, 
TerminalIdentifiable, 
BOLTCodeable,
CoreContact,
BOLTCommentable,
BOLTActive,
BOLTLocalDirections,
BOLTrelationalAddress {}

export interface ShipTo extends Location {}

export interface BOLTLoadAggregates extends BOLTdbEntity {
    linear_feet:number,
    pallets_out:number,
    cubes:number,
    pallets_in:number,
    weight:number,
    pieces:number,
}

export interface BOLTStopRules extends BOLTdbEntity {
    change_truck:boolean,
    can_begin_load:boolean,
    is_billable:boolean,
    change_driver:boolean,
    can_end_load:boolean,
    second_truck:boolean,
    allow_to_be_moved:boolean,
    is_billable_loaded:boolean,
    not_load_related:boolean,
    check_late:boolean,
    change_trailer:boolean,
    is_ui_visible:boolean,
    is_payable:boolean,
    is_customer_visible:boolean,
}

export interface BOLTstopType extends BOLTCoreIdentifiable,
BOLTNamed {
    rules:BOLTStopRules
}

export interface BOLTStop extends BOLTCoreIdentifiable,
BOLTActive,
BOLTCommentable {
    location:Location,
    number:number,
    contact?:string,
    time_from_last_stop:number,
    actual:BOLTCoreArrivalTimes,
    aggregates:BOLTLoadAggregates,
    scheduled:BOLTCoreArrivalTimes,
    bill_of_lading?:string,
    stop_type:BOLTstopType,
    distance_from_last_stop:number,
}

export interface BOLTRevenueItem extends BOLTdbEntity {
    fuel_surcharge:number,
    miscellaneous:number,
    accessorial:number,
    line_haul:number,
    type: string,
}

export interface BOLTLoadDistances extends BOLTdbEntity {
    loaded:number,
    empty:number
}

export interface BOLTStopDetail extends BOLTdbEntity {
    total:number,
    arrived:number
}

export interface BOLTLoadSummary extends BOLTdbEntity {
    has_temperature_controlled_shipment:boolean,
    has_backhaul_shipment:boolean,
    revenue:BOLTRevenueItem[],
    has_unassigned_segment:boolean,
    shipments:number,
    distances:BOLTLoadDistances,
    stops: BOLTStopDetail,
    has_hazmat_shipment:boolean,
    has_edi_shipment:boolean
}

export interface BOLTLoadCategory extends BOLTCoreIdentifiable,
BOLTNamed {}

export interface BOLTEmergencyContact extends BOLTNamed {
    phone?:string
}

export interface BOLTPersonalDetails {
    mobile_phone?:string,
    emergency_contact:BOLTEmergencyContact,
    address?:string,
    home_phone?:string,
    email?:string,
    birthday?:string
}

export interface BOLTWorkDetailsTerminalSettings {
    modify?:string|boolean,
    view?:string|boolean
}

export interface BOLTWorkDetailsTerminalInfo {
    secondaries?:BOLTWorkDetailsTerminalSettings,
    primary?:BOLTWorkDetailsTerminalSettings
}

export interface BOLTWorkDetailsWorkersCompDetail {
    expiration?:string,
    account?:string
}

export interface BOLTWorkDetails {
    mobile_phone?:string,
    terminal:BOLTWorkDetailsTerminalInfo,
    termination_date?:string,
    hire_date?:string,
    desk_phone?:string,
    workers_compensation: BOLTWorkDetailsWorkersCompDetail,
    review_date?:string,
    email?:string,
    rehire_date?:string,
}

export interface BOLTUser extends BOLTCoreIdentifiable,
BOLTActive,
BOLTNamed {
    suffix:string,
    permissions:any [],
    employee_id:string,
    user_name?:string,
    last_name:string,
    landing_path:string,
    first_name:string,
    personal:BOLTPersonalDetails,
    work:BOLTWorkDetails,
    middle_name?:string

}

export interface BOLTLoad extends BOLTCoreIdentifiable,
BOLTActive {
    load_template:string,
    next_stop:BOLTStop,
    current_stop:BOLTStop,
    first_stop:BOLTStop,
    comment_count:number,
    drivers:string[],
    first_purchase_order:string,
    carrier?:string | number,
    last_stop:BOLTStop,
    status:BOLTCoreCodeIdNamed,
    hauling_terminal:Location,
    summary:BOLTLoadSummary,
    origination_terminal:Location,
    trailers:any[],
    category:BOLTLoadCategory,
    creator:BOLTUser,
    current_location:BOLTCoreCurrentLocationRecord,
    first_shipment_id:string,
    truck:BOLTCoreLoadTruck
}

export interface BOLTterminal extends Location {}

export interface BOLTeld extends BOLTCoreIdentifiable,
BOLTActive {
    dataSupplier:string
}

export interface BOLTLoadStatuses extends BOLTCoreIdentifiable,
BOLTNamed,
BOLTCodeable {}