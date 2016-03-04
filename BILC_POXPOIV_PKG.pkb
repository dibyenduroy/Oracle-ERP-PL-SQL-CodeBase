CREATE OR REPLACE PACKAGE BODY APPS.BILC_POXPOIV_PKG
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
      retcode                OUT      NUMBER,
      errbuf                 OUT      VARCHAR2,
      p_transaction_source   IN       VARCHAR2,
      p_commit_interval      IN       NUMBER,
      p_shipment_header_id   IN       NUMBER,
      p_aging_period         IN       NUMBER
   )
   IS
      x_progress             VARCHAR2 (3);
      x_shipment_header_id   NUMBER;
      v_org_id               NUMBER          := fnd_profile.VALUE ('ORG_ID');
      v_get_doc_category     VARCHAR2 (1000);
      v_error                VARCHAR2 (1000);
      exit_procedure         EXCEPTION;
      v_document_category    VARCHAR2 (1000);
   BEGIN
      v_get_doc_category := get_doc_category (v_org_id, v_error);
      fnd_file.put_line (fnd_file.LOG,'v_org_id = '||v_org_id);
      fnd_file.put_line (fnd_file.LOG,'v_get_doc_category='||v_get_doc_category);
      IF v_error IS NOT NULL
      THEN
         RAISE exit_procedure;
      END IF;
      asn_debug.put_line (   'Shipment Header ID from runtime parameter = '
                          || TO_CHAR (p_shipment_header_id)
                         );
      /*** begin processing ***/
      bilc_po_invoices_sv1.create_ap_invoices (p_transaction_source,
                                          p_commit_interval,
                                          p_shipment_header_id,
                                          p_aging_period
                                         );
   EXCEPTION
      WHEN exit_procedure
      THEN
         raise_application_error (-20001, v_error);
      WHEN OTHERS
      THEN
         po_message_s.sql_error ('POXPOIV.sql', x_progress, SQLCODE);
         po_message_s.sql_show_error;
         --dbms_output.put_line(substr(fnd_message.get,1,255));
         fnd_file.put_line (fnd_file.LOG, fnd_message.get);
         RAISE;
   END create_receipt;
   FUNCTION get_doc_category (p_org_id IN NUMBER, p_error OUT VARCHAR2)
      RETURN VARCHAR2
   IS
      v_doc_category   VARCHAR2 (240);
   BEGIN
      SELECT doc_category_code
        INTO v_doc_category
        FROM q_bil_pn_doc_cat_ou_mapping_v
       WHERE aop_circle_id = TO_CHAR(p_org_id);
      RETURN (v_doc_category);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_error :=
                 'No Operating Unit vs Sequence defined in your quality plan';
         RETURN (p_error);
      WHEN TOO_MANY_ROWS
      THEN
         p_error := 'Duplicate Sequence defined for this Operating Unit';
         RETURN (p_error);
      WHEN OTHERS
      THEN
         p_error := 'An error occured in OTHERS';
         RETURN (p_error || '-' || SQLERRM);
   END;
END bilc_poxpoiv_pkg;
/