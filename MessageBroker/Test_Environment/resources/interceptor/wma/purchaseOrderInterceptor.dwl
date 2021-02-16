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

fun destinorder(order) = using(headerlevelshipto = order.orderLogisticalInformation.shipTo.*additionalPartyIdentification[?($.@additionalPartyIdentificationTypeCode == "FOR_INTERNAL_USE_1")][0] default order.orderLogisticalInformation.shipTo.*additionalPartyIdentification[?($.@additionalPartyIdentificationTypeCode == "UNKNOWN")][0]) 
    if(not isEmpty(headerlevelshipto))
        (if(destination contains headerlevelshipto)
        {
            "order": order,
            "headerlevelshipto": not isEmpty(headerlevelshipto)
        }
        else
        {
            "order": null,
            "headerlevelshipto": not isEmpty(headerlevelshipto)
        }    
        )
    else
        {
            "order": order.*orderLineItem filter(destination contains ($.orderLineItemDetail.orderLogisticalInformation.shipTo.*additionalPartyIdentification[?($.@additionalPartyIdentificationTypeCode == "FOR_INTERNAL_USE_1")][0] default $.orderLineItemDetail.orderLogisticalInformation.shipTo.*additionalPartyIdentification[?($.@additionalPartyIdentificationTypeCode == "UNKNOWN")][0])),
            "headerlevelshipto": false
        }

---

payload mapObject(order, roottag) -> {                       // Filter the orders based on the destination receivers
    (roottag): order mapObject(po, pokey) -> {
        (if(pokey ~= "StandardBusinessDocumentHeader")		 // print sbdh section
            (pokey): po
        else if (pokey ~= "order") using (destinationOrders = destinorder(po))							        (pokey): (if(destinationOrders.headerlevelshipto == true) 
                destinationOrders.order
            else
                (if(sizeOf(destinationOrders.order) > 0)				//check if current order has the current destination
                    filterOrder(po,destinationOrders.order.lineItemNumber,"order")
            else
                null
            ) 
                
            )            
        else
            (pokey): po
        )
    }
}