CREATE OR REPLACE PROCEDURE SP_CLEAN_CUST_MELB AS

BEGIN
INSERT INTO ERROR_EVENT (errorid , source_rowid , source_table , filter_id , date_time , action)
SELECT errorid_seq.nextval , rowid , 'A2CUSTMELB' , 9 , SYSDATE , 'MODIFY'
FROM vli.a2custmelb c
WHERE (c.FNAME IN (SELECT firstname FROM DWCUST)) OR (c.phone IN (SELECT phone FROM DWCUST));
-- ^^^ filter 9 puts in rowid of a2custmelb that has identical first name or phone numbers in dwcust
END;
/
CREATE OR REPLACE PROCEDURE SP_UPLOAD_CUSTOMER_MELB AS

BEGIN
	SP_CLEAN_CUST_MELB;
	INSERT INTO DWCUST (DWCUSTID , DWSOURCEIDBRIS, DWSOURCEIDMELB, FIRSTNAME, SURNAME, GENDER, PHONE, POSTCODE, CITY, STATE, CUSTCATNAME)
	SELECT DWCUSTSEQ.nextval , NULL ,c.id , c.fname , c.sname, c.gender, c.phone, c.postcode, c.city, c.state, cat.custcatname
	FROM vli.a2custmelb c
	NATURAL JOIN vli.a2custcategory cat
	WHERE rowid NOT IN (SELECT source_rowid FROM error_event e WHERE e.filter_ID = '9');
	--^^^ inserting clean data not in error_event
	UPDATE DWCUST dc
	SET dc.DWSOURCEIDMELB = (SELECT c.id FROM vli.a2custmelb c WHERE (c.fname = dc.firstname) OR (c.phone = dc.phone))
	FROM DWCUST dc
	WHERE c.rowid IN (SELECT source_rowid FROM error_event e WHERE e.filter_id = '9');
	--^^^^ updating DWCUST DWSOURCEIDMELB for melbcust with identical fname or phone
END;
/