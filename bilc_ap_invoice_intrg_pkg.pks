/* Formatted on 2009/06/30 12:48 (Formatter Plus v4.8.7) */
CREATE OR REPLACE PACKAGE bilc_ap_invoice_intrg_pkg
AS
--
--
--
-- **************************************************************************************
-- *                                                                                    *
-- * PL/SQL Package     :       BILC_AP_INVOICE_INTEGRATION_PKG                         *
-- * Date               :       25-June-2009                                            *
-- * Purpose            :       Package is used for Invoice Integration with Maximo     *
-- *                                                                                    *
-- *------------------------------------------------------------------------------------*
-- * Modifications      :                                                               *
-- *                                                                                    *
-- * Version     DD-MON-YYYY     Person        Changes Made                             *
-- * ----------  -------------  ------------  ----------------------------------------- *
-- * DRAFT1A     25-jun-2009     Dibyendu     Initial Draft Version                     *
-- *                                                                                    *
-- **************************************************************************************
--
--
   TYPE sys_refcursor IS REF CURSOR;

   PROCEDURE dummy_proc (
      p_invoice_id     IN       NUMBER,
      ERROR_CODE       OUT      VARCHAR2,
      error_message    OUT      VARCHAR2,
      error_severity   OUT      NUMBER,
      error_status     OUT      NUMBER
   );

   PROCEDURE bilc_ap_invoice_integration (
      p_invoice_id   IN      NUMBER DEFAULT NULL,
      ref_data       OUT   sys_refcursor
   );
END bilc_ap_invoice_intrg_pkg;