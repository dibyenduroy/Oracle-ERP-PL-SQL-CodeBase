CREATE OR REPLACE PACKAGE bilc_poreq_import
AS
-- **************************************************************************************************
-- **************************************************************************************
-- *                                                                                    *
-- * PL/SQL Package     :       BILC_POREQ_IMPORT                              *
-- * Date               :       23-June-2009                                            *
-- * Purpose            :       Package is used for import Po_requisitions                      *
-- *                                                                                    *
-- *------------------------------------------------------------------------------------*
-- * Modifications      :                                                               *
-- *                                                                                    *
-- * Version     DD-MON-YYYY     Person        Changes Made                             *
-- * ----------  -------------  ------------  ----------------------------------------- *
-- * DRAFT1A     23-jun-2009     Ramkomma     Initial Draft Version                     *
-- *                                                                                    *
-- **************************************************************************************
/*********************
  Global Varaibles
*********************/
   ln_error_no           NUMBER                                         := 0;
   lt_error_tbl          apps.bilc_integration_error_pkg.error_tbl_type;
   g_user_id             NUMBER                         := fnd_global.user_id;
                                               -- To hold Login User_ID Value
   g_responsibility_id   NUMBER              := fnd_profile.VALUE ('RESP_ID');
                                                     -- To hold RESP_ID Value
   g_application_id      NUMBER         := fnd_profile.VALUE ('RESP_APPL_ID');
                                              -- To hold APPLICATION_ID Value
   g_request_id          NUMBER                 := fnd_global.conc_request_id;
                                                -- To hold Program Request ID
   g_program_id          NUMBER                 := fnd_global.conc_program_id;
                                            ---To hold con current program_id
   g_org_id              NUMBER               := fnd_profile.VALUE ('ORG_ID');
-- To hold ORG_ID Value                                                   -- To hold Operating Unit ID
   g_language            VARCHAR2 (4)                     := USERENV ('LANG');
                                                    -- To hold Language Value
   g_debug_mode          VARCHAR2 (1)                                  := 'N';
                                                  -- To hold Debug Mode Value

   /*************************************************************************
   * Procedure Name  : MAIN                                                *
   * Description     : Main Procedure to validate staging table records              *
   *************************************************************************/
   PROCEDURE bilc_import_to_interface (
      errbuf    OUT   VARCHAR2,
      retcode   OUT   VARCHAR2
   );
/******************************************************************************************************
* Procedure Name  : IMPORT_TO_BASE                                                                    *
* Description     : IMPORT_TO_BASE Procedure to insert records from staging table to interface tables *
******************************************************************************************************/
END bilc_poreq_import;                         -- End of Package Specification
/

