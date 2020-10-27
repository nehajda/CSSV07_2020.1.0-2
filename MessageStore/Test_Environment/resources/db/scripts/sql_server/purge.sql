DECLARE @retention_days INT = 30
DECLARE @cur_date DATETIME = Getdate()
DECLARE @cutoff_date DATETIME = @cur_date - @retention_days

BEGIN
    BEGIN TRANSACTION

    BEGIN try
        
		-----------------------------------------------------PURGE MESSAGE ENTRIES-----------------------------------------------------------
        --Purge message entries from MS_MSG_BDY
		DELETE FROM MS_MSG_BDY WHERE MSG_BDY_ID IN (SELECT MSG_BDY_ID FROM MS_MSG_EVNT 
								WHERE MSG_HDR_ID IN (SELECT MSG_HDR_ID FROM MS_MSG_HDR 
									WHERE CRTD_AT < @cutoff_date));

        -----------------------------------------------------PURGE BULK MESSAGE ENTRIES-----------------------------------------------------------
        --Purge bulk message entries from MS_BLK_HDR
		DELETE FROM MS_BLK_HDR WHERE  BLK_HDR_ID IN (SELECT BLK_HDR_ID FROM MS_BLK_HDR
                                            WHERE  CRTD_AT < @cutoff_date);
		
		  ---------------------PURGE INGESTION ENTRIES------------------Purge ingestion entries from MS_INGSTN_RCRD
		DELETE FROM MS_INGSTN_RCRD WHERE INGSTN_RCRD_ID IN (SELECT INGSTN_RCRD_ID FROM MS_INGSTN_RCRD
                                            WHERE  CRTD_AT < @cutoff_date);
        COMMIT TRANSACTION
    END try

    BEGIN catch
        ROLLBACK TRANSACTION

        DECLARE @L_ERROR     NVARCHAR(1000) = '',
                @L_FAILEDExe NVARCHAR(max)

        SET @L_FAILEDExe = 'Error: ' + CONVERT(NVARCHAR(1000), @@ERROR)
                           + ' ;ErrorMessage:' + Error_message()

        SELECT @L_ERROR = CONVERT(NVARCHAR(1000), @L_FAILEDExe)

        PRINT @L_ERROR

        PRINT( 'Exception ' + @L_ERROR )

        RAISERROR(@L_ERROR,16,1)
    END catch
END 
