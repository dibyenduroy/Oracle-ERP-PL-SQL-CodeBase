CREATE OR REPLACE PACKAGE APPS.bilc_insert_doccategory_pkg
------------------------------------------------------------------------------------
--    File Name    : bilc_insert_doccategory_pkg.pks
--    Date         : 27-July-2009
--    Author       : Jaswant Singh Hooda
--    Description  :
--
--    Version      :1.0
--
--
--  Modification History :
--  Who              Date          Reason
--------------------------------------------------------------------------------------
IS
   PROCEDURE insert_doccategory (retcode    OUT      NUMBER,
                                 errbuf     OUT      VARCHAR2,
                                 p_org_id   IN       NUMBER,
                                 p_source   IN       VARCHAR2);


   FUNCTION get_doc_category (p_org_id IN NUMBER, 
                              p_error OUT VARCHAR2) RETURN VARCHAR2;

   PROCEDURE bilc_report_format;
END bilc_insert_doccategory_pkg;
/