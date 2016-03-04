CREATE OR REPLACE PACKAGE BODY APPS.BILC_PO_INVOICES_SV2 AS
/* $Header: POXIVRPB.pls 115.52.11510.19 2007/05/24 06:21:12 kagupta ship $*/
-- Read the profile option that enables/disables the debug log
g_asn_debug VARCHAR2(1) := NVL(FND_PROFILE.VALUE('PO_RVCTP_ENABLE_TRACE'),'N');
create_invoice_error          EXCEPTION; --SBI
/* <PAY ON USE FPI START> */
    g_fetch_size CONSTANT NUMBER := 1000;
    g_pkg_name   CONSTANT VARCHAR2(20) := 'BILC_PO_INVOICES_SV2';
/* Bug 5534479.The g_ variables below were initialized as NULL and was used in the
   comparions.This was failing the if clause and call to get valid tax id was not getting
   called.Intialize to -99 */
    /* For caching values */
    g_old_tax_code_id AP_TAX_CODES.tax_id%TYPE := -99;
    g_old_tax_rate AP_TAX_CODES.tax_rate%TYPE := -99;
/* <PAY ON USE FPI END> */
/*  Bug 3506659 */
    g_this_invoice_dist_cnt  NUMBER  := 0;
    g_this_invoice_has_tax   BOOLEAN := FALSE;
    g_inv_line_id           ap_invoice_lines_interface.invoice_line_id%TYPE := 0;
/*  Bug 3506659 */
/* =================================================================
 FUNCTION NAME:  create_receipt_invoices()
==================================================================*/
FUNCTION  create_receipt_invoices(X_commit_interval   IN NUMBER,
      X_rcv_shipment_header_id  IN NUMBER,
      X_receipt_event   IN VARCHAR2,
          X_aging_period   IN NUMBER DEFAULT NULL)
       RETURN BOOLEAN
 IS
X_progress      VARCHAR2(3)  := NULL;
/* Cursor bind var for aging period */
X_profile       VARCHAR2(20) := NULL;
l_aging_period  NUMBER := NULL;
/* Actual quauntity for the invoice */
X_received_quantity NUMBER := 0;
X_received_amount NUMBER := 0;
/*Bug# 1539257 */
X_tmp_batch_id  NUMBER;
X_batch_name    ap_batches.batch_name%TYPE;
/* Bug:396027. gtummala. 10/17/96
 * Now the cursor picks up previously REJECTED transactions as well
 * as PENDING ones
 */
/* Bug:551612. gtummala. 11/02/97
 * Now we will only pick up those trnxs where rts.invoice_status_code is
 * 'PENDING' or 'REJECTED'. We won't pick up where it is null.
 * The enter receipts form will only set this to 'PENDING' if the
 * supplier site is set up for pay on receipt.
 */
/* Bug 1930776. We need to pick up pay_on_receipt_summary_code from the
 * purchasing site even if it is defined in the alternate pay site.
*/
/* Bug 5443198.Forward port of 4732594. There was performance issue when running the pay on receipt pgm.
Index RCV_TRANSACTIONS_N16 was on a nullable field.So have modified the index
to create a function based index.Also have split the query into 2 parts,for
Purchase Orders and Releases */
/***** Cursor declaration ****/
CURSOR C_receipt_txns IS
SELECT  /*+ INDEX (rts RCV_TRANSACTIONS_N16) */
        rts.rowid                      rcv_txn_rowid,
        rts.transaction_id,
        rts.po_header_id,
        rts.po_release_id,
        rts.po_line_id,
        rts.po_line_location_id,
        rts.po_distribution_id,
        rsh.vendor_id,
        pvds.segment1                  vendor_num,
        NVL(pvss.default_pay_site_id,pvss.vendor_site_id) default_pay_site_id,
        pvss2.vendor_site_code         pay_site_code,
        pvss.pay_on_receipt_summary_code,  -- default pay site's summary code
        pvss.auto_tax_calc_flag, --bug 3506659
        pvss.ap_tax_rounding_rule,  --bug 3506659
        rts.shipment_header_id,
/* Bug 3065403 - Taking rsl.packing slip if rsh.packing slip is null.
   Also changed the alias packing_slip to pack_slip to avoid ambiguous
  column error in the order by clause.*/
        NVL(rsh.packing_slip, nvl(rsl.packing_slip,rsh.receipt_num)) pack_slip,
        rsh.receipt_num,
        rts.shipment_line_id,
        rts.transaction_date,
        rts.amount,
        rts.quantity,
        nvl(plls.price_override, pls.unit_price) po_unit_price, /* Bug4199745 */
        rts.currency_code,
        rts.currency_conversion_type,
/* Note that we must decode currency type because the receiving programs put in
   a 1 for the currency rate if base currency is same as PO.  Purchasing and
   Payables expects that the rate be null if base currency=PO/Invoice currency. */
        decode (rts.currency_conversion_type,null,null,rts.currency_conversion_rate) currency_conversion_rate,
        rts.currency_conversion_date,
        NVL(NVL(plls.terms_id, phs.terms_id) , pvss2.terms_id) payment_terms_id,
        DECODE(plls.taxable_flag, 'Y', plls.tax_code_id, NULL) tax_code_id,
        pls.item_description,
        pls.matching_basis,
  rsh.SHIPMENT_NUM,---- added by sandeep on 11-sep-2008 for invoice num
  rsh.SHIPPED_DATE, ------ added by sandeep on 11-sep-2008 for invoice num,
  rsh.SHIP_TO_ORG_ID, ------ added by sandeep on 15-april-2009 for DOA
  phs.segment1 po_num,--added by Jaswant Hooda on 28 July2009 for Invoice Number
  rsh.attribute10 vendor_invoice_num--added by Jaswant Hooda on 27 Aug 2009 for Invoice Number
FROM    po_vendor_sites         pvss,
        po_vendor_sites         pvss2,
        po_vendors              pvds,
        po_headers              phs,
        -- po_releases             prs, Bug 5443198
        po_lines                pls,
        po_line_locations       plls,
        rcv_shipment_headers    rsh,
        rcv_shipment_lines      rsl,
        rcv_transactions        rts
WHERE   rts.shipment_header_id = rsh.shipment_header_id
AND     rts.po_header_id = phs.po_header_id
-- AND     rts.po_release_id = prs.po_release_id(+)  Bug 5443198
AND     rts.po_line_location_id = plls.line_location_id
AND     rts.po_line_id = pls.po_line_id
AND     rts.shipment_header_id = rsl.shipment_header_id
AND     rts.shipment_line_id = rsl.shipment_line_id
AND     phs.vendor_id =  pvds.vendor_id
AND     phs.vendor_site_id = pvss.vendor_site_id
AND     phs.pcard_id is null
AND     rsh.receipt_source_code = 'VENDOR'
AND     rts.source_document_code = 'PO'
AND     rts.invoice_status_code  IN ('PENDING','REJECTED') /*Bug:551612 */
AND     rts.transaction_type =  X_receipt_event
/* <PAY ON USE FPI START> */
AND     pvss.pay_on_code IN ('RECEIPT', 'RECEIPT_AND_USE')
AND     PHS.PAY_ON_CODE  IN ('RECEIPT', 'RECEIPT_AND_USE')  -- Bug 5443198
-- AND     decode(nvl(rts.po_release_id, -999), -999, phs.pay_on_code,prs.pay_on_code)
--                 IN ('RECEIPT', 'RECEIPT_AND_USE')           Bug 5443198
AND     NVL(plls.consigned_flag,'N') <> 'Y'
/* <PAY ON USE FPI END> */
AND     pvss2.vendor_site_id = NVL(pvss.default_pay_site_id,pvss.vendor_site_id)
AND     nvl(rsh.asn_type, ' ') <> 'ASBN'
AND     rts.transaction_date <= sysdate - l_aging_period -- Bug 4488601.ERS program should consider timestamps.
AND     rts.po_release_id IS null -- Bug 5443198
UNION
SELECT  /*+ INDEX (rts RCV_TRANSACTIONS_N16) */
        rts.rowid                      rcv_txn_rowid,
        rts.transaction_id,
        rts.po_header_id,
        rts.po_release_id,
        rts.po_line_id,
        rts.po_line_location_id,
        rts.po_distribution_id,
        rsh.vendor_id,
        pvds.segment1                  vendor_num,
        NVL(pvss.default_pay_site_id,pvss.vendor_site_id) default_pay_site_id,
        pvss2.vendor_site_code         pay_site_code,
        pvss.pay_on_receipt_summary_code,  -- default pay site's summary code
        pvss.auto_tax_calc_flag, --bug 3506659
        pvss.ap_tax_rounding_rule,  --bug 3506659
        rts.shipment_header_id,
/* Bug 3065403 - Taking rsl.packing slip if rsh.packing slip is null.
   Also changed the alias packing_slip to pack_slip to avoid ambiguous
  column error in the order by clause.*/
        NVL(rsh.packing_slip, nvl(rsl.packing_slip,rsh.receipt_num)) pack_slip,
        rsh.receipt_num,
        rts.shipment_line_id,
        rts.transaction_date,
        rts.amount,
        rts.quantity,
        nvl(plls.price_override, pls.unit_price) po_unit_price, /* Bug4199745 */
        rts.currency_code,
        rts.currency_conversion_type,
/* Note that we must decode currency type because the receiving programs put in
   a 1 for the currency rate if base currency is same as PO.  Purchasing and
   Payables expects that the rate be null if base currency=PO/Invoice currency. */
        decode (rts.currency_conversion_type,null,null,rts.currency_conversion_rate) currency_conversion_rate,
        rts.currency_conversion_date,
        NVL(NVL(plls.terms_id, phs.terms_id) , pvss2.terms_id) payment_terms_id,
        DECODE(plls.taxable_flag, 'Y', plls.tax_code_id, NULL) tax_code_id,
        pls.item_description,
        pls.matching_basis,
  rsh.SHIPMENT_NUM,------ added by sandeep on 11-sep-2008 for invoice num
  rsh.SHIPPED_DATE,------ added by sandeep on 11-sep-2008 for invoice num
  rsh.SHIP_TO_ORG_ID, ------ added by sandeep on 15-april-2009 for DOA
  phs.segment1 po_num,--added by Jaswant Hooda on 28 July2009 for Invoice Number
  rsh.attribute10 vendor_invoice_num--added by Jaswant Hooda on 27 Aug 2009 for Invoice Number 
FROM    po_vendor_sites         pvss,
        po_vendor_sites         pvss2,
        po_vendors              pvds,
        po_headers              phs,
        po_releases             prs,
        po_lines                pls,
        po_line_locations       plls,
        rcv_shipment_headers    rsh,
        rcv_shipment_lines      rsl,
        rcv_transactions        rts
WHERE   rts.shipment_header_id = rsh.shipment_header_id
AND     rts.po_header_id = phs.po_header_id
AND     rts.po_release_id = prs.po_release_id -- Bug 5443198
AND     rts.po_line_location_id = plls.line_location_id
AND     rts.po_line_id = pls.po_line_id
AND     rts.shipment_header_id = rsl.shipment_header_id
AND     rts.shipment_line_id = rsl.shipment_line_id
AND     phs.vendor_id =  pvds.vendor_id
AND     phs.vendor_site_id = pvss.vendor_site_id
AND     phs.pcard_id is null
AND     rsh.receipt_source_code = 'VENDOR'
AND     rts.source_document_code = 'PO'
AND     rts.invoice_status_code  IN ('PENDING','REJECTED') /*Bug:551612 */
AND     rts.transaction_type =  X_receipt_event
/* <PAY ON USE FPI START> */
AND     pvss.pay_on_code IN ('RECEIPT', 'RECEIPT_AND_USE')
AND     PRS.PAY_ON_CODE  IN ('RECEIPT', 'RECEIPT_AND_USE')  -- Bug 5443198
-- AND     decode(nvl(rts.po_release_id, -999), -999, phs.pay_on_code,
--                prs.pay_on_code) IN ('RECEIPT', 'RECEIPT_AND_USE')   Bug 5443198
AND     NVL(plls.consigned_flag,'N') <> 'Y'
/* <PAY ON USE FPI END> */
AND     pvss2.vendor_site_id = NVL(pvss.default_pay_site_id,pvss.vendor_site_id)
AND     nvl(rsh.asn_type, ' ') <> 'ASBN'
AND     rts.transaction_date <= sysdate - l_aging_period -- Bug 4488601.ERS program should consider timestamps.
ORDER BY 15,8,10,23,27,19,16;
--ORDER BY        rsh.shipment_header_id, --Bug 5198805
--                phs.vendor_id,
--                NVL(pvss.default_pay_site_id,pvss.vendor_site_id),
--                rts.currency_code,
--                payment_terms_id,
--                rts.transaction_date,
--                pack_slip;
/***** Cursor declaration ****/
CURSOR C_receipt_txns2 IS
SELECT rts.rowid                      rcv_txn_rowid,
 rts.transaction_id,
 rts.po_header_id,
        rts.po_release_id,
 rts.po_line_id,
 rts.po_line_location_id,
 rts.po_distribution_id,
 rsh.vendor_id,
 pvds.segment1                  vendor_num,
 NVL(pvss.default_pay_site_id,pvss.vendor_site_id) default_pay_site_id,
 pvss2.vendor_site_code         pay_site_code,
 pvss.pay_on_receipt_summary_code,  -- default pay site's summary code
        pvss.auto_tax_calc_flag, --bug 3506659
        pvss.ap_tax_rounding_rule,  --bug 3506659
 rts.shipment_header_id,
/* Bug 3065403 - Taking rsl.packing slip if rsh.packing slip is null.
   Also changed the alias packing_slip to pack_slip to avoid ambiguous
   column error in the order by clause*/
 NVL(rsh.packing_slip,nvl(rsl.packing_slip, rsh.receipt_num)) pack_slip,
 rsh.receipt_num,
 rts.shipment_line_id,
 rts.transaction_date,
 rts.amount,
 rts.quantity,
 nvl(plls.price_override, pls.unit_price) po_unit_price, /* Bug4199745 */
 rts.currency_code,
 rts.currency_conversion_type,
/* Note that we must decode currency type because the receiving programs put in
   a 1 for the currency rate if base currency is same as PO.  Purchasing and
   Payables expects that the rate be null if base currency=PO/Invoice currency. */
 decode (rts.currency_conversion_type,null,null,rts.currency_conversion_rate) currency_conversion_rate,
 rts.currency_conversion_date,
 NVL(NVL(plls.terms_id, phs.terms_id) , pvss2.terms_id) payment_terms_id,
 DECODE(plls.taxable_flag, 'Y', plls.tax_code_id, NULL) tax_code_id,
 pls.item_description,
 pls.matching_basis,
 rsh.SHIPMENT_NUM,------ added by sandeep on 11-sep-2008 for invoice num
 rsh.SHIPPED_DATE,------ added by sandeep on 11-sep-2008 for invoice num
 rsh.SHIP_TO_ORG_ID, ------ added by sandeep on 15-april-2009 for DOA
 phs.segment1 po_num,--added by Jaswant Hooda on 28 July2009 for Invoice Number
 rsh.attribute10 vendor_invoice_num--added by Jaswant Hooda on 27 Aug 2009 for Invoice Number
FROM po_vendor_sites  pvss,
 po_vendor_sites  pvss2,
 po_vendors  pvds,
 po_headers  phs,
        po_releases             prs,
 po_lines  pls,
 po_line_locations plls,
 rcv_shipment_headers  rsh,
        rcv_shipment_lines      rsl,
 rcv_transactions rts
WHERE rts.shipment_header_id = rsh.shipment_header_id
AND rts.po_header_id = phs.po_header_id
AND     rts.po_release_id = prs.po_release_id(+)
AND rts.po_line_location_id = plls.line_location_id
AND rts.po_line_id = pls.po_line_id
AND     rts.shipment_header_id = rsl.shipment_header_id
AND     rts.shipment_line_id = rsl.shipment_line_id
AND phs.vendor_id =  pvds.vendor_id
AND phs.vendor_site_id = pvss.vendor_site_id
AND     phs.pcard_id is null
AND rsh.receipt_source_code = 'VENDOR'
AND rts.source_document_code = 'PO'
AND     rts.invoice_status_code  IN ('PENDING','REJECTED') /*Bug:551612 */
AND rts.transaction_type =  X_receipt_event
/* <PAY ON USE FPI START> */
AND pvss.pay_on_code IN ('RECEIPT', 'RECEIPT_AND_USE')
AND     decode(nvl(rts.po_release_id, -999), -999, phs.pay_on_code,
               prs.pay_on_code) IN ('RECEIPT', 'RECEIPT_AND_USE')
AND     NVL(plls.consigned_flag, 'N') <> 'Y'
/* <PAY ON USE FPI END> */
AND pvss2.vendor_site_id = NVL(pvss.default_pay_site_id,pvss.vendor_site_id)
AND rsh.shipment_header_id = X_rcv_shipment_header_id
AND     nvl(rsh.asn_type, ' ') <> 'ASBN'
AND     rts.transaction_date <= sysdate - l_aging_period -- Bug 4488601.ERS program should consider timestamps.
ORDER BY        rsh.shipment_header_id,  -- Bug 5198805
             phs.vendor_id,
  NVL(pvss.default_pay_site_id,pvss.vendor_site_id),
  rts.currency_code,
  payment_terms_id,
  rts.transaction_date,
  pack_slip;
--Bug 5477365:Cursor to fetch the offset tax id.
/*CURSOR c_offset_tax(p_tax_id in NUMBER,p_org_id IN NUMBER) IS
select offset_tax_code_id
from ap_tax_codes_all
where tax_id = p_tax_id
and org_id = p_org_id;*/
X_rcv_txns  c_receipt_txns%ROWTYPE;
X_terms_date  DATE;
X_invoice_count  NUMBER;   /** num of invoices created in this run ***/
X_invoice_running_total NUMBER;  /** running total of invoice amount for
     invoices created */
X_first_rcv_txn_flag VARCHAR2(1);
X_curr_inv_process_flag VARCHAR2(1) := 'Y';
 /*** flag used to indicate whether the current invoice is processable,
 i.e. indicate whether any application error has occurred during the
 process of the invoice. If error occurs, this flag will be 'N'.
 ***/
X_completion_status     BOOLEAN := TRUE;
 /*** This flag will be set to FALSE if at least one error occurred
 during the run of this API. ***/
/*** The following set of curr_ variables are used to keep track of the
     current values used to determine if a new invoice has to be created ***/
X_curr_invoice_amount  NUMBER := 0;
X_curr_tax_amount  NUMBER := 0;
X_curr_invoice_id  NUMBER := NULL;
X_curr_invoice_num  ap_invoices.invoice_num%TYPE;
X_curr_vendor_id  NUMBER := NULL;
X_curr_pay_site_id  NUMBER := NULL;
X_curr_auto_tax_calc_flag       po_vendor_sites.auto_tax_calc_flag%type := 'N'; -- bug 3506659
X_curr_currency_code  rcv_transactions.currency_code%TYPE := NULL;
X_curr_payment_terms_id         NUMBER := NULL;
X_curr_transaction_date  DATE := NULL;
X_curr_le_transaction_date DATE := NULL; --LE time zone date (Bug: 5262997)
X_curr_packing_slip  rcv_shipment_headers.receipt_num%TYPE := NULL;
X_curr_shipment_header_id NUMBER := NULL;
X_curr_conversion_rate_type rcv_transactions.currency_conversion_type%TYPE;
X_curr_conversion_rate_date DATE;
X_curr_conversion_rate  NUMBER;
/** Bug# 1176326 **/
X_curr_conversion_rate_date1 DATE;
X_curr_conversion_rate1  NUMBER;
X_def_base_currency_code        ap_system_parameters.base_currency_code%TYPE;
X_curr_accounting_date  DATE;
X_curr_period_name  gl_periods.period_name%TYPE;
/**   Bug 586895      **/
X_curr_method_code     po_vendors.payment_method_lookup_code%TYPE;
/*    Bug 612979      **/
X_curr_pay_curr_code   po_vendor_sites.payment_currency_code%TYPE;
X_ap_pay_curr            po_vendor_sites.payment_currency_code%TYPE;
 /*** vendor, vendor-pay-site related varibles ***/
X_pay_group_lookup_code         po_vendors.pay_group_lookup_code%TYPE;
X_accts_pay_combination_id po_vendors.accts_pay_code_combination_id%TYPE;
X_payment_method_lookup_code po_vendors.payment_method_lookup_code%TYPE;
X_exclusive_payment_flag po_vendors.exclusive_payment_flag%TYPE;
X_payment_priority  po_vendors.payment_priority%TYPE;
X_terms_date_basis  po_vendors.terms_date_basis%TYPE;
X_vendor_income_tax_region po_vendor_sites.state%TYPE;
X_type_1099   po_vendors.type_1099%TYPE;
X_awt_flag   po_Vendor_sites.allow_awt_flag%TYPE;
X_awt_group_id   po_vendor_sites.awt_group_id%TYPE;
X_exclude_freight_from_disc po_vendor_sites.exclude_freight_from_discount%TYPE;
/*  BUG 612979 */
X_payment_currency_code         po_vendor_sites.payment_currency_code%TYPE := NULL;
X_pay_cross_rate                NUMBER;
X_batch_id   NUMBER;
X_discountable_amount  NUMBER;
X_inv_event                     VARCHAR2(26);
X_invoice_description ap_invoices.description%TYPE;
l_user_id   NUMBER;
v_req_id   NUMBER;
/** this is the group id we insert into the
    AP interface table to identify out batch **/
X_group_id    VARCHAR2(80);
x_dist_count   NUMBER;
/* Fix for bug 2943056.
   Commenting the fix done in 2379414 at all places of the code.
*/
x_org_id                        NUMBER;        --Bug# 2492041
/* <PAY ON USE FPI START> */
l_error_msg   VARCHAR2(2000);
l_return_status   VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
/* <PAY ON USE FPI END> */
x_cnt                           NUMBER;  /* bug 3506659 */
x_tax_amount                    NUMBER;  /* bug 3506659 */
x_curr_tax_rounding_rule        po_vendor_sites.ap_tax_rounding_rule%TYPE;  /* bug 3506659 */
/*added by sandeep on 11-sep-2008 start*/
V_org_id      Number :=fnd_profile.value ('ORG_ID');
v_error       varchar2(1000);
v_document_category    varchar2(1000);
 x_tmp_sequence_id    number;
 l_sequence_num_query  VARCHAR2(1000);--Added by Jaswant Hooda on 28 July 2009
/* added by sandeep on 11-sep-2008 end */
--l_offset_tax_id                 NUMBER; --5477365
/*********** added by sandeep angra on 13-apr-2009 for DOA **********/
 l_scm_head            VARCHAR2 (240);
 l_fin_head            VARCHAR2 (240);
 l_requester           VARCHAR2 (240);
 l_supervisor          VARCHAR2 (240);
 l_attr_cat      VARCHAR2 (240);
 lv_error              VARCHAR2 (2000);
 l_exit_procedure        EXCEPTION;
/********* End**************************/
BEGIN
 /**** BEGIN create_receipt_invoices ***/
 IF (g_asn_debug = 'Y') THEN
    asn_debug.put_line('Begin Create Receipt Invoices ... ');
 END IF;
 X_invoice_count := 0;
 X_invoice_running_total := 0;
 X_first_rcv_txn_flag := 'Y';
        /* Bug 3506659 Start */
        g_this_invoice_dist_cnt := 0;
        g_this_invoice_has_tax := FALSE;
        g_inv_line_id         := 0;
        p_tax_info_tbl        :=  AP_POR_TAX_INFO_OBJ_TBL_TYPE();
        x_recov_tax_tbl       :=  AP_POR_TAX_NUMBER_TBL_TYPE();
        x_nonrecov_tax_tbl    :=  AP_POR_TAX_NUMBER_TBL_TYPE();
        /* Bug 3506659  End */
 X_progress := '010';
 /* added by sandeep on 11-sep-2008 to get document category for circle*/
BEGIN
     v_document_category := bilc_insert_doccategory_pkg.get_doc_category(v_org_id, v_error);
 fnd_file.put_line (fnd_file.LOG, 'v_document_category    - ' || v_document_category);---- added by sandy
 fnd_file.put_line (fnd_file.LOG, 'v_error    - ' || v_error);---- added by sandy
END;
/* added by sandeep on 11-sep-2008 to get document category for circle*/
 /** bug 885111, allow user to supply aging period from the report **/
 IF (x_aging_period IS NULL) THEN
     /* Get Aging period */
            FND_PROFILE.GET('AGING_PERIOD', X_profile);
            l_aging_period := floor(to_number(X_profile));
            IF l_aging_period < 0 THEN
            l_aging_period := 0;
            END IF;
 ELSE
     l_aging_period := x_aging_period;
 END IF;
 X_progress := '020';
-- fnd_file.put_line (fnd_file.LOG, ' X_progress '|| X_progress);
 IF (g_asn_debug = 'Y') THEN
    asn_debug.put_line('Begin processing rcv txns ... [' || to_char(x_aging_period) || ']');
 END IF;
 IF (X_rcv_shipment_header_id IS NULL) THEN
     IF (g_asn_debug = 'Y') THEN
        asn_debug.put_line('opening c_receipt_txns');
     END IF;
-- fnd_file.put_line (fnd_file.LOG, ' before opening c_receipt_txns');
     OPEN c_receipt_txns;
        ELSE
     IF (g_asn_debug = 'Y') THEN
        asn_debug.put_line('opening c_receipt_txns2');
     END IF;
     OPEN c_receipt_txns2;
        END IF;
 LOOP
 X_progress := '030';
-- fnd_file.put_line (fnd_file.LOG, ' X_progress '|| X_progress);
 IF (X_rcv_shipment_header_id IS NULL) THEN
     IF (g_asn_debug = 'Y') THEN
        asn_debug.put_line('fetching c_receipt_txns');
     END IF;
     FETCH c_receipt_txns INTO X_rcv_txns;
-- fnd_file.put_line (fnd_file.LOG, ' X_rcv_txns.receipt_num '|| X_rcv_txns.receipt_num);
-- fnd_file.put_line (fnd_file.LOG, ' X_rcv_txns.ship_to_org_id '|| X_rcv_txns.ship_to_org_id);
     IF (c_receipt_txns%NOTFOUND) THEN
         IF (g_asn_debug = 'Y') THEN
            asn_debug.put_line('closing c_receipt_txns');
         END IF;
         CLOSE C_receipt_txns;
  EXIT;
     END IF;
        ELSE
     IF (g_asn_debug = 'Y') THEN
        asn_debug.put_line('fetching c_receipt_txns2');
     END IF;
     FETCH c_receipt_txns2 INTO X_rcv_txns;
     IF (c_receipt_txns2%NOTFOUND) THEN
         IF (g_asn_debug = 'Y') THEN
            asn_debug.put_line('closing c_receipt_txns2');
         END IF;
  CLOSE C_receipt_txns2;
  EXIT;
     END IF;
        END IF;
          IF (g_asn_debug = 'Y') THEN
             asn_debug.put_line('IN processing rcv txns ... ');
          END IF;
  X_progress := '040';
-- fnd_file.put_line (fnd_file.LOG, ' X_progress '|| X_progress);
  bilc_po_invoices_sv1.get_vendor_related_info(X_rcv_txns.vendor_id,
                               X_rcv_txns.default_pay_site_id,
      X_pay_group_lookup_code,
                                X_accts_pay_combination_id,
                                X_payment_method_lookup_code,
                  X_exclusive_payment_flag,
           X_payment_priority,
           X_terms_date_basis,
           X_vendor_income_tax_region,
           X_type_1099,
    X_awt_flag,
    X_awt_group_id,
    X_exclude_freight_from_disc,
                                X_payment_currency_code           -- BUG 612979 add payment_currency_code of default pay site
    );
  X_progress := '045';
-- fnd_file.put_line (fnd_file.LOG, ' X_progress '|| X_progress);
               /*Bug#2492041 Get the Operating Unit for the PO */
                select org_id
                into   x_org_id
                from   po_headers_all
                where  po_header_id = X_rcv_txns.po_header_id;
  IF (x_payment_currency_code is NULL) THEN
      x_payment_currency_code := X_rcv_txns.currency_code;
  END IF;
  /*Check to see if it is the first invoice to be created: */
  IF (X_first_rcv_txn_flag = 'Y') THEN
   /**** Logic for the first invoice created ***/
   X_progress := '050';
-- fnd_file.put_line (fnd_file.LOG, ' X_progress '|| X_progress);
   X_first_rcv_txn_flag := 'N';
   /*** if any application error occurs the creation
   of an invoice, the program will rollback to this
   savepoint. ***/
   SAVEPOINT header_record_savepoint;
   X_curr_inv_process_flag := 'Y';
   /*The following variables will be used to determine if
   a new invoice should be created: */
                        /**   Bug 586895      **/
                        X_curr_method_code :=
                                        X_payment_method_lookup_code;
                        /**   Bug 612979      **/
                 X_curr_pay_curr_code := X_payment_currency_code;
   X_curr_invoice_amount      := 0;
   X_curr_tax_amount      := 0;
   X_curr_vendor_id       := X_rcv_txns.vendor_id;
   X_curr_pay_site_id       :=
     X_rcv_txns.default_pay_site_id;
   X_curr_currency_code     := X_rcv_txns.currency_code;
   X_curr_conversion_rate_type :=
     X_rcv_txns.currency_conversion_type;
                        /*  Bug# 1176326
   ** We now take the rate corresponding to the date
   ** on which the invoice was created rather than taking
   ** the rate on the receipt date
   */
                         select base_currency_code
                         into X_def_base_currency_code
                         from ap_system_parameters;
                        /*Bug: 5739670
                         X_curr_conversion_rate_date  :=
                         X_rcv_txns.transaction_date ;
                        */
                        IF X_rcv_txns.currency_conversion_date IS NULL THEN
                          X_curr_conversion_rate_date := X_rcv_txns.transaction_date;
                        ELSE
                          X_curr_conversion_rate_date  := X_rcv_txns.currency_conversion_date;
                        END IF;
   X_curr_conversion_rate :=
    ap_utilities_pkg.get_exchange_rate(
     X_curr_currency_code,
                                        X_def_base_currency_code,
     X_curr_conversion_rate_type,
     X_curr_conversion_rate_date,
     'create_receipt_invoices');
   if X_curr_conversion_rate is null then
       X_curr_conversion_rate       :=
     X_rcv_txns.currency_conversion_rate;
       X_curr_conversion_rate_date  :=
     X_rcv_txns.currency_conversion_date;
   end if;
      /* 3065403 - Changed packing slip to pack slip as the alias name is
         changed in the cursor. */
   X_curr_payment_terms_id      :=
      X_rcv_txns.payment_terms_id;
   X_curr_packing_slip      := X_rcv_txns.pack_slip;
   X_curr_shipment_header_id    :=
     X_rcv_txns.shipment_header_id;
   X_curr_transaction_date      :=
     X_rcv_txns.transaction_date;
  /*
           AP requires the invoice_date, goods_received_date and
           invoice_received_date converted in to the LE time zone.
           Bug: 5262997
     */
      X_curr_le_transaction_date   :=
          INV_LE_TIMEZONE_PUB.GET_LE_DAY_TIME_FOR_OU(x_curr_transaction_date,x_org_id);
   X_progress := '060';
-- fnd_file.put_line (fnd_file.LOG, ' X_progress '|| X_progress);
   /* Bug510160. gtummala. 8/4/97
               * Need to set the approval status to NULL not
    * UNAPPROVED.
               */
   /* added by nwang  */
             IF (X_curr_inv_process_flag = 'Y') THEN
             BEGIN
                fnd_file.put_line (fnd_file.LOG, ' XX_curr_inv_process_flag '|| X_curr_inv_process_flag);
                /*Start Commented By Jaswant Hooda
                SELECT po_invoice_num_segment_s.NEXTVAL
                INTO   x_tmp_sequence_id
                FROM   SYS.DUAL;
                End Commented by Jaswant Hooda*/
                --Following code added by Jaswant Singh Hooda to get the Circle specific Sequence Number
                l_sequence_num_query := 'select po_invoice_num_segment_'||to_char(v_org_id)||'_s.nextval from dual';

                execute immediate l_sequence_num_query into x_tmp_sequence_id;

                 X_curr_invoice_num :=X_rcv_txns.po_num||'/'||X_rcv_txns.receipt_num||'/'|| x_tmp_sequence_id||'-'||X_rcv_txns.vendor_invoice_num;------ added by Jaswant Hooda on 28-July-2009 for invoice num

                 fnd_file.put_line (fnd_file.LOG, ' X_curr_invoice_num '|| X_curr_invoice_num);


             EXCEPTION
               WHEN others THEN
                 asn_debug.put_line('create_invoice_num raised error');
                 X_curr_inv_process_flag := 'N';
                 X_first_rcv_txn_flag := 'Y';
             END;
             END IF;

        select ap_invoices_interface_s.nextval
        into   x_curr_invoice_id
        from   sys.dual;
-- fnd_file.put_line (fnd_file.LOG, ' x_curr_invoice_id '|| x_curr_invoice_id);
        x_group_id :=  substr('ERS-'||TO_CHAR(X_rcv_txns.transaction_id),1,80);
/* bug 612979 */       IF (gl_currency_api.is_fixed_rate(X_curr_pay_curr_code,
     X_curr_currency_code, X_curr_transaction_date) = 'Y'
                           and X_curr_pay_curr_code <> X_curr_currency_code) THEN
                            X_ap_pay_curr := X_curr_pay_curr_code;
                       ELSE
                            X_ap_pay_curr := X_curr_currency_code;
                       END IF;
  End IF; -- X_first_rcv_txn_flag
 -- parameters to this API are NOT all the columns in AP_INVOICES, the
 -- other columns are not used by create_receipt_invoices or create_notice_invoices.
 /**** Check to see if there is a change in  vendor,
        pay_site,
      currency  or
      txn_date
  If so, we would first update the current invoice -- invoice amount, etc.
   create payment schedule for the invoice and then
        get ready to create a new invoice.    ***/
        /* Bug 586895 */
        /* Bug 2536170 - We consider the transaction date also for
          creating new invoice as it determines the conversion rate
          between the purchasing currency and invoice currency.But when
          the transaction date remaining the same except for the timestamp
          we were creating a new invoice. This should not be the case.
          So added a trunc on the date comparisons so that all the transactions
          that have the same transaction date except for the timestamp will
          have a single invoice provided these transactions can be grouped by
          the invoice summary level(pay_on_summary_code). Also removed the
          AND condition added in fix 1703833 as there will conversion issues
          if we don't consider transaction dates for pay sites also.
       */
 /* Bug 1703833. If the receipt_date is different, then we create
  * multiple invoices even if the pay_on_receipt_summary_code is
  * PAY_SITE. Changed the code below to include the condition
  * that if transaction_date is not the same and the summary code
  * is not PAY_SITE, then go inside the if clause.
 */
       /* Bug 2531542 - The logic followed for creating invoices is to
          insert records into ap_lines_interface first (distributions)
          and then insert the records in ap_invoices_interface(Headers)
          so the amount will be the total distribution amount.
          For bug fix 1762305 , if the net received quantity is 0 then
          distribuitions lines were not inserted. But the records were
          inserted for the headers even for the received qty of 0.
          Because of this Payables import program was erroring out with
          'Atleast one invoice line is needed'  error message. So
          checking for the distribiution count before inserting the headers
          and inserting only if the distribution count is >0. */
   /* 3065403 - Changed packing slip to pack slip as the alias name is
         changed in the cursor. */
 IF   (X_curr_vendor_id <> X_rcv_txns.vendor_id)   OR
           (X_curr_pay_site_id <> X_rcv_txns.default_pay_site_id) OR
      (X_curr_currency_code <> X_rcv_txns.currency_code)  OR
      (X_curr_payment_terms_id <> X_rcv_txns.payment_terms_id) OR
           (trunc(X_curr_transaction_date) <> trunc(X_rcv_txns.transaction_date)) OR
             (X_curr_packing_slip <> X_rcv_txns.pack_slip AND
                X_rcv_txns.pay_on_receipt_summary_code = 'PACKING_SLIP') OR
             (X_curr_shipment_header_id <> X_rcv_txns.shipment_header_id AND
                X_rcv_txns.pay_on_receipt_summary_code = 'RECEIPT')  OR
             (X_curr_method_code <> X_payment_method_lookup_code)
                                                                       THEN
            /*  2531542 */
             select count(*) into x_dist_count
             from ap_invoice_lines_interface
             where invoice_id = x_curr_invoice_id;
-- fnd_file.put_line (fnd_file.LOG, ' x_dist_count '|| x_dist_count);
            /* Bug# 1176326
            ** We now take the rate corresponding to the date
            ** on which the invoice was created rather than taking
            ** the rate on the receipt date
            */
            select base_currency_code
            into X_def_base_currency_code
            from ap_system_parameters;
            /*Bug: 5739670
             X_curr_conversion_rate_date  :=
             X_rcv_txns.transaction_date ;
            */
            IF X_rcv_txns.currency_conversion_date IS NULL THEN
              X_curr_conversion_rate_date := X_rcv_txns.transaction_date;
            ELSE
              X_curr_conversion_rate_date  := X_rcv_txns.currency_conversion_date;
            END IF;
            X_curr_conversion_rate1 :=
                ap_utilities_pkg.get_exchange_rate(
                    X_rcv_txns.currency_code,
                    X_def_base_currency_code,
                    X_rcv_txns.currency_conversion_type,
                    X_curr_conversion_rate_date1,
                    'create_receipt_invoices');
            if X_curr_conversion_rate1 is null then
                X_curr_conversion_rate1       :=
                    X_rcv_txns.currency_conversion_rate;
                X_curr_conversion_rate_date1  :=
                    X_rcv_txns.currency_conversion_date;
            end if;
         /*** a new invoice needs to be created ... and we need to
  update the current one before the new one can be created.  ***/
  X_progress := '090';
-- fnd_file.put_line (fnd_file.LOG, ' X_progress '|| X_progress);
   /** update invoice amounts and also running totals.
   Also create payment schedules ***/
         fnd_message.set_name('PO', 'PO_INV_CR_ERS_INVOICE_DESC');
  X_progress := '100';
-- fnd_file.put_line (fnd_file.LOG, ' X_progress '|| X_progress);
  fnd_message.set_token('RUN_DATE', X_curr_le_transaction_date); --Bug: 5262997
  X_progress := '110';
--   fnd_file.put_line (fnd_file.LOG, ' X_progress '|| X_progress);
  X_invoice_description := fnd_message.get;
      IF (UPPER(x_curr_conversion_rate_type) <> 'USER') THEN
   x_curr_conversion_rate := NULL;
                    END IF;
 IF (g_asn_debug = 'Y') THEN
    asn_debug.put_line('creating invoice headers');
 END IF;
---removed from here
   /* bug 1832024 : we need to insert terms id into the interface table
               so that ap get the value */
              if (x_curr_inv_process_flag = 'Y') THEN
                 if (x_dist_count > 0 ) then   -- 2531542
                    asn_debug.put_line('x_curr_pay_site_id='||x_curr_pay_site_id||' and X_rcv_txns.default_pay_site_id='||X_rcv_txns.default_pay_site_id);

--	          fnd_file.put_line (fnd_file.LOG, 'before First insert Call');
--              fnd_file.put_line (fnd_file.LOG, 'l_scm_head '||l_scm_head);
--	          fnd_file.put_line (fnd_file.LOG, 'l_fin_head '||l_fin_head);
--		      fnd_file.put_line (fnd_file.LOG, 'l_requester '||l_requester);
--			  fnd_file.put_line (fnd_file.LOG, 'l_supervisor '||l_supervisor);

--      fnd_file.put_line (fnd_file.LOG, 'x_curr_invoice_num '||x_curr_invoice_num);
--      dbms_output.put_line ('x_curr_invoice_num '||x_curr_invoice_num);

      insert into AP_INVOICES_INTERFACE
      (INVOICE_ID,
       INVOICE_NUM,
       VENDOR_ID,
       VENDOR_SITE_ID,
       INVOICE_AMOUNT,
       INVOICE_CURRENCY_CODE,
       INVOICE_DATE,
       SOURCE,
       DESCRIPTION,
       GOODS_RECEIVED_DATE,
       INVOICE_RECEIVED_DATE,
       CREATION_DATE,
       EXCHANGE_RATE,
       EXCHANGE_RATE_TYPE,
       EXCHANGE_DATE,
                     TERMS_ID,
       GROUP_ID,
    DOC_CATEGORY_CODE,------- added by sandeep on 11-sep-2008
                     ORG_ID,
      attribute_category,
          attribute6 ,
                   attribute7 ,
                   attribute8 ,
                   attribute9             -- Bug#2492041
             --GL_DATE            -- Bug#: 3418406   /* Bug 4718994. Commenting gl_date so that AP determines the same based on GL Date basis */
       ) VALUES
      (x_curr_invoice_id,
       x_curr_invoice_num,
       x_curr_vendor_id,
       x_curr_pay_site_id,
       x_curr_invoice_amount, /* +x_curr_tax_amount, */
       x_curr_currency_code,
       X_curr_le_transaction_date, --Bug: 5262997: INVOICE_DATE in LE Time zone
       'ERS',  -- debug, needs to change,
       x_invoice_description,
       X_curr_le_transaction_date, --Bug: 5262997: GOODS_RECEIVIED_DATE in LE Time zone
       X_curr_le_transaction_date, --Bug: 5262997: INVOICE_RECEIVIED_DATE in LE Time zone
       sysdate,
       x_curr_conversion_rate,
       x_curr_conversion_rate_type,
       x_curr_conversion_rate_date,
                     X_curr_payment_terms_id,
       x_group_id,
    v_document_category,------- added by sandeep on 11-sep-2008
                     x_org_id,
    l_attr_cat,
   'person_id: ' ||l_scm_head,
   l_requester,
            l_supervisor,
   'person_id: ' ||l_fin_head
    --inv_le_timezone_pub.get_le_day_for_ou(x_curr_transaction_date, x_org_id)
       );
                end if ; -- x_dist_count >0
             end if;
              /* Bug 3506659 Start
                * Call the Tax engine by passing the input Plsql table that has the tax
                * information populated in it, get the recoverable and non recoverable
                * tax amounts via the output plsql tables x_recov_tax_tbl and
                * x_nonrecov_tax_tbl respectively, sum them and add the resultant value
                * to the invoice amount.
                */
               IF (g_this_invoice_has_tax) THEN
                  IF (g_asn_debug = 'Y') THEN
                      asn_debug.put_line('Calling Tax API for invoice ' || x_curr_invoice_num);
                      asn_debug.put_line('Invoice Id = ' || to_char(x_curr_invoice_id));
                  END IF;
                  /* Bug 4112614: Flushing recoverable and non recoverable tax pl/sql tables */
                  x_recov_tax_tbl.delete;
                  x_nonrecov_tax_tbl.delete;
                  AP_POR_TAX_PKG.calculate_tax(p_tax_info_tbl,
                                               x_recov_tax_tbl,
                                               x_nonrecov_tax_tbl);
                  IF (g_asn_debug = 'Y') THEN
                     asn_debug.put_line('After Tax API call - '||'Return count is ' || to_char(x_recov_tax_tbl.count));
                  END IF;
                  x_cnt := 1;
                  x_tax_amount := 0;
                  loop
                      exit when (x_recov_tax_tbl.count = 0);
                      x_tax_amount := x_tax_amount + (nvl(x_recov_tax_tbl(x_cnt),0) + nvl(x_nonrecov_tax_tbl(x_cnt),0));
                      IF (g_asn_debug = 'Y') THEN
                      asn_debug.put_line('Tax Amount for this line is ' || to_char(x_tax_amount));
                      END IF;
                      x_cnt := x_cnt + 1;
                      exit when (x_cnt > x_recov_tax_tbl.count);
                  end loop;
                  IF (g_asn_debug = 'Y') THEN
                      asn_debug.put_line('Total Tax Amount is ' || to_char(x_tax_amount));
                      asn_debug.put_line('Updating invoice header amount');
                  END IF;
    --Bug 5477365:Add the tax amount to the header amount only if the
           --tax code does not have an offset tax attached to it.
   /* open c_offset_tax(X_rcv_txns.tax_code_id,x_org_id);
    fetch c_offset_tax into l_offset_tax_id;
    close c_offset_tax;
                  if (x_tax_amount > 0 and l_offset_tax_id is NULL) then
                      update ap_invoices_interface
                      set invoice_amount = invoice_amount + x_tax_amount
                      where invoice_id = x_curr_invoice_id;
                  end if;*/
    /* Added for bug 6070030 - Revered the fix by 5477365  */
                      update ap_invoices_interface
                      set invoice_amount = invoice_amount + x_tax_amount
                      where invoice_id = x_curr_invoice_id;
               END IF;  /* End of g_this_invoice_has_tax */
               /* Reset the global variables after the invoice creation */
                g_this_invoice_dist_cnt := 0;
                g_this_invoice_has_tax := FALSE;
                g_inv_line_id := 0;
                p_tax_info_tbl.delete;  --bug 4112614 to flush the input tax records pl/sql table
             /* Bug 3506659 End */
  BILC_PO_INVOICES_SV2.wrap_up_current_invoice(
    X_rcv_txns.vendor_id,
     X_rcv_txns.default_pay_site_id,
           X_rcv_txns.currency_code,
           X_rcv_txns.currency_conversion_type,
/* Bug#3277331
    X_rcv_txns.currency_conversion_date,
    X_rcv_txns.currency_conversion_rate,
*/
    X_curr_conversion_rate_date1,  /* Bug#3277331 */
    X_curr_conversion_rate1, /* Bug#3277331 */
    X_rcv_txns.payment_terms_id,
    X_rcv_txns.transaction_date,
    X_rcv_txns.pack_slip,
    X_rcv_txns.shipment_header_id,
    X_terms_date,
    X_payment_priority,
/**   Bug 586895      **/ X_payment_method_lookup_code,
                                X_curr_method_code,
/*    Bug 612979 */  X_payment_currency_code,
                                X_curr_pay_curr_code,
    X_batch_id,
    X_curr_invoice_amount,
    X_curr_tax_amount,
    X_curr_invoice_id,
    X_curr_vendor_id,
    X_curr_pay_site_id,
    X_curr_currency_code,
    X_curr_conversion_rate_type,
    X_curr_conversion_rate_date,
    X_curr_conversion_rate,
    X_curr_payment_terms_id,
    X_curr_transaction_date,
    X_curr_packing_slip,
    X_curr_shipment_header_id,
    X_curr_inv_process_flag,
    X_invoice_count,
    X_invoice_running_total,
    X_org_id, --Bug 5533454
    X_curr_le_transaction_date
    );
  /*** Ready to create the next invoice ***/
  X_progress := '110';
  IF (X_curr_inv_process_flag <> 'Y') THEN
   /** at least one error occurred **/
   X_completion_status := FALSE;
   ROLLBACK TO header_record_savepoint;
  END IF;
  IF MOD(X_invoice_count , X_commit_interval) = 0
                                    AND x_invoice_count  > 0   THEN
   X_progress := '100';
   IF (g_asn_debug = 'Y') THEN
      asn_debug.put_line('Committing changes ... ');
   END IF;

   COMMIT;

  END IF;
  SAVEPOINT header_record_savepoint;
  X_curr_inv_process_flag := 'Y';

		 IF (X_curr_inv_process_flag = 'Y') THEN
         BEGIN
            /*Following lines commented by Jaswant Hooda
            SELECT po_invoice_num_segment_s.NEXTVAL
            INTO   x_tmp_sequence_id
            FROM   SYS.DUAL;*/

                l_sequence_num_query := 'select po_invoice_num_segment_'||to_char(v_org_id)||'_s.nextval from dual';

                execute immediate l_sequence_num_query into x_tmp_sequence_id;

                 X_curr_invoice_num :=X_rcv_txns.PO_NUM||'/'||X_rcv_txns.receipt_num||'/'|| x_tmp_sequence_id||'-'||X_rcv_txns.vendor_invoice_num;------ added by Jaswant Hooda on 28-July-2009 for invoice num


            EXCEPTION
              WHEN others THEN
                asn_debug.put_line('create_invoice_num raised error');
                X_curr_inv_process_flag := 'N';
            END;
            END IF;
  X_progress := '130';
               /* Bug510160. gtummala. 8/4/97
                * Need to set the approval status to NULL not UNAPPROVED.
                */
               /* bug 612979 */
               IF (gl_currency_api.is_fixed_rate(X_curr_pay_curr_code,
   X_curr_currency_code, X_curr_transaction_date) = 'Y'
                   and X_curr_pay_curr_code <> X_curr_currency_code) THEN
                     X_ap_pay_curr := X_curr_pay_curr_code;
               ELSE
                     X_ap_pay_curr := X_curr_currency_code;
               END IF;
   -- parameters to this API are NOT all the columns in
   -- AP_INVOICES, the other columns are not used by
   -- create_receipt_invoices or create_notice_invoices.
 END IF; /** change in one of the curr_ variables **/
 /**** Create invoice distribution(s) , tax distribution(s) and
 update rcv_txns, po_line_locations and po_distributions accordingly *****/
 X_progress := '140'; -- receipt_invoices
 IF (X_curr_inv_process_flag = 'Y') THEN
  /** only create invoice and/or tax distr if the invoice is still
  processable.  **/
                /* bug 660397 if there is a corresponding 'DELIVER' transaction for
                   a 'RECEIVE' transaction, we want to pass in 'DELIVER' into
                   create_invoice_distribution, so that only one invoice distribution is created.
                   Otherwise, if there would be pro-ration done on every distribution,
      creating a total of n square invoice distributions */
                SELECT MIN(NVL(transaction_type, X_receipt_event))
                INTO   X_inv_event
                FROM   rcv_transactions
                WHERE  shipment_line_id = X_rcv_txns.shipment_line_id
                AND    po_distribution_id = NVL(X_rcv_txns.po_distribution_id,-1)
                AND    parent_transaction_id = X_rcv_txns.transaction_id
                AND    transaction_type = 'DELIVER';
                /* Get the adjusted quantity for invoice creation */
                IF X_rcv_txns.matching_basis = 'AMOUNT' THEN
                   X_received_quantity := 0;
                   BILC_PO_INVOICES_SV2.get_received_amount(X_rcv_txns.transaction_id,
                                                       X_rcv_txns.shipment_line_id,
                                                       X_received_amount);
                ELSE
                   X_received_amount := 0;
                   BILC_PO_INVOICES_SV2.get_received_quantity(X_rcv_txns.transaction_id,
                                                         X_rcv_txns.shipment_line_id,
                                                         X_received_quantity);
                END IF;
                X_curr_auto_tax_calc_flag   := X_rcv_txns.auto_tax_calc_flag;    --bug 3506659
                X_curr_tax_rounding_rule    := X_rcv_txns.ap_tax_rounding_rule;  --bug 3506659
  /* Bug 1762305. Need not create an invoice line if
   * net quantity received is 0.
  */
                /* Removed the fix of 2379414 as it is already commented */
                if (x_received_quantity <> 0 or x_received_amount <> 0) then
   BILC_PO_INVOICES_SV2.create_invoice_distributions(
       X_curr_invoice_id,
       X_curr_currency_code,
       x_curr_currency_code,
       X_batch_id,
       X_curr_vendor_id,
       X_curr_pay_site_id,
       X_curr_auto_tax_calc_flag,
       X_curr_tax_rounding_rule,
       X_rcv_txns.po_header_id,
       X_rcv_txns.po_line_id,
       X_rcv_txns.po_line_location_id,
       X_rcv_txns.po_release_id, -- bug 901039
       X_inv_event, -- bug 660397
       X_rcv_txns.po_distribution_id,
       X_rcv_txns.item_description,
       X_type_1099,
       X_rcv_txns.tax_code_id,
       NULL,
       'Y',  -- create_tax_flag
       X_received_quantity,
       X_rcv_txns.po_unit_price,
       X_curr_conversion_rate_type,
       X_curr_conversion_rate_date,
       X_curr_conversion_rate,
       X_accts_pay_combination_id,
       X_curr_transaction_date,
       X_curr_transaction_date,
              X_vendor_income_tax_region,
       'ERS',   -- reference_1
                 TO_CHAR(X_rcv_txns.transaction_id),
          -- reference_2
       X_awt_flag,
       X_awt_group_id,
       X_curr_accounting_date,
       X_curr_period_name,
       'ERS',   -- transaction_type
       X_rcv_txns.transaction_id,
        -- unique_id
               X_curr_invoice_amount,
              X_curr_tax_amount,
       X_curr_inv_process_flag,
       X_rcv_txns.receipt_num,
       X_rcv_txns.transaction_id,
/* Bug3493515 (2) - START */
       NULL,
       X_received_amount,
       X_rcv_txns.matching_basis);
/* Bug3493515 (2) - END */
  end if; -- end of if x_received_quantity <> 0
 END IF;    -- X_curr_inv_process_flag
 X_progress := '150';
 /*** make sure to indicate this receipt transaction has been invoiced ***/
 -- need to provide an API for AP instead
        -- update invoice_status_code of 'RECEIVE', 'CORRECT' and
        --   'RETURN TO VENDOR' transactions
           UPDATE  rcv_transactions
           SET invoice_status_code = DECODE(X_curr_inv_process_flag,'Y','INVOICED','REJECTED'), -- bug 3640106
   last_updated_by     = FND_GLOBAL.user_id,
   last_update_date    = sysdate,
   last_update_login   = FND_GLOBAL.login_id
           WHERE   transaction_id IN (
                 SELECT
                   transaction_id
                 FROM
                   rcv_transactions
                 WHERE
                   invoice_status_code <> 'INVOICED' AND
                   transaction_type IN ('RECEIVE','CORRECT','RETURN TO VENDOR')
                 START WITH transaction_id = X_rcv_txns.transaction_id
                 CONNECT BY parent_transaction_id = PRIOR transaction_id
                );
 END LOOP;

 /*** Logic for the last invoice ***/
 X_progress := '160';
 IF (X_first_rcv_txn_flag = 'N') AND
    (X_curr_inv_process_flag = 'Y')
 THEN
         fnd_message.set_name('PO', 'PO_INV_CR_ERS_INVOICE_DESC');
  X_progress := '100';
  fnd_message.set_token('RUN_DATE', X_curr_le_transaction_date);--Bug: 5262997
  X_progress := '110';
  X_invoice_description := fnd_message.get;
      IF (UPPER(x_curr_conversion_rate_type) <> 'USER') THEN
   x_curr_conversion_rate := NULL;
                    END IF;

       /* Removed the fix of 2379414 from here as it is already commented */
 IF (g_asn_debug = 'Y') THEN
    asn_debug.put_line('creating invoice distributions');
 END IF;

--      fnd_file.put_line (fnd_file.LOG, 'before second insert Call');
--      fnd_file.put_line (fnd_file.LOG, 'l_scm_head '||l_scm_head);
--	  fnd_file.put_line (fnd_file.LOG, 'l_fin_head '||l_fin_head);
--	  fnd_file.put_line (fnd_file.LOG, 'l_requester '||l_requester);
--	  fnd_file.put_line (fnd_file.LOG, 'l_supervisor '||l_supervisor);
--      fnd_file.put_line (fnd_file.LOG, 'x_curr_invoice_num '||x_curr_invoice_num);

      insert into AP_INVOICES_INTERFACE
      (INVOICE_ID,
       INVOICE_NUM,
       VENDOR_ID,
       VENDOR_SITE_ID,
       INVOICE_AMOUNT,
       INVOICE_CURRENCY_CODE,
       INVOICE_DATE,
       SOURCE,
       DESCRIPTION,
       GOODS_RECEIVED_DATE,
       INVOICE_RECEIVED_DATE,
       CREATION_DATE,
       EXCHANGE_RATE,
       EXCHANGE_RATE_TYPE,
       EXCHANGE_DATE,
                     TERMS_ID,
       GROUP_ID,
    DOC_CATEGORY_CODE,------- added by sandeep on 11-sep-2008
                     ORG_ID ,
      attribute_category,
      attribute6 ,
                   attribute7 ,
                   attribute8 ,
                   attribute9           -- Bug#2492041
             --GL_DATE        /* Bug 4718994. Commenting gl_date so that AP determines the same based on GL date basis */
       ) VALUES
      (x_curr_invoice_id,
       x_curr_invoice_num,
       x_curr_vendor_id,
       x_curr_pay_site_id,
       x_curr_invoice_amount,  /* Bug 3506659 */
       x_curr_currency_code,
       X_curr_le_transaction_date, --Bug 5262997
       'ERS',  -- debug, needs to change,
       x_invoice_description,
       X_curr_le_transaction_date, --Bug 5262997
       X_curr_le_transaction_date, --Bug 5262997
       sysdate,
       x_curr_conversion_rate,
       x_curr_conversion_rate_type,
       x_curr_conversion_rate_date,
                     X_curr_payment_terms_id,
       x_group_id,
    v_document_category,------- added by sandeep on 11-sep-2008
                     x_org_id,
       l_attr_cat,
      'person_id: ' ||l_scm_head,
   l_requester,
            l_supervisor,
   'person_id: ' ||l_fin_head
             --inv_le_timezone_pub.get_le_day_for_ou(x_curr_transaction_date, x_org_id)
       );
                /* Bug 3506659 Start
                * Call the Tax engine by passing the input Plsql table that has the tax
                * information populated in it, get the recoverable and non recoverable
                * tax amounts via the output plsql tables x_recov_tax_tbl and
                * x_nonrecov_tax_tbl respectively, sum them and add the resultant value
                * to the invoice amount.
                */
               IF (g_this_invoice_has_tax) THEN
                  IF (g_asn_debug = 'Y') THEN
                      asn_debug.put_line('Calling Tax API for invoice ' || x_curr_invoice_num);
                      asn_debug.put_line('Invoice Id = ' || to_char(x_curr_invoice_id));
                  END IF;
                  /* Bug 4112614: Flushing recoverable and non recoverable tax pl/sql tables */
                  x_recov_tax_tbl.delete;
                  x_nonrecov_tax_tbl.delete;
                  AP_POR_TAX_PKG.calculate_tax(p_tax_info_tbl,
                                               x_recov_tax_tbl,
                                               x_nonrecov_tax_tbl);
                  IF (g_asn_debug = 'Y') THEN
                     asn_debug.put_line('After Tax API call - ' || 'Return count is ' || to_char(x_recov_tax_tbl.count));
                  END IF;
                  x_cnt := 1;
                  x_tax_amount := 0;
                  loop
                      exit when (x_recov_tax_tbl.count = 0);
                      x_tax_amount := x_tax_amount + (nvl(x_recov_tax_tbl(x_cnt),0) + nvl(x_nonrecov_tax_tbl(x_cnt),0));
                      IF (g_asn_debug = 'Y') THEN
                      asn_debug.put_line('Tax Amount for this line is ' || to_char(x_tax_amount));
                      END IF;
                      x_cnt := x_cnt + 1;
                      exit when (x_cnt > x_recov_tax_tbl.count);
                  end loop;
                  IF (g_asn_debug = 'Y') THEN
                      asn_debug.put_line('Total Tax Amount is ' || to_char(x_tax_amount));
                      asn_debug.put_line('Updating invoice header amount');
                  END IF;
    --Bug 5477365:Add the tax amount to the header amount only if the
    --tax code does not have an offset tax attached to it.
  /*  open c_offset_tax(X_rcv_txns.tax_code_id,x_org_id);
    fetch c_offset_tax into l_offset_tax_id;
    close c_offset_tax;
                  if (x_tax_amount > 0 and l_offset_tax_id is NULL) then
                      update ap_invoices_interface
                      set invoice_amount = invoice_amount + x_tax_amount
                      where invoice_id = x_curr_invoice_id;
                  end if; */
     /*Added for Bug 6070030 - Reversing the fix of bug 5477365  */
                      update ap_invoices_interface
                      set invoice_amount = invoice_amount + x_tax_amount
                      where invoice_id = x_curr_invoice_id;
               END IF;  /* End of g_this_invoice_has_tax */
               /* Reset the global variables after the invoice creation */
                g_this_invoice_dist_cnt := 0;
                g_this_invoice_has_tax := FALSE;
                g_inv_line_id := 0;
                p_tax_info_tbl.delete;  --bug 4112614 to flush the input tax records pl/sql table
            /* Bug 3506659 End */
  /*** We do not need to round our amounts here because
  the invoice amount and tax amount are calculated within
  the create_invoice_distributions and roundings are done
  there. ***/
  /*** Update running totals ***/
  X_progress := '170';
  X_invoice_count := X_invoice_count + 1;
  X_invoice_running_total := X_invoice_running_total + X_curr_invoice_amount;
  X_progress := '180';
 END IF;    -- if X_rcv_first_flag
 IF (g_asn_debug = 'Y') THEN
    asn_debug.put_line('Completed create receipt invoices program... ');
 END IF;
 select count(*) into x_dist_count
 from ap_invoice_lines_interface
 where invoice_id = x_curr_invoice_id;
 if (x_dist_count = 0 ) then
  x_invoice_count := x_invoice_count - 1;
  delete from ap_invoices_interface
  where invoice_id=x_curr_invoice_id;
 end if;
 /*
 ** if x_group_id is not null, then at least one record has been inserted.
 ** Then we need to run the AP import program
 */
 IF (x_group_id is NOT NULL) THEN
           FND_PROFILE.GET('USER_ID', l_user_id);
         /*Bug# 1539257 Building the batch name which was earlier NA */
                fnd_message.set_name('PO', 'PO_INV_CR_ERS_BATCH_DESC');
                X_batch_name := fnd_message.get;
             SELECT  ap_batches_s.nextval
             INTO    X_tmp_batch_id
             FROM    dual;
    /* need to commit before we submit another conc request, since
       the request in another session */
    COMMIT;
/* <PAY ON USE FPI START> */
/* fnd_request.submit_request has been replaced by
   BILC_PO_INVOICES_SV1.submit_invoice_import as a result of refactoring
   performed during FPI Consigned Inv project */
    bilc_PO_INVOICES_SV1.submit_invoice_import(
                l_return_status,
                'ERS',
                x_group_id,
                x_batch_name || '/' || TO_CHAR(sysdate)
                    || '/' || TO_CHAR(X_tmp_batch_id),
                l_user_id,
                0,
                v_req_id);
           IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
           END IF;
/* <PAY ON USE FPI END> */
            fnd_message.set_name('PO', 'PO_ERS_CONC_REQUEST_CHECK');
     fnd_message.set_token('REQUEST', TO_CHAR(v_req_id));
     fnd_message.set_token('BATCH', x_group_id);
       IF (g_asn_debug = 'Y') THEN
          asn_debug.put_line(fnd_message.get);
       END IF;
         END IF;
 RETURN (X_completion_status);
EXCEPTION
/* <PAY ON USE FPI START> */
WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
        l_error_msg := FND_MSG_PUB.get(p_encoded => 'F');
        IF (g_asn_debug = 'Y') THEN
           ASN_DEBUG.put_line(l_error_msg);
        END IF;
        RAISE;
/* <PAY ON USE FPI END> */
WHEN l_exit_procedure then
 l_error_msg := FND_MSG_PUB.get(p_encoded => 'F');
        IF (g_asn_debug = 'Y') THEN
           ASN_DEBUG.put_line(l_error_msg);
        END IF;
        RAISE;

WHEN others THEN
 IF (g_asn_debug = 'Y') THEN
    asn_debug.put_line('Error in Create Receipt Invoices ...');
 END IF;
        po_message_s.sql_error('create_receipt_invoices', X_progress, sqlcode);
 RAISE;
END create_receipt_invoices;
/*================================================================
  PROCEDURE NAME: wrap_up_current_invoice()
==================================================================*/
PROCEDURE WRAP_UP_CURRENT_INVOICE(X_new_vendor_id IN NUMBER,
  X_new_pay_site_id  IN NUMBER,
  X_new_currency_code  IN VARCHAR2,
  X_new_conversion_rate_type IN VARCHAR2,
  X_new_conversion_rate_date IN DATE,
  X_new_conversion_rate  IN NUMBER,
  X_new_payment_terms_id  IN NUMBER,
  X_new_transaction_date  IN DATE,
         X_new_packing_slip  IN VARCHAR2,
  X_new_shipment_header_id IN NUMBER,
  X_terms_date   IN DATE,
  X_payment_priority  IN VARCHAR2,
/*Bug 586895*/  X_new_payment_code              IN VARCHAR2,
  X_curr_method_code              IN OUT NOCOPY VARCHAR2,
/*Bug 612979*/  X_new_pay_curr_code             IN VARCHAR2,
  X_curr_pay_curr_code            IN OUT NOCOPY VARCHAR2,
  X_batch_id   IN OUT NOCOPY NUMBER,
  X_curr_invoice_amount  IN OUT NOCOPY NUMBER,
  X_curr_tax_amount  IN OUT NOCOPY NUMBER,
  X_curr_invoice_id  IN OUT NOCOPY NUMBER,
  X_curr_vendor_id  IN OUT NOCOPY NUMBER,
  X_curr_pay_site_id  IN OUT NOCOPY NUMBER,
         X_curr_currency_code  IN OUT NOCOPY VARCHAR2,
  X_curr_conversion_rate_type IN OUT NOCOPY VARCHAR2,
  X_curr_conversion_rate_date IN OUT NOCOPY DATE,
  X_curr_conversion_rate  IN OUT NOCOPY NUMBER,
  X_curr_payment_terms_id  IN OUT NOCOPY NUMBER,
  X_curr_transaction_date  IN OUT NOCOPY DATE,
  X_curr_packing_slip  IN OUT NOCOPY VARCHAR2,
         X_curr_shipment_header_id IN OUT NOCOPY NUMBER,
  X_curr_inv_process_flag  IN OUT NOCOPY VARCHAR2,
  X_invoice_count   IN OUT NOCOPY NUMBER,
  X_invoice_running_total  IN OUT NOCOPY NUMBER,
  X_org_id IN NUMBER, --Bug 5533454
  X_curr_le_transaction_date IN OUT NOCOPY DATE )
IS
 X_progress     VARCHAR2(3) := NULL;
 X_discountable_amount  NUMBER;
 X_pay_cross_rate  NUMBER;
        X_ap_pay_curr           po_vendor_sites.payment_currency_code%TYPE;
BEGIN
 IF (g_asn_debug = 'Y') THEN
    asn_debug.put_line('Wrapping up the current invoice ... ');
 END IF;
 IF (X_curr_inv_process_flag = 'Y') THEN
  X_progress := '010';
  /*** a new invoice needs to be created ... and we need to
  update the current one before the new one can be created.  ***/
                -- BUG 612979
                IF (gl_currency_api.is_fixed_rate(X_curr_pay_curr_code, X_curr_currency_code, X_curr_transaction_date) = 'Y'
                    and X_curr_pay_curr_code <> X_curr_currency_code) THEN
                       X_pay_cross_rate := gl_currency_api.get_rate(X_curr_currency_code,
            X_curr_pay_curr_code,
                                                                    X_curr_transaction_date,
            'EMU FIXED');
                ELSE
                       X_pay_cross_rate := 1;
                END IF;
                IF (X_pay_cross_rate = 1) THEN
                    X_ap_pay_curr := X_curr_currency_code;
                ELSE
                    X_ap_pay_curr := X_curr_pay_curr_code;
                END IF;
              IF (g_asn_debug = 'Y') THEN
                 asn_debug.put_line ('x_pay_cross_rate ='|| x_pay_cross_rate);
                    asn_debug.put_line ('X_pay_curr_invoice_amount ='|| ap_utilities_pkg.ap_round_currency(X_curr_invoice_amount * X_pay_cross_rate, X_ap_pay_curr));
              END IF;
  -- create invoice header here
  /*** update the running totals ***/
  X_invoice_count := X_invoice_count + 1;
  X_invoice_running_total := X_invoice_running_total +
     X_curr_invoice_amount;
  X_progress := '020';
 END IF;   -- curr_inv_process_flag
 /*** assign the correct exchange rate info if currency changes ***/
 /*** remember the first occurrence of the exchange rate info will be
 used ***/
 /*** make sure the "current" variables are correct ***/
 X_progress := '080';
        select ap_invoices_interface_s.nextval
        into   x_curr_invoice_id
        from   sys.dual;
 X_curr_invoice_amount := 0;
 X_curr_tax_amount := 0;
 X_curr_vendor_id  := X_new_vendor_id;
 X_curr_pay_site_id  := X_new_pay_site_id;
 X_curr_currency_code := X_new_currency_code;
 X_curr_conversion_rate_type := X_new_conversion_rate_type;
 X_curr_conversion_rate  := X_new_conversion_rate;
        X_curr_conversion_rate_date := X_new_conversion_rate_date;
 X_curr_payment_terms_id := X_new_payment_terms_id;
 X_curr_transaction_date := X_new_transaction_date;
 X_curr_packing_slip := X_new_packing_slip;
 X_curr_shipment_header_id := X_new_shipment_header_id;
        /**   Bug 586895      **/
        X_curr_method_code       := X_new_payment_code;
        X_curr_pay_curr_code     := X_new_pay_curr_code;
        --Bug 5533454
   X_curr_le_transaction_date   :=
               INV_LE_TIMEZONE_PUB.GET_LE_DAY_TIME_FOR_OU(x_curr_transaction_date,x_org_id);
EXCEPTION
WHEN others THEN
      po_message_s.sql_error('wrap_up_current_invoice', x_progress,sqlcode);
 RAISE;
END wrap_up_current_invoice;
/* =================================================================
 FUNCTION NAME:  create_invoice_num()
==================================================================*/
FUNCTION create_invoice_num (
   x_org_id                        IN   NUMBER, -- SBI ENH
   x_vendor_site_id                IN   NUMBER, -- SBI ENH
   x_pay_on_receipt_summary_code   IN   VARCHAR2,
   x_invoice_date                  IN   DATE,
   x_packing_slip                  IN   VARCHAR2,
   x_receipt_num                   IN   VARCHAR2,
   p_source                        IN   VARCHAR2 := NULL /* <PAY ON USE FPI> */
)
   RETURN VARCHAR2
IS
   x_progress                    VARCHAR2 (3)                   := NULL;
   x_tmp_sequence_id             NUMBER;
   x_tmp_invoice_num             ap_invoices.invoice_num%TYPE;
   x_prefix                      VARCHAR2 (20);
   -- SBI ENH
   x_return_status               VARCHAR2 (1);
   x_msg_data                    VARCHAR2 (2000);
   x_msg_count                   NUMBER;
   x_buying_company_identifier   VARCHAR2 (10);
   x_selling_company_identifier  VARCHAR2 (10);
   x_gapless_inv_num_flag_org    VARCHAR2 (1);
   x_gapless_inv_num_flag_sup    VARCHAR2 (1);
   x_invoice_num                 VARCHAR2 (45);
   -- SBI ENH
BEGIN
   IF (g_asn_debug = 'Y') THEN
      asn_debug.put_line ('Constructing Invoice Num for the invoice ... ');
   END IF;
   x_progress := '001';
   po_ap_integration_grp.get_invoice_numbering_options (1,
                                                        x_org_id,
                                                        x_return_status,
                                                        x_msg_data,
                                                        x_buying_company_identifier,
                                                        x_gapless_inv_num_flag_org
                                                       );
   x_progress := '002';
   AP_PO_GAPLESS_SBI_PKG.site_uses_gapless_num (x_vendor_site_id,
                                                x_gapless_inv_num_flag_sup,
                                                x_selling_company_identifier
                                               );
   x_progress := '003';
   IF (x_gapless_inv_num_flag_org = 'Y' or x_gapless_inv_num_flag_sup = 'Y') THEN -- SBI ENH
      rcv_gapless_numbering.generate_invoice_number (1,
                                                     x_buying_company_identifier,
                                                     x_selling_company_identifier,
                                                     'ERS',
                                                     x_invoice_num,
                                                     x_return_status,
                                                     x_msg_count,
                                                     x_msg_data
                                                    );
      x_progress := '004';
      IF (x_return_status = fnd_api.g_ret_sts_success) THEN
         RETURN x_invoice_num;
      ELSE
         RAISE create_invoice_error;
      END IF;
   END IF;
   x_progress := '010';
   SELECT po_invoice_num_segment_s.NEXTVAL
   INTO   x_tmp_sequence_id
   FROM   SYS.DUAL;
   x_progress := '020';
/* <PAY ON USE FPI START> */
   IF (p_source = 'USE') THEN
      x_progress := '025';
      x_tmp_invoice_num :=
             'USE-'
          || TO_CHAR (x_invoice_date)
          || '-'
          || TO_CHAR (x_tmp_sequence_id);
   ELSE
/* <PAY ON USE FPI END> */
      -- Use Profile option to determine prefix
      fnd_profile.get ('ERS_PREFIX', x_prefix);
      x_progress := '030';
      IF (x_pay_on_receipt_summary_code = 'PAY_SITE') THEN
         x_progress := '040';
         x_tmp_invoice_num :=
                x_prefix
             || '-'
             || TO_CHAR (x_invoice_date)
             || '-'
             || TO_CHAR (x_tmp_sequence_id);
      ELSIF (x_pay_on_receipt_summary_code = 'PACKING_SLIP') THEN
         x_progress := '050';
         x_tmp_invoice_num :=
                x_prefix
             || '-'
             || x_packing_slip
             || '-'
             || TO_CHAR (x_tmp_sequence_id);
      ELSIF (x_pay_on_receipt_summary_code = 'RECEIPT') THEN
         x_progress := '060';
         x_tmp_invoice_num :=
                x_prefix
             || '-'
             || x_receipt_num
             || '-'
             || TO_CHAR (x_tmp_sequence_id);
      END IF; -- x_pay_on_receipt_summary_code
   END IF; -- p_source
   RETURN (x_tmp_invoice_num);
EXCEPTION
   WHEN create_invoice_error THEN
      FND_MESSAGE.SET_NAME('PO','RCV_CREATE_INVOICE_NUM_ERROR');
      FND_MESSAGE.SET_TOKEN('RECEIPT_NUM',x_receipt_num);
      FND_MESSAGE.SET_TOKEN('REASON',x_msg_data);
      FND_FILE.PUT_LINE(FND_FILE.LOG,FND_MESSAGE.GET);
      RAISE create_invoice_error;
   WHEN OTHERS THEN
      po_message_s.sql_error ('create_invoice_num', x_progress, SQLCODE);
      FND_FILE.PUT_LINE(FND_FILE.LOG,FND_MESSAGE.GET);
      RAISE;
END create_invoice_num;
/* =====================================================================
   PROCEDURE get_received_quantity
======================================================================== */
PROCEDURE get_received_quantity( X_transaction_id     IN     NUMBER,
                                 X_shipment_line_id   IN     NUMBER,
                                 X_received_quantity  IN OUT NOCOPY NUMBER) IS
   X_current_quantity    NUMBER := 0;
   X_primary_uom         VARCHAR2(25) := '';
   X_po_uom              VARCHAR2(25) := '';
   X_item_id             NUMBER := 0;
   v_primary_uom         VARCHAR2(25) := '';
   v_po_uom              VARCHAR2(25) := '';
   v_txn_id              NUMBER := 0;
   v_primary_quantity    NUMBER := 0;
   v_transaction_type    VARCHAR2(25) := '';
   v_parent_id           NUMBER := 0;
   v_parent_type         VARCHAR2(25) := '';
   CURSOR c_txn_history (c_transaction_id NUMBER) IS
     select
       transaction_id,
       primary_quantity,
       primary_unit_of_measure,
       source_doc_unit_of_measure,
       transaction_type,
       parent_transaction_id
     from
       rcv_transactions
     where
       invoice_status_code <> 'INVOICED'
     start with transaction_id = c_transaction_id
     connect by parent_transaction_id = prior transaction_id;
BEGIN
     OPEN c_txn_history(X_transaction_id);
     LOOP
       FETCH c_txn_history INTO v_txn_id,
                                v_primary_quantity,
                                v_primary_uom,
                                v_po_uom,
                                v_transaction_type,
                                v_parent_id;
       EXIT WHEN c_txn_history%NOTFOUND;
       IF v_transaction_type = 'RECEIVE' THEN
         select
           item_id
         into
           X_item_id
         from
           rcv_shipment_lines
         where
           shipment_line_id = X_shipment_line_id;
         X_current_quantity := v_primary_quantity;
         X_primary_uom := v_primary_uom;
         X_po_uom := v_po_uom;
       ELSIF v_transaction_type = 'CORRECT' THEN
         select
           transaction_type
         into
           v_parent_type
         from
           rcv_transactions
         where
           transaction_id = v_parent_id;
         IF v_parent_type = 'RECEIVE' THEN
           X_current_quantity := X_current_quantity + v_primary_quantity;
         ELSIF v_parent_type = 'RETURN TO VENDOR' THEN
           X_current_quantity := X_current_quantity - v_primary_quantity;
         END IF;
       ELSIF v_transaction_type = 'RETURN TO VENDOR' THEN
         X_current_quantity := X_current_quantity - v_primary_quantity;
       END IF;
     END LOOP;
     CLOSE c_txn_history;
     /* Added debug messages to identify the uoms for which the uom convert function failed.
        For this enclosed the uom_convert function in a begin,exception and end block.
        Bug 2923345. */
     if (X_primary_uom <> X_po_uom) then
       begin
        po_uom_s.uom_convert(X_current_quantity,
                             X_primary_uom,
                             X_item_id,
                             X_po_uom,
                             X_received_quantity);
      exception
        WHEN NO_DATA_FOUND THEN
       IF (g_asn_debug = 'Y') THEN
         asn_debug.put_line('conversion not defined between uoms '||x_primary_uom||' and  '||X_po_uom);
       END IF;
       RAISE;
       WHEN OTHERS THEN
        IF (g_asn_debug = 'Y') THEN
         asn_debug.put_line('Exception occured while converting from uom '||x_primary_uom||' to uom  '||X_po_uom);
         asn_debug.put_line('Check if conversion exists between uoms '||x_primary_uom||' and  '||X_po_uom);
       END IF;
       RAISE;
       end;
     else
        X_received_quantity := X_current_quantity;
     end if;
END get_received_quantity;
/* =====================================================================
   PROCEDURE get_received_amount
======================================================================== */
PROCEDURE get_received_amount( X_transaction_id     IN     NUMBER,
                               X_shipment_line_id   IN     NUMBER,
                               X_received_amount    IN OUT NOCOPY NUMBER) IS
   l_current_amount      NUMBER := 0;
   v_txn_id              NUMBER := 0;
   v_amount              NUMBER := 0;
   v_transaction_type    VARCHAR2(25) := '';
   v_parent_id           NUMBER := 0;
   v_parent_type         VARCHAR2(25) := '';
   CURSOR c_txn_history (c_transaction_id NUMBER) IS
     select
       transaction_id,
       amount,
       transaction_type,
       parent_transaction_id
     from
       rcv_transactions
     where
       invoice_status_code <> 'INVOICED'
     start with transaction_id = c_transaction_id
     connect by parent_transaction_id = prior transaction_id;
BEGIN
     OPEN c_txn_history(X_transaction_id);
     LOOP
       FETCH c_txn_history INTO v_txn_id,
                                v_amount,
                                v_transaction_type,
                                v_parent_id;
       EXIT WHEN c_txn_history%NOTFOUND;
       IF v_transaction_type = 'RECEIVE' THEN
         l_current_amount := v_amount;
       ELSIF v_transaction_type = 'CORRECT' THEN
         select
           transaction_type
         into
           v_parent_type
         from
           rcv_transactions
         where
           transaction_id = v_parent_id;
         IF v_parent_type = 'RECEIVE' THEN
           l_current_amount := l_current_amount + v_amount;
         ELSIF v_parent_type = 'RETURN TO VENDOR' THEN
           l_current_amount := l_current_amount - v_amount;
         END IF;
       ELSIF v_transaction_type = 'RETURN TO VENDOR' THEN
         l_current_amount := l_current_amount - v_amount;
       END IF;
     END LOOP;
     CLOSE c_txn_history;
     X_received_amount := l_current_amount; /* Bug3493515 (1) */
END get_received_amount;
/********************************************************************/
/*                                                                  */
/* PROCEDURE  create_invoice_distributions              */
/*                                                                  */
/********************************************************************/
PROCEDURE create_invoice_distributions(X_invoice_id   IN NUMBER,
      X_invoice_currency_code  IN VARCHAR2,
      X_base_currency_code   IN VARCHAR2,
      X_batch_id    IN NUMBER,
      X_vendor_id                   IN NUMBER,
      X_pay_site_id   IN NUMBER,
      X_auto_tax_calc_flag          IN VARCHAR2, -- bug 3506659
      X_tax_rounding_rule           IN VARCHAR2,
      X_po_header_id   IN NUMBER,
      X_po_line_id    IN NUMBER,
      X_po_line_location_id  IN NUMBER,
      X_po_release_id   IN NUMBER,  -- bug 901039
      X_receipt_event   IN VARCHAR2,
      X_po_distribution_id   IN NUMBER,
         /*X_receipt_event and X_po_distribution_id
         used only for DELIVER transactions*******/
      X_item_description   IN VARCHAR2,
      X_type_1099    IN VARCHAR2,
      X_tax_code_id   IN OUT NOCOPY NUMBER,
      X_tax_amount    IN NUMBER,
         /*This will be populated only for shipment
         and bill notices; for the other cases tax
         amount will be calculated****************/
      X_create_tax_dist_flag  IN VARCHAR2,
         /*If set to 'Y', create_tax_distributions
         API will be invoked to create tax distributions
         lines.  This flag will be set to 'N' for
         the case where a shipment and billing notice
         specifies a tax_amount and tax_name at the
         shipment header level.  We will then create
         only one tax distribution line for the entire
         invoice and not create any tax distributions
         for the individual distributions. (see Key
         assumptions.)******************************/
      X_quantity    IN NUMBER,
      X_unit_price    IN NUMBER,
      X_exchange_rate_type   IN VARCHAR2,
      X_exchange_date   IN DATE,
      X_exchange_rate   IN NUMBER,
      X_accts_pay_code_comb_id  IN NUMBER,
      X_invoice_date   IN DATE,
      X_receipt_date   IN DATE,
      X_vendor_income_tax_region  IN VARCHAR2,
      X_reference_1   IN VARCHAR2,
      X_reference_2   IN VARCHAR2,
      X_awt_flag   IN VARCHAR2,
      X_awt_group_id  IN NUMBER,
      X_accounting_date  IN DATE,
      X_period_name   IN VARCHAR2,
      X_transaction_type  IN VARCHAR2,
      X_unique_id   IN NUMBER,
      X_curr_invoice_amount  IN OUT NOCOPY   NUMBER,
      X_curr_tax_amount   IN OUT NOCOPY NUMBER,
                                  X_curr_inv_process_flag  IN OUT NOCOPY VARCHAR2,
      X_receipt_num          IN VARCHAR2 DEFAULT NULL,
      X_rcv_transaction_id         IN NUMBER   DEFAULT NULL,
                                  X_match_option                IN VARCHAR2 DEFAULT NULL,
                                  X_amount                      IN NUMBER   DEFAULT NULL,
                                  X_matching_basis              IN VARCHAR2 DEFAULT 'QUANTITY')
               IS
/*** Cursor Declaration ***/
/* Bug 3338268 - removed X_receipt_event */
CURSOR c_po_distributions(X_po_header_id        NUMBER,
         X_po_line_id           NUMBER,
         X_po_line_location_id  NUMBER,
         X_po_distribution_id   NUMBER
   )
IS
  SELECT   pod.po_distribution_id,
    pod.set_of_books_id,
    DECODE (pod.destination_type_code,
                  'EXPENSE', DECODE (pod.accrue_on_receipt_flag,
                                     'Y', pod.accrual_account_id,
                                     pod.code_combination_id
                                    ),
                  pod.accrual_account_id
                 ) code_combination_id,
    DECODE(gcc.account_type, 'A','Y','N') assets_tracking_flag,
    NVL(pod.quantity_ordered,0) quantity_remaining,
    NVL(pod.amount_ordered,0) amount_remaining,
    pod.rate,
    pod.rate_date,
    pod.variance_account_id,
    pod.attribute_category,
    pod.attribute1,
    pod.attribute2,
    pod.attribute3,
    pod.attribute4,
    pod.attribute5,
    pod.attribute6,
    pod.attribute7,
    pod.attribute8,
    pod.attribute9,
    pod.attribute10,
    pod.attribute11,
    pod.attribute12,
    pod.attribute13,
    pod.attribute14,
    pod.attribute15,
    pod.project_id, -- the following are PA related columns
    pod.task_id,
    pod.expenditure_item_date,
    pod.expenditure_type,
    pod.expenditure_organization_id,
    pod.project_accounting_context,
           pod.recovery_rate,
           pod.tax_recovery_override_flag
  FROM     gl_code_combinations    gcc,
           po_distributions  pod
  WHERE    pod.po_header_id        = X_po_header_id
  AND      pod.po_line_id          = X_po_line_id
  AND      pod.line_location_id    = X_po_line_location_id
  AND    pod.code_combination_id = gcc.code_combination_id
  AND      DECODE(X_receipt_event, 'DELIVER', pod.po_distribution_id, 1)=
           DECODE(X_receipt_event, 'DELIVER', X_po_distribution_id, 1)
  ORDER BY pod.distribution_num;
/**** Variable declarations ****/
/*  Bug 3338268 */
x_pod_distribution_id                po_distributions.po_distribution_id%TYPE  := NULL;
x_pod_set_of_books_id                po_distributions.set_of_books_id%TYPE  := NULL;
x_pod_code_combinations_id           po_distributions.code_combination_id%TYPE  := NULL;
x_pod_assets_tracking_flag           VARCHAR2(1)     := NULL;
x_pod_quantity_remaining             po_distributions.quantity_ordered%TYPE  := NULL;
x_pod_amount_remaining               po_distributions.amount_ordered%TYPE  := NULL;
x_pod_rate                           po_distributions.rate%TYPE    := NULL;
x_pod_rate_date                      po_distributions.rate_date%TYPE   := NULL;
x_pod_variance_account_id            po_distributions.variance_account_id%TYPE  := NULL;
x_pod_attribute_category             po_distributions.attribute_category%TYPE  := NULL;
x_pod_attribute1                     po_distributions.attribute1%TYPE   := NULL;
x_pod_attribute2                     po_distributions.attribute2%TYPE   := NULL;
x_pod_attribute3                     po_distributions.attribute3%TYPE   := NULL;
x_pod_attribute4                     po_distributions.attribute4%TYPE   := NULL;
x_pod_attribute5                     po_distributions.attribute5%TYPE   := NULL;
x_pod_attribute6                     po_distributions.attribute6%TYPE   := NULL;
x_pod_attribute7                     po_distributions.attribute7%TYPE   := NULL;
x_pod_attribute8                     po_distributions.attribute8%TYPE   := NULL;
x_pod_attribute9                     po_distributions.attribute9%TYPE   := NULL;
x_pod_attribute10                    po_distributions.attribute10%TYPE   := NULL;
x_pod_attribute11                    po_distributions.attribute11%TYPE   := NULL;
x_pod_attribute12                    po_distributions.attribute12%TYPE   := NULL;
x_pod_attribute13                    po_distributions.attribute13%TYPE   := NULL;
x_pod_attribute14                    po_distributions.attribute14%TYPE   := NULL;
x_pod_attribute15                    po_distributions.attribute15%TYPE   := NULL;
x_pod_project_id                     po_distributions.project_id%TYPE   := NULL;
x_pod_task_id                        po_distributions.task_id%TYPE   := NULL;
x_pod_expenditure_item_date          po_distributions.expenditure_item_date%TYPE := NULL;
x_pod_expenditure_type               po_distributions.expenditure_type%TYPE  := NULL;
x_pod_expenditure_org_id             po_distributions.expenditure_organization_id%TYPE := NULL;
x_pod_proj_accounting_context        po_distributions.project_accounting_context%TYPE := NULL;
/* End Bug 3338268 */
/* Bug3875677 */
x_pod_recovery_rate                  po_distributions.recovery_rate%TYPE                := NULL;
x_pod_recovery_override_flag         po_distributions.tax_recovery_override_flag%TYPE   := NULL;
X_rowid                VARCHAR2(50);
X_po_distributions     c_po_distributions%ROWTYPE;
X_invoice_distribution_id NUMBER;
X_curr_qty             NUMBER;      /*Qty billed to a particular dist*/
X_curr_amount        NUMBER;
X_temp_tax_amount      NUMBER;
X_sum_order_qty        NUMBER;      /*Used when proration is used*/
X_sum_order_amt        NUMBER;
/* nwang 5/13/1999 */
X_sum_tax              NUMBER;      /*Used when proration is used*/
X_count                NUMBER:=0;   /*Num of distrs for that receive txn*/
X_tmp_count            NUMBER;
X_total_amount        NUMBER;
X_amount_running_total    NUMBER;
X_tax_amount_for_proration NUMBER;
X_tax_running_total    NUMBER;
X_income_tax_region    ap_invoice_distributions.income_tax_region%TYPE;
X_assets_addition_flag VARCHAR2(1);
X_new_dist_line_number ap_invoice_distributions.distribution_line_number%TYPE;
X_base_amount  NUMBER;
X_conversion_rate NUMBER;   -- This is the rate based of match option.
X_conversion_rate_date DATE;
X_progress  VARCHAR2(3) := '';
x_invoice_line_id NUMBER;
X_line_count  NUMBER;
x_org_id                NUMBER;        --Bug# 2492041
/* Bug 3506659 Start */
X_tax_rate              ap_tax_codes.tax_rate%TYPE;
i                       NUMBER := 1;
x_curr_prorated_qty     NUMBER;
x_tbl_rec_cnt           NUMBER;
x_max_dist_amount       NUMBER;
/* Bug 3506659 End */
l_curr_amount           NUMBER; -- Bug 4731249
BEGIN
 IF (g_asn_debug = 'Y') THEN
    asn_debug.put_line('Begin Create Invoice Distributions ');
 END IF;
 /********************
     The algorithm for proration is as follows:
     Suppose there are 1..N distributions that need to be prorated.
     Sum of all the N distributions need to be prorated.
     Sum of all the N distribution qtys = X_total_qty
     Qty to be prorated = X_qty
     Then   for i = 1..N-1 prorated_qty(i) = X_qty*distribution_qty(i)/
         X_total_qty
     for i = N (the last distribution)prorated_qty(i) = X_qty-
           SUM(prorated_qty from q to N-1)
     In this way, the last distribution will handle any rounding errors
     which might occur.
 *********************/
 /***Find out how many distribution records and total ordered qty that
     need to be prorated.***/
 X_progress := '010';
 SELECT     COUNT(*),
     SUM(NVL(quantity_ordered,0)),
     SUM(NVL(amount_ordered,0)),
            SUM(NVL(RECOVERABLE_TAX,0)+ NVL(NONRECOVERABLE_TAX,0))
        /***Amount remaining for each po distribution***/
 INTO       X_count,
     X_sum_order_qty,
     X_sum_order_amt,
            X_sum_tax
 FROM       po_distributions
 WHERE      po_header_id        = X_po_header_id
 AND        po_line_id          = X_po_line_id
 AND        line_location_id = X_po_line_location_id
 AND        DECODE(X_receipt_event, 'DELIVER', po_distribution_id,1)=
     DECODE(X_receipt_event, 'DELIVER', X_po_distribution_id,1);
 /* Removed the fix of 2379414 as it is already commented */
IF (X_count > 0) THEN
   X_progress := '020';
   IF X_matching_basis = 'AMOUNT' THEN
      X_total_amount := X_amount;
   ELSE
      X_total_amount := ap_utilities_pkg.ap_round_currency(
    X_quantity * X_unit_price,
    X_invoice_currency_code);
   END IF;
   X_tmp_count             := 0;
   X_amount_running_total  := 0;
   X_tax_running_total     := 0;
   X_progress := '030';
   /*
   ** nwang 4/13 prorate the tax amount
   */
   /* Bug# 1698069 - Rounding issues with ERS */
    /* IF X_matching_basis = 'AMOUNT' THEN
       X_curr_tax_amount := X_curr_tax_amount + ap_utilities_pkg.ap_round_tax(
                            (x_amount * x_sum_tax/X_sum_order_amt),
                            X_invoice_currency_code,
                            x_tax_rounding_rule,
                            'Round curr tax amount');
    ELSE
       X_curr_tax_amount := X_curr_tax_amount + ap_utilities_pkg.ap_round_tax(
                            (x_quantity * x_sum_tax/X_sum_order_qty),
                             X_invoice_currency_code,
                             x_tax_rounding_rule,
                            'Round curr tax amount');
    END IF; */
   /* Removed the fix of 2379414 from here as it is already commented */
   --Bug 3338268 call only if x_receipt_event='DELIVER', remove x_receipt_event, fetch only one record
   IF (x_receipt_event = 'DELIVER') THEN
     OPEN  c_po_distributions(X_po_header_id,
                              X_po_line_id,
                              X_po_line_location_id,
                              X_po_distribution_id
                             );
     FETCH c_po_distributions INTO
       x_pod_distribution_id,
       x_pod_set_of_books_id,
       x_pod_code_combinations_id,
       x_pod_assets_tracking_flag,
       x_pod_quantity_remaining,
       x_pod_amount_remaining,
       x_pod_rate,
       x_pod_rate_date,
       x_pod_variance_account_id,
       x_pod_attribute_category,
       x_pod_attribute1,
       x_pod_attribute2,
       x_pod_attribute3,
       x_pod_attribute4,
       x_pod_attribute5,
       x_pod_attribute6,
       x_pod_attribute7,
       x_pod_attribute8,
       x_pod_attribute9,
       x_pod_attribute10,
       x_pod_attribute11,
       x_pod_attribute12,
       x_pod_attribute13,
       x_pod_attribute14,
       x_pod_attribute15,
       x_pod_project_id,
       x_pod_task_id,
       x_pod_expenditure_item_date,
       x_pod_expenditure_type,
       x_pod_expenditure_org_id,
       x_pod_proj_accounting_context,
       x_pod_recovery_rate,
       x_pod_recovery_override_flag;
     CLOSE c_po_distributions;
     /* Bug3493515 (3) - Start */
     IF X_matching_basis = 'AMOUNT' THEN
        X_curr_amount:= (X_amount   * X_pod_amount_remaining  )/X_sum_order_amt;
     ELSE
        X_curr_qty   := (X_quantity * X_pod_quantity_remaining)/X_sum_order_qty;
     END IF;
     /* Bug3493515 (3) - End */
   ELSE
     x_curr_amount := x_amount;
     x_curr_qty := x_quantity;
   END IF;
      X_progress := '085';
   /*Bug#2492041 Get the Operating Unit for the PO */
   select org_id
   into   x_org_id
   from   po_headers_all
   where  po_header_id = X_po_header_id;
   --Bug 3338268 - remove line item amt and qty calculations
      X_progress := '100';
      IF X_matching_basis <> 'AMOUNT' THEN
        X_curr_amount := ap_utilities_pkg.ap_round_currency(
     X_curr_qty * X_unit_price,
     X_invoice_currency_code);
      END IF;
      X_progress := '140';
      IF (X_curr_inv_process_flag = 'Y') THEN
 /** continue only if invoice is still processable **/
      X_progress := '160';
 IF (X_invoice_currency_code = X_base_currency_code) THEN
  X_base_amount := NULL;
 ELSE
  X_base_amount := ap_utilities_pkg.ap_round_currency(
      X_curr_amount * X_conversion_rate,
      X_base_currency_code);
 END IF;
       /*** call object handler to create the item distributions ***/
       X_progress := '140';
 IF (g_asn_debug = 'Y') THEN
    asn_debug.put_line('Creating Item Distribution...');
 END IF;
     SELECT NVL(MAX(line_number), 0) + 1
     INTO    X_line_count
     FROM    ap_invoice_lines_interface
     WHERE   invoice_id = x_invoice_id;
    select ap_invoice_lines_interface_s.nextval
    into   x_invoice_line_id
    from   sys.dual;
   /* Bug# 3506659
    * Check if new tax rate is changed for tax code, if so get new the tax_code_id
    */
   if (x_tax_code_id is not null and x_tax_code_id <> g_old_tax_code_id) then
       x_tax_code_id  := AP_TAX_VALIDATE_PKG.get_valid_tax_id(x_tax_code_id,x_invoice_date);
       g_old_tax_code_id  := x_tax_code_id;
   end if;
 /* Bug 1374789: We should not pass project_id and task_id
 ** to AP bas for some reason the AP import program fails
 ** with inconsistent distribution info error.
 ** This is being removed based on APs suggestion.
 ** PROJECT_ID, TASK_ID,
 ** x_po_distributions.project_id, x_po_distributions.task_id,
 */
   /* Bug 2664078 - Since the accounting date is passed as the invoice date
      the Payables Open Interface import program is no considering the
      gl date basis. */
    -- Bug 3338268 - Use variables instead of record
    insert into ap_invoice_lines_interface
      (INVOICE_ID,
       INVOICE_LINE_ID,
       LINE_NUMBER,
       LINE_TYPE_LOOKUP_CODE,
       AMOUNT,
      -- ACCOUNTING_DATE,  Bug 2664078
       DESCRIPTION,
       TAX_CODE_ID,
       AMOUNT_INCLUDES_TAX_FLAG,
       -- DIST_CODE_COMBINATION_ID,
 PO_HEADER_ID,
 PO_LINE_ID,
 PO_LINE_LOCATION_ID,
 PO_DISTRIBUTION_ID,
 PO_RELEASE_ID,
 QUANTITY_INVOICED,
 EXPENDITURE_ITEM_DATE,
 EXPENDITURE_TYPE,
 EXPENDITURE_ORGANIZATION_ID,
 PROJECT_ACCOUNTING_CONTEXT,
  PA_QUANTITY,
 PA_ADDITION_FLAG,
 UNIT_PRICE,
 ASSETS_TRACKING_FLAG,
 ATTRIBUTE_CATEGORY,
 ATTRIBUTE1,
 ATTRIBUTE2,
 ATTRIBUTE3,
 ATTRIBUTE4,
 ATTRIBUTE5,
 ATTRIBUTE6,
 ATTRIBUTE7,
 ATTRIBUTE8,
 ATTRIBUTE9,
 ATTRIBUTE10,
 ATTRIBUTE11,
 ATTRIBUTE12,
 ATTRIBUTE13,
 ATTRIBUTE14,
 ATTRIBUTE15,
        MATCH_OPTION,
        RCV_TRANSACTION_ID,
        RECEIPT_NUMBER,
 TAX_CODE_OVERRIDE_FLAG, -- Bug 921579, PO needs to pass 'Y' for this
        ORG_ID,                 -- Bug#2492041
        TAX_RECOVERY_RATE       -- Bug 3875677
 ) VALUES
      (x_invoice_id,
       x_invoice_line_id,
       x_line_count,
       'ITEM',
       X_curr_amount,
       --x_invoice_date,  Bug  2664078
       x_item_description,
       x_tax_code_id,
       NULL,
       -- x_po_distributions.code_combination_id,
 x_po_header_id,
 x_po_line_id,
 x_po_line_location_id,
 x_pod_distribution_id,
 x_po_release_id,
 x_curr_qty,
 x_pod_expenditure_item_date,
 x_pod_expenditure_type,
 x_pod_expenditure_org_id,
 x_pod_proj_accounting_context,
 x_curr_qty,
 'N',
 x_unit_price,
 x_pod_assets_tracking_flag,
 x_pod_attribute_CATEGORY,
 x_pod_attribute1,
 x_pod_attribute2,
 x_pod_attribute3,
 x_pod_attribute4,
 x_pod_attribute5,
 x_pod_attribute6,
 x_pod_attribute7,
 x_pod_attribute8,
 x_pod_attribute9,
 x_pod_attribute10,
 x_pod_attribute11,
 x_pod_attribute12,
 x_pod_attribute13,
 x_pod_attribute14,
 x_pod_attribute15,
        x_match_option,
        x_rcv_transaction_id,
        x_receipt_num,
 'Y',    -- bug 921579, PO needs to pass 'Y' for this
        x_org_id,
        x_pod_recovery_rate
 );
       /**UPDATE CURRENT INVOICE AMOUNT**/
       X_progress := '150';
       X_curr_invoice_amount:= X_curr_invoice_amount +
           X_curr_amount ;
       IF (g_asn_debug = 'Y') THEN
          asn_debug.put_line('progress: '|| X_progress);
          asn_debug.put_line('curr_invoice_amount: '|| X_curr_invoice_amount);
       END IF;
   END IF; -- X_curr_inv_process_flag
   X_progress := '180';
   /* Bug 3506659
      c_po_distributions is required for tax computation.
      So reusing the cursor.
   */
   /* Bug 3506659 Start */
   IF (g_asn_debug = 'Y') THEN
       asn_debug.put_line('progress: '|| X_progress);
       asn_debug.put_line('X_po_header_id: '|| X_po_header_id);
       asn_debug.put_line('X_po_line_id: '|| X_po_line_id);
       asn_debug.put_line('X_po_line_location_id: '|| X_po_line_location_id);
       asn_debug.put_line('X_po_distribution_id: '|| X_po_distribution_id);
   END IF;
   OPEN  c_po_distributions(X_po_header_id,
                            X_po_line_id,
                            X_po_line_location_id,
                            X_po_distribution_id);
    x_max_dist_amount := 0;  -- variable to store the max distr amount tied of the PO shipment.
    LOOP
    X_progress := '160';
    FETCH  c_po_distributions INTO  X_po_distributions;
    EXIT WHEN  c_po_distributions%NOTFOUND;
    /* Bug 4731249 : Added calculations for Amount Based lines */
    IF X_matching_basis = 'AMOUNT' THEN
      l_curr_amount := (X_amount * X_po_distributions.amount_remaining  )/X_sum_order_amt;
    ELSE
      X_curr_prorated_qty:= (X_quantity * X_po_distributions.quantity_remaining) /X_sum_order_qty;
      l_curr_amount := ap_utilities_pkg.ap_round_currency(x_unit_price*x_curr_prorated_qty, X_invoice_currency_code);
    END IF;
   /* Check if new tax rate is changed for tax code, if so get new the tax_code_id */
    if (x_tax_code_id is not null and x_tax_code_id <> g_old_tax_code_id) then
        x_tax_code_id  := AP_TAX_VALIDATE_PKG.get_valid_tax_id(x_tax_code_id,x_invoice_date);
        g_old_tax_code_id  := x_tax_code_id;
    end if;
   /* Only if the tax calculation level is Line or Tax Code get the tax rate,
    * populate the input tax PL/Sql table for each distribution.
   */
   IF (g_asn_debug = 'Y') THEN
       asn_debug.put_line('x_auto_tax_calc_flag: '|| x_auto_tax_calc_flag);
       asn_debug.put_line('x_tax_code_id: '|| x_tax_code_id);
   END IF;
    IF (x_auto_tax_calc_flag in ('L','T') AND x_tax_code_id is not null) THEN
      select tax_rate
      into x_tax_rate
      from ap_tax_codes_all
      where tax_id = x_tax_code_id;
      g_this_invoice_has_tax := TRUE;
      g_inv_line_id := g_inv_line_id + 1;
      IF (g_asn_debug = 'Y') THEN
          ASN_DEBUG.put_line('Before populating the input Tax PL/Sql table');
          ASN_DEBUG.put_line('Invoice_line_id is ' || to_char(g_inv_line_id));
          ASN_DEBUG.put_line('Current Dist Amount is ' ||to_char(l_curr_amount));
      END IF;
      l_ap_tax_record  :=  AP_POR_TAX_INFO_OBJECT_TYPE(
                           null,null,null,null,null,null,null,null,
                           null,null,null,null,null,null,null,null,
                           null,null,null,null,null,null,null,null,
                           null,null,null,null,null);
      l_ap_tax_record.set_of_books_id             :=  x_po_distributions.set_of_books_id;
      l_ap_tax_record.trx_shipment_id             :=  x_invoice_id;
      l_ap_tax_record.trx_distribution_id         :=  g_inv_line_id;
      l_ap_tax_record.trx_line_type               :=  'ITEM';
      l_ap_tax_record.inventory_item_id           :=  NULL;
      l_ap_tax_record.quantity                    :=  x_curr_prorated_qty;
      l_ap_tax_record.quantity_ordered            :=  NULL;
      l_ap_tax_record.unit_price                  :=  l_curr_amount;
      l_ap_tax_record.currency_unit_price         :=  NULL;
      l_ap_tax_record.ussgl_transaction_code      :=  NULL;
      l_ap_tax_record.ship_to_location_id         :=  NULL;
      l_ap_tax_record.tax_code_id                 :=  x_tax_code_id;
      l_ap_tax_record.tax_user_override_flag      :=  'Y';
      l_ap_tax_record.tax_rate                    :=  x_tax_rate;
      l_ap_tax_record.tax_recovery_rate           :=  x_po_distributions.recovery_rate;
      l_ap_tax_record.project_id                  :=  NULL;
      l_ap_tax_record.task_id                     :=  NULL;
      l_ap_tax_record.award_id                    :=  NULL;
      l_ap_tax_record.expenditure_type            :=  NULL;
      l_ap_tax_record.expenditure_organization_id :=  NULL;
      l_ap_tax_record.expenditure_item_date_str   :=  NULL;
      l_ap_tax_record.date_format_str           :=  NULL;
      l_ap_tax_record.application_short_name      :=  'SQLAP';
      l_ap_tax_record.code_combination_id         :=  x_po_distributions.code_combination_id;
      l_ap_tax_record.tax_recovery_override_flag  :=  x_po_distributions.tax_recovery_override_flag;
      l_ap_tax_record.trx_currency_code           :=  X_invoice_currency_code;
      l_ap_tax_record.exchange_rate               :=  X_exchange_rate ;
      l_ap_tax_record.ship_from_supplier_id       :=  X_vendor_id;
      l_ap_tax_record.ship_from_site_use_id       :=  X_pay_site_id;
      p_tax_info_tbl.extend;
      g_this_invoice_dist_cnt := g_this_invoice_dist_cnt + 1;
      p_tax_info_tbl(g_this_invoice_dist_cnt) := l_ap_tax_record;
      /* If Tax rounding Rule is Nearest then conditionally adjust the amount by -1
         for the distribution which has the max amount. AP too does the same while
         prorating the invoice distributions at the time of processing the AP lines
         interface data.
         The condition is:
         If the distribution running total for the PO shipment is greater than the amount
         for the received qty then adjust the amount by -1 for the distribution
         which has the max amount. With this the tax compuation will be proper.
      */
      IF (X_tax_rounding_rule = 'N') THEN
        if (l_ap_tax_record.unit_price > x_max_dist_amount) then
            x_max_dist_amount := l_ap_tax_record.unit_price;
            x_tbl_rec_cnt := g_this_invoice_dist_cnt;
        end if;
        X_amount_running_total := X_amount_running_total + l_ap_tax_record.unit_price;
      END IF;
    END IF; -- x_auto_tax_calc_flag
   END LOOP;
   IF (X_tax_rounding_rule = 'N' AND X_amount_running_total > x_total_amount) THEN
       p_tax_info_tbl(x_tbl_rec_cnt).unit_price := x_max_dist_amount - 1;
   END IF;
  /* Bug 3506659 End */
ELSE /** X_count = 0, this should be an error we should have atleast one
        distribution for our rcv. txn.**/
   IF (g_asn_debug = 'Y') THEN
      asn_debug.put_line('->Error: No distr available.');
   END IF;
         po_interface_errors_sv1.handle_interface_errors(
    X_transaction_type,
                                'FATAL',
     X_batch_id,
     X_unique_id,   -- header_id
     NULL,  -- line_id
     'PO_INV_CR_NO_DISTR',
     'PO_DISTRIBUTIONS',
     NULL,
     NULL,
     NULL,
     NULL,
     NULL,
     NULL,
     NULL,
     NULL,
     NULL,
     NULL,
     NULL,
     NULL,
     NULL,
     X_curr_inv_process_flag);
END IF;
EXCEPTION
WHEN others THEN
       po_message_s.sql_error('create_invoice_distributions', X_progress,
    sqlcode);
       RAISE;
END create_invoice_distributions;
/* <PAY ON USE FPI START> */
/*******************************************************
 * PROCEDURE create_use_invoices
 *******************************************************/
PROCEDURE create_use_invoices(
    p_api_version       IN  NUMBER,
    x_return_status     OUT NOCOPY  VARCHAR2,
    p_commit_interval   IN  NUMBER,
    p_aging_period      IN  NUMBER)
IS
    l_api_version CONSTANT NUMBER := 1.0;
    l_api_name CONSTANT VARCHAR2(50) := 'create_use_invoices';
    l_consumption   BILC_PO_INVOICES_SV2.consump_rec_type;
    l_ap_inv_header BILC_PO_INVOICES_SV2.invoice_header_rec_type;
    l_curr BILC_PO_INVOICES_SV2.curr_condition_rec_type;
    l_commit_lower NUMBER;
    l_commit_upper NUMBER;
    l_header_idx NUMBER := 0;
    l_invoice_count NUMBER := 0;
    l_distr_count NUMBER := 0;
    l_first_flag VARCHAR2(1) := FND_API.G_TRUE;
    l_aging_period NUMBER;
    l_cutoff_date DATE;
    l_def_base_currency_code ap_system_parameters.base_currency_code%TYPE;
    l_org_id                po_headers.org_id%TYPE;
    l_invoice_desc          ap_invoices_interface.description%TYPE;
    l_group_id ap_invoices_interface.group_id%TYPE;
    l_user_id NUMBER;
    l_login_id NUMBER;
    l_tmp_batch_id NUMBER;
    l_batch_name ap_batches.batch_name%TYPE;
    l_request_id ap_invoices_interface.request_id%TYPE;
    l_error_msg VARCHAR2(2000);
    l_return_status VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
    l_progress VARCHAR2(3);
BEGIN
    l_progress := '000';
    IF (g_asn_debug = 'Y') THEN
       ASN_DEBUG.put_line('Enter create use invoices');
    END IF;
    x_return_status := FND_API.G_RET_STS_SUCCESS;
    IF NOT FND_API.Compatible_API_Call (
                    l_api_version,
     p_api_version,
     l_api_name,
     g_pkg_name)
    THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF; -- check api version compatibility
    IF (g_asn_debug = 'Y') THEN
       ASN_DEBUG.put_line('API Version Check is passed');
    END IF;
    l_progress := '010';
   /* Bug 3506659 Start */
    g_this_invoice_dist_cnt := 0;
    g_this_invoice_has_tax := FALSE;
    g_inv_line_id := 0;
    p_tax_info_tbl        :=  AP_POR_TAX_INFO_OBJ_TBL_TYPE();
    x_recov_tax_tbl       :=  AP_POR_TAX_NUMBER_TBL_TYPE();
    x_nonrecov_tax_tbl    :=  AP_POR_TAX_NUMBER_TBL_TYPE();
   /* Bug 3506659  End */
    IF (g_asn_debug = 'Y') THEN
       ASN_DEBUG.put_line('Aging period passing in = ' || p_aging_period);
    END IF;
    IF (p_aging_period IS NULL) THEN
        IF (g_asn_debug = 'Y') THEN
           ASN_DEBUG.put_line('Getting aging period from profile');
        END IF;
        l_aging_period :=
            NVL(FLOOR(TO_NUMBER(FND_PROFILE.VALUE('AGING_PERIOD'))), 0);
        IF (g_asn_debug = 'Y') THEN
           ASN_DEBUG.put_line('After getting aging period from profile,
                               aging period = ' || l_aging_period);
        END IF;
        IF (l_aging_period < 0) THEN
            l_aging_period := 0;
        END IF;
    ELSE
        l_aging_period := p_aging_period;
    END IF; -- p_aging_period IS NULL
    l_cutoff_date := TRUNC(SYSDATE) + 1 - l_aging_period;
    IF (g_asn_debug = 'Y') THEN
       ASN_DEBUG.put_line('Aging Period = ' || l_aging_period ||
                           ' Cutoff Date = ' || l_cutoff_date);
    END IF;
    l_progress := '020';
    -- get base currency
    SELECT base_currency_code
    INTO   l_def_base_currency_code
    FROM   ap_system_parameters;
    IF (g_asn_debug = 'Y') THEN
       ASN_DEBUG.put_line('Base Currency Code = ' || l_def_base_currency_code);
    END IF;
    OPEN BILC_PO_INVOICES_SV2.c_consumption(l_cutoff_date);
    IF (g_asn_debug = 'Y') THEN
       ASN_DEBUG.put_line('Using Bulk Collect. Limit = ' || g_fetch_size);
    END IF;
    LOOP
        l_progress := '030';
        IF (g_asn_debug = 'Y') THEN
           ASN_DEBUG.put_line('In Outer Loop');
        END IF;
        l_commit_lower := 1;
        l_commit_upper := 0;
        FETCH c_consumption
        BULK COLLECT INTO   l_consumption.po_header_id,
                            l_consumption.po_release_id,
                            l_consumption.po_line_id,
                            l_consumption.line_location_id,
                            l_consumption.po_distribution_id,
                            l_consumption.vendor_id,
                            l_consumption.pay_on_receipt_summary_code,
                            l_consumption.vendor_site_id,
                            l_consumption.default_pay_site_id,
                            l_consumption.item_description,
                            l_consumption.unit_price,
                            l_consumption.quantity_ordered,
                            l_consumption.quantity_billed,
                            l_consumption.currency_code,
                            l_consumption.currency_conversion_type,
                            l_consumption.currency_conversion_rate,
                            l_consumption.currency_conversion_date,
                            l_consumption.payment_currency_code,
                            l_consumption.creation_date,
                            l_consumption.payment_terms_id,
                            l_consumption.tax_code_id,
                            l_consumption.tax_rounding_rule,
                            l_consumption.auto_tax_calc_flag,
                            l_consumption.org_id
        LIMIT g_fetch_size;
        l_progress := '040';
        IF (g_asn_debug = 'Y') THEN
           ASN_DEBUG.put_line('After Bulk Collect. Fetched ' ||
                               l_consumption.po_header_id.COUNT || ' records');
        END IF;
        FOR i IN 1..l_consumption.po_header_id.COUNT LOOP
            IF (g_asn_debug = 'Y') THEN
               ASN_DEBUG.put_line('In Inner Loop. i = ' || i);
            END IF;
            IF (l_first_flag = FND_API.G_TRUE) THEN
                l_progress := '050';
                l_first_flag := FND_API.G_FALSE;
                IF (g_asn_debug = 'Y') THEN
                   ASN_DEBUG.put_line('First Record.');
                END IF;
                l_org_id := l_consumption.org_id(i);
                -- get group id
                SELECT 'USE-' || ap_interface_groups_s.nextval
                INTO   l_group_id
                FROM   sys.dual;
                IF (g_asn_debug = 'Y') THEN
                   ASN_DEBUG.put_line('group_id = ' || l_group_id);
                END IF;
                -- get invoice description
                FND_MESSAGE.set_name('PO', 'PO_INV_CR_USE_INVOICE_DESC');
                FND_MESSAGE.set_token('RUN_DATE', sysdate);
                l_invoice_desc := FND_MESSAGE.get;
                IF (g_asn_debug = 'Y') THEN
                   ASN_DEBUG.put_line('invoice_desc = ' || l_invoice_desc);
                END IF;
                BILC_PO_INVOICES_SV2.reset_header_values(
                    l_return_status,
                    l_consumption,
                    i,
                    l_curr);
                IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                END IF;
                IF (g_asn_debug = 'Y') THEN
                   ASN_DEBUG.put_line('Done Initializing Header variables.');
                END IF;
            END IF; -- l_first_flag = FND_API.G_TRUE
            IF (BILC_PO_INVOICES_SV2.need_new_invoice(
                    l_return_status,
                    l_consumption,
                    i,
                    l_curr,
                    l_def_base_currency_code) = FND_API.G_TRUE)
            THEN
                l_progress := '060';
                l_header_idx := l_header_idx + 1;
                IF (g_asn_debug = 'Y') THEN
                   ASN_DEBUG.put_line('Invoice header needs to be created for ' ||
                                       'previous records.');
                END IF;
                IF (g_asn_debug = 'Y') THEN
                   ASN_DEBUG.put_line('# of lines for this invoice = ' ||
                                       l_distr_count);
                END IF;
                /* IF (l_curr.auto_tax_calc_flag <> 'L') THEN
                    IF (g_asn_debug = 'Y') THEN
                       ASN_DEBUG.put_line('Round tax at header level.');
                    END IF;
                    l_curr.tax_amount := AP_UTILITIES_PKG.ap_round_tax(
                                            l_curr.tax_amount,
                                            l_curr.currency_code,
                                            l_curr.tax_rounding_rule,
                                            'Round curr tax amount');
                END IF; -- l_curr.auto_tax_calc_flag <> 'L'
                */
                l_progress := '065';
               l_distr_count := 0;
                IF (g_asn_debug = 'Y') THEN
                    ASN_DEBUG.put_line('Bulk Insert into line interface');
                END IF;
              /*  Bug 3506659 Start.
               *  Moving the procedures create_invoice_distr and store_header_info
               *  out of the IF condn "IF (l_header_idx = p_commit_interval) THEN"
               *  to ensure that the pl/sql tax table is populated with the
               *  distribution(s) corresponding to an invoice, store_header_info
               *  procedure is called immediately to calculate tax for the invoice
               *  and the global variable g_this_invoice_has_tax is reset to FALSE.
               *
               *  If these procedures are there inside the above IF condn then the
               *  global variable g_this_invoice_has_tax will not be reset to FALSE
               *  until the invoice count is equal to the commit interval. Becuase of
               *  this the tax is computed wrongly for one or more invoices. This
               *  problem will be observed with cases like commit interval = 5 and
               *  when Pay on Use prog creates less than 5 invoices when tax is involved.
               *  Bug 3506659 End.
               */
                BILC_PO_INVOICES_SV2.create_invoice_distr(
                     l_return_status,
                     l_consumption,
                     l_commit_lower,
                     l_commit_upper);
                IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                END IF;
                l_commit_lower := l_commit_upper + 1;
                l_progress := '066';
                BILC_PO_INVOICES_SV2.store_header_info(
                    l_return_status,
                    l_curr,
                    l_invoice_desc,
                    l_group_id,
                    l_org_id,
                    l_ap_inv_header,
                    l_header_idx);
                IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                END IF;
                IF (g_asn_debug = 'Y') THEN
                   ASN_DEBUG.put_line('Stored Header Information into table');
                END IF;
                l_invoice_count := l_invoice_count + 1;
                BILC_PO_INVOICES_SV2.reset_header_values(
                    l_return_status,
                    l_consumption,
                    i,
                    l_curr);
                IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                END IF;
                IF (g_asn_debug = 'Y') THEN
                   ASN_DEBUG.put_line('Done Resetting Header Variables');
                   ASN_DEBUG.put_line('# of headers created after last commit= ' ||
                                       l_header_idx || ' Commit interval= ' ||
                                       p_commit_interval);
                END IF;
                IF (l_header_idx = p_commit_interval) THEN
                    -- As we have reached the commit interval, all records
                    -- created so far needs to be inserted and committed.
                    l_progress := '070';
                    IF (g_asn_debug = 'Y') THEN
                       ASN_DEBUG.put_line('Bulk Insert into header interface');
                    END IF;
                    BILC_PO_INVOICES_SV2.create_invoice_hdr(
                        l_return_status,
                        l_ap_inv_header,
                        1,
                        l_header_idx);
                    IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                    END IF;
                    l_header_idx := 0;
                    COMMIT;
                    l_progress := '080';
                    IF (g_asn_debug = 'Y') THEN
                       ASN_DEBUG.put_line('After commit');
                    END IF;
                END IF; -- l_header_idx = p_commit_interval
            END IF; -- BILC_PO_INVOICES_SV2.need_new_invoice
            -- This if is to check the return value of need_new_invoice
            IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
            END IF;
            l_progress := '090';
            IF (g_asn_debug = 'Y') THEN
               ASN_DEBUG.put_line('Deriving more line information');
            END IF;
            l_distr_count := l_distr_count + 1;
            l_consumption.invoice_line_number(i) := l_distr_count;
            l_consumption.invoice_id(i) := l_curr.invoice_id;
            l_consumption.quantity_invoiced(i) :=
                                l_consumption.quantity_ordered(i) -
                                l_consumption.quantity_billed(i);
            IF (g_asn_debug = 'Y') THEN
               ASN_DEBUG.put_line('po_distribution_id = ' ||
                               l_consumption.po_distribution_id(i) ||
                               'Quantity to invoice = ' ||
                               l_consumption.quantity_invoiced(i));
            END IF;
            BILC_PO_INVOICES_SV2.calc_consumption_cost(
                l_return_status,
                l_consumption.quantity_invoiced(i),
                l_consumption.unit_price(i),
                l_consumption.tax_code_id(i),
                l_consumption.tax_rounding_rule(i),
                l_consumption.auto_tax_calc_flag(i),
                l_consumption.currency_code(i),
                l_consumption.invoice_line_amount(i),
                l_curr.invoice_amount,
                l_curr.tax_amount);
            IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
            END IF;
            IF (g_asn_debug = 'Y') THEN
               ASN_DEBUG.put_line('line_amount = ' ||
                                   l_consumption.invoice_line_amount(i));
               ASN_DEBUG.put_line('Cumu. tax Amount = ' || l_curr.tax_amount);
               ASN_DEBUG.put_line('Cumu. Invoive amt = '||l_curr.invoice_amount);
            END IF;
            l_commit_upper := l_commit_upper + 1;
-- bug2786193
-- We now use sysdate as the invoice date so no need to update
-- it everytime
            -- l_curr.invoice_date := l_consumption.creation_date(i);
            IF (g_asn_debug = 'Y') THEN
               ASN_DEBUG.put_line('-*-*-*-*-*- Done with one line -*-*-*-*-*-');
            END IF;
        END LOOP; -- for i in 1.. po_header_id.count
        l_progress := '100';
        IF (g_asn_debug = 'Y') THEN
           ASN_DEBUG.put_line('Exit inner loop');
        END IF;
        IF (g_asn_debug = 'Y') THEN
           ASN_DEBUG.put_line('Insert remaining distributions from pl/sql table'
                               || ' to lines interface table');
        END IF;
        BILC_PO_INVOICES_SV2.create_invoice_distr(
            l_return_status,
            l_consumption,
            l_commit_lower,
            l_commit_upper);
        IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
            RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;
        EXIT WHEN c_consumption%NOTFOUND;
    END LOOP; -- loop for bulk fetching consumption advice
    l_progress := '110';
    IF (g_asn_debug = 'Y') THEN
       ASN_DEBUG.put_line('Exit outer loop');
    END IF;
    IF c_consumption%ISOPEN THEN
        CLOSE c_consumption;
    END IF;
    IF (l_distr_count > 0) THEN
        IF (g_asn_debug = 'Y') THEN
           ASN_DEBUG.put_line('l_distr_count = ' || l_distr_count || '. Need to' ||
                               ' perform some clean up work.');
        END IF;
        l_header_idx := l_header_idx + 1;
        IF (g_asn_debug = 'Y') THEN
           ASN_DEBUG.put_line('# of headers created after last commit= ' ||
                                       l_header_idx);
        END IF;
        /* IF (l_curr.auto_tax_calc_flag <> 'L') THEN
            IF (g_asn_debug = 'Y') THEN
               ASN_DEBUG.put_line('Round tax at header level.');
            END IF;
            l_curr.tax_amount := AP_UTILITIES_PKG.ap_round_tax(
                                            l_curr.tax_amount,
                                            l_curr.currency_code,
                                            l_curr.tax_rounding_rule,
                                            'Round curr tax amount');
        END IF; -- l_curr.auto_tax_calc_flag <> 'L'
        */
        BILC_PO_INVOICES_SV2.store_header_info(
            l_return_status,
            l_curr,
            l_invoice_desc,
            l_group_id,
            l_org_id,
            l_ap_inv_header,
            l_header_idx);
        IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
            RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;
        l_progress := '120';
        IF (g_asn_debug = 'Y') THEN
           ASN_DEBUG.put_line('Insert remaining invoice headers');
        END IF;
        BILC_PO_INVOICES_SV2.create_invoice_hdr(
            l_return_status,
            l_ap_inv_header,
            1,
            l_header_idx);
        IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
            RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;
        COMMIT;
        l_progress := '130';
        IF (g_asn_debug = 'Y') THEN
           ASN_DEBUG.put_line('Call invoice import program');
        END IF;
        SELECT ap_batches_s.nextval
        INTO   l_tmp_batch_id
        FROM   sys.dual;
        FND_MESSAGE.set_name('PO', 'PO_INV_CR_USE_BATCH_DESC');
        l_batch_name := FND_MESSAGE.get || '/' || TO_CHAR(sysdate) ||
                        '/' || TO_CHAR(l_tmp_batch_id);
        IF (g_asn_debug = 'Y') THEN
           ASN_DEBUG.put_line('Batch name = ' || l_batch_name);
        END IF;
        l_user_id := NULL;
        l_login_id := NULL;
        bilc_PO_INVOICES_SV1.submit_invoice_import(
            l_return_status,
            'USE',
            l_group_id,
            l_batch_name,
            l_user_id,
            l_login_id,
            l_request_id);
        IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
             RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;
        l_progress := '140';
        FND_MESSAGE.set_name('PO', 'PO_ERS_CONC_REQUEST_CHECK');
 FND_MESSAGE.set_token('REQUEST', TO_CHAR(l_request_id));
 FND_MESSAGE.set_token('BATCH', l_batch_name);
   IF (g_asn_debug = 'Y') THEN
      ASN_DEBUG.put_line(FND_MESSAGE.get);
   END IF;
    END IF; -- l_distr_count > 0
    IF (g_asn_debug = 'Y') THEN
       ASN_DEBUG.put_line('Exit create_use_invoices');
    END IF;
EXCEPTION
    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
        x_return_status :=  FND_API.G_RET_STS_UNEXP_ERROR;
        l_error_msg := FND_MSG_PUB.get(p_encoded => 'F');
        IF (g_asn_debug = 'Y') THEN
           ASN_DEBUG.put_line(l_api_name || '-' || l_progress);
           ASN_DEBUG.put_line(l_error_msg);
        END IF;
        IF c_consumption%ISOPEN THEN
            CLOSE c_consumption;
        END IF;
        ROLLBACK;
        bilc_PO_INVOICES_SV1.delete_interface_records(
            l_return_status,
            l_group_id);
        COMMIT;
    WHEN OTHERS THEN
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        FND_MSG_PUB.add_exc_msg(g_pkg_name, l_api_name);
        l_error_msg := FND_MSG_PUB.get(p_encoded => 'F');
        IF (g_asn_debug = 'Y') THEN
           ASN_DEBUG.put_line(l_api_name || '-' || l_progress);
           ASN_DEBUG.put_line(l_error_msg);
        END IF;
        IF c_consumption%ISOPEN THEN
            CLOSE c_consumption;
        END IF;
        ROLLBACK;
        BILC_PO_INVOICES_SV1.delete_interface_records(
            l_return_status,
            l_group_id);
        COMMIT;
END create_use_invoices;
/*******************************************************
 * FUNCTION need_new_invoice
 *******************************************************/
FUNCTION need_new_invoice (
    x_return_status         OUT NOCOPY VARCHAR2,
    p_consumption           IN BILC_PO_INVOICES_SV2.consump_rec_type,
    p_index                 IN NUMBER,
    p_curr                  IN BILC_PO_INVOICES_SV2.curr_condition_rec_type,
    p_base_currency_code    IN VARCHAR2) RETURN VARCHAR2
IS
    l_api_name VARCHAR2(50) := 'need_new_invoice';
BEGIN
    x_return_status := FND_API.G_RET_STS_SUCCESS;
-- bug2786193
-- Use p_curr structure to reduce number of parameters passed
    IF (p_curr.vendor_id <> p_consumption.vendor_id(p_index)
       OR
        p_curr.pay_site_id <> p_consumption.default_pay_site_id(p_index)
       OR
        p_curr.inv_summary_code <>
            p_consumption.pay_on_receipt_summary_code(p_index)
       OR
        p_curr.currency_code <> p_consumption.currency_code(p_index)
       OR
-- bug2786193
-- to group two lines under same invoice header, rate date and rate type
-- has to match if we are talking about foreign currencies
        (p_consumption.currency_code(p_index) <> p_base_currency_code AND
         (TRUNC(p_curr.conversion_date) <>
             TRUNC(p_consumption.currency_conversion_date(p_index)) OR
          p_curr.conversion_type <>
             p_consumption.currency_conversion_type(p_index)))
       OR
-- bug2786193
-- if currency type is user, make sure that we do not group invoice lines
-- together if they are using different conversion rate
        (p_consumption.currency_conversion_type(p_index) = 'User' AND
         NVL(p_curr.conversion_rate, -1) <>
            p_consumption.currency_conversion_rate(p_index))
       OR
        p_curr.payment_terms_id <> p_consumption.payment_terms_id(p_index)
       OR
        ((p_curr.po_header_id <> p_consumption.po_header_id(p_index) OR
          NVL(p_curr.po_release_id, -1) <>
            NVL(p_consumption.po_release_id(p_index), -1)) AND
          p_consumption.pay_on_receipt_summary_code(p_index) =
            'CONSUMPTION_ADVICE')
       ) THEN
        RETURN FND_API.G_TRUE;
    END IF;
    RETURN FND_API.G_FALSE;
EXCEPTION
    WHEN OTHERS THEN
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        FND_MSG_PUB.add_exc_msg(g_pkg_name, l_api_name);
        RETURN FND_API.G_FALSE;
END need_new_invoice;
/*******************************************************
 * PROCEDURE store_header_info
 *******************************************************/
PROCEDURE store_header_info(
    x_return_status     OUT NOCOPY VARCHAR2,
    p_curr              IN  BILC_PO_INVOICES_SV2.curr_condition_rec_type,
    p_invoice_desc      IN  VARCHAR2,
    p_group_id          IN  VARCHAR2,
    p_org_id            IN  VARCHAR2,
    x_ap_inv_header     IN OUT NOCOPY BILC_PO_INVOICES_SV2.invoice_header_rec_type,
    p_index             IN  NUMBER)
IS
    l_api_name VARCHAR2(50) := 'store_header_info';
    x_cnt number;
    x_tax_amount number;
BEGIN
    x_return_status := FND_API.G_RET_STS_SUCCESS;
    IF (g_asn_debug = 'Y') THEN
       ASN_DEBUG.put_line('Storing header data into PL/SQL tables');
    END IF;
/* Bug 3506659
    Call the Tax engine by passing the input Plsql table that has the tax information
    populated in it, get the recoverable and non recoverable tax amounts via the output
    plsql tables x_recov_tax_tbl and x_nonrecov_tax_tbl respectively, sum them and add
    the resultant value to the invoice amount.
 */
 /* Bug 3506659 Start */
    x_tax_amount  := 0;
    IF (g_this_invoice_has_tax) THEN
        IF (g_asn_debug = 'Y') THEN
            asn_debug.put_line('Calling Tax API  for Invoice id ' || to_char(p_curr.invoice_id));
        END IF;
        /* Bug 4112614: Flushing recoverable and non recoverable tax pl/sql tables */
        x_recov_tax_tbl.delete;
        x_nonrecov_tax_tbl.delete;
 AP_POR_TAX_PKG.calculate_tax(p_tax_info_tbl,
                                     x_recov_tax_tbl,
                                     x_nonrecov_tax_tbl);
 IF (g_asn_debug = 'Y') THEN
     asn_debug.put_line('After Tax API call - the return count is ' || to_char(x_recov_tax_tbl.count));
 END IF;
 x_cnt := 1;
 x_tax_amount := 0;
 loop
       exit when (x_recov_tax_tbl.count = 0);
       x_tax_amount := x_tax_amount + (nvl(x_recov_tax_tbl(x_cnt),0) + nvl(x_nonrecov_tax_tbl(x_cnt),0));
       IF (g_asn_debug = 'Y') THEN
           asn_debug.put_line('Tax Amount for this line is ' || to_char(x_tax_amount));
       END IF;
       x_cnt := x_cnt + 1;
       exit when (x_cnt > x_recov_tax_tbl.count);
 end loop;
 IF (g_asn_debug = 'Y') THEN
     asn_debug.put_line('Total Tax Amount is ' || to_char(x_tax_amount));
 END IF;
    END IF;  /* End of g_this_invoice_has_tax */
  /* Reset the invoice distribution count to zero before processing the next invoice */
     g_this_invoice_dist_cnt := 0;
     g_this_invoice_has_tax := FALSE;
     g_inv_line_id := 0;
     p_tax_info_tbl.delete;  --bug 4112614 to flush the input tax records pl/sql table
  /* Bug 3506659 End */
    x_ap_inv_header.invoice_num(p_index) :=
                                BILC_PO_INVOICES_SV2.create_invoice_num(
                                    p_org_id, -- SBI ENH
                                    p_curr.pay_site_id, -- SBI ENH
                                    p_curr.inv_summary_code,
                                    p_curr.invoice_date,
                                    NULL,
                                    NULL,
                                    'USE');
    x_ap_inv_header.invoice_id(p_index) := p_curr.invoice_id;
    x_ap_inv_header.vendor_id(p_index) := p_curr.vendor_id;
    x_ap_inv_header.vendor_site_id(p_index) := p_curr.pay_site_id;
    x_ap_inv_header.invoice_amount(p_index) :=
                        p_curr.invoice_amount + x_tax_amount; --bug 3506659
    x_ap_inv_header.invoice_currency_code(p_index) := p_curr.currency_code;
    x_ap_inv_header.invoice_date(p_index) := p_curr.invoice_date;
    x_ap_inv_header.source(p_index) := 'USE';
    x_ap_inv_header.description(p_index) := p_invoice_desc;
    x_ap_inv_header.creation_date(p_index) := sysdate;
    x_ap_inv_header.exchange_rate(p_index) := p_curr.conversion_rate;
    x_ap_inv_header.exchange_rate_type(p_index) := p_curr.conversion_type;
    x_ap_inv_header.exchange_date(p_index) := p_curr.conversion_date;
    x_ap_inv_header.payment_currency_code(p_index) := p_curr.pay_curr_code;
    x_ap_inv_header.terms_id(p_index) := p_curr.payment_terms_id;
    x_ap_inv_header.group_id(p_index) := p_group_id;
    x_ap_inv_header.org_id(p_index) := p_org_id;
    IF (g_asn_debug = 'Y') THEN
       ASN_DEBUG.put_line('Invoice id = ' || x_ap_inv_header.invoice_id(p_index));
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        FND_MSG_PUB.add_exc_msg(g_pkg_name, l_api_name);
END store_header_info;
/*******************************************************
 * PROCEDURE reset_header_values
 *******************************************************/
PROCEDURE reset_header_values (
    x_return_status         OUT NOCOPY VARCHAR2,
    p_next_consump          IN BILC_PO_INVOICES_SV2.consump_rec_type,
    p_index                 IN NUMBER,
    x_curr                  OUT NOCOPY BILC_PO_INVOICES_SV2.curr_condition_rec_type)
IS
    l_api_name VARCHAR2(50) := 'reset_header_values';
BEGIN
    x_return_status := FND_API.G_RET_STS_SUCCESS;
-- bug2786193
-- pass in currency_conversion_date instead of creation_date
    IF (GL_CURRENCY_API.is_fixed_rate(
                p_next_consump.payment_currency_code(p_index),
                p_next_consump.currency_code(p_index),
                p_next_consump.currency_conversion_date(p_index)) = 'Y') THEN
        x_curr.pay_curr_code := p_next_consump.payment_currency_code(p_index);
    ELSE
        x_curr.pay_curr_code := p_next_consump.currency_code(p_index);
    END IF; -- GL_CURRENCY_API.is_fixed_rate(...)
    x_curr.invoice_amount := 0;
    x_curr.tax_amount := 0;
    SELECT AP_INVOICES_INTERFACE_S.NEXTVAL
    INTO   x_curr.invoice_id
    FROM   SYS.DUAL;
    x_curr.vendor_id := p_next_consump.vendor_id(p_index);
    x_curr.pay_site_id := p_next_consump.default_pay_site_id(p_index);
    x_curr.inv_summary_code :=
                        p_next_consump.pay_on_receipt_summary_code(p_index);
    x_curr.po_header_id := p_next_consump.po_header_id(p_index);
    x_curr.po_release_id := p_next_consump.po_release_id(p_index);
    x_curr.currency_code := p_next_consump.currency_code(p_index);
    x_curr.conversion_type := p_next_consump.currency_conversion_type(p_index);
    x_curr.conversion_date := p_next_consump.currency_conversion_date(p_index);
    x_curr.payment_terms_id := p_next_consump.payment_terms_id(p_index);
    x_curr.creation_date := p_next_consump.creation_date(p_index);
    x_curr.auto_tax_calc_flag := p_next_consump.auto_tax_calc_flag(p_index);
    x_curr.tax_rounding_rule := p_next_consump.tax_rounding_rule(p_index);
-- bug2786193
-- use sysdate as invoice_date
    x_curr.invoice_date := sysdate;
    IF (p_next_consump.currency_conversion_type(p_index) <> 'User') THEN
        x_curr.conversion_rate := NULL;
-- bug2786193
--        x_curr.conversion_date := x_curr.creation_date;
    ELSE
        x_curr.conversion_rate :=
                p_next_consump.currency_conversion_rate(p_index);
-- bug2786193
--        x_curr.conversion_date :=
--                p_next_consump.currency_conversion_date(p_index);
    END IF;  -- p_next_consump.currency_conversion_type(p_index) <> 'User'
EXCEPTION
    WHEN OTHERS THEN
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        FND_MSG_PUB.add_exc_msg(g_pkg_name, l_api_name);
END reset_header_values;
/*******************************************************
 * PROCEDURE calc_consumption_cost
 *******************************************************/
PROCEDURE calc_consumption_cost (
    x_return_status         OUT NOCOPY VARCHAR2,
    p_quantity              IN  NUMBER,
    p_unit_price            IN  NUMBER,
    p_tax_code_id           IN  NUMBER,
    p_tax_rounding_rule     IN  VARCHAR2,
    p_auto_tax_calc_flag    IN  VARCHAR2,
    p_invoice_currency_code IN  VARCHAR2,
    x_invoice_line_amount   OUT NOCOPY NUMBER,
    x_curr_invoice_amount   IN OUT NOCOPY NUMBER,
    x_curr_tax_amount       IN OUT NOCOPY NUMBER)
IS
    --l_tax_rate  NUMBER;
    --l_line_tax_amount NUMBER;
    l_api_name VARCHAR2(50) := 'calc_consumption_cost';
BEGIN
    x_return_status := FND_API.G_RET_STS_SUCCESS;
    /* if  tax_code_id is cached in g_old_tax_code_id, use g_old_tax_rate as
     * the tax rate. if tax_code_id is NULL, use 0 as tax_rate. If tax_code_id
     * is not cached, run a query to get the tax rate, and cache both
     * tax_code_id and tax_rate */
    /* Bug 3506659
     Commenting this part of the tax computation as separate logic exists now
     This logic does not take care of tax groups and others. Now tax engine
     is called and tax is calculated.
   */
    /* IF (p_tax_code_id IS NULL) THEN
        l_tax_rate := 0;
    ELSIF (p_tax_code_id = g_old_tax_code_id) THEN
        l_tax_rate := g_old_tax_rate;
    ELSE
        SELECT  tax_rate
        INTO    l_tax_rate
        FROM    ap_tax_codes atc
        WHERE   tax_id = p_tax_code_id;
        g_old_tax_code_id := p_tax_code_id;
        g_old_tax_rate := l_tax_rate;
    END IF; -- p_tax_code is null
    IF (g_asn_debug = 'Y') THEN
       ASN_DEBUG.put_line('Tax Rate = ' || l_tax_rate || '%');
    END IF;
    */
    x_invoice_line_amount := AP_UTILITIES_PKG.ap_round_currency(
                                p_quantity * p_unit_price,
                                p_invoice_currency_code);
    /* Bug 3506659 Start
    IF (g_asn_debug = 'Y') THEN
       ASN_DEBUG.put_line('line amount = ' || x_invoice_line_amount);
    END IF;
    l_line_tax_amount :=  p_quantity*p_unit_price*l_tax_rate/100;
    IF (g_asn_debug = 'Y') THEN
       ASN_DEBUG.put_line('TAX CALC LEVEL = ' || p_auto_tax_calc_flag);
    END IF;
    IF (p_auto_tax_calc_flag = 'L') THEN
        x_curr_tax_amount := x_curr_tax_amount +
                             AP_UTILITIES_PKG.ap_round_tax(
                                l_line_tax_amount,
                                p_invoice_currency_code,
                                p_tax_rounding_rule,
                                'ROUND TAX AMOUNT');
    ELSE
        x_curr_tax_amount := x_curr_tax_amount + l_line_tax_amount;
    END IF; -- p_auto_tax_calc_flag = 'L'
    Bug 3506659 End
    */
    x_curr_invoice_amount := x_curr_invoice_amount + x_invoice_line_amount;
EXCEPTION
    WHEN OTHERS THEN
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        FND_MSG_PUB.add_exc_msg(g_pkg_name, l_api_name);
END calc_consumption_cost;
/*******************************************************
 * PROCEDURE create_invoice_hdr
 *******************************************************/
PROCEDURE create_invoice_hdr(
    x_return_status OUT NOCOPY VARCHAR2,
    p_ap_inv_header IN BILC_PO_INVOICES_SV2.invoice_header_rec_type,
    p_from          IN NUMBER,
    p_to            IN NUMBER)
IS
    l_api_name VARCHAR2(50) := 'create_invoice_hdr';
BEGIN
    SAVEPOINT create_invoice_hdr_sp;
    x_return_status := FND_API.G_RET_STS_SUCCESS;
    FORALL i IN p_from..p_to
        INSERT INTO ap_invoices_interface(
            invoice_id,
            invoice_num,
            vendor_id,
            vendor_site_id,
            invoice_amount,
            invoice_currency_code,
            invoice_date,
            source,
            description,
            creation_date,
            exchange_rate,
            exchange_rate_type,
            exchange_date,
            payment_currency_code,
            terms_id,
            group_id,
            org_id)
        SELECT
            p_ap_inv_header.invoice_id(i),
            p_ap_inv_header.invoice_num(i),
            p_ap_inv_header.vendor_id(i),
            p_ap_inv_header.vendor_site_id(i),
            p_ap_inv_header.invoice_amount(i),
            p_ap_inv_header.invoice_currency_code(i),
            p_ap_inv_header.invoice_date(i),
            p_ap_inv_header.source(i),
            p_ap_inv_header.description(i),
            p_ap_inv_header.creation_date(i),
            p_ap_inv_header.exchange_rate(i),
            p_ap_inv_header.exchange_rate_type(i),
            p_ap_inv_header.exchange_date(i),
            p_ap_inv_header.payment_currency_code(i),
            p_ap_inv_header.terms_id(i),
            p_ap_inv_header.group_id(i),
            p_ap_inv_header.org_id(i)
        FROM
            sys.dual;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO create_invoice_hdr_sp;
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        FND_MSG_PUB.add_exc_msg(g_pkg_name, l_api_name);
END create_invoice_hdr;
/*******************************************************
 * PROCEDURE create_invoice_distr
 *******************************************************/
PROCEDURE create_invoice_distr(
    x_return_status OUT NOCOPY VARCHAR2,
    p_consumption   IN BILC_PO_INVOICES_SV2.consump_rec_type,
    p_from          IN NUMBER,
    p_to            IN NUMBER)
IS
    l_api_name VARCHAR2(50) := 'create_invoice_distr';
    x_tax_rate                      AP_TAX_CODES.tax_rate%TYPE;
    x_set_of_books_id               PO_DISTRIBUTIONS.set_of_books_id%TYPE;
    x_code_combination_id           PO_DISTRIBUTIONS.code_combination_id%TYPE;
    x_tax_recovery_override_flag    PO_DISTRIBUTIONS.tax_recovery_override_flag%TYPE;
    x_recovery_rate                 PO_DISTRIBUTIONS.recovery_rate%TYPE;
    x_invoice_line_id               AP_INVOICE_LINES_INTERFACE.invoice_line_id%TYPE;
    x_invoice_date                  date := sysdate;
    x_tax_code_tbl  tax_code_id_tbl_type;  /* bug 3506659 */
    x_tax_code_rec  BILC_PO_INVOICES_SV2.consump_rec_type := p_consumption;  /* bug 3506659 */
BEGIN
    SAVEPOINT create_invoice_distr_sp;
    IF (g_asn_debug = 'Y') THEN
       ASN_DEBUG.put_line('Inside Create Invoice Distributions');
    END IF;
   /* Bug 3506659.
      Tax will be calculated only if tax calculation level in vendor site is
      Line or Tax Code.
      Get the valid tax id using AP_TAX_VALIDATE_PKG.get_valid_tax_id() if there
      is any tax rate change for the tax code that is used.
      Populate the Plsql table with the tax information for each distribution.
   */
   /* Bug 3506659 Start */
    FOR i in p_from..p_to LOOP
      x_tax_code_tbl(i) := null;
      IF (g_asn_debug = 'Y') THEN
          ASN_DEBUG.put_line('Counter is ' || to_char(i) ||', Calculate tax flag is ' || p_consumption.auto_tax_calc_flag(i)
                              || ', Tax Code Id = ' || p_consumption.tax_code_id(i));
      END IF;
      IF (p_consumption.auto_tax_calc_flag(i) in ('L','T') AND p_consumption.tax_code_id(i) is not null) THEN
        g_this_invoice_has_tax := TRUE;
        IF (g_asn_debug = 'Y') THEN
            ASN_DEBUG.put_line('Old Tax Code id = '|| g_old_tax_code_id);
            ASN_DEBUG.put_line('New Tax Code Id is ' || p_consumption.tax_code_id(i));
        END IF;
        select set_of_books_id,
               accrual_account_id,
               tax_recovery_override_flag,
               recovery_rate
          into x_set_of_books_id,
               x_code_combination_id,
               x_tax_recovery_override_flag,
               x_recovery_rate
          from po_distributions
         where po_distribution_id = p_consumption.po_distribution_id(i);
        IF (p_consumption.tax_code_id(i) <> nvl(g_old_tax_code_id,-99)) THEN
              IF (g_asn_debug = 'Y') THEN
                  ASN_DEBUG.put_line('Check if new tax rate is used for tax code, if so get new the tax_code_id');
              END IF;
              g_old_tax_code_id := AP_TAX_VALIDATE_PKG.get_valid_tax_id(p_consumption.tax_code_id(i),x_invoice_date);
              select tax_rate
              into x_tax_rate
              from ap_tax_codes_all
              where tax_id = g_old_tax_code_id;
              x_tax_code_tbl(i) := g_old_tax_code_id;
              g_old_tax_rate := x_tax_rate;
        ELSE
              x_tax_code_tbl(i) := g_old_tax_code_id;
              x_tax_rate := g_old_tax_rate;
        END IF;
        g_inv_line_id := g_inv_line_id + 1;
        IF (g_asn_debug = 'Y') THEN
            ASN_DEBUG.put_line('Before populating the input Tax PL/Sql table');
        END IF;
        l_ap_tax_record  :=  AP_POR_TAX_INFO_OBJECT_TYPE(
                               null,null,null,null,null,null,null,null,
                               null,null,null,null,null,null,null,null,
                               null,null,null,null,null,null,null,null,
                               null,null,null,null,null);
        l_ap_tax_record.set_of_books_id             :=  x_set_of_books_id;
        l_ap_tax_record.trx_shipment_id             :=  p_consumption.invoice_id(i);
        l_ap_tax_record.trx_distribution_id         :=  g_inv_line_id;
        l_ap_tax_record.trx_line_type               :=  'ITEM';
        l_ap_tax_record.inventory_item_id           :=  NULL;
        l_ap_tax_record.quantity                    :=  p_consumption.quantity_invoiced(i);
        l_ap_tax_record.quantity_ordered            :=  NULL;
        l_ap_tax_record.unit_price                  :=  p_consumption.unit_price(i) * p_consumption.quantity_invoiced(i);
        l_ap_tax_record.currency_unit_price         :=  NULL;
        l_ap_tax_record.ussgl_transaction_code      :=  NULL;
        l_ap_tax_record.ship_to_location_id         :=  NULL;
        l_ap_tax_record.tax_code_id                 :=  g_old_tax_code_id;
        l_ap_tax_record.tax_user_override_flag      :=  'Y';
        l_ap_tax_record.tax_rate                    :=  x_tax_rate;
        l_ap_tax_record.tax_recovery_rate           :=  x_recovery_rate;
        l_ap_tax_record.project_id                  :=  NULL;
        l_ap_tax_record.task_id                     :=  NULL;
        l_ap_tax_record.award_id                    :=  NULL;
        l_ap_tax_record.expenditure_type            :=  NULL;
        l_ap_tax_record.expenditure_organization_id :=  NULL;
        l_ap_tax_record.expenditure_item_date_str   :=  NULL;
        l_ap_tax_record.date_format_str             :=  NULL;
        l_ap_tax_record.application_short_name      :=  'SQLAP';
        l_ap_tax_record.code_combination_id         :=  x_code_combination_id;
        l_ap_tax_record.tax_recovery_override_flag  :=  x_tax_recovery_override_flag;
        l_ap_tax_record.trx_currency_code           :=  p_consumption.currency_code(i);
        l_ap_tax_record.exchange_rate               :=  p_consumption.currency_conversion_rate(i);
        l_ap_tax_record.ship_from_supplier_id       :=  p_consumption.vendor_id(i);
        l_ap_tax_record.ship_from_site_use_id       :=  p_consumption.default_pay_site_id(i);
        p_tax_info_tbl.extend;
        g_this_invoice_dist_cnt := g_this_invoice_dist_cnt + 1;
        p_tax_info_tbl(g_this_invoice_dist_cnt) := l_ap_tax_record;
        IF (g_asn_debug = 'Y') THEN
            ASN_DEBUG.put_line('After populating the Tax PL/Sql table');
        END IF;
      END IF;  /* End of p_consumption.auto_tax_calc_flag in ('L','T') */
    END LOOP;
   x_tax_code_rec.tax_code_id :=  x_tax_code_tbl;
   /* Bug 3506659 End */
    x_return_status := FND_API.G_RET_STS_SUCCESS;
    FORALL i IN p_from..p_to
        INSERT INTO ap_invoice_lines_interface(
            invoice_id,
            invoice_line_id,
            line_number,
            line_type_lookup_code,
            amount,
            accounting_date,
            description,
            tax_code_Id,
            amount_includes_tax_flag,
            --dist_code_combination_id,
            po_header_id,
            po_line_id,
            po_line_location_id,
            po_distribution_id,
            po_release_id,
            quantity_invoiced,
            expenditure_item_date,
            expenditure_type,
            expenditure_organization_id,
            project_accounting_context,
            pa_quantity,
            pa_addition_flag,
            unit_price,
            assets_tracking_flag,
            attribute_category,
            attribute1,
            attribute2,
            attribute3,
            attribute4,
            attribute5,
            attribute6,
            attribute7,
            attribute8,
            attribute9,
            attribute10,
            attribute11,
            attribute12,
            attribute13,
            attribute14,
            attribute15,
            match_option,
            tax_code_override_flag,
            org_id)
        SELECT
            p_consumption.invoice_id(i),
            ap_invoice_lines_interface_s.nextval,
            p_consumption.invoice_line_number(i),
            'ITEM',
            p_consumption.invoice_line_amount(i),
            -- p_consumption.creation_date(i),  -- bug2786193: use sysdate
            sysdate,
            p_consumption.item_description(i),
            x_tax_code_rec.tax_code_id(i),  /* bug 3506659 */
            NULL,
            --pod.code_combination_id,
            p_consumption.po_header_id(i),
            p_consumption.po_line_id(i),
            p_consumption.line_location_id(i),
            p_consumption.po_distribution_id(i),
            p_consumption.po_release_id(i),
            p_consumption.quantity_invoiced(i),
            pod.expenditure_item_date,
            pod.expenditure_type,
            pod.expenditure_organization_id,
            pod.project_accounting_context,
            p_consumption.quantity_invoiced(i),
            'N',
            p_consumption.unit_price(i),
            DECODE(gcc.account_type, 'A','Y','N'),
            pod.attribute_category,
            pod.attribute1,
            pod.attribute2,
            pod.attribute3,
            pod.attribute4,
            pod.attribute5,
            pod.attribute6,
            pod.attribute7,
            pod.attribute8,
            pod.attribute9,
            pod.attribute10,
            pod.attribute11,
            pod.attribute12,
            pod.attribute13,
            pod.attribute14,
            pod.attribute15,
            'P',    -- match option
            'Y',
            p_consumption.org_id(i)
        FROM
              po_distributions pod,
              gl_code_combinations gcc
        WHERE
              pod.po_distribution_id = p_consumption.po_distribution_id(i)
        AND   pod.code_combination_id = gcc.code_combination_id;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO create_invoice_distr_sp;
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        FND_MSG_PUB.add_exc_msg(g_pkg_name, l_api_name);
END create_invoice_distr;
/* <PAY ON USE FPI END> */
END BILC_PO_INVOICES_SV2;
/