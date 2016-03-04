/* Formatted on 2009/07/23 13:30 (Formatter Plus v4.8.7) */
CREATE OR REPLACE PACKAGE BODY bilc_ap_invoice_intrg_pkg
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
   PROCEDURE dummy_proc (
      p_invoice_id     IN       NUMBER,
      ERROR_CODE       OUT      VARCHAR2,
      error_message    OUT      VARCHAR2,
      error_severity   OUT      NUMBER,
      error_status     OUT      NUMBER
   )
   IS
   BEGIN
      error_status := 0;
      error_severity := 1;
      ERROR_CODE := NULL;
      error_message := NULL;
   END dummy_proc;

   PROCEDURE bilc_ap_invoice_integration (
      p_invoice_id         NUMBER DEFAULT NULL,
      ref_data       OUT   sys_refcursor
   )
   IS
      ls_where   VARCHAR2 (30000) := ' and 1 = 1 ';
      p_query    VARCHAR2 (30000);
   BEGIN
      IF p_invoice_id IS NULL
      THEN
         ls_where := ls_where || ' ';
      ELSE
         ls_where := ls_where || ' and aia.invoice_id = ' || p_invoice_id;
      END IF;

      p_query :=
            'SELECT aia.org_id org_id,hro.NAME operating_unit, aia.invoice_num invoice_num,'
         || ' aia.description, aia.approval_status approval_status,'
         || ' aia.amount_paid amount_paid,'
         || ' aia.approved_amount approved_amount,'
         || ' aia.attribute1 inv_attribute1,'
         || ' aia.attribute2 inv_attribute2,'
         || ' aia.attribute3 inv_attribute3, aia.attribute4 inv_attribute4,'
         || ' aia.attribute5 inv_attribute5, aia.attribute6 inv_attribute6,'
         || ' aia.attribute7 inv_attribute7, aia.attribute8 inv_attribute8,'
         || ' aia.attribute9 inv_attribute9,'
         || ' aia.attribute10 inv_attribute10,'
         || ' aia.attribute11 inv_attribute11,'
         || ' aia.attribute12 inv_attribute12,'
         || ' aia.attribute13 inv_attribute13,'
         || ' aia.attribute14 inv_attribute14,'
         || ' aia.attribute15 inv_attribute15,'
         || ' to_char(aia.creation_date,'
         || ''''
         || 'DD-MON-YYYY HH24:MI:SS'
         || ''''
         || ') inv_creation_date,'
         || ' aida.attribute1 inv_dist_attribute1,'
         || ' aida.attribute2 inv_dist_attribute2,'
         || ' aida.attribute3 inv_dist_attribute3,'
         || ' aida.attribute4 inv_dist_attribute4,'
         || ' aida.attribute5 inv_dist_attribute5,'
         || ' aida.attribute6 inv_dist_attribute6,'
         || ' aida.attribute7 inv_dist_attribute7,'
         || ' aida.attribute8 inv_dist_attribute8,'
         || ' aida.attribute9 inv_dist_attribute9,'
         || ' aida.attribute10 inv_dist_attribute10,'
         || ' aida.attribute11 inv_dist_attribute11,'
         || ' aida.attribute12 inv_dist_attribute12,'
         || ' aida.attribute13 inv_dist_attribute13,'
         || ' aida.attribute14 inv_dist_attribute14,'
         || ' aida.attribute15 inv_dist_attribute15,'
         || ' aida.amount AMOUNT,'
         || ' aida.quantity_invoiced quantity_invoiced,'
         || ' aia.payment_method_lookup_code,'
         || ' aia.payment_status_flag payment_status_flag,'
         || ' to_char(aia.goods_received_date,'
         || ''''
         || 'DD-MON-YYYY HH24:MI:SS'
         || ''''
         || ') goods_received_date,'
         || ' aia.accts_pay_code_combination_id'
         || ' accts_pay_code_combination_id,'
         || 'gcc.concatenated_segments concat_account_id,'
         || 'poh.segment1 po_number, poh.po_header_id,'
         || ' ppf.first_name po_buyer, ppf.email_address po_buyer_email,'
         || ' ppf.attribute1 buyer_attribute1,'
         || ' ppf.attribute2 buyer_attribute2,'
         || ' ppf.attribute3 buyer_attribute3,'
         || ' ppf.attribute4 buyer_attribute4,'
         || ' ppf.attribute4 buyer_attribute4,'
         || ' ppf.attribute5 buyer_attribute5,'
         || ' ppf.attribute6 buyer_attribute6,'
         || ' ppf.attribute7 buyer_attribute7,'
         || ' ppf.attribute8 buyer_attribute8,'
         || ' ppf.attribute9 buyer_attribute9,'
         || ' ppf.attribute10 buyer_attribute10,'
         || ' ppf.attribute11 buyer_attribute11,'
         || ' ppf.attribute13 buyer_attribute13,'
         || ' ppf.attribute14 buyer_attribute14,'
         || ' ppf.attribute15 buyer_attribute15,'
         || ' poh.authorization_status po_authorization_status,'
         || ' to_char(poh.creation_date,'
         || ''''
         || 'DD-MON-YYYY HH24:MI:SS'
         || ''''
         || ') po_creation_date,'
         || ' hrlah1.location_code po_bill_to_location,'
         || ' hrlah1.attribute1 billto_loc_attribute1,'
         || ' hrlah1.attribute2 billto_loc_attribute2,'
         || ' hrlah1.attribute3 billto_loc_attribute3,'
         || ' hrlah1.attribute4 billto_loc_attribute4,'
         || ' hrlah1.attribute5 billto_loc_attribute5,'
         || ' hrlah1.attribute6 billto_loc_attribute6,'
         || ' hrlah1.attribute7 billto_loc_attribute7,'
         || ' hrlah1.attribute8 billto_loc_attribute8,'
         || ' hrlah1.attribute9 billto_loc_attribute9,'
         || ' hrlah1.attribute10 billto_loc_attribute10,'
         || ' hrlah1.attribute11 billto_loc_attribute11,'
         || ' hrlah1.attribute12 billto_loc_attribute12,'
         || ' hrlah1.attribute13 billto_loc_attribute13,'
         || ' hrlah1.attribute14 billto_loc_attribute14,'
         || ' hrlah1.attribute15 billto_loc_attribute15,'
         || ' hrlah2.location_code po_ship_to_location,'
         || ' hrlah2.attribute1 ship_to_loc_attribute1,'
         || ' hrlah2.attribute2 ship_to_loc_attribute2,'
         || ' hrlah2.attribute3 ship_to_loc_attribute3,'
         || ' hrlah2.attribute4 ship_to_loc_attribute4,'
         || ' hrlah2.attribute5 ship_to_loc_attribute5,'
         || ' hrlah2.attribute6 ship_to_loc_attribute6,'
         || ' hrlah2.attribute7 ship_to_loc_attribute7,'
         || ' hrlah2.attribute8 ship_to_loc_attribute8,'
         || ' hrlah2.attribute9 ship_to_loc_attribute9,'
         || ' hrlah2.attribute10 ship_to_loc_attribute10,'
         || ' hrlah2.attribute11 ship_to_loc_attribute11,'
         || ' hrlah2.attribute12 ship_to_loc_attribute12,'
         || ' hrlah2.attribute13 ship_to_loc_attribute13,'
         || ' hrlah2.attribute14 ship_to_loc_attribute14,'
         || ' hrlah2.attribute15 ship_to_loc_attribute15,'
         || ' poh.attribute1 poh_attribute1, poh.attribute2 poh_attribute2,'
         || ' poh.attribute3 poh_attribute3, poh.attribute4 poh_attribute4,'
         || ' poh.attribute5 poh_attribute5, poh.attribute6 poh_attribute6,'
         || ' poh.attribute7 poh_attribute7, poh.attribute8 poh_attribute8,'
         || ' poh.attribute9 poh_attribute9,'
         || ' poh.attribute10 poh_attribute10,'
         || ' poh.attribute11 poh_attribute11,'
         || ' poh.attribute12 poh_attribute12,'
         || ' poh.attribute13 poh_attribute13,'
         || ' poh.attribute14 poh_attribute14,'
         || ' poh.attribute15 poh_attribute15, pol.amount pol_amount, pol.line_num pol_line_num,'
         || ' pol.attribute_category pol_attribute_category,'
         || ' pol.base_qty pol_base_qty,'
         || ' pol.base_unit_price pol_base_unit_price,'
         || ' pol.base_uom pol_base_uom, pol.item_id,'
         || ' pol.quantity pol_quantity, pol.attribute1 pol_attribute1,'
         || ' pol.attribute2 pol_attribute2, pol.attribute3 pol_attribute3,'
         || ' pol.attribute4 pol_attribute4, pol.attribute5 pol_attribute5,'
         || ' pol.attribute6 pol_attribute6, pol.attribute7 pol_attribute7,'
         || ' pol.attribute8 pol_attribute8, pol.attribute9 pol_attribute9,'
         || ' pol.attribute10 pol_attribute10,'
         || ' pol.attribute11 pol_attribute11,'
         || ' pol.attribute12 pol_attribute12,'
         || ' pol.attribute13 pol_attribute13,'
         || ' pol.attribute14 pol_attribute14,'
         || ' pol.attribute15 pol_attribute15,'
         || ' pol.category_id pol_category_id,'
         || ' to_char(pol.closed_date,'
         || ''''
         || 'DD-MON-YYYY HH24:MI:SS'
         || ''''
         || ') pol_closed_date,'
         || ' pol.committed_amount pol_committed_amount,'
         || ' pol.contractor_first_name pol_contractor_first_name,'
         || ' pol.contractor_last_name pol_contractor_last_name,'
         || ' pol.contract_num pol_contract_num,'
         || ' pol.from_header_id pol_from_header_id,'
         || ' pol.from_line_location_id from_line_location_id,'
         || ' poda.attribute1 pod_attribute1,'
         || ' poda.attribute2 pod_attribute2,'
         || ' poda.attribute3 pod_attribute3,'
         || ' poda.attribute4 pod_attribute4,'
         || ' poda.attribute5 pod_attribute5,'
         || ' poda.attribute6 pod_attribute6,'
         || ' poda.attribute7 pod_attribute7,'
         || ' poda.attribute8 pod_attribute8,'
         || ' poda.attribute9 pod_attribute9,'
         || ' poda.attribute10 pod_attribute10,'
         || ' poda.attribute11 pod_attribute11,'
         || ' poda.attribute12 pod_attribute12,'
         || ' poda.attribute13 pod_attribute13,'
         || ' poda.attribute14 pod_attribute14,'
         || ' poda.attribute15 pod_attribute15,'
         || ' poda.amount_billed pod_amount_billed,'
         || ' poda.amount_ordered pod_amount_ordered,'
         || ' poda.amount_delivered pod_amount_delivered,'
         || ' poda.accrual_account_id pod_accrual_account_id,'
         || ' poda.budget_account_id, poda.code_combination_id,'
         || 'gcc1.concatenated_segments poda_concat_account_id,'
         || 'poda.deliver_to_person_id, ppf1.first_name deliver_to_person,'
         || 'ppf1.email_address,  '
         || 'prha.REQUISITION_HEADER_ID REQUISITION_HEADER_ID,'
         || 'prha.ATTRIBUTE1 REQ_H_ATTRIBUTE1,prha.ATTRIBUTE2 REQ_H_ATTRIBUTE2,prha.ATTRIBUTE3 REQ_H_ATTRIBUTE3,'
         || 'prha.ATTRIBUTE4 REQ_H_ATTRIBUTE4,prha.ATTRIBUTE5 REQ_H_ATTRIBUTE5,prha.ATTRIBUTE6 REQ_H_ATTRIBUTE6,'
         || 'prha.ATTRIBUTE7 REQ_H_ATTRIBUTE7,prha.ATTRIBUTE8 REQ_H_ATTRIBUTE8,prha.ATTRIBUTE9 REQ_H_ATTRIBUTE9,'
         || 'prha.ATTRIBUTE10 REQ_H_ATTRIBUTE10,prha.ATTRIBUTE11 REQ_H_ATTRIBUTE11,prha.ATTRIBUTE12 REQ_H_ATTRIBUTE12,'
         || 'prha.ATTRIBUTE13 REQ_H_ATTRIBUTE13,prha.ATTRIBUTE14 REQ_H_ATTRIBUTE14,prha.ATTRIBUTE15 REQ_H_ATTRIBUTE15,'
         || 'prla.REQUISITION_LINE_ID REQUISITION_LINE_ID,prla.ATTRIBUTE1 REQ_L_ATTRIBUTE1,prla.ATTRIBUTE2 REQ_L_ATTRIBUTE2,'
         || 'prla.ATTRIBUTE3 REQ_L_ATTRIBUTE3,prla.ATTRIBUTE4 REQ_L_ATTRIBUTE4,prla.ATTRIBUTE5 REQ_L_ATTRIBUTE5,prla.ATTRIBUTE6 REQ_L_ATTRIBUTE6,'
         || 'prla.ATTRIBUTE7 REQ_L_ATTRIBUTE7,prla.ATTRIBUTE8 REQ_L_ATTRIBUTE8,prla.ATTRIBUTE9 REQ_L_ATTRIBUTE9,prla.ATTRIBUTE10 REQ_L_ATTRIBUTE10,'
         || 'prla.ATTRIBUTE11 REQ_L_ATTRIBUTE11,prla.ATTRIBUTE12 REQ_L_ATTRIBUTE12,prla.ATTRIBUTE13 REQ_L_ATTRIBUTE13,prla.ATTRIBUTE14 REQ_L_ATTRIBUTE14,  '
         || 'prla.ATTRIBUTE15 REQ_L_ATTRIBUTE15'
         || ' FROM   '
         || 'ap_invoices_all aia,  '
         || 'ap_invoice_distributions_all aida,'
         || 'po_distributions_all poda,'
         || 'po_headers_all poh,'
         || 'po_lines_all pol,'
         || 'po_line_locations_all pla,'
         || 'gl_code_combinations_kfv gcc,'
         || 'gl_code_combinations_kfv gcc1,'
         || 'hr_locations_all hrlah1,'
         || 'hr_locations_all hrlah2,'
         || 'per_all_people_f ppf,'
         || 'per_all_people_f ppf1,'
         || 'hr_operating_units hro  ,'
         || 'po_req_distributions_all prda,'
         || 'po_requisition_lines_all prla,'
         || 'po_requisition_headers_all prha '
         || 'WHERE '
         || 'aia.invoice_id = aida.invoice_id   '
         || 'and  aida.ORG_ID = hro.ORGANIZATION_ID   '
         || 'and  aida.po_distribution_id = poda.po_distribution_id  '
         || 'and  poda.line_location_id=pla.line_location_id  '
         || 'and  pla.po_line_id = pol.po_line_id   '
         || 'and  pol.po_header_id=poh.po_header_id  '
         || 'and  ppf.person_id = poh.agent_id  '
         || 'and  sysdate between ppf.effective_start_date and ppf.effective_end_date  '
         || 'and  gcc.code_combination_id = aia.accts_pay_code_combination_id  '
         || 'and  poda.code_combination_id = gcc1.code_combination_id  '
         || 'and poda.deliver_to_person_id = ppf1.person_id(+)  '
         || 'and hrlah1.location_id = poh.bill_to_location_id  '
         || 'and hrlah2.location_id = poh.ship_to_location_id  '
         || 'and prda.DISTRIBUTION_ID(+)=poda.REQ_DISTRIBUTION_ID '
         || 'and prda.REQUISITION_LINE_ID=prla.REQUISITION_LINE_ID '
         || 'and prla.REQUISITION_HEADER_ID=prha.REQUISITION_HEADER_ID '
         || ls_where;

      OPEN ref_data FOR p_query;
   END bilc_ap_invoice_integration;
END bilc_ap_invoice_intrg_pkg;