CREATE OR REPLACE PACKAGE bilc_po_pr_integration_pkg
AS
   TYPE pr_table_type IS TABLE OF bilc_po_pr_staging_tbl%ROWTYPE
      INDEX BY BINARY_INTEGER;

   ln_error_no    NUMBER                                    := 0;
   lt_error_tbl   apps.bilc_integration_error_pkg.error_tbl_type;

   PROCEDURE dummy_proc (
      p_pr_tbl         IN       pr_table_type,
      ERROR_CODE       OUT      VARCHAR2,
      error_message    OUT      VARCHAR2,
      error_severity   OUT      NUMBER,
      error_status     OUT      NUMBER
   );

   PROCEDURE bilc_po_pr_main (p_pr_tbl IN pr_table_type);

   PROCEDURE bilc_po_staging_insert (
      p_pr_rec   IN   bilc_po_pr_staging_tbl%ROWTYPE
   );
END;
/

