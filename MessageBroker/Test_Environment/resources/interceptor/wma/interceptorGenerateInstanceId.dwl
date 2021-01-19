%dw 2.0
output application/xml
fun generateInstanceId(sbdh,parentKey) = sbdh mapObject(sbdhvalue,sbdhkey) -> {(
    if(sbdhkey ~= "InstanceIdentifier" and parentKey ~= "DocumentIdentification")
        (sbdhkey): uuid()
    else if(sbdhkey ~= "CreationDateAndTime" and parentKey ~= "DocumentIdentification")
        (sbdhkey): now()
    else if(sbdhvalue is String and not isEmpty(sbdhvalue) and sbdhvalue != null)   
        (sbdhkey): sbdhvalue
    else
        (sbdhkey): generateInstanceId(sbdhvalue,sbdhkey)
)}
fun removenullvalues(value) = value mapObject(value,key) -> {(
    if((value is Object) and (not isEmpty(value)) and value != null)
        (key): removenullvalues(value)
    else if(value is String and value != '')
        (key): value
    else
        null

)}
---
payload mapObject (rootvalue,rootkey) -> {
    (rootkey): rootvalue mapObject (value,key) -> {(
        if(key ~= "StandardBusinessDocumentHeader")
            (key): generateInstanceId(value,key)
        else
            (key): removenullvalues(value)
    )}
}