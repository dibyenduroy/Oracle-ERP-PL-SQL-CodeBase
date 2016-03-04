CREATE OR REPLACE PROCEDURE APPS.bilc_ap_inv_fields_update
AS
-- +===================================================================+
-- | Procedure Name:       bilc_ap_inv_fields_update                   |
-- |Description      :   This procedure is used to update various       |
-- |                    fields' appearance. Mandatory parameters are    |
--|                  marked with * and user hints are given for      |
-- |                     various fields.                              |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                  |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A        Initial draft version   |
-- +===================================================================+
----cariable declaration------------
   lc_interface_code   VARCHAR2 (100);
   ln_application_id   NUMBER;
BEGIN
------- Fetching the interface code and the application id -------------
   BEGIN
      SELECT biv.interface_code,
             bit.application_id
        INTO lc_interface_code,
             ln_application_id
        FROM bne_interfaces_vl biv, bne_integrators_tl bit
       WHERE biv.integrator_app_id = bit.application_id
         AND bit.integrator_code = biv.integrator_code
         AND bit.user_name = 'BILC AP Invoice Upload Web ADI New';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RAISE_APPLICATION_ERROR ('20001', 'No Integrator Found ');
      WHEN OTHERS
      THEN
         RAISE_APPLICATION_ERROR ('20001', 'Invalid Integrator ');
   END;

------------update various fields as per the agreed need ------------
   UPDATE bne_interface_cols_tl
      SET prompt_above = 'INVOICE NUMBER *                 ',
          prompt_left = 'INVOICE NUMBER *                 '
    WHERE prompt_above = 'INVOICE_NUM'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'INVOICE TYPE LOOKUP CODE *',
          prompt_left = 'INVOICE TYPE LOOKUP CODE *',
          user_hint = 'Enter STANDARD or CREDIT'
    WHERE prompt_above = 'INVOICE_TYPE_LOOKUP_CODE'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'INVOICE DATE *        ',
          prompt_left = 'INVOICE DATE *        ',
          user_hint = 'Date format (DD-MON-YYYY)'
    WHERE prompt_above = 'INVOICE_DATE'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'VENDOR NAME *           ',
          prompt_left = 'VENDOR NAME *           ',
          user_hint = 'Enter atleast Name or Number'
    WHERE prompt_above = 'VENDOR_NAME'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'VENDOR NUM *',
          prompt_left = 'VENDOR NUM *',
          user_hint = 'Enter atleast Name or Number'
    WHERE prompt_above = 'VENDOR_NUM'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'VENDOR SITE CODE *',
          prompt_left = 'VENDOR SITE CODE *'
    WHERE prompt_above = 'VENDOR_SITE_CODE'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'INVOICE AMOUNT *',
          prompt_left = 'INVOICE AMOUNT *'
    WHERE prompt_above = 'INVOICE_AMOUNT'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'INVOICE CURRENCY CODE *',
          prompt_left = 'INVOICE CURRENCY CODE *',
          user_hint =
                 'Exchange rate reqd if Inv curr is diff from Functional curr'
    WHERE prompt_above = 'INVOICE_CURRENCY_CODE'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'EXCHANGE RATE *',
          prompt_left = 'EXCHANGE RATE *'
    WHERE prompt_above = 'EXCHANGE_RATE'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = '   EXCHANGE RATE TYPE *',
          prompt_left = '   EXCHANGE RATE TYPE *'
    WHERE prompt_above = 'EXCHANGE_RATE_TYPE'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'EXCHANGE DATE *        ',
          prompt_left = 'EXCHANGE DATE *        ',
          user_hint = 'Date format (DD-MON-YYYY)'
    WHERE prompt_above = 'EXCHANGE_DATE'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'SOURCE *',
          prompt_left = 'SOURCE *'
    WHERE prompt_above = 'SOURCE'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'DOC CATEGORY CODE *',
          prompt_left = 'DOC CATEGORY CODE *'
    WHERE prompt_above = 'DOC_CATEGORY_CODE'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'HEADER GL DATE        ',
          prompt_left = 'HEADER GL DATE        ',
          user_hint = 'Date format (DD-MON-YYYY)'
    WHERE prompt_above = 'HEADER_GL_DATE'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'PREPAY GL DATE          ',
          prompt_left = 'PREPAY GL DATE          ',
          user_hint = 'Date format (DD-MON-YYYY)'
    WHERE prompt_above = 'PREPAY_GL_DATE'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;
	  
	  UPDATE bne_interface_cols_tl
      SET prompt_above = 'DPIS                 ',
          prompt_left =  'DPIS                 ',
          user_hint = 'Date format (DD-MON-YYYY)'
    WHERE prompt_above = 'DPIS'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;
	  
	  UPDATE bne_interface_cols_tl
      SET prompt_above = 'LINE_ATTRIBUTE6             ',
          prompt_left = 'LINE_ATTRIBUTE6             ',
          user_hint = 'Date format (DD-MON-YYYY)'
    WHERE prompt_above = 'LINE_ATTRIBUTE6'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;
	  
	  UPDATE bne_interface_cols_tl
      SET prompt_above = 'LINE_ATTRIBUTE7             ',
          prompt_left = 'LINE_ATTRIBUTE7             ',
          user_hint = 'Date format (DD-MON-YYYY)'
    WHERE prompt_above = 'LINE_ATTRIBUTE7'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'ORGANIZATION ID *',
          prompt_left = 'ORGANIZATION ID *'
    WHERE prompt_above = 'ORG_ID'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'LINE TYPE LOOKUP CODE *',
          prompt_left = 'LINE TYPE LOOKUP CODE *',
          user_hint = 'Enter ITEM or MISCELLANEOUS'
    WHERE prompt_above = 'LINE_TYPE_LOOKUP_CODE'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'LINE AMOUNT *',
          prompt_left = 'LINE AMOUNT *'
    WHERE prompt_above = 'LINE_AMOUNT'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'DIST_GL_DATE  *               ',
          prompt_left = 'DIST_GL_DATE  *               ',
          user_hint = 'Date format (DD-MON-YYYY)'
    WHERE prompt_above = 'DIST_GL_DATE'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'DISTRIBUTION SET NAME *',
          prompt_left = 'DISTRIBUTION SET NAME *',
          user_hint = 'Enter Dist set or Segment Values'
    WHERE prompt_above = 'DISTRIBUTION_SET_NAME'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'SEGMENT1 *',
          prompt_left = 'SEGMENT1 *'
    WHERE prompt_above = 'SEGMENT1'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'SEGMENT2 *',
          prompt_left = 'SEGMENT2 *'
    WHERE prompt_above = 'SEGMENT2'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'SEGMENT3 *',
          prompt_left = 'SEGMENT3 *'
    WHERE prompt_above = 'SEGMENT3'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'SEGMENT4 *',
          prompt_left = 'SEGMENT4 *'
    WHERE prompt_above = 'SEGMENT4'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'SEGMENT5 *',
          prompt_left = 'SEGMENT5 *'
    WHERE prompt_above = 'SEGMENT5'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'SEGMENT6 *',
          prompt_left = 'SEGMENT6 *'
    WHERE prompt_above = 'SEGMENT6'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'SEGMENT7 *',
          prompt_left = 'SEGMENT7 *'
    WHERE prompt_above = 'SEGMENT7'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'SEGMENT8 *',
          prompt_left = 'SEGMENT8 *'
    WHERE prompt_above = 'SEGMENT8'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'SEGMENT9 *',
          prompt_left = 'SEGMENT9 *'
    WHERE prompt_above = 'SEGMENT9'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET user_hint = 'India Distributions'
    WHERE prompt_above = 'CONTEXT'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'TDS TAX ',
          prompt_left = 'TDS TAX ',
          user_hint = 'Enter TDS Tax Id'
    WHERE prompt_above = 'TDS_TAX'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'WCT TAX ',
          prompt_left = 'WCT TAX ',
          user_hint = 'Enter WCT Tax Id'
    WHERE prompt_above = 'WCT_TAX'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'ESI TAX ',
          prompt_left = 'ESI TAX ',
          user_hint = 'Enter ESI Tax Id'
    WHERE prompt_above = 'ESI_TAX'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   UPDATE bne_interface_cols_tl
      SET prompt_above = 'ASSET CATEGORY     ',
          prompt_left = 'ASSET CATEGORY     '
    WHERE prompt_above = 'ASSET_CATEGORY'
      AND application_id = ln_application_id
      AND interface_code = lc_interface_code;

   COMMIT;
END;
/