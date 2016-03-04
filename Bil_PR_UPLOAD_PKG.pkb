/* Formatted on 2009/06/12 18:09 (Formatter Plus v4.8.7) */
CREATE OR REPLACE PACKAGE BODY bil_pr_upload_pkg
AS
   g_pkg_name   CONSTANT VARCHAR2 (30) := 'Bil_PR_UPLOAD_PKG';

   PROCEDURE dummy_proc (
      ERROR_CODE       OUT   VARCHAR2,
      error_message    OUT   VARCHAR2,
      error_severity   OUT   NUMBER,
      error_status     OUT   NUMBER
   )
   IS
   BEGIN
      error_status := 0;
      error_severity := 1;
      ERROR_CODE := NULL;
      error_message := NULL;
   END dummy_proc;

   PROCEDURE bil_print_msg (p_msg IN VARCHAR2)
   IS
   BEGIN
      DBMS_OUTPUT.put_line (p_msg);
   END bil_print_msg;

   PROCEDURE bil_pr_intrfce_upload (p_pr_rec IN pr_tbl_type)
   IS
      bil_pr_tbl          pr_tbl_type     := p_pr_rec;
      lv_preparer_flag    VARCHAR2 (10)   := NULL;
      lv_requester_flag   VARCHAR2 (10)   := NULL;
      lv_ou_flag          VARCHAR2 (10)   := NULL;
      lv_item_flag        VARCHAR2 (10)   := NULL;
      lv_uom_flag         VARCHAR2 (10)   := NULL;
      print_msg           VARCHAR2 (5000) := NULL;
      lv_header_flag      VARCHAR2 (5000) := NULL;
      lv_line_flag        VARCHAR2 (5000) := NULL;
      error_flag          VARCHAR2 (10)   := 'N';
   /* Flag for determining wether that particular record should be inserted */
   BEGIN
      bil_print_msg ('Start of the Program ' || g_pkg_name);

      FOR i IN 1 .. bil_pr_tbl.COUNT
      LOOP
        

         IF     bil_pr_tbl (i).preparer_id IS NULL
            AND bil_pr_tbl (i).preparer IS NOT NULL
         THEN
            

            BEGIN
               SELECT 'Y',person_id
                 INTO lv_preparer_flag,bil_pr_tbl (i).preparer_id
                 FROM per_people_f
                WHERE full_name = bil_pr_tbl (i).preparer
                  AND SYSDATE BETWEEN effective_start_date AND effective_end_date;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
			   bil_print_msg('Preparer Not Valid');
                   lv_preparer_flag := 'N';
				   error_flag := 'E';
            END;

            IF lv_preparer_flag != 'Y'
            THEN
               error_flag := 'E';
               print_msg :=
                     'The PR NUM:'
                  || bil_pr_tbl (i).pr_num
                  || 'has an invalid preparer';
               bil_print_msg (print_msg);
            END IF;
         END IF;

         IF     bil_pr_tbl (i).preparer_id IS NOT NULL
            AND bil_pr_tbl (i).preparer IS NULL
         THEN
            

            BEGIN
               SELECT 'Y'
                 INTO lv_preparer_flag
                 FROM per_people_f
                WHERE person_id = bil_pr_tbl (i).preparer_id
                  AND SYSDATE BETWEEN effective_start_date AND effective_end_date;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
			       
				   bil_print_msg('Preparer Not Valid');
				   error_flag := 'E';
                  lv_preparer_flag := 'N';
            END;

            IF lv_preparer_flag != 'Y'
            THEN
               error_flag := 'E';
               print_msg :=
                     'The PR NUM:'
                  || bil_pr_tbl (i).pr_num
                  || 'has an invalid preparer';
               bil_print_msg (print_msg);
               END IF;
         END IF;

         IF     bil_pr_tbl (i).preparer_id IS NULL
            AND bil_pr_tbl (i).preparer IS NULL
         THEN
            error_flag := 'E';
            print_msg :=
                  'The PR NUM:'
               || bil_pr_tbl (i).pr_num
               || 'has an invalid preparer';
            bil_print_msg (print_msg);
         END IF;

         IF     bil_pr_tbl (i).preparer_id IS NOT NULL
            AND bil_pr_tbl (i).preparer IS NOT NULL
         THEN
           
            BEGIN
               SELECT 'Y'
                 INTO lv_preparer_flag
                 FROM per_people_f
                WHERE person_id = bil_pr_tbl (i).preparer_id
                  AND full_name = bil_pr_tbl (i).preparer
                  AND SYSDATE BETWEEN effective_start_date AND effective_end_date;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
			   bil_print_msg('===================================================================');
			   bil_print_msg('Invalid Preparer');
                  lv_preparer_flag := 'N';
            END;

            IF lv_preparer_flag != 'Y'
            THEN
               error_flag := 'E';
               print_msg :=
                     'The PR NUM:'
                  || bil_pr_tbl (i).pr_num
                  || 'has an invalid preparer';
               bil_print_msg (print_msg);
               
            END IF;
         END IF;

         IF     bil_pr_tbl (i).requester_id IS NULL
            AND bil_pr_tbl (i).requester IS NOT NULL
         THEN
           

            BEGIN
               SELECT 'Y',person_id
                 INTO lv_requester_flag,bil_pr_tbl (i).requester_id
                 FROM per_people_f
                WHERE full_name = bil_pr_tbl (i).requester
                  AND SYSDATE BETWEEN effective_start_date AND effective_end_date;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
			   bil_print_msg('Invalid Requester');
                  lv_requester_flag := 'N';
            END;

            IF lv_requester_flag != 'Y'
            THEN
              
               error_flag := 'E';
               print_msg :=
                     'The PR NUM:'
                  || bil_pr_tbl (i).pr_num
                  || 'has an invalid requester';
               bil_print_msg (print_msg);
            END IF;
         END IF;

         IF     bil_pr_tbl (i).requester_id IS NOT NULL
            AND bil_pr_tbl (i).requester IS NULL
         THEN
            

            BEGIN
               SELECT 'Y'
                 INTO lv_requester_flag
                 FROM per_people_f
                WHERE person_id = bil_pr_tbl (i).requester_id
                  AND SYSDATE BETWEEN effective_start_date AND effective_end_date;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
			    bil_print_msg('Invalid Requester');
                  lv_requester_flag := 'N';
            END;

            IF lv_requester_flag != 'Y'
            THEN
               
               error_flag := 'E';
               print_msg :=
                     'The PR NUM:'
                  || bil_pr_tbl (i).pr_num
                  || 'has an invalid requester';
               bil_print_msg (print_msg);
            END IF;
         END IF;

         IF     bil_pr_tbl (i).requester_id IS NOT NULL
            AND bil_pr_tbl (i).requester IS NOT NULL
         THEN
           

            BEGIN
               SELECT 'Y'
                 INTO lv_requester_flag
                 FROM per_people_f
                WHERE person_id = bil_pr_tbl (i).requester_id
                  AND full_name = bil_pr_tbl (i).requester
                  AND SYSDATE BETWEEN effective_start_date AND effective_end_date;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
			    bil_print_msg('Invalid Requester');
                  lv_requester_flag := 'N';
            END;

            IF lv_requester_flag != 'Y'
            THEN
              
               error_flag := 'E';
               print_msg :=
                     'The PR NUM:'
                  || bil_pr_tbl (i).pr_num
                  || 'has an invalid requester';
               bil_print_msg (print_msg);
            END IF;
         END IF;

         IF     bil_pr_tbl (i).requester_id IS NULL
            AND bil_pr_tbl (i).requester IS NULL
         THEN
            
            error_flag := 'E';
            print_msg :=
                  'The PR NUM:'
               || bil_pr_tbl (i).pr_num
               || 'has an invalid requester';
            bil_print_msg (print_msg);
         END IF;

/* Validating OU ID and Name Combination */
         IF     bil_pr_tbl (i).operating_unit IS NULL
            AND bil_pr_tbl (i).operating_unit_name IS NULL
         THEN
            
            error_flag := 'E';
            print_msg :=
                  print_msg
               || 'The PR NUM:'
               || bil_pr_tbl (i).pr_num
               || 'has no operating Unit data';
         END IF;

         IF     bil_pr_tbl (i).operating_unit IS NOT NULL
            AND bil_pr_tbl (i).operating_unit_name IS NULL
         THEN
            

            BEGIN
               SELECT 'Y'
                 INTO lv_ou_flag
                 FROM hr_operating_units
                WHERE organization_id = bil_pr_tbl (i).operating_unit;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  bil_print_msg('Invalid Organization');
				  lv_ou_flag := 'N';
            END;

            IF lv_ou_flag != 'Y'
            THEN
              
               error_flag := 'E';
               print_msg :=
                     print_msg
                  || 'The PR NUM:'
                  || bil_pr_tbl (i).pr_num
                  || 'has an invalid Operating Unit';
               bil_print_msg (print_msg);
            END IF;
         END IF;

         IF     bil_pr_tbl (i).operating_unit IS NULL
            AND bil_pr_tbl (i).operating_unit_name IS NOT NULL
         THEN
            bil_print_msg ('Entered If Cond 13');

            BEGIN
               SELECT 'Y',organization_id
                 INTO lv_ou_flag,bil_pr_tbl (i).operating_unit
                 FROM hr_operating_units
                WHERE NAME = bil_pr_tbl (i).operating_unit_name;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  lv_ou_flag := 'N';
            END;

            IF lv_ou_flag != 'Y'
            THEN
               bil_print_msg ('Entered If Cond 14');
               error_flag := 'E';
               print_msg :=
                     print_msg
                  || 'The PR NUM:'
                  || bil_pr_tbl (i).pr_num
                  || 'has an invalid Operating Unit';
               bil_print_msg (print_msg);
			    bil_print_msg('Invalid Organization');
            END IF;
         END IF;

         IF     bil_pr_tbl (i).operating_unit IS NOT NULL
            AND bil_pr_tbl (i).operating_unit_name IS NOT NULL
         THEN
            

            BEGIN
               SELECT 'Y'
                 INTO lv_ou_flag
                 FROM hr_operating_units
                WHERE NAME = bil_pr_tbl (i).operating_unit_name
                  AND organization_id = bil_pr_tbl (i).operating_unit;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
			    bil_print_msg('Invalid OU');
                  lv_ou_flag := 'N';
            END;

            IF lv_ou_flag != 'Y'
            THEN
               
               error_flag := 'E';
               print_msg :=
                     print_msg
                  || 'The PR NUM:'
                  || bil_pr_tbl (i).pr_num
                  || 'has an invalid Operating Unit';
               bil_print_msg (print_msg);
            END IF;
         END IF;

         IF bil_pr_tbl (i).item IS NULL AND bil_pr_tbl (i).item_name IS NULL
         THEN
           
            error_flag := 'E';
            print_msg :=
                  print_msg
               || 'The PR NUM:'
               || bil_pr_tbl (i).pr_num
               || 'has an No Item ';
            bil_print_msg (print_msg);
         END IF;

         IF     bil_pr_tbl (i).item IS NOT NULL
            AND bil_pr_tbl (i).item_name IS NULL
         THEN
           

            BEGIN
               SELECT 'Y'
                 INTO lv_item_flag
                 FROM mtl_system_items_b
                WHERE inventory_item_id = bil_pr_tbl (i).item
                  AND organization_id = bil_pr_tbl (i).organization_id;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  lv_item_flag := 'N';
            END;

            IF lv_item_flag != 'Y'
            THEN
              
               error_flag := 'E';
               print_msg :=
                     print_msg
                  || 'The PR NUM:'
                  || bil_pr_tbl (i).pr_num
                  || 'has an invalid Item Number';
               bil_print_msg (print_msg);
            END IF;
         END IF;

         IF     bil_pr_tbl (i).item IS NULL
            AND bil_pr_tbl (i).item_name IS NOT NULL
         THEN
            BEGIN
               SELECT 'Y',inventory_item_id
                 INTO lv_item_flag,bil_pr_tbl (i).item
                 FROM mtl_system_items_b
                WHERE description = bil_pr_tbl (i).item_name
                  AND organization_id = bil_pr_tbl (i).organization_id;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  lv_item_flag := 'N';
            END;

            IF lv_item_flag != 'Y'
            THEN
               error_flag := 'E';
               print_msg :=
                     print_msg
                  || 'The PR NUM:'
                  || bil_pr_tbl (i).pr_num
                  || 'has an invalid Item Name';
               bil_print_msg (print_msg);
            END IF;
         END IF;

         IF     bil_pr_tbl (i).item IS NOT NULL
            AND bil_pr_tbl (i).item_name IS NOT NULL
         THEN
            BEGIN
               SELECT 'Y'
                 INTO lv_item_flag
                 FROM mtl_system_items_b
                WHERE description = bil_pr_tbl (i).item_name
                  AND inventory_item_id = bil_pr_tbl (i).item
                  AND organization_id = bil_pr_tbl (i).organization_id;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
			    bil_print_msg('Invalid UOM');
                  lv_item_flag := 'N';
            END;

            IF lv_item_flag != 'Y'
            THEN
               error_flag := 'E';
               print_msg :=
                     print_msg
                  || 'The PR NUM:'
                  || bil_pr_tbl (i).pr_num
                  || 'has an invalid Item Number';
               bil_print_msg (print_msg);
            END IF;
         END IF;

         BEGIN
            SELECT 'Y'
              INTO lv_uom_flag
              FROM DUAL
             WHERE EXISTS (
                      SELECT 1
                        FROM mtl_system_items_b
                       WHERE inventory_item_id = bil_pr_tbl (i).item
                         AND organization_id = bil_pr_tbl (i).organization_id
                         AND primary_unit_of_measure = bil_pr_tbl (i).uom);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
			 bil_print_msg('Invalid UOM');
               lv_uom_flag := 'N';
         END;

         IF lv_uom_flag != 'Y' OR lv_uom_flag IS NULL
         THEN
            error_flag := 'E';
            print_msg :=
                  print_msg
               || 'The PR NUM:'
               || bil_pr_tbl (i).pr_num
               || 'has an invalid UOM';
            bil_print_msg (print_msg);
         END IF;

         IF error_flag = 'N'
         THEN
            print_msg :=
               'Passed Validation now inserting into po_requisitions_interface_all and po_req_dist_interface_all';
            bil_print_msg (print_msg);

            INSERT INTO po_requisitions_interface_all
                        (req_number_segment1, header_description,
                         requisition_type,
                         header_attribute9,
                         header_attribute10,
                         interface_source_code, source_type_code,
                         destination_type_code, authorization_status,
                         preparer_id, item_id,
                         category_id,
                         quantity, unit_of_measure,
                         destination_organization_id,
                         deliver_to_location_id,
                         deliver_to_requestor_id,
                         need_by_date,
                         org_id,
                         charge_account_id,
                         creation_date,
                         line_attribute1, line_attribute2,
                         line_attribute3,
                         line_attribute4,
                         suggested_vendor_id,
                         suggested_vendor_site_id,
                         suggested_vendor_contact, currency_code
                        )
                 VALUES (bil_pr_tbl (i).pr_num, bil_pr_tbl (i).pr_desc,
                         bil_pr_tbl (i).req_type,
                         bil_pr_tbl (i).maximo_work_order,
                         bil_pr_tbl (i).maximo_pr_number,
                         bil_pr_tbl (i).SOURCE, g_source_type_code,
                         g_destination_type_code, g_authorization_status,
                         bil_pr_tbl (i).preparer_id, bil_pr_tbl (i).item,
                         bil_pr_tbl (i).item_category,
                         bil_pr_tbl (i).quantity, bil_pr_tbl (i).uom,
                         bil_pr_tbl (i).destination,
                         bil_pr_tbl (i).location_id,
                         bil_pr_tbl (i).requester_id,
                         bil_pr_tbl (i).need_by_date,
                         bil_pr_tbl (i).operating_unit,
                         bil_pr_tbl (i).charge_account_d,
                         bil_pr_tbl (i).creation_date,
                         bil_pr_tbl (i).line_num, bil_pr_tbl (i).line_type,
                         bil_pr_tbl (i).pr_line_desc,
                         bil_pr_tbl (i).item_category,
                         bil_pr_tbl (i).vendor_id,
                         bil_pr_tbl (i).vendor_site_id,
                         bil_pr_tbl (i).suggested_vendor_contact,  bil_pr_tbl (i).currency
                        );

            INSERT INTO po_req_dist_interface_all
                        (charge_account_id,
                         accrual_account_id,
                         --DISTRIBUTION_NUMBER,
                         --DESTINATION_TYPE_CODE,
                         interface_source_code,
                         variance_account_id
                        )
                 VALUES (bil_pr_tbl (i).charge_account_d,
                         bil_pr_tbl (i).accrual_account_d,
                         g_interface_source_code,
                         bil_pr_tbl (i).variance_account
                        );

            bil_print_msg ('Finished Entering Data ' || g_pkg_name);
            COMMIT;
         ELSE
            bil_print_msg (print_msg);
         END IF;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         bil_print_msg ('Errored due to' || SQLERRM);
   END bil_pr_intrfce_upload;
END bil_pr_upload_pkg;