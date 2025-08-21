import type { BOLTCoreLoadTruck, 
    BOLTdbEntity, 
    BOLTCoreLocation,
    BOLTCoreNamed, 
    BOLTCoreLoadData,
    BOLTCoreUser,
    BOLTCoreDataSupplier,
    BOLTCoreLoadCategory,
    BOLTCoreStop
} from "./BOLTCore";


export interface ShipTo extends BOLTCoreLocation {}

export interface BillTo extends BOLTCoreLocation {}

export interface BOLTLoadCategory extends BOLTCoreLoadCategory {}

export interface BOLTEmergencyContact extends BOLTCoreNamed {
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

export interface BOLTUser extends BOLTCoreUser {
    personal:BOLTPersonalDetails,
    work:BOLTWorkDetails
}

export interface BOLTLoad extends BOLTCoreLoadData {
    next_stop?:BOLTCoreStop,
    current_stop?:BOLTCoreStop,
    first_stop?:BOLTCoreStop,
    drivers:string[],
    last_stop?:BOLTCoreStop,
    hauling_terminal:BOLTCoreLocation,
    origination_terminal:BOLTCoreLocation,
    category:BOLTLoadCategory,
    creator:BOLTUser,
    truck:BOLTCoreLoadTruck
}

export interface BOLTLoadTerminal extends BOLTCoreLocation {}

export interface BOLTeld extends BOLTCoreDataSupplier {}

export interface BOLTInsuranceDetail extends BOLTdbEntity {
    expiration?:string,
    limit?:string | number,
}

export interface BOLTCarrierInsurance extends BOLTdbEntity {
    cargo?:BOLTInsuranceDetail,
    liability?:BOLTInsuranceDetail,
    general?:BOLTInsuranceDetail,
}

export interface BOLTCarrierDetails extends BOLTdbEntity {
    scac?:string,
    insurance:BOLTCarrierInsurance,
    tax_id:string
    motor_carrier:string
}

export interface BOLTCarrier extends BOLTCoreLocation {
    carrier:BOLTCarrierDetails,
}

export interface BOLTLoadBoardLoadCategory extends BOLTCoreLoadCategory {
    code?:string,
}

export interface BOLTLoadBoardEntry extends BOLTCoreLoadData {
    most_recent_comment?:string | BOLTdbEntity,
    driver_ids?:number[],
    eta?:string,
    origination_terminal_id?:string,
    hauling_terminal_id?:number,
}

export interface BOLTLoadBoard extends BOLTCoreLoadData {
    
}