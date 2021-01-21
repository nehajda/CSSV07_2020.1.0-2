%dw 2.0
output application/xml
---
if(vars.jci.messageSubType == "transportLoadMessage")
	if(isEmpty(payload..*transportLoad.transportLoadShipment[0]))
		vars.runningPayload
	else
		payload
else if(vars.jci.messageSubType == "PurchaseOrder")
	if(isEmpty(payload..*order))
		vars.runningPayload
	else	
		payload
else
	payload