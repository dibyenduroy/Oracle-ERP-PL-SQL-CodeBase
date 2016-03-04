CREATE OR REPLACE PACKAGE bilc_pr_integration_pkg
AS
   TYPE sys_refcursor IS REF CURSOR;

   PROCEDURE dummy_proc (
      po_header_id              NUMBER DEFAULT NULL,
      ERROR_CODE       OUT   VARCHAR2,
      error_message    OUT   VARCHAR2,
      error_severity   OUT   NUMBER,
      error_status     OUT   NUMBER
   );

   PROCEDURE bilc_pr_integration (
      po_header_id         NUMBER DEFAULT NULL,
      ref_data    OUT   sys_refcursor
   );
END bilc_pr_integration_pkg;