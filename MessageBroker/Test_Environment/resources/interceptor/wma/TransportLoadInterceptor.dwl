/**
 * ==========================================================================
 *                      Copyright 2020, Blue Yonder Group, Inc.
 *                                All Rights Reserved
 *
 *                   THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF
 *                              Blue Yonder Group, Inc.
 *
 *
 *               The copyright notice above does not evidence any actual
 *                    or intended publication of such source code.
 *
 *  ==========================================================================
 */

%dw 2.0
output application/xml encoding="utf-8"
ns transport_load urn:jda:ecom:transport_load:xsd:3
ns sh http://www.unece.org/cefact/namespaces/StandardBusinessDocumentHeader
ns xsi http://www.w3.org/2001/XMLSchema-instance
var receiverCount= sizeOf (payload.transportLoadMessage.StandardBusinessDocumentHeader.*Receiver.*Identifier)
---
if ((receiverCount >= 1))
(
		transport_load#transportLoadMessage @("xmlns:sh":"http://www.unece.org/cefact/namespaces/StandardBusinessDocumentHeader", "xmlns:xsi":"http://www.w3.org/2001/XMLSchema-instance" , "xsi:schemaLocation": "urn:jda:ecom:transport_load:xsd:3 ../Schemas/jda/ecom/TransportLoad.xsd"): {
              (sh#StandardBusinessDocumentHeader:  {
                     sh#HeaderVersion: payload.transportLoadMessage.StandardBusinessDocumentHeader.HeaderVersion,
                     sh#Sender: payload.transportLoadMessage.StandardBusinessDocumentHeader.*Sender,
                     (sh#Receiver: {
                           sh#Identifier @(Authority: "ENTERPRISE"): vars.messageReceiver
                     }) if((vars.receiverSuffix == 'LOC.')),
                     (sh#Receiver: {
                           sh#Identifier @(Authority: "ENTERPRISE"): vars.messageReceiver
                     }) if((vars.receiverSuffix != 'LOC.')),                        
                     sh#DocumentIdentification: {
                           sh#Standard: 'GS1',
                           sh#TypeVersion: 3.2,
                           sh#InstanceIdentifier: payload.transportLoadMessage.StandardBusinessDocumentHeader.DocumentIdentification.InstanceIdentifier,
                           sh#Type: payload.transportLoadMessage.StandardBusinessDocumentHeader.DocumentIdentification.'Type',
                           sh#CreationDateAndTime: payload.transportLoadMessage.StandardBusinessDocumentHeader.DocumentIdentification.CreationDateAndTime
                     },
                     sh#BusinessScope: payload.transportLoadMessage.StandardBusinessDocumentHeader.BusinessScope
              }),
              (transportLoad: {
              		((creationDateTime: payload.transportLoadMessage.transportLoad.creationDateTime)),              
                     (documentStatusCode: payload.transportLoadMessage.transportLoad.documentStatusCode),
                     (documentActionCode: if ((not (vars.isPickStopAvailable contains true)) and (vars.receiverSuffix == 'LOC.')) 'DELETE' else payload.transportLoadMessage.transportLoad.documentActionCode),
                     ((lastUpdateDateTime: payload.transportLoadMessage.transportLoad.lastUpdateDateTime) if (payload.transportLoadMessage.transportLoad.lastUpdateDateTime != null)),
                     transportLoadIdentification: payload.transportLoadMessage.transportLoad.transportLoadIdentification,
                     loadStatusCode: payload.transportLoadMessage.transportLoad.loadStatusCode,
                     logisticServicesSeller: payload.transportLoadMessage.transportLoad.logisticServicesSeller,
                     logisticServicesBuyer:payload.transportLoadMessage.transportLoad.logisticServicesBuyer,
                     transportModeTypeCode: payload.transportLoadMessage.transportLoad.transportModeTypeCode,
                     transportCargoCharacteristics: payload.transportLoadMessage.transportLoad.transportCargoCharacteristics,
                     transportServiceCategoryType: payload.transportLoadMessage.transportLoad.transportServiceCategoryType,
		              transportServiceLevelCode: payload.transportLoadMessage.transportLoad.transportServiceLevelCode,
		              carrier: payload.transportLoadMessage.transportLoad.carrier,
		              ((driver: payload.transportLoadMessage.transportLoad.driver) if (payload.transportLoadMessage.transportLoad.driver != null)),
		              transportEquipment: payload.transportLoadMessage.transportLoad.transportEquipment,
		              ((transportReference: payload.transportLoadMessage.transportLoad.transportReference) if (payload.transportLoadMessage.transportLoad.transportReference != null)),
					  loadStartDateTime:payload.transportLoadMessage.transportLoad.loadStartDateTime,
					  loadEndDateTime:payload.transportLoadMessage.transportLoad.loadEndDateTime,
					 (tmReferenceNumber : payload.transportLoadMessage.transportLoad.*tmReferenceNumber map (current, index) -> {
						referenceNumberName : current.referenceNumberName,
						referenceNumberValue : current.referenceNumberValue
						 }),
		              numberOfPickUpStops: payload.transportLoadMessage.transportLoad.numberOfPickUpStops,
		              numberOfDropOffStops: payload.transportLoadMessage.transportLoad.numberOfDropOffStops,
		              (externalTransportServiceLevelCode1: payload.transportLoadMessage.transportLoad.externalTransportServiceLevelCode1) if (payload.transportLoadMessage.transportLoad.externalTransportServiceLevelCode1 != null),
		              (externalTransportServiceLevelCode2: payload.transportLoadMessage.transportLoad.externalTransportServiceLevelCode2) if(payload.transportLoadMessage.transportLoad.externalTransportServiceLevelCode2 != null),
		              (tripIdentification: payload.transportLoadMessage.transportLoad.tripIdentification) if (payload.transportLoadMessage.transportLoad.tripIdentification != null),
					  (tripInformation : payload.transportLoadMessage.transportLoad.tripInformation) if (payload.transportLoadMessage.transportLoad.tripInformation != null),
		              //Pickup Stops
		              (stop: if (vars.receiverSuffix == 'LOC.' and payload.transportLoadMessage.transportLoad.*stop != null) 
		              			(payload.transportLoadMessage.transportLoad.*stop filter (($.stopLocation.additionalLocationIdentification == vars.locationName) and ($.pickupShipmentReference.additionalShipmentIdentification != null)))
		              else payload.transportLoadMessage.transportLoad.*stop),
		              //Drop Stops
		              (stop: if (vars.receiverSuffix == 'LOC.' and vars.dropStops != null) 
		              			(payload.transportLoadMessage.transportLoad.*stop filter ((vars.dropStops contains ($.stopLocation.additionalLocationIdentification as String))) and ($.dropoffShipmentReference.additionalShipmentIdentification != null))
		              else null),
		              //Dummy Stops		              
		              (stop: (payload.transportLoadMessage.transportLoad.*stop filter (($.stopLocation.additionalLocationIdentification != vars.locationName))) map (currentStop, index) -> 
		              using (iterator= (sizeOf ((payload.transportLoadMessage.transportLoad.*stop filter (($.stopLocation.additionalLocationIdentification != vars.locationName))))) + 1)	
		              {
		              	stopSequenceNumber : iterator + index,
		              	stopLocation:{
		              		additionalLocationIdentification: vars.locationName		              		
		              	},
							(stopLogisticEvent:{
		                         logisticEventTypeCode: 'TERMINAL_ARRIVAL',
		                         logisticEventDateTime:{
		                               date: (currentStop.*stopLogisticEvent filter ($.logisticEventTypeCode == 'TERMINAL_ARRIVAL')).logisticEventDateTime.date default "2019-02-06Z",
		                               time: (currentStop.*stopLogisticEvent filter ($.logisticEventTypeCode == 'TERMINAL_ARRIVAL')).logisticEventDateTime.time default "17:43:35.000"
		                         }
		                    }),
		                    (stopLogisticEvent:{
		                        logisticEventTypeCode: 'TERMINAL_DEPARTURE',
		                        logisticEventDateTime:{
		                               date: (currentStop.*stopLogisticEvent filter ($.logisticEventTypeCode == 'TERMINAL_DEPARTURE')).logisticEventDateTime.date default "2019-02-06Z",
		                               time: (currentStop.*stopLogisticEvent filter ($.logisticEventTypeCode == 'TERMINAL_DEPARTURE')).logisticEventDateTime.time default "17:43:35.000"
		                        }
		                    })              				              	
		              }) if ((not (vars.isPickStopAvailable contains true)) and (vars.receiverSuffix == 'LOC.')),
                      (stop: payload.transportLoadMessage.transportLoad.*stop filter ($.dropoffShipmentReference == null and $.pickupShipmentReference == null)),
		              (transportLoadShipment: if (vars.receiverSuffix != 'LOC.') (payload.transportLoadMessage.transportLoad.*transportLoadShipment filter ($.shipFrom.additionalPartyIdentification != vars.locationName)) else (payload.transportLoadMessage.transportLoad.*transportLoadShipment filter ($.shipFrom.additionalPartyIdentification == vars.locationName)))
              })
           }
) else (payload)