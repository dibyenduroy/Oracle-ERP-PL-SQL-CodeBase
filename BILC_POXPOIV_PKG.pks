CREATE OR REPLACE PACKAGE APPS.BILC_POXPOIV_PKG
------------------------------------------------------------------------------------
--    File Name    : BILC_POXPOIV_PKG.pkb
--    Date         : July 28,2009
--    Description  :
--    
--    Version      :1.0
--
--
--  Modification History :
--  Who              Date          Reason
-------------------------------------------------------------------------------------
IS
   PROCEDURE create_receipt (
      retcode    OUT      NUMBER,
      errbuf     OUT      VARCHAR2,
      P_transaction_source  IN  VARCHAR2,
   P_commit_interval      IN  NUMBER,
   P_shipment_header_id  IN  NUMBER,
   P_aging_period   IN  NUMBER
   );

   FUNCTION get_doc_category (p_org_id IN NUMBER, p_error OUT VARCHAR2)
      RETURN VARCHAR2;

END BILC_POXPOIV_PKG;
/