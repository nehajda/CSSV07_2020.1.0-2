%dw 2.0
output application/xml

var destination = vars.jciOutboundReceivers map (($ splitBy  ".")[1])

fun filterOrder(order,linenumber,parentkey) = order mapObject(value,key) -> {               // Filter the jdaOrderExtension.orderLineItem and orderLineItem based on the receiver
    (
        if(value is String and not isEmpty(value) and value != null)
            (key): value
        else 
            (if(key ~= "orderLineItem" and parentkey ~= "order")                           // check if its orderLineItem
                ((key): value) if (destination contains (value.orderLineItemDetail.orderLogisticalInformation.shipTo.*additionalPartyIdentification[?($.@additionalPartyIdentificationTypeCode == "FOR_INTERNAL_USE_1")][0] default value.orderLineItemDetail.orderLogisticalInformation.shipTo.*additionalPartyIdentification[?($.@additionalPartyIdentificationTypeCode == "UNKNOWN")][0]))
            else if (key ~= "orderLineItem" and parentkey ~= "jdaOrderExtension")          // CHeck if its extension orderlineitem
                ((key): value) if(linenumber contains value.lineItemNumber)
            else
                (key) : filterOrder(value,linenumber,key)
            )
        
        )
}

fun destinorder(order) = order.*orderLineItem filter(destination contains ($.orderLineItemDetail.orderLogisticalInformation.shipTo.*additionalPartyIdentification[?($.@additionalPartyIdentificationTypeCode == "FOR_INTERNAL_USE_1")][0] default $.orderLineItemDetail.orderLogisticalInformation.shipTo.*additionalPartyIdentification[?($.@additionalPartyIdentificationTypeCode == "UNKNOWN")][0]))

---

payload mapObject(order, roottag) -> {                       // Filter the orders based on the destination receivers
    (roottag): order mapObject(po, pokey) -> {
        (if(pokey ~= "StandardBusinessDocumentHeader")		 // print sbdh section
            (pokey): po
        else if (pokey ~= "order")							
            (if(sizeOf(destinorder(po)) > 0)				//check if current order has the current destination
                (pokey): filterOrder(po,destinorder(po).lineItemNumber,"order")
            else
                null
            ) 
        else
            (pokey): po
        )
    }
}