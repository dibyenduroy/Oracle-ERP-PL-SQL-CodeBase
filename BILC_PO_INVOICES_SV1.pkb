CREATE OR REPLACE PACKAGE BODY APPS.BILC_PO_INVOICES_SV1 AS
/* $Header: POXIVCRB.pls 115.27 2004/06/02 20:06:49 pparthas ship $ */
-- Read the profile option that enables/disables the debug log
g_fnd_debug VARCHAR2(1) := NVL(FND_PROFILE.VALUE('AFLOG_ENABLED'),'N');
g_asn_debug VARCHAR2(1) := NVL(FND_PROFILE.VALUE('PO_RVCTP_ENABLE_TRACE'),'N');
/* <CANCEL ASBN FPI START>, bug # 2569530 */
g_log_head    CONSTANT VARCHAR2(30) := 'po.plsql.BILC_PO_INVOICES_SV1.';
/* <CANCEL ASBN FPI END> */
/* <PAY ON USE FPI START> */
g_pkg_name CONSTANT VARCHAR2(50) := 'BILC_PO_INVOICES_SV1';
/* <PAY ON USE FPI END> */
/*================================================================
  PROCEDURE NAME: 	create_ap_invoices()
==================================================================*/
PROCEDURE  create_ap_invoices(X_transaction_source	 IN	 VARCHAR2,
			      X_commit_interval	         IN	 NUMBER,
			      X_shipment_header_id	 IN	 NUMBER,
			      X_aging_period		 IN      NUMBER)
 IS
   	X_progress   				VARCHAR2(4) := null;
        X_completion_code                       BOOLEAN;
   	X_receipt_completion_status	        BOOLEAN := TRUE;
   	X_bill_notice_compl_status	        BOOLEAN := TRUE;
    	X_receipt_event			        VARCHAR2(25) := 'RECEIVE';
        /*** this makes the API more generic, in future releases, we can use
	the same procedure to handle transactions for 'ACCEPT', 'DELIVER', etc.
	***/
	X_doc_sequence_value 	NUMBER;
	X_doc_sequence_id	NUMBER;
	X_db_sequence_name	VARCHAR2(50);
	X_sequential_numbering  VARCHAR2(2);
	X_invoice_id		NUMBER;
	X_set_of_books_id	NUMBER;
	X_invoice_date		DATE;
	X_use_interface		VARCHAR2(1) := null;
/* <PAY ON USE FPI> */
        l_consumption_comp_status VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
 BEGIN
     FND_MSG_PUB.initialize;
     X_use_interface := NVL(fnd_profile.value('PO_ASBN_INVOICE_INTERFACE'), 'N');
     If (X_transaction_source IS NULL) THEN
     	X_progress := '010';
	X_receipt_completion_status :=
		po_invoices_sv2.create_receipt_invoices(X_commit_interval,
 		                                X_shipment_header_id,
					        X_receipt_event, X_aging_period);
     	X_progress := '020';
        if (X_use_interface = 'N') then
  	   X_bill_notice_compl_status :=
		po_invoices_sv3.create_bill_notice_invoices(X_commit_interval,
		                                X_shipment_header_id);
        elsif (X_use_interface = 'Y') then
  	   X_bill_notice_compl_status :=
		PO_CREATE_ASBN_INVOICE.create_asbn_invoice (1,
		                                X_shipment_header_id);
	end if;
/* <PAY ON USE FPI START> */
        PO_INVOICES_SV2.create_use_invoices(
            1.0,
            l_consumption_comp_status,
            x_commit_interval,
            x_aging_period);
/* <PAY ON USE FPI END> */
     ELSIF (X_transaction_source = 'ERS') THEN
     	X_progress := '030';
	X_receipt_completion_status :=
		bilc_po_invoices_sv2.create_receipt_invoices(X_commit_interval,
				        X_shipment_header_id,
					X_receipt_event,X_aging_period);
     ELSIF (X_transaction_source = 'ASBN') THEN
     	X_progress := '040';
        if (X_use_interface = 'N') then
  	   X_bill_notice_compl_status :=
		po_invoices_sv3.create_bill_notice_invoices(X_commit_interval,
		                                X_shipment_header_id);
        elsif (X_use_interface = 'Y') then
  	   X_bill_notice_compl_status :=
		PO_CREATE_ASBN_INVOICE.create_asbn_invoice (1,
		                                X_shipment_header_id);
	end if;
/* <PAY ON USE FPI START> */
      ELSIF (X_transaction_source = 'ERS_AND_USE') THEN
	X_receipt_completion_status :=
		PO_INVOICES_SV2.create_receipt_invoices(
                  X_commit_interval,
                  X_shipment_header_id,
                  X_receipt_event,
                  X_aging_period);
        PO_INVOICES_SV2.create_use_invoices(
            1.0,
            l_consumption_comp_status,
            x_commit_interval,
            x_aging_period);
      ELSIF (X_transaction_source = 'USE') THEN
        PO_INVOICES_SV2.create_use_invoices(
            1.0,
            l_consumption_comp_status,
            x_commit_interval,
            x_aging_period);
/* <PAY ON USE FPI END> */
     END IF;
     X_progress := '050';
     X_completion_code :=	X_receipt_completion_status 	AND
				X_bill_notice_compl_status;
     /** This will return TRUE if create_ap_invoices did not encounter any
	application errors. However, if one or more application errors is
	found during the execution of this program, X_completion_code will
	be FALSE. **/
/* <PAY ON USE FPI START> */
    IF (l_consumption_comp_status <> FND_API.G_RET_STS_SUCCESS) THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;
/* <PAY ON USE FPI END> */
EXCEPTION
/* <PAY ON USE FPI START> */
WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
    RAISE;      /* Error has been printed. No need to print error here */
/* <PAY ON USE FPI END> */
WHEN others THEN
       	po_message_s.sql_error('create_ap_invoices', x_progress,sqlcode);
	RAISE;
END create_ap_invoices;
/*================================================================
  FUNCTION NAME:	get_vendor_related_info()
==================================================================*/
PROCEDURE get_vendor_related_info (X_vendor_id 	IN NUMBER,
		   X_default_pay_site_id	IN NUMBER,
                   X_pay_group_lookup_code      OUT NOCOPY VARCHAR2,
                   X_accts_pay_combination_id   OUT NOCOPY NUMBER,
                   X_payment_method_lookup_code OUT NOCOPY VARCHAR2,
                   X_exclusive_payment_flag     OUT NOCOPY VARCHAR2,
                   X_payment_priority           OUT NOCOPY VARCHAR2,
                   X_terms_date_basis           OUT NOCOPY VARCHAR2,
                   X_vendor_income_tax_region   OUT NOCOPY VARCHAR2,
                   X_type_1099                  OUT NOCOPY VARCHAR2,
		   X_awt_flag			OUT NOCOPY VARCHAR2,
		   X_awt_group_id		OUT NOCOPY NUMBER,
		   X_exclude_freight_from_disc	OUT NOCOPY VARCHAR2,
                   X_payment_currency_code      OUT NOCOPY VARCHAR2  -- BUG 612979
		  )
IS
	X_progress   			VARCHAR2(4) := null;
Begin
	X_progress	:= '010';
	/*** Obtain the following vendor, vendor_site related info. We would
	first lookup the values at the vendor-site first. If not found, then
	we would use the values specified at the vendor site. */
	SELECT	NVL(pvss.pay_group_lookup_code, pvds.pay_group_lookup_code),
	        NVL(pvss.accts_pay_code_combination_id,
			pvds.accts_pay_code_combination_id) ,
		pvss.payment_method_lookup_code,
		NVL(pvss.exclusive_payment_flag, pvds.exclusive_payment_flag),
		pvss.payment_priority,
		pvss.terms_date_basis,
		pvss.state vendor_income_tax_region,
		pvds.type_1099,
		pvss.allow_awt_flag,
		pvss.awt_group_id,
		pvss.exclude_freight_from_discount,
		NVL(pvss.payment_currency_code, pvss.invoice_currency_code)
	INTO	X_pay_group_lookup_code,
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
		X_payment_currency_code
	FROM	po_vendors 	pvds,
		po_vendor_sites pvss
	WHERE	pvss.vendor_site_id = X_default_pay_site_id
	AND	pvss.vendor_id = pvds.vendor_id;
EXCEPTION
WHEN others THEN
       	po_message_s.sql_error('get_vendor_related_info', x_progress,sqlcode);
	RAISE;
END get_vendor_related_info;
/*================================================================
  FUNCTION NAME:	get_ap_parameters()
==================================================================*/
PROCEDURE get_ap_parameters(	X_def_sets_of_books_id		OUT NOCOPY NUMBER,
				X_def_base_currency_code	OUT NOCOPY VARCHAR2,
				X_def_batch_control_flag	OUT NOCOPY VARCHAR2,
				X_def_exchange_rate_type	OUT NOCOPY VARCHAR2,
				X_def_multi_currency_flag	OUT NOCOPY VARCHAR2,
				X_def_gl_dat_fr_rec_flag	OUT NOCOPY VARCHAR2,
				X_def_dis_inv_less_tax_flag	OUT NOCOPY VARCHAR2,
				X_def_income_tax_region		OUT NOCOPY VARCHAR2,
				X_def_income_tax_region_flag	OUT NOCOPY VARCHAR2,
				X_def_vat_country_code		OUT NOCOPY VARCHAR2,
				X_def_transfer_desc_flex_flag	OUT NOCOPY VARCHAR2,
				X_def_org_id			OUT NOCOPY NUMBER,
/* bug# 908129 added the following parameter*/
                                X_def_awt_include_tax_amt       OUT NOCOPY VARCHAR2 )
IS
	X_progress	VARCHAR2(4)	:= NULL;
BEGIN
	IF (g_asn_debug = 'Y') THEN
   	asn_debug.put_line('Obtain AP System Options ... ');
	END IF;
	X_progress := '010';
	/* This select statement is used to obtain the AP_SYSTEM_PARAMETERS */
	SELECT		set_of_books_id,
			base_currency_code,
			NVL(batch_control_flag, 'N') batch_control_flag,
			default_exchange_rate_type,
			multi_currency_flag,
			gl_date_from_receipt_flag,
			disc_is_inv_less_tax_flag,							income_tax_region,
			income_tax_region_flag,
			transfer_desc_flex_flag,
			org_id,
                        awt_include_tax_amt
	INTO		X_def_sets_of_books_id,
			X_def_base_currency_code,
			X_def_batch_control_flag,
			X_def_exchange_rate_type,
			X_def_multi_currency_flag,
			X_def_gl_dat_fr_rec_flag,
			X_def_dis_inv_less_tax_flag,
			X_def_income_tax_region,
			X_def_income_tax_region_flag,
			X_def_transfer_desc_flex_flag,
			X_def_org_id,
                        X_def_awt_include_tax_amt
	FROM		ap_system_parameters;
	X_progress := '020';
	SELECT		vat_country_code
	INTO		X_def_vat_country_code
	FROM		financials_system_parameters;
EXCEPTION
WHEN others THEN
   IF (g_asn_debug = 'Y') THEN
      asn_debug.put_line('Error in getting AP System Options ... ');
   END IF;
   po_message_s.sql_error('get_ap_parameters', x_progress,sqlcode);
   RAISE;
END get_ap_parameters;
/*================================================================
  PROCEDURE NAME: 	create_ap_batches()
==================================================================*/
PROCEDURE create_ap_batches(	X_batch_source  IN  VARCHAR2,
				X_currency_code IN  VARCHAR2,
				X_batch_id   	OUT NOCOPY NUMBER
			   )
IS
	X_progress 	VARCHAR2(3)  := NULL;
	X_tmp_batch_id  NUMBER;
	X_batch_name	ap_batches.batch_name%TYPE;
BEGIN
	IF (g_asn_debug = 'Y') THEN
   	asn_debug.put_line('Creating AP Invoice Batch ... ');
	END IF;
	X_progress := '010';
	/*** obtain the translated batch name ***/
	IF (X_batch_source = 'ERS') THEN
		fnd_message.set_name('PO', 'PO_INV_CR_ERS_BATCH_DESC');
	ELSIF (X_batch_source = 'ASBN') THEN
		fnd_message.set_name('PO', 'PO_INV_CR_ASBN_BATCH_DESC');
	END IF;
	X_progress := '020';
	IF (X_batch_source IN ('ERS', 'ASBN')) THEN
		X_batch_name := fnd_message.get;
	ELSE
		X_batch_name := X_batch_source;
	END IF;
	X_progress := '030';
	SELECT	ap_batches_s.nextval
	INTO	X_tmp_batch_id
	FROM    dual;
	X_progress := '040';
	INSERT INTO	ap_batches
		( 	batch_id,
			batch_name,
			batch_date,
			invoice_currency_code,
			payment_currency_code,
			last_update_date,
			last_updated_by,
			last_update_login,
			creation_date,
			created_by 	)
	VALUES
		(	X_tmp_batch_id,
			X_batch_name || '/' || TO_CHAR(sysdate)
				|| '/' || TO_CHAR(X_tmp_batch_id),
			sysdate,
			X_currency_code,
			X_currency_code,
			sysdate,
			FND_GLOBAL.user_id,
			FND_GLOBAL.login_id,
			sysdate,
			FND_GLOBAL.user_id
		);
	X_batch_id := X_tmp_batch_id;
EXCEPTION
WHEN others THEN
	IF (g_asn_debug = 'Y') THEN
   	asn_debug.put_line('Error in creating AP Invoice Batch ... ');
	END IF;
       	po_message_s.sql_error('create_ap_batches', x_progress,sqlcode);
	RAISE;
END create_ap_batches;
/*================================================================
  PROCEDURE NAME: 	update_ap_batches()
==================================================================*/
PROCEDURE update_ap_batches( X_batch_id	 IN	NUMBER,
			X_invoice_count	 IN	NUMBER,
			X_invoice_total  IN	NUMBER)
IS
	X_progress   		VARCHAR2(3) := null;
BEGIN
	IF (g_asn_debug = 'Y') THEN
   	asn_debug.put_line('Updating current invoice batch ... ');
	END IF;
	X_progress := '010';
	/* Bug402317. gtummala. 2/13/97
         * We were not populating the control count or the control
         * control total originally. These need to be popluated
         * to be the same as the actual count and actual total.
         */
	UPDATE 	ap_batches
	SET	actual_invoice_count 	= X_invoice_count,
		actual_invoice_total 	= X_invoice_total,
		control_invoice_count   = X_invoice_count,
		control_invoice_total   = X_invoice_total,
		last_updated_by 	= FND_GLOBAL.user_id,
		last_update_date 	= sysdate,
		last_update_login 	= FND_GLOBAL.login_id
	WHERE	batch_id = X_batch_id;
EXCEPTION
WHEN others THEN
	 IF (g_asn_debug = 'Y') THEN
   	 asn_debug.put_line('Error in Updating current invoice batch ... ');
	 END IF;
       	po_message_s.sql_error('update_ap_batches', x_progress,sqlcode);
	RAISE;
END update_ap_batches;
/*================================================================
  PROCEDURE NAME: 	create_invoice_header()
==================================================================*/
PROCEDURE create_invoice_header(X_Invoice_Id 		IN OUT	NOCOPY 	NUMBER,
			X_Vendor_Id			IN	NUMBER,
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
			X_Terms_date		        IN OUT NOCOPY 	DATE,
                     	X_Payment_Method_Lookup_Code    IN      VARCHAR2,
			X_Goods_Received_Date 	        IN	DATE,
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
                  	X_Exchange_Date 		IN	DATE,
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
			X_curr_inv_process_flag		IN OUT	NOCOPY VARCHAR2
			)
IS
	X_progress   		VARCHAR2(3) := NULL;
	X_invoice_description	ap_invoices.description%TYPE;
	X_tmp_invoice_id	NUMBER;
	X_rowid			VARCHAR2(50);
	X_tmp			NUMBER;
	X_doc_category_code	VARCHAR2(30);
        X_doc_sequence_value 	NUMBER;
        X_seq_count     	NUMBER;
	X_seq_num_type  	VARCHAR2(30);
	X_doc_sequence_id	NUMBER;
	X_db_sequence_name	VARCHAR2(50);
        X_Payment_Cross_Rate_Type  VARCHAR2(30) := NULL;
        X_Pay_Cross_Rate        NUMBER := NULL;
        X_Payment_Cross_Rate_Date  DATE := NULL;
        X_Pay_Curr_invoice_Amount  NUMBER;
        e_no_sequence           EXCEPTION;
	-- since this package now called by
	-- ASBN only, we do not need the pay_on_receipt
	-- info to be set
	CURSOR 	c_pay_site IS
	SELECT 	1
	FROM	po_vendor_sites
	WHERE	vendor_site_id = X_vendor_site_id
	AND	pay_site_flag = 'Y'
	AND	NVL(inactive_date, sysdate + 1 ) > sysdate;
	CURSOR	c_invoice IS
	SELECT	1
	FROM	ap_invoices
	WHERE	vendor_id = X_vendor_id
	AND	invoice_num = X_invoice_num;
BEGIN
   IF (g_asn_debug = 'Y') THEN
      asn_debug.put_line('Create Invoice header ... ');
   END IF;
   X_progress := '010';
	/*** Need to check to see if the pay-site is a valid pay-site. **/
   OPEN  c_pay_site;
   FETCH c_pay_site INTO X_tmp;
   IF (c_pay_site%NOTFOUND) THEN
	/*** should be an application error if site is not a valid pay site */
	X_progress := '020';
        IF (g_asn_debug = 'Y') THEN
           asn_debug.put_line('->Error: invalid pay site.');
        END IF;
        po_interface_errors_sv1.handle_interface_errors(
				       X_transaction_type,
				       'FATAL',
				       X_batch_id,   -- batch_id
                                       X_unique_id,  -- header_id
                                       NULL,         -- line_id
                                       'PO_INV_CR_INVALID_PAY_SITE',
                                       'PO_VENDOR_SITES',  -- table_name
                                       'VENDOR_SITE_ID',   -- column_name
                                       'VENDOR_SITE_ID',
                                       null, null, null, null, null,
                                       X_vendor_site_id,
				       null, null, null, null, null,
				       X_curr_inv_process_flag);
   END IF;  /** c_pay_site **/
   CLOSE c_pay_site;
   /*** Next need to verify if the invoice_num specified is unique for
   the vendor. Should be an application error it is not ***/
   X_progress := '030';
   OPEN c_invoice;
   FETCH c_invoice INTO X_tmp;
   IF (c_invoice%FOUND) THEN
	/** call interface error handling routine... duplicate invoice num
	not allowed **/
   	X_progress := '040';
	IF (g_asn_debug = 'Y') THEN
   	asn_debug.put_line('->Error: Duplicate invoice num.');
	END IF;
        po_interface_errors_sv1.handle_interface_errors(
				       X_transaction_type,
				       'FATAL',
				       X_batch_id,   -- batch_id
                                       X_unique_id,  -- header_id
                                       NULL,         -- line_id
                                       'PO_INV_CR_DUPL_INVOICE_NUM',
                                       'AP_INVOICES',  -- table_name
                                       'INVOICE_NUM',   -- column_name
                                       'INVOICE_NUM',
                                       null, null, null, null, null,
                                       X_invoice_num,
				       null, null, null, null, null,
				       X_curr_inv_process_flag);
   END IF;
   CLOSE c_invoice;
   /*** Next Step is to obtain and validate the accounting date ***/
   X_progress := '050';
   BILC_PO_INVOICES_SV1.get_accounting_date_and_period(
			 X_def_gl_dat_fr_rec_flag,
			 X_set_of_books_id,
			 X_invoice_date,
			 X_goods_received_date,
			 X_batch_id,
			 X_transaction_type,
			 X_unique_id,
			 X_accounting_date,
			 X_period_name,
			 X_curr_inv_process_flag);
   IF (X_curr_inv_process_flag = 'Y') THEN
	X_progress := '060';
	SELECT	ap_invoices_s.nextval
	INTO	X_tmp_invoice_id
	FROM	dual;
	X_invoice_id := X_tmp_invoice_id;
	/** use X_tmp_invoice_id when calling insert_row **/
	X_progress := '070';
	IF (X_terms_date_basis = 'Current') THEN
		X_terms_date := sysdate;
	ELSIF (X_terms_date_basis = 'Goods Received') THEN
		X_terms_date := X_goods_received_date;
	ELSIF (X_terms_date_basis = 'Invoice') THEN
		X_terms_date := X_invoice_date;
	ELSIF (X_terms_date_basis = 'Invoice Received') THEN
		X_terms_date := X_invoice_received_date;
	END IF;
	/**** Create the invoice description from a message stored in
	FND_NEW_MESSAGES ***/
	IF (X_source = 'ERS') THEN
	    X_progress := '080';
	    fnd_message.set_name('PO', 'PO_INV_CR_ERS_INVOICE_DESC');
	ELSIF (X_source = 'ASBN') THEN
	    X_progress := '090';
	    fnd_message.set_name('PO', 'PO_INV_CR_ASBN_INVOICE_DESC');
	END IF;
	IF (X_source IN ('ERS', 'ASBN')) THEN
		X_progress := '100';
		fnd_message.set_token('RUN_DATE', fnd_date.date_to_chardate(sysdate));
		X_progress := '110';
		X_invoice_description := fnd_message.get;
	ELSE
		X_invoice_description := X_description;
	END IF;
        /* GTummala. Bug396001. 10/17/95.
         * For prod15 fnd has taken the commit out of thier
         * api (for prod15) to get the seq num. See bug 405545.
         * So now we can get the seq num here and insert the seq num here
         * along with the rest of the header.
         * There is no need to use a wrapper as we did before
         */
        -- BUG 563012 handle partial sequential numbering differently
        X_seq_num_type :=  NVL(FND_PROFILE.VALUE('UNIQUE:SEQ_NUMBERS'),'N');
	/* Bug 3648544.
	 * We had to use date format mask for date conversion. Changed
	 * to use format for to_date usage.
	*/
        SELECT count(*)
         INTO x_seq_count
         FROM FND_DOC_SEQUENCE_ASSIGNMENTS
        WHERE APPLICATION_ID          = 200
          AND CATEGORY_CODE           = 'STD INV'
          AND METHOD_CODE = 'A'
          AND SET_OF_BOOKS_ID = X_Set_Of_Books_Id
          AND to_char(to_date(X_Invoice_Date,'DD-MM-YY'),'J') between
              to_char(trunc(START_DATE),'J') and
             nvl(to_char(trunc(END_DATE),'J'),
                 to_char(to_date(X_Invoice_Date,'DD-MM-YY'),'J'));
        if ((x_seq_num_type = 'N') OR (x_seq_num_type = 'P' and X_seq_count = 0)) then
                  IF (g_asn_debug = 'Y') THEN
                     asn_debug.put_line ('Not using sequential numbering ...');
                  END IF;
                  X_doc_category_code := null;
             	  X_doc_sequence_value:= null;
                  X_doc_sequence_id   := null;
        elsif (X_seq_count > 0) and (x_seq_num_type IN ('P', 'A')) then
       	          X_doc_category_code := 'STD INV';
                  IF (g_asn_debug = 'Y') THEN
                     asn_debug.put_line ('Using sequential numbering ...');
                  END IF;
                  X_doc_sequence_value := fnd_seqnum.get_next_sequence(
      					  		200,
      					  		X_doc_category_code,
					  		X_Set_Of_Books_Id,
        				  		'A',
      					  		X_Invoice_Date,
      					  		X_db_sequence_name,
      					  		X_doc_sequence_id);
            	  IF (g_asn_debug = 'Y') THEN
               	  asn_debug.put_line ('Called the fnd_seqnum.get_next_sequence api');
   	          asn_debug.put_line ('X_doc_sequence_value ='||X_doc_sequence_value);
   	          asn_debug.put_line ('X_db_sequence_name ='||X_db_sequence_name);
            	  END IF;
        else
                  RAISE e_no_sequence;
        end if;
	/*** call object handler to create the invoice header ***/
	X_progress := '120';
	X_rowid := NULL;
        /* bug 612979  supporting fixed currency relationship */
        X_Pay_Curr_Invoice_Amount := X_Invoice_amount;
        X_Pay_cross_rate := X_Payment_Cross_Rate ;
        if (gl_currency_api.is_fixed_rate(X_payment_currency_code, X_invoice_currency_code, X_invoice_date) = 'Y'
            and X_payment_currency_code <> X_invoice_currency_code) then
              IF (g_asn_debug = 'Y') THEN
                 asn_debug.put_line ('Inside is fixed rate currencies.');
              END IF;
              x_pay_cross_rate      := gl_currency_api.get_rate(X_invoice_currency_code,x_payment_currency_code,
                                                                    X_invoice_date, 'EMU FIXED');
              X_Pay_curr_invoice_amount := ap_utilities_pkg.ap_round_currency(
                                                  X_invoice_amount * x_pay_cross_rate,
                                                  X_payment_currency_code);
              X_Payment_Cross_Rate_Type := 'EMU FIXED';
              X_Payment_Cross_Rate_Date := TRUNC(X_invoice_Date);
	      IF (g_asn_debug = 'Y') THEN
   	      asn_debug.put_line ('x_payment_currency_code ='|| x_payment_currency_code);
   	      asn_debug.put_line ('x_invoice_amount ='|| x_invoice_amount);
   	      asn_debug.put_line ('x_pay_cross_rate ='|| x_pay_cross_rate);
   	      asn_debug.put_line ('X_payment_cross_rate Date ='|| X_payment_cross_rate_date);
   	      asn_debug.put_line ('X_pay_curr_invoice_amount ='||X_pay_curr_invoice_amount);
	      END IF;
        end if;
	/* gtummala. 8/28/97
         * AP added 3 new paramters for R11 for cross currency.
         * X_Payment_Cross_Rate_Type, X_Payment_Cross_Rate_Date,
	 * X_Pay_Curr_Invoice_Amount. I added these as the last
	 * parameters with values as suggested by the AP team.
	 */
  	ap_invoices_pkg.insert_row(X_Rowid=>X_Rowid,
                     X_Invoice_Id=>X_tmp_invoice_Id,
                     X_Last_Update_Date=>sysdate,
                     X_Last_Updated_By=>FND_GLOBAL.user_id,
                     X_Vendor_Id=>X_Vendor_Id,
                     X_Invoice_Num=>X_Invoice_Num,
		     X_Invoice_Amount=>X_Invoice_Amount,
                     X_Vendor_Site_Id=>X_Vendor_Site_Id,
                     X_Amount_Paid=>null,
                     X_Discount_Amount_Taken=>null,
                     X_Invoice_Date=>X_Invoice_Date,
                     X_Source=>X_Source,
                     X_Invoice_Type_Lookup_Code=>X_Invoice_Type_Lookup_Code,
                     X_Description=>X_invoice_description,
                     X_Batch_Id=>X_Batch_Id,
                     X_Amt_Applicable_To_Discount=>X_Amt_Applicable_To_Discount,
                     X_Tax_Amount=>X_Tax_Amount,
                     X_Terms_Id=>X_Terms_Id,
                     X_Terms_Date=>X_Terms_Date,
                     X_Payment_Method_Lookup_Code=>X_Payment_Method_Lookup_Code,
                     X_Goods_Received_Date=>X_Goods_Received_Date,
                     X_Invoice_Received_Date=>X_Invoice_Received_Date,
                     X_Voucher_Num=>null,
                     X_Approved_Amount=>null,
                     X_Approval_Status=>X_Approval_Status,
                     X_Approval_Description=>NULL,
                     X_Pay_Group_Lookup_Code=>X_Pay_Group_Lookup_Code,
                     X_Set_Of_Books_Id=>X_Set_Of_Books_Id,
                     X_Accts_Pay_CCId=>X_Accts_Pay_CCID,
                     X_Recurring_Payment_Id=>null,
                     X_Invoice_Currency_Code=>X_Invoice_Currency_Code,
                     X_Payment_Currency_Code=>X_Payment_Currency_Code,
                     X_Exchange_Rate=>X_Exchange_Rate,
                     X_Invoice_Distribution_Total=>null,
                     X_Payment_Amount_Total=>X_Payment_Amount_Total,
                     X_Payment_Status_Flag=>X_Payment_Status_Flag,
                     X_Posting_Status=>X_Posting_Status,
                     X_Authorized_By=>null,
                     X_Attribute_Category=>null,
                     X_Attribute1=>null,
                     X_Attribute2=>null,
                     X_Attribute3=>null,
                     X_Attribute4=>null,
                     X_Attribute5=>null,
                     X_Creation_Date=>sysdate,
                     X_Created_By=>FND_GLOBAL.user_id,
                     X_Vendor_Prepay_Amount=>null,
                     X_Prepay_Flag=>X_Prepay_Flag,
                     X_Base_Amount=>X_Base_Amount,
                     X_Exchange_Rate_Type=>X_Exchange_Rate_Type,
                     X_Exchange_Date=>X_Exchange_Date,
                     X_Payment_Cross_Rate=>X_Pay_Cross_Rate,
                     X_Vat_Code=>X_Vat_Code,
                     X_Last_Update_Login =>FND_GLOBAL.login_id,
                     X_Original_Prepayment_Amount=>null,
                     X_Earliest_Settlement_Date=>null,
                     X_Attribute11=>null,
                     X_Attribute12=>null,
                     X_Attribute13=>null,
                     X_Attribute14=>null,
                     X_Attribute6=>null,
                     X_Attribute7=>null,
                     X_Attribute8=>null,
                     X_Attribute9=>null,
                     X_Attribute10=>null,
                     X_Attribute15=>null,
                     X_Cancelled_Date=>null,
                     X_Cancelled_By=>null,
                     X_Cancelled_Amount=>null,
                     X_Temp_Cancelled_Amount=>null,
                     X_Exclusive_Payment_Flag=>null,
                     X_Po_Header_Id=>null,
                     X_Ussgl_Transaction_Code=>null,
                     X_Ussgl_Trx_Code_Context=>null,
                     X_Doc_Sequence_Id=>X_doc_sequence_id,
                     X_Doc_Sequence_Value=>X_doc_sequence_value,
                     X_Doc_Category_Code=>X_doc_category_code,
                     X_Freight_Amount=>X_Freight_Amount,
                     X_Expenditure_Item_Date=>null,
                     X_Expenditure_Organization_Id=>null,
                     X_Expenditure_Type=>null,
                     X_Pa_Default_Dist_Ccid=>null,
                     X_Pa_Quantity=>null,
                     X_Project_Id=>null,
                     X_Project_Accounting_Context=>null,
                     X_Task_Id=>null,
		     X_Awt_Flag=>'N',
		     X_Awt_Group_Id=>X_awt_group_id,
                     X_Reference_1=>X_reference_1,
                     X_Reference_2=>X_reference_2,
/* 1314128 WIll pass value 'L' to X_Auto_Tax_Calc_Flag
  for Invoice Approval program to compare tax at line level*/
		     X_Auto_Tax_Calc_Flag=>'L', -- X_Auto_Tax_Calc_Flag
                     X_Org_Id=>X_Org_Id,
		     X_calling_sequence=>'CREATE_INVOICE_HEADER',
                     X_Payment_Cross_Rate_Type =>X_Payment_Cross_Rate_Type,
                     X_Payment_Cross_Rate_Date =>X_Payment_Cross_Rate_Date,
		     X_Pay_Curr_Invoice_Amount =>X_Pay_Curr_Invoice_Amount,
		     /**** new parameters for R115 ***/
		     X_gl_date	=> x_accounting_date,
		     X_Award_Id	=> null
                     );
   IF (g_asn_debug = 'Y') THEN
      asn_debug.put_line('Invoice created...  Invoice_id =  ' || to_char(X_tmp_invoice_id));
   END IF;
   END IF;  -- curr_inv_process_flag
EXCEPTION
WHEN e_no_sequence THEN
      IF (g_asn_debug = 'Y') THEN
         asn_debug.put_line ('No sequence defined for sequential numbering! ');
      END IF;
      RAISE;
WHEN others THEN
      IF (g_asn_debug = 'Y') THEN
         asn_debug.put_line('Error in creating invoice header ...') ;
      END IF;
      po_message_s.sql_error('create_invoice_header', x_progress,sqlcode);
      RAISE;
END create_invoice_header;
/* =====================================================================
   PROCEDURE	get_accounting_date_and_period
======================================================================== */
PROCEDURE  get_accounting_date_and_period(
			 X_def_gl_dat_fr_rec_flag        IN	VARCHAR2,
		         X_def_sets_of_books_id	         IN	NUMBER,
		         X_invoice_date		         IN 	DATE,
		         X_receipt_date		         IN	DATE,
			 X_batch_id			 IN	NUMBER,
			 X_transaction_type		 IN	VARCHAR2,
			 X_unique_id			 IN	NUMBER,
                         X_accounting_date               OUT NOCOPY    DATE,
                         X_period_name                   OUT NOCOPY    VARCHAR2,
			 X_curr_inv_process_flag	 IN OUT NOCOPY VARCHAR2 )
IS
	X_progress   		VARCHAR2(3) := null;
	X_temp_accounting_date	DATE;
	X_temp_period_name	gl_period_statuses.period_name%TYPE;
	CURSOR c_period IS
	SELECT		period_name
	FROM		gl_period_statuses gps
	WHERE		gps.application_id = 200   /*** Payables ***/
	AND		gps.set_of_books_id = X_def_sets_of_books_id
	AND		gps.adjustment_period_flag = 'N'
	AND		X_temp_accounting_date
	BETWEEN 	gps.start_date AND gps.end_date
	AND		gps.closing_status IN ('O', 'F');
			/*** period would be an OPEN or FUTURE one ***/
BEGIN
	x_progress := '010';
	IF (X_def_gl_dat_fr_rec_flag = 'I') THEN
		/*** GL Date = 'Invoice' ***/
		X_temp_accounting_date := X_invoice_date;
	ELSIF (X_def_gl_dat_fr_rec_flag = 'S') THEN
		/*** GL Date = 'System' ***/
		X_temp_accounting_date := sysdate;
	ELSIF (X_def_gl_dat_fr_rec_flag = 'N') THEN
		/*** GL Date = 'Receipt-Invoice' ***/
		X_temp_accounting_date := NVL(X_receipt_date, X_invoice_date);
	ELSIF (X_def_gl_dat_fr_rec_flag = 'Y') THEN
		/*** GL Date = 'Receipt-System ***/
		X_temp_accounting_date := NVL(X_receipt_date, sysdate);
	END IF;
        /* bug 657365, need to truncate the accounting date before we pass into the cursor
           to determine if period is open or not */
        x_temp_accounting_date := trunc(x_temp_accounting_date);
	/*** need some way to signal an error if accounting date is NULL ***/
	X_progress := '020';
	/*** Next find out the period name for the accounting date: ***/
	X_temp_period_name := NULL;
	OPEN  c_period;
	FETCH c_period INTO X_temp_period_name;
	CLOSE c_period;
	X_progress := '030';
	If (X_temp_period_name IS NULL) THEN
		/*** accounting date used does not fall into an open
		or future accounting period. ***/
		X_progress := '040';
		 IF (g_asn_debug = 'Y') THEN
   		 asn_debug.put_line('->Error: Invalid acctg date.');
		 END IF;
        	po_interface_errors_sv1.handle_interface_errors(
					       X_transaction_type,
					       'FATAL',
					       X_batch_id,
                                               X_unique_id,  -- header_id
                                               null,	     -- line_id
                                               'PO_INV_CR_INVALID_GL_PERIOD',
                                               'GL_PERIOD_STATUSES',
                                               'PERIOD_NAME',
                                               'GL_DATE',
                                               null, null, null, null, null,
                                               fnd_date.date_to_chardate(X_temp_accounting_date),
                                               null,null,null,null,null,
						X_curr_inv_process_flag);
	ELSE
	       X_progress := '050';
	       IF (g_asn_debug = 'Y') THEN
   	       asn_debug.put_line('Acctg Date = ' ||TO_CHAR(X_temp_accounting_date));
	       END IF;
	       X_accounting_date := X_temp_accounting_date;
	       X_period_name 	 := X_temp_period_name;
	END IF;
EXCEPTION
WHEN others THEN
	po_message_s.sql_error('get_accounting_date_and_period',
		x_progress, sqlcode);
	RAISE;
END get_accounting_date_and_period;
/********************************************************************/
/*                                                                  */
/* PROCEDURE  create_invoice_distributions		            */
/*                                                                  */
/********************************************************************/
PROCEDURE create_invoice_distributions(X_invoice_id 		IN NUMBER,
				  X_invoice_currency_code 	IN VARCHAR2,
				  X_base_currency_code  	IN VARCHAR2,
				  X_batch_id 			IN NUMBER,
				  X_pay_site_id 		IN NUMBER,
				  X_po_header_id 		IN NUMBER,
				  X_po_line_id 			IN NUMBER,
				  X_po_line_location_id 	IN NUMBER,
				  X_receipt_event 		IN VARCHAR2,
				  X_po_distribution_id 		IN NUMBER,
		       /*X_receipt_event and X_po_distribution_id
		       used only for DELIVER transactions*******/
				  X_item_description 		IN VARCHAR2,
				  X_type_1099 			IN VARCHAR2,
				  X_tax_name 			IN VARCHAR2,
				  X_tax_code_id			IN NUMBER,
				  X_tax_amount 			IN NUMBER,
		       /*This will be populated only for shipment
		       and bill notices; for the other cases tax
		       amount will be calculated****************/
				  X_create_tax_dist_flag 	IN VARCHAR2,
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
				  X_quantity 			IN NUMBER,
				  X_unit_price 			IN NUMBER,
				  X_exchange_rate_type 		IN VARCHAR2,
				  X_exchange_date 		IN DATE,
				  X_exchange_rate 		IN NUMBER,
				  X_accts_pay_code_comb_id 	IN NUMBER,
				  X_def_gl_dat_fr_rec_flag 	IN VARCHAR2,
				  X_def_sets_of_books_id 	IN NUMBER,
				  X_invoice_date 		IN DATE,
				  X_receipt_date 		IN DATE,
				  X_def_income_tax_region_flag  IN VARCHAR2,
				  X_def_income_tax_region 	IN VARCHAR2,
				  X_vendor_income_tax_region 	IN VARCHAR2,
				  X_reference_1			IN VARCHAR2,
				  X_reference_2			IN VARCHAR2,
				  X_def_transfer_desc_flex_flag	IN VARCHAR2,
				  X_awt_flag			IN VARCHAR2,
				  X_awt_group_id		IN NUMBER,
				  X_accounting_date		IN DATE,
				  X_period_name			IN VARCHAR2,
				  X_transaction_type		IN VARCHAR2,
				  X_unique_id			IN NUMBER,
                                  X_def_awt_include_tax_amt     IN VARCHAR2,
				  X_curr_invoice_amount 	IN OUT NOCOPY   NUMBER,
				  X_curr_tax_amount 		IN OUT NOCOPY NUMBER,
                                  X_curr_inv_process_flag 	IN OUT NOCOPY VARCHAR2,
                                  X_base_amount1                IN OUT NOCOPY NUMBER )
               IS
/*** Cursor Declaration ***/
/* to get the account type, we should look for charge account.
Bug 892962 bgopired */
CURSOR c_po_distributions(X_po_header_id        NUMBER,
			      X_po_line_id           NUMBER,
			      X_po_line_location_id  NUMBER,
			      X_receipt_event        VARCHAR2,
			      X_po_distribution_id   NUMBER,
			      X_def_transfer_desc_flex_flag VARCHAR2
			)
IS
  SELECT   pod.po_distribution_id,
	   pod.set_of_books_id,
	   pod.code_combination_id,
	   DECODE(gcc.account_type, 'A','Y','N') assets_tracking_flag,
	   NVL(pod.quantity_ordered,0) quantity_remaining,
	   pod.rate,
	   pod.rate_date,
	   pod.variance_account_id,
	   DECODE(X_def_transfer_desc_flex_flag, 'Y', pod.attribute_category,
			NULL) attribute_category,
	   DECODE(X_def_transfer_desc_flex_flag, 'Y', pod.attribute1, NULL)
			attribute1,
	   DECODE(X_def_transfer_desc_flex_flag, 'Y', pod.attribute2, NULL)
			attribute2,
	   DECODE(X_def_transfer_desc_flex_flag, 'Y', pod.attribute3, NULL)
			attribute3,
	   DECODE(X_def_transfer_desc_flex_flag, 'Y', pod.attribute4, NULL)
			attribute4,
	   DECODE(X_def_transfer_desc_flex_flag, 'Y', pod.attribute5, NULL)
			attribute5,
	   DECODE(X_def_transfer_desc_flex_flag, 'Y', pod.attribute6, NULL)
			attribute6,
	   DECODE(X_def_transfer_desc_flex_flag, 'Y', pod.attribute7, NULL)
			attribute7,
	   DECODE(X_def_transfer_desc_flex_flag, 'Y', pod.attribute8, NULL)
			attribute8,
	   DECODE(X_def_transfer_desc_flex_flag, 'Y', pod.attribute9, NULL)
			attribute9,
	   DECODE(X_def_transfer_desc_flex_flag, 'Y', pod.attribute10, NULL)
			attribute10,
	   DECODE(X_def_transfer_desc_flex_flag, 'Y', pod.attribute11, NULL)
			attribute11,
	   DECODE(X_def_transfer_desc_flex_flag, 'Y', pod.attribute12, NULL)
			attribute12,
	   DECODE(X_def_transfer_desc_flex_flag, 'Y', pod.attribute13, NULL)
			attribute13,
	   DECODE(X_def_transfer_desc_flex_flag, 'Y', pod.attribute14, NULL)
			attribute14,
	   DECODE(X_def_transfer_desc_flex_flag, 'Y', pod.attribute15, NULL)
			attribute15,
	   pod.project_id,	-- the following are PA related columns
	   pod.task_id,
	   pod.expenditure_item_date,
	   pod.expenditure_type,
	   pod.expenditure_organization_id,
	   pod.project_accounting_context
  FROM     gl_code_combinations    gcc,
	   po_distributions_ap_v   pod
  WHERE    pod.po_header_id        = X_po_header_id
  AND      pod.po_line_id          = X_po_line_id
  AND      pod.line_location_id = X_po_line_location_id
  AND	   pod.original_charge_account_id = gcc.code_combination_id
  AND      DECODE(X_receipt_event, 'DELIVER', pod.po_distribution_id, 1)=
	   DECODE(X_receipt_event, 'DELIVER', X_po_distribution_id, 1)
  ORDER BY pod.distribution_num;
/**** Variable declarations ****/
X_rowid                VARCHAR2(50);
X_po_distributions     c_po_distributions%ROWTYPE;
X_invoice_distribution_id NUMBER;
X_curr_qty             NUMBER;      /*Qty billed to a particular dist*/
X_curr_amount	       NUMBER;
X_temp_tax_amount      NUMBER;
X_sum_order_qty        NUMBER;      /*Used when proration is used*/
X_count                NUMBER:=0;   /*Num of distrs for that receive txn*/
X_tmp_count            NUMBER;
X_total_amount	       NUMBER;
X_amount_running_total    NUMBER;
X_tax_amount_for_proration NUMBER;
X_tax_rate	       NUMBER;
X_tax_running_total    NUMBER;
X_income_tax_region    ap_invoice_distributions.income_tax_region%TYPE;
X_assets_addition_flag VARCHAR2(1);
X_new_dist_line_number ap_invoice_distributions.distribution_line_number%TYPE;
X_base_amount		NUMBER ;
X_temp_base_amount      NUMBER := 0; -- 1500661
X_progress		VARCHAR2(4) := '';
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
	    SUM(NVL(quantity_ordered,0))
	       /***Amount remaining for each po distribution***/
 INTO       X_count,
	    X_sum_order_qty
 FROM       po_distributions
 WHERE      po_header_id        = X_po_header_id
 AND        po_line_id          = X_po_line_id
 AND        line_location_id = X_po_line_location_id
 AND        DECODE(X_receipt_event, 'DELIVER', po_distribution_id,1)=
	    DECODE(X_receipt_event, 'DELIVER', X_po_distribution_id,1);
IF (X_count > 0) THEN
   X_progress := '020';
   X_total_amount := ap_utilities_pkg.ap_round_currency(
				X_quantity * X_unit_price,
				X_invoice_currency_code);
   X_tmp_count             := 0;
   X_amount_running_total  := 0;
   X_tax_running_total     := 0;
   X_progress := '030';
   IF ((X_tax_name IS NOT NULL) OR (X_tax_code_id IS NOT NULL)) THEN
	/*** need to calculate tax .... proration is required. ***/
	IF (X_tax_amount IS NOT NULL) THEN
		X_progress := '018';
		X_tax_amount_for_proration := X_tax_amount;
	ELSE
	    IF X_tax_code_id IS NOT NULL then
  	       X_progress := '040';
	       SELECT tax_rate
		 INTO X_tax_rate
		 FROM ap_tax_codes
		WHERE tax_id = x_tax_code_id;
            ELSE
  	       SELECT tax_rate
	         INTO X_tax_rate
	         FROM ap_tax_codes
	        WHERE name = X_tax_name;
	    END IF;
	    X_progress := '050';
	    -- bug 805420, should not round currency here, create tax distribution
	    -- will round instead
	    X_tax_amount_for_proration := X_tax_rate / 100
					    * X_quantity * X_unit_price;
	END IF;
   ELSE
	X_tax_amount_for_proration := NULL;
   END IF;
   X_progress := '060';
   OPEN  c_po_distributions(X_po_header_id,
                            X_po_line_id,
                            X_po_line_location_id,
                            X_receipt_event,
                            X_po_distribution_id,
			    X_def_transfer_desc_flex_flag
			);
   X_progress := '070';
   LOOP
   X_progress := '080';
   FETCH  c_po_distributions INTO  X_po_distributions;
   EXIT WHEN  c_po_distributions%NOTFOUND;
      X_progress := '090';
      X_tmp_count := X_tmp_count + 1;
      X_curr_qty:= (X_quantity * X_po_distributions.quantity_remaining)
				       /X_sum_order_qty;
      IF (X_tmp_count <> X_count) THEN
		 /***Prorate the qty across the distributions for all
		     the distributions except the last one.   ******/
         X_progress := '100';
	 X_curr_amount := ap_utilities_pkg.ap_round_currency(
				 X_curr_qty * X_unit_price,
				 X_invoice_currency_code);
	 X_amount_running_total:= X_amount_running_total + X_curr_amount;
	 IF (X_tax_amount_for_proration IS NOT NULL) THEN
	    /***tax amount already supplied,
		so we have to prorate the tax amount.*/
             X_progress := '110';
   	     -- bug 805420, should not round currency here, create tax distribution
	     -- will round instead
	     X_temp_tax_amount := X_tax_amount_for_proration *
					X_po_distributions.quantity_remaining
					/ X_sum_order_qty;
	     X_tax_running_total := X_tax_running_total +
				   X_temp_tax_amount;
	 ELSE
	     X_temp_tax_amount := NULL;
	 END IF; -- tax_amount
     ELSE   -- the last record
	  /***In this way, we will be able to handle rounding errors by
	      assigning the round up/down amount to the last distribution***/
          X_progress := '120';
	  X_curr_amount := X_total_amount - X_amount_running_total;
	  /***Again we have to handle the tax amount if supplied***/
	 IF (X_tax_amount_for_proration IS NOT NULL) THEN
                X_progress := '130';
		X_temp_tax_amount := X_tax_amount_for_proration
					- X_tax_running_total;
	 ELSE
		X_temp_tax_amount := NULL;
	 END IF;
     END IF;  -- tmp_count <> count
      X_progress := '140';
      IF (X_curr_inv_process_flag = 'Y') THEN
	/** continue only if invoice is still processable **/
      	X_progress := '150';
      	IF (X_type_1099 IS NOT NULL) THEN
	 /***Type_1099 info defaults from the vendor level***/
	 /***Income tax region can be entered only if the vendor
	     has income tax type set up***/
	 	IF (X_def_income_tax_region_flag = 'Y') THEN
	    	    /**Use vendor site's tax region as the income tax region**/
	    		X_income_tax_region := X_vendor_income_tax_region;
	 	ELSE
	    	    /**Use system options**/
	    		X_income_tax_region := X_def_income_tax_region;
	 	END IF;
      	ELSE
	 	X_income_tax_region := NULL;
      	END IF;
      	/**Determine the distribution line number for the new record***/
     	X_progress := '160';
	SELECT NVL(MAX(distribution_line_number), 0) + 1
      	INTO   X_new_dist_line_number
      	FROM   ap_invoice_distributions
      	WHERE  invoice_id = X_invoice_id;
      	X_progress := '130';
	IF (X_invoice_currency_code = X_base_currency_code) THEN
		X_base_amount := NULL;
	ELSE
		X_base_amount := ap_utilities_pkg.ap_round_currency(
						X_curr_amount * X_exchange_rate,
						X_base_currency_code);
	END IF;
      	/*** call object handler to create the item distributions ***/
      	X_progress := '140';
	IF (g_asn_debug = 'Y') THEN
   	asn_debug.put_line('Creating Item Distribution...');
	END IF;
      	X_rowid := NULL;
        /* Bug:559224. gtummala. 10/27/97.
	 * Accounting date should not have a non-zero time stamp. Ie it should
         * be 00:00:00. So truncate the X_accounting_date.
         */
	ap_invoice_distributions_pkg.insert_row(
				     X_Rowid=>X_rowid,
				     X_Invoice_Id=>X_invoice_id,
				     X_Invoice_Distribution_Id=> X_invoice_distribution_id,
				     X_Dist_Code_Combination_Id=>X_po_distributions.code_combination_id,
				     X_Last_Update_Date=>sysdate,
				     X_Last_Updated_By=>FND_GLOBAL.user_id,
				     X_Accounting_Date=>trunc(X_accounting_date),
							         /* Bug:559224 */
				     X_Period_Name=>X_period_name,
				     X_Set_Of_Books_Id=>X_po_distributions.set_of_books_id,
				     X_Amount=>X_curr_amount,
				     X_Description=>X_item_description,
				     X_Type_1099=>X_type_1099,
				     X_tax_code_id=> X_tax_code_id,  -- :DEBUG  X_Vat_Code=>X_tax_name,
				     X_Posted_Flag=>'N',
				     X_Batch_Id=>X_batch_id,
				     X_Quantity_Invoiced=>X_curr_qty,
				     X_Unit_Price=>X_unit_price,
				     X_Match_Status_Flag=>NULL,	-- match status flag
				     X_Attribute_Category=>X_po_distributions.attribute_category,
				     X_Attribute1=>X_po_distributions.attribute1,
				     X_Attribute2=>X_po_distributions.attribute2,
				     X_Attribute3=>X_po_distributions.attribute3,
				     X_Attribute4=>X_po_distributions.attribute4,
				     X_Attribute5=>X_po_distributions.attribute5,
				     X_Prepay_Amount_Remaining=>NULL,
				     X_Assets_Addition_Flag=>'U',
				     X_Assets_Tracking_Flag=>X_po_distributions.assets_tracking_flag,
				     X_Distribution_Line_Number=>X_new_dist_line_number,
				     X_Line_Type_Lookup_Code=>'ITEM',
				     X_Po_Distribution_Id=>X_po_distributions.po_distribution_id,
				     X_Base_Amount=>X_base_amount,
				     X_Exchange_Rate=>X_exchange_rate,
				     X_Exchange_Rate_Type=>X_exchange_rate_type,
				     X_Exchange_Date=>X_exchange_date,
				     X_Pa_Addition_Flag=>'N',
				     X_Je_Batch_Id=>NULL,
				     X_Posted_Amount=>NULL,
				     X_Posted_Base_Amount=>NULL,
				     X_Encumbered_Flag=>'N',
				     X_Accrual_Posted_Flag=>'N',
				     X_Cash_Posted_Flag=>'N',
				     X_Last_Update_Login=>FND_GLOBAL.login_id,
				     X_Creation_Date=>sysdate,
				     X_Created_By=>FND_GLOBAL.user_id,
				     X_Cash_Je_Batch_Id=>NULL,
				     X_Stat_Amount=>NULL,
				     X_Attribute11=>X_po_distributions.attribute11,
				     X_Attribute12=>X_po_distributions.attribute12,
				     X_Attribute13=>X_po_distributions.attribute13,
				     X_Attribute14=>X_po_distributions.attribute14,
				     X_Attribute6=>X_po_distributions.attribute6,
				     X_Attribute7=>X_po_distributions.attribute7,
				     X_Attribute8=>X_po_distributions.attribute8,
				     X_Attribute9=>X_po_distributions.attribute9,
				     X_Attribute10=>X_po_distributions.attribute10,
				     X_Attribute15=>X_po_distributions.attribute15,
				     X_Accts_Pay_Code_Comb_Id=>NULL, -- liability acct
				     X_Rate_Var_Code_Combination_Id=>NULL,
				     X_Price_Var_Code_Comb_Id=>X_po_distributions.variance_account_id,
				     X_Exchange_Rate_Variance=>NULL,
				     X_Invoice_Price_Variance=>NULL,
				     X_Base_Invoice_Price_Variance=>NULL,
				     X_Reversal_Flag=>NULL,
				     X_Parent_Invoice_Id=>NULL,
				     X_Income_Tax_Region=>X_income_tax_region,
				     X_Final_Match_Flag=>'N',
				     X_Ussgl_Transaction_Code=>NULL,
				     X_Ussgl_Trx_Code_Context=>NULL,
			       	     X_Expenditure_Item_Date=>X_po_distributions.expenditure_item_date,
				     X_Expenditure_Organization_Id=>X_po_distributions.expenditure_organization_id,
				     X_Expenditure_Type=>X_po_distributions.expenditure_type,
				     X_Pa_Quantity=>X_curr_qty,  --  pa_qty
				     X_Project_Id=>X_po_distributions.project_id,
				     X_Task_Id=>X_po_distributions.task_id,
				     X_Project_Accounting_Context=>X_po_distributions.project_accounting_context,
				     X_Quantity_Variance=>NULL,
				     X_Base_Quantity_Variance=>NULL,
				     X_Packet_Id=>NULL,
				     X_Awt_Flag=>X_awt_flag,
				     X_Awt_Group_Id=>X_awt_group_id,
				     X_Awt_Tax_Rate_Id=>NULL,
				     X_Awt_Gross_Amount=>NULL,
				     X_Reference_1=>X_reference_1,
				     X_Reference_2=>X_reference_2,
				     X_Org_Id=>NULL,
				     X_Other_Invoice_Id=>NULL,
				     X_Awt_Invoice_Id=>NULL,
				     X_Awt_Origin_Group_Id=>NULL,
				     X_Program_Application_Id=>FND_GLOBAL.prog_appl_id,
				     X_Program_Id=>FND_GLOBAL.conc_program_id,
                                     X_Program_Update_Date=>sysdate,
				     X_Request_Id=>FND_GLOBAL.conc_request_id,
				     X_Amount_Includes_Tax_Flag=>NULL,       --X_Amount_Includes_Tax_Flag
				     X_Tax_Code_Override_Flag => NULL,
				     X_Tax_Recovery_Rate	=> NULL,
				     X_Tax_Recovery_Override_Flag	=> NULL,
				     X_Tax_Recoverable_Flag           => NULL,
				     X_Award_Id                       => NULL,
				     X_Start_Expense_Date             => NULL,
				     X_Merchant_Document_Number       => NULL,
				     X_Merchant_Name                  => NULL,
				     X_Merchant_Tax_Reg_Number        => NULL,
				     X_Merchant_Taxpayer_Id           => NULL,
				     X_Country_Of_Supply              => NULL,
				     X_Merchant_Reference             => NULL,
				     X_parent_reversal_id		=> NULL,
				     X_rcv_transaction_id		=> NULL,
				     X_matched_uom_lookup_code	=> NULL,
				     X_global_attribute_category      =>NULL,
				     X_global_attribute1              =>NULL,
				     X_global_attribute2              =>NULL,
				     X_global_attribute3              =>NULL,
				     X_global_attribute4              =>NULL,
				     X_global_attribute5              =>NULL,
				     X_global_attribute6              =>NULL,
				     X_global_attribute7              =>NULL,
				     X_global_attribute8              =>NULL,
				     X_global_attribute9              =>NULL,
				     X_global_attribute10             =>NULL,
				     X_global_attribute11             =>NULL,
				     X_global_attribute12             =>NULL,
				     X_global_attribute13             =>NULL,
				     X_global_attribute14             =>NULL,
				     X_global_attribute15             =>NULL,
				     X_global_attribute16             =>NULL,
				     X_global_attribute17             =>NULL,
				     X_global_attribute18             =>NULL,
				     X_global_attribute19             =>NULL,
				     X_global_attribute20             =>NULL,
				     X_Calling_Sequence=>'CREATE ITEM DISTR');
  /* Bug# 1500661 */
     X_progress := '140a';
     select Base_Amount
     into X_temp_base_amount
     from ap_invoice_distributions
     where invoice_id=X_invoice_id
     and Distribution_Line_Number = X_new_dist_line_number;
      	/**UPDATE CURRENT INVOICE AMOUNT**/
      	X_progress := '150';
      	X_curr_invoice_amount:= X_curr_invoice_amount +
			      		X_curr_amount ;
        X_base_amount1 := X_base_amount1 + X_temp_base_amount;
      	IF (X_create_tax_dist_flag= 'Y' ) AND
	     ((X_tax_name IS NOT NULL) OR (X_tax_code_id IS NOT NULL))THEN
	   /** The first is to make sure we have to create tax distributions
            for individual invoice distribution lines (X_create_tax_dist_flag)*/
	    /*** Process tax distributions. X_curr_invoice_amount and
		X_curr_tax_amount will be updated accordingly. ***/
	    X_progress := '160';
	    IF (g_asn_debug = 'Y') THEN
   	    asn_debug.put_line('Create tax distribution lines ... ');
	    END IF;
            BILC_PO_INVOICES_SV1.create_tax_distributions(
					     X_invoice_id,
					     X_invoice_currency_code,
					     X_base_currency_code,
					     X_batch_id,
					     X_pay_site_id,
					     X_accounting_date,
					     X_period_name,
					     X_tax_name,
					     X_tax_code_id,
					     X_temp_tax_amount,
					     X_curr_amount,
					     X_exchange_rate_type,
					     X_exchange_date,
					     X_exchange_rate,
					     X_type_1099,
					     X_income_tax_region,
					     'N',
					     X_def_sets_of_books_id,
					     X_accts_pay_code_comb_id,
					     X_awt_flag,
					     X_awt_group_id,
					     X_transaction_type,
					     X_unique_id,
                                             X_def_awt_include_tax_amt,
					     X_curr_invoice_amount,
					     X_curr_tax_amount,
					     X_curr_inv_process_flag,
                                             X_base_amount1);
      END IF;
      /**Make sure po_distributions is updated accordingly**/
      IF (X_curr_inv_process_flag = 'Y') THEN
	/*** first need to make sure no applicable error occurred. **/
      	X_progress := '170';
      	UPDATE po_distributions
      	SET    	quantity_billed   = NVL(quantity_billed,0) + X_curr_qty,
	     	amount_billed     = NVL(amount_billed,0) +
					X_curr_amount,
	     	last_updated_by   = FND_GLOBAL.user_id,
	     	last_update_date  = sysdate,
	     	last_update_login = FND_GLOBAL.login_id
      	WHERE  po_distribution_id = X_po_distributions.po_distribution_id;
      END IF;
   END IF; -- X_curr_inv_process_flag
   X_progress := '180';
   END LOOP;
   CLOSE c_po_distributions;
   /**Shipment Line needs to be updated accordingly***/
   IF (X_curr_inv_process_flag = 'Y') THEN
   	X_progress := '190';
   	UPDATE   po_line_locations
   	SET      quantity_billed = NVL(quantity_billed,0) + X_quantity,
	    	 last_updated_by = FND_GLOBAL.user_id,
	    	 last_update_date = sysdate,
	    	 last_update_login = FND_GLOBAL.login_id
   	WHERE    line_location_id = X_po_line_location_id;
    END IF;
ELSE /** X_count = 0, this should be an error we should have atleast one
		      distribution for our rcv. txn.**/
        	po_interface_errors_sv1.handle_interface_errors(
				X_transaction_type,
                                'FATAL',
				 X_batch_id,
				 X_unique_id,   -- header_id
				 NULL,		-- line_id
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
/**************************************************************************/
/*                                                                        */
/* PROCEDURE  	create_tax_distributions				  */
/*                                                                        */
/**************************************************************************/
PROCEDURE create_tax_distributions(
                                     X_invoice_id               NUMBER,
				     X_invoice_currency_code	VARCHAR2,
				     X_base_currency_code	VARCHAR2,
			             X_batch_id	                NUMBER,
                                     X_pay_site_id              NUMBER,
                                     X_accounting_date          DATE,
                                     X_period_name              VARCHAR2,
                                     X_tax_name                 VARCHAR2,
                                     X_tax_code_id              NUMBER,
                                     X_tax_amount               VARCHAR2,
                         /*This parameter will be NOT NULL only for the case of
                           ship bill notices, where tax amount is already
                          supplied in the shipment lines**/
                                     X_taxable_amount           NUMBER,
                                /**Amount which is to be taxed**/
                                     X_exchange_rate_type       VARCHAR2,
                                     X_exchange_date            DATE,
                                     X_exchange_rate            NUMBER,
                                     X_type_1099                VARCHAR2,
                                     X_income_tax_region        VARCHAR2,
                                     X_assets_tracking_flag     VARCHAR2,
                                     X_def_sets_of_books_id     NUMBER,
                                     X_accts_pay_combination_id NUMBER,
				     X_awt_flag			VARCHAR2,
				     X_awt_group_id		NUMBER,
				     X_transaction_type		IN VARCHAR2,
				     X_unique_id		IN NUMBER,
                                     X_def_awt_include_tax_amt  IN VARCHAR2,
                                     X_curr_invoice_amount      IN OUT NOCOPY NUMBER,
                                     X_curr_tax_amount          IN OUT NOCOPY NUMBER,
				     X_curr_inv_process_flag	IN OUT NOCOPY VARCHAR2,
				     X_base_amount1             IN OUT NOCOPY NUMBER  )
   IS
/**** variable declarations ****/
X_progress		   VARCHAR2(4) := '';
X_rowid                    VARCHAR2(50);
X_tax_rate                 ap_tax_codes.tax_rate%TYPE;
X_tax_type                 ap_tax_codes.tax_type%TYPE;
X_tax_code_combination_id  ap_tax_codes.tax_code_combination_id%TYPE;
X_new_dist_line_number     ap_invoice_distributions.distribution_line_number%TYPE;
X_temp_tax_amount          NUMBER := 0;
X_base_tax_amount	   NUMBER;
X_base_offset_tax_amount   NUMBER;
X_temp_offset_tax_amount   NUMBER := 0;
X_temp_taxable_amount	   NUMBER;
X_count                    NUMBER;
X_offset_tax_code          ap_tax_codes.name%TYPE;
X_offset_tax_rate	   ap_tax_codes.tax_rate%TYPE;
X_offset_tax_ccid	   NUMBER;
X_offset_tax_code_id	   ap_tax_codes.tax_id%TYPE;
X_create_offset_flag	   VARCHAR2(1);
X_rounding_rule		   VARCHAR2(1);   -- for bug 777775
X_curr_awt_group_id        ap_invoice_distributions.awt_group_id%TYPE := X_awt_group_id;
X_curr_awt_flag            ap_invoice_distributions.awt_flag%TYPE := X_awt_flag;
X_invoice_distribution_id NUMBER;
X_tax_description          ap_tax_codes.description%TYPE; --bug 1333115
X_offset_tax_description   ap_tax_codes.description%TYPE; --bug 1333115
X_temp_tax_base_amount     NUMBER := 0; -- bug# 1500661
X_temp_tax_base_offset     NUMBER := 0; -- bug# 1500661
        /*==================================================================**/
       	/**The following function will return 'Y' if offset tax distribution
		is to be created; 'N' otherwise. **/
        FUNCTION det_if_offset_tax_req(X_tax_name IN VARCHAR2,
					X_pay_site_id IN NUMBER,
					X_offset_tax_name OUT NOCOPY VARCHAR2,
					X_offset_tax_code_id  OUT NOCOPY NUMBER,
					X_offset_tax_rate OUT NOCOPY NUMBER,
					X_offset_tax_ccid OUT NOCOPY NUMBER
				)
        RETURN VARCHAR2 IS
                    X_tmp_tax_name  	ap_tax_codes.name%TYPE;
		X_tmp_offset_tax_name 	ap_tax_codes.name%TYPE;
		X_tmp_offset_tax_rate	ap_tax_codes.tax_rate%TYPE;
		x_tmp_offset_tax_code_id ap_tax_codes.tax_id%TYPE;
		X_tmp_offset_tax_ccid	ap_tax_codes.tax_code_combination_id%TYPE;
		X_progress	VARCHAR2(3);
        BEGIN
	     	X_progress := '010';
		/** find out if an offset tax code is defined at the vendor
		site. ***/
		SELECT 	pvss.vat_code,
			pvss.offset_vat_code,
			aptc.tax_id,
			aptc.tax_rate,
			aptc.tax_code_combination_id
		INTO	X_tmp_tax_name,
			X_tmp_offset_tax_name,
			X_tmp_offset_tax_code_id,
			X_tmp_offset_tax_rate,
			X_tmp_offset_tax_ccid
		FROM	ap_tax_codes  aptc,
			po_vendor_sites pvss
		WHERE	pvss.offset_vat_code = aptc.name (+)
		AND	pvss.vendor_site_id = X_pay_site_id;
	     	X_progress := '020';
		IF (X_tax_name = X_tmp_tax_name) AND
		   (X_tmp_offset_tax_name IS NOT NULL) THEN
			X_offset_tax_name := X_tmp_offset_tax_name;
			X_offset_tax_rate := X_tmp_offset_tax_rate;
			X_offset_tax_ccid := X_tmp_offset_tax_ccid;
			X_offset_tax_code_id := X_tmp_offset_tax_code_id;
			RETURN ('Y');
		ELSE
			X_offset_tax_name := NULL;
			X_offset_tax_rate := NULL;
			X_offset_tax_ccid := NULL;
			X_offset_tax_code_id := NULL;
			RETURN ('N');
		END IF;
	EXCEPTION
	WHEN OTHERS THEN
	    IF (g_asn_debug = 'Y') THEN
   	    asn_debug.put_line('Errr in getting offset tax code...');
	    END IF;
       	    po_message_s.sql_error('det_if_offset_tax_req', x_progress,
					sqlcode);
            RAISE;
        END det_if_offset_tax_req;
     /**====================================================================**/
BEGIN
IF (g_asn_debug = 'Y') THEN
   asn_debug.put_line('Creating Tax Distribution ... ');
END IF;
X_progress := '010';
/* bug# 908129 Set the values in the variables based on the values
   of the parameter X_def_awt_include_tax_amt*/
IF X_def_awt_include_tax_amt = 'N' then
	X_curr_awt_group_id := NULL;
        X_curr_awt_flag := 'N';
END IF;
IF (x_tax_name IS NOT NULL) THEN
  SELECT   tax_rate,
       	   tax_type,
           tax_code_combination_id,
           description
  INTO     X_tax_rate,
           X_tax_type,
           X_tax_code_combination_id,
           X_tax_description
  FROM     ap_tax_codes
  WHERE    name = X_tax_name;
ELSE
  SELECT   tax_rate,
       	   tax_type,
           tax_code_combination_id,
           description
  INTO     X_tax_rate,
           X_tax_type,
           X_tax_code_combination_id,
           X_tax_description
  FROM     ap_tax_codes
  WHERE    tax_id = x_tax_code_id;
END IF;
/* Bug 777775 Tax rounding */
SELECT	ap_tax_rounding_rule
INTO	x_rounding_rule
FROM 	PO_VENDOR_SITES
WHERE	VENDOR_SITE_ID = x_pay_site_id;
X_progress := '020';
IF (X_tax_type <> 'USE') THEN
	IF (X_tax_amount IS NOT NULL) THEN
	/**Tax amount already supplied does not need to calculate**/
		X_progress := '030';
 	        -- bug 805420, call ap_round_tax to round taxes
     		X_temp_tax_amount := ap_utilities_pkg.ap_round_tax(
					X_tax_amount,
					X_invoice_currency_code,
					x_rounding_rule,
					'Round temp tax amount');
	ELSE
		X_progress := '040';
 	        -- bug 805420, call ap_round_tax to round taxes
     		X_temp_tax_amount := ap_utilities_pkg.ap_round_tax(
					X_taxable_amount * X_tax_rate/100,
					X_invoice_currency_code,
					x_rounding_rule,
					'Round temp tax amount');
	END IF;
ELSE
	/*** tax distribution lines will not be created if tax type is
	     'USE'
	***/
	X_progress := '050';
	X_temp_tax_amount := 0;
	X_temp_offset_tax_amount := 0;
END IF;
IF (X_tax_type <> 'USE') AND (X_curr_inv_process_flag = 'Y')  THEN
     /** Create one tax distribution for each taxable invoice distribution line
         if tax_type is not 'USE' **/
     /** Determine the distribution line number for the new record**/
     X_progress := '060';
     SELECT NVL(MAX(distribution_line_number), 0) + 1
     INTO    X_new_dist_line_number
     FROM    ap_invoice_distributions
     WHERE   invoice_id = X_invoice_id;
	/** call object handler to create the tax distribution ****/
     X_progress := '070';
     IF (X_invoice_currency_code <> X_base_currency_code) THEN
        -- bug 805420, call ap_round_tax to round taxes
	X_base_tax_amount := ap_utilities_pkg.ap_round_tax(
				X_temp_tax_amount * X_exchange_rate,
				X_base_currency_code,
				X_rounding_rule,
				'Round base tax_amount');
     ELSE
	X_base_tax_amount := NULL;
     END IF;
     X_progress := '075';
     X_rowid := NULL;	   -- need to make sure X_rowid is NULL before insert
    /* Bug:559224. gtummala. 10/27/97.
     * Accounting date should not have a non-zero time stamp. Ie it should
     * be 00:00:00. So truncate the X_accounting_date.
     */
     ap_invoice_distributions_pkg.insert_row(
                                     X_Rowid=>X_rowid,
				     X_Invoice_Id=>X_invoice_id,
				     X_Invoice_Distribution_Id=> X_invoice_distribution_id,
				     X_Dist_Code_Combination_Id=>X_tax_code_combination_id,
				     X_Last_Update_Date=>sysdate,
				     X_Last_Updated_By=>FND_GLOBAL.user_id,
				     X_Accounting_Date=>trunc(X_accounting_date),
							         /* Bug:559224 */
				     X_Period_Name=>X_period_name,
				     X_Set_Of_Books_Id=>X_def_sets_of_books_id,
				     X_Amount=>X_temp_tax_amount,
				     X_Description=>X_tax_description,--1333115
				     X_Type_1099=>X_type_1099,
				     X_tax_code_id=> X_tax_code_id,  -- :DEBUG  X_Vat_Code=>X_tax_name,
				     X_Posted_Flag=>'N',
				     X_Batch_Id=>X_batch_id,
				     X_Quantity_Invoiced=>NULL,
				     X_Unit_Price=>NULL,
				     X_Match_Status_Flag=>NULL,	-- match_status_flag
				     X_Attribute_Category=>NULL,
				     X_Attribute1=>NULL,
				     X_Attribute2=>NULL,
				     X_Attribute3=>NULL,
				     X_Attribute4=>NULL,
				     X_Attribute5=>NULL,
				     X_Prepay_Amount_Remaining=>NULL,
				     X_Assets_Addition_Flag=>'U',
				     X_Assets_Tracking_Flag=>X_assets_tracking_flag,
				     X_Distribution_Line_Number=>X_new_dist_line_number,
				     X_Line_Type_Lookup_Code=>'TAX',
				     X_Po_Distribution_Id=>NULL,
				     X_Base_Amount=>X_base_tax_amount,
				     X_Exchange_Rate=>X_exchange_rate,
				     X_Exchange_Rate_Type=>X_exchange_rate_type,
				     X_Exchange_Date=>X_exchange_date,
				     X_Pa_Addition_Flag=>'N',
				     X_Je_Batch_Id=>NULL,
				     X_Posted_Amount=>NULL,
				     X_Posted_Base_Amount=>NULL,
				     X_Encumbered_Flag=>'N',
				     X_Accrual_Posted_Flag=>'N',
				     X_Cash_Posted_Flag=>'N',
				     X_Last_Update_Login=>FND_GLOBAL.login_id,
				     X_Creation_Date=>sysdate,
				     X_Created_By=>FND_GLOBAL.user_id,
				     X_Cash_Je_Batch_Id=>NULL,
				     X_Stat_Amount=>NULL,
				     X_Attribute11=>NULL,
				     X_Attribute12=>NULL,
				     X_Attribute13=>NULL,
				     X_Attribute14=>NULL,
				     X_Attribute6=>NULL,
				     X_Attribute7=>NULL,
				     X_Attribute8=>NULL,
				     X_Attribute9=>NULL,
				     X_Attribute10=>NULL,
				     X_Attribute15=>NULL,
				     X_Accts_Pay_Code_Comb_Id=>NULL, -- liability acct
				     X_Rate_Var_Code_Combination_Id=>NULL,
				     X_Price_Var_Code_Comb_Id=>NULL,
				     X_Exchange_Rate_Variance=>NULL,
				     X_Invoice_Price_Variance=>NULL,
				     X_Base_Invoice_Price_Variance=>NULL,
				     X_Reversal_Flag=>NULL,
				     X_Parent_Invoice_Id=>NULL,
				     X_Income_Tax_Region=>X_income_tax_region,
				     X_Final_Match_Flag=>'N',
				     X_Ussgl_Transaction_Code=>NULL,
				     X_Ussgl_Trx_Code_Context=>NULL,
				     X_Expenditure_Item_Date=>NULL,
				     X_Expenditure_Organization_Id=>NULL,
				     X_Expenditure_Type=>NULL,
				     X_Pa_Quantity=>NULL,
				     X_Project_Id=>NULL,
				     X_Task_Id=>NULL,
				     X_Project_Accounting_Context=>NULL,
				     X_Quantity_Variance=>NULL,
				     X_Base_Quantity_Variance=>NULL,
				     X_Packet_Id=>NULL,
				     X_Awt_Flag=>X_curr_awt_flag,
				     X_Awt_Group_Id=>X_curr_awt_group_id,
				     X_Awt_Tax_Rate_Id=>NULL,
				     X_Awt_Gross_Amount=>NULL,
				     X_Reference_1=>NULL,
				     X_Reference_2=>NULL,
				     X_Org_Id=>NULL,
				     X_Other_Invoice_Id=>NULL,
				     X_Awt_Invoice_Id=>NULL,
				     X_Awt_Origin_Group_Id=>NULL,
				     X_Program_Application_Id=>FND_GLOBAL.prog_appl_id,
				     X_Program_Id=>FND_GLOBAL.conc_program_id,
				     X_Program_Update_Date=>sysdate,
				     X_Request_Id=>FND_GLOBAL.conc_request_id,
				     X_Amount_Includes_Tax_Flag=>NULL, 	--X_Amount_Includes_Tax_Flag
				     X_Tax_Code_Override_Flag => NULL,
				     X_Tax_Recovery_Rate	=> NULL,
				     X_Tax_Recovery_Override_Flag	=> NULL,
				     X_Tax_Recoverable_Flag           => NULL,
				     X_Award_Id                       => NULL,
				     X_Start_Expense_Date             => NULL,
				     X_Merchant_Document_Number       => NULL,
				     X_Merchant_Name                  => NULL,
				     X_Merchant_Tax_Reg_Number        => NULL,
				     X_Merchant_Taxpayer_Id           => NULL,
				     X_Country_Of_Supply              => NULL,
				     X_Merchant_Reference             => NULL,
				     X_parent_reversal_id		=> NULL,
				     X_rcv_transaction_id		=> NULL,
				     X_matched_uom_lookup_code	=> NULL,
				     X_global_attribute_category      =>NULL,
				     X_global_attribute1              =>NULL,
				     X_global_attribute2              =>NULL,
				     X_global_attribute3              =>NULL,
				     X_global_attribute4              =>NULL,
				     X_global_attribute5              =>NULL,
				     X_global_attribute6              =>NULL,
				     X_global_attribute7              =>NULL,
				     X_global_attribute8              =>NULL,
				     X_global_attribute9              =>NULL,
				     X_global_attribute10             =>NULL,
				     X_global_attribute11             =>NULL,
				     X_global_attribute12             =>NULL,
				     X_global_attribute13             =>NULL,
				     X_global_attribute14             =>NULL,
				     X_global_attribute15             =>NULL,
				     X_global_attribute16             =>NULL,
				     X_global_attribute17             =>NULL,
				     X_global_attribute18             =>NULL,
				     X_global_attribute19             =>NULL,
				     X_global_attribute20             =>NULL,
				     X_Calling_Sequence=>'CREATE_TAX_DISTR'
				);
     /*** Then determine if offset tax is required. ***/
     /* Bug 1500661 */
      X_progress := '075a';
      select Base_Amount
      into X_temp_tax_base_amount
      from ap_invoice_distributions
      where Invoice_Id = X_invoice_id
      and Distribution_Line_Number = X_new_dist_line_number;
     X_progress := '090';
     X_create_offset_flag := det_if_offset_tax_req(
				X_tax_name,
				X_pay_site_id,
				X_offset_tax_code,
				X_offset_tax_rate,
				X_offset_tax_ccid,
				X_offset_tax_code_id);
     IF (X_create_offset_flag = 'Y') THEN
         /**Find the corresponding offset tax code***/
     	 X_progress := '100';
	 /*** The following was added to handle the case when users specify
	 a VAT tax in RCV_SHIPMENT_HEADERS, we have to create an offset tax
	 for the entire invoice. But at this time, we do not know what the
         taxable amount is. We have to find it out using the tax_amount
         and tax_rate of the VAT Tax code ****/
       /* added select stmt to get offset tax description  bug 1333115*/
	   /* Bug 3648544.
	    * To get the offset tax description, we need to join
	    * offset_Tax_code_id to the tax_id in ap_tax_codes.
	   */
           IF(X_offset_tax_code_id IS NOT NULL) THEN
               SELECT description
                 INTO X_offset_tax_description
                 FROM ap_tax_codes
                WHERE tax_id=X_offset_tax_code_id;
           END IF;
	 IF (X_taxable_amount IS NULL) THEN
		IF (X_tax_rate <> 0) THEN
		    X_temp_taxable_amount := X_tax_amount * 100 /
						X_tax_rate;
		ELSE
		    X_temp_taxable_amount := NULL;
		END IF;
	 ELSE
		X_temp_taxable_amount := X_taxable_amount;
	 END IF;
	 X_progress := '105';
         X_temp_offset_tax_amount:= ap_utilities_pkg.ap_round_tax(
				X_temp_taxable_amount* X_offset_tax_rate /100 ,
				X_invoice_currency_code,
				x_rounding_rule,
				'Round temp offset tax amount');
         /**Find out the distribution line number for this distribution
	    line **/
     	X_progress := '110';
        SELECT NVL(MAX(distribution_line_number), 0) + 1
       	INTO    X_new_dist_line_number
        FROM    ap_invoice_distributions
        WHERE   invoice_id = X_invoice_id;
     	X_progress := '120';
        /* Bug 777775 Tax rounding */
	IF (X_invoice_currency_code <> X_base_currency_code) THEN
		X_base_offset_tax_amount := ap_utilities_pkg.ap_round_tax(
						X_temp_offset_tax_amount *
						X_exchange_rate,
						X_base_currency_code,
						x_rounding_rule,
						'Round offset base tax amount');
	END IF;
        /*** call object handler to insert the tax distribution ***/
	/*** offset tax distr **/
     	X_progress := '130';
    	X_rowid := NULL; -- make sure X_rowid is NULL before insert
	/* Bug:559224. gtummala. 10/27/97.
	 * Accounting date should not have a non-zero time stamp. Ie it should
         * be 00:00:00. So truncate the X_accounting_date.
         */
     	ap_invoice_distributions_pkg.insert_row(
                                     X_Rowid=>X_rowid,
				     X_Invoice_Id=>X_invoice_id,
				     X_Invoice_Distribution_Id=> X_invoice_distribution_id,
				     X_Dist_Code_Combination_Id=>X_offset_tax_ccid,
				     X_Last_Update_Date=>sysdate,
				     X_Last_Updated_By=>FND_GLOBAL.user_id,
				     X_Accounting_Date=>trunc(X_accounting_date),
								/* Bug:559224 */
				     X_Period_Name=>X_period_name,
				     X_Set_Of_Books_Id=>X_def_sets_of_books_id,
				     X_Amount=>X_temp_offset_tax_amount,
				     X_Description=>X_offset_tax_description,
                                        /*1333115*/
				     X_Type_1099=>X_type_1099,
				     X_tax_code_id=> X_offset_tax_code_id,  -- :DEBUG  X_Vat_Code=>X_offset_tax_code,
				     X_Posted_Flag=>'N',
				     X_Batch_Id=>X_batch_id,
				     X_Quantity_Invoiced=>NULL,
				     X_Unit_Price=>NULL,
				     X_Match_Status_Flag=>NULL,  -- match_status_flag
				     X_Attribute_Category=>NULL,
				     X_Attribute1=>NULL,
				     X_Attribute2=>NULL,
				     X_Attribute3=>NULL,
				     X_Attribute4=>NULL,
				     X_Attribute5=>NULL,
				     X_Prepay_Amount_Remaining=>NULL,
				     X_Assets_Addition_Flag=>'U',
				     X_Assets_Tracking_Flag=>X_assets_tracking_flag,
				     X_Distribution_Line_Number=>X_new_dist_line_number,
				     X_Line_Type_Lookup_Code=>'TAX',
				     X_Po_Distribution_Id=>NULL,
				     X_Base_Amount=>X_base_offset_tax_amount,
				     X_Exchange_Rate=>X_exchange_rate,
				     X_Exchange_Rate_Type=>X_exchange_rate_type,
				     X_Exchange_Date=>X_exchange_date,
				     X_Pa_Addition_Flag=>'N',
				     X_Je_Batch_Id=>NULL,
				     X_Posted_Amount=>NULL,
				     X_Posted_Base_Amount=>NULL,
				     X_Encumbered_Flag=>'N',
				     X_Accrual_Posted_Flag=>'N',
				     X_Cash_Posted_Flag=>'N',
				     X_Last_Update_Login=>FND_GLOBAL.login_id,
				     X_Creation_Date=>sysdate,
				     X_Created_By=>FND_GLOBAL.user_id,
				     X_Cash_Je_Batch_Id=>NULL,
				     X_Stat_Amount=>NULL,
				     X_Attribute11=>NULL,
				     X_Attribute12=>NULL,
				     X_Attribute13=>NULL,
				     X_Attribute14=>NULL,
				     X_Attribute6=>NULL,
				     X_Attribute7=>NULL,
				     X_Attribute8=>NULL,
				     X_Attribute9=>NULL,
				     X_Attribute10=>NULL,
				     X_Attribute15=>NULL,
				     X_Accts_Pay_Code_Comb_Id=>NULL, -- liability acct
				     X_Rate_Var_Code_Combination_Id=>NULL,
				     X_Price_Var_Code_Comb_Id=>NULL,
				     X_Exchange_Rate_Variance=>NULL,
				     X_Invoice_Price_Variance=>NULL,
				     X_Base_Invoice_Price_Variance=>NULL,
				     X_Reversal_Flag=>NULL,
				     X_Parent_Invoice_Id=>NULL,
				     X_Income_Tax_Region=>X_income_tax_region,
				     X_Final_Match_Flag=>'N',
				     X_Ussgl_Transaction_Code=>NULL,
				     X_Ussgl_Trx_Code_Context=>NULL,
				     X_Expenditure_Item_Date=>NULL,
				     X_Expenditure_Organization_Id=>NULL,
				     X_Expenditure_Type=>NULL,
				     X_Pa_Quantity=>NULL,
				     X_Project_Id=>NULL,
				     X_Task_Id=>NULL,
				     X_Project_Accounting_Context=>NULL,
				     X_Quantity_Variance=>NULL,
				     X_Base_Quantity_Variance=>NULL,
				     X_Packet_Id=>NULL,
				     X_Awt_Flag=>X_curr_awt_flag,
				     X_Awt_Group_Id=>X_curr_awt_group_id,
				     X_Awt_Tax_Rate_Id=>NULL,
				     X_Awt_Gross_Amount=>NULL,
				     X_Reference_1=>NULL,
				     X_Reference_2=>NULL,
				     X_Org_Id=>NULL,
				     X_Other_Invoice_Id=>NULL,
				     X_Awt_Invoice_Id=>NULL,
				     X_Awt_Origin_Group_Id=>NULL,
				     X_Program_Application_Id=>FND_GLOBAL.prog_appl_id,
				     X_Program_Id=>FND_GLOBAL.conc_program_id,
				     X_Program_Update_Date=>sysdate,
				     X_Request_Id=>FND_GLOBAL.conc_request_id,
				     X_Amount_Includes_Tax_Flag=>NULL,    --X_Amount_Includes_Tax_Flag
				     X_Tax_Code_Override_Flag => NULL,
				     X_Tax_Recovery_Rate	=> NULL,
				     X_Tax_Recovery_Override_Flag	=> NULL,
				     X_Tax_Recoverable_Flag           => NULL,
				     X_Award_Id                       => NULL,
				     X_Start_Expense_Date             => NULL,
				     X_Merchant_Document_Number       => NULL,
				     X_Merchant_Name                  => NULL,
				     X_Merchant_Tax_Reg_Number        => NULL,
				     X_Merchant_Taxpayer_Id           => NULL,
				     X_Country_Of_Supply              => NULL,
				     X_Merchant_Reference             => NULL,
				     X_parent_reversal_id		=> NULL,
				     X_rcv_transaction_id		=> NULL,
				     X_matched_uom_lookup_code	=> NULL,
				     X_global_attribute_category      =>NULL,
				     X_global_attribute1              =>NULL,
				     X_global_attribute2              =>NULL,
				     X_global_attribute3              =>NULL,
				     X_global_attribute4              =>NULL,
				     X_global_attribute5              =>NULL,
				     X_global_attribute6              =>NULL,
				     X_global_attribute7              =>NULL,
				     X_global_attribute8              =>NULL,
				     X_global_attribute9              =>NULL,
				     X_global_attribute10             =>NULL,
				     X_global_attribute11             =>NULL,
				     X_global_attribute12             =>NULL,
				     X_global_attribute13             =>NULL,
				     X_global_attribute14             =>NULL,
				     X_global_attribute15             =>NULL,
				     X_global_attribute16             =>NULL,
				     X_global_attribute17             =>NULL,
				     X_global_attribute18             =>NULL,
				     X_global_attribute19             =>NULL,
				     X_global_attribute20             =>NULL,
				     X_Calling_Sequence=>'CREATE_TAX_DISTR');
       /* Bug 1500661*/
     X_progress := '130a';
      select Base_Amount
      into X_temp_tax_base_offset
      from ap_invoice_distributions
      where Invoice_Id = X_invoice_id
      and Distribution_Line_Number = X_new_dist_line_number;
    ELSE  -- create offset tax flag
     		X_temp_offset_tax_amount :=0;
    END IF;
       /** Update the current invoice and tax amounts for the invoice
	   being processed.**/
    X_progress := '140';
    IF (X_curr_inv_process_flag = 'Y') THEN
	X_curr_invoice_amount := X_curr_invoice_amount +
			 		NVL(X_temp_tax_amount,0) +
		         		NVL(X_temp_offset_tax_amount,0);
	X_curr_tax_amount := X_curr_tax_amount +
			 		NVL(X_temp_tax_amount,0) +
			 		NVL(X_temp_offset_tax_amount,0);
          /* Bug 1500661 */
         X_base_amount1 := X_base_amount1 +
                                 NVL(X_temp_tax_base_amount,0) +
                                 NVL(X_temp_tax_base_offset,0);
    END IF;
END IF; 	-- X_type_type <> 'USE'
EXCEPTION
WHEN OTHERS THEN
       IF (g_asn_debug = 'Y') THEN
          asn_debug.put_line('Error in creating tax distributions...');
       END IF;
       po_message_s.sql_error('create_tax_distributions', x_progress, sqlcode);
       RAISE;
END create_tax_distributions;
/* <CANCEL ASBN FPI START> */
--
-- This procedure will be compatible with AP minipack F or above.
--
/*==================================================================
  PROCEDURE NAME: cancel_asbn_invoices_line_new
  DESCRIPTION: 	Calls AP's API Ap_Cancel_Single_Invoice to cancel invoices
		in ASBN cancellation,  AP's patch level is F or above
  PARAMETERS:	p_invoice_id 		IN	NUMBER,
		p_set_of_books_id	IN	NUMBER,
		p_gl_date		IN	DATE,
		p_period_name		IN	VARCHAR2
  DESIGN
  REFERENCES:
  CHANGE 	Created		21-AUGUST-02	DXIE
  HISTORY:
=======================================================================*/
PROCEDURE cancel_asbn_invoices_line_new (
	p_invoice_id 		IN	NUMBER,
	p_set_of_books_id	IN	NUMBER,
	p_gl_date		IN	DATE,
	p_period_name		IN	VARCHAR2 )
IS
   l_plsql_block_old		VARCHAR2(1000);
   l_plsql_block_new		VARCHAR2(1000);
   l_message_name		FND_NEW_MESSAGES.message_name%TYPE;
   l_invoice_amount		AP_INVOICES.invoice_amount%TYPE;
   l_base_amount		AP_INVOICES.base_amount%TYPE;
   l_tax_amount 		AP_INVOICES.tax_amount%TYPE;
   l_temp_cancelled_amount 	AP_INVOICES.temp_cancelled_amount%TYPE;
   l_cancelled_by 		AP_INVOICES.cancelled_by%TYPE;
   l_cancelled_amount 		AP_INVOICES.cancelled_amount%TYPE;
   l_cancelled_date 		AP_INVOICES.cancelled_date%TYPE;
   l_last_update_date 		AP_INVOICES.last_update_date%TYPE;
   l_dummy_amount		NUMBER;
   l_pay_curr_invoice_amount 	AP_INVOICES.pay_curr_invoice_amount%TYPE;
   l_api_name	 		CONSTANT VARCHAR2(40) := 'cancel_asbn_invoices_line_new';
BEGIN
   IF (g_fnd_debug = 'Y') THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name || '.begin','Inside CANCEL_ASBN_INVOICES_LINE_NEW procedure');
   END IF;
   /* l_plsql_block_new has one more binding argument than l_plsql_block_old. */
   l_plsql_block_old := ' BEGIN if (AP_CANCEL_PKG.Ap_Cancel_Single_Invoice( ' ||
		   	' :v1,  :v2,  :v3,  :v4,  :v5, :v6, :v7, :v8, :v9, '  ||
		  	' :v10, :v11, :v12, :v13, :v14, :v15, :v16, null, '   ||
		   	' ''rvtth.lpc'')) then null; end if; END; ';
   l_plsql_block_new := ' BEGIN if (AP_CANCEL_PKG.Ap_Cancel_Single_Invoice( ' ||
		   	' :v1,  :v2,  :v3,  :v4,  :v5, :v6, :v7, :v8, :v9, '  ||
		   	' :v10, :v11, :v12, :v13, :v14, :v15, :v16, null, '   ||
		   	' :v17, ''rvtth.lpc'')) then null; end if;  END; ';
   BEGIN
      IF (g_fnd_debug = 'Y') THEN
         FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ||'.begin', 'Call: l_plsql_block_new');
      END IF;
      /* Cancel the invoice using function with new signature. */
      EXECUTE IMMEDIATE l_plsql_block_new USING
		IN	p_invoice_id,
		IN	1,
		IN	1,
		IN	p_set_of_books_id,
		IN	p_gl_date,
		IN	p_period_name,
		OUT 	l_message_name,
		OUT 	l_invoice_amount,
		OUT 	l_base_amount,
		OUT 	l_tax_amount,
		OUT 	l_temp_cancelled_amount,
		OUT 	l_cancelled_by,
		OUT 	l_cancelled_amount,
		OUT 	l_cancelled_date,
		OUT 	l_last_update_date,
		OUT 	l_dummy_amount,
		OUT 	l_pay_curr_invoice_amount;
   EXCEPTION
     WHEN OTHERS THEN
       /** If the exception is due to the wrong number of arguments in call
          to 'AP_CANCEL_SINGLE_INVOICE', we'll try the old signature. **/
       IF (SQLCODE = -6550) THEN
          BEGIN
	     IF (g_fnd_debug = 'Y') THEN
   	     FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ||'.begin', 'Call: l_plsql_block_old');
	     END IF;
             EXECUTE IMMEDIATE l_plsql_block_old USING
		IN	p_invoice_id,
		IN	1,
		IN	1,
		IN	p_set_of_books_id,
		IN	p_gl_date,
		IN	p_period_name,
		OUT 	l_message_name,
		OUT 	l_invoice_amount,
		OUT 	l_base_amount,
		OUT 	l_tax_amount,
		OUT 	l_temp_cancelled_amount,
		OUT 	l_cancelled_by,
		OUT 	l_cancelled_amount,
		OUT 	l_cancelled_date,
		OUT 	l_last_update_date,
		OUT 	l_dummy_amount;
          EXCEPTION
             WHEN OTHERS THEN
              raise;
          END;
       ELSE
          raise;   -- Raise other types of exception.
       END IF;
   END;
   IF (g_fnd_debug = 'Y') THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name || '.begin', 'CANCEL_ASBN_INVOICES_LINE_NEW procedure Ends');
   END IF;
END cancel_asbn_invoices_line_new;
--
-- This procedure will be compatible with AP minipack A to D.
--
/*==================================================================
  PROCEDURE NAME: cancel_asbn_invoices_line_old
  DESCRIPTION: 	Calls AP's API Ap_Cancel_Single_Invoice to cancel invoices in
		ASBN cancellation, AP's patch level is not registered or below
  PARAMETERS:	p_invoice_id 		IN	NUMBER,
		p_set_of_books_id	IN	NUMBER,
		p_gl_date		IN	DATE,
		p_period_name		IN	VARCHAR2
  DESIGN
  REFERENCES:
  CHANGE 	Created		21-AUGUST-02	DXIE
  HISTORY:
=======================================================================*/
PROCEDURE cancel_asbn_invoices_line_old (
	p_invoice_id 		IN	NUMBER,
	p_set_of_books_id	IN	NUMBER,
	p_gl_date		IN	DATE,
	p_period_name		IN	VARCHAR2 )
IS
   l_plsql_block_old		VARCHAR2(1000);
   l_plsql_block_new		VARCHAR2(1000);
   l_message_name		FND_NEW_MESSAGES.message_name%TYPE;
   l_invoice_amount		AP_INVOICES.invoice_amount%TYPE;
   l_base_amount		AP_INVOICES.base_amount%TYPE;
   l_tax_amount 		AP_INVOICES.tax_amount%TYPE;
   l_temp_cancelled_amount 	AP_INVOICES.temp_cancelled_amount%TYPE;
   l_cancelled_by 		AP_INVOICES.cancelled_by%TYPE;
   l_cancelled_amount 		AP_INVOICES.cancelled_amount%TYPE;
   l_cancelled_date 		AP_INVOICES.cancelled_date%TYPE;
   l_last_update_date 		AP_INVOICES.last_update_date%TYPE;
   l_dummy_amount		NUMBER;
   l_pay_curr_invoice_amount 	AP_INVOICES.pay_curr_invoice_amount%TYPE;
   l_api_name	 		CONSTANT VARCHAR2(40) := 'cancel_asbn_invoices_line_old';
BEGIN
   IF (g_fnd_debug = 'Y') THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name || '.begin','Inside CANCEL_ASBN_INVOICES_LINE_OLD procedure');
   END IF;
   /* l_plsql_block_new has one more binding argument than l_plsql_block_old. */
   l_plsql_block_old := ' BEGIN if (AP_CANCEL_PKG.Ap_Cancel_Single_Invoice( ' ||
		   	' :v1,  :v2,  :v3,  :v4,  :v5, :v6, :v7, :v8, :v9, '  ||
		   	' :v10, :v11, :v12, :v13, :v14, :v15, :v16, null, '   ||
		   	' ''rvtth.lpc'')) then null; end if; END; ';
   l_plsql_block_new := ' BEGIN if (AP_CANCEL_PKG.Ap_Cancel_Single_Invoice( ' ||
		   	' :v1,  :v2,  :v3,  :v4,  :v5, :v6, :v7, :v8, :v9, '  ||
		   	' :v10, :v11, :v12, :v13, :v14, :v15, :v16, null, '   ||
		   	' :v17, ''rvtth.lpc'')) then null; end if;  END; ';
   BEGIN
      IF (g_fnd_debug = 'Y') THEN
         FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ||'.begin', 'Call: l_plsql_block_old');
      END IF;
      EXECUTE IMMEDIATE l_plsql_block_old USING
		IN	p_invoice_id,
		IN	1,
		IN	1,
		IN	p_set_of_books_id,
		IN	p_gl_date,
		IN	p_period_name,
		OUT 	l_message_name,
		OUT 	l_invoice_amount,
		OUT 	l_base_amount,
		OUT 	l_tax_amount,
		OUT 	l_temp_cancelled_amount,
		OUT 	l_cancelled_by,
		OUT 	l_cancelled_amount,
		OUT 	l_cancelled_date,
		OUT 	l_last_update_date,
		OUT 	l_dummy_amount;
   EXCEPTION
     WHEN OTHERS THEN
       /** If the exception is due to the wrong number of arguments in call
          to 'AP_CANCEL_SINGLE_INVOICE', we'll try the new signature. **/
       IF (SQLCODE = -6550) THEN
          BEGIN
	     IF (g_fnd_debug = 'Y') THEN
   	     FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ||'.begin', 'Call: l_plsql_block_new');
	     END IF;
             EXECUTE IMMEDIATE l_plsql_block_new USING
		IN	p_invoice_id,
		IN	1,
		IN	1,
		IN	p_set_of_books_id,
		IN	p_gl_date,
		IN	p_period_name,
		OUT 	l_message_name,
		OUT 	l_invoice_amount,
		OUT 	l_base_amount,
		OUT 	l_tax_amount,
		OUT 	l_temp_cancelled_amount,
		OUT 	l_cancelled_by,
		OUT 	l_cancelled_amount,
		OUT 	l_cancelled_date,
		OUT 	l_last_update_date,
		OUT 	l_dummy_amount,
		OUT 	l_pay_curr_invoice_amount;
          EXCEPTION
             WHEN OTHERS THEN
              raise;
          END;
       ELSE
          raise;  -- Raise other types of exception.
       END IF;
   END;
   IF (g_fnd_debug = 'Y') THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name || '.begin', 'CANCEL_ASBN_INVOICES_LINE_OLD procedure Ends');
   END IF;
END cancel_asbn_invoices_line_old;
--
-- Cancel invoice line
--
/*==================================================================
  PROCEDURE NAME: cancel_asbn_invoices_line
  DESCRIPTION: 	Decide call which version of AP's API Ap_Cancel_Single_Invoice
		to cancel invoices in ASBN cancellation
  PARAMETERS:	p_invoice_id 		IN	NUMBER,
  DESIGN
  REFERENCES:
  CHANGE 	Created		21-AUGUST-02	DXIE
  HISTORY:
=======================================================================*/
PROCEDURE cancel_asbn_invoices_line (
	p_invoice_id IN NUMBER)
IS
   l_ap_patch_level 	fnd_product_installations.patch_level%TYPE;
   l_set_of_books_id	NUMBER;
   l_gl_date		DATE;
   l_period_name	gl_period_statuses.period_name%TYPE;
   l_api_name 		CONSTANT VARCHAR2(30) := 'cancel_asbn_invoices_line';
BEGIN
   IF (g_fnd_debug = 'Y') THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name || '.begin','Inside CANCEL_ASBN_INVOICES_LINE procedure');
   END IF;
   select set_of_books_id, gl_date
   into   l_set_of_books_id, l_gl_date
   from   ap_invoices_all
   where  invoice_id = p_invoice_id;
   l_period_name := AP_INVOICES_PKG.GET_PERIOD_NAME(l_gl_date);
   IF (g_fnd_debug = 'Y') THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, G_log_head || l_api_name ||'.begin', 'period name is :'|| l_period_name);
   END IF;
   /** Get AP's patch level in the enviroment **/
   BEGIN
     ad_version_util.get_product_patch_level(200, l_ap_patch_level);
   EXCEPTION
     WHEN OTHERS THEN
       l_ap_patch_level := null;
   END;
   /** If AP's patch level is not registered or below AP.F. **/
   IF (l_ap_patch_level is null or l_ap_patch_level in ('11i.AP.A',
       '11i.AP.B', '11i.AP.C', '11i.AP.D', '11i.AP.E')) THEN
      IF (g_fnd_debug = 'Y') THEN
         FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ||'.begin', 'Call: cancel_asbn_invoices_line_old');
      END IF;
      cancel_asbn_invoices_line_old ( p_invoice_id,
			   l_set_of_books_id,
			   l_gl_date,
			   l_period_name );
   ELSE  -- AP's patch level is F or above
      IF (g_fnd_debug = 'Y') THEN
         FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ||'.begin', 'Call: cancel_asbn_invoices_line_new');
      END IF;
      cancel_asbn_invoices_line_new ( p_invoice_id,
			   l_set_of_books_id,
			   l_gl_date,
			   l_period_name );
   END IF;
   IF (g_fnd_debug = 'Y') THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name || '.begin', 'CANCEL_ASBN_INVOICES_LINE procedure Ends');
   END IF;
   EXCEPTION
     WHEN OTHERS THEN
	IF (g_fnd_debug = 'Y') THEN
   	FND_LOG.string(FND_LOG.LEVEL_EXCEPTION, g_log_head || l_api_name ||'.EXCEPTION', 'CANCEL_ASBN_INVOICES_LINE: Inside exception :'|| sqlcode);
	END IF;
	raise;
END cancel_asbn_invoices_line;
--
-- Cancel invoice in case of ASBN
-- Call the AP package to cancel the single invoice.
--
/*==================================================================
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
PROCEDURE cancel_asbn_invoices (
	p_invoice_num	IN	VARCHAR2,
	p_vendor_id	IN	NUMBER)
IS
   l_invoice_id NUMBER := NULL;
   CURSOR l_invoice_id_csr IS
	select 	invoice_id
	from 	AP_INVOICES_ALL
	where 	invoice_num = p_invoice_num
	and	vendor_id = p_vendor_id;
   l_api_name 	CONSTANT VARCHAR2(30) := 'cancel_asbn_invoices';
BEGIN
   IF (g_fnd_debug = 'Y') THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name || '.begin','Inside CANCEL_ASBN_INVOICES procedure');
   END IF;
   -- Get invoice_id and call AP package to cancel invoice
   if (p_invoice_num is not null) then
      OPEN l_invoice_id_csr;
      LOOP
        FETCH l_invoice_id_csr INTO l_invoice_id;
        EXIT WHEN l_invoice_id_csr%NOTFOUND;
        if (l_invoice_id is not null) then
	   IF (g_fnd_debug = 'Y') THEN
   	   FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name || '.begin', 'Call CANCEL_ASBN_INVOICES_LINE procedure');
	   END IF;
           cancel_asbn_invoices_line(l_invoice_id);
        end if;
      END LOOP;
      CLOSE l_invoice_id_csr;
   end if;
   IF (g_fnd_debug = 'Y') THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name || '.begin', 'CANCEL_ASBN_INVOICES procedure Ends');
   END IF;
EXCEPTION
	WHEN OTHERS THEN
		IF (g_fnd_debug = 'Y') THEN
   		FND_LOG.string(FND_LOG.LEVEL_EXCEPTION, g_log_head || l_api_name ||'.EXCEPTION', 'CANCEL_ASBN_INVOICES: Inside exception :'|| sqlcode);
		END IF;
		raise;
END cancel_asbn_invoices;
/* <CANCEL ASBN FPI END> */
/* <PAY ON USE FPI START> */
PROCEDURE submit_invoice_import (
	x_return_status	OUT NOCOPY VARCHAR2,
	p_source        IN      VARCHAR2,
	p_group_id      IN      VARCHAR2,
	p_batch_name    IN      VARCHAR2,
	p_user_id       IN      NUMBER,
	p_login_id      IN      NUMBER,
	x_request_id	OUT NOCOPY NUMBER)
IS
    l_api_name VARCHAR2(50) := 'submit_invoice_import';
BEGIN
    x_return_status := FND_API.G_RET_STS_SUCCESS;
    x_request_id := fnd_request.submit_request(
        'SQLAP',
        'APXIIMPT',
        NULL,
        NULL,
        FALSE,
        p_source,
        p_group_id,
        p_batch_name,
        'Courier Hold',		-- hold name
        'Courier Hold',		-- hold reason
        null,		-- gl date
        'N',		-- purge flag
        'N',		-- trace switch
        'N',		-- debug switch
        'N',		-- summary flag
        TO_CHAR(1000),	-- commit batch size
        TO_CHAR(p_user_id), -- user_id
        TO_CHAR(p_login_id), -- login_id
        fnd_global.local_chr(0),NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL);
EXCEPTION
    WHEN OTHERS THEN
        IF (g_asn_debug = 'Y') THEN
           ASN_DEBUG.put_line('Error in submit invoice import.');
        END IF;
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        FND_MSG_PUB.add_exc_msg(g_pkg_name, l_api_name);
END submit_invoice_import;
PROCEDURE delete_interface_records(
    x_return_status     OUT NOCOPY VARCHAR2,
    p_group_id          IN VARCHAR2)
IS
    l_api_name VARCHAR2(50) := 'delete_interface_records';
BEGIN
    x_return_status := FND_API.G_RET_STS_SUCCESS;
    DELETE FROM ap_invoice_lines_interface aili
    WHERE EXISTS (SELECT 1
                  FROM   ap_invoices_interface aii
                  WHERE  aii.invoice_id = aili.invoice_id
                  AND    aii.group_id = p_group_id);
    DELETE FROM ap_invoices_interface aii
    WHERE       aii.group_id = p_group_id;
EXCEPTION
    WHEN OTHERS THEN
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        FND_MSG_PUB.add_exc_msg(g_pkg_name, l_api_name);
END delete_interface_records;
/* <PAY ON USE FPI END> */
END BILC_PO_INVOICES_SV1;
/