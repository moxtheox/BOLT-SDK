import type { CoreAddress, Identifiable, CoreContact } from "../DBcore/coreDbInterfaces";

export interface BOLTdbEntity {}

export interface BOLTCoreIdentifiable extends BOLTdbEntity, Identifiable {}

export interface BOLTCoreGeoLocation extends BOLTdbEntity{
    longitude:number,
    latitude:number
}

export interface BOLTCoreTerminalIdentifiable extends BOLTdbEntity {
    terminal_id:number,
}

export interface BOLTCoreAddress extends CoreAddress,
BOLTCoreIdentifiable {
    postal_code?:number | string,
    geo:BOLTCoreGeoLocation,
}

export interface BOLTCoreCodeable extends BOLTdbEntity {
    code:string,
}

export interface BOLTCoreNamed extends BOLTdbEntity {
    name:string,
}

export interface BOLTCoreCommentable extends BOLTdbEntity {
    comments?:string,
}

export interface BOLTCoreActive extends BOLTdbEntity {
    is_active:boolean,
}

export interface BOLTCoreLocalDirections extends BOLTdbEntity {
    local_directions?:string,
}

export interface BOLTCoreRelationalAddress extends BOLTdbEntity {
    parent_address_id?:number,
    child_address_ids:number [],
}

export interface BOLTCoreArrivalTimes extends BOLTdbEntity {
    arrive_at?:string,
    depart_at?:string,
}

export interface BOLTCoreCodeIdNamed extends BOLTCoreIdentifiable,
BOLTCoreCodeable,
BOLTCoreNamed {
    code:string,
    id:number,
    name:string,
}

export interface BOLTCoreBreadCrumbDataSupplier extends BOLTCoreIdentifiable,
BOLTCoreNamed {}

export interface BOLTCoreCurrentLocationRecord extends BOLTCoreIdentifiable {
    geo?:BOLTCoreGeoLocation,
    speed?:number,
    heading?:number,
    data_supplier?:BOLTCoreBreadCrumbDataSupplier,
    temperature?:number,
    description?:number,
    recorded_at?:string,
    is_ignition_on:boolean,
    odometer?:number,
}

export interface BOLTCoreVehicleSpecification extends BOLTdbEntity {
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
BOLTCoreNamed {
    dimensions:BOLTCoreEquipmentDetails,
    rules:BOLTCoreEquipmentRules,
}

export interface BOLTCoreLoadTruck extends BOLTCoreIdentifiable,
BOLTCoreActive,
BOLTCoreNamed {
    last_dot_inspection:string,
    last_in_service?:string,
    is_cross_terminal:boolean,
    owned_by?: any,
    last_out_of_service?:string,
    last_breadcrumb?:string,
    primary_terminal:BOLTdbEntity
    is_ifta:boolean,
    registration:BOLTCoreVehicleRegistration,
    insurance_expiration?:string,
    type:BOLTCoreEquipmentDetails
}   

export interface BOLTCoreBreadCrumbDataSupplier extends BOLTCoreIdentifiable,
BOLTCoreNamed {}

export interface BOLTCurrentBreadCrumb extends BOLTCoreCurrentLocationRecord,
BOLTCoreNamed {}

export interface BOLTCoreStop extends BOLTCoreIdentifiable,
BOLTCoreActive,
BOLTCoreCommentable {
    location:BOLTCoreLocation,
    number:number,
    contact?:string,
    time_from_last_stop:number,
    actual:BOLTCoreArrivalTimes,
    aggregates:BOLTCoreLoadAggregates,
    scheduled:BOLTCoreArrivalTimes,
    bill_of_lading?:string,
    stop_type:BOLTCoreStopType,
    distance_from_last_stop:number,
}

export interface BOLTCoreLoadDistances extends BOLTdbEntity {
    loaded:number,
    empty:number
}

export interface BOLTCoreRevenueItem extends BOLTdbEntity {
    fuel_surcharge:number,
    miscellaneous:number,
    accessorial:number,
    line_haul:number,
    type: string,
}

export interface BOLTCoreLoadStopsDetail extends BOLTdbEntity {
    total:number,
    arrived:number
}

export interface BOLTCoreLoadSummary extends BOLTdbEntity {
    has_temperature_controlled_shipment:boolean,
    has_backhaul_shipment:boolean,
    revenue:BOLTCoreRevenueItem[],
    has_unassigned_segment:boolean,
    shipments:number,
    distances:BOLTCoreLoadDistances,
    stops: BOLTCoreLoadStopsDetail,
    has_hazmat_shipment:boolean,
    has_edi_shipment:boolean
}

export interface BOLTCoreUser extends BOLTCoreIdentifiable,
BOLTCoreActive,
BOLTCoreNamed {
    suffix:string,
    permissions:BOLTdbEntity [],
    employee_id:string,
    user_name?:string,
    last_name:string,
    landing_path:string,
    first_name:string,
    personal:BOLTdbEntity,
    work:BOLTdbEntity,
    middle_name?:string

}

export interface BOLTCoreLoadCategory extends BOLTCoreIdentifiable,
BOLTCoreNamed {}

export interface BOLTCoreLoadData extends BOLTCoreIdentifiable,
BOLTCoreActive {
    load_template?:string,
    next_stop?:BOLTCoreStop,
    first_stop?:BOLTCoreStop,
    comment_count?:number,
    last_stop?:BOLTCoreStop,
    first_purchase_order:string
    carrier?:any,
    status:BOLTCoreCodeIdNamed,
    summary:BOLTCoreLoadSummary,
    trailers:BOLTdbEntity[],
    category?:BOLTCoreLoadCategory,
    creator?:BOLTCoreUser,
    current_location:BOLTCoreCurrentLocationRecord,
    first_shipment_id:string,
}

export interface BOLTCoreDataSupplier extends BOLTCoreIdentifiable,
BOLTCoreActive {
    dataSupplier?:string
}

export interface BOLTCoreLocation extends BOLTCoreAddress, 
BOLTCoreRelationalAddress, 
BOLTCoreCodeable,
CoreContact,
BOLTCoreCommentable,
BOLTCoreActive,
BOLTCoreLocalDirections,
BOLTCoreNamed,
BOLTCoreTerminalIdentifiable {}

export interface BOLTCoreLoadAggregates extends BOLTdbEntity {
    linear_feet:number,
    pallets_out:number,
    cubes:number,
    pallets_in:number,
    weight:number,
    pieces:number,
}


export interface BOLTCoreStopRules extends BOLTdbEntity {
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

export interface BOLTCoreStopType extends BOLTCoreIdentifiable,
BOLTCoreNamed {
    rules:BOLTCoreStopRules
}
