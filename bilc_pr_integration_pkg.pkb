CREATE OR REPLACE PACKAGE BODY bilc_pr_integration_pkg
AS
   PROCEDURE dummy_proc (
      po_header_id              NUMBER DEFAULT NULL,
      ERROR_CODE       OUT   VARCHAR2,
      error_message    OUT   VARCHAR2,
      error_severity   OUT   NUMBER,
      error_status     OUT   NUMBER
   )
   IS
   BEGIN
      error_status               := 0;
      error_severity             := 1;
      ERROR_CODE                 := NULL;
      error_message              := NULL;
   END dummy_proc;

   PROCEDURE bilc_pr_integration (
      po_header_id         NUMBER DEFAULT NULL,
      ref_data    OUT   sys_refcursor
   )
   IS
      ls_where                      VARCHAR2 (30000) := ' and 1 = 1 ';
      p_query                       VARCHAR2 (30000);
   BEGIN
      IF po_header_id IS NULL
      THEN
         ls_where                   := ls_where || ' ';
      ELSE
         ls_where                   :=
                     ls_where || ' and pha.po_header_id = ' || po_header_id;
      END IF;

      p_query:=
	  
'SELECT pha.po_header_id,pha.segment1,prha.requisition_header_id,prha.attribute6,prha.attribute7,ppf1.FULL_NAME Buyer,ppf2.FULL_NAME Preparer,pha.ORG_ID,'||
'pha.COMMENTS,prla.ITEM_ID,prla.ITEM_DESCRIPTION,prla.INVENTORY_SOURCE_CONTEXT,prla.CATEGORY_ID,prha.INTERFACE_SOURCE_CODE,'||
 'prha.AUTHORIZATION_STATUS ,pha.VENDOR_ID,pva.VENDOR_NAME,pda.DELIVER_TO_LOCATION_ID'||
 'FROM'|| 
       'po_headers_all pha,'||
	   'po_vendors pva,'||
	   'per_all_people_f ppf1,'||
	   'per_all_people_f ppf2,'||
	   'po_requisition_headers_all prha,'||
       'po_requisition_lines_all prla,'||
       'po_req_distributions_all prda,'||
       'po_distributions_all pda'||
 'WHERE prha.requisition_header_id = prla.requisition_header_id'||
   'AND prla.requisition_line_id = prda.requisition_line_id'||
   'AND prda.distribution_id = pda.req_distribution_id'||
   'AND prha.attribute6 IS NOT NULL'||
   'AND prha.attribute7 IS NOT NULL'||
   'AND pda.po_header_id = pha.po_header_id'||
   'AND pha.AGENT_ID = ppf1.PERSON_ID'||
   'AND prha.PREPARER_ID=ppf2.PERSON_ID'||
   'AND sysdate between ppf2.EFFECTIVE_START_DATE and ppf2.EFFECTIVE_END_DATE'||
   'AND sysdate between ppf1.EFFECTIVE_START_DATE and ppf1.EFFECTIVE_END_DATE'||'AND pva.VENDOR_ID=pha.VENDOR_ID'||ls_where;
      OPEN ref_data FOR p_query;
   END bilc_pr_integration;
END bilc_pr_integration_pkg;
/

