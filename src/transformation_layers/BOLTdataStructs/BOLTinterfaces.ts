
export interface BOLTGeoLocation {
    latitude:number,
    longitude:number
}

export interface ShipToType {
    code:string,
    id:number,
    name:string
}

export interface ShipTo {
    parent_address_id?:number,
    child_address_ids:number[],
    phone?:string,
    state?:string,
    comments?:string,
    terminal_id:number,
    email?:string,
    is_active:boolean,
    street1?:string,
    name:string,
    street2?:string,
    geo:BOLTGeoLocation,
    code:string,
    local_directions?:string,
    city?:string,
    postal_code?:string,
    id:number,
    type:ShipToType
}
