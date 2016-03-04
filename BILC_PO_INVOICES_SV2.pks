CREATE OR REPLACE PACKAGE APPS.BILC_PO_INVOICES_SV2 AUTHID CURRENT_USER AS
/* $Header: POXIVRPS.pls 115.16.11510.4 2006/09/25 05:49:00 szaveri ship $ */
/* <PAY ON USE FPI START> */
/* Define structure for bulk processing */
TYPE po_header_id_tbl_type IS TABLE OF
     po_headers.po_header_id%TYPE INDEX BY BINARY_INTEGER;
TYPE po_release_id_tbl_type IS TABLE OF
     po_releases.po_release_id%TYPE INDEX BY BINARY_INTEGER;
TYPE po_line_id_tbl_type IS TABLE OF
     po_lines.po_line_id%TYPE INDEX BY BINARY_INTEGER;
TYPE line_location_id_tbl_type IS TABLE OF
     po_line_locations.line_location_id%TYPE INDEX BY BINARY_INTEGER;
TYPE po_distribution_id_tbl_type IS TABLE OF
     po_distributions.po_distribution_id%TYPE INDEX BY BINARY_INTEGER;
TYPE vendor_id_tbl_type IS TABLE OF
     po_vendors.vendor_id%TYPE INDEX BY BINARY_INTEGER;
TYPE pay_on_rec_sum_code_tbl_type IS TABLE OF
     po_vendor_sites.pay_on_receipt_summary_code%TYPE INDEX BY BINARY_INTEGER;
TYPE vendor_site_id_tbl_type IS TABLE OF
     po_vendor_sites.vendor_site_id%TYPE INDEX BY BINARY_INTEGER;
TYPE item_description_tbl_type IS TABLE OF
     PO_LINES.item_description%TYPE INDEX BY BINARY_INTEGER;
TYPE price_override_tbl_type IS TABLE OF
     po_line_locations.price_override%TYPE INDEX BY BINARY_INTEGER;
TYPE quantity_tbl_type IS TABLE OF
     po_distributions.quantity_ordered%TYPE INDEX BY BINARY_INTEGER;
TYPE currency_code_tbl_type IS TABLE OF
     po_headers.currency_code%TYPE INDEX BY BINARY_INTEGER;
TYPE currency_conv_type_tbl_type IS TABLE OF
     po_headers.rate_type%TYPE INDEX BY BINARY_INTEGER;
TYPE currency_conv_rate_tbl_type IS TABLE OF
     po_headers.rate%TYPE INDEX BY BINARY_INTEGER;
TYPE date_tbl_type IS TABLE OF
     DATE INDEX BY BINARY_INTEGER;
TYPE payment_terms_id_tbl_type IS TABLE OF
     po_headers.terms_id%TYPE INDEX BY BINARY_INTEGER;
TYPE tax_code_id_tbl_type IS TABLE OF
     po_line_locations.tax_code_id%TYPE INDEX BY BINARY_INTEGER;
TYPE tax_rounding_rule_tbl_type IS TABLE OF
     po_vendor_sites.ap_tax_rounding_rule%TYPE INDEX BY BINARY_INTEGER;
TYPE auto_tax_calc_flag_tbl_type IS TABLE OF
     po_vendor_sites.auto_tax_calc_flag%TYPE INDEX BY BINARY_INTEGER;
TYPE invoice_amount_tbl_type IS TABLE OF
     ap_invoices_interface.invoice_amount%TYPE INDEX BY BINARY_INTEGER;
TYPE org_id_tbl_type IS TABLE OF
     po_headers.org_id%TYPE INDEX BY BINARY_INTEGER;
TYPE invoice_line_num_tbl_type IS TABLE OF
     ap_invoice_lines_interface.line_number%TYPE INDEX BY BINARY_INTEGER;
TYPE invoice_id_tbl_type IS TABLE OF
     ap_invoices_interface.invoice_id%TYPE INDEX BY BINARY_INTEGER;
TYPE invoice_num_tbl_type IS TABLE OF
     ap_invoices_interface.invoice_num%TYPE INDEX BY BINARY_INTEGER;
TYPE source_tbl_type IS TABLE OF
     ap_invoices_interface.source%TYPE INDEX BY BINARY_INTEGER;
TYPE description_tbl_type IS TABLE OF
     ap_invoices_interface.description%TYPE INDEX BY BINARY_INTEGER;
TYPE pay_curr_code_tbl_type IS TABLE OF
     po_vendor_sites.payment_currency_code%TYPE INDEX BY BINARY_INTEGER;
TYPE terms_id_tbl_type IS TABLE OF
     ap_invoices_interface.terms_id%TYPE INDEX BY BINARY_INTEGER;
TYPE group_id_tbl_type IS TABLE OF
     ap_invoices_interface.group_id%TYPE INDEX BY BINARY_INTEGER;
TYPE consump_rec_type IS RECORD (
    po_header_id                     po_header_id_tbl_type,
    po_release_id                   po_release_id_tbl_type,
    po_Line_id                      po_line_id_tbl_type,
    line_location_id                line_location_id_tbl_type,
    po_distribution_id              po_distribution_id_tbl_type,
    vendor_id                       vendor_id_tbl_type,
    pay_on_receipt_summary_code     pay_on_rec_sum_code_tbl_type,
    vendor_site_id                  vendor_site_id_tbl_type,
    default_pay_site_id             vendor_site_id_tbl_type,
    item_description                item_description_tbl_type,
    unit_price                      price_override_tbl_type,
    quantity_ordered                quantity_tbl_type,
    quantity_billed                 quantity_tbl_type,
    currency_code                   currency_code_tbl_type,
    currency_conversion_type        currency_conv_type_tbl_type,
    currency_conversion_rate        currency_conv_rate_tbl_type,
    currency_conversion_date        date_tbl_type,
    payment_currency_code           pay_curr_code_tbl_type,
    payment_terms_id                payment_terms_id_tbl_type,
    tax_code_id                     tax_code_id_tbl_type,
    tax_rounding_rule               tax_rounding_rule_tbl_type,
    auto_tax_calc_flag              auto_tax_calc_flag_tbl_type,
    invoice_line_amount             invoice_amount_tbl_type,
    creation_date                   date_tbl_type,
    org_id                          org_id_tbl_type,
    invoice_id                      invoice_id_tbl_type,
    invoice_line_number             invoice_line_num_tbl_type,
    quantity_invoiced               quantity_tbl_type);
TYPE invoice_header_rec_type IS RECORD (
    invoice_id                      invoice_id_tbl_type,
    invoice_num                     invoice_num_tbl_type,
    vendor_id                       vendor_id_tbl_type,
    vendor_site_id                  vendor_site_id_tbl_type,
    invoice_amount                  invoice_amount_tbl_type,
    invoice_currency_code           currency_code_tbl_type,
    invoice_date                    date_tbl_type,
    source                          source_tbl_type,
    description                     description_tbl_type,
    creation_date                   date_tbl_type,
    exchange_rate                   currency_conv_rate_tbl_type,
    exchange_rate_type              currency_conv_type_tbl_type,
    exchange_date                   date_tbl_type,
    payment_currency_code           pay_curr_code_tbl_type,
    terms_id                        terms_id_tbl_type,
    group_id                        group_id_tbl_type,
    org_id                          org_id_tbl_type);
TYPE curr_condition_rec_type IS RECORD (
    pay_curr_code    po_vendor_sites.payment_currency_code%TYPE,
    invoice_amount   ap_invoices_interface.invoice_amount%TYPE,
    tax_amount       ap_invoices_interface.invoice_amount%TYPE,
    invoice_id       ap_invoices_interface.invoice_id%TYPE,
    invoice_num      ap_invoices_interface.invoice_num%TYPE,
    vendor_id        po_vendors.vendor_id%TYPE,
    pay_site_id      po_vendor_sites.vendor_site_id%TYPE,
    inv_summary_code po_vendor_sites.pay_on_receipt_summary_code%TYPE,
    po_header_id     po_headers.po_header_id%TYPE,
    po_release_id    po_releases.po_release_id%TYPE,
    currency_code    po_headers.currency_code%TYPE,
    conversion_rate  po_headers.rate%TYPE,
    conversion_type  po_headers.rate_type%TYPE,
    conversion_date  po_headers.rate_date%TYPE,
    payment_terms_id po_headers.terms_id%TYPE,
    creation_date    po_headers.creation_date%TYPE,
    auto_tax_calc_flag po_vendor_sites.auto_tax_calc_flag%TYPE,
    tax_rounding_rule  po_vendor_sites.ap_tax_rounding_rule%TYPE,
    invoice_date     ap_invoices_interface.invoice_date%TYPE
);
/* Cursor for fetching consumption advice */
/* Bug 5021261 : Pay on receipt program was interfacing USE invoices multiple
**               times. Modified the cursor below to exclude Consumption Advice
**               lines that are already interfaced to AP.
*/
CURSOR c_consumption (p_cutoff_date DATE) IS
-- std PO referencing Global Agreement
SELECT
    poh.po_header_id                            PO_HEADER_ID,
    TO_NUMBER(NULL)                             PO_RELEASE_ID,  -- bug2840859
    pol.po_line_id                              PO_LINE_ID,
    poll.line_location_id                       LINE_LOCATION_ID,
    pod.po_distribution_id                      PO_DISTRIBUTION_ID,
    pv.vendor_id                                VENDOR_ID,
    pvs.pay_on_receipt_summary_code             PAY_ON_RECEIPT_SUMMARY_CODE,
    poh.vendor_site_id                          VENDOR_SITE_ID,
    NVL(pvs.default_pay_site_id, pvs.vendor_site_id) DEFAULT_PAY_SITE_ID,
    pol.item_description                        ITEM_DESCRIPTION,
    poll.price_override                         UNIT_PRICE,
    pod.quantity_ordered                        QUANTITY,
    NVL(pod.quantity_billed, 0)                 QUANTITY_BILLED,
    poh.currency_code                           CURRENCY_CODE,
    poh.rate_type                               CURRENCY_CONVERSION_TYPE,
    poh.rate                                    CURRENCY_CONVERSION_RATE,
    poh.rate_date                               CURRENCY_CONVERSION_DATE,
    NVL(pvs.payment_currency_code,
        NVL(pvs.invoice_currency_code,
            poh.currency_code))                 PAYMENT_CURRENCY_CODE,
    poh.creation_date                           CREATION_DATE,
    NVL(NVL(poll.terms_id, poh.terms_id), pvs2.terms_id) PAYMENT_TERMS_ID,
    DECODE(poll.taxable_flag, 'Y', poll.tax_code_id, NULL) TAX_CODE_ID,
    NVL(pvs.ap_tax_rounding_rule, 'N')          TAX_ROUNDING_RULE,
    NVL(pvs.auto_tax_calc_flag, 'N')            AUTO_TAX_CALC_FLAG,
    poh.org_id                                  ORG_ID
FROM
    PO_VENDORS pv,
    PO_VENDOR_SITES pvs,
    PO_VENDOR_SITES pvs2,
    PO_HEADERS poh,
    PO_LINES pol,
    PO_LINE_LOCATIONS poll,
    PO_DISTRIBUTIONS pod
WHERE
      pv.vendor_id = poh.vendor_id
AND   poh.vendor_site_id = pvs.vendor_site_id
AND   NVL(pvs.default_pay_site_id, pvs.vendor_site_id) =
        pvs2.vendor_site_id
AND   poh.po_header_id = pol.po_header_id
AND   pol.po_line_id = poll.po_line_id
AND   poll.line_location_id = pod.line_location_id
AND   poh.pay_on_code IN ('RECEIPT_AND_USE', 'USE')
AND   DECODE (poh.consigned_consumption_flag,     -- utilize PO_HEADERS_F1 idx
              'Y',
              DECODE(poh.closed_code,
                     'FINALLY CLOSED',
                     NULL,
                     'Y'),
              NULL) = 'Y'
AND   poh.type_lookup_code = 'STANDARD'
AND   poh.creation_date <= p_cutoff_date
AND   pvs.pay_on_code IN ('RECEIPT_AND_USE', 'USE')
AND   pod.quantity_ordered > NVL(pod.quantity_billed,0)
AND   poll.closed_code <> 'FINALLY CLOSED'
AND   NOT EXISTS ( SELECT 'use invoice is interfaced'
                     FROM  ap_invoices_interface aii,
                           ap_invoice_lines_interface aili
                    WHERE  aii.invoice_id = aili.invoice_id
                      AND  nvl(aii.status,'PENDING') <> 'PROCESSED'
                      AND  aili.po_distribution_id = pod.po_distribution_id )
UNION ALL
-- blanket release
SELECT
    poh.po_header_id                            PO_HEADER_ID,
    por.po_release_id                           PO_RELEASE_ID,
    pol.po_line_id                              PO_LINE_ID,
    poll.line_location_id                       LINE_LOCATION_ID,
    pod.po_distribution_id                      PO_DISTRIBUTION_ID,
    pv.vendor_id                                VENDOR_ID,
    pvs.pay_on_receipt_summary_code             PAY_ON_RECEIPT_SUMMARY_CODE,
    poh.vendor_site_id                          VENDOR_SITE_ID,
    NVL(pvs.default_pay_site_id, pvs.vendor_site_id) DEFAULT_PAY_SITE_ID,
    pol.item_description                        ITEM_DESCRIPTION,
    poll.price_override                         UNIT_PRICE,
    pod.quantity_ordered                        QUANTITY,
    NVL(pod.quantity_billed, 0)                 QUANTITY_BILLED,
    poh.currency_code                           CURRENCY_CODE,
    poh.rate_type                               CURRENCY_CONVERSION_TYPE,
    poh.rate                                    CURRENCY_CONVERSION_RATE,
    poh.rate_date                               CURRENCY_CONVERSION_DATE,
    NVL(pvs.payment_currency_code,
        NVL(pvs.invoice_currency_code,
            poh.currency_code))                 PAYMENT_CURRENCY_CODE,
    por.creation_date                           CREATION_DATE,
    NVL(NVL(poll.terms_id, poh.terms_id), pvs2.terms_id) PAYMENT_TERMS_ID,
    DECODE(poll.taxable_flag, 'Y', poll.tax_code_id, NULL) TAX_CODE_ID,
    NVL(pvs.ap_tax_rounding_rule, 'N')          TAX_ROUNDING_RULE,
    NVL(pvs.auto_tax_calc_flag, 'N')            AUTO_TAX_CALC_FLAG,
    por.org_id                                  ORG_ID
FROM
    PO_VENDORS pv,
    PO_VENDOR_SITES pvs,
    PO_VENDOR_SITES pvs2,
    PO_HEADERS poh,
    PO_RELEASES por,
    PO_LINES pol,
    PO_LINE_LOCATIONS poll,
    PO_DISTRIBUTIONS pod
WHERE
      pv.vendor_id = poh.vendor_id
AND   poh.vendor_site_id = pvs.vendor_site_id
AND   NVL(pvs.default_pay_site_id, pvs.vendor_site_id) =
        pvs2.vendor_site_id
AND   poh.po_header_id = por.po_header_id
AND   poh.po_header_id = pol.po_header_id
AND   pol.po_line_id = poll.po_line_id
AND   por.po_release_id = poll.po_release_id
AND   poll.line_location_id = pod.line_location_id
AND   por.pay_on_code IN ('RECEIPT_AND_USE', 'USE')
AND   DECODE (por.consigned_consumption_flag,  -- utilize PO_RELEASES_F1 idx
              'Y',
              DECODE(por.closed_code,
                     'FINALLY CLOSED',
                     NULL,
                     'Y'),
              NULL) = 'Y'
AND   por.release_type = 'BLANKET'
AND   por.creation_date <= p_cutoff_date
AND   pvs.pay_on_code IN ('RECEIPT_AND_USE', 'USE')
AND   pod.quantity_ordered > NVL(pod.quantity_billed,0)
AND   poll.closed_code <> 'FINALLY CLOSED'
AND   NOT EXISTS ( SELECT 'use invoice is interfaced'
                     FROM  ap_invoices_interface aii,
                           ap_invoice_lines_interface aili
                    WHERE  aii.invoice_id = aili.invoice_id
                      AND  nvl(aii.status,'PENDING') <> 'PROCESSED'
                      AND  aili.po_distribution_id = pod.po_distribution_id )
ORDER BY  6,    -- VENDOR_ID
          9,    -- DEFAULT_PAY_SITE_ID
          7,    -- PAY_ON_RECEIPT_SUMMARY_CODE
          15,   -- CURRENCY_CODE
          18,   -- CURRENCY_CONVERSION_DATE  -- bug2786193
          16,   -- CURRENCY_CONVERSION_TYPE  -- bug2786193
          17,   -- CURRENCY_CONVERSION_RATE  -- bug2786193
          20,   -- PAYMENT_TERMS_ID
          -- 19,   -- CREATION_DATE          -- bug2786193
          1,    -- PO_HEADER_ID
          2,    -- PO_RELEASE_ID
          3,    -- PO_LINE_ID
          4,    -- LINE_LOCATION_ID
          5;    -- DISTRIBUTION_ID
/* <PAY ON USE FPI END> */
/* Bug 3506659*/
p_tax_info_tbl          AP_POR_TAX_INFO_OBJ_TBL_TYPE;
x_recov_tax_tbl         AP_POR_TAX_NUMBER_TBL_TYPE;
x_nonrecov_tax_tbl      AP_POR_TAX_NUMBER_TBL_TYPE;
l_ap_tax_record         AP_POR_TAX_INFO_OBJECT_TYPE ;
/* Bug 3506659*/
/*==================================================================
  FUNCTION  NAME:	create_receipt_invoices
  DESCRIPTION: 	This is a batch layer API which will create standard invoices
		in Oracle Payables based on purchase orders and receipt
		transactions. Record(s) will be created in the following
		entities by calling various process APIs:
  PARAMETERS:	X_commit_interval		 IN	 NUMBER,
		X_rcv_shipment_header_id	 IN	 NUMBER,
		X_receipt_event		 	 IN	 VARCHAR2
  DESIGN
  REFERENCES:	857proc.doc
  CHANGE 		Created		19-March-96	SODAYAR
  HISTORY:
=======================================================================*/
FUNCTION  create_receipt_invoices(X_commit_interval	 IN	 NUMBER,
			    X_rcv_shipment_header_id	 IN	 NUMBER,
			    X_receipt_event		 IN	 VARCHAR2,
			    X_aging_period		 IN      NUMBER DEFAULT NULL)
							RETURN BOOLEAN;
/*==================================================================
  FUNCTION NAME:	create_invoice_num
  DESCRIPTION: 	This Api is used to create invoice number according to the
		summary level(input parameter) for ERS.
                For pay on use, the invoice num always has the structure
                'USE-<INVOICE_DATE>-<UNIQUE NUM FROM SEQUENCE>'
  PARAMETERS:	X_pay_on_receipt_summary_code   IN 	VARCHAR2,
		X_invoice_date			IN	DATE,
		X_packing_slip		  	IN	VARCHAR2,
		X_receipt_num		  	IN    	VARCHAR2,
                p_source			IN	VARCHAR2 := NULL
  PARAMETER DESCRIPTIONS:
  x_org_id: org id
  x_vendor_site_id: vendor pay site id
  X_pay_on_receipt_summary_code: invoice summary level from vendor site
  X_invoice_date: invoice date
  X_packing_slip: packing slip information
  X_receipt_num: receipt number
  p_source: what invoice it is creating invoice number for
  DESIGN
  REFERENCES:	 	857proc.doc
  CHANGE 		Created		19-March-96	SODAYAR
  HISTORY:
                        <PAY ON USE FPI> 10-October-2002 BAO
=======================================================================*/
FUNCTION create_invoice_num( X_org_id			     IN NUMBER,
			     X_vendor_site_id		     IN NUMBER,
			     X_pay_on_receipt_summary_code   IN	VARCHAR2,
			     X_invoice_date		     IN DATE,
			     X_packing_slip	  	     IN	VARCHAR2,
			     X_receipt_num		     IN VARCHAR2,
/* <PAY ON USE FPI START> */
                 p_source                IN VARCHAR2 := NULL)
/* <PAY ON USE FPI END> */
					RETURN VARCHAR2;
/*==================================================================
  PROCEDURE NAME:	wrap_up_current_invoice
  DESCRIPTION: 	This API is called whenever a new invoice is about to be
		 created. It performs wrap-up operations:
			1) update the current invoice with the correct amounts;
			2) update the grand totals
			3) create payment schedule for the current invoice
			4) update ap_batches if required
			5) setup all the necessary "current" variables for
			   the next invoice.
  PARAMETERS:	X_new_vendor_id		        IN NUMBER,
		X_new_pay_site_id		IN NUMBER,
		X_new_currency_code		IN VARCHAR2,
		X_new_conversion_rate_type	IN VARCHAR2,
		X_new_conversion_date		IN DATE,
		X_new_conversion_rate		IN NUMBER,
		X_new_payment_terms_id	        IN NUMBER,
		X_new_transaction_date		IN DATE,
		X_new_packing_slip		IN VARCHAR2,
		X_new_shipment_header_id	IN NUMBER,
		X_def_disc_is_inv_less_tax_flag	IN VARCHAR2,
		X_terms_date			IN DATE,
		X_payment_priority		IN VARCHAR2,
		X_payment_method_lookup_code	IN VARCHAR2,
		X_batch_id			IN OUT NUMBER,
		X_def_batch_control_flag	IN VARCHAR2,
		X_def_base_currency_code	IN VARCHAR2,
		X_curr_invoice_amount		IN OUT	NUMBER,
		X_curr_tax_amount		IN OUT	NUMBER,
		X_curr_invoice_id		IN OUT NUMBER,
		X_curr_vendor_id		IN OUT NUMBER,
		X_curr_pay_site_id		IN OUT NUMBER,
		X_curr_currency_code		IN OUT VARCHAR2,
		X_curr_conversion_rate_type	IN OUT	VARCHAR2,
		X_curr_conversion_date		IN OUT DATE,
		X_curr_conversion_rate		IN OUT NUMBER,
		X_curr_payment_terms_id	        IN OUT NUMBER,
		X_curr_transaction_date		IN OUT	DATE,
		X_curr_packing_slip		IN OUT	VARCHAR2,
		X_curr_shipment_header_id	IN OUT NUMBER,
		X_curr_inv_process_flag		IN OUT VARCHAR2,
		X_invoice_count			IN OUT NUMBER,
		X_invoice_running_total		IN OUT NUMBER
  DESIGN
  REFERENCES:	 	857proc.doc
  CHANGE 		Created		19-March-96	SODAYAR
  HISTORY:	 	Modified	14-May-96	KKCHAN
				added X_def_base_currency_code as a param.
                        Modified        03-Dec-97       NWANG
                                added X_curr_payment_code as param
=======================================================================*/
/* Bug 586895 */
PROCEDURE WRAP_UP_CURRENT_INVOICE(X_new_vendor_id       IN NUMBER,
                X_new_pay_site_id               IN NUMBER,
                X_new_currency_code             IN VARCHAR2,
                X_new_conversion_rate_type      IN VARCHAR2,
                X_new_conversion_rate_date      IN DATE,
                X_new_conversion_rate           IN NUMBER,
                X_new_payment_terms_id          IN NUMBER,
                X_new_transaction_date          IN DATE,
                X_new_packing_slip              IN VARCHAR2,
                X_new_shipment_header_id        IN NUMBER,
                X_terms_date                    IN DATE,
                X_payment_priority              IN VARCHAR2,
                X_new_payment_code              IN VARCHAR2,
                X_curr_method_code              IN OUT NOCOPY VARCHAR2,
/*Bug 612979*/  X_new_pay_curr_code             IN VARCHAR2,
                X_curr_pay_curr_code            IN OUT NOCOPY VARCHAR2,
                X_batch_id                      IN OUT NOCOPY NUMBER,
                X_curr_invoice_amount           IN OUT NOCOPY  NUMBER,
                X_curr_tax_amount               IN OUT NOCOPY  NUMBER,
                X_curr_invoice_id               IN OUT NOCOPY NUMBER,
                X_curr_vendor_id                IN OUT NOCOPY NUMBER,
                X_curr_pay_site_id              IN OUT NOCOPY NUMBER,
                X_curr_currency_code            IN OUT NOCOPY VARCHAR2,
                X_curr_conversion_rate_type     IN OUT NOCOPY  VARCHAR2,
                X_curr_conversion_rate_date     IN OUT NOCOPY DATE,
                X_curr_conversion_rate          IN OUT NOCOPY NUMBER,
                X_curr_payment_terms_id         IN OUT NOCOPY NUMBER,
                X_curr_transaction_date         IN OUT NOCOPY  DATE,
                X_curr_packing_slip             IN OUT NOCOPY  VARCHAR2,
                X_curr_shipment_header_id       IN OUT NOCOPY NUMBER,
                X_curr_inv_process_flag		IN OUT NOCOPY VARCHAR2,
                X_invoice_count                 IN OUT NOCOPY NUMBER,
                X_invoice_running_total         IN OUT NOCOPY NUMBER,
                X_org_id IN NUMBER,--Bug 5533454
                X_curr_le_transaction_date IN OUT NOCOPY DATE);
/*==================================================================
  PROCEDURE NAME: get_received_quantity
  DESCRIPTION: 	This API calculates the actual received quantity of a
                shipment after adjustment
  PARAMETERS:	 X_transaction_id	IN NUMBER,
		 X_received_quantity	IN OUT NUMBER
  CHANGE 		Created		01-DEC-98	DKFCHAN
  HISTORY:
=======================================================================*/
PROCEDURE get_received_quantity( X_transaction_id     IN     NUMBER,
                                 X_shipment_line_id   IN     NUMBER,
                                 X_received_quantity  IN OUT NOCOPY NUMBER);
PROCEDURE get_received_amount( X_transaction_id     IN     NUMBER,
                               X_shipment_line_id   IN     NUMBER,
                               X_received_amount    IN OUT NOCOPY NUMBER);
PROCEDURE create_invoice_distributions(X_invoice_id     	IN NUMBER,
				  X_invoice_currency_code 	IN VARCHAR2,
				  X_base_currency_code  	IN VARCHAR2,
                                  X_batch_id            	IN NUMBER,
                                  X_vendor_id                   IN NUMBER, --bug 3506659
                                  X_pay_site_id         	IN NUMBER,
                                  X_auto_tax_calc_flag          IN VARCHAR2, --bug 3506659
                                  X_tax_rounding_rule           IN VARCHAR2, --bug 3506659
                                  X_po_header_id        	IN NUMBER,
                                  X_po_line_id          	IN NUMBER,
                                  X_po_line_location_id 	IN NUMBER,
                                  X_po_release_id        	IN NUMBER,
                                  X_receipt_event       	IN VARCHAR2,
                                  X_po_distribution_id  	IN NUMBER,
                       /*X_receipt_event and X_po_distribution_id
                       used only for DELIVER transactions*******/
                                  X_item_description    	IN VARCHAR2,
                                  X_type_1099           	IN VARCHAR2,
                                  X_tax_code_id            	IN OUT NOCOPY NUMBER,
                                  X_tax_amount          	IN NUMBER,
                       /*This will be populated only for shipment
                       and bill notices; for the other cases tax
                       amount will be calculated****************/
                                  X_create_tax_dist_flag 	IN VARCHAR2,
                       /*If set to 'Y', create_tax_distributions
                       API will be invoked to create tax distributions
                       API will be invoked to create tax distributions
                       lines.  This flag will be set to 'N' for
                       the case where a shipment and billing notice
                       specifies a tax_amount and tax_name at the
                       shipment header level.  We will then create
                       only one tax distribution line for the entire
                       invoice and not create any tax distributions
                       for the individual distributions. (see Key
                       assumptions.)******************************/
                                  X_quantity            	IN NUMBER,
                                  X_unit_price          	IN NUMBER,
                                  X_exchange_rate_type  	IN VARCHAR2,
                                  X_exchange_date       	IN DATE,
                                  X_exchange_rate       	IN NUMBER,
                                  X_accts_pay_code_comb_id 	IN NUMBER,
                                  X_invoice_date        	IN DATE,
                                  X_receipt_date        	IN DATE,
                                  X_vendor_income_tax_region    IN VARCHAR2,
				  X_reference_1			IN VARCHAR2,
				  X_reference_2			IN VARCHAR2,
				  X_awt_flag			IN VARCHAR2,
				  X_awt_group_id		IN NUMBER,
				  X_accounting_date		IN DATE,
				  X_period_name			IN VARCHAR2,
				  X_transaction_type		IN VARCHAR2,
				  X_unique_id			IN NUMBER,
                                  X_curr_invoice_amount     IN OUT NOCOPY   NUMBER,
                                  X_curr_tax_amount         IN OUT NOCOPY NUMBER,
                                  X_curr_inv_process_flag   IN OUT NOCOPY VARCHAR2,
				  X_receipt_num		        IN VARCHAR2 DEFAULT NULL,
				  X_rcv_transaction_id	        IN NUMBER   DEFAULT NULL,
				  X_match_option	        IN VARCHAR2 DEFAULT NULL,
				  X_amount                      IN NUMBER   DEFAULT NULL,
				  X_matching_basis              IN VARCHAR2 DEFAULT 'QUANTITY');
/* <PAY ON USE FPI START> */
/*==================================================================
  PROCEDURE NAME:	create_use_invoice
  DESCRIPTION: 	API for creating invoices for consumption advice.
  PARAMETERS:
    p_api_version     : API version of this procedure the caller assumes
    x_return_status   : Return status of the procedure
    p_commit_interval : Number of Invoices evaluated before a commit is issued
    p_aging_period    : days for a consumption advice to age before
                        it can be invoiced
  DESIGN
  REFERENCES:
  CHANGE 		Created		09-October-02	BAO
  HISTORY:
=======================================================================*/
PROCEDURE create_use_invoices(
    p_api_version       IN  NUMBER,
    x_return_status     OUT NOCOPY  VARCHAR2,
    p_commit_interval   IN  NUMBER,
    p_aging_period      IN  NUMBER);
/*==================================================================
  PROCEDURE NAME:	need_new_invoice
  DESCRIPTION: 	A function to compare between current grouping
                variables and the record just fetched to determine
                whether the record belongs to the same invoice or not.
               .
  PARAMETERS:
    x_return_status          : return status of the procedure
    p_consumption            : record of tables to store invoice line info
    p_index                  : index to identify a record in p_consumption
    p_curr                   : structure that stores current invoice hdr info
    p_base_currency_code     : base currency code
  RETURN VALUE DATATYPE: VARCHAR2
    Possible Values: FND_API.G_TRUE or FND_API.G_FALSE
  DESIGN
  REFERENCES:
  CHANGE 		Created		09-October-02	BAO
  HISTORY:
                        Bug2786193      05-Feb-02       BAO
                        changed param list to use p_curr rec structure
=======================================================================*/
FUNCTION need_new_invoice (
    x_return_status           OUT NOCOPY VARCHAR2,
    p_consumption             IN BILC_PO_INVOICES_SV2.consump_rec_type,
    p_index                   IN NUMBER,
    p_curr                    IN BILC_PO_INVOICES_SV2.curr_condition_rec_type,
    p_base_currency_code      IN VARCHAR2) RETURN VARCHAR2;
/*==================================================================
  PROCEDURE NAME:	store_header_info
  DESCRIPTION: 	Temporarily stores all header related information into
                PL/SQL table structure for bulk insert later
  PARAMETERS:
    x_return_status    : return status of the procedure
    p_curr             : record structure to store current invoice header info
    p_invoice_desc     : invoice description
    p_group_id         : group id when doing import
    p_org_id           : org id
    x_ap_inv_header    : record of tables to store invoice header info
    p_index            : index to identify a record in x_ap_inv_header
  DESIGN
  REFERENCES:
  CHANGE     Created		09-October-02	BAO
  HISTORY:
=======================================================================*/
PROCEDURE store_header_info(
    x_return_status     OUT NOCOPY VARCHAR2,
    p_curr              IN  BILC_PO_INVOICES_SV2.curr_condition_rec_type,
    p_invoice_desc      IN  VARCHAR2,
    p_group_id          IN  VARCHAR2,
    p_org_id            IN  VARCHAR2,
    x_ap_inv_header     IN OUT NOCOPY BILC_PO_INVOICES_SV2.invoice_header_rec_type,
    p_index             IN  NUMBER);
/*==================================================================
  PROCEDURE NAME:	reset_header_values
  DESCRIPTION: 	reset all header grouping variables (curr_ variables) and
                other variables for invoice headers
  PARAMETERS:
    x_return_status    : return status of the procedure
    p_next_consump     : record of tables to store invoice line info
    p_index            : index to identify a recordd in p_next_consump
    x_curr             : record structure to store current invoice header info
  DESIGN
  REFERENCES:
  CHANGE     Created		09-October-02	BAO
  HISTORY:
=======================================================================*/
PROCEDURE reset_header_values (
    x_return_status         OUT NOCOPY VARCHAR2,
    p_next_consump          IN BILC_PO_INVOICES_SV2.consump_rec_type,
    p_index                 IN NUMBER,
    x_curr                  OUT NOCOPY BILC_PO_INVOICES_SV2.curr_condition_rec_type);
/*==================================================================
  PROCEDURE NAME:	calc_consumption_cost
  DESCRIPTION: 	calculate the invoice amount of the distribution and
                the tax.
  PARAMETERS:
    x_return_status         : return status of the procedure
    p_quantity              : quantity to be invoiced
    p_unit_price            : price
    p_tax_code_id           : tax code id
    p_tax_rounding_rule     : what rounding is used for taxing
    p_auto_tax_calc_flag    : tax calculation level
    p_invoice_currency_code : invoice currency
    x_invoice_line_amount   : return amt invoiced (excluding tax) of the line
    x_curr_invoice_amount   : return amt invoiced(excluding tax) for invoice
    x_curr_tax_amount       : return amt taxed for invoice
  DESIGN
  REFERENCES:
  CHANGE     Created		09-October-02	BAO
  HISTORY:
=======================================================================*/
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
    x_curr_tax_amount       IN OUT NOCOPY NUMBER);
/*==================================================================
  PROCEDURE NAME:	create_invoice_hdr
  DESCRIPTION: 	bulk insert records from p_ap_inv_header structure
                into AP_INVOICES_INTERFACE
  PARAMETERS:
    x_return_status : return status of the procedure
    p_ap_inv_header : record of tables that stores invoice header info
    p_from          : starting index to insert
    p_to            : ending index to insert
  DESIGN
  REFERENCES:
  CHANGE     Created		09-October-02	BAO
  HISTORY:
=======================================================================*/
PROCEDURE create_invoice_hdr(
    x_return_status OUT NOCOPY VARCHAR2,
    p_ap_inv_header IN BILC_PO_INVOICES_SV2.invoice_header_rec_type,
    p_from          IN NUMBER,
    p_to            IN NUMBER);
/*==================================================================
  PROCEDURE NAME:	create_invoice_distr
  DESCRIPTION: 	bulk insert records from p_consumption structure
                into AP_INVOICE_LINES_INTERFACE
  PARAMETERS:
    x_return_status : return status of the procedure
    p_consumption   : record of tables that stores invoice line info
    p_from          : starting index to insert
    p_to            : ending index to insert
  DESIGN
  REFERENCES:
  CHANGE     Created		09-October-02	BAO
  HISTORY:
=======================================================================*/
PROCEDURE create_invoice_distr(
    x_return_status OUT NOCOPY VARCHAR2,
    p_consumption   IN BILC_PO_INVOICES_SV2.consump_rec_type,
    p_from          IN NUMBER,
    p_to            IN NUMBER);
/* <PAY ON USE FPI END> */
END BILC_PO_INVOICES_SV2;
/