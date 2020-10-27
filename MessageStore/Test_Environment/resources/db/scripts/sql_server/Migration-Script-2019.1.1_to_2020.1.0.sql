/*
 * Changes:
 * 1. Added a table MS_USER_DATA. This will store the Message Store UI application related user data.
 * 2. Created bulk ingestion tables which will be used to support water marking.
 * 3. Added a column CONNECT_ERR to MS_MSG_EVNT, MS_BLK_EVNT and MS_RCRD_EVNT Tables. this will store the connect error.
 */


/*
* ************** 1. Added a table MS_USER_DATA. This will store the Message Store UI application related user data. ****************
*/

CREATE TABLE MS_USER_DATA
(
	USER_ID		VARCHAR(255)	PRIMARY KEY ,
	USER_DATA	VARCHAR(4000)	NOT NULL ,
	CREATED_AT	DATETIME		NOT NULL
)

/*
   ************** 2. Create bulk ingestion related schema 
*/
CREATE TABLE MS_INGSTN_RCRD 
(
    INGSTN_RCRD_ID  NUMERIC(16) NOT NULL IDENTITY(1,1),
    CRTD_AT        DATETIME NOT NULL,
    SRVC_NAME      VARCHAR(255) NOT NULL,
    SRVC_INST      VARCHAR(255),
	BULK_ID		   VARCHAR(255) NOT NULL,
    BLK_LOC        VARCHAR(255) NOT NULL    
);

EXEC sp_addextendedproperty 'MS_Description' , 'Table that saves bulk ingestion records' , 'USER' , 'dbo' , 'TABLE' , 'MS_INGSTN_RCRD'	

ALTER TABLE MS_INGSTN_RCRD ADD CONSTRAINT INGSTN_RCRD_ID_PK PRIMARY KEY ( INGSTN_RCRD_ID );

ALTER TABLE MS_INGSTN_RCRD ADD CONSTRAINT INGSTN_RCRD_UK UNIQUE ( SRVC_NAME, BULK_ID );

CREATE TABLE MS_BLK_INGSTN 
(
    BLK_INGSTN_ID  NUMERIC(16) NOT NULL IDENTITY(1,1),
    LST_INGSTD_AT  DATETIME NOT NULL,
    BLK_INGSTN_RCRD_ID        NUMERIC(16) NOT NULL,
    ING_SRVC_NAME      VARCHAR(255) NOT NULL,
    CUR_POS            NUMERIC(16) NOT NULL    
);

EXEC sp_addextendedproperty 'MS_Description' , 'Table that keeps track of the bulk ingestions' , 'USER' , 'dbo' , 'TABLE' , 'MS_BLK_INGSTN'	

ALTER TABLE MS_BLK_INGSTN ADD CONSTRAINT BLK_INGSTN_ID_PK PRIMARY KEY ( BLK_INGSTN_ID );

ALTER TABLE MS_BLK_INGSTN ADD CONSTRAINT BLK_INGSTN_UK UNIQUE ( BLK_INGSTN_RCRD_ID, ING_SRVC_NAME );

ALTER TABLE MS_BLK_INGSTN ADD CONSTRAINT MS_BULK_INGSTN_FK FOREIGN KEY ( BLK_INGSTN_RCRD_ID ) REFERENCES MS_INGSTN_RCRD ( INGSTN_RCRD_ID ) ON DELETE CASCADE;

CREATE TABLE MS_BLK_INGSTN_EVNT 
(
    BLK_INGSTN_EVNT_ID        NUMERIC(16) NOT NULL IDENTITY(1,1),
	BLK_INGSTN_ID        NUMERIC(16) NOT NULL,
    INGSTD_AT  DATETIME NOT NULL,
    ING_SRVC_INST      VARCHAR(255),    
    STRT_POS       NUMERIC(16) NOT NULL,
    END_POS       NUMERIC(16) NOT NULL
);

EXEC sp_addextendedproperty 'MS_Description' , 'Table that captures the ingestion events of a service' , 'USER' , 'dbo' , 'TABLE' , 'MS_BLK_INGSTN_EVNT'		

ALTER TABLE MS_BLK_INGSTN_EVNT ADD CONSTRAINT MS_BULK_INGSTN_EVNT_FK FOREIGN KEY ( BLK_INGSTN_ID ) REFERENCES MS_BLK_INGSTN ( BLK_INGSTN_ID ) ON DELETE CASCADE;


/********* Adding CONNECT_ERR column to MS_MSG_EVNT *********/

ALTER TABLE MS_MSG_EVNT ADD CONNECT_ERR NVARCHAR (MAX);

/********* Adding CONNECT_ERR column to MS_BLK_EVNT *********/

ALTER TABLE MS_BLK_EVNT ADD CONNECT_ERR NVARCHAR (MAX);

/********* Adding CONNECT_ERR column to MS_RCRD_EVNT *********/

ALTER TABLE MS_RCRD_EVNT ADD CONNECT_ERR NVARCHAR (MAX);

/*
* ************** 3. Add the current message store schema version. ****************
*/
INSERT INTO MS_VER(VER, CRTD_AT) VALUES('2020.1.0', CURRENT_TIMESTAMP);

