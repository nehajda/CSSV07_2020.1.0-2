%dw 2.0
output application/xml
fun checkPayload(data)= (if(isEmpty(data))
		                            vars.runningPayload
	                            else
		                            payload)

---
vars.jci.messageSubType match  {
    case "PurchaseOrder" -> checkPayload(payload..*order)
    case "transportLoadMessage" -> checkPayload(payload..*transportLoad[0])
    case "itemMessage" -> checkPayload(payload..*item)
    else -> payload
}