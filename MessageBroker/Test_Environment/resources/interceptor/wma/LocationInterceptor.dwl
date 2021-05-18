%dw 2.0
import * from dw::util::Values
ns sh http://www.unece.org/cefact/namespaces/StandardBusinessDocumentHeader
ns location urn:jda:master:location:xsd:3
output application/xml
/* Function to Check value from ClientID to WarehouseId CodeMapping */
fun mapping(data) = jda::CodeMap::keyLookupOptional(vars.wmaCodeMap, "CWM", data default "")

/* Create an array of All warehouseId from Message Receivers */
var destinations = vars.jciOutboundReceivers map (($ splitBy  ".")[1])

fun parentPartyFilter(party) = (party mapObject (value,key) -> {
	
	/* Check if Corresponding WarehouseId for Each ClientId given in additionalPartyIdentification matches the receiver list */
    (if(key ~= "additionalPartyIdentification" and key.@additionalPartyIdentificationTypeCode == "FOR_INTERNAL_USE_1")
        ((key): value) if( destinations contains mapping(value))
        
    /* Remove additionalPartyIdentification key with typecode UNKNOWN as value from FOR_INTERNAL_USE_1 will be picked */    
    else if(key ~= "additionalPartyIdentification" and key.@additionalPartyIdentificationTypeCode == "UNKNOWN")
        null
    
    /* Other Keys will passed without any change */
    else
        (key): value
    )
}) 
---
{
       
       location#locationMessage @("xmlns:sh":"http://www.unece.org/cefact/namespaces/StandardBusinessDocumentHeader"
       ,"xsi:schemaLocation":"urn:jda:master:location:xsd:3 ../Schemas/jda/master/Location.xsd",
       "xmlns:xsi":"http://www.w3.org/2001/XMLSchema-instance"): {
           sh#StandardBusinessDocumentHeader: payload.locationMessage.StandardBusinessDocumentHeader,
           (payload.locationMessage.*location map(location,Indexoflocation) ->  
           using(newParentParty = parentPartyFilter(location.parentParty))
           		location: location update "parentParty" with newParentParty //Update Only the parentParty Object with the Filtered List
           )
       }

}