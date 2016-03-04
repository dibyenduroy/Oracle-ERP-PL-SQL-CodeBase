CREATE OR REPLACE PACKAGE BODY bilc_poreq_import
AS
   /***************************************************************************************                                                                                    *
   -- * PL/SQL Package     :       BILC_POREQ_IMPORT                                       *
   -- * Date               :       23-June-2009                                            *
   -- * Purpose            :       Package is used for import Po_requisitions              *
   -- *------------------------------------------------------------------------------------*
   -- * Modifications      :                                                               *
   -- *                                                                                    *
   -- * Version     DD-MON-YYYY     Person        Changes Made                             *
   -- * ----------  -------------  ------------  ----------------------------------------- *
   -- * DRAFT1A     23-jun-2009     Ramkomma     Initial Draft Version                     *
   -- *                                                                                    *
   -- ***************************************************************************************/
   PROCEDURE bilc_import_to_interface (
      errbuf    OUT   VARCHAR2,
      retcode   OUT   VARCHAR2
   )
   IS
--+----------------------------------------------------------------+--
--+                    Cursor Declaration                          +--
--+----------------------------------------------------------------+--
-- Staging Table Cursor
      CURSOR cur_interface_stage
      IS
         SELECT bppst.ROWID row_id,
                bppst.*
           FROM bilc_po_pr_staging_tbl bppst
          WHERE UPPER (status) = 'NEW';

--+----------------------------------------------------------------+--
--+                    Variable Declaration                        +--
--+----------------------------------------------------------------+--
      ln_preparer_id               per_people_f.person_id%TYPE;
      lc_preparer                  per_people_f.full_name%TYPE;
      ln_charge_account_id         mtl_secondary_inventories.material_account%TYPE;
      ln_org_id                    org_organization_definitions.operating_unit%TYPE;
      ln_organization_id           org_organization_definitions.organization_id%TYPE;
      lc_organization_code         org_organization_definitions.organization_code%TYPE;
      lc_location_code             hr_locations_all_tl.location_code%TYPE;
      ln_location_id               hr_locations_all_tl.location_id%TYPE;
      lc_currency_code             fnd_currencies.currency_code%TYPE;
      ln_line_type_id              po_line_types.line_type_id%TYPE;
      lc_line_type                 po_line_types.line_type%TYPE;
      lc_requestor                 per_people_f.full_name%TYPE;
      ln_deliver_to_requestor_id   per_people_f.person_id%TYPE;
      ln_item_id                   mtl_system_items_b.inventory_item_id%TYPE;
      ln_invitem_id                mtl_system_items_b.inventory_item_id%TYPE;
      lc_item_description          mtl_system_items_b.description%TYPE;
      lc_primary_uom_code          mtl_system_items_b.primary_uom_code%TYPE;
      lc_unit_of_measure           mtl_system_items_b.primary_unit_of_measure%TYPE;
      lc_sub_inventory_name        mtl_secondary_inventories.secondary_inventory_name%TYPE;
      ln_category_id               mtl_categories.category_id%TYPE;
      lc_category_segment1         mtl_categories_kfv.concatenated_segments%TYPE;
      lc_insert_error_flag         VARCHAR2 (1)                         := 'N';
      lc_source_type_code          po_lookup_codes.lookup_code%TYPE
                                                                   := 'VENDOR';
      lc_dest_type_code            po_lookup_codes.lookup_code%TYPE
                                                                  := 'EXPENSE';
      lc_segment1                  mtl_system_items_kfv.concatenated_segments%TYPE;
      lc_chargeerr_flag            VARCHAR2 (2)                         := 'N';
      lc_error_flag                VARCHAR2 (2);
      lc_segerr_flag               VARCHAR2 (2)                         := 'N';
      lc_itemdesc_flag             VARCHAR2 (2)                         := 'N';
      lc_orgerr_flag               VARCHAR2 (2)                         := 'N';
      lc_curr_flag                 VARCHAR2 (2)                         := 'Y';
      lc_requestor_flag            VARCHAR2 (2)                         := 'N';
      lc_opearting_unit            hr_operating_units.NAME%TYPE;
      ln_fin_invorgan_id           financials_system_parameters.inventory_organization_id%TYPE;
   BEGIN
-----------------------------------------------------------------------------+--
--+ POREQ STAGING Cursor LOOP                      +--
--+-----------------------------------------------------------------------------+--
-- Opening Cursor
      lt_error_tbl.DELETE;

      FOR cur_stage_rec IN cur_interface_stage
      LOOP
         BEGIN
            cur_stage_rec.interface_source_code := 'MXM';
            lc_error_flag := 'N';

--+-----------------------------------------------------------------+--
--Deriving Destination organization and Validation of Deliver To location_id and Location Code
--+-----------------------------------------------------------------+--
            IF     cur_stage_rec.deliver_to_location_code IS NULL
               AND cur_stage_rec.deliver_to_location_id IS NULL
            THEN
               lc_error_flag := 'Y';
               ln_error_no := ln_error_no + 1;
               lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
               lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
               lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
               lt_error_tbl (ln_error_no).error_msg :=
                  'Deliver To Location Code and deliver to location id cannot be null to  Derive Destination Organization ID.';
               fnd_file.put_line
                  (fnd_file.LOG,
                   'Deliver To Location Code and deliver to location id cannot be null to  Derive Destination Organization ID.'
                  );
               fnd_file.put_line
                  (fnd_file.output,
                   'Deliver To Location Code and deliver to location id cannot be null to  Derive Destination Organization ID.'
                  );
            ELSIF cur_stage_rec.deliver_to_location_code IS NOT NULL
            THEN
               BEGIN
                  ln_location_id := NULL;
                  lc_location_code := NULL;
                  ln_organization_id := NULL;
                  lc_organization_code := NULL;

                  SELECT hla.location_id,                   --hou.location_id,
                         hla.location_code,
                         mp.organization_id,
                         mp.organization_code
                    INTO ln_location_id,
                         lc_location_code,
                         ln_organization_id,
                         lc_organization_code
                    FROM                      --hr_all_organization_units hou,
                         mtl_parameters mp, hr_locations_all hla
                   WHERE            --hou.organization_id = mp.organization_id
                         --AND hou.location_id = hla.location_id
                         hla.inventory_organization_id = mp.organization_id
                     AND UPPER (hla.location_code) =
                                UPPER (cur_stage_rec.deliver_to_location_code);
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     lc_error_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           ' Invalid Deliver To location_id'
                        || ' '
                        || cur_stage_rec.deliver_to_location_id
                        || ' '
                        || ' to Derive  destination organization id';
                     fnd_file.put_line
                                    (fnd_file.LOG,
                                        ' Invalid Deliver To location_id'
                                     || ' '
                                     || cur_stage_rec.deliver_to_location_id
                                     || ' '
                                     || ' to Derive  destination organization id'
                                    );
                     fnd_file.put_line
                                      (fnd_file.output,
                                          ' Invalid Deliver To location_id'
                                       || ' '
                                       || cur_stage_rec.deliver_to_location_id
                                       || ' '
                                       || 'to Derive destination organization id'
                                      );
                  WHEN TOO_MANY_ROWS
                  THEN
                     lc_error_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           'Multiple Deliver To Locations For '
                        || ' '
                        || cur_stage_rec.deliver_to_location_id;
                     fnd_file.put_line
                                      (fnd_file.LOG,
                                          'Multiple Deliver To Locations For '
                                       || ' '
                                       || cur_stage_rec.deliver_to_location_id
                                      );
                     fnd_file.put_line
                                      (fnd_file.output,
                                          'Multiple Deliver To Locations For '
                                       || ' '
                                       || cur_stage_rec.deliver_to_location_id
                                      );
                  WHEN OTHERS
                  THEN
                     lc_error_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           'Error while Validating Deliver To  location id '
                        || ' '
                        || cur_stage_rec.deliver_to_location_id
                        || '_'
                        || SUBSTR (SQLERRM, 1, 100);
                     fnd_file.put_line
                          (fnd_file.LOG,
                              'Error while Validating Deliver To  locationid '
                           || ' '
                           || cur_stage_rec.deliver_to_location_id
                           || '_'
                           || SUBSTR (SQLERRM, 1, 250)
                          );
                     fnd_file.put_line
                          (fnd_file.output,
                              'Error while Validating Deliver To  location id'
                           || ' '
                           || cur_stage_rec.deliver_to_location_id
                           || '_'
                           || SUBSTR (SQLERRM, 1, 250)
                          );
               END;
            END IF;

--+-----------------------------------------------------------------+--
--Validation of operating unit
--+-----------------------------------------------------------------+--
            IF cur_stage_rec.org_id IS NOT NULL
            THEN
               BEGIN
                  ln_org_id := NULL;
                  lc_orgerr_flag := 'N';

                  SELECT hou.organization_id,
                         hou.NAME
                    INTO ln_org_id,
                         lc_opearting_unit
                    FROM hr_operating_units hou
                   WHERE hou.organization_id = cur_stage_rec.org_id;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     lc_orgerr_flag := 'Y';
                     lc_error_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                                   'Invalid  ORG_ID.' || cur_stage_rec.org_id;
                     fnd_file.put_line (fnd_file.LOG,
                                           'Invalid  ORG_ID.'
                                        || cur_stage_rec.org_id
                                       );
                     fnd_file.put_line (fnd_file.output,
                                           'Invalid  ORG_ID.'
                                        || cur_stage_rec.org_id
                                       );
                  WHEN TOO_MANY_ROWS
                  THEN
                     lc_orgerr_flag := 'Y';
                     lc_error_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           'Duplicate Orgids defined in the system.'
                        || cur_stage_rec.org_id;
                     fnd_file.put_line
                                 (fnd_file.LOG,
                                     'Duplicate Orgids defined in the system.'
                                  || cur_stage_rec.org_id
                                 );
                     fnd_file.put_line
                                 (fnd_file.output,
                                     'Duplicate Orgids defined in the system.'
                                  || cur_stage_rec.org_id
                                 );
                  WHEN OTHERS
                  THEN
                     lc_orgerr_flag := 'Y';
                     lc_error_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           'Error while validating ORG_ID.'
                        || cur_stage_rec.org_id
                        || SUBSTR (SQLERRM, 1, 100);
                     fnd_file.put_line (fnd_file.LOG,
                                           'Error while validating ORG_ID.'
                                        || cur_stage_rec.org_id
                                        || SUBSTR (SQLERRM, 1, 250)
                                       );
                     fnd_file.put_line (fnd_file.output,
                                           'Error while validating ORG_ID.'
                                        || cur_stage_rec.org_id
                                        || SUBSTR (SQLERRM, 1, 250)
                                       );
               END;

               IF     lc_orgerr_flag <> 'Y'
                  AND cur_stage_rec.operating_unit IS NOT NULL
               THEN
                  IF TRIM (lc_opearting_unit) <>
                                          TRIM (cur_stage_rec.operating_unit)
                  THEN
                     lc_error_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           'Derived operating Unit is not Same as Given operating Unit'
                        || lc_opearting_unit
                        || '='
                        || cur_stage_rec.operating_unit;
                     fnd_file.put_line
                        (fnd_file.LOG,
                            'Derived operating Unit is not Same as Given operating Unit'
                         || lc_opearting_unit
                         || '='
                         || cur_stage_rec.operating_unit
                        );
                     fnd_file.put_line
                        (fnd_file.output,
                            'Derived operating Unit is not Same as Given operating Unit'
                         || lc_opearting_unit
                         || '='
                         || cur_stage_rec.operating_unit
                        );
                  END IF;
               END IF;
            ELSIF cur_stage_rec.operating_unit IS NOT NULL
            THEN
               ln_org_id := NULL;
               lc_opearting_unit := NULL;

               BEGIN
                  SELECT hou.organization_id,
                         hou.NAME
                    INTO ln_org_id,
                         lc_opearting_unit
                    FROM hr_operating_units hou
                   WHERE UPPER (hou.NAME) =
                                          UPPER (cur_stage_rec.operating_unit)
                     AND organization_id =
                                 (SELECT operating_unit
                                    FROM org_organization_definitions
                                   WHERE organization_id = ln_organization_id);
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     lc_error_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           'Invalid Operating Unit '
                        || ' -'
                        || cur_stage_rec.operating_unit;
                     fnd_file.put_line (fnd_file.LOG,
                                           'Invalid Operating Unit '
                                        || ' -'
                                        || cur_stage_rec.operating_unit
                                       );
                     fnd_file.put_line (fnd_file.output,
                                           'Invalid Operating Unit '
                                        || ' -'
                                        || cur_stage_rec.operating_unit
                                       );
                  WHEN TOO_MANY_ROWS
                  THEN
                     lc_orgerr_flag := 'Y';
                     lc_error_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           'Multiple  Orgids Available for.'
                        || ' -'
                        || cur_stage_rec.operating_unit;
                     fnd_file.put_line (fnd_file.LOG,
                                           'Multiple  Orgids Available for.'
                                        || ' -'
                                        || cur_stage_rec.operating_unit
                                       );
                     fnd_file.put_line (fnd_file.output,
                                           'Multiple  Orgids Available for.'
                                        || ' -'
                                        || cur_stage_rec.operating_unit
                                       );
                  WHEN OTHERS
                  THEN
                     lc_error_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           'Error while deriving  Validating operaring Unit '
                        || ' '
                        || cur_stage_rec.operating_unit
                        || SUBSTR (SQLERRM, 1, 250);
                     fnd_file.put_line
                        (fnd_file.LOG,
                            'Error while deriving  Validating operating Unit '
                         || ' '
                         || cur_stage_rec.operating_unit
                         || SUBSTR (SQLERRM, 1, 250)
                        );
                     fnd_file.put_line
                        (fnd_file.output,
                            'Error while deriving  Validating operating Unit '
                         || ' '
                         || cur_stage_rec.operating_unit
                         || SUBSTR (SQLERRM, 1, 250)
                        );
               END;
            ELSIF     cur_stage_rec.operating_unit IS NULL
                  AND cur_stage_rec.org_id IS NULL
            THEN
               lc_error_flag := 'Y';
               ln_error_no := ln_error_no + 1;
               lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
               lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
               lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
               lt_error_tbl (ln_error_no).error_msg :=
                  'operating_unit and  Org_id can not be null to derive ORG_ID.';
               fnd_file.put_line
                  (fnd_file.LOG,
                   'operating_unit and  Org_id can not be null to derive ORG_ID.'
                  );
               fnd_file.put_line
                  (fnd_file.output,
                   'operating_unit and  Org_id can not be null to derive ORG_ID.'
                  );
            END IF;

--+-----------------------------------------------+------------------------------------------
--+  Deriving default Inventory Otganization id from financial Options for Operating unit+--
--+-----------------------------------------------+-----------------------------------------
            BEGIN
               ln_fin_invorgan_id := NULL;

               SELECT inventory_organization_id
                 INTO ln_fin_invorgan_id
                 FROM financials_system_parameters
                WHERE org_id = ln_org_id;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  lc_error_flag := 'Y';
                  ln_error_no := ln_error_no + 1;
                  lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                  lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                  lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                  lt_error_tbl (ln_error_no).error_msg :=
                        'Inventory Organization is not aasigned for Operating Unit in Financial Options '
                     || ' -'
                     || lc_opearting_unit;
                  fnd_file.put_line
                     (fnd_file.LOG,
                         'Inventory Organization is not aasigned for Operating Unit in Financial Options '
                      || ' -'
                      || lc_opearting_unit
                     );
                  fnd_file.put_line
                     (fnd_file.output,
                         'Inventory Organization is not aasigned for Operating Unit in Financial Options '
                      || ' -'
                      || lc_opearting_unit
                     );
               WHEN TOO_MANY_ROWS
               THEN
                  lc_orgerr_flag := 'Y';
                  lc_error_flag := 'Y';
                  ln_error_no := ln_error_no + 1;
                  lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                  lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                  lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                  lt_error_tbl (ln_error_no).error_msg :=
                        'Multiple Inventory Organizations  Assigned for operating unit'
                     || ' -'
                     || lc_opearting_unit
                     || ' '
                     || 'In financial Options';
                  fnd_file.put_line
                     (fnd_file.LOG,
                         'Multiple Inventory Organizations  Assigned for operating unit'
                      || ' -'
                      || lc_opearting_unit
                      || ' '
                      || 'In financial Options'
                     );
                  fnd_file.put_line
                     (fnd_file.output,
                         'Multiple Inventory Organizations  Assigned for operating unit'
                      || ' -'
                      || lc_opearting_unit
                      || ' '
                      || 'In financial Options'
                     );
               WHEN OTHERS
               THEN
                  lc_error_flag := 'Y';
                  ln_error_no := ln_error_no + 1;
                  lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                  lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                  lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                  lt_error_tbl (ln_error_no).error_msg :=
                        'Error while deriving Inventory Organization for operaring Unit '
                     || ' '
                     || lc_opearting_unit
                     || SUBSTR (SQLERRM, 1, 250);
                  fnd_file.put_line
                     (fnd_file.LOG,
                         'Error while deriving Inventory Organization for operaring Unit '
                      || ' '
                      || lc_opearting_unit
                      || SUBSTR (SQLERRM, 1, 250)
                     );
                  fnd_file.put_line
                        (fnd_file.output,
                            'Error while deriving  Validating operating Unit '
                         || ' '
                         || lc_opearting_unit
                         || SUBSTR (SQLERRM, 1, 250)
                        );
            END;

--+-----------------------------------------------+--
--+   Item code validation  and Deriving Item_Id    +--
--+-----------------------------------------------+--
            IF     cur_stage_rec.item_segment1 IS NULL
               AND cur_stage_rec.item_id IS NULL
            THEN
               lc_error_flag := 'Y';
               ln_error_no := ln_error_no + 1;
               lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
               lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
               lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
               lt_error_tbl (ln_error_no).error_msg :=
                                         'Item  AND Item_id cannot be null .';
               fnd_file.put_line (fnd_file.LOG,
                                  'Item  AND Item_id cannot be null .'
                                 );
               fnd_file.put_line (fnd_file.output,
                                  'Item  AND Item_id cannot be null .'
                                 );
            ELSIF cur_stage_rec.item_segment1 IS NOT NULL
            THEN
               --Item Validation for Destination Organization_id
               BEGIN
                  ln_item_id := NULL;
                  lc_segment1 := NULL;
                  lc_item_description := NULL;
                  lc_primary_uom_code := NULL;
                  lc_unit_of_measure := NULL;

                  SELECT inventory_item_id,
                         description,
                         primary_uom_code,
                         primary_unit_of_measure,
                         concatenated_segments
                    INTO ln_item_id,
                         lc_item_description,
                         lc_primary_uom_code,
                         lc_unit_of_measure,
                         lc_segment1
                    FROM mtl_system_items_kfv
                   WHERE organization_id = ln_organization_id
                     AND UPPER (concatenated_segments) =
                                           UPPER (cur_stage_rec.item_segment1)
                     AND purchasing_item_flag = 'Y';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     lc_itemdesc_flag := 'Y';
                     lc_error_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                         'Invalid  item_Code:' || cur_stage_rec.item_segment1;
                     fnd_file.put_line (fnd_file.LOG,
                                           'Invalid  item_Code:'
                                        || cur_stage_rec.item_segment1
                                       );
                     fnd_file.put_line (fnd_file.output,
                                           'Invalid  item_Code:'
                                        || cur_stage_rec.item_segment1
                                       );
                  WHEN TOO_MANY_ROWS
                  THEN
                     lc_error_flag := 'Y';
                     lc_itemdesc_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           'Multiple Items are existed for'
                        || cur_stage_rec.item_segment1;
                     fnd_file.put_line (fnd_file.LOG,
                                           'Multiple Items are existed for'
                                        || cur_stage_rec.item_segment1
                                       );
                     fnd_file.put_line (fnd_file.output,
                                           'Multiple Items are existed for'
                                        || cur_stage_rec.item_segment1
                                       );
                  WHEN OTHERS
                  THEN
                     lc_error_flag := 'Y';
                     lc_itemdesc_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           'Error while validating Item code'
                        || cur_stage_rec.item_segment1
                        || SUBSTR (SQLERRM, 1, 100);
                     fnd_file.put_line (fnd_file.LOG,
                                           'Error while validating Item code'
                                        || cur_stage_rec.item_segment1
                                        || SUBSTR (SQLERRM, 1, 250)
                                       );
                     fnd_file.put_line (fnd_file.output,
                                           'Error while validating Item code'
                                        || cur_stage_rec.item_segment1
                                        || SUBSTR (SQLERRM, 1, 250)
                                       );
               END;

               --Validating Item_code for Financial Inventory organization_id
               BEGIN
                  ln_invitem_id := NULL;

                  SELECT inventory_item_id
                    INTO ln_invitem_id
                    FROM mtl_system_items_kfv
                   WHERE organization_id = ln_fin_invorgan_id
                     AND UPPER (concatenated_segments) =
                                           UPPER (cur_stage_rec.item_segment1)
                     AND purchasing_item_flag = 'Y';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     lc_itemdesc_flag := 'Y';
                     lc_error_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           'Invalid  item_Code:'
                        || cur_stage_rec.item_segment1
                        || ' '
                        || 'In Inventory  Organization'
                        || '-'
                        || ln_fin_invorgan_id;
                     fnd_file.put_line (fnd_file.LOG,
                                           'Invalid  item_Code:'
                                        || cur_stage_rec.item_segment1
                                        || ' '
                                        || 'In Inventory  Organization'
                                        || '-'
                                        || ln_fin_invorgan_id
                                       );
                     fnd_file.put_line (fnd_file.output,
                                           'Invalid  item_Code:'
                                        || cur_stage_rec.item_segment1
                                        || ' '
                                        || 'In Inventory  Organization'
                                        || '-'
                                        || ln_fin_invorgan_id
                                       );
                  WHEN TOO_MANY_ROWS
                  THEN
                     lc_error_flag := 'Y';
                     lc_itemdesc_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           'Multiple Items are existed for'
                        || cur_stage_rec.item_segment1
                        || ' '
                        || 'In Inventory Organization'
                        || '-'
                        || ln_fin_invorgan_id;
                     fnd_file.put_line (fnd_file.LOG,
                                           'Multiple Items are existed for'
                                        || cur_stage_rec.item_segment1
                                        || ' '
                                        || 'In Inventory Organization'
                                        || '-'
                                        || ln_fin_invorgan_id
                                       );
                     fnd_file.put_line (fnd_file.output,
                                           'Multiple Items are existed for'
                                        || cur_stage_rec.item_segment1
                                        || ' '
                                        || 'In Inventory Organization'
                                        || '-'
                                        || ln_fin_invorgan_id
                                       );
                  WHEN OTHERS
                  THEN
                     lc_error_flag := 'Y';
                     lc_itemdesc_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           'Error while validating Item code'
                        || cur_stage_rec.item_segment1
                        || ' '
                        || 'In Inventory Organization'
                        || '-'
                        || ln_fin_invorgan_id
                        || SUBSTR (SQLERRM, 1, 100);
                     fnd_file.put_line (fnd_file.LOG,
                                           'Error while validating Item code'
                                        || cur_stage_rec.item_segment1
                                        || ' '
                                        || 'In Inventory Organization'
                                        || '-'
                                        || ln_fin_invorgan_id
                                        || SUBSTR (SQLERRM, 1, 100)
                                       );
                     fnd_file.put_line (fnd_file.output,
                                           'Error while validating Item code'
                                        || cur_stage_rec.item_segment1
                                        || ' '
                                        || 'In Inventory Organization'
                                        || '-'
                                        || ln_fin_invorgan_id
                                        || SUBSTR (SQLERRM, 1, 100)
                                       );
               END;

               IF lc_itemdesc_flag <> 'Y'
               THEN
                  IF ln_item_id <> ln_invitem_id
                  THEN
                     lc_error_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           ' Destination Org item_id is not Same as  inventory organization Item_id'
                        || ln_item_id
                        || '='
                        || ln_invitem_id;
                     fnd_file.put_line
                        (fnd_file.LOG,
                            'Destination Org item_id is not Same as  inventory organization Item_id'
                         || ln_item_id
                         || '='
                         || ln_invitem_id
                        );
                     fnd_file.put_line
                        (fnd_file.output,
                            'Destination Org item_id is not Same as  inventory organization Item_id'
                         || ln_item_id
                         || '='
                         || ln_invitem_id
                        );
                  END IF;

                  IF cur_stage_rec.item_id IS NOT NULL
                  THEN
                     IF ln_item_id <> cur_stage_rec.item_id
                     THEN
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Derived Item_id is not Same as Given Item_id'
                           || ln_item_id
                           || '='
                           || cur_stage_rec.item_id;
                        fnd_file.put_line
                            (fnd_file.LOG,
                                'Derived Item_id is not Same as Given Item_id'
                             || ln_item_id
                             || '='
                             || cur_stage_rec.item_id
                            );
                        fnd_file.put_line
                            (fnd_file.output,
                                'Derived Item_id is not Same as Given Item_id'
                             || ln_item_id
                             || '='
                             || cur_stage_rec.item_id
                            );
                     END IF;
                  END IF;
               END IF;
            ELSIF cur_stage_rec.item_id IS NOT NULL
            THEN
               --Validating Item_id for Destination organization_id
               BEGIN
                  ln_item_id := NULL;
                  lc_segment1 := NULL;
                  lc_item_description := NULL;
                  lc_primary_uom_code := NULL;
                  lc_unit_of_measure := NULL;

                  SELECT inventory_item_id,
                         description,
                         primary_uom_code,
                         primary_unit_of_measure,
                         concatenated_segments
                    INTO ln_item_id,
                         lc_item_description,
                         lc_primary_uom_code,
                         lc_unit_of_measure,
                         lc_segment1
                    FROM mtl_system_items_kfv
                   WHERE organization_id = ln_organization_id
                     AND inventory_item_id = cur_stage_rec.item_id
                     AND purchasing_item_flag = 'Y';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     lc_segerr_flag := 'Y';
                     lc_error_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           'Invalid item_id:' || '-' || cur_stage_rec.item_id;
                     fnd_file.put_line (fnd_file.LOG,
                                           'Invalid item_id:'
                                        || '-'
                                        || cur_stage_rec.item_id
                                       );
                     fnd_file.put_line (fnd_file.output,
                                           'Invalid item_id:'
                                        || '-'
                                        || cur_stage_rec.item_id
                                       );
                  WHEN TOO_MANY_ROWS
                  THEN
                     lc_segerr_flag := 'Y';
                     lc_error_flag := 'Y';
                     lc_curr_flag := 'E';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           'Multiple Items  are existed for'
                        || ' '
                        || cur_stage_rec.item_id;
                     fnd_file.put_line (fnd_file.LOG,
                                           'Multiple Items  are existed for'
                                        || ' '
                                        || cur_stage_rec.item_id
                                       );
                     fnd_file.put_line (fnd_file.output,
                                           'Multiple Items  are existed for'
                                        || ' '
                                        || cur_stage_rec.item_id
                                       );
                  WHEN OTHERS
                  THEN
                     lc_segerr_flag := 'Y';
                     lc_error_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           'Error while Validating Item_id'
                        || cur_stage_rec.item_id
                        || SUBSTR (SQLERRM, 1, 100);
                     fnd_file.put_line (fnd_file.LOG,
                                           'Error while Validating Item_id'
                                        || cur_stage_rec.item_id
                                        || SUBSTR (SQLERRM, 1, 100)
                                       );
                     fnd_file.put_line (fnd_file.output,
                                           'Error while Validating Item_id'
                                        || cur_stage_rec.item_id
                                        || SUBSTR (SQLERRM, 1, 100)
                                       );
               END;

               --Validating Item_id for Financial Inventory organization_id
               BEGIN
                  ln_invitem_id := NULL;

                  SELECT inventory_item_id
                    INTO ln_invitem_id
                    FROM mtl_system_items_kfv
                   WHERE organization_id = ln_fin_invorgan_id
                     AND inventory_item_id = cur_stage_rec.item_id
                     AND purchasing_item_flag = 'Y';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     lc_itemdesc_flag := 'Y';
                     lc_error_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           'Invalid  item_id:'
                        || cur_stage_rec.item_id
                        || ' '
                        || 'In Inventory  Organization'
                        || '-'
                        || ln_fin_invorgan_id;
                     fnd_file.put_line (fnd_file.LOG,
                                           'Invalid  item_id:'
                                        || cur_stage_rec.item_id
                                        || ' '
                                        || 'In Inventory  Organization'
                                        || '-'
                                        || ln_fin_invorgan_id
                                       );
                     fnd_file.put_line (fnd_file.output,
                                           'Invalid  item_Id:'
                                        || cur_stage_rec.item_id
                                        || ' '
                                        || 'In Inventory  Organization'
                                        || '-'
                                        || ln_fin_invorgan_id
                                       );
                  WHEN TOO_MANY_ROWS
                  THEN
                     lc_error_flag := 'Y';
                     lc_itemdesc_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           'Multiple Items are existed for'
                        || cur_stage_rec.item_id
                        || ' '
                        || 'In Inventory Organization'
                        || '-'
                        || ln_fin_invorgan_id;
                     fnd_file.put_line (fnd_file.LOG,
                                           'Multiple Items are existed for'
                                        || cur_stage_rec.item_id
                                        || ' '
                                        || 'In Inventory Organization'
                                        || '-'
                                        || ln_fin_invorgan_id
                                       );
                     fnd_file.put_line (fnd_file.output,
                                           'Multiple Items are existed for'
                                        || cur_stage_rec.item_id
                                        || ' '
                                        || 'In Inventory Organization'
                                        || '-'
                                        || ln_fin_invorgan_id
                                       );
                  WHEN OTHERS
                  THEN
                     lc_error_flag := 'Y';
                     lc_itemdesc_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           'Error while validating Item code'
                        || cur_stage_rec.item_id
                        || ' '
                        || 'In Inventory Organization'
                        || '-'
                        || ln_fin_invorgan_id
                        || SUBSTR (SQLERRM, 1, 100);
                     fnd_file.put_line (fnd_file.LOG,
                                           'Error while validating Item code'
                                        || cur_stage_rec.item_id
                                        || ' '
                                        || 'In Inventory Organization'
                                        || '-'
                                        || ln_fin_invorgan_id
                                        || SUBSTR (SQLERRM, 1, 100)
                                       );
                     fnd_file.put_line (fnd_file.output,
                                           'Error while validating Item code'
                                        || cur_stage_rec.item_id
                                        || ' '
                                        || 'In Inventory Organization'
                                        || '-'
                                        || ln_fin_invorgan_id
                                        || SUBSTR (SQLERRM, 1, 100)
                                       );
               END;

               IF ln_item_id <> ln_invitem_id
               THEN
                  lc_error_flag := 'Y';
                  ln_error_no := ln_error_no + 1;
                  lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                  lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                  lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                  lt_error_tbl (ln_error_no).error_msg :=
                        ' Destination Org item_id is not Same as  inventory organization Item_id'
                     || ln_item_id
                     || '='
                     || ln_invitem_id;
                  fnd_file.put_line
                     (fnd_file.LOG,
                         'Destination Org item_id is not Same as  inventory organization Item_id'
                      || ln_item_id
                      || '='
                      || ln_invitem_id
                     );
                  fnd_file.put_line
                     (fnd_file.output,
                         'Destination Org item_id is not Same as  inventory organization Item_id'
                      || ln_item_id
                      || '='
                      || ln_invitem_id
                     );
               END IF;
            END IF;

--+-----------------------------------------------------------------+--
--Deriving Charge Accountid for ITEM
--+-----------------------------------------------------------------+--
            BEGIN
               BEGIN
                  ln_charge_account_id := NULL;
                  lc_chargeerr_flag := NULL;

                  SELECT expense_account
                    INTO ln_charge_account_id
                    FROM mtl_system_items_kfv
                   WHERE inventory_item_id = ln_item_id
                     AND organization_id = ln_organization_id;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     lc_chargeerr_flag := 'N';
                  WHEN TOO_MANY_ROWS
                  THEN
                     lc_error_flag := 'Y';
                     lc_chargeerr_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           'Multiple Charge account Id''s'' are existed for Item'
                        || ln_item_id;
                     fnd_file.put_line
                        (fnd_file.LOG,
                            'Multiple Charge account Id''s'' are existed for Item'
                         || ln_item_id
                        );
                     fnd_file.put_line
                        (fnd_file.output,
                            'Multiple Charge account Id''s'' are existed for Item'
                         || ln_item_id
                        );
                  WHEN OTHERS
                  THEN
                     lc_error_flag := 'Y';
                     lc_chargeerr_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           'Exception Raised whileDeriving Charge Account_id for Item'
                        || ' '
                        || ln_item_id
                        || SUBSTR (SQLERRM, 1, 100);
                     fnd_file.put_line
                        (fnd_file.LOG,
                            'Exception Raised whileDeriving Charge Account_id for Item'
                         || ' '
                         || ln_item_id
                         || SUBSTR (SQLERRM, 1, 100)
                        );
                     fnd_file.put_line
                        (fnd_file.output,
                            'Exception Raised whileDeriving Charge Account_id for Item'
                         || ' '
                         || ln_item_id
                         || SUBSTR (SQLERRM, 1, 100)
                        );
               END;

               IF lc_chargeerr_flag = 'N' AND ln_charge_account_id IS NULL
               THEN
                  BEGIN
                     ln_charge_account_id := NULL;
                     lc_chargeerr_flag := NULL;

                     SELECT attribute7
                       INTO ln_charge_account_id
                       FROM mtl_parameters
                      WHERE organization_id = ln_organization_id;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        lc_chargeerr_flag := 'N';
                     WHEN TOO_MANY_ROWS
                     THEN
                        lc_error_flag := 'Y';
                        lc_chargeerr_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Multiple Charge account Ids are Assigned for Organization'
                           || ln_organization_id;
                        fnd_file.put_line
                           (fnd_file.LOG,
                               'Multiple Charge account Ids are existed for Item'
                            || ln_item_id
                           );
                        fnd_file.put_line
                           (fnd_file.output,
                               'Multiple Charge account Ids are Assigned for Organization'
                            || ln_organization_id
                           );
                     WHEN OTHERS
                     THEN
                        lc_error_flag := 'Y';
                        lc_chargeerr_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Exception Raised whileDeriving Charge Account_id for Organization'
                           || ' '
                           || ln_organization_id
                           || SUBSTR (SQLERRM, 1, 100);
                        fnd_file.put_line
                           (fnd_file.LOG,
                               'Exception Raised whileDeriving Charge Account_id for Organization'
                            || ' '
                            || ln_organization_id
                            || SUBSTR (SQLERRM, 1, 100)
                           );
                        fnd_file.put_line
                           (fnd_file.output,
                               'Exception Raised whileDeriving Charge Account_id for Organization'
                            || ' '
                            || ln_organization_id
                            || SUBSTR (SQLERRM, 1, 100)
                           );
                  END;
               END IF;

               IF lc_chargeerr_flag = 'N' AND ln_charge_account_id IS NULL
               THEN
                  lc_error_flag := 'Y';
                  ln_error_no := ln_error_no + 1;
                  lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                  lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                  lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                  lt_error_tbl (ln_error_no).error_msg :=
                        ' NO Charge Account_id Available FOR Item '
                     || ' '
                     || ln_item_id
                     || ' and Organization'
                     || ' '
                     || ln_organization_id;
                  fnd_file.put_line
                               (fnd_file.LOG,
                                   ' NO Charge Account_id Available FOR Item '
                                || ' '
                                || ln_item_id
                                || ' and Organization'
                                || ' '
                                || ln_organization_id
                               );
                  fnd_file.put_line
                               (fnd_file.output,
                                   ' NO Charge Account_id Available FOR Item '
                                || ' '
                                || ln_item_id
                                || ' and Organization'
                                || ' '
                                || ln_organization_id
                               );
               END IF;
            END;

-----------------------------------------------------------------------------------------------
--Deriving of Category_id
-----------------------------------------------------------------------------------------------
            BEGIN
               IF cur_stage_rec.category_id IS NOT NULL
               THEN
                  BEGIN
                     ln_category_id := NULL;
                     lc_category_segment1 := NULL;

                     SELECT mck.category_id,
                            mck.concatenated_segments
                       INTO ln_category_id,
                            lc_category_segment1
                       FROM mtl_categories_kfv mck
                      WHERE mck.category_id = cur_stage_rec.category_id;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        lc_curr_flag := 'E';
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                           'Invalid  Category id'
                           || cur_stage_rec.category_id;
                        fnd_file.put_line (fnd_file.LOG,
                                              ' Invalid  Category id'
                                           || cur_stage_rec.category_id
                                          );
                        fnd_file.put_line (fnd_file.output,
                                              ' Invalid  Category id'
                                           || cur_stage_rec.category_id
                                          );
                     WHEN TOO_MANY_ROWS
                     THEN
                        lc_error_flag := 'Y';
                        lc_curr_flag := 'E';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Duplicate Category_ids are existed'
                           || '-'
                           || cur_stage_rec.category_id;
                        fnd_file.put_line
                                      (fnd_file.LOG,
                                          'Duplicate Category_ids are existed'
                                       || '-'
                                       || cur_stage_rec.category_id
                                      );
                        fnd_file.put_line
                                      (fnd_file.output,
                                          'Duplicate Category_ids are existed'
                                       || '-'
                                       || cur_stage_rec.category_id
                                      );
                     WHEN OTHERS
                     THEN
                        lc_error_flag := 'Y';
                        lc_curr_flag := 'E';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Error while Validating Category ID '
                           || cur_stage_rec.category_id
                           || SUBSTR (SQLERRM, 1, 100);
                        fnd_file.put_line
                                     (fnd_file.LOG,
                                         'Error while Validating Category ID '
                                      || cur_stage_rec.category_id
                                      || SUBSTR (SQLERRM, 1, 250)
                                     );
                        fnd_file.put_line
                                     (fnd_file.output,
                                         'Error while Validating Category ID '
                                      || cur_stage_rec.category_id
                                      || SUBSTR (SQLERRM, 1, 250)
                                     );
                  END;

                  IF     lc_category_segment1 IS NOT NULL
                     AND cur_stage_rec.category_segment1 IS NOT NULL
                  THEN
                     IF lc_category_segment1 <>
                                              cur_stage_rec.category_segment1
                     THEN
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Derived category segments   is not Same as Given  category segments '
                           || lc_category_segment1
                           || '='
                           || cur_stage_rec.category_segment1;
                        fnd_file.put_line
                           (fnd_file.LOG,
                               'Derived category segments   is not Same as Given  category segments '
                            || lc_category_segment1
                            || '='
                            || cur_stage_rec.category_segment1
                           );
                        fnd_file.put_line
                           (fnd_file.output,
                               'Derived category segments   is not Same as Given  category segments '
                            || lc_category_segment1
                            || '='
                            || cur_stage_rec.category_segment1
                           );
                     END IF;
                  END IF;
               ELSIF cur_stage_rec.category_segment1 IS NOT NULL
               THEN
                  BEGIN
                     SELECT mck.category_id,
                            mck.concatenated_segments
                       INTO ln_category_id,
                            lc_category_segment1
                       FROM mtl_categories_kfv mck
                      WHERE UPPER (mck.concatenated_segments) =
                                       UPPER (cur_stage_rec.category_segment1);
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        lc_curr_flag := 'E';
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              ' Invalid  Category segment'
                           || '- '
                           || cur_stage_rec.category_segment1;
                        fnd_file.put_line (fnd_file.LOG,
                                              'Invalid  Category segment'
                                           || '- '
                                           || cur_stage_rec.category_segment1
                                          );
                        fnd_file.put_line (fnd_file.output,
                                              'Invalid  Category segment'
                                           || '- '
                                           || cur_stage_rec.category_segment1
                                          );
                     WHEN TOO_MANY_ROWS
                     THEN
                        lc_error_flag := 'Y';
                        lc_curr_flag := 'E';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Duplicate Category_ids are existed for'
                           || ' '
                           || cur_stage_rec.category_segment1;
                        fnd_file.put_line
                                  (fnd_file.LOG,
                                      'Duplicate Category_ids are existed for'
                                   || ' '
                                   || cur_stage_rec.category_segment1
                                  );
                        fnd_file.put_line
                                  (fnd_file.output,
                                      'Duplicate Category_ids are existed for'
                                   || ' '
                                   || cur_stage_rec.category_segment1
                                  );
                     WHEN OTHERS
                     THEN
                        lc_error_flag := 'Y';
                        lc_curr_flag := 'E';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Error while Validating Category segement '
                           || ' '
                           || cur_stage_rec.category_segment1
                           || ' '
                           || SUBSTR (SQLERRM, 1, 100);
                        fnd_file.put_line
                               (fnd_file.LOG,
                                   'Error while Validating Category segement '
                                || ' '
                                || cur_stage_rec.category_segment1
                                || ' '
                                || SUBSTR (SQLERRM, 1, 100)
                               );
                        fnd_file.put_line
                               (fnd_file.output,
                                   'Error while Validating Category segement '
                                || ' '
                                || cur_stage_rec.category_segment1
                                || ' '
                                || SUBSTR (SQLERRM, 1, 100)
                               );
                  END;
               ELSIF ln_item_id IS NOT NULL
               THEN
                  BEGIN
                     ln_category_id := NULL;
                     lc_category_segment1 := NULL;

                     SELECT mck.category_id,
                            mck.concatenated_segments
                       INTO ln_category_id,
                            lc_category_segment1
                       FROM mtl_categories_kfv mck,
                            mtl_system_items_kfv msik,
                            mtl_item_categories mic,
                            mtl_category_sets mcs
                      WHERE msik.inventory_item_id = mic.inventory_item_id
                        AND mic.category_id = mck.category_id
                        AND msik.organization_id = mic.organization_id
                        AND mck.structure_id = mcs.structure_id
                        AND UPPER (mcs.category_set_name) =
                                                        'INFRATEL PO CATEGORY'
                        AND mic.category_set_id = mcs.category_set_id
                        AND msik.organization_id = ln_organization_id
                        AND msik.inventory_item_id = ln_item_id
                        AND msik.purchasing_enabled_flag = 'Y';
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        lc_curr_flag := 'E';
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                           ' No Category is assigned for ' || ','
                           || ln_item_id;
                        fnd_file.put_line (fnd_file.LOG,
                                              ' No Category is assigned for '
                                           || ','
                                           || ln_item_id
                                          );
                        fnd_file.put_line (fnd_file.output,
                                              'No Category is assigned for '
                                           || ','
                                           || ln_item_id
                                          );
                     WHEN TOO_MANY_ROWS
                     THEN
                        lc_error_flag := 'Y';
                        lc_curr_flag := 'E';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Duplicate Category_ids are existed for'
                           || '-'
                           || ln_item_id;
                        fnd_file.put_line
                                  (fnd_file.LOG,
                                      'Duplicate Category_ids are existed for'
                                   || '-'
                                   || ln_item_id
                                  );
                        fnd_file.put_line
                                  (fnd_file.output,
                                      'Duplicate Category_ids are existed for'
                                   || '-'
                                   || ln_item_id
                                  );
                     WHEN OTHERS
                     THEN
                        lc_error_flag := 'Y';
                        lc_curr_flag := 'E';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Exception Raised  while deriving Category ID for'
                           || '-'
                           || ln_item_id
                           || SUBSTR (SQLERRM, 1, 100);
                        fnd_file.put_line
                                     (fnd_file.LOG,
                                         'Error while Validating Category ID '
                                      || '-'
                                      || ln_item_id
                                      || SUBSTR (SQLERRM, 1, 250)
                                     );
                        fnd_file.put_line
                                     (fnd_file.output,
                                         'Error while Validating Category ID '
                                      || '-'
                                      || ln_item_id
                                      || SUBSTR (SQLERRM, 1, 250)
                                     );
                  END;
               ELSE
                  lc_curr_flag := 'E';
                  lc_error_flag := 'Y';
                  ln_error_no := ln_error_no + 1;
                  lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                  lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                  lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                  lt_error_tbl (ln_error_no).error_msg :=
                                                'Category id can not be null';
                  fnd_file.put_line (fnd_file.LOG,
                                     'Category id can not be null'
                                    );
                  fnd_file.put_line (fnd_file.output,
                                     'Category id can not be null'
                                    );
               END IF;
            END;

--+-----------------------------------------------------------------+--
--Validation of Preparer name
--+-----------------------------------------------------------------+--
--FND_FILE.PUT_LINE(FND_FILE.LOG, 'Validation of Preparer name');
            BEGIN
               IF     cur_stage_rec.preparer_name IS NULL
                  AND cur_stage_rec.preparer_id IS NULL
               THEN
                  lc_error_flag := 'Y';
                  ln_error_no := ln_error_no + 1;
                  lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                  lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                  lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                  lt_error_tbl (ln_error_no).error_msg :=
                              'Preparer Name and preparer_id cannot be null.';
                  fnd_file.put_line
                             (fnd_file.LOG,
                              'Preparer Name and preparer_id cannot be null.'
                             );
                  fnd_file.put_line
                              (fnd_file.output,
                               'Preparer Name and preparer_id cannot be null.'
                              );
               ELSIF cur_stage_rec.preparer_id IS NOT NULL
               THEN
                  BEGIN
                     lc_preparer := NULL;
                     ln_preparer_id := NULL;

                     SELECT papf.full_name,
                            papf.person_id
                       INTO lc_preparer,
                            ln_preparer_id
                       FROM per_all_people_f papf,
                            per_all_assignments_f paaf,
                            per_assignment_status_types past,
                            fnd_user fu
                      WHERE paaf.person_id = papf.person_id
                        AND paaf.primary_flag = 'Y'
                        AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                                AND papf.effective_end_date
                        AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                                AND paaf.effective_end_date
                        AND papf.employee_number IS NOT NULL
                        AND paaf.assignment_type = 'E'
                        AND paaf.assignment_status_type_id =
                                                past.assignment_status_type_id
                        AND UPPER (past.per_system_status) = 'ACTIVE_ASSIGN'
                        AND papf.person_id = fu.employee_id
                        AND papf.person_id = cur_stage_rec.preparer_id
                        AND ROWNUM < 2;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Invalid Preparer id '
                           || '-'
                           || cur_stage_rec.preparer_id;
                        fnd_file.put_line (fnd_file.LOG,
                                              'Invalid Preparer id .'
                                           || '-'
                                           || cur_stage_rec.preparer_id
                                          );
                        fnd_file.put_line (fnd_file.output,
                                              'Invalid Preparer id .'
                                           || '-'
                                           || cur_stage_rec.preparer_id
                                          );
                     WHEN OTHERS
                     THEN
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Error while validating Preparer id '
                           || '-'
                           || cur_stage_rec.preparer_id
                           || SUBSTR (SQLERRM, 1, 250);
                        fnd_file.put_line
                                     (fnd_file.LOG,
                                         'Error while validating Preparer id '
                                      || '-'
                                      || cur_stage_rec.preparer_id
                                      || SUBSTR (SQLERRM, 1, 250)
                                     );
                        fnd_file.put_line
                                     (fnd_file.output,
                                         'Error while validating Preparer id '
                                      || '-'
                                      || cur_stage_rec.preparer_id
                                      || SUBSTR (SQLERRM, 1, 250)
                                     );
                  END;

                  IF     lc_preparer IS NOT NULL
                     AND cur_stage_rec.preparer_name IS NOT NULL
                  THEN
                     IF lc_preparer <> cur_stage_rec.preparer_name
                     THEN
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Derived Preparer name is not Same as Preparer name '
                           || lc_preparer
                           || '='
                           || cur_stage_rec.preparer_name;
                        fnd_file.put_line
                           (fnd_file.LOG,
                               'Derived Preparer name is not Same as Preparer name '
                            || lc_preparer
                            || '='
                            || cur_stage_rec.preparer_name
                           );
                        fnd_file.put_line
                           (fnd_file.output,
                               'Derived Preparer name is not Same as Preparer name '
                            || lc_preparer
                            || '='
                            || cur_stage_rec.preparer_name
                           );
                     END IF;
                  END IF;
               ELSIF cur_stage_rec.preparer_name IS NOT NULL
               THEN
                  BEGIN
                     lc_preparer := NULL;
                     ln_preparer_id := NULL;

                     SELECT papf.full_name,
                            papf.person_id
                       INTO lc_preparer,
                            ln_preparer_id
                       FROM per_all_people_f papf,
                            per_all_assignments_f paaf,
                            per_assignment_status_types past,
                            fnd_user fu
                      WHERE paaf.person_id = papf.person_id
                        AND paaf.primary_flag = 'Y'
                        AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                                AND papf.effective_end_date
                        AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                                AND paaf.effective_end_date
                        AND papf.employee_number IS NOT NULL
                        AND paaf.assignment_type = 'E'
                        AND paaf.assignment_status_type_id =
                                                past.assignment_status_type_id
                        AND UPPER (past.per_system_status) = 'ACTIVE_ASSIGN'
                        AND papf.person_id = fu.employee_id
                        --AND papf.person_id       =cur_stage_rec.preparer_id
                        AND UPPER (papf.full_name) =
                                           UPPER (cur_stage_rec.preparer_name)
                        AND ROWNUM < 2;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Invalid preparer_name.'
                           || '-'
                           || cur_stage_rec.preparer_name;
                        fnd_file.put_line
                                  (fnd_file.LOG,
                                      'Invalid Preparer id AND preparer_name.'
                                   || '-'
                                   || cur_stage_rec.preparer_name
                                  );
                        fnd_file.put_line (fnd_file.output,
                                              'Invalid preparer_name.'
                                           || '-'
                                           || cur_stage_rec.preparer_name
                                          );
                     WHEN OTHERS
                     THEN
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Error while validating  preparer_name.'
                           || '-'
                           || cur_stage_rec.preparer_name
                           || SUBSTR (SQLERRM, 1, 250);
                        fnd_file.put_line
                                  (fnd_file.LOG,
                                      'Error while validating  preparer_name.'
                                   || '-'
                                   || cur_stage_rec.preparer_name
                                   || SUBSTR (SQLERRM, 1, 250)
                                  );
                        fnd_file.put_line
                                  (fnd_file.output,
                                      'Error while validating  preparer_name.'
                                   || '-'
                                   || cur_stage_rec.preparer_name
                                   || SUBSTR (SQLERRM, 1, 250)
                                  );
                  END;
               END IF;
            END;

--+-----------------------------------------------------------------+--
--Validation of Quantity
--+-----------------------------------------------------------------+--
-- FND_FILE.PUT_LINE(FND_FILE.LOG, 'Validation of Quantity');
            BEGIN
               IF cur_stage_rec.quantity IS NULL
                  OR cur_stage_rec.quantity < 0
               THEN
                  lc_error_flag := 'Y';
                  ln_error_no := ln_error_no + 1;
                  lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                  lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                  lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                  lt_error_tbl (ln_error_no).error_msg :=
                                      'Quantity cannot be null OR Negative .';
                  fnd_file.put_line (fnd_file.LOG,
                                     'Quantity cannot be null OR Negative.'
                                    );
                  fnd_file.put_line (fnd_file.output,
                                     'Quantity cannot be null OR Negative.'
                                    );
               END IF;
            END;

--+-----------------------------------------------------------------+--
--Validation of Deliver To Requestor Name
            BEGIN
               IF     cur_stage_rec.deliver_to_requestor_name IS NULL
                  AND cur_stage_rec.deliver_to_requestor_id IS NULL
               THEN
                  --Insert Into Error Table
                  lc_error_flag := 'Y';
                  ln_error_no := ln_error_no + 1;
                  lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                  lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                  lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                  lt_error_tbl (ln_error_no).error_msg :=
                     'Deliver To requestor Name AND Requestor_id  cannot be null.';
                  fnd_file.put_line
                     (fnd_file.LOG,
                      'Deliver To requestor Name AND Requestor_id cannot be null.'
                     );
                  fnd_file.put_line
                     (fnd_file.output,
                      'Deliver To requestor Name AND Requestor_id cannot be null.'
                     );
               ELSIF cur_stage_rec.deliver_to_requestor_id IS NOT NULL
               THEN
                  lc_requestor := NULL;
                  ln_deliver_to_requestor_id := NULL;
                  ln_deliver_to_requestor_id :=
                                        cur_stage_rec.deliver_to_requestor_id;

                  BEGIN
                     SELECT papf.person_id,
                            papf.full_name
                       INTO ln_deliver_to_requestor_id,
                            lc_requestor
                       FROM per_all_people_f papf,
                            per_all_assignments_f paaf,
                            per_assignment_status_types past
                      -- ,po_agents pa
                     WHERE  paaf.person_id = papf.person_id
                        AND paaf.primary_flag = 'Y'
                        AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                                AND papf.effective_end_date
                        AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                                AND paaf.effective_end_date
                        AND papf.employee_number IS NOT NULL
                        AND paaf.assignment_type = 'E'
                        AND paaf.assignment_status_type_id =
                                                past.assignment_status_type_id
                        AND past.per_system_status IN ('ACTIVE_ASSIGN')
                        ---AND papf.person_id=pa.agent_id
                        AND papf.person_id = ln_deliver_to_requestor_id
                        AND ROWNUM < 2;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        lc_requestor_flag := 'Y';
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              ' Invalid Deliver To requestor_id'
                           || ln_deliver_to_requestor_id;
                        fnd_file.put_line
                                        (fnd_file.LOG,
                                            ' Invalid Deliver To requestor_id'
                                         || ln_deliver_to_requestor_id
                                        );
                        fnd_file.put_line
                                        (fnd_file.output,
                                            ' Invalid Deliver To requestor_id'
                                         || ln_deliver_to_requestor_id
                                        );
                     WHEN TOO_MANY_ROWS
                     THEN
                        lc_requestor_flag := 'Y';
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Duplicate Deliver To requestor_ids  existed'
                           || ln_deliver_to_requestor_id;
                        fnd_file.put_line
                             (fnd_file.LOG,
                                 'Duplicate Deliver To requestor_ids  existed'
                              || ln_deliver_to_requestor_id
                             );
                        fnd_file.put_line
                             (fnd_file.output,
                                 'Duplicate Deliver To requestor_ids  existed'
                              || ln_deliver_to_requestor_id
                             );
                     WHEN OTHERS
                     THEN
                        lc_requestor_flag := 'Y';
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Invalid Deliver To requestor_id'
                           || ln_deliver_to_requestor_id
                           || SUBSTR (SQLERRM, 1, 100);
                        fnd_file.put_line
                                         (fnd_file.LOG,
                                             'Invalid Deliver To requestor_id'
                                          || ln_deliver_to_requestor_id
                                          || SUBSTR (SQLERRM, 1, 250)
                                         );
                        fnd_file.put_line
                                         (fnd_file.output,
                                             'Invalid Deliver To requestor_id'
                                          || ln_deliver_to_requestor_id
                                          || SUBSTR (SQLERRM, 1, 250)
                                         );
                  END;

                  IF lc_requestor_flag <> 'Y'
                  THEN
                     IF     lc_requestor IS NOT NULL
                        AND cur_stage_rec.deliver_to_requestor_name IS NOT NULL
                     THEN
                        IF lc_requestor <>
                                      cur_stage_rec.deliver_to_requestor_name
                        THEN
                           lc_error_flag := 'Y';
                           ln_error_no := ln_error_no + 1;
                           lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                           lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                           lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                           lt_error_tbl (ln_error_no).error_msg :=
                                 'Derived requestor_name  is not Same as Given requestor_name  '
                              || lc_requestor
                              || '='
                              || cur_stage_rec.deliver_to_requestor_name;
                           fnd_file.put_line
                              (fnd_file.LOG,
                                  'Derived requestor_name  is not Same as Given requestor_name  '
                               || lc_requestor
                               || '='
                               || cur_stage_rec.deliver_to_requestor_name
                              );
                           fnd_file.put_line
                              (fnd_file.output,
                                  'Derived requestor_name  is not Same as Given requestor_name  '
                               || lc_requestor
                               || '='
                               || cur_stage_rec.deliver_to_requestor_name
                              );
                        END IF;
                     END IF;
                  END IF;
               ELSIF cur_stage_rec.deliver_to_requestor_name IS NOT NULL
               THEN
                  lc_requestor := cur_stage_rec.deliver_to_requestor_name;
                  ln_deliver_to_requestor_id := NULL;

                  BEGIN
                     SELECT papf.person_id,
                            papf.full_name
                       INTO ln_deliver_to_requestor_id,
                            lc_requestor
                       FROM per_all_people_f papf,
                            per_all_assignments_f paaf,
                            per_assignment_status_types past
                      -- ,po_agents pa
                     WHERE  paaf.person_id = papf.person_id
                        AND paaf.primary_flag = 'Y'
                        AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                                AND papf.effective_end_date
                        AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                                AND paaf.effective_end_date
                        AND papf.employee_number IS NOT NULL
                        AND paaf.assignment_type = 'E'
                        AND paaf.assignment_status_type_id =
                                                past.assignment_status_type_id
                        AND past.per_system_status IN ('ACTIVE_ASSIGN')
                        ---AND papf.person_id=pa.agent_id
                        AND UPPER (papf.full_name) = UPPER (lc_requestor)
                        AND ROWNUM < 2;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              ' Invalid Deliver To requestor name'
                           || ' '
                           || lc_requestor;
                        fnd_file.put_line
                                      (fnd_file.LOG,
                                          ' Invalid Deliver To requestor Name'
                                       || ' '
                                       || lc_requestor
                                      );
                        fnd_file.put_line
                                      (fnd_file.output,
                                          ' Invalid Deliver To requestor Name'
                                       || ' '
                                       || lc_requestor
                                      );
                     WHEN OTHERS
                     THEN
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Invalid Deliver To requestor name'
                           || ' '
                           || lc_requestor
                           || SUBSTR (SQLERRM, 1, 100);
                        fnd_file.put_line
                                      (fnd_file.LOG,
                                          'Invalid Deliver To requestor name '
                                       || ' '
                                       || lc_requestor
                                       || SUBSTR (SQLERRM, 1, 250)
                                      );
                        fnd_file.put_line
                                       (fnd_file.output,
                                           'Invalid Deliver To requestor name'
                                        || ' '
                                        || lc_requestor
                                        || SUBSTR (SQLERRM, 1, 250)
                                       );
                  END;
               END IF;
            END;

--+-----------------------------------------------------------------+--
--Validation of currency code and derive and validate rate,rate type,rate date for a Currency Code
--+-----------------------------------------------------------------+--
-- FND_FILE.PUT_LINE(FND_FILE.LOG,
--'Validation of rate,rate type,rate date for a Currency Code');
            BEGIN
               IF cur_stage_rec.currency_code IS NOT NULL
               THEN
                  lc_curr_flag := 'Y';

                  BEGIN
                     lc_currency_code := NULL;

                     SELECT fc.currency_code
                       INTO lc_currency_code
                       FROM fnd_currencies fc
                      WHERE UPPER (fc.currency_code) =
                                           UPPER (cur_stage_rec.currency_code)
                        AND fc.enabled_flag = 'Y'
                        AND fc.currency_flag = 'Y'
                        AND (   (SYSDATE BETWEEN fc.start_date_active
                                             AND fc.end_date_active
                                )
                             OR (    fc.start_date_active IS NULL
                                 AND fc.end_date_active IS NULL
                                )
                             OR (    fc.start_date_active IS NULL
                                 AND fc.end_date_active > SYSDATE
                                )
                             OR (    fc.start_date_active <= SYSDATE
                                 AND fc.end_date_active IS NULL
                                )
                            );
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              ' Invalid Currency_code'
                           || cur_stage_rec.currency_code;
                        fnd_file.put_line (fnd_file.LOG,
                                              ' Invalid Currency_code'
                                           || cur_stage_rec.currency_code
                                          );
                        fnd_file.put_line (fnd_file.output,
                                              ' Invalid Currency_code'
                                           || cur_stage_rec.currency_code
                                          );
                     WHEN TOO_MANY_ROWS
                     THEN
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Duplicate Currency_codes'
                           || cur_stage_rec.currency_code;
                        fnd_file.put_line (fnd_file.LOG,
                                              'Duplicate Currency_codes'
                                           || cur_stage_rec.currency_code
                                          );
                        fnd_file.put_line (fnd_file.output,
                                              'Duplicate Currency_codes'
                                           || cur_stage_rec.currency_code
                                          );
                     WHEN OTHERS
                     THEN
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Error while Validating currency_code '
                           || cur_stage_rec.currency_code
                           || SUBSTR (SQLERRM, 1, 100);
                        fnd_file.put_line
                                   (fnd_file.LOG,
                                       'Error while Validating currency_code '
                                    || cur_stage_rec.currency_code
                                    || SUBSTR (SQLERRM, 1, 250)
                                   );
                        fnd_file.put_line
                                   (fnd_file.output,
                                       'Error while Validating currency_code '
                                    || cur_stage_rec.currency_code
                                    || SUBSTR (SQLERRM, 1, 250)
                                   );
                  END;
               ELSE
                  lc_currency_code := 'INR';
               END IF;
            END;

--+---------------------------------+--
--+   Validation for Need By Date   +--
--+---------------------------------+--
            BEGIN
               IF cur_stage_rec.need_by_date IS NULL
               THEN
                  lc_error_flag := 'Y';
                  ln_error_no := ln_error_no + 1;
                  --Insert Into Error Table
                  lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                  lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                  lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                  lt_error_tbl (ln_error_no).error_msg :=
                                              'Need_by_date Cannot be NULL .';
                  fnd_file.put_line (fnd_file.LOG,
                                     'Need_by_date Cannot be NULL .'
                                    );
                  fnd_file.put_line (fnd_file.output,
                                     'Need_by_date Cannot be NULL .'
                                    );
               END IF;
            END;

-----------------------------------------------------------------------------------------------
--Validation of Subinventory
-----------------------------------------------------------------------------------------------
            BEGIN
               IF cur_stage_rec.destination_subinventory IS NOT NULL
               THEN
                  BEGIN
                     lc_sub_inventory_name := NULL;

                     SELECT secondary_inventory_name
                       INTO lc_sub_inventory_name
                       FROM mtl_secondary_inventories
                      WHERE UPPER (secondary_inventory_name) =
                                UPPER (cur_stage_rec.destination_subinventory)
                        AND organization_id = ln_organization_id;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        lc_curr_flag := 'E';
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              ' Invalid  destination subinventory '
                           || '-'
                           || cur_stage_rec.destination_subinventory;
                        fnd_file.put_line
                                       (fnd_file.LOG,
                                           'Invalid  destination subinventory'
                                        || '-'
                                        || cur_stage_rec.destination_subinventory
                                       );
                        fnd_file.put_line
                              (fnd_file.output,
                                  ' Invalid Invalid  destination subinventory'
                               || '-'
                               || cur_stage_rec.destination_subinventory
                              );
                     WHEN TOO_MANY_ROWS
                     THEN
                        lc_error_flag := 'Y';
                        lc_curr_flag := 'E';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Multiple  destination subinventories existed'
                           || '-'
                           || cur_stage_rec.destination_subinventory;
                        fnd_file.put_line
                            (fnd_file.LOG,
                                'Multiple  destination subinventories existed'
                             || '-'
                             || cur_stage_rec.destination_subinventory
                            );
                        fnd_file.put_line
                            (fnd_file.output,
                                'Multiple  destination subinventories existed'
                             || '-'
                             || cur_stage_rec.destination_subinventory
                            );
                     WHEN OTHERS
                     THEN
                        lc_error_flag := 'Y';
                        lc_curr_flag := 'E';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Error while Validating destination subinventory '
                           || '-'
                           || cur_stage_rec.destination_subinventory
                           || SUBSTR (SQLERRM, 1, 100);
                        fnd_file.put_line
                           (fnd_file.LOG,
                               'Error while Validating destination subinventory '
                            || '-'
                            || cur_stage_rec.destination_subinventory
                            || SUBSTR (SQLERRM, 1, 250)
                           );
                        fnd_file.put_line
                           (fnd_file.output,
                               'Error while Validating destination subinventory '
                            || '-'
                            || cur_stage_rec.destination_subinventory
                            || SUBSTR (SQLERRM, 1, 250)
                           );
                  END;
               END IF;
            END;

-----------------------------------------------------------------------------------------------
--Validation of line type
-----------------------------------------------------------------------------------------------
---FND_FILE.PUT_LINE(FND_FILE.LOG, 'Validation of line type');
            BEGIN
               IF     cur_stage_rec.line_type IS NULL
                  AND cur_stage_rec.line_type_id IS NULL
               THEN
                  lc_error_flag := 'Y';
                  ln_error_no := ln_error_no + 1;
                  --Insert Into Error Table
                  lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                  lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                  lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                  lt_error_tbl (ln_error_no).error_msg :=
                                'Line Type_id and LIne type can not be null.';
                  fnd_file.put_line
                               (fnd_file.LOG,
                                'Line Type_id and LIne type can not be null.'
                               );
                  fnd_file.put_line
                                 (fnd_file.output,
                                  'Line Type_id and LIne type can not be null'
                                 );
               ELSIF cur_stage_rec.line_type_id IS NOT NULL
               THEN
                  BEGIN
                     ln_line_type_id := NULL;
                     lc_line_type := NULL;

                     SELECT line_type_id,
                            line_type
                       INTO ln_line_type_id,
                            lc_line_type
                       FROM po_line_types plt
                      WHERE plt.line_type_id = cur_stage_rec.line_type_id
                        AND plt.outside_operation_flag = 'N';
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'line_type_id is  not valid'
                           || cur_stage_rec.line_type_id;
                        fnd_file.put_line (fnd_file.LOG,
                                              'line_type_id is  not valid'
                                           || cur_stage_rec.line_type_id
                                          );
                        fnd_file.put_line (fnd_file.output,
                                              'line_type_id   is  not valid'
                                           || cur_stage_rec.line_type_id
                                          );
                     WHEN TOO_MANY_ROWS
                     THEN
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Duplicate line_type_ids  are existed'
                           || cur_stage_rec.line_type_id;
                        fnd_file.put_line
                                     (fnd_file.LOG,
                                         'Duplicate line_type_ids are existed'
                                      || cur_stage_rec.line_type_id
                                     );
                        fnd_file.put_line
                                     (fnd_file.output,
                                         'Duplicate line_type_ids are existed'
                                      || cur_stage_rec.line_type_id
                                     );
                     WHEN OTHERS
                     THEN
                        lc_error_flag := 'Y';
                        lc_curr_flag := 'E';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Error while Validating line_type_id '
                           || SUBSTR (SQLERRM, 1, 100);
                        fnd_file.put_line
                                     (fnd_file.LOG,
                                         'Error while Validating line_type_id'
                                      || cur_stage_rec.currency_code
                                      || SUBSTR (SQLERRM, 1, 250)
                                     );
                        fnd_file.put_line
                                     (fnd_file.output,
                                         'Error while Validating line_type_id'
                                      || SUBSTR (SQLERRM, 1, 250)
                                     );

                        IF     lc_line_type IS NOT NULL
                           AND cur_stage_rec.line_type IS NOT NULL
                        THEN
                           IF lc_line_type <> cur_stage_rec.line_type
                           THEN
                              lc_error_flag := 'Y';
                              ln_error_no := ln_error_no + 1;
                              lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                              lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                              lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                              lt_error_tbl (ln_error_no).error_msg :=
                                    'Derived line_type  is not Same as Given line_typ '
                                 || lc_line_type
                                 || '='
                                 || cur_stage_rec.line_type;
                              fnd_file.put_line
                                 (fnd_file.LOG,
                                     'Derived line_type  is not Same as Given line_typ '
                                  || lc_line_type
                                  || '='
                                  || cur_stage_rec.line_type
                                 );
                              fnd_file.put_line
                                 (fnd_file.output,
                                     'Derived line_type  is not Same as Given line_typ '
                                  || lc_line_type
                                  || '='
                                  || cur_stage_rec.line_type
                                 );
                           END IF;
                        END IF;
                  END;
               ELSIF cur_stage_rec.line_type IS NOT NULL
               THEN
                  BEGIN
                     ln_line_type_id := NULL;
                     lc_line_type := NULL;

                     SELECT line_type_id,
                            line_type
                       INTO ln_line_type_id,
                            lc_line_type
                       FROM po_line_types plt
                      WHERE plt.line_type = cur_stage_rec.line_type
                        AND plt.outside_operation_flag = 'N';
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Invalid line type ' || cur_stage_rec.line_type;
                        fnd_file.put_line (fnd_file.LOG,
                                              'Invalid line type'
                                           || cur_stage_rec.line_type
                                          );
                        fnd_file.put_line (fnd_file.output,
                                              'Invalid line type'
                                           || cur_stage_rec.line_type
                                          );
                     WHEN TOO_MANY_ROWS
                     THEN
                        lc_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Duplicate line_type_ids are existed for'
                           || '_'
                           || cur_stage_rec.line_type;
                        fnd_file.put_line
                                 (fnd_file.LOG,
                                     'Duplicate line_type_ids are existed for'
                                  || '_'
                                  || cur_stage_rec.line_type_id
                                  || cur_stage_rec.line_type
                                 );
                        fnd_file.put_line
                                 (fnd_file.output,
                                     'Duplicate line_type_ids are existed for'
                                  || '_'
                                  || cur_stage_rec.line_type
                                 );
                     WHEN OTHERS
                     THEN
                        lc_error_flag := 'Y';
                        lc_curr_flag := 'E';
                        ln_error_no := ln_error_no + 1;
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Error while validating line_type '
                           || cur_stage_rec.line_type
                           || SUBSTR (SQLERRM, 1, 100);
                        fnd_file.put_line
                                        (fnd_file.LOG,
                                            'Error while Validating line_type'
                                         || cur_stage_rec.line_type
                                         || SUBSTR (SQLERRM, 1, 250)
                                        );
                        fnd_file.put_line
                                        (fnd_file.output,
                                            'Error while Validating line_type'
                                         || cur_stage_rec.line_type
                                         || SUBSTR (SQLERRM, 1, 250)
                                        );
                  END;
               END IF;
            END;

            ----------Inserting the records into Interface Table..
            IF lc_error_flag <> 'Y'
            THEN
               UPDATE bilc_po_pr_staging_tbl
                  SET status = 'VALID',
                      last_updated_by = fnd_global.user_id,
                      last_update_date = SYSDATE
                WHERE ROWID = cur_stage_rec.row_id;

               COMMIT;

--+-------------------------------------------------------------------------+--
--+         Inserting Record into PO_REQUISITIONS_INTERFACE_ALL Table       +--
--+-------------------------------------------------------------------------+--
--FND_FILE.PUT_LINE(FND_FILE.LOG, 'Entered In Insert Procedure');
               BEGIN
                  --FND_FILE.PUT_LINE(FND_FILE.LOG, 'Entered1');
                  INSERT INTO po_requisitions_interface_all
                              (transaction_id,
                               process_flag,
                               request_id,
                               program_id,
                               program_application_id,
                               program_update_date,
                               last_updated_by,
                               last_update_date,
                               last_update_login,
                               creation_date,
                               created_by,
                               interface_source_code,
                               interface_source_line_id,
                               source_type_code,
                               requisition_header_id,
                               requisition_line_id,
                               req_distribution_id,
                               requisition_type,
                               destination_type_code,
                               item_description,
                               quantity,
                               unit_price,
                               authorization_status,
                               batch_id,
                               group_code,
                               delete_enabled_flag,
                               update_enabled_flag,
                               approver_id,
                               approver_name,
                               approval_path_id,
                               note_to_approver,
                               preparer_id,
                               autosource_flag,
                               req_number_segment1,
                               req_number_segment2,
                               req_number_segment3,
                               req_number_segment4,
                               req_number_segment5,
                               header_description,
                               header_attribute_category,
                               header_attribute1,
                               header_attribute2,
                               header_attribute3,
                               header_attribute4,
                               header_attribute5,
                               header_attribute6,
                               header_attribute7,
                               header_attribute8,
                               header_attribute9,
                               header_attribute10,
                               header_attribute11,
                               header_attribute12,
                               header_attribute13,
                               header_attribute14,
                               urgent_flag,
                               header_attribute15,
                               rfq_required_flag,
                               justification,
                               note_to_buyer,
                               note_to_receiver,
                               item_id,
                               item_segment1,
                               item_segment2,
                               item_segment3,
                               item_segment4,
                               item_segment5,
                               item_segment6,
                               item_segment7,
                               item_segment8,
                               item_segment9,
                               item_segment10,
                               item_segment11,
                               item_segment12,
                               item_segment13,
                               item_segment14,
                               item_segment15,
                               item_segment16,
                               item_segment17,
                               item_segment18,
                               item_segment19,
                               item_segment20,
                               item_revision,
                               charge_account_id,
                               charge_account_segment1,
                               charge_account_segment2,
                               charge_account_segment3,
                               charge_account_segment4,
                               charge_account_segment5,
                               charge_account_segment6,
                               charge_account_segment7,
                               charge_account_segment8,
                               charge_account_segment9,
                               charge_account_segment10,
                               charge_account_segment11,
                               charge_account_segment12,
                               charge_account_segment13,
                               charge_account_segment14,
                               charge_account_segment15,
                               charge_account_segment16,
                               charge_account_segment17,
                               charge_account_segment18,
                               charge_account_segment19,
                               charge_account_segment20,
                               charge_account_segment21,
                               charge_account_segment22,
                               charge_account_segment23,
                               charge_account_segment24,
                               charge_account_segment25,
                               charge_account_segment26,
                               charge_account_segment27,
                               charge_account_segment28,
                               charge_account_segment29,
                               charge_account_segment30,
                               category_id,
                               category_segment1,
                               category_segment2,
                               category_segment3,
                               category_segment4,
                               category_segment5,
                               category_segment6,
                               category_segment7,
                               category_segment8,
                               category_segment9,
                               category_segment10,
                               category_segment11,
                               category_segment12,
                               category_segment13,
                               category_segment14,
                               category_segment15,
                               category_segment16,
                               category_segment17,
                               category_segment18,
                               category_segment19,
                               category_segment20,
                               unit_of_measure,
                               uom_code,
                               line_type_id,
                               line_type,
                               un_number_id,
                               un_number,
                               hazard_class_id,
                               hazard_class,
                               must_use_sugg_vendor_flag,
                               reference_num,
                               wip_entity_id,
                               wip_line_id,
                               wip_operation_seq_num,
                               wip_resource_seq_num,
                               wip_repetitive_schedule_id,
                               project_num,
                               task_num,
                               expenditure_type,
                               source_organization_id,
                               source_organization_code,
                               source_subinventory,
                               destination_organization_id,
                               destination_organization_code,
                               destination_subinventory,
                               deliver_to_location_id,
                               deliver_to_location_code,
                               deliver_to_requestor_id,
                               deliver_to_requestor_name,
                               suggested_buyer_id,
                               suggested_buyer_name,
                               suggested_vendor_name,
                               suggested_vendor_id,
                               suggested_vendor_site,
                               suggested_vendor_site_id,
                               suggested_vendor_contact,
                               suggested_vendor_contact_id,
                               suggested_vendor_phone,
                               suggested_vendor_item_num,
                               line_attribute_category,
                               line_attribute1,
                               line_attribute2,
                               line_attribute3,
                               line_attribute4,
                               line_attribute5,
                               line_attribute6,
                               line_attribute7,
                               line_attribute8,
                               line_attribute9,
                               line_attribute10,
                               line_attribute11,
                               line_attribute12,
                               line_attribute13,
                               line_attribute14,
                               line_attribute15,
                               need_by_date,
                               note1_id,
                               note2_id,
                               note3_id,
                               note4_id,
                               note5_id,
                               note6_id,
                               note7_id,
                               note8_id,
                               note9_id,
                               note10_id,
                               note1_title,
                               note2_title,
                               note3_title,
                               note4_title,
                               note5_title,
                               note6_title,
                               note7_title,
                               note8_title,
                               note9_title,
                               note10_title,
                               gl_date,
                               dist_attribute_category,
                               distribution_attribute1,
                               distribution_attribute2,
                               distribution_attribute3,
                               distribution_attribute4,
                               distribution_attribute5,
                               distribution_attribute6,
                               distribution_attribute7,
                               distribution_attribute8,
                               distribution_attribute9,
                               distribution_attribute10,
                               distribution_attribute11,
                               distribution_attribute12,
                               distribution_attribute13,
                               distribution_attribute14,
                               distribution_attribute15,
                               preparer_name,
                               bom_resource_id,
                               accrual_account_id,
                               variance_account_id,
                               budget_account_id,
                               ussgl_transaction_code,
                               government_context,
                               currency_code,
                               currency_unit_price,
                               rate,
                               rate_date,
                               rate_type,
                               prevent_encumbrance_flag,
                               autosource_doc_header_id,
                               autosource_doc_line_num,
                               project_accounting_context,
                               expenditure_organization_id,
                               project_id,
                               task_id,
                               end_item_unit_number,
                               expenditure_item_date,
                               document_type_code,
                               org_id,
                               transaction_reason_code,
                               allocation_type,
                               allocation_value,
                               multi_distributions,
                               req_dist_sequence_id,
                               kanban_card_id,
                               emergency_po_num,
                               award_id,
                               tax_code_id,
                               oke_contract_header_id,
                               oke_contract_num,
                               oke_contract_version_id,
                               oke_contract_line_id,
                               oke_contract_line_num,
                               oke_contract_deliverable_id,
                               oke_contract_deliverable_num,
                               secondary_unit_of_measure,
                               secondary_uom_code,
                               secondary_quantity,
                               preferred_grade,
                               vmi_flag,
                               tax_user_override_flag,
                               amount,
                               currency_amount,
                               ship_method,
                               estimated_pickup_date,
                               base_unit_price,
                               negotiated_by_preparer_flag
                              )
                       VALUES (cur_stage_rec.transaction_id,
                               cur_stage_rec.process_flag,
                               g_request_id,
                               g_program_id,
                               g_application_id,
                               SYSDATE,
                               g_user_id,
                               SYSDATE,
                               g_user_id,
                               SYSDATE,
                               g_user_id,
                               cur_stage_rec.interface_source_code,
                               cur_stage_rec.interface_source_line_id,
                               lc_source_type_code,
                               NULL,    ---cur_stage_rec.requisition_header_id
                               NULL,      ---cur_stage_rec.requisition_line_id
                               NULL,       --cur_stage_rec.req_distribution_id
                               'PURCHASE',
                               lc_dest_type_code,
                               lc_item_description,
                               cur_stage_rec.quantity,
                               cur_stage_rec.unit_price,
                               'APPROVED',
                               cur_stage_rec.batch_id,
                               cur_stage_rec.group_code,
                               cur_stage_rec.delete_enabled_flag,
                               cur_stage_rec.update_enabled_flag,
                               cur_stage_rec.approver_id,
                               cur_stage_rec.approver_name,
                               cur_stage_rec.approval_path_id,
                               cur_stage_rec.note_to_approver,
                               ln_preparer_id,
                               cur_stage_rec.autosource_flag,
                               cur_stage_rec.req_number_segment1,
                               cur_stage_rec.req_number_segment2,
                               cur_stage_rec.req_number_segment3,
                               cur_stage_rec.req_number_segment4,
                               cur_stage_rec.req_number_segment5,
                               cur_stage_rec.header_description,
                               cur_stage_rec.header_attribute_category,
                               cur_stage_rec.header_attribute1,
                               cur_stage_rec.header_attribute2,
                               cur_stage_rec.header_attribute3,
                               cur_stage_rec.header_attribute4,
                               cur_stage_rec.header_attribute5,
                               cur_stage_rec.header_attribute6,
                               cur_stage_rec.header_attribute7,
                               cur_stage_rec.header_attribute8,
                               cur_stage_rec.header_attribute9,
                               cur_stage_rec.header_attribute10,
                               cur_stage_rec.header_attribute11,
                               cur_stage_rec.header_attribute12,
                               cur_stage_rec.header_attribute13,
                               cur_stage_rec.header_attribute14,
                               cur_stage_rec.urgent_flag,
                               cur_stage_rec.header_attribute15,
                               cur_stage_rec.rfq_required_flag,
                               cur_stage_rec.justification,
                               cur_stage_rec.note_to_buyer,
                               cur_stage_rec.note_to_receiver,
                               ln_item_id,
                               lc_segment1,
                               cur_stage_rec.item_segment2,
                               cur_stage_rec.item_segment3,
                               cur_stage_rec.item_segment4,
                               cur_stage_rec.item_segment5,
                               cur_stage_rec.item_segment6,
                               cur_stage_rec.item_segment7,
                               cur_stage_rec.item_segment8,
                               cur_stage_rec.item_segment9,
                               cur_stage_rec.item_segment10,
                               cur_stage_rec.item_segment11,
                               cur_stage_rec.item_segment12,
                               cur_stage_rec.item_segment13,
                               cur_stage_rec.item_segment14,
                               cur_stage_rec.item_segment15,
                               cur_stage_rec.item_segment16,
                               cur_stage_rec.item_segment17,
                               cur_stage_rec.item_segment18,
                               cur_stage_rec.item_segment19,
                               cur_stage_rec.item_segment20,
                               cur_stage_rec.item_revision,
                               ln_charge_account_id,
                               cur_stage_rec.charge_account_segment1,
                               cur_stage_rec.charge_account_segment2,
                               cur_stage_rec.charge_account_segment3,
                               cur_stage_rec.charge_account_segment4,
                               cur_stage_rec.charge_account_segment5,
                               cur_stage_rec.charge_account_segment6,
                               cur_stage_rec.charge_account_segment7,
                               cur_stage_rec.charge_account_segment8,
                               cur_stage_rec.charge_account_segment9,
                               cur_stage_rec.charge_account_segment10,
                               cur_stage_rec.charge_account_segment11,
                               cur_stage_rec.charge_account_segment12,
                               cur_stage_rec.charge_account_segment13,
                               cur_stage_rec.charge_account_segment14,
                               cur_stage_rec.charge_account_segment15,
                               cur_stage_rec.charge_account_segment16,
                               cur_stage_rec.charge_account_segment17,
                               cur_stage_rec.charge_account_segment18,
                               cur_stage_rec.charge_account_segment19,
                               cur_stage_rec.charge_account_segment20,
                               cur_stage_rec.charge_account_segment21,
                               cur_stage_rec.charge_account_segment22,
                               cur_stage_rec.charge_account_segment23,
                               cur_stage_rec.charge_account_segment24,
                               cur_stage_rec.charge_account_segment25,
                               cur_stage_rec.charge_account_segment26,
                               cur_stage_rec.charge_account_segment27,
                               cur_stage_rec.charge_account_segment28,
                               cur_stage_rec.charge_account_segment29,
                               cur_stage_rec.charge_account_segment30,
                               ln_category_id,
                               lc_category_segment1,
                               cur_stage_rec.category_segment2,
                               cur_stage_rec.category_segment3,
                               cur_stage_rec.category_segment4,
                               cur_stage_rec.category_segment5,
                               cur_stage_rec.category_segment6,
                               cur_stage_rec.category_segment7,
                               cur_stage_rec.category_segment8,
                               cur_stage_rec.category_segment9,
                               cur_stage_rec.category_segment10,
                               cur_stage_rec.category_segment11,
                               cur_stage_rec.category_segment12,
                               cur_stage_rec.category_segment13,
                               cur_stage_rec.category_segment14,
                               cur_stage_rec.category_segment15,
                               cur_stage_rec.category_segment16,
                               cur_stage_rec.category_segment17,
                               cur_stage_rec.category_segment18,
                               cur_stage_rec.category_segment19,
                               cur_stage_rec.category_segment20,
                               lc_unit_of_measure,
                               lc_primary_uom_code,
                               ln_line_type_id,
                               lc_line_type,
                               cur_stage_rec.un_number_id,
                               cur_stage_rec.un_number,
                               cur_stage_rec.hazard_class_id,
                               cur_stage_rec.hazard_class,
                               cur_stage_rec.must_use_sugg_vendor_flag,
                               cur_stage_rec.reference_num,
                               cur_stage_rec.wip_entity_id,
                               cur_stage_rec.wip_line_id,
                               cur_stage_rec.wip_operation_seq_num,
                               cur_stage_rec.wip_resource_seq_num,
                               cur_stage_rec.wip_repetitive_schedule_id,
                               cur_stage_rec.project_num,
                               cur_stage_rec.task_num,
                               cur_stage_rec.expenditure_type,
                               cur_stage_rec.source_organization_id,
                               cur_stage_rec.source_organization_code,
                               cur_stage_rec.source_subinventory,
                               ln_organization_id,
                               lc_organization_code,
                               lc_sub_inventory_name,
                               ln_location_id,
                               lc_location_code,
                               ln_deliver_to_requestor_id,
                               lc_requestor,
                               cur_stage_rec.suggested_buyer_id,
                               cur_stage_rec.suggested_buyer_name,
                               cur_stage_rec.suggested_vendor_name,
                               cur_stage_rec.suggested_vendor_id,
                               cur_stage_rec.suggested_vendor_site,
                               cur_stage_rec.suggested_vendor_site_id,
                               cur_stage_rec.suggested_vendor_contact,
                               cur_stage_rec.suggested_vendor_contact_id,
                               cur_stage_rec.suggested_vendor_phone,
                               cur_stage_rec.suggested_vendor_item_num,
                               cur_stage_rec.line_attribute_category,
                               cur_stage_rec.line_attribute1,
                               cur_stage_rec.line_attribute2,
                               cur_stage_rec.line_attribute3,
                               cur_stage_rec.line_attribute4,
                               cur_stage_rec.line_attribute5,
                               cur_stage_rec.line_attribute6,
                               cur_stage_rec.line_attribute7,
                               cur_stage_rec.line_attribute8,
                               cur_stage_rec.line_attribute9,
                               cur_stage_rec.line_attribute10,
                               cur_stage_rec.line_attribute11,
                               cur_stage_rec.line_attribute12,
                               cur_stage_rec.line_attribute13,
                               cur_stage_rec.line_attribute14,
                               cur_stage_rec.line_attribute15,
                               cur_stage_rec.need_by_date,
                               cur_stage_rec.note1_id,
                               cur_stage_rec.note2_id,
                               cur_stage_rec.note3_id,
                               cur_stage_rec.note4_id,
                               cur_stage_rec.note5_id,
                               cur_stage_rec.note6_id,
                               cur_stage_rec.note7_id,
                               cur_stage_rec.note8_id,
                               cur_stage_rec.note9_id,
                               cur_stage_rec.note10_id,
                               cur_stage_rec.note1_title,
                               cur_stage_rec.note2_title,
                               cur_stage_rec.note3_title,
                               cur_stage_rec.note4_title,
                               cur_stage_rec.note5_title,
                               cur_stage_rec.note6_title,
                               cur_stage_rec.note7_title,
                               cur_stage_rec.note8_title,
                               cur_stage_rec.note9_title,
                               cur_stage_rec.note10_title,
                               cur_stage_rec.gl_date,
                               cur_stage_rec.dist_attribute_category,
                               cur_stage_rec.distribution_attribute1,
                               cur_stage_rec.distribution_attribute2,
                               cur_stage_rec.distribution_attribute3,
                               cur_stage_rec.distribution_attribute4,
                               cur_stage_rec.distribution_attribute5,
                               cur_stage_rec.distribution_attribute6,
                               cur_stage_rec.distribution_attribute7,
                               cur_stage_rec.distribution_attribute8,
                               cur_stage_rec.distribution_attribute9,
                               cur_stage_rec.distribution_attribute10,
                               cur_stage_rec.distribution_attribute11,
                               cur_stage_rec.distribution_attribute12,
                               cur_stage_rec.distribution_attribute13,
                               cur_stage_rec.distribution_attribute14,
                               cur_stage_rec.distribution_attribute15,
                               lc_preparer,
                               cur_stage_rec.bom_resource_id,
                               cur_stage_rec.accrual_account_id,
                               cur_stage_rec.variance_account_id,
                               cur_stage_rec.budget_account_id,
                               cur_stage_rec.ussgl_transaction_code,
                               cur_stage_rec.government_context,
                               lc_currency_code,
                               cur_stage_rec.currency_unit_price,
                               cur_stage_rec.rate,
                               cur_stage_rec.rate_date,
                               cur_stage_rec.rate_type,
                               cur_stage_rec.prevent_encumbrance_flag,
                               cur_stage_rec.autosource_doc_header_id,
                               cur_stage_rec.autosource_doc_line_num,
                               cur_stage_rec.project_accounting_context,
                               cur_stage_rec.expenditure_organization_id,
                               cur_stage_rec.project_id,
                               cur_stage_rec.task_id,
                               cur_stage_rec.end_item_unit_number,
                               cur_stage_rec.expenditure_item_date,
                               cur_stage_rec.document_type_code,
                               ln_org_id,
                               cur_stage_rec.transaction_reason_code,
                               cur_stage_rec.allocation_type,
                               cur_stage_rec.allocation_value,
                               cur_stage_rec.multi_distributions,
                               cur_stage_rec.req_dist_sequence_id,
                               cur_stage_rec.kanban_card_id,
                               cur_stage_rec.emergency_po_num,
                               cur_stage_rec.award_id,
                               cur_stage_rec.tax_code_id,
                               cur_stage_rec.oke_contract_header_id,
                               cur_stage_rec.oke_contract_num,
                               cur_stage_rec.oke_contract_version_id,
                               cur_stage_rec.oke_contract_line_id,
                               cur_stage_rec.oke_contract_line_num,
                               cur_stage_rec.oke_contract_deliverable_id,
                               cur_stage_rec.oke_contract_deliverable_num,
                               cur_stage_rec.secondary_unit_of_measure,
                               cur_stage_rec.secondary_uom_code,
                               cur_stage_rec.secondary_quantity,
                               cur_stage_rec.preferred_grade,
                               cur_stage_rec.vmi_flag,
                               cur_stage_rec.tax_user_override_flag,
                               cur_stage_rec.amount,
                               cur_stage_rec.currency_amount,
                               cur_stage_rec.ship_method,
                               cur_stage_rec.estimated_pickup_date,
                               cur_stage_rec.base_unit_price,
                               cur_stage_rec.negotiated_by_preparer_flag
                              );
               ---FND_FILE.PUT_LINE(FND_FILE.LOG, 'AFTEREntered1');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     fnd_file.put_line (fnd_file.LOG,
                                        'AFTEREntered1exception'
                                       );
                     lc_insert_error_flag := 'Y';
                     ln_error_no := ln_error_no + 1;
                     --Insert Into Error Table
                     lt_error_tbl (ln_error_no).staging_id :=
                                                      cur_stage_rec.staging_id;
                     lt_error_tbl (ln_error_no).table_name :=
                                                      'BILC_PO_PR_STAGING_TBL';
                     lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                     lt_error_tbl (ln_error_no).error_msg :=
                           'Error Occured while inserting in to PO_REQUISITIONS_INTERFACE_ALL Table'
                        || SQLCODE
                        || ''
                        || SUBSTR (SQLERRM, 1, 250);
                     fnd_file.put_line
                        (fnd_file.LOG,
                            'Error Occured while inserting in to PO_REQUISITIONS_INTERFACE_ALL Table'
                         || SQLCODE
                         || ''
                         || SUBSTR (SQLERRM, 1, 250)
                        );
                     fnd_file.put_line
                        (fnd_file.output,
                            'Error Occured while inserting in to PO_REQUISITIONS_INTERFACE_ALL Table'
                         || SQLCODE
                         || ''
                         || SUBSTR (SQLERRM, 1, 250)
                        );
               END;

               --FND_FILE.PUT_LINE(FND_FILE.LOG,
               --'lc_insert_error_flag' || lc_insert_error_flag);
               IF lc_insert_error_flag <> 'Y'
               THEN
                  BEGIN
                     --FND_FILE.PUT_LINE(FND_FILE.LOG, 'Entered in distributuions');
                     INSERT INTO po_req_dist_interface_all
                                 (accrual_account_id,
                                  allocation_type,
                                  allocation_value,
                                  batch_id,
                                  budget_account_id,
                                  charge_account_id,
                                  charge_account_segment1,
                                  charge_account_segment10,
                                  charge_account_segment11,
                                  charge_account_segment12,
                                  charge_account_segment13,
                                  charge_account_segment14,
                                  charge_account_segment15,
                                  charge_account_segment16,
                                  charge_account_segment17,
                                  charge_account_segment18,
                                  charge_account_segment19,
                                  charge_account_segment2,
                                  charge_account_segment20,
                                  charge_account_segment21,
                                  charge_account_segment22,
                                  charge_account_segment23,
                                  charge_account_segment24,
                                  charge_account_segment25,
                                  charge_account_segment26,
                                  charge_account_segment27,
                                  charge_account_segment28,
                                  charge_account_segment29,
                                  charge_account_segment3,
                                  charge_account_segment30,
                                  charge_account_segment4,
                                  charge_account_segment5,
                                  charge_account_segment6,
                                  charge_account_segment7,
                                  charge_account_segment8,
                                  charge_account_segment9,
                                  created_by,
                                  creation_date,
                                  destination_organization_id,
                                  destination_subinventory,
                                  destination_type_code,
                                  distribution_attribute1,
                                  distribution_attribute10,
                                  distribution_attribute11,
                                  distribution_attribute12,
                                  distribution_attribute13,
                                  distribution_attribute14,
                                  distribution_attribute15,
                                  distribution_attribute2,
                                  distribution_attribute3,
                                  distribution_attribute4,
                                  distribution_attribute5,
                                  distribution_attribute6,
                                  distribution_attribute7,
                                  distribution_attribute8,
                                  distribution_attribute9,
                                  --distribution_number            ,
                                  dist_attribute_category,
                                  --dist_sequence_id               ,
                                  expenditure_item_date,
                                  expenditure_organization_id,
                                  expenditure_type,
                                  gl_date,
                                  government_context,
                                  group_code,
                                  interface_source_code,
                                  interface_source_line_id,
                                  item_id,
                                  last_updated_by,
                                  last_update_date,
                                  last_update_login,
                                  org_id,
                                  prevent_encumbrance_flag,
                                  process_flag,
                                  program_application_id,
                                  program_id,
                                  program_update_date,
                                  project_accounting_context,
                                  project_id,
                                  project_num,
                                  quantity,
                                  request_id,
                                  requisition_header_id,
                                  req_number_segment1,
                                  requisition_line_id,
                                  req_distribution_id,
                                  task_id,
                                  task_num,
                                  transaction_id,
                                  update_enabled_flag,
                                  ussgl_transaction_code,
                                  variance_account_id,
                                  oke_contract_line_id,
                                  oke_contract_line_num,
                                  oke_contract_deliverable_id,
                                  oke_contract_deliverable_num,
                                  amount,
                                  currency_amount
                                 )
                          VALUES (cur_stage_rec.accrual_account_id,
                                  cur_stage_rec.allocation_type,
                                  cur_stage_rec.allocation_value,
                                  cur_stage_rec.batch_id,
                                  cur_stage_rec.budget_account_id,
                                  ln_charge_account_id,
                                  cur_stage_rec.charge_account_segment1,
                                  cur_stage_rec.charge_account_segment10,
                                  cur_stage_rec.charge_account_segment11,
                                  cur_stage_rec.charge_account_segment12,
                                  cur_stage_rec.charge_account_segment13,
                                  cur_stage_rec.charge_account_segment14,
                                  cur_stage_rec.charge_account_segment15,
                                  cur_stage_rec.charge_account_segment16,
                                  cur_stage_rec.charge_account_segment17,
                                  cur_stage_rec.charge_account_segment18,
                                  cur_stage_rec.charge_account_segment19,
                                  cur_stage_rec.charge_account_segment2,
                                  cur_stage_rec.charge_account_segment20,
                                  cur_stage_rec.charge_account_segment21,
                                  cur_stage_rec.charge_account_segment22,
                                  cur_stage_rec.charge_account_segment23,
                                  cur_stage_rec.charge_account_segment24,
                                  cur_stage_rec.charge_account_segment25,
                                  cur_stage_rec.charge_account_segment26,
                                  cur_stage_rec.charge_account_segment27,
                                  cur_stage_rec.charge_account_segment28,
                                  cur_stage_rec.charge_account_segment29,
                                  cur_stage_rec.charge_account_segment3,
                                  cur_stage_rec.charge_account_segment30,
                                  cur_stage_rec.charge_account_segment4,
                                  cur_stage_rec.charge_account_segment5,
                                  cur_stage_rec.charge_account_segment6,
                                  cur_stage_rec.charge_account_segment7,
                                  cur_stage_rec.charge_account_segment8,
                                  cur_stage_rec.charge_account_segment9,
                                  g_user_id,
                                  SYSDATE,
                                  ln_organization_id,
                                  cur_stage_rec.destination_subinventory,
                                  cur_stage_rec.destination_type_code,
                                  cur_stage_rec.distribution_attribute1,
                                  cur_stage_rec.distribution_attribute10,
                                  cur_stage_rec.distribution_attribute11,
                                  cur_stage_rec.distribution_attribute12,
                                  cur_stage_rec.distribution_attribute13,
                                  cur_stage_rec.distribution_attribute14,
                                  cur_stage_rec.distribution_attribute15,
                                  cur_stage_rec.distribution_attribute2,
                                  cur_stage_rec.distribution_attribute3,
                                  cur_stage_rec.distribution_attribute4,
                                  cur_stage_rec.distribution_attribute5,
                                  cur_stage_rec.distribution_attribute6,
                                  cur_stage_rec.distribution_attribute7,
                                  cur_stage_rec.distribution_attribute8,
                                  cur_stage_rec.distribution_attribute9,
                                  cur_stage_rec.dist_attribute_category,
                                  cur_stage_rec.expenditure_item_date,
                                  cur_stage_rec.expenditure_organization_id,
                                  cur_stage_rec.expenditure_type,
                                  cur_stage_rec.gl_date,
                                  cur_stage_rec.government_context,
                                  cur_stage_rec.group_code,
                                  cur_stage_rec.interface_source_code,
                                  cur_stage_rec.interface_source_line_id,
                                  ln_item_id,
                                  g_user_id,
                                  SYSDATE,
                                  g_user_id,
                                  ln_org_id,
                                  cur_stage_rec.prevent_encumbrance_flag,
                                  cur_stage_rec.process_flag,
                                  g_application_id,
                                  g_program_id,
                                  SYSDATE,
                                  cur_stage_rec.project_accounting_context,
                                  cur_stage_rec.project_id,
                                  cur_stage_rec.project_num,
                                  cur_stage_rec.quantity,
                                  g_request_id,
                                  NULL,     --requisition_header_id          ,
                                  NULL,     --req_number_segment1            ,
                                  NULL,     --requisition_line_id            ,
                                  NULL,     --req_distribution_id            ,
                                  cur_stage_rec.task_id,
                                  cur_stage_rec.task_num,
                                  cur_stage_rec.transaction_id,
                                  cur_stage_rec.update_enabled_flag,
                                  cur_stage_rec.ussgl_transaction_code,
                                  cur_stage_rec.variance_account_id,
                                  cur_stage_rec.oke_contract_line_id,
                                  cur_stage_rec.oke_contract_line_num,
                                  cur_stage_rec.oke_contract_deliverable_id,
                                  cur_stage_rec.oke_contract_deliverable_num,
                                  cur_stage_rec.amount,
                                  cur_stage_rec.currency_amount
                                 );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        lc_insert_error_flag := 'Y';
                        ln_error_no := ln_error_no + 1;
                        --Insert Into Error Table
                        lt_error_tbl (ln_error_no).staging_id :=
                                                     cur_stage_rec.staging_id;
                        lt_error_tbl (ln_error_no).table_name :=
                                                     'BILC_PO_PR_STAGING_TBL';
                        lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
                        lt_error_tbl (ln_error_no).error_msg :=
                              'Error Occured while inserting in to po_req_dist_interface_all Table'
                           || SQLCODE
                           || ''
                           || SUBSTR (SQLERRM, 1, 250);
                        fnd_file.put_line
                           (fnd_file.LOG,
                               'Error Occured while inserting in to po_req_dist_interface_all Table'
                            || SQLCODE
                            || ''
                            || SUBSTR (SQLERRM, 1, 250)
                           );
                        fnd_file.put_line
                           (fnd_file.output,
                               'Error Occured while inserting in to po_req_dist_interface_all Table'
                            || SQLCODE
                            || ''
                            || SUBSTR (SQLERRM, 1, 250)
                           );
                  END;
               END IF;

               IF lc_insert_error_flag <> 'Y'
               THEN
                  --UPDATING THE STAGING TABLE
                  UPDATE bilc_po_pr_staging_tbl
                     SET status = 'UPLOADED',
                         last_updated_by = fnd_global.user_id,
                         last_update_date = SYSDATE
                   WHERE ROWID = cur_stage_rec.row_id;

                  COMMIT;
               -- FND_FILE.PUT_LINE(FND_FILE.LOG, 'SUCCESS');
               ELSIF lc_insert_error_flag = 'Y'
               THEN
                  UPDATE bilc_po_pr_staging_tbl
                     SET status = 'INSERTERR',
                         last_updated_by = fnd_global.user_id,
                         last_update_date = SYSDATE
                   WHERE ROWID = cur_stage_rec.row_id;
               --FND_FILE.PUT_LINE(FND_FILE.LOG, 'INSERTERR');
               END IF;
            ELSIF lc_error_flag = 'Y'
            THEN
               UPDATE bilc_po_pr_staging_tbl
                  SET status = 'ERROR',
                      last_updated_by = fnd_global.user_id,
                      last_update_date = SYSDATE
                WHERE ROWID = cur_stage_rec.row_id;

               COMMIT;
            END IF;
         END;

         IF ln_error_no <> 0
         THEN
            ROLLBACK;
            apps.bilc_integration_error_pkg.bilc_error_insert (lt_error_tbl);
         END IF;
      END LOOP;                                   -- End of Base Header Cursor

      COMMIT;
   ---FND_FILE.PUT_LINE(FND_FILE.LOG, 'AFTER LOOP');
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         lt_error_tbl (ln_error_no).table_name := 'BILC_PO_PR_STAGING_TBL';
         lt_error_tbl (ln_error_no).ERROR_CODE := NULL;
         lt_error_tbl (ln_error_no).error_msg :=
               'Exception Raised In BILC_IMPORT_TO_INTERFACE'
            || SQLCODE
            || ''
            || SUBSTR (SQLERRM, 1, 250);
         fnd_file.put_line (fnd_file.LOG,
                               'Exception Raised In BILC_IMPORT_TO_INTERFACE'
                            || SQLCODE
                            || ''
                            || SUBSTR (SQLERRM, 1, 250)
                           );
         fnd_file.put_line (fnd_file.output,
                               'Exception Raised In BILC_IMPORT_TO_INTERFACE'
                            || SQLCODE
                            || ''
                            || SUBSTR (SQLERRM, 1, 250)
                           );
   END bilc_import_to_interface;
END bilc_poreq_import;                                  -- End of Package Body
/

