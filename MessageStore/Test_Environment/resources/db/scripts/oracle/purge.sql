/*
* Script to purge the Messagestore data.
* Deletes the data from Message store tables, retaining the data for the days specified by retention_days variable.
* By default the retention days are 30, and the value can be changed based on the requirement.
*/
DECLARE
   retention_days     INT := 30;
   cur_date           TIMESTAMP := SYSDATE;
   cutoff_date        TIMESTAMP := cur_date - retention_days;

   
BEGIN
-----------------------------------------------------PURGE MESSAGE ENTRIES-----------------------------------------------------------

	--Purge message entries from MS_MSG_BDY										   
	DELETE FROM MS_MSG_BDY WHERE MSG_BDY_ID IN (SELECT MSG_BDY_ID FROM MS_MSG_EVNT 
							WHERE MSG_HDR_ID IN (SELECT MSG_HDR_ID FROM MS_MSG_HDR 
								WHERE CRTD_AT < cutoff_date));
		  
-----------------------------------------------------PURGE BULK MESSAGE ENTRIES-----------------------------------------------------------
	--Purge bulk message entries from MS_BLK_HDR
	DELETE FROM MS_BLK_HDR WHERE  BLK_HDR_ID IN (SELECT BLK_HDR_ID FROM MS_BLK_HDR
                                            WHERE CRTD_AT < cutoff_date);						

-----------------------------------------------------PURGE INGESTION ENTRIES-----------------------------------------------------------
	--Purge ingestion entries from MS_INGSTN_RCRD
	DELETE FROM MS_INGSTN_RCRD WHERE  INGSTN_RCRD_ID IN (SELECT INGSTN_RCRD_ID FROM MS_INGSTN_RCRD
                                            WHERE CRTD_AT < cutoff_date);									
											
COMMIT;		

END;
/
