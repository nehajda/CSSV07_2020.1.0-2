%dw 2.0
output application/java
var interceptordwlpath = {
	"PurchaseOrder": "interceptor/wma/PurchaseOrderInterceptor.dwl",
	"transportLoadMessage": "interceptor/wma/TransportLoadInterceptor.dwl",
	"itemMessage": "interceptor/wma/ItemInterceptor.dwl"
}
---
interceptordwlpath[vars.jci.messageSubType] default "interceptor/wma/NoTransformation.dwl"