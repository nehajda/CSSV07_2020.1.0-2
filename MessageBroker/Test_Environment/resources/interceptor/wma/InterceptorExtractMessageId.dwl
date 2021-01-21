%dw 2.0

output application/json 
--- 
if(["PurchaseOrder","purchaseOrder"] contains vars.jci.messageSubType)
	(payload..*orderIdentification.entityIdentification joinBy "-") default (payload..*orderId joinBy "-")
else if(["transportLoadMessage","transportLoad"] contains vars.jci.messageSubType)
	(payload..*transportLoadIdentification.entityIdentification joinBy "-") default (payload..*transportLoadId joinBy "-")
else null