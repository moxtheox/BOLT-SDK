import {Elysia} from 'elysia';
import { BOLTApi, BOLTApiLoadBoardShipmentStatus } from './src/api/BOLTApi';
import { get } from 'http';


interface iBOLTLoadBoardEntry {is_edi:boolean,
    id:number,
    load_ids:number[],
    is_active:boolean,
    shipment_name:string,
    purchase_order_name:string
}
const api = new BOLTApi();
function filterLoadBoardEntries(entries: iBOLTLoadBoardEntry[], pattern:RegExp): iBOLTLoadBoardEntry[] {
    return entries.filter(entry=> pattern.test(entry.purchase_order_name) && entry.is_active);
}

async function getActiveLoadBoardEntries(): Promise<iBOLTLoadBoardEntry[]> {
    
    const lb_active = [
        api.GetLoadBoard(BOLTApiLoadBoardShipmentStatus.IN_TRANSIT), 
        api.GetLoadBoard(BOLTApiLoadBoardShipmentStatus.SCHEDULED)
    ];
    const pattern = /^(PW|LC|NY|MD)/;
    const responses = await Promise.all(lb_active);
    return [ ...filterLoadBoardEntries(responses[0]?.data as iBOLTLoadBoardEntry[], pattern),
             ...filterLoadBoardEntries(responses[1]?.data as iBOLTLoadBoardEntry[], pattern)];
}

async function getActiveLoadData():Promise<any[]> {
    const pros = (await getActiveLoadBoardEntries()).map(e=> e.load_ids[0]);
    const proms = pros.map( (pro)=> {
        return api.getLoadSegmentsById(pro as number)
    });
    const loads = await Promise.all(proms);
   return loads.map( l=> l.data);
}


console.log(await getActiveLoadData());