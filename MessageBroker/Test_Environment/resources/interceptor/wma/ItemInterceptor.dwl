%dw 2.0
import * from dw::core::Arrays
output application/xml
fun mapping(data) = jda::CodeMap::keyLookupOptional(vars.wmaCodeMap, "CWM", data default "")
var destinations = vars.jciOutboundReceivers map (($ splitBy  ".")[1])
fun checkValidItem(item) = (item.specificLocations.*location.additionalPartyIdentification map mapping($)) some (destinations contains $)
---
payload mapObject(itemMessage,roottag) -> {
    (roottag): itemMessage mapObject(item,itemkey) -> {
        (if(itemkey ~= "StandardBusinessDocumentHeader")
            (itemkey): item
        else if(itemkey ~= "item")
            (if(checkValidItem(item) == true){
                (itemkey): item mapObject (value,key) -> {
                    (if(["ownerOfTradeItem","procurementAuthority"] some ($ ~= key))
                        null
                    else if(key ~= "specificLocations") 
                    {
                        ownerOfTradeItem: {
                        	additionalPartyIdentification:(((item.specificLocations.*location.additionalPartyIdentification) filter (destinations contains mapping($))) distinctBy $) map $
                        },
                        (procurementAuthority: item.procurementAuthority) if (not isEmpty(item.procurementAuthority)),
                        specificLocations @(allLocations: item.specificLocations.@allLocations): {
                            location: (((item.specificLocations.*location.additionalPartyIdentification map mapping($)) filter (destinations contains $)) distinctBy $) map {
                                additionalPartyIdentification @(additionalPartyIdentificationTypeCode: "UNKNOWN"): $
                            }
                        }
                    }
                    else (key): value
                    )
                } 
            } else null)
        else (itemkey): item)
    }
}