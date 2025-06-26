
export interface Identifiable {
    id:number
}

export interface CoreAddress extends Identifiable {
    street1?:string,
    street2?:string,
    city?:string,
    state?:string,
}

export interface CoreContact {
    email?:string,
    phone?:string,
}
