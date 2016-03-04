CREATE OR REPLACE PACKAGE bil_item_integration_pkg
AS
   TYPE sys_refcursor IS REF CURSOR;

   PROCEDURE dummy_proc (
      p_item_id              NUMBER DEFAULT NULL,
      ERROR_CODE       OUT   VARCHAR2,
      error_message    OUT   VARCHAR2,
      error_severity   OUT   NUMBER,
      error_status     OUT   NUMBER
   );

   PROCEDURE bil_item_integration (
      p_item_id         NUMBER DEFAULT NULL,
      ref_data    OUT   sys_refcursor
   );
END bil_item_integration_pkg;
/

