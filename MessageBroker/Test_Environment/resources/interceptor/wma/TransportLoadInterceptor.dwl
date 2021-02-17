%dw 2.0
import * from dw::core::Arrays
output application/xml
ns transport_load urn:jda:ecom:transport_load:xsd:3
ns sh http://www.unece.org/cefact/namespaces/StandardBusinessDocumentHeader
ns xsi http://www.w3.org/2001/XMLSchema-instance

var locationName = vars.jciOutboundReceivers map ($ splitBy ".")[1]

var receiverSuffix = (vars.jciOutboundReceivers[0])[0 to 3]

var messageReceiver = vars.jciOutboundReceivers

var receiverCount= sizeOf (payload.transportLoadMessage.StandardBusinessDocumentHeader.*Receiver.*Identifier)

fun stopPickLocationIDTL(tl) = (tl.*stop map (currentStop, stopIndex) ->
						(if((sizeOf (currentStop.*pickupShipmentReference filter ($.additionalShipmentIdentification != null)) default 0) != 0 )
							(currentStop.stopLocation.sublocationIdentification default currentStop.stopLocation.additionalLocationIdentification) else null
						)) distinctBy $

fun isPickStopAvailable(tl,stopPickLocationID) = (tl.*stop map (currentStop, stopIndex) -> if (locationName every (stopPickLocationID contains $)) true else false) distinctBy $

fun dropStops(tl) = using(shipment = (tl.*transportLoadShipment filter (locationName contains ($.shipFrom.*additionalPartyIdentification[?($.@additionalPartyIdentificationTypeCode == "FOR_INTERNAL_USE_1")][0] default $.shipFrom.*additionalPartyIdentification[?($.@additionalPartyIdentificationTypeCode == "UNKNOWN")][0]) ))) (shipment.shipTo.*additionalPartyIdentification[?($.@additionalPartyIdentificationTypeCode == "FOR_INTERNAL_USE_1")][0] default shipment.shipTo.*additionalPartyIdentification[?($.@additionalPartyIdentificationTypeCode == "UNKNOWN")][0])

fun transportLoadShipments(tl) = if (receiverSuffix != 'LOC.') 
        							(tl.*transportLoadShipment filter (!(locationName contains $.shipFrom.additionalPartyIdentification) )) 
        						else      
        							(tl.*transportLoadShipment filter (locationName contains ($.shipFrom.*additionalPartyIdentification[?($.@additionalPartyIdentificationTypeCode == "FOR_INTERNAL_USE_1")][0] default $.shipFrom.*additionalPartyIdentification[?($.@additionalPartyIdentificationTypeCode == "UNKNOWN")][0]) ) )
---
if ((receiverCount >= 1))
(
transport_load#transportLoadMessage @("xmlns:sh":"http://www.unece.org/cefact/namespaces/StandardBusinessDocumentHeader", "xmlns:xsi":"http://www.w3.org/2001/XMLSchema-instance" , "xsi:schemaLocation": "urn:jda:ecom:transport_load:xsd:3 ../Schemas/jda/ecom/TransportLoad.xsd"): {
    (sh#StandardBusinessDocumentHeader:{
        sh#HeaderVersion: payload.transportLoadMessage.StandardBusinessDocumentHeader.HeaderVersion,
                     sh#Sender: payload.transportLoadMessage.StandardBusinessDocumentHeader.*Sender,
                     sh#Receiver: payload.transportLoadMessage.StandardBusinessDocumentHeader.*Receiver,                                         
                     sh#DocumentIdentification: {
                           sh#Standard: 'GS1',
                           sh#TypeVersion: 3.2,
                           sh#InstanceIdentifier: payload.transportLoadMessage.StandardBusinessDocumentHeader.DocumentIdentification.InstanceIdentifier,
                           sh#Type: payload.transportLoadMessage.StandardBusinessDocumentHeader.DocumentIdentification.'Type',
                           sh#CreationDateAndTime: payload.transportLoadMessage.StandardBusinessDocumentHeader.DocumentIdentification.CreationDateAndTime
                     },
                     sh#BusinessScope: payload.transportLoadMessage.StandardBusinessDocumentHeader.BusinessScope
    }),
    (transportLoad: payload..*transportLoad filter( isEmpty(transportLoadShipments($)) != true ) map(transportLoad,IndexoftransportLoad) -> 
    using(stopPickLocationID = stopPickLocationIDTL(transportLoad))
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
		
		//Pickup Stops
        (stop: if (receiverSuffix == 'LOC.' and transportLoad.*stop != null) 
		             (transportLoad.*stop filter ((locationName contains ($.stopLocation.sublocationIdentification default $.stopLocation.additionalLocationIdentification)) and ($.pickupShipmentReference.additionalShipmentIdentification != null)))
		else transportLoad.*stop),
		
		//Drop Stops
		(stop: if (receiverSuffix == 'LOC.' and dropStops(transportLoad) != null) 
		             (transportLoad.*stop filter ((dropStops(transportLoad) ~= (($.stopLocation.sublocationIdentification default $.stopLocation.additionalLocationIdentification) as String))) and ($.dropoffShipmentReference.additionalShipmentIdentification != null) and (!(locationName contains ($.stopLocation.sublocationIdentification default $.stopLocation.additionalLocationIdentification))))
		else null),
		
        // Stops without any shipment references
        (stop: transportLoad.*stop filter ($.dropoffShipmentReference == null and $.pickupShipmentReference == null)),  
        
        transportLoadShipment: (transportLoadShipments(transportLoad))        
    })
}
) else (payload)