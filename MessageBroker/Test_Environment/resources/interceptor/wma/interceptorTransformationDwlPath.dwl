%dw 2.0
output application/java
var interceptordwlpath = {
	"OrderRelease" : "interceptor/wma/orderReleaseInterceptor.dwl",
	"TransferOrder": "interceptor/wma/orderReleaseInterceptor.dwl",
	"PurchaseOrder": "interceptor/wma/purchaseOrderInterceptor.dwl"
}
---
interceptordwlpath[vars.jci.messageSubType] default "interceptor/wma/noTransformation.dwl"