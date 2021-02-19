%dw 2.0
output application/json
---
vars.jci.messageSubType match  {
    case "PurchaseOrder" -> payload..*orderIdentification.entityIdentification joinBy "-"
    case "purchaseOrder" -> payload..*orderId joinBy "-"
    case "transportLoadMessage" -> payload..*transportLoadIdentification.entityIdentification joinBy "-"
    case "transportLoad" -> payload..*transportLoadId joinBy "-"
    case "itemMessage" -> payload..*itemIdentification.additionalTradeItemIdentification joinBy "-"
    case "item" -> payload..*itemId.primaryId joinBy "-"
    else -> null
}