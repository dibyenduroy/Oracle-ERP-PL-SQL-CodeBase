


CREATE PROCEDURE xxlcb_ld_hist_prc 
is

BEGIN

 /* Inserting Data into Staging Tables from Source Tables   */
 
 INSERT INTO xxlcb.xxlcb_inv_hist_stg
 (
   <<plcb_code>>,
   <<cost_center_no>>,
   <<inventory_date>>,
   <<item_type>>
 )
 (SELECT a.plcb_code,
         a.cost_center_no,
		 a.inventory_date,
		 a.item_type
		 
		 from prdmstr.week_end_inventory@teame a, item_master b
		 where << need the joining condition between invetory and item master>>
		 <<b.item_status='N'>> 
  );
  
 DBMS_OUTPUT.put_line( SQL%ROWCOUNT || ' Rows Inserted Successfully' );
 COMMIT;
 EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
                             (    'Error while inserting data into staging table using XXLCB_LD_HIST_PRC procedure: '
                               || SQLERRM );
         raise_application_error( -20002
                                , 'Error while inserting data into staging table using XXLCB_INV_HIST_STG procedure ' );
 