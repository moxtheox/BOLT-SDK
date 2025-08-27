
export interface iCoreIdentifiable {
    serial_id:number
}

export interface iCoreDeactivatable {
    is_active:boolean
}

export interface iCoreCreatedAt {
    created_at:Date
}

export interface iCoreUpdatedAt {
    updated_at:Date
}

export interface iCoreCommonAuditFields extends iCoreCreatedAt, iCoreUpdatedAt, iCoreDeactivatable {
}

export interface iCoreAddress extends iCoreIdentifiable {
    street_1: string,
    street_2?: string,
    city: string,
    state: string,
}

