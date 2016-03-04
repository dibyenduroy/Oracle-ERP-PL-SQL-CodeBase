CREATE OR REPLACE PACKAGE APPS.BILC_PO_INVOICES_SV1 AUTHID CURRENT_USER AS
/* $Header: POXIVCRS.pls 115.10 2002/11/25 23:31:43 sbull ship $ */
/*==================================================================
  PROCEDURE NAME:	create_ap_invoices
  DESCRIPTION: 	This Api automatically creates AP invoices for either
		Receipt transactions combined with purchase order or shipment
		and billing notice.
  PARAMETERS:	X_transaction_source	 IN	 VARCHAR2,
		X_commit_interval	 IN	 NUMBER,
		X_shipment_header_id	 IN	 NUMBER
  DESIGN
  REFERENCES:	 	857proc.doc
  CHANGE 		Created		19-March-96	SODAYAR
  HISTORY:
=======================================================================*/
PROCEDURE  create_ap_invoices(X_transaction_source	 IN	 VARCHAR2,
			      X_commit_interval	         IN	 NUMBER,
			      X_shipment_header_id	 IN	 NUMBER,
			      X_aging_period		 IN      NUMBER DEFAULT NULL);
/*==================================================================
  PROCEDURE NAME:	get_ap_parameters
  DESCRIPTION: 	This procedure is used to obtain options defined in
		AP_SYSTEM_PARAMETERS and FINANCIAL_SYSTEM_PARAMETERS.
  PARAMETERS:	X_def_sets_of_books_id		OUT NUMBER,
		X_def_base_currency_code	OUT VARCHAR2,
		X_def_batch_control_flag	OUT VARCHAR2,
		X_def_exchange_rate_type	OUT VARCHAR2,
		X_def_multi_currency_flag	OUT VARCHAR2,
		X_def_gl_dat_fr_rec_flag	OUT VARCHAR2,
		X_def_dis_inv_less_tax_flag	OUT VARCHAR2,
		X_def_income_tax_region		OUT VARCHAR2,
		X_def_income_tax_region_flag	OUT VARCHAR2,
		X_def_vat_country_code		OUT VARCHAR2,
		X_def_transfer_desc_flex_flag	OUT VARCHAR2,
		X_def_org_id			OUT NUMBER,
                X_def_awt_include_tax_amt       OUT VARCHAR2
  DESIGN
  REFERENCES:	 	857proc.doc
  CHANGE 		Created		19-March-96	SODAYAR
  HISTORY:	        Changed         07-july-99      SRIKRISH
=======================================================================*/
PROCEDURE get_ap_parameters(    X_def_sets_of_books_id          OUT NOCOPY NUMBER,
                                X_def_base_currency_code        OUT NOCOPY VARCHAR2,
                                X_def_batch_control_flag        OUT NOCOPY VARCHAR2,
                                X_def_exchange_rate_type        OUT NOCOPY VARCHAR2,
                                X_def_multi_currency_flag       OUT NOCOPY VARCHAR2,
                                X_def_gl_dat_fr_rec_flag        OUT NOCOPY VARCHAR2,
                                X_def_dis_inv_less_tax_flag     OUT NOCOPY VARCHAR2,
                                X_def_income_tax_region         OUT NOCOPY VARCHAR2,
                                X_def_income_tax_region_flag    OUT NOCOPY VARCHAR2,
                                X_def_vat_country_code          OUT NOCOPY VARCHAR2,
				X_def_transfer_desc_flex_flag	OUT NOCOPY VARCHAR2,
                                X_def_org_id                    OUT NOCOPY NUMBER,
                                X_def_awt_include_tax_amt       OUT NOCOPY VARCHAR2 );
/*==================================================================
  PROCEDURE NAME:	get_vendor_related_info
  DESCRIPTION: 	This API is used to obtain vendor/vendor pay-site related
		info needed by the invoice creation program.
  PARAMETERS:	X_vendor_id  			IN  NUMBER,
		X_default_pay_site_id		IN  NUMBER,
                X_pay_group_lookup_code         OUT VARCHAR2,
                X_accts_pay_combination_id      OUT NUMBER,
                X_payment_method_lookup_code    OUT VARCHAR2,
                X_exclusive_payment_flag        OUT VARCHAR2,
                X_payment_priority              OUT VARCHAR2,
                X_terms_date_basis              OUT VARCHAR2,
                X_vendor_income_tax_region      OUT VARCHAR2,
                X_type_1099                     OUT VARCHAR2,
		X_awt_flag			OUT VARCHAR2,
		X_awt_group_id			OUT NUMBER,
		X_exclude_freight_from_disc	OUT VARCHAR2,
		X_payment_currency_code         OUT VARCHAR2
  DESIGN
  REFERENCES:	 	857proc.doc
  CHANGE 		Created		19-March-96	SODAYAR
  HISTORY:		Modified	29-APR-96	KKCHAN
=======================================================================*/
PROCEDURE get_vendor_related_info (  X_vendor_id  	      IN   NUMBER,
	        X_default_pay_site_id		IN NUMBER,
                X_pay_group_lookup_code         OUT NOCOPY VARCHAR2,
                X_accts_pay_combination_id      OUT NOCOPY NUMBER,
                X_payment_method_lookup_code    OUT NOCOPY VARCHAR2,
                X_exclusive_payment_flag        OUT NOCOPY VARCHAR2,
                X_payment_priority              OUT NOCOPY VARCHAR2,
                X_terms_date_basis              OUT NOCOPY VARCHAR2,
                X_vendor_income_tax_region      OUT NOCOPY VARCHAR2,
                X_type_1099                     OUT NOCOPY VARCHAR2,
		X_awt_flag			OUT NOCOPY VARCHAR2,
		X_awt_group_id			OUT NOCOPY NUMBER,
		X_exclude_freight_from_disc	OUT NOCOPY VARCHAR2,
		X_payment_currency_code         OUT NOCOPY VARCHAR2
		 );
/*==================================================================
  PROCEDURE NAME:	create_ap_batches
  DESCRIPTION: 	This API is used by the AP invoice creation program to
		create an invoice batch header record (depending on the
		system option). However no defaulting info will be populated
		in this API.
  PARAMETERS:	X_batch_source  IN  VARCHAR2
		X_currency_code IN  VARCHAR2
                X_batch_id   	OUT NUMBER
  DESIGN
  REFERENCES:	 	857proc.doc
  CHANGE 		Created		19-March-96	SODAYAR
  HISTORY:
=======================================================================*/
PROCEDURE create_ap_batches(	X_batch_source  IN  VARCHAR2,
				X_currency_code IN  VARCHAR2,
                                X_batch_id   	OUT NOCOPY NUMBER);
/*==================================================================
  PROCEDURE NAME:	update_ap_batches
  DESCRIPTION: 	This API is used to update the invoice control count and
		invoice running total for a given invoice batch.
  PARAMETERS:	X_batch_id	 IN	NUMBER,
		X_invoice_count	 IN	NUMBER,
		X_invoice_total  IN	NUMBER
  DESIGN
  REFERENCES:	 	857proc.doc
  CHANGE 		Created		19-March-96	SODAYAR
  HISTORY:
=======================================================================*/
PROCEDURE update_ap_batches( X_batch_id	      IN	NUMBER,
			     X_invoice_count  IN	NUMBER,
			     X_invoice_total  IN	NUMBER);
/*==================================================================
  PROCEDURE NAME:	create_invoice_header
  DESCRIPTION: 	This API is used to create a record in AP_INVOICES with
		values passed as input  parameters to this API. It will then
		call the standard AP object handler to insert the record into
		AP_INVOICES. Note this API is specific to the invoice
                creation program.
  PARAMETERS:	X_Invoice_Id 		        IN OUT	NUMBER,
		X_Vendor_Id			IN	NUMBER ,
               	X_Invoice_Num 			IN	VARCHAR2,
               	X_Invoice_Amount 		IN	NUMBER,
               	X_Vendor_Site_Id 		IN	NUMBER,
               	X_Invoice_Date 			IN	DATE,
               	X_Source 			IN	VARCHAR2,
                X_Invoice_Type_Lookup_Code 	IN	VARCHAR2,
               	X_Description 			IN	VARCHAR2,
               	X_Batch_Id 			IN	NUMBER,
               	X_Amt_Applicable_To_Discount 	IN	NUMBER,
               	X_Tax_Amount 			IN	NUMBER,
               	X_Terms_Id 			IN	NUMBER,
               	X_Terms_date_basis		IN	VARCHAR2,
		X_Terms_date		      IN OUT 	DATE ,
               	X_Payment_Method_Lookup_Code    IN      VARCHAR2,
	        X_Goods_Received_Date 	        IN	DATE,
               	X_Invoice_Received_Date         IN	DATE,
 		X_Approval_Status 	        IN	VARCHAR2,
 	        X_Pay_Group_Lookup_Code         IN	VARCHAR2,
		X_Set_Of_Books_Id 		IN	NUMBER,
               	X_Accts_Pay_CCID 		IN	NUMBER,
               	X_Invoice_Currency_Code 	IN	VARCHAR2,
               	X_Payment_Currency_Code 	IN	VARCHAR2,
               	X_Payment_Status_Flag 		IN	VARCHAR2,
		X_payment_amount_total		IN	NUMBER,
               	X_Posting_Status 		IN	VARCHAR2,
                X_Prepay_Flag 			IN	VARCHAR2,
               	X_Base_Amount 		        IN	NUMBER,
		X_Exchange_Rate		        IN	NUMBER,
               	X_Exchange_Rate_Type            IN	VARCHAR2,
               	X_Exchange_Date 	        IN	DATE,
               	X_Payment_Cross_Rate 	        IN	NUMBER,
               	X_Vat_Code                      IN	VARCHAR2,
               	X_Exclusive_Payment_Flag        IN	VARCHAR2,
 		X_Freight_Amount 	        IN	NUMBER,
               	X_Org_Id 		        IN	NUMBER
		X_reference_1			IN	VARCHAR2
		X_reference_2			IN	VARCHAR2
		X_awt_flag			IN	VARCHAR2
		X_awt_group_id			IN	NUMBER
		X_transaction_type		IN	VARCHAR2
		X_unique_id			IN	NUMBER
			-- transaction_type and X_unique_id are mainly used
			-- for error handling. X_txn_type will either be 'ERS'
			-- or 'ASBN'.
		X_def_gl_dat_fr_rec_flag	IN	VARCHAR2,
		X_accounting_date		IN OUT  DATE,
		X_period_name			IN OUT  VARCHAR2,
		X_curr_inv_process_flag		IN OUT   VARCHAR2
  DESIGN
  REFERENCES:	 	857proc.doc
  CHANGE 		Created		19-March-96	SODAYAR
  HISTORY:
=======================================================================*/
PROCEDURE create_invoice_header(X_Invoice_Id 		IN OUT	NOCOPY NUMBER,
			X_Vendor_Id			IN	NUMBER ,
                     	X_Invoice_Num 			IN	VARCHAR2,
                     	X_Invoice_Amount 		IN	NUMBER,
                     	X_Vendor_Site_Id 		IN	NUMBER,
                     	X_Invoice_Date 			IN	DATE,
                     	X_Source 			IN	VARCHAR2,
                     	X_Invoice_Type_Lookup_Code 	IN	VARCHAR2,
                     	X_Description 			IN	VARCHAR2,
                    	X_Batch_Id 			IN	NUMBER,
                     	X_Amt_Applicable_To_Discount 	IN	NUMBER,
                     	X_Tax_Amount 			IN	NUMBER,
                     	X_Terms_Id 			IN	NUMBER,
                     	X_Terms_date_basis		IN	VARCHAR2,
		    	X_Terms_date		       	IN OUT NOCOPY 	DATE ,
                     	X_Payment_Method_Lookup_Code    IN      VARCHAR2,
			X_Goods_Received_Date 		IN	DATE,
                     	X_Invoice_Received_Date 	IN	DATE,
 			X_Approval_Status 		IN	VARCHAR2,
 		        X_Pay_Group_Lookup_Code 	IN	VARCHAR2,
			X_Set_Of_Books_Id 		IN	NUMBER,
                     	X_Accts_Pay_CCID 		IN	NUMBER,
                        X_Invoice_Currency_Code 	IN	VARCHAR2,
                     	X_Payment_Currency_Code 	IN	VARCHAR2,
                      	X_Payment_Status_Flag 		IN	VARCHAR2,
			X_payment_amount_total		IN	NUMBER,
                     	X_Posting_Status 		IN	VARCHAR2,
                       	X_Prepay_Flag 			IN	VARCHAR2,
                     	X_Base_Amount 		        IN	NUMBER,
			X_Exchange_Rate		        IN	NUMBER,
                     	X_Exchange_Rate_Type            IN	VARCHAR2,
                     	X_Exchange_Date                 IN	DATE,
                     	X_Payment_Cross_Rate 		IN	NUMBER,
                     	X_Vat_Code 			IN	VARCHAR2,
                     	X_Exclusive_Payment_Flag 	IN	VARCHAR2,
 			X_Freight_Amount 		IN	NUMBER,
                     	X_Org_Id 			IN	NUMBER,
			X_reference_1			IN	VARCHAR2,
			X_reference_2			IN	VARCHAR2,
			X_awt_flag			IN	VARCHAR2,
			X_awt_group_id			IN	NUMBER,
			X_transaction_type		IN	VARCHAR2,
			X_unique_id			IN	NUMBER,
			X_def_gl_dat_fr_rec_flag	IN	VARCHAR2,
			X_accounting_date		IN OUT	NOCOPY DATE,
			X_period_name			IN OUT NOCOPY  VARCHAR2,
			X_curr_inv_process_flag		IN OUT NOCOPY  VARCHAR2
				 );
/*==================================================================
  PROCEDURE NAME:	create_invoice_distributions
  DESCRIPTION: 	This API is used to create ITEM invoice distribution and TAX
		distribution lines for a given invoice.
  PARAMETERS:   X_invoice_id 	IN NUMBER,
		X_invoice_currency_code IN VARCHAR2,
		X_base_currency_code	IN VARCHAR2,
	        X_batch_id 	IN NUMBER,
		X_pay_site_id 	IN NUMBER,
		X_po_header_id 	IN NUMBER,
		X_po_line_id 		IN NUMBER,
		X_po_line_location_id IN NUMBER,
		X_receipt_event 	IN NUMBER,
		X_po_distribution_id 	IN NUMBER,
		X_item_description 	IN VARCHAR2,
		X_type_1099 		IN VARCHAR2,
		X_tax_name 		IN VARCHAR2,
		X_tax_code_id 		IN NUMBER,
		X_tax_amount 		IN NUMBER,
		X_create_tax_dist_flag IN VARCHAR2,
		X_quantity 		IN NUMBER,
		X_unit_price 		IN NUMBER,
		X_exchange_rate_type 	IN VARCHAR2,
		X_exchange_date 	IN DATE,
		X_exchange_rate 	IN NUMBER,
		X_accts_pay_code_comb_id IN NUMBER,
		X_def_gl_dat_fr_rec_flag IN VARCHAR2,
		X_def_sets_of_books_id IN NUMBER,
		X_invoice_date 	       IN DATE,
		X_receipt_date 	       IN DATE,
		X_def_income_tax_region_flag IN VARCHAR2,
		X_def_income_tax_region 	IN VARCHAR2,
		X_vendor_income_tax_region 	IN VARCHAR2,
		X_reference_1		IN VARCHAR2,
		X_reference_2		IN VARCHAR2,
		X_def_transfer_desc_flex_flag IN VARCHAR2,
		X_awt_flag		IN VARCHAR2,
		X_awt_group_id		IN NUMBER,
		X_accounting_date	IN DATE,
		X_period_name		IN VARCHAR2,
		X_transaction_type	IN VARCHAR2,
		X_unique_id		IN NUMBER,
                X_def_awt_include_tax_amt      IN VARCHAR2,
		X_curr_invoice_amount 	IN OUT   NUMBER,
		X_curr_tax_amount 	IN OUT NUMBER,
                X_curr_inv_process_flag IN OUT VARCHAR2,
                X_Base_Amount1          IN  OUT NUMBER
  DESIGN
  REFERENCES:	 	857proc.doc
  CHANGE 		Created		19-March-96	SODAYAR
  HISTORY:	        Changed         07-july-99      SRIKRISH
=======================================================================*/
PROCEDURE create_invoice_distributions(X_invoice_id     	IN NUMBER,
				  X_invoice_currency_code 	IN VARCHAR2,
				  X_base_currency_code  	IN VARCHAR2,
                                  X_batch_id            	IN NUMBER,
                                  X_pay_site_id         	IN NUMBER,
                                  X_po_header_id        	IN NUMBER,
                                  X_po_line_id          	IN NUMBER,
                                  X_po_line_location_id 	IN NUMBER,
                                  X_receipt_event       	IN VARCHAR2,
                                  X_po_distribution_id  	IN NUMBER,
                       /*X_receipt_event and X_po_distribution_id
                       used only for DELIVER transactions*******/
                                  X_item_description    	IN VARCHAR2,
                                  X_type_1099           	IN VARCHAR2,
                                  X_tax_name            	IN VARCHAR2,
                                  X_tax_code_id          	IN NUMBER,
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
                                  X_def_gl_dat_fr_rec_flag 	IN VARCHAR2,
                                  X_def_sets_of_books_id 	IN NUMBER,
                                  X_invoice_date        	IN DATE,
                                  X_receipt_date        	IN DATE,
                                  X_def_income_tax_region_flag IN VARCHAR2,
                                  X_def_income_tax_region       IN VARCHAR2,
                                  X_vendor_income_tax_region    IN VARCHAR2,
				  X_reference_1			IN VARCHAR2,
				  X_reference_2			IN VARCHAR2,
				  X_def_transfer_desc_flex_flag IN VARCHAR2,
				  X_awt_flag			IN VARCHAR2,
				  X_awt_group_id		IN NUMBER,
				  X_accounting_date		IN DATE,
				  X_period_name			IN VARCHAR2,
				  X_transaction_type		IN VARCHAR2,
				  X_unique_id			IN NUMBER,
                                  X_def_awt_include_tax_amt     IN VARCHAR2,
                                  X_curr_invoice_amount     IN OUT NOCOPY   NUMBER,
                                  X_curr_tax_amount         IN OUT NOCOPY NUMBER,
                                  X_curr_inv_process_flag   IN OUT NOCOPY VARCHAR2,
                                  X_Base_Amount1            IN OUT NOCOPY NUMBER  )  ;
/*==================================================================
  PROCEDURE NAME:	get_accounting_date_and_period
  DESCRIPTION: 	This Api is used to determine the accounting date used in
		the in voice distribution based on the gl daate setup in
		 payables.
  PARAMETERS:	X_def_gl_date_from_receipt_flag  IN	VARCHAR2,
		X_def_sets_of_books_id	         IN	NUMBER,
		X_invoice_date		         IN 	DATE,
		X_receipt_date		         IN	DATE
		X_batch_id			IN	NUMBER,
		X_transaction_type		IN	VARCHAR2,
		X_unique_id			IN	NUMBER,
			-- The above 3 variables are used for error handling.
                X_accounting_date               OUT    DATE,
                X_period_name                   OUT    VARCHAR2 ,
		X_curr_inv_process_flag		IN OUT VARCHAR2
  DESIGN
  REFERENCES:	857proc.doc
  CHANGE 	Created		19-March-96	SODAYAR
  HISTORY:
=======================================================================*/
PROCEDURE  get_accounting_date_and_period(
                         X_def_gl_dat_fr_rec_flag        IN     VARCHAR2,
                         X_def_sets_of_books_id          IN     NUMBER,
                         X_invoice_date                  IN     DATE,
                         X_receipt_date                  IN     DATE,
			 X_batch_id			 IN	NUMBER,
			 X_transaction_type		 IN	VARCHAR2,
			 X_unique_id			 IN	NUMBER,
                         X_accounting_date               OUT NOCOPY    DATE,
                         X_period_name                   OUT NOCOPY    VARCHAR2,
			 X_curr_inv_process_flag         IN OUT NOCOPY VARCHAR2 );
/*==================================================================
  PROCEDURE NAME:	create_tax_distributions
  DESCRIPTION: 	This API is used to create tax distribution lines for a
		given in voice and tax name.
  PARAMETERS:
                        X_invoice_id               IN     NUMBER,
			X_invoice_currency_code	   IN     VARCHAR2,
			X_base_currency_code	   IN     VARCHAR2,
			X_batch_id	           IN     NUMBER,
                        X_pay_site_id              IN     NUMBER,
                        X_accounting_date          IN     DATE,
                        X_period_name              IN     VARCHAR2,
                        X_tax_name                 IN     VARCHAR2,
                        X_tax_code_id              IN     NUMBER,
                        X_tax_amount               IN     VARCHAR2,
                        X_taxable_amount           IN     NUMBER,
                        X_exchange_rate_type       IN     VARCHAR2,
                        X_exchange_date            IN     DATE,
                        X_exchange_rate            IN     NUMBER,
                        X_type_1099                IN     VARCHAR2,
                        X_income_tax_region        IN     VARCHAR2,
                        X_assets_tracking_flag     IN     VARCHAR2,
                        X_def_sets_of_books_id     IN     NUMBER,
                        X_accts_pay_combination_id IN     NUMBER,
        		X_awt_flag		   IN     VARCHAR2,
                        X_awt_group_id		   IN     NUMBER,
                        X_transaction_type         IN     VARCHAR2,
                        X_unique_id		   IN     NUMBER,
                        X_def_awt_include_tax_amt  IN     VARCHAR2,
                        X_curr_invoice_amount      IN OUT NUMBER,
                        X_curr_tax_amount          IN OUT NUMBER,
                        X_curr_inv_process_flag	IN OUT VARCHAR2,
                        X_Base_Amount1             IN  OUT   NUMBER
  DESIGN
  REFERENCES:	 	857proc.doc
  CHANGE 		Created		19-March-96	SODAYAR
  HISTORY:	        Changed         07-July-99      SRIKRISH
=======================================================================*/
PROCEDURE create_tax_distributions(
                             X_invoice_id               IN     NUMBER,
			     X_invoice_currency_code	IN     VARCHAR2,
			     X_base_currency_code	IN     VARCHAR2,
			     X_batch_id	                IN     NUMBER,
                             X_pay_site_id              IN     NUMBER,
                             X_accounting_date          IN     DATE,
                             X_period_name              IN     VARCHAR2,
                             X_tax_name                 IN     VARCHAR2,
                             X_tax_code_id              IN     NUMBER,
                             X_tax_amount               IN     VARCHAR2,
                             X_taxable_amount           IN     NUMBER,
                             X_exchange_rate_type       IN     VARCHAR2,
                             X_exchange_date            IN     DATE,
                             X_exchange_rate            IN     NUMBER,
                             X_type_1099                IN     VARCHAR2,
                             X_income_tax_region        IN     VARCHAR2,
                             X_assets_tracking_flag     IN     VARCHAR2,
                             X_def_sets_of_books_id     IN     NUMBER,
                             X_accts_pay_combination_id IN     NUMBER,
	                     X_awt_flag			IN     VARCHAR2,
		             X_awt_group_id		IN     NUMBER,
		             X_transaction_type		IN     VARCHAR2,
		             X_unique_id		IN     NUMBER,
                             X_def_awt_include_tax_amt  IN     VARCHAR2,
                             X_curr_invoice_amount      IN OUT NOCOPY NUMBER,
                             X_curr_tax_amount          IN OUT NOCOPY NUMBER,
                             X_curr_inv_process_flag	IN OUT NOCOPY VARCHAR2,
                             X_Base_Amount1             IN OUT NOCOPY    NUMBER );
/*==================================================================
  <CANCEL ASBN FPI, bug # 2569530>
  PROCEDURE NAME:	cancel_asbn_invoices
  DESCRIPTION: 	Calls AP's API Ap_Cancel_Single_Invoice to cancel invoices
		in ASBN cancellation
  PARAMETERS:	p_invoice_num	 IN	 VARCHAR2,
		p_vendor_id	 IN	 NUMBER
  DESIGN
  REFERENCES:
  CHANGE 	Created		21-AUGUST-02	DXIE
  HISTORY:
=======================================================================*/
PROCEDURE  cancel_asbn_invoices(
	p_invoice_num	IN	VARCHAR2,
	p_vendor_id	IN	NUMBER);
/* <PAY ON USE FPI START> */
/*=================================================================
  PROCEDURE NAME:	submit_invoice_import
  DESCRIPTION:	Submit a concurrent request "Payable Open Interface Import"
		to process data that have been inserted into AP Interface
		tables.
  PARAMETERS:
        x_return_status : return status of the procedure
	p_source        : what kind of invoices this call is creating for
	p_group_id	: group id for invoice import
	p_batch_name	: batch name
	p_user_id	: user id
	p_login_id	: login id
	x_request_id	: return request id after submitting the request
  DESIGN REFERENCES:
  CHANGE HISTORY:	Created		08-October-02	BAO
==================================================================*/
PROCEDURE submit_invoice_import (
        x_return_status	OUT NOCOPY VARCHAR2,
	p_source	IN	VARCHAR2,
	p_group_id	IN	VARCHAR2,
	p_batch_name	IN	VARCHAR2,
	p_user_id	IN	NUMBER,
	p_login_id	IN	NUMBER,
	x_request_id	OUT NOCOPY NUMBER);
/*=================================================================
  PROCEDURE NAME:	delete_interface_records
  DESCRIPTION:	Deletes all the records in AP_INVOICES_INTERFACE and
                AP_INVOICE_LINES_INTERFACE tables based on group_id
  PARAMETERS:
    x_return_status     : return status of the procedure
    p_group_id          : group id for import program
  DESIGN REFERENCES:
  CHANGE HISTORY:	Created		08-October-02	BAO
==================================================================*/
PROCEDURE delete_interface_records(
    x_return_status     OUT NOCOPY VARCHAR2,
    p_group_id          IN VARCHAR2);
/* <PAY ON USE FPI END> */
END BILC_PO_INVOICES_SV1;
/