%dw 2.0
output application/xml

var destination = (vars.jciOutboundReceivers[0] splitBy ".")[1]

fun filterOrder(order,linenumber,parentkey) = order mapObject(value,key) -> {               // Filter the jdaOrderExtension.orderLineItem and orderLineItem based on the receiver
    (
        if(value is String and not isEmpty(value) and value != null)
            (key): value
        else 
            (if(key ~= "orderLineItem" and parentkey ~= "order")                           // check if its orderLineItem
                ((key): value) if (value.orderLineItemDetail.orderLogisticalInformation.shipTo.additionalPartyIdentification == destination)
            else if (key ~= "orderLineItem" and parentkey ~= "jdaOrderExtension")          // CHeck if its extension orderlineitem
                ((key): value) if(linenumber contains value.lineItemNumber)
            else
                (key) : filterOrder(value,linenumber,key)
            )
        
        )
}

fun destinorder(order) = order.*orderLineItem filter($.orderLineItemDetail.orderLogisticalInformation.shipTo.additionalPartyIdentification == destination)

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