/* Formatted on 2008/11/24 17:47 (Formatter Plus v4.8.6) */
CREATE OR REPLACE PACKAGE BODY xxlcb_transfer_alloc
IS
/* ===============================================================================================
||   Filename:    xxlcb_transfer_alloc_tsforder.pkh
||   Description: Package Body
||
||  Change History:
||  =====================================================================
||  Version Date          Author         Modification
||  ------- -----------   ------------   ----------------
||  1.0     23-Nov-2008   Avinash Initial Version
||  =====================================================================
||
||   Usage : This Package is used to Transfer the Allocation details to Transfer Orders
||
||   Copyright PLCB
||   3rd and Forester Street, Harrisburg, PA  17101
||   All rights reserved.
|| ===============================================================================================*/
   PROCEDURE main
   IS
      -- step 1 from MD50
      CURSOR c_alloc_cur
      IS
         SELECT h.wh, d.to_loc, d.to_loc_type, h.item scc_code, h.alloc_no,
                d.qty_allocated, p.item AS plcb_code
           FROM alloc_header h, alloc_detail d, packitem p, ordloc ol
          WHERE h.alloc_no = d.alloc_no
            AND h.status IN ('A', 'R')
            AND h.item = p.pack_no
            AND h.item = ol.item
            AND h.wh = ol.LOCATION
            AND h.order_no = ol.order_no
            AND ol.qty_received > 0;

      -- step 2 obtaining all transfer numbers for warehouse and location combination where status='B' and tsf_type='SR'
      CURSOR cur_tsfhead (p_wh NUMBER, p_to_loc NUMBER)
      IS
         SELECT tsf_no, tsf_type
           FROM tsfhead
          WHERE from_loc = p_wh
            AND to_loc = p_to_loc
            AND status = 'B'
            AND tsf_type = 'SR';

      -- step 3 there should only be 1 transfer create for each WH/Loc combinations
      CURSOR cur_tsfcreate (p_wh NUMBER, p_to_loc NUMBER)
      IS
         SELECT DISTINCT h.wh, d.to_loc, d.to_loc_type
                    FROM alloc_header h, alloc_detail d, packitem p,
                         ordloc ol
                   WHERE h.alloc_no = d.alloc_no
                     AND h.status IN ('A', 'R')
                     AND h.item = p.pack_no
                     AND h.item = ol.item
                     AND h.wh = ol.LOCATION
                     AND h.order_no = ol.order_no
                     AND ol.qty_received > 0
                     AND h.wh = p_wh
                     AND d.to_loc = p_to_loc;

      lv_wh_toloc         NUMBER;
      lv_src_dsd          NUMBER;
      lv_item_chk         NUMBER;
      lv_tsf_hdr          NUMBER;
      lv_tsf_dtl          NUMBER;
      lv_tsf_no           NUMBER;
      lv_tsf_seq_no       NUMBER;
      --l_return_code varchar2(60);
      lv_err_msg          VARCHAR2 (4000);
      lv_error_message    VARCHAR2 (10000);
      lv_return_code      NUMBER;
      lv_tsf_num          NUMBER;
      lv_supp_pack_size   NUMBER;
      --lv_return_code   varchar2(60);
      lv_tsf_type         VARCHAR2 (30);
      lv_alloc_chk        NUMBER;
      lv_user             VARCHAR2 (15);
      lv_vdate            DATE;
      lv_logi_wh          NUMBER;
      lv_tsf_exist        NUMBER           := 0;
      lv_count_tsf        NUMBER           := 0;
      lv_comb_exist       NUMBER           := 0;
   BEGIN
      --database user
      SELECT USER
        INTO lv_user
        FROM DUAL;

      -- current period date
      SELECT vdate
        INTO lv_vdate
        FROM period;

      -- step 1 from program logic in MD50
      FOR c1 IN c_alloc_cur
      LOOP
         DBMS_OUTPUT.put_line ('wh' || c1.wh);
         DBMS_OUTPUT.put_line ('to_loc' || c1.to_loc);
         DBMS_OUTPUT.put_line ('alloc no ' || c1.alloc_no);

         --- checking the warehouse/location combination exist or not
         SELECT COUNT (tsf_no)
           INTO lv_comb_exist
           FROM tsfhead
          WHERE from_loc = c1.wh
            AND to_loc = c1.to_loc
            AND status = 'B'
            AND tsf_type = 'SR';

         DBMS_OUTPUT.put_line ('lv_comb_exist ' || lv_comb_exist);

 -------------------------------------------------------------------------------------------------------------------------
-- if WH/LOC combination does not exists does not exist then
--proceeding for step 3
         IF lv_comb_exist = 0
         THEN
               --Check If delivery date tomorrow. If records exists Create tsfheader records
            -- converting physical warehouse to logical warehouse
            IF c1.wh = 9001
            THEN
               lv_logi_wh := 1;
            ELSIF c1.wh = 9002
            THEN
               lv_logi_wh := 2;
            ELSIF c1.wh = 9004
            THEN
               lv_logi_wh := 3;
            ELSIF c1.wh = 9004
            THEN
               lv_logi_wh := 4;
            END IF;

            SELECT COUNT (1)
              INTO lv_src_dsd
              FROM source_dlvry_sched_days
             WHERE SOURCE = lv_logi_wh
               AND LOCATION = c1.to_loc
               AND DAY = TO_CHAR (lv_vdate + 1, 'D');

            DBMS_OUTPUT.put_line ('lv_src_dsd ' || lv_src_dsd);

            IF lv_src_dsd = 0
            THEN
               DBMS_OUTPUT.put_line ('If Delivery Schedule is tomorrow....');

               --Call the API and  Create Header Transfer

               -- step 3 there should only be 1 transfer create for each WH/Loc combinations
               FOR cur_create IN cur_tsfcreate (c1.wh, c1.to_loc)
               LOOP
                  -- generating sequence number
                  SELECT transfer_number_sequence.NEXTVAL
                    INTO lv_tsf_no
                    FROM DUAL;

                  DBMS_OUTPUT.put_line ('tsf no ' || lv_tsf_no);

                  BEGIN
                     INSERT INTO tsfhead
                                 (tsf_no, from_loc_type, from_loc,
                                  to_loc_type, to_loc,
                                  dept, tsf_type, status, freight_code,
                                  routing_code, create_date, create_id,
                                  approval_date, approval_id, delivery_date,
                                  repl_tsf_approve_ind, inventory_type,
                                  comment_desc
                                 )
                          VALUES (lv_tsf_no, 'W', cur_create.wh,
                                  cur_create.to_loc_type, cur_create.to_loc,
                                  NULL, 'SR',   -- manual requisition transfer
                                             'A', 'N',
                                  NULL, lv_vdate,             -- current VDATE
                                                 lv_user,      -- current USER
                                  lv_vdate, lv_user, NULL,
                                  'N',                 -- repl_tsf_approve_ind
                                      'A',                   -- inventory_type
                                  NULL
                                 );

                     DBMS_OUTPUT.put_line ('inserted into tsfhead');
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        DBMS_OUTPUT.put_line
                                        ('error while inserting into tsfhead');
                  END;
               END LOOP;

               COMMIT;
            END IF;
         END IF;

-------------------------------------------------------------------------------------------------------------------------
         DBMS_OUTPUT.put_line (   ' step 2 moving '
                               || c1.wh
                               || '  to_loc '
                               || c1.to_loc
                              );
         -- step 2 obtaining all transfer numbers for warehouse and location combination where status='B' and tsf_type='SR'
         lv_tsf_exist := 0;

         FOR cur_tsf_exist IN cur_tsfhead (c1.wh, c1.to_loc)
         LOOP
            lv_tsf_exist := lv_tsf_exist + 1;
            DBMS_OUTPUT.put_line ('step 4 ' || cur_tsf_exist.tsf_no);
            DBMS_OUTPUT.put_line ('step 4 ' || c1.scc_code);

            -- step 4 check if the item exist in details records
            SELECT COUNT (tsf_no)
              INTO lv_count_tsf
              FROM tsfdetail
             WHERE tsf_no = cur_tsf_exist.tsf_no AND item = c1.scc_code;

            -- if item exists in detail table then update allocated qty
            IF lv_count_tsf > 0
            THEN
               UPDATE tsfdetail
                  SET tsf_qty = tsf_qty + c1.qty_allocated
                WHERE tsf_no = cur_tsf_exist.tsf_no AND item = c1.scc_code;
            ELSE                    -- if item does not exists in detail table
               -- generating next seq number for detail table
               SELECT (NVL (MAX (tsf_seq_no), 0) + 1)
                 INTO lv_tsf_seq_no
                 FROM tsfdetail
                WHERE tsf_no = cur_tsf_exist.tsf_no;

               -- get supplier package size for the item detail
               IF supp_item_attrib_sql.get_supp_pack_size (lv_error_message,
                                                           lv_supp_pack_size,
                                                           c1.scc_code,
                                                           NULL,
                                                           NULL
                                                          ) = FALSE
               THEN
                  RETURN;
               END IF;

               DBMS_OUTPUT.put_line ('package size ' || lv_supp_pack_size);

               BEGIN
/*  24 Nov 2008 Dibyendu Added this Begin end block to trap any exception on Insert   */
                  --step 5 inserting into tsfdetail
                  INSERT INTO tsfdetail
                              (tsf_no, tsf_seq_no,
                               item, tsf_qty,
                               supp_pack_size, inv_status, tsf_po_link_no,
                               mbr_processed_ind, publish_ind, fill_qty,
                               ship_qty, received_qty, distro_qty,
                               selected_qty, cancelled_qty
                              )
                       VALUES (cur_tsf_exist.tsf_no, lv_tsf_seq_no,
                               c1.scc_code, c1.qty_allocated,
                               lv_supp_pack_size, NULL, NULL,
                                                             -- tsf_po_link_no
                               NULL,                      -- mbr_processed_ind
                                    'N',                        -- publish_ind
                                        NULL,                      -- fill_qty
                               NULL,                               -- ship_qty
                                    NULL,                      -- received_qty
                                         NULL,                   -- distro_qty
                               NULL,                           -- selected_qty
                                    NULL
                              );                              -- cancelled_qty
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     DBMS_OUTPUT.put_line
                          (   'Error while inserting into tsf detail due to '
                           || SQLERRM
                          );
               END;
/*   24 Nov 2008 Dibyendu Added this Begin end block to trap any exception on Insert  */

               IF NOT transfer_charge_sql.default_chrgs
                                                  (lv_error_message,
                                                   cur_tsf_exist.tsf_no,
                                                   cur_tsf_exist.tsf_type,
                                                   lv_tsf_seq_no,
                                                                 -- tsf_seq_no
                                                   NULL,           -- shipment
                                                   NULL,        -- ship_seq_no
                                                   c1.wh,
                                                   'W',
                                                   c1.to_loc,
                                                   c1.to_loc_type,
                                                   c1.scc_code
                                                  ) = FALSE
               THEN
                  RETURN;
               END IF;
            END IF;
         END LOOP;

         DBMS_OUTPUT.put_line (   'updating item_loc_soh '
                               || c1.qty_allocated
                               || ' wh '
                               || c1.wh
                               || ' scc '
                               || c1.scc_code
                               || ' loc type '
                               || c1.to_loc_type
                              );

         --steps 6 updating the item_loc_soh tables

         -- update the tsf_reserved_qty for scc code as the wh
         UPDATE item_loc_soh
            SET tsf_reserved_qty = tsf_reserved_qty + c1.qty_allocated,
                last_update_datetime = lv_vdate,
                last_update_id = lv_user
          WHERE item = c1.scc_code AND loc = c1.wh AND loc_type = 'W';

         -- update the pack_comp_resv for the plcb code as the WH
         UPDATE item_loc_soh
            SET pack_comp_resv = pack_comp_resv + c1.qty_allocated,
                last_update_datetime = lv_vdate,
                last_update_id = lv_user
          WHERE item = c1.plcb_code AND loc = c1.wh AND loc_type = 'W';

         -- If TO_LOC_TYPE = 'S' from step 1, Update the tsf_expected_qty for the PLCB Code at the store
         IF c1.to_loc_type = 'S'
         THEN
            /* update tsf_expected_qty for PLCB code */
            UPDATE item_loc_soh
               SET tsf_expected_qty = tsf_expected_qty + c1.qty_allocated,
                   last_update_datetime = lv_vdate,
                   last_update_id = lv_user
             WHERE item = c1.plcb_code
               AND loc = c1.to_loc
               AND loc_type = c1.to_loc_type;
         ELSE
            -- if loc_type='W' then update tsf_expected_qty for SCC code at the wh
            UPDATE item_loc_soh
               SET tsf_expected_qty = tsf_expected_qty + c1.qty_allocated,
                   last_update_datetime = lv_vdate,
                   last_update_id = lv_user
             WHERE item = c1.scc_code
               AND loc = c1.to_loc
               AND loc_type = c1.to_loc_type;

            /* update pack_comp_exp for PLCB code */
            UPDATE item_loc_soh
               SET pack_comp_exp = pack_comp_exp + c1.qty_allocated,
                   last_update_datetime = lv_vdate,
                   last_update_id = lv_user
             WHERE item = c1.plcb_code
               AND loc = c1.to_loc
               AND loc_type = c1.to_loc_type;
         END IF;
      ----------------------Step 7 delete the records from alloc_header, alloc_detail and alloc_charg tables

      --delete from alloc_chrg for up charges
--             DELETE FROM alloc_chrg
--                   WHERE alloc_no = c1.alloc_no
--                     AND item = c1.scc_code
--                     AND to_loc = c1.to_loc;
--
--          --delete from alloc_detail
--             DELETE FROM alloc_detail
--                   WHERE alloc_no = c1.alloc_no
--                and to_loc = c1.to_loc;
--
--          -- delete from alloc_header
--          Delete from alloc_header h
--          Where h.alloc_no = c1.alloc_no
--          And h.wh = c1.wh
--          And not exists (select 'X'
--                           From alloc_detail d
--                           Where h.alloc_no = d.alloc_no);
--

      --------------------------------------------------------------------------
      END LOOP;

      COMMIT;
      DBMS_OUTPUT.put_line ('Successfully transfered');
   END main;
END xxlcb_transfer_alloc;
/