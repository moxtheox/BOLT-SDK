
import type { iStop, iTruck } from "./BOLTInterfaces";

export interface iLoadSegment {
    stops:iStop[];
    purchase_orders:string[];
    load_id:number;
    truck:iTruck
}