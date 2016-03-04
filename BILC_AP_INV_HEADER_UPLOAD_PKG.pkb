CREATE OR REPLACE PACKAGE BODY APPS.bilc_ap_inv_header_upload_pkg
AS
-- +===================================================================+
-- | Package Name:       bilc_ap_inv_upload_pkg                        |
-- |Description      :   This Package is used by the WebADI as a    |
-- |                    toolto push data to invoice interface after  |
-- |                      performing business validations,            |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                  |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A        Initial draft version   |
-- +===================================================================+
   PROCEDURE bilc_inv_header_insert (
            p_invoice_num                  IN   VARCHAR2,
            p_invoice_type_lookup_code     IN   VARCHAR2,
            p_invoice_date                 IN   VARCHAR2,
            p_vendor_name                  IN   VARCHAR2,
            p_vendor_num                   IN   VARCHAR2,
            p_vendor_site_code             IN   VARCHAR2,
            p_invoice_amount               IN   NUMBER,
            p_invoice_currency_code        IN   VARCHAR2,
            p_exchange_rate                IN   NUMBER,
            p_exchange_rate_type           IN   VARCHAR2,
            p_exchange_date                IN   VARCHAR2,
            p_terms_name                   IN   VARCHAR2,
            p_description                  IN   VARCHAR2,
            p_attribute_category           IN   VARCHAR2 DEFAULT NULL,
            p_attribute1                   IN   VARCHAR2 DEFAULT NULL,
            p_attribute2                   IN   VARCHAR2 DEFAULT NULL,
            p_attribute3                   IN   VARCHAR2 DEFAULT NULL,
            p_attribute4                   IN   VARCHAR2 DEFAULT NULL,
            p_attribute5                   IN   VARCHAR2 DEFAULT NULL,
            p_attribute6                   IN   VARCHAR2 DEFAULT NULL,
            p_attribute7                   IN   VARCHAR2 DEFAULT NULL,
            p_attribute8                   IN   VARCHAR2 DEFAULT NULL,
            p_attribute9                   IN   VARCHAR2 DEFAULT NULL,
            p_po_number                    IN   VARCHAR2 DEFAULT NULL,--attribute10
            p_po_line_number              IN   VARCHAR2 DEFAULT NULL,--attribute11
            p_attribute12                  IN   VARCHAR2 DEFAULT NULL,
            p_attribute13                  IN   VARCHAR2 DEFAULT NULL,
            p_attribute14                  IN   VARCHAR2 DEFAULT NULL,
            p_attribute15                  IN   VARCHAR2 DEFAULT NULL,
            p_source                       IN   VARCHAR2,
            p_doc_category_code            IN   VARCHAR2,
            p_payment_method_lookup_code   IN   VARCHAR2 DEFAULT NULL,
            p_pay_group_lookup_code        IN   VARCHAR2 DEFAULT NULL,
            p_header_gl_date               IN   VARCHAR2,
            p_org_id                       IN   NUMBER)
   IS
      -- Declaration pf Variable
      lv_err_msg             fnd_new_messages.MESSAGE_TEXT%TYPE;
      lv_func_curr_code      gl_sets_of_books.currency_code%TYPE;
      lv_inv_type_lkp_code   ap_invoices_all.invoice_type_lookup_code%TYPE;
      ln_vendor_site_id      po_vendor_sites_all.vendor_site_id%TYPE;
      ln_vendor_id           po_vendors.vendor_id%TYPE;
      ln_invoice_id          ap_invoices_all.invoice_id%TYPE             := 0;
      lv_segment1            gl_code_combinations.segment1%TYPE;
      ln_org_id              hr_operating_units.organization_id%TYPE;
      ln_dist_set_id         ap_distribution_sets_all.distribution_set_id%TYPE;
      lf_err_flag            NUMBER                                      := 0;
      ln_tds_id              ja_in_tax_codes.tax_id%TYPE;
      ln_wct_id              ja_in_tax_codes.tax_id%TYPE;
      ln_esi_id              ja_in_tax_codes.tax_id%TYPE;
      ln_temp                NUMBER;
   BEGIN
      --------------------- checking for mandatory parameters---------------------------
      IF (p_invoice_num IS NULL)
      THEN
         lf_err_flag := 1;
         lv_err_msg := 'Please enter Invoice Num - ';
      END IF;

      -------------Validation for Invoice Date Format----------------------
      IF (p_invoice_date IS NULL)
      THEN
         lf_err_flag := 1;
         lv_err_msg := lv_err_msg || ' ' || 'Enter Invoice Date - ';
      ELSE
         BEGIN
            SELECT 1
              INTO ln_temp
              FROM DUAL
             WHERE p_invoice_date =
                      TO_CHAR (TO_DATE (p_invoice_date, 'DD-MM-YYYY'),
                               'DD-MON-YYYY'
                              );
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                     lv_err_msg
                  || ' '
                  || ' Enter Invoice date in DD-MON-YYYY Format';
            WHEN OTHERS
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                     lv_err_msg
                  || ' '
                  || ' Enter Invoice date in DD-MON-YYYY Format';
         END;
      END IF;

      -------------------------Validate Exchange Date--------------------------------------
      IF (p_exchange_date IS NOT NULL)
      THEN
         BEGIN
            SELECT 1
              INTO ln_temp
              FROM DUAL
             WHERE p_exchange_date =
                      TO_CHAR (TO_DATE (p_exchange_date, 'DD-MM-YYYY'),
                               'DD-MON-YYYY'
                              );
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                     lv_err_msg
                  || ' '
                  || ' Enter Exchange date in DD-MON-YYYY Format';
            WHEN OTHERS
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                     lv_err_msg
                  || ' '
                  || ' Enter Exchange date in DD-MON-YYYY Format';
         END;
      END IF;

      -------------------------Validate Header GL Date---------------------------------
      IF (p_header_gl_date IS NOT NULL)
      THEN
         BEGIN
            SELECT 1
              INTO ln_temp
              FROM DUAL
             WHERE p_header_gl_date =
                      TO_CHAR (TO_DATE (p_header_gl_date, 'DD-MM-YYYY'),
                               'DD-MON-YYYY'
                              );
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                     lv_err_msg
                  || ' '
                  || ' Enter Header Gl date in DD-MON-YYYY Format';
            WHEN OTHERS
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                     lv_err_msg
                  || ' '
                  || ' Enter Header Gl date in DD-MON-YYYY Format';
         END;
      END IF;

-------------------------------------------------------------------------------------
      IF (p_invoice_type_lookup_code IS NULL)
      THEN
         lf_err_flag := 1;
         lv_err_msg := lv_err_msg || ' ' || 'Enter Invoice Type - ';
      END IF;

      IF (p_invoice_amount IS NULL)
      THEN
         lf_err_flag := 1;
         lv_err_msg := lv_err_msg || ' ' || 'Enter Inv Hdr Amt - ';
      END IF;

      IF (p_vendor_num IS NULL AND p_vendor_name IS NULL)
      THEN
         lf_err_flag := 1;
         lv_err_msg := lv_err_msg || ' ' || 'Enter Vendor Name or Number  - ';
      END IF;

      IF (p_vendor_site_code IS NULL)
      THEN
         lf_err_flag := 1;
         lv_err_msg := lv_err_msg || ' ' || 'Enter Vendor site - ';
      END IF;

      IF (p_invoice_currency_code IS NULL)
      THEN
         lf_err_flag := 1;
         lv_err_msg := lv_err_msg || ' ' || 'Enter Inv Currency - ';
      END IF;

      IF (p_doc_category_code IS NULL)
      THEN
         lf_err_flag := 1;
         lv_err_msg := lv_err_msg || ' ' || 'Doc Category Not Found - ';
      END IF;
      -------------------Fetch AP Business Unit and match it with segment1 provided by user----
      BEGIN
         SELECT fnd_profile.VALUE ('ORG_ID')
           INTO ln_org_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            lf_err_flag := 1;
            lv_err_msg := lv_err_msg || ' ' || 'ERROR fetching Org Id - ';
      END;

      IF (p_org_id IS NULL)
      THEN
         lf_err_flag := 1;
         lv_err_msg := lv_err_msg || ' ' || 'Please enter Org_id - ';
      ELSIF (p_org_id <> ln_org_id)
      THEN
         lf_err_flag := 1;
         lv_err_msg :=
            lv_err_msg || ' ' || 'Entered Org_id do not match profile org_id';
      END IF;

            ------------------ Fetching Vendor Id for the invoice data--------------------------
      BEGIN
         SELECT pv.vendor_id
           INTO ln_vendor_id
           FROM po_vendors pv
          WHERE (p_vendor_num IS NOT NULL OR p_vendor_name IS NOT NULL)
            AND pv.segment1 = NVL (p_vendor_num, pv.segment1)
            AND pv.vendor_name = NVL (p_vendor_name, pv.vendor_name);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lf_err_flag := 1;
            lv_err_msg := lv_err_msg || ' ' || 'No Valid Vendor Found - ';
         WHEN OTHERS
         THEN
            lf_err_flag := 1;
            lv_err_msg := lv_err_msg || ' ' || 'Invalid Vendor - ' || SQLERRM;
      END;

      --------------------hecking for lines for the duplicate header----------------------------
      BEGIN
         SELECT invoice_id
           INTO ln_invoice_id
           FROM ap_invoices_interface
          WHERE invoice_num = p_invoice_num AND vendor_id = ln_vendor_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      ----------------- Validating the Invoice Type lookup Code -----------------------------------------
      BEGIN
         SELECT DECODE
                   (SIGN (p_invoice_amount),
                    -1, 'CREDIT',
                    'STANDARD'
                   )
                    -- Debit Again changed to Credit as per the renrewed reqmt
           INTO lv_inv_type_lkp_code
           FROM DUAL;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lv_err_msg := lv_err_msg || ' ' || 'Inv hdr amt not found- ';
            lf_err_flag := 1;
         WHEN OTHERS
         THEN
            lv_err_msg :=
                  lv_err_msg || ' ' || 'Invalid Inv Hdr Amount - ' || SQLERRM;
            lf_err_flag := 1;
      END;

      IF (lv_inv_type_lkp_code <> UPPER (p_invoice_type_lookup_code))
      THEN
         lv_err_msg :=
               lv_err_msg
            || ' '
            || 'Inv Type does not match sign of Inv amount - ';
         lf_err_flag := 1;
      END IF;

      ---------------------Validate Vendor site name ---------------------------------
      BEGIN
         SELECT pvs.vendor_site_id
           INTO ln_vendor_site_id
           FROM po_vendor_sites_all pvs
          WHERE pvs.org_id = p_org_id
            AND pvs.vendor_id = ln_vendor_id
            AND pvs.vendor_site_code = p_vendor_site_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lv_err_msg := lv_err_msg || ' ' || 'Vendor Site  not found- ';
            lf_err_flag := 1;
         WHEN OTHERS
         THEN
            lv_err_msg :=
                      lv_err_msg || ' ' || 'Invalid Vendor Site- ' || SQLERRM;
            lf_err_flag := 1;
      END;

      -----------------------Fetch Functional currency code --------------------------------
      BEGIN
         SELECT gsb.currency_code
           INTO lv_func_curr_code
           FROM gl_sets_of_books gsb, hr_operating_units hou
          WHERE gsb.set_of_books_id = hou.set_of_books_id
            AND hou.organization_id = p_org_id;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lv_err_msg :=
                     lv_err_msg || ' ' || 'functional currency not defined- ';
            lf_err_flag := 1;
         WHEN OTHERS
         THEN
            lv_err_msg :=
                  lv_err_msg
               || ' '
               || 'Error fetching functional currency for this org - '
               || SQLERRM;
            lf_err_flag := 1;
      END;

      -------------------Exchange rate info reqd if inv curr is diff from function curr------
      IF (lv_func_curr_code = p_invoice_currency_code)
      THEN
         NULL;
      ELSIF (   p_exchange_rate IS NULL
             OR p_exchange_rate_type IS NULL
             OR p_exchange_date IS NULL
            )
      THEN
         lv_err_msg :=
               lv_err_msg
            || ' '
            || 'Exchange rate info required- Inv Curr is Diff from function Currency- ';
         lf_err_flag := 1;
      END IF;

      IF (lf_err_flag = 0)
      THEN
         ------------------------Insert the invoice header ------------------------------
         IF (ln_invoice_id = 0)                 -- check for duplicate header
         THEN
            SELECT ap_invoices_interface_s.NEXTVAL
              INTO ln_invoice_id
              FROM DUAL;

            BEGIN
               INSERT INTO ap_invoices_interface
                           (invoice_id,
                            invoice_num,
                            invoice_type_lookup_code,
                            invoice_date,
                            vendor_id,
                            vendor_site_code,
                            invoice_amount,
                            invoice_currency_code,
                            exchange_rate,
                            exchange_rate_type,
                            exchange_date,
                            terms_name,
                            description,
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
                            SOURCE,
                            doc_category_code,
                            payment_method_lookup_code,
                            pay_group_lookup_code,
                            gl_date,
                            --prepay_num,
                            --prepay_dist_num,
                            --prepay_apply_amount,
                            --prepay_gl_date,
                            org_id
                           )
                    VALUES (ln_invoice_id,
                            p_invoice_num,
                            UPPER (p_invoice_type_lookup_code),
                            TO_DATE (p_invoice_date),
                            ln_vendor_id,
                            p_vendor_site_code,
                            p_invoice_amount,
                            p_invoice_currency_code,
                            p_exchange_rate,
                            p_exchange_rate_type,
                            TO_DATE (p_exchange_date),
                            p_terms_name,
                            p_description,
                            p_attribute_category,
                            p_attribute1,
                            p_attribute2,
                            p_attribute3,
                            p_attribute4,
                            p_attribute5,
                            p_attribute6,
                            p_attribute7,
                            p_attribute8,
                            p_attribute9,
                            p_po_number,--attribute10,
                            p_po_line_number,--attribute11,
                            p_attribute12,
                            p_attribute13,
                            p_attribute14,
                            p_attribute15,
                            p_source,
                            p_doc_category_code,
                            p_payment_method_lookup_code,
                            p_pay_group_lookup_code,
                            TO_DATE (p_header_gl_date),
                            --p_prepay_num,
                            --p_prepay_dist_num,
                            --p_prepay_apply_amount,
                            --TO_DATE (p_prepay_gl_date),
                            p_org_id
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  lv_err_msg :=
                        lv_err_msg
                     || ' '
                     || 'error loading Invoice hdr-'
                     || ln_invoice_id
                     || SQLERRM;
                  lf_err_flag := 1;
                  ROLLBACK;
            END;
         END IF;
      ELSE                                           -- when error flag is set
         raise_application_error (-20001, lv_err_msg);
      END IF;
   END;
END bilc_ap_inv_header_upload_pkg;
/