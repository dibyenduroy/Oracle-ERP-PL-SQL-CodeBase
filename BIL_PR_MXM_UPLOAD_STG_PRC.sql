/* Formatted on 2009/06/11 11:13 (Formatter Plus v4.8.7) */
CREATE OR REPLACE PROCEDURE bil_pr_mxm_upload_stg_prc (
   errbuf    OUT   VARCHAR2,
   retcode   OUT   NUMBER
)
IS
    --v_tbl_pr_req is table of po_requisitions_interface_all%rowtype
   --index by binary_integer;

   --v_tbl_pr_req  v_pr_rec;

   /* Cursor for selecting distinct Requisition Numbers*/
   CURSOR bil_pr_req_num
   IS
      SELECT DISTINCT pr_num
                 FROM bil_pr_stg;

   /* Cursor For Fetching a Requisition Header & Detail Together */
   CURSOR bil_req_hd_cr (p_pr_num NUMBER)
   IS
      SELECT *
        FROM bil_pr_stg
       WHERE pr_num = p_pr_num;
/* Cursor for Fetching Requisition Distribution Data Distributions */
BEGIN
   FOR pr_no IN bil_pr_req_num
   LOOP
      FOR i IN bil_req_hd_cr (pr_no.pr_num)
      LOOP
         BEGIN
/* All validations to be included */
            INSERT INTO PO_REQUISITIONS_INTERFACE_ALL 
                        (interface_source_code, source_type_code,
                         destination_type_code, authorization_status,
                         preparer_id,deliver_to_requestor_name, item_id, category_id, quantity,
                         unit_of_measure, destination_organization_id,
                         deliver_to_location_id, deliver_to_requestor_id,
                         need_by_date, org_id, req_number_segment1,
                         requisition_type, line_type
                        )
                 VALUES ('MXM', 'VENDOR',
                         'EXPENSE', 'APPROVED',
                         i.preparer_id, i.requester,i.item, i.item_category, i.quantity,
                         i.uom, i.ORGANIZATION,
                         i.LOCATION, i.requester_id,
                         i.need_by_date, i.operating_unit, pr_no.pr_num,
                         'Purchase Requisition', 'Goods/Services'
                        );

            INSERT INTO po_req_dist_interface_all
                        (charge_account_id, accrual_account_id,
                         --DISTRIBUTION_NUMBER,
                         --DESTINATION_TYPE_CODE,
                         interface_source_code, variance_account_id
                        )
                 VALUES (i.charge_account_d, i.accrual_account_d,
                         'MXM', i.variance_account
                        );
						COMMIT;
         --i.DESTINATION;
         END;
      END LOOP;
   END LOOP;
EXCEPTION
   WHEN OTHERS
   THEN
      fnd_file.put_line (fnd_file.LOG, 'Errored due to ' || SQLERRM);
END bil_pr_mxm_upload_stg_prc;