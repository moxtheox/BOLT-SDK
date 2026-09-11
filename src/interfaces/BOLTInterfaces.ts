export interface iBOLTLoadBoardEntry {
    is_edi:boolean,
    id:number,
    load_ids:number[],
    is_active:boolean,
    shipment_name:string,
    purchase_order_name:string
}

export interface iGeo {
    longitude: number;
    latitude: number;
}

export interface iRules {
    change_truck: boolean;
    can_begin_load: boolean;
    is_billable: boolean;
    change_driver: boolean;
    can_end_load: boolean;
    second_truck: boolean;
    allow_to_be_moved: boolean;
    is_billable_loaded: boolean;
    not_load_related: boolean;
    check_late: boolean;
    change_trailer: boolean;
    is_ui_visible: boolean;
    is_payable: boolean;
    is_customer_visible: boolean;
}

export interface iStopType {
    id: number;
    rules: iRules;
    name: string;
}

export interface iActual {
    arrive_at?: string | null; // 2024-04-23T05:00:00Z
    depart_at?: string | null; // 2024-04-23T05:00:00Z
}

export interface iAggregates {
    linear_feet: number;
    pallets_out: number;
    cubes: number;
    pallets_in: number;
    weight: number;
    pieces: number;
}

export interface iScheduled {
    arrive_at?: string | null; // 2024-04-23T05:00:00Z
    depart_at?: string | null; // 2024-04-23T05:00:00Z
}

export interface iLocation {
    parent_address_id?: number | null;
    child_address_ids: number[];
    phone?: string | null;
    state: string;
    comments?: string | null;
    terminal_id?: number | null;
    email?: string | null;
    is_active: boolean;
    street1: string;
    name: string;
    street2?: string | null;
    geo: iGeo;
    code: string;
    local_directions?: string | null;
    city: string;
    postal_code: string;
    id: number;
}

export interface iStop {
    location: iLocation;
    number: number;
    contact?: string | null;
    time_from_last_stop: number;
    actual: iActual;
    aggregates: iAggregates;
    is_active: boolean;
    scheduled: iScheduled;
    comment?: string | null;
    bill_of_lading?: string | null;
    stop_type: iStopType;
    id: number;
    distance_from_last_stop: number;
}

export interface iSpecification {
  vin: string | null;
  model: string | null;
  year: number | null;
  price: number | null;
  make: string | null;
}

export interface iPrimaryTerminal {
  maintenance_emails: string[] | null;
}

export interface iRegistration {
  expiration: string | null;
  state: string | null;
  tag: string | null;
  country: string | null;
}

export interface iDimensions {
  height: number | null;
  width: number | null;
  length: number | null;
}

export interface iRules {
  is_power_unit: boolean;
  is_chassis: boolean;
  is_container: boolean;
  is_trailer: boolean;
  has_fifth_wheel: boolean;
}

export interface iType {
  dimensions: iDimensions;
  id: number | null;
  rules: iRules;
  name: string | null;
}

export interface iTruck {
  id: number;
  name: string;
  is_active: boolean;
  is_ifta: boolean;
  is_cross_terminal: boolean;
  last_dot_inspection: string;
  last_in_service: string | null;
  last_out_of_service: string | null;
  last_breadcrumb: any | null;
  owned_by: string | number | null;
  insurance_expiration: string | null;
  specification: iSpecification;
  primary_terminal: iPrimaryTerminal;
  registration: iRegistration;
  type: iType;
}