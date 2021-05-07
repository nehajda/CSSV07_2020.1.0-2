%dw 2.0
import * from dw::core::Arrays
output application/xml
ns transport_load urn:jda:ecom:transport_load:xsd:3
ns sh http://www.unece.org/cefact/namespaces/StandardBusinessDocumentHeader
ns xsi http://www.w3.org/2001/XMLSchema-instance

/* Extract the Destinations from the Receiver List */
var locationName = vars.jciOutboundReceivers map ($ splitBy ".")[1]

/* Extract the Receiver Suffix */
var receiverSuffix = (vars.jciOutboundReceivers[0])[0 to 3]

var messageReceiver = vars.jciOutboundReceivers

var receiverCount = sizeOf (payload.transportLoadMessage.StandardBusinessDocumentHeader.*Receiver.*Identifier)

/* Collect All the Drop Location values (shipto.additionalPartyIdentification) from the shipments that matches the destination given in the receiver list */
fun dropStops(tl) = using(shipment = (tl.*transportLoadShipment filter (locationName contains ($.shipFrom.*additionalPartyIdentification[?($.@additionalPartyIdentificationTypeCode == "FOR_INTERNAL_USE_1")][0] default $.shipFrom.*additionalPartyIdentification[?($.@additionalPartyIdentificationTypeCode == "UNKNOWN")][0]) ))) 
										(shipment map(sh,Indexofsh) -> 
											sh.shipTo.*additionalPartyIdentification[?($.@additionalPartyIdentificationTypeCode == "FOR_INTERNAL_USE_1")][0] default sh.shipTo.*additionalPartyIdentification[?($.@additionalPartyIdentificationTypeCode == "UNKNOWN")][0]
										)

/* Filter the shipment list to match the receiver value */
fun transportLoadShipments(tl) = if (receiverSuffix != 'LOC.') 
        							(tl.*transportLoadShipment filter (!(locationName contains $.shipFrom.additionalPartyIdentification) )) 
        						else      
        							(tl.*transportLoadShipment filter (locationName contains ($.shipFrom.*additionalPartyIdentification[?($.@additionalPartyIdentificationTypeCode == "FOR_INTERNAL_USE_1")][0] default $.shipFrom.*additionalPartyIdentification[?($.@additionalPartyIdentificationTypeCode == "UNKNOWN")][0]) ) )
---
if ((receiverCount >= 1))
(
transport_load#transportLoadMessage @("xmlns:sh":"http://www.unece.org/cefact/namespaces/StandardBusinessDocumentHeader", "xmlns:xsi":"http://www.w3.org/2001/XMLSchema-instance" , "xsi:schemaLocation": "urn:jda:ecom:transport_load:xsd:3 ../Schemas/jda/ecom/TransportLoad.xsd"): {
    (sh#StandardBusinessDocumentHeader: using (sbdh = payload.transportLoadMessage.StandardBusinessDocumentHeader){
        sh#HeaderVersion: sbdh.HeaderVersion,
                     sh#Sender: sbdh.*Sender,
                     sh#Receiver: sbdh.*Receiver,                                         
                     sh#DocumentIdentification: {
                           sh#Standard: 'GS1',
                           sh#TypeVersion: 3.2,
                           sh#InstanceIdentifier: sbdh.DocumentIdentification.InstanceIdentifier,
                           sh#Type: sbdh.DocumentIdentification.'Type',
                           sh#CreationDateAndTime: sbdh.DocumentIdentification.CreationDateAndTime
                     },
                     sh#BusinessScope: sbdh.BusinessScope
    }),
    
    /* Check if the transportload has valid shipments that matches the receiver list. If not, then remove the transportload from the message */
    (transportLoad: payload..*transportLoad filter( isEmpty(transportLoadShipments($)) != true ) map(transportLoad,IndexoftransportLoad) -> 
    using(stops = (transportLoad.*stop filter ($ != null)),
    		dropstops = dropStops(transportLoad))
    {
        creationDateTime: transportLoad.creationDateTime,
        documentStatusCode: transportLoad.documentStatusCode,
        documentActionCode: transportLoad.documentActionCode,
        (lastUpdateDateTime: transportLoad.lastUpdateDateTime) if(transportLoad.lastUpdateDateTime != null),
        transportLoadIdentification: transportLoad.transportLoadIdentification,
        loadStatusCode: transportLoad.loadStatusCode,
        logisticServicesSeller: transportLoad.logisticServicesSeller,
        logisticServicesBuyer: transportLoad.logisticServicesBuyer,
        transportModeTypeCode: transportLoad.transportModeTypeCode,
        transportCargoCharacteristics: transportLoad.transportCargoCharacteristics,
        transportServiceCategoryType: transportLoad.transportServiceCategoryType,
		transportServiceLevelCode: transportLoad.transportServiceLevelCode,
		carrier: transportLoad.carrier,
		((driver: transportLoad.driver) if (transportLoad.driver != null)),
		transportEquipment: transportLoad.transportEquipment,
		((transportReference: transportLoad.transportReference) if (transportLoad.transportReference != null)),
		loadStartDateTime:transportLoad.loadStartDateTime,
		loadEndDateTime: transportLoad.loadEndDateTime,
		(transportLoad.*tmReferenceNumber map (current, index) -> AnytmReferenceNumber : {
						referenceNumberName : current.referenceNumberName,
						referenceNumberValue : current.referenceNumberValue
		}),
		numberOfPickUpStops: transportLoad.numberOfPickUpStops,
		numberOfDropOffStops: transportLoad.numberOfDropOffStops,
		(externalTransportServiceLevelCode1: transportLoad.externalTransportServiceLevelCode1) if (transportLoad.externalTransportServiceLevelCode1 != null),
		(externalTransportServiceLevelCode2: transportLoad.externalTransportServiceLevelCode2) if(transportLoad.externalTransportServiceLevelCode2 != null),
		(tripIdentification: transportLoad.tripIdentification) if (transportLoad.tripIdentification != null),
		(tripInformation : transportLoad.tripInformation) if (transportLoad.tripInformation != null),
		
		//Filter the Pickup Stops that match the receiver
        (stop: if (receiverSuffix == 'LOC.' and stops != null) 
		             (stops filter ((locationName contains ($.stopLocation.sublocationIdentification default $.stopLocation.additionalLocationIdentification)) and ($.pickupShipmentReference.additionalShipmentIdentification != null)))
		else stops),
		
		//Drop Stops
		(stop: if (receiverSuffix == 'LOC.' and dropstops != null) 
		             (stops filter ((dropstops contains (($.stopLocation.sublocationIdentification default $.stopLocation.additionalLocationIdentification) as String))) and ($.dropoffShipmentReference.additionalShipmentIdentification != null) and (!(locationName contains ($.stopLocation.sublocationIdentification default $.stopLocation.additionalLocationIdentification))))
		else null),
		
        // Stops without any shipment references
        (stop: stops filter ($.dropoffShipmentReference == null and $.pickupShipmentReference == null)),  
        
        transportLoadShipment: (transportLoadShipments(transportLoad))        
    })
}
) else (payload)