CREATE OR REPLACE PACKAGE BODY APPS.bilc_ap_inv_upload_pkg
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
   PROCEDURE bilc_inv_interface_insert (
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
      p_attribute10                  IN   VARCHAR2 DEFAULT NULL,
      p_attribute11                  IN   VARCHAR2 DEFAULT NULL,
      p_attribute12                  IN   VARCHAR2 DEFAULT NULL,
      p_attribute13                  IN   VARCHAR2 DEFAULT NULL,
      p_attribute14                  IN   VARCHAR2 DEFAULT NULL,
      p_attribute15                  IN   VARCHAR2 DEFAULT NULL,
      p_source                       IN   VARCHAR2,
      p_doc_category_code            IN   VARCHAR2,
      p_payment_method_lookup_code   IN   VARCHAR2 DEFAULT NULL,
      p_pay_group_lookup_code        IN   VARCHAR2 DEFAULT NULL,
      p_header_gl_date               IN   VARCHAR2,
      p_prepay_num                   IN   VARCHAR2,
      p_prepay_dist_num              IN   NUMBER DEFAULT NULL,
      p_prepay_apply_amount          IN   NUMBER DEFAULT NULL,
      p_prepay_gl_date               IN   VARCHAR2,
      p_org_id                       IN   NUMBER,
      p_line_type_lookup_code        IN   VARCHAR2,
      p_line_amount                  IN   NUMBER,
      p_dist_gl_date                 IN   VARCHAR2,
      p_line_description             IN   VARCHAR2,
      p_distribution_set_name        IN   VARCHAR2,
      p_segment1                     IN   VARCHAR2,
      p_segment2                     IN   VARCHAR2,
      p_segment3                     IN   VARCHAR2,
      p_segment4                     IN   VARCHAR2,
      p_segment5                     IN   VARCHAR2,
      p_segment6                     IN   VARCHAR2,
      p_segment7                     IN   VARCHAR2,
      --p_segment8                     IN   VARCHAR2,
      --p_segment9                     IN   VARCHAR2,
      p_context                      IN   VARCHAR2,
      p_tds_tax                      IN   VARCHAR2,
      p_wct_tax                      IN   VARCHAR2,
      p_esi_tax                      IN   VARCHAR2,
      p_line_attribute4              IN   VARCHAR2 DEFAULT NULL,
      --p_dpis                         IN   VARCHAR2,
      p_line_attribute6              IN   VARCHAR2 DEFAULT NULL,
      p_line_attribute7              IN   VARCHAR2 DEFAULT NULL,
      p_line_attribute8              IN   VARCHAR2 DEFAULT NULL,
      p_line_attribute9              IN   VARCHAR2 DEFAULT NULL,
      p_line_attribute10             IN   VARCHAR2 DEFAULT NULL,
      p_line_attribute11             IN   VARCHAR2 DEFAULT NULL,
      --p_location                     IN   VARCHAR2,
      --p_asset_category               IN   VARCHAR2,
      p_line_attribute14             IN   VARCHAR2 DEFAULT NULL,
      p_line_attribute15             IN   VARCHAR2 DEFAULT NULL
   )
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

      -----------------------------Validate Prepay GL Date------------------------------
      IF (p_prepay_gl_date IS NOT NULL)
      THEN
         BEGIN
            SELECT 1
              INTO ln_temp
              FROM DUAL
             WHERE p_prepay_gl_date =
                      TO_CHAR (TO_DATE (p_prepay_gl_date, 'DD-MM-YYYY'),
                               'DD-MON-YYYY'
                              );
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                     lv_err_msg
                  || ' '
                  || ' Enter Prepay Gl date in DD-MON-YYYY Format';
            WHEN OTHERS
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                     lv_err_msg
                  || ' '
                  || ' Enter Prepay Gl date in DD-MON-YYYY Format';
         END;
      END IF;

     /* ----------------------------------Validate DPIS Date Format------------------
      IF (p_dpis IS NOT NULL)
      THEN
         BEGIN
            SELECT 1
              INTO ln_temp
              FROM DUAL
             WHERE p_dpis =
                       TO_CHAR (TO_DATE (p_dpis, 'DD-MM-YYYY'), 'DD-MON-YYYY');
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                  lv_err_msg || ' '
                  || ' Enter DPIS date in DD-MON-YYYY Format';
            WHEN OTHERS
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                  lv_err_msg || ' '
                  || ' Enter DPIS date in DD-MON-YYYY Format';
         END;
      END IF;*/

      ---------------------------Validate Line attr6 for Date Format--------------
      IF (p_line_attribute6 IS NOT NULL)
      THEN
         BEGIN
            SELECT 1
              INTO ln_temp
              FROM DUAL
             WHERE p_line_attribute6 =
                      TO_CHAR (TO_DATE (p_line_attribute6, 'DD-MM-YYYY'),
                               'DD-MON-YYYY'
                              );
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                     lv_err_msg
                  || ' '
                  || ' Enter Line Attr6 in DD-MON-YYYY Format';
            WHEN OTHERS
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                     lv_err_msg
                  || ' '
                  || ' Enter Line Attr6 in DD-MON-YYYY Format';
         END;
      END IF;

      ---------------------------Validate Line attr7 for Date Format-----------------
      IF (p_line_attribute7 IS NOT NULL)
      THEN
         BEGIN
            SELECT 1
              INTO ln_temp
              FROM DUAL
             WHERE p_line_attribute7 =
                      TO_CHAR (TO_DATE (p_line_attribute7, 'DD-MM-YYYY'),
                               'DD-MON-YYYY'
                              );
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                     lv_err_msg
                  || ' '
                  || ' Enter Line Attr7 in DD-MON-YYYY Format';
            WHEN OTHERS
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                     lv_err_msg
                  || ' '
                  || ' Enter Line Attr7 in DD-MON-YYYY Format';
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

      IF (p_line_amount IS NULL)
      THEN
         lf_err_flag := 1;
         lv_err_msg := lv_err_msg || ' ' || 'Enter Inv Line Amt - ';
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

      -----------------Validating Dist Gl Date---------------------------------------------
      IF (p_dist_gl_date IS NULL)
      THEN
         lf_err_flag := 1;
         lv_err_msg := lv_err_msg || ' ' || 'Enter Dist Gl date - ';
      ELSE
         BEGIN
            SELECT 1
              INTO ln_temp
              FROM DUAL
             WHERE p_dist_gl_date =
                      TO_CHAR (TO_DATE (p_dist_gl_date, 'DD-MM-YYYY'),
                               'DD-MON-YYYY'
                              );
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                     lv_err_msg
                  || ' '
                  || ' Enter Dist Gl date in DD-MON-YYYY Format';
            WHEN OTHERS
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                     lv_err_msg
                  || ' '
                  || ' Enter Dist Gl date in DD-MON-YYYY Format';
         END;
      END IF;

----------------------------------------------------------------------------------------------
      IF (p_line_type_lookup_code IS NULL)
      THEN
         lf_err_flag := 1;
         lv_err_msg := lv_err_msg || ' ' || 'Enter Inv Line Type - ';
      END IF;

      IF (p_source IS NULL)
      THEN
         lf_err_flag := 1;
         lv_err_msg := lv_err_msg || ' ' || 'Enter Source - ';
      END IF;

      --------------- If Dist_set_name given then segments shdn't contain any values-----
      IF (p_distribution_set_name IS NULL)
      THEN
         IF (   p_segment1 IS NULL
             OR p_segment2 IS NULL
             OR p_segment3 IS NULL
             OR p_segment4 IS NULL
             OR p_segment5 IS NULL
             OR p_segment6 IS NULL
             OR p_segment7 IS NULL
             --OR p_segment8 IS NULL
             --OR p_segment9 IS NULL
            )
         THEN
            lf_err_flag := 1;
            lv_err_msg := lv_err_msg || ' ' || 'Enter All Segments Values - ';
         ELSE
            --------------------------------Validating segment1------------------------------
            BEGIN
               SELECT 1
                 INTO ln_temp
                 FROM fnd_flex_values_vl a, fnd_flex_value_sets b
                WHERE a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_set_name = 'BIL_GL_BS_Value_Set'
                  AND flex_value_meaning = p_segment1;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  lv_err_msg :=
                               lv_err_msg || ' ' || 'Please enter segment1  ';
                  lf_err_flag := 1;
               WHEN OTHERS
               THEN
                  lv_err_msg := lv_err_msg || ' ' || 'Segment1 is invalid  ';
                  lf_err_flag := 1;
            END;

            ---------------------------Validate segment2 --------------------------------
            BEGIN
               SELECT 1
                 INTO ln_temp
                 FROM fnd_flex_values_vl a, fnd_flex_value_sets b
                WHERE a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_set_name = 'BIL_GL_COST_CENTRE_Value_Set'
                  AND flex_value_meaning = p_segment2;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  lv_err_msg :=
                               lv_err_msg || ' ' || 'Please enter segment2  ';
                  lf_err_flag := 1;
               WHEN OTHERS
               THEN
                  lv_err_msg := lv_err_msg || ' ' || 'Segment2 is invalid  ';
                  lf_err_flag := 1;
            END;

            ------------------------Validate segment3--------------------------------------
            BEGIN
               SELECT 1
                 INTO ln_temp
                 FROM fnd_flex_values_vl a, fnd_flex_value_sets b
                WHERE a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_set_name = 'BIL_GL_ACCOUNT_Value_Set'
                  AND flex_value_meaning = p_segment3;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  lv_err_msg :=
                               lv_err_msg || ' ' || 'Please enter segment3  ';
                  lf_err_flag := 1;
               WHEN OTHERS
               THEN
                  lv_err_msg := lv_err_msg || ' ' || 'Segment3 is invalid  ';
                  lf_err_flag := 1;
            END;

            ------------------------Validate segment4--------------------------------------
            BEGIN
               SELECT 1
                 INTO ln_temp
                 FROM fnd_flex_values_vl a, fnd_flex_value_sets b
                WHERE a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_set_name = 'BIL_GL_BS_Value_Set'
                  AND flex_value_meaning = p_segment4;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  lv_err_msg :=
                               lv_err_msg || ' ' || 'Please enter segment4  ';
                  lf_err_flag := 1;
               WHEN OTHERS
               THEN
                  lv_err_msg := lv_err_msg || ' ' || 'Segment4 is invalid  ';
                  lf_err_flag := 1;
            END;

            ------------------------Validate segment5--------------------------------------
            BEGIN
               SELECT 1
                 INTO ln_temp
                 FROM fnd_flex_values_vl a, fnd_flex_value_sets b
                WHERE a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_set_name = 'BIL_GL_Future1_Value_Set'
                  AND flex_value_meaning = p_segment5;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  lv_err_msg :=
                               lv_err_msg || ' ' || 'Please enter segment5  ';
                  lf_err_flag := 1;
               WHEN OTHERS
               THEN
                  lv_err_msg := lv_err_msg || ' ' || 'Segment5 is invalid  ';
                  lf_err_flag := 1;
            END;

            ------------------------Validate segment6--------------------------------------
            BEGIN
               SELECT 1
                 INTO ln_temp
                 FROM fnd_flex_values_vl a, fnd_flex_value_sets b
                WHERE a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_set_name = 'BIL_GL_Future2_Value_Set'
                  AND flex_value_meaning = p_segment6;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  lv_err_msg :=
                               lv_err_msg || ' ' || 'Please enter segment6  ';
                  lf_err_flag := 1;
               WHEN OTHERS
               THEN
                  lv_err_msg := lv_err_msg || ' ' || 'Segment6 is invalid  ';
                  lf_err_flag := 1;
            END;

            ------------------------Validate segment7--------------------------------------
            BEGIN
               SELECT 1
                 INTO ln_temp
                 FROM fnd_flex_values_vl a, fnd_flex_value_sets b
                WHERE a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_set_name = 'BIL_GL_Future3_Value_Set'
                  AND flex_value_meaning = p_segment7;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  lv_err_msg :=
                               lv_err_msg || ' ' || 'Please enter segment7  ';
                  lf_err_flag := 1;
               WHEN OTHERS
               THEN
                  lv_err_msg := lv_err_msg || ' ' || 'Segment7 is invalid  ';
                  lf_err_flag := 1;
            END;

           /*------------------------Validate segment8--------------------------------------
            BEGIN
               SELECT 1
                 INTO ln_temp
                 FROM fnd_flex_values_vl a, fnd_flex_value_sets b
                WHERE a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_set_name = 'BTVL_FUTURE USE2';
                  --AND flex_value_meaning = p_segment8;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  lv_err_msg :=
                               lv_err_msg || ' ' || 'Please enter segment8  ';
                  lf_err_flag := 1;
               WHEN OTHERS
               THEN
                  lv_err_msg := lv_err_msg || ' ' || 'Segment8 is invalid  ';
                  lf_err_flag := 1;
            END;

            ------------------------Validate segment9--------------------------------------
            BEGIN
               SELECT 1
                 INTO ln_temp
                 FROM fnd_flex_values_vl a, fnd_flex_value_sets b
                WHERE a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_set_name = 'BTVL_FUTURE USE3';
                  --AND flex_value_meaning = p_segment9;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  lv_err_msg :=
                               lv_err_msg || ' ' || 'Please enter segment9  ';
                  lf_err_flag := 1;
               WHEN OTHERS
               THEN
                  lv_err_msg := lv_err_msg || ' ' || 'Segment9 is invalid  ';
                  lf_err_flag := 1;
            END;*/
         END IF;
      ELSIF (   p_segment1 IS NOT NULL
             OR p_segment2 IS NOT NULL
             OR p_segment3 IS NOT NULL
             OR p_segment4 IS NOT NULL
             OR p_segment5 IS NOT NULL
             OR p_segment6 IS NOT NULL
             OR p_segment7 IS NOT NULL
             --OR p_segment8 IS NOT NULL
             --OR p_segment9 IS NOT NULL
            )
      THEN
         lf_err_flag := 1;
         lv_err_msg :=
            lv_err_msg || ' ' || 'Dist set present-Segments Should be empty ';
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

      --------- To validate the segment1 with the org_id ---------------------------
      
      SELECT COUNT (1)
        INTO lv_segment1
        FROM fnd_flex_values_vl
       WHERE flex_value_set_id = (SELECT flex_value_set_id FROM fnd_flex_value_sets  WHERE UPPER(flex_value_set_name) = 'BIL_HRMS_BUSINESS_UNIT')
         AND value_category = 'HRMS Finance Mapping'
         AND TO_NUMBER (attribute20) = ln_org_id
         AND attribute10 = p_segment1;

      IF (lv_segment1 = 0)
      THEN
         lf_err_flag := 1;
         lv_err_msg :=
                lv_err_msg || ' ' || 'Please enter correct segment1 value - ';
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

      ---------------------Validate Distribution Set name ---------------------------------
      IF (p_distribution_set_name IS NOT NULL)
      THEN
         BEGIN
            SELECT ads.distribution_set_id
              INTO ln_dist_set_id
              FROM ap_distribution_sets_all ads
             WHERE ads.distribution_set_name = p_distribution_set_name
               AND ads.org_id = ln_org_id;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                       lv_err_msg || ' ' || 'Enter Valid Distribution Set - ';
            WHEN OTHERS
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                  lv_err_msg || ' ' || 'Invalid Distribution Set - '
                  || SQLERRM;
         END;
      END IF;

      ----If value exist in any of the following TDS ,WCT ,ESI Tax then context column
      ----should consist of "India Distributions".
      IF (   p_tds_tax IS NOT NULL
          OR p_wct_tax IS NOT NULL
          OR p_esi_tax IS NOT NULL
         )
      THEN
         IF ((p_context IS NULL) OR (p_context <> 'India Distributions'))
         THEN
            lf_err_flag := 1;
            lv_err_msg := lv_err_msg || ' ' || 'Invalid Context - ';
         END IF;
      END IF;

      -----------If TDS tax Id present it should be of the same org-----------
      IF (p_tds_tax IS NOT NULL)
      THEN
         BEGIN
            SELECT jtc.tax_id
              INTO ln_tds_id
              FROM ja_in_tax_codes jtc
             WHERE jtc.tax_id = TO_NUMBER (p_tds_tax)
               AND jtc.org_id = ln_org_id
               AND jtc.tax_type = 'TDS'
               AND jtc.section_type = 'TDS_SECTION'
               AND NVL (jtc.end_date, TRUNC (SYSDATE) + 1) >= TRUNC (SYSDATE);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                     lv_err_msg
                  || ' '
                  || 'Enter Valid TDS Tax ID for Org'
                  || '-'
                  || ln_org_id;
            WHEN OTHERS
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                     lv_err_msg
                  || ' '
                  || 'Invalid TDS Tax ID for Org'
                  || '-'
                  || ln_org_id
                  || SQLERRM;
         END;
      END IF;

      -------------If WCT Tax id present it should be of the same org------------
      IF (p_wct_tax IS NOT NULL)
      THEN
         BEGIN
            SELECT jtc.tax_id
              INTO ln_wct_id
              FROM ja_in_tax_codes jtc
             WHERE jtc.tax_id = TO_NUMBER (p_wct_tax)
               AND jtc.org_id = ln_org_id
               AND jtc.tax_type = 'TDS'
               AND jtc.section_type = 'WCT_SECTION'
               AND NVL (jtc.end_date, TRUNC (SYSDATE) + 1) >= TRUNC (SYSDATE);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                     lv_err_msg
                  || ' '
                  || 'Enter Valid WCT Tax ID for Org'
                  || '-'
                  || ln_org_id;
            WHEN OTHERS
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                     lv_err_msg
                  || ' '
                  || 'Invalid WCT Tax ID for Org'
                  || '-'
                  || ln_org_id
                  || SQLERRM;
         END;
      END IF;

      -------------If ESI Tax id present it should be of the same org------------
      IF (p_esi_tax IS NOT NULL)
      THEN
         BEGIN
            SELECT jtc.tax_id
              INTO ln_esi_id
              FROM ja_in_tax_codes jtc
             WHERE jtc.tax_id = TO_NUMBER (p_esi_tax)
               AND jtc.org_id = ln_org_id
               AND jtc.tax_type = 'TDS'
               AND jtc.section_type = 'ESSI_SECTION'
               AND NVL (jtc.end_date, TRUNC (SYSDATE) + 1) >= TRUNC (SYSDATE);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                     lv_err_msg
                  || ' '
                  || 'Enter Valid ESI Tax ID for Org'
                  || '-'
                  || ln_org_id;
            WHEN OTHERS
            THEN
               lf_err_flag := 1;
               lv_err_msg :=
                     lv_err_msg
                  || ' '
                  || 'Invalid ESI Tax ID for Org'
                  || '-'
                  || ln_org_id
                  || SQLERRM;
         END;
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

      ----------------------- Prepay amt shd not exceed inv amount-------------------------
      IF (p_prepay_apply_amount > p_invoice_amount)
      THEN
         lv_err_msg :=
               lv_err_msg
            || ' '
            || 'Prepay Apply amount cannot exceed Invoice amount- ';
         lf_err_flag := 1;
      ELSIF (p_prepay_apply_amount = 0)
      THEN
         lv_err_msg :=
                  lv_err_msg || ' ' || 'Prepay Apply amount cannot be zero- ';
         lf_err_flag := 1;
      ELSIF (SIGN (p_prepay_apply_amount) = -1)
      THEN
         lv_err_msg :=
               lv_err_msg || ' ' || 'Prepay Apply amount cannotbe negative  ';
         lf_err_flag := 1;
      END IF;

      -------------------Validate Line Type Lookup Code ---------------------------------
      IF (   UPPER (p_line_type_lookup_code) = 'ITEM'
          OR UPPER (p_line_type_lookup_code) = 'MISCELLANEOUS'
         )
      THEN
         NULL;
      ELSE
         lv_err_msg := 'Line Type Lookup code is Invalid  ';
         lf_err_flag := 1;
      END IF;

      /*------------------------Validate Line attribute12--------------------------------------
      BEGIN
         SELECT 1
           INTO ln_temp
           FROM fnd_flex_values_vl a, fnd_flex_value_sets b
          WHERE a.flex_value_set_id = b.flex_value_set_id
            AND b.flex_value_set_name = 'BTVL_FA_LOCATION_3'
            AND flex_value_meaning = p_location;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
         WHEN OTHERS
         THEN
            lv_err_msg := lv_err_msg || ' ' || 'Location is invalid  ';
            lf_err_flag := 1;
      END;

      ------------------------Validate Line attribute13-------------------------------------
      BEGIN
         SELECT 1
           INTO ln_temp
           FROM fnd_flex_values_vl a, fnd_flex_value_sets b
          WHERE a.flex_value_set_id = b.flex_value_set_id
            AND b.flex_value_set_name = 'BTVL_FA_CATEGORY_2'
            AND flex_value_meaning = p_asset_category;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
         WHEN OTHERS
         THEN
            lv_err_msg := lv_err_msg || ' ' || 'Asset Category is invalid  ';
            lf_err_flag := 1;
      END;*/

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
                            prepay_num,
                            prepay_dist_num,
                            prepay_apply_amount,
                            prepay_gl_date,
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
                            p_attribute10,
                            p_attribute11,
                            p_attribute12,
                            p_attribute13,
                            p_attribute14,
                            p_attribute15,
                            p_source,
                            p_doc_category_code,
                            p_payment_method_lookup_code,
                            p_pay_group_lookup_code,
                            TO_DATE (p_header_gl_date),
                            p_prepay_num,
                            p_prepay_dist_num,
                            p_prepay_apply_amount,
                            TO_DATE (p_prepay_gl_date),
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

         -----------------Insert Lines to Interface -----------------------------
         BEGIN
            INSERT INTO ap_invoice_lines_interface
                        (invoice_id,
                         invoice_line_id,
                         line_type_lookup_code,
                         amount,
                         accounting_date,
                         description,
                         distribution_set_name,
                         dist_code_concatenated,
                         attribute_category,
                         attribute1,
                         attribute2,
                         attribute3,
                         attribute4,
                         --attribute5,
                         attribute6,
                         attribute7,
                         attribute8,
                         attribute9,
                         attribute10,
                         attribute11,
                         --attribute12,
                         --attribute13,
                         attribute14,
                         attribute15,
                         org_id
                        )
                 VALUES (ln_invoice_id,
                         ap_invoice_lines_interface_s.NEXTVAL,
                         UPPER (p_line_type_lookup_code),
                         p_line_amount,
                         TO_DATE (p_dist_gl_date),
                         p_line_description,
                         p_distribution_set_name,
                            p_segment1
                         || '-'
                         || p_segment2
                         || '-'
                         || p_segment3
                         || '-'
                         || p_segment4
                         || '-'
                         || p_segment5
                         || '-'
                         || p_segment6
                         || '-'
                         || p_segment7,
                         --|| '-'
                         --|| p_segment8
                        --|| '-'
                         --|| p_segment9,
                         p_context,
                         p_tds_tax,
                         p_wct_tax,
                         p_esi_tax,
                         p_line_attribute4,
                         --TO_DATE (p_dpis),
                         TO_DATE (p_line_attribute6),
                         TO_DATE (p_line_attribute7),
                         p_line_attribute8,
                         p_line_attribute9,
                         p_line_attribute10,
                         p_line_attribute11,
                         --p_location,
                         --p_asset_category,
                         p_line_attribute14,
                         p_line_attribute15,
                         p_org_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               lv_err_msg :=
                     lv_err_msg
                  || ' '
                  || 'error loading Invoice Line-'
                  || ln_invoice_id
                  || SQLERRM;
               lf_err_flag := 1;
               ROLLBACK;
         END;
      ELSE                                           -- when error flag is set
         raise_application_error (-20001, lv_err_msg);
      END IF;
   END;
END bilc_ap_inv_upload_pkg;
/