
export interface BOLTApiSingleResponse<T> {
    message?:string,
    data:T,
    links?:BOLTApiResponseLinks
    type?:string
}

interface BOLTResponseMeta {
    total?:number,
    current_page?:number,
    from?:number,
    to?:number,
}

interface BOLTApiResponseLinks {
    last?:string,
    next?:string,
    first?:string,
    previous?:string
}

export interface BOLTApiMultiResponse<TData> extends BOLTApiSingleResponse<TData[]>{
    meta?:BOLTResponseMeta,
    data:TData[],
}