/* Formatted on 2009/07/29 09:31 (Formatter Plus v4.8.7) */
CREATE OR REPLACE PACKAGE BODY bilc_mtl_txn_interface_pkg
--
--
--
-- **************************************************************************************
-- *                                                                                    *
-- * PL/SQL Package     :       BILC_MTL_TXN_INTERFACE_PKG                              *
-- * Date               :       27-July-2009                                            *
-- * Purpose            :  Package is used for Populating Subinventory Transfer/Misc    *
---*                       Receipt Transactions                                         *
-- *                                                                                    *
-- *------------------------------------------------------------------------------------*
-- * Modifications      :                                                               *
-- *                                                                                    *
-- * Version     DD-MON-YYYY     Person        Changes Made                             *
-- * ----------  -------------  ------------  ----------------------------------------- *
-- * DRAFT1A     27-July-2009    Dibyendu     Initial Draft Version                 *
-- *                                                                                    *
-- **************************************************************************************
AS
   PROCEDURE bilc_call_main
   IS
      lv_request_id   NUMBER;
   BEGIN
      fnd_global.apps_initialize (0, 50238, 401);
      lv_request_id :=
         fnd_request.submit_request (application      => 'BTVL',
                                     program          => 'BILCINVTXN'
                                    );
      COMMIT;
      display_message ('The Request ID is : ' || lv_request_id);

      IF lv_request_id <> 0
      THEN
         display_message
            (   'SUCESSFULLY SUBMITTED The Inventory Transaction Interface Program: with Request_ID :'
             || lv_request_id
            );
         DBMS_OUTPUT.put_line
            (   'SUCESSFULLY SUBMITTED The Inventory Transaction Interface Program: with Request_ID :'
             || lv_request_id
            );
      ELSE
         display_message
                ('Failed in Submitting BILC Inventory Transactions Interface');
         DBMS_OUTPUT.put_line
                ('Failed in Submitting BILC Inventory Transactions Interface');
      END IF;
   END bilc_call_main;

   PROCEDURE bilc_txn_stg_prc (errbuf OUT VARCHAR2, retcode OUT NUMBER)
   IS
      lv_message           VARCHAR2 (5000);
      lv_mtl_line_num      NUMBER          := 0;
      lv_lot_line_num      NUMBER          := 0;
      lv_serial_line_num   NUMBER          := 0;
      ln_error_no          NUMBER          := 0;

      CURSOR mmt_c
      IS
         SELECT *
           FROM bilc_mtl_txn_stg_tbl
          WHERE status = 'NEW';

      CURSOR mmt_lots_c (
         p_transaction_id   IN   bilc_mtl_txn_lots_stg_tbl.transaction_interface_id%TYPE
      )
      IS
         SELECT *
           FROM bilc_mtl_txn_lots_stg_tbl
          WHERE transaction_interface_id = p_transaction_id
                AND status = 'NEW';

      CURSOR mmt_serial_c (
         p_transaction_id   IN   bilc_mtl_txn_lots_stg_tbl.serial_transaction_temp_id%TYPE
      )
      IS
         SELECT *
           FROM bilc_mtl_sln_stg_tbl
          WHERE transaction_interface_id = p_transaction_id
                AND status = 'NEW';
   BEGIN
      FOR c_mtl_txn IN mmt_c
      LOOP
         lv_lot_line_num := 0;
         lv_serial_line_num := 0;
         lv_message :=
               'START : Opening the MTL_TXN Cursor Fetching Transaction ID: '
            || c_mtl_txn.transaction_interface_id;
         display_message (lv_message);
         lv_mtl_line_num := lv_mtl_line_num + 1;
         g_mtl_txn_rec := c_mtl_txn;
         g_mtl_lots_txn_tbl := g_mtl_lots_txn_tbl_dummy;
         g_mtl_sln_txn_tbl := g_mtl_sln_txn_tbl_dummy;

         FOR c_mtl_lots IN mmt_lots_c (c_mtl_txn.transaction_interface_id)
         LOOP
            lv_message :=
                  'START : Opening the MTL_LOTS Cursor Fetching Transaction ID '
               || c_mtl_lots.transaction_interface_id;
            display_message (lv_message);
            lv_lot_line_num := lv_lot_line_num + 1;
            g_mtl_lots_txn_tbl (lv_lot_line_num) := c_mtl_lots;

            FOR c_mtl_serial IN
               mmt_serial_c (c_mtl_lots.serial_transaction_temp_id)
            LOOP
               lv_message :=
                     'START : Openin the MTL_Serial Cursor Fetching Serial Transaction ID :'
                  || c_mtl_serial.transaction_interface_id;
               display_message (lv_message);
               lv_serial_line_num := lv_serial_line_num + 1;
               g_mtl_sln_txn_tbl (lv_serial_line_num) := c_mtl_serial;
            END LOOP;
         /*  Serial Loop Ends */
         END LOOP;

         IF lv_mtl_line_num = 0
         THEN
            /* Neeed to insert into error table */
            lv_message := 'No Transaction Exists';
            ln_error_no := ln_error_no + 1;
            g_errors_tbl (ln_error_no).error_message := lv_message;
            bilc_inv_errors (g_errors_tbl);
            display_message (lv_message);
         ELSE
            IF lv_lot_line_num = 0
            THEN
               lv_message := 'No Lot Exists';
               display_message (lv_message);
               ln_error_no := ln_error_no + 1;
               g_errors_tbl (ln_error_no).error_message := lv_message;
            ELSE
               bilc_txn_process_prc (g_mtl_txn_rec,
                                     g_mtl_lots_txn_tbl,
                                     g_mtl_sln_txn_tbl
                                    );
            END IF;
         END IF;                                          /*  Lot Loop Ends */
      END LOOP;                                /* MTL Transaction Loop Ends */
   EXCEPTION
      WHEN OTHERS
      THEN
/* Neeed to insert data into the Error table*/
         lv_message := 'Error in the Interface Program due to :' || SQLERRM;
         display_message (lv_message);
         ln_error_no := ln_error_no + 1;
         g_errors_tbl (ln_error_no).error_message := lv_message;
   END bilc_txn_stg_prc;

   PROCEDURE bilc_txn_process_prc (
      p_mtl_txn_rec        IN   bilc_mtl_txn_stg_tbl%ROWTYPE,
      p_mtl_lots_txn_tbl   IN   g_mtl_lots_txn_tbl_type,
      p_mtl_sln_txn_tbl    IN   g_mtl_sln_txn_tbl_type
   )
   IS
      lv_mtl_txn_rec        bilc_mtl_txn_stg_tbl%ROWTYPE;
      lv_mtl_lots_txn_tbl   g_mtl_lots_txn_tbl_type;
      lv_mtl_sln_txn_tbl    g_mtl_sln_txn_tbl_type;
      g_errors_tbl          g_errors_tbl_type;
      lv_user_id            NUMBER                      := fnd_global.user_id;
      lv_request_id         NUMBER              := fnd_global.conc_request_id;
      lv_program_appl_id    NUMBER                 := fnd_global.prog_appl_id;
      ln_err_cnt            NUMBER                                     := 0;
      v_chk                 NUMBER;
      v_lot_control_code    mtl_system_items_b.lot_control_code%TYPE;
      lv_message            VARCHAR2 (5000);
   BEGIN
/* Assigning the Transaction Record */
      lv_mtl_txn_rec.staging_id := p_mtl_txn_rec.staging_id;
      lv_mtl_txn_rec.transaction_interface_id :=
                                       p_mtl_txn_rec.transaction_interface_id;
      lv_mtl_txn_rec.transaction_header_id :=
                                          p_mtl_txn_rec.transaction_header_id;
      lv_mtl_txn_rec.source_code := p_mtl_txn_rec.source_code;
      lv_mtl_txn_rec.source_line_id := p_mtl_txn_rec.source_line_id;
      lv_mtl_txn_rec.source_header_id := p_mtl_txn_rec.source_header_id;
      lv_mtl_txn_rec.process_flag := p_mtl_txn_rec.process_flag;
      lv_mtl_txn_rec.validation_required := p_mtl_txn_rec.validation_required;
      lv_mtl_txn_rec.transaction_mode := p_mtl_txn_rec.transaction_mode;
      lv_mtl_txn_rec.lock_flag := p_mtl_txn_rec.lock_flag;
      lv_mtl_txn_rec.last_update_date := SYSDATE;
      lv_mtl_txn_rec.last_updated_by := lv_user_id;
      lv_mtl_txn_rec.creation_date := SYSDATE;
      lv_mtl_txn_rec.created_by := lv_user_id;
      lv_mtl_txn_rec.last_update_login := lv_user_id;
      lv_mtl_txn_rec.request_id := lv_request_id;
      lv_mtl_txn_rec.program_application_id := lv_program_appl_id;
      lv_mtl_txn_rec.program_id :=
                          32321 /* Currently Hard coded needs to be changed */;
      lv_mtl_txn_rec.program_update_date := SYSDATE;
      lv_mtl_txn_rec.inventory_item_id := p_mtl_txn_rec.inventory_item_id;
      lv_mtl_txn_rec.item_segment1 := p_mtl_txn_rec.item_segment1;
      lv_mtl_txn_rec.item_segment2 := p_mtl_txn_rec.item_segment2;
      lv_mtl_txn_rec.item_segment3 := p_mtl_txn_rec.item_segment3;
      lv_mtl_txn_rec.item_segment4 := p_mtl_txn_rec.item_segment4;
      lv_mtl_txn_rec.item_segment5 := p_mtl_txn_rec.item_segment5;
      lv_mtl_txn_rec.item_segment6 := p_mtl_txn_rec.item_segment6;
      lv_mtl_txn_rec.item_segment7 := p_mtl_txn_rec.item_segment7;
      lv_mtl_txn_rec.item_segment8 := p_mtl_txn_rec.item_segment8;
      lv_mtl_txn_rec.item_segment9 := p_mtl_txn_rec.item_segment9;
      lv_mtl_txn_rec.item_segment10 := p_mtl_txn_rec.item_segment10;
      lv_mtl_txn_rec.item_segment11 := p_mtl_txn_rec.item_segment11;
      lv_mtl_txn_rec.item_segment12 := p_mtl_txn_rec.item_segment12;
      lv_mtl_txn_rec.item_segment13 := p_mtl_txn_rec.item_segment13;
      lv_mtl_txn_rec.item_segment14 := p_mtl_txn_rec.item_segment14;
      lv_mtl_txn_rec.item_segment15 := p_mtl_txn_rec.item_segment15;
      lv_mtl_txn_rec.item_segment16 := p_mtl_txn_rec.item_segment16;
      lv_mtl_txn_rec.item_segment17 := p_mtl_txn_rec.item_segment17;
      lv_mtl_txn_rec.item_segment18 := p_mtl_txn_rec.item_segment18;
      lv_mtl_txn_rec.item_segment19 := p_mtl_txn_rec.item_segment19;
      lv_mtl_txn_rec.item_segment20 := p_mtl_txn_rec.item_segment20;
      lv_mtl_txn_rec.revision := p_mtl_txn_rec.revision;
      lv_mtl_txn_rec.organization_id := p_mtl_txn_rec.organization_id;
      lv_mtl_txn_rec.transaction_quantity :=
                                           p_mtl_txn_rec.transaction_quantity;
      lv_mtl_txn_rec.primary_quantity := p_mtl_txn_rec.primary_quantity;
      lv_mtl_txn_rec.transaction_uom := p_mtl_txn_rec.transaction_uom;
      lv_mtl_txn_rec.transaction_date := SYSDATE;
      lv_mtl_txn_rec.acct_period_id := p_mtl_txn_rec.acct_period_id;
      lv_mtl_txn_rec.subinventory_code := p_mtl_txn_rec.subinventory_code;
      lv_mtl_txn_rec.locator_id := p_mtl_txn_rec.locator_id;
      lv_mtl_txn_rec.loc_segment1 := p_mtl_txn_rec.loc_segment1;
      lv_mtl_txn_rec.loc_segment2 := p_mtl_txn_rec.loc_segment2;
      lv_mtl_txn_rec.loc_segment3 := p_mtl_txn_rec.loc_segment3;
      lv_mtl_txn_rec.loc_segment4 := p_mtl_txn_rec.loc_segment4;
      lv_mtl_txn_rec.loc_segment5 := p_mtl_txn_rec.loc_segment5;
      lv_mtl_txn_rec.loc_segment6 := p_mtl_txn_rec.loc_segment6;
      lv_mtl_txn_rec.loc_segment7 := p_mtl_txn_rec.loc_segment7;
      lv_mtl_txn_rec.loc_segment8 := p_mtl_txn_rec.loc_segment8;
      lv_mtl_txn_rec.loc_segment9 := p_mtl_txn_rec.loc_segment9;
      lv_mtl_txn_rec.loc_segment10 := p_mtl_txn_rec.loc_segment10;
      lv_mtl_txn_rec.loc_segment11 := p_mtl_txn_rec.loc_segment11;
      lv_mtl_txn_rec.loc_segment12 := p_mtl_txn_rec.loc_segment12;
      lv_mtl_txn_rec.loc_segment13 := p_mtl_txn_rec.loc_segment13;
      lv_mtl_txn_rec.loc_segment14 := p_mtl_txn_rec.loc_segment14;
      lv_mtl_txn_rec.loc_segment15 := p_mtl_txn_rec.loc_segment15;
      lv_mtl_txn_rec.loc_segment16 := p_mtl_txn_rec.loc_segment16;
      lv_mtl_txn_rec.loc_segment17 := p_mtl_txn_rec.loc_segment17;
      lv_mtl_txn_rec.loc_segment18 := p_mtl_txn_rec.loc_segment18;
      lv_mtl_txn_rec.loc_segment19 := p_mtl_txn_rec.loc_segment19;
      lv_mtl_txn_rec.loc_segment20 := p_mtl_txn_rec.loc_segment20;
      lv_mtl_txn_rec.transaction_source_id :=
                                          p_mtl_txn_rec.transaction_source_id;
      lv_mtl_txn_rec.dsp_segment1 := p_mtl_txn_rec.dsp_segment1;
      lv_mtl_txn_rec.dsp_segment2 := p_mtl_txn_rec.dsp_segment2;
      lv_mtl_txn_rec.dsp_segment3 := p_mtl_txn_rec.dsp_segment3;
      lv_mtl_txn_rec.dsp_segment4 := p_mtl_txn_rec.dsp_segment4;
      lv_mtl_txn_rec.dsp_segment5 := p_mtl_txn_rec.dsp_segment5;
      lv_mtl_txn_rec.dsp_segment6 := p_mtl_txn_rec.dsp_segment6;
      lv_mtl_txn_rec.dsp_segment7 := p_mtl_txn_rec.dsp_segment7;
      lv_mtl_txn_rec.dsp_segment8 := p_mtl_txn_rec.dsp_segment8;
      lv_mtl_txn_rec.dsp_segment9 := p_mtl_txn_rec.dsp_segment9;
      lv_mtl_txn_rec.dsp_segment10 := p_mtl_txn_rec.dsp_segment10;
      lv_mtl_txn_rec.dsp_segment11 := p_mtl_txn_rec.dsp_segment11;
      lv_mtl_txn_rec.dsp_segment12 := p_mtl_txn_rec.dsp_segment12;
      lv_mtl_txn_rec.dsp_segment13 := p_mtl_txn_rec.dsp_segment13;
      lv_mtl_txn_rec.dsp_segment14 := p_mtl_txn_rec.dsp_segment14;
      lv_mtl_txn_rec.dsp_segment15 := p_mtl_txn_rec.dsp_segment15;
      lv_mtl_txn_rec.dsp_segment16 := p_mtl_txn_rec.dsp_segment16;
      lv_mtl_txn_rec.dsp_segment17 := p_mtl_txn_rec.dsp_segment17;
      lv_mtl_txn_rec.dsp_segment18 := p_mtl_txn_rec.dsp_segment18;
      lv_mtl_txn_rec.dsp_segment19 := p_mtl_txn_rec.dsp_segment19;
      lv_mtl_txn_rec.dsp_segment20 := p_mtl_txn_rec.dsp_segment20;
      lv_mtl_txn_rec.dsp_segment21 := p_mtl_txn_rec.dsp_segment22;
      lv_mtl_txn_rec.dsp_segment22 := p_mtl_txn_rec.dsp_segment22;
      lv_mtl_txn_rec.dsp_segment23 := p_mtl_txn_rec.dsp_segment23;
      lv_mtl_txn_rec.dsp_segment24 := p_mtl_txn_rec.dsp_segment24;
      lv_mtl_txn_rec.dsp_segment25 := p_mtl_txn_rec.dsp_segment25;
      lv_mtl_txn_rec.dsp_segment26 := p_mtl_txn_rec.dsp_segment26;
      lv_mtl_txn_rec.dsp_segment27 := p_mtl_txn_rec.dsp_segment27;
      lv_mtl_txn_rec.dsp_segment28 := p_mtl_txn_rec.dsp_segment28;
      lv_mtl_txn_rec.dsp_segment29 := p_mtl_txn_rec.dsp_segment29;
      lv_mtl_txn_rec.dsp_segment30 := p_mtl_txn_rec.dsp_segment30;
      lv_mtl_txn_rec.transaction_source_name :=
                                        p_mtl_txn_rec.transaction_source_name;
      lv_mtl_txn_rec.transaction_source_type_id :=
                                     p_mtl_txn_rec.transaction_source_type_id;
      lv_mtl_txn_rec.transaction_action_id :=
                                          p_mtl_txn_rec.transaction_action_id;
      lv_mtl_txn_rec.transaction_type_id := p_mtl_txn_rec.transaction_type_id;
      lv_mtl_txn_rec.reason_id := p_mtl_txn_rec.reason_id;
      lv_mtl_txn_rec.transaction_reference :=
                                          p_mtl_txn_rec.transaction_reference;
      lv_mtl_txn_rec.transaction_cost := p_mtl_txn_rec.transaction_cost;
      lv_mtl_txn_rec.distribution_account_id :=
                                        p_mtl_txn_rec.distribution_account_id;
      lv_mtl_txn_rec.dst_segment1 := p_mtl_txn_rec.dst_segment1;
      lv_mtl_txn_rec.dst_segment2 := p_mtl_txn_rec.dst_segment2;
      lv_mtl_txn_rec.dst_segment3 := p_mtl_txn_rec.dst_segment3;
      lv_mtl_txn_rec.dst_segment4 := p_mtl_txn_rec.dst_segment4;
      lv_mtl_txn_rec.dst_segment5 := p_mtl_txn_rec.dst_segment5;
      lv_mtl_txn_rec.dst_segment6 := p_mtl_txn_rec.dst_segment6;
      lv_mtl_txn_rec.dst_segment7 := p_mtl_txn_rec.dst_segment7;
      lv_mtl_txn_rec.dst_segment8 := p_mtl_txn_rec.dst_segment8;
      lv_mtl_txn_rec.dst_segment9 := p_mtl_txn_rec.dst_segment9;
      lv_mtl_txn_rec.dst_segment10 := p_mtl_txn_rec.dst_segment10;
      lv_mtl_txn_rec.dst_segment11 := p_mtl_txn_rec.dst_segment11;
      lv_mtl_txn_rec.dst_segment12 := p_mtl_txn_rec.dst_segment12;
      lv_mtl_txn_rec.dst_segment13 := p_mtl_txn_rec.dst_segment13;
      lv_mtl_txn_rec.dst_segment14 := p_mtl_txn_rec.dst_segment14;
      lv_mtl_txn_rec.dst_segment15 := p_mtl_txn_rec.dst_segment15;
      lv_mtl_txn_rec.dst_segment16 := p_mtl_txn_rec.dst_segment16;
      lv_mtl_txn_rec.dst_segment17 := p_mtl_txn_rec.dst_segment17;
      lv_mtl_txn_rec.dst_segment18 := p_mtl_txn_rec.dst_segment18;
      lv_mtl_txn_rec.dst_segment19 := p_mtl_txn_rec.dst_segment19;
      lv_mtl_txn_rec.dst_segment20 := p_mtl_txn_rec.dst_segment20;
      lv_mtl_txn_rec.dst_segment21 := p_mtl_txn_rec.dst_segment21;
      lv_mtl_txn_rec.dst_segment22 := p_mtl_txn_rec.dst_segment22;
      lv_mtl_txn_rec.dst_segment23 := p_mtl_txn_rec.dst_segment23;
      lv_mtl_txn_rec.dst_segment24 := p_mtl_txn_rec.dst_segment24;
      lv_mtl_txn_rec.dst_segment25 := p_mtl_txn_rec.dst_segment25;
      lv_mtl_txn_rec.dst_segment26 := p_mtl_txn_rec.dst_segment26;
      lv_mtl_txn_rec.dst_segment27 := p_mtl_txn_rec.dst_segment27;
      lv_mtl_txn_rec.dst_segment28 := p_mtl_txn_rec.dst_segment28;
      lv_mtl_txn_rec.dst_segment29 := p_mtl_txn_rec.dst_segment29;
      lv_mtl_txn_rec.dst_segment30 := p_mtl_txn_rec.dst_segment30;
      lv_mtl_txn_rec.requisition_line_id := p_mtl_txn_rec.requisition_line_id;
      lv_mtl_txn_rec.currency_code := p_mtl_txn_rec.currency_code;
      lv_mtl_txn_rec.currency_conversion_date :=
                                       p_mtl_txn_rec.currency_conversion_date;
      lv_mtl_txn_rec.currency_conversion_type :=
                                       p_mtl_txn_rec.currency_conversion_type;
      lv_mtl_txn_rec.currency_conversion_rate :=
                                       p_mtl_txn_rec.currency_conversion_rate;
      lv_mtl_txn_rec.ussgl_transaction_code :=
                                         p_mtl_txn_rec.ussgl_transaction_code;
      lv_mtl_txn_rec.wip_entity_type := p_mtl_txn_rec.wip_entity_type;
      lv_mtl_txn_rec.schedule_id := p_mtl_txn_rec.schedule_id;
      lv_mtl_txn_rec.employee_code := p_mtl_txn_rec.employee_code;
      lv_mtl_txn_rec.department_id := p_mtl_txn_rec.department_id;
      lv_mtl_txn_rec.schedule_update_code :=
                                           p_mtl_txn_rec.schedule_update_code;
      lv_mtl_txn_rec.setup_teardown_code := p_mtl_txn_rec.setup_teardown_code;
      lv_mtl_txn_rec.primary_switch := p_mtl_txn_rec.primary_switch;
      lv_mtl_txn_rec.mrp_code := p_mtl_txn_rec.mrp_code;
      lv_mtl_txn_rec.operation_seq_num := p_mtl_txn_rec.operation_seq_num;
      lv_mtl_txn_rec.repetitive_line_id := p_mtl_txn_rec.repetitive_line_id;
      lv_mtl_txn_rec.picking_line_id := p_mtl_txn_rec.picking_line_id;
      lv_mtl_txn_rec.trx_source_line_id := p_mtl_txn_rec.trx_source_line_id;
      lv_mtl_txn_rec.trx_source_delivery_id :=
                                         p_mtl_txn_rec.trx_source_delivery_id;
      lv_mtl_txn_rec.demand_id := p_mtl_txn_rec.demand_id;
      lv_mtl_txn_rec.customer_ship_id := p_mtl_txn_rec.customer_ship_id;
      lv_mtl_txn_rec.line_item_num := p_mtl_txn_rec.line_item_num;
      lv_mtl_txn_rec.receiving_document := p_mtl_txn_rec.receiving_document;
      lv_mtl_txn_rec.rcv_transaction_id := p_mtl_txn_rec.rcv_transaction_id;
      lv_mtl_txn_rec.ship_to_location_id := p_mtl_txn_rec.ship_to_location_id;
      lv_mtl_txn_rec.encumbrance_account := p_mtl_txn_rec.encumbrance_account;
      lv_mtl_txn_rec.encumbrance_amount := p_mtl_txn_rec.encumbrance_amount;
      lv_mtl_txn_rec.vendor_lot_number := p_mtl_txn_rec.vendor_lot_number;
      lv_mtl_txn_rec.transfer_subinventory :=
                                          p_mtl_txn_rec.transfer_subinventory;
      lv_mtl_txn_rec.transfer_organization :=
                                          p_mtl_txn_rec.transfer_organization;
      lv_mtl_txn_rec.transfer_locator := p_mtl_txn_rec.transfer_locator;
      lv_mtl_txn_rec.xfer_loc_segment1 := p_mtl_txn_rec.xfer_loc_segment1;
      lv_mtl_txn_rec.xfer_loc_segment2 := p_mtl_txn_rec.xfer_loc_segment2;
      lv_mtl_txn_rec.xfer_loc_segment3 := p_mtl_txn_rec.xfer_loc_segment3;
      lv_mtl_txn_rec.xfer_loc_segment4 := p_mtl_txn_rec.xfer_loc_segment4;
      lv_mtl_txn_rec.xfer_loc_segment5 := p_mtl_txn_rec.xfer_loc_segment5;
      lv_mtl_txn_rec.xfer_loc_segment6 := p_mtl_txn_rec.xfer_loc_segment6;
      lv_mtl_txn_rec.xfer_loc_segment7 := p_mtl_txn_rec.xfer_loc_segment7;
      lv_mtl_txn_rec.xfer_loc_segment8 := p_mtl_txn_rec.xfer_loc_segment8;
      lv_mtl_txn_rec.xfer_loc_segment9 := p_mtl_txn_rec.xfer_loc_segment9;
      lv_mtl_txn_rec.xfer_loc_segment10 := p_mtl_txn_rec.xfer_loc_segment10;
      lv_mtl_txn_rec.xfer_loc_segment11 := p_mtl_txn_rec.xfer_loc_segment11;
      lv_mtl_txn_rec.xfer_loc_segment12 := p_mtl_txn_rec.xfer_loc_segment12;
      lv_mtl_txn_rec.xfer_loc_segment13 := p_mtl_txn_rec.xfer_loc_segment13;
      lv_mtl_txn_rec.xfer_loc_segment14 := p_mtl_txn_rec.xfer_loc_segment14;
      lv_mtl_txn_rec.xfer_loc_segment15 := p_mtl_txn_rec.xfer_loc_segment15;
      lv_mtl_txn_rec.xfer_loc_segment16 := p_mtl_txn_rec.xfer_loc_segment16;
      lv_mtl_txn_rec.xfer_loc_segment17 := p_mtl_txn_rec.xfer_loc_segment17;
      lv_mtl_txn_rec.xfer_loc_segment18 := p_mtl_txn_rec.xfer_loc_segment18;
      lv_mtl_txn_rec.xfer_loc_segment19 := p_mtl_txn_rec.xfer_loc_segment19;
      lv_mtl_txn_rec.xfer_loc_segment20 := p_mtl_txn_rec.xfer_loc_segment20;
      lv_mtl_txn_rec.shipment_number := p_mtl_txn_rec.shipment_number;
      lv_mtl_txn_rec.transportation_cost := p_mtl_txn_rec.transportation_cost;
      lv_mtl_txn_rec.transportation_account :=
                                         p_mtl_txn_rec.transportation_account;
      lv_mtl_txn_rec.transfer_cost := p_mtl_txn_rec.transfer_cost;
      lv_mtl_txn_rec.freight_code := p_mtl_txn_rec.freight_code;
      lv_mtl_txn_rec.containers := p_mtl_txn_rec.containers;
      lv_mtl_txn_rec.waybill_airbill := p_mtl_txn_rec.waybill_airbill;
      lv_mtl_txn_rec.expected_arrival_date :=
                                          p_mtl_txn_rec.expected_arrival_date;
      lv_mtl_txn_rec.new_average_cost := p_mtl_txn_rec.new_average_cost;
      lv_mtl_txn_rec.value_change := p_mtl_txn_rec.value_change;
      lv_mtl_txn_rec.percentage_change := p_mtl_txn_rec.percentage_change;
      lv_mtl_txn_rec.demand_source_header_id :=
                                        p_mtl_txn_rec.demand_source_header_id;
      lv_mtl_txn_rec.demand_source_line := p_mtl_txn_rec.demand_source_line;
      lv_mtl_txn_rec.demand_source_delivery :=
                                         p_mtl_txn_rec.demand_source_delivery;
      lv_mtl_txn_rec.negative_req_flag := p_mtl_txn_rec.negative_req_flag;
      lv_mtl_txn_rec.error_explanation := p_mtl_txn_rec.error_explanation;
      lv_mtl_txn_rec.shippable_flag := p_mtl_txn_rec.shippable_flag;
      lv_mtl_txn_rec.ERROR_CODE := p_mtl_txn_rec.ERROR_CODE;
      lv_mtl_txn_rec.required_flag := p_mtl_txn_rec.required_flag;
      lv_mtl_txn_rec.attribute_category := p_mtl_txn_rec.attribute_category;
      lv_mtl_txn_rec.attribute1 := p_mtl_txn_rec.attribute1;
      lv_mtl_txn_rec.attribute2 := p_mtl_txn_rec.attribute2;
      lv_mtl_txn_rec.attribute3 := p_mtl_txn_rec.attribute3;
      lv_mtl_txn_rec.attribute4 := p_mtl_txn_rec.attribute4;
      lv_mtl_txn_rec.attribute5 := p_mtl_txn_rec.attribute5;
      lv_mtl_txn_rec.attribute6 := p_mtl_txn_rec.attribute6;
      lv_mtl_txn_rec.attribute7 := p_mtl_txn_rec.attribute7;
      lv_mtl_txn_rec.attribute8 := p_mtl_txn_rec.attribute8;
      lv_mtl_txn_rec.attribute9 := p_mtl_txn_rec.attribute9;
      lv_mtl_txn_rec.attribute10 := p_mtl_txn_rec.attribute10;
      lv_mtl_txn_rec.attribute11 := p_mtl_txn_rec.attribute11;
      lv_mtl_txn_rec.attribute12 := p_mtl_txn_rec.attribute12;
      lv_mtl_txn_rec.attribute13 := p_mtl_txn_rec.attribute13;
      lv_mtl_txn_rec.attribute14 := p_mtl_txn_rec.attribute14;
      lv_mtl_txn_rec.attribute15 := p_mtl_txn_rec.attribute15;
      lv_mtl_txn_rec.requisition_distribution_id :=
                                    p_mtl_txn_rec.requisition_distribution_id;
      lv_mtl_txn_rec.movement_id := p_mtl_txn_rec.movement_id;
      lv_mtl_txn_rec.reservation_quantity :=
                                           p_mtl_txn_rec.reservation_quantity;
      lv_mtl_txn_rec.shipped_quantity := p_mtl_txn_rec.shipped_quantity;
      lv_mtl_txn_rec.inventory_item := p_mtl_txn_rec.inventory_item;
      lv_mtl_txn_rec.locator_name := p_mtl_txn_rec.locator_name;
      lv_mtl_txn_rec.task_id := p_mtl_txn_rec.task_id;
      lv_mtl_txn_rec.to_task_id := p_mtl_txn_rec.to_task_id;
      lv_mtl_txn_rec.source_task_id := p_mtl_txn_rec.source_task_id;
      lv_mtl_txn_rec.project_id := p_mtl_txn_rec.project_id;
      lv_mtl_txn_rec.to_project_id := p_mtl_txn_rec.to_project_id;
      lv_mtl_txn_rec.source_project_id := p_mtl_txn_rec.source_project_id;
      lv_mtl_txn_rec.pa_expenditure_org_id :=
                                          p_mtl_txn_rec.pa_expenditure_org_id;
      lv_mtl_txn_rec.expenditure_type := p_mtl_txn_rec.expenditure_type;
      lv_mtl_txn_rec.final_completion_flag :=
                                          p_mtl_txn_rec.final_completion_flag;
      lv_mtl_txn_rec.transfer_percentage := p_mtl_txn_rec.transfer_percentage;
      lv_mtl_txn_rec.transaction_sequence_id :=
                                        p_mtl_txn_rec.transaction_sequence_id;
      lv_mtl_txn_rec.material_account := p_mtl_txn_rec.material_account;
      lv_mtl_txn_rec.material_overhead_account :=
                                      p_mtl_txn_rec.material_overhead_account;
      lv_mtl_txn_rec.resource_account := p_mtl_txn_rec.resource_account;
      lv_mtl_txn_rec.outside_processing_account :=
                                     p_mtl_txn_rec.outside_processing_account;
      lv_mtl_txn_rec.overhead_account := p_mtl_txn_rec.overhead_account;
      lv_mtl_txn_rec.bom_revision := p_mtl_txn_rec.bom_revision;
      lv_mtl_txn_rec.routing_revision := p_mtl_txn_rec.routing_revision;
      lv_mtl_txn_rec.bom_revision_date := p_mtl_txn_rec.bom_revision_date;
      lv_mtl_txn_rec.routing_revision_date :=
                                          p_mtl_txn_rec.routing_revision_date;
      lv_mtl_txn_rec.alternate_bom_designator :=
                                       p_mtl_txn_rec.alternate_bom_designator;
      lv_mtl_txn_rec.alternate_routing_designator :=
                                   p_mtl_txn_rec.alternate_routing_designator;
      lv_mtl_txn_rec.accounting_class := p_mtl_txn_rec.accounting_class;
      lv_mtl_txn_rec.demand_class := p_mtl_txn_rec.demand_class;
      lv_mtl_txn_rec.parent_id := p_mtl_txn_rec.parent_id;
      lv_mtl_txn_rec.substitution_type_id :=
                                           p_mtl_txn_rec.substitution_type_id;
      lv_mtl_txn_rec.substitution_item_id :=
                                           p_mtl_txn_rec.substitution_item_id;
      lv_mtl_txn_rec.schedule_group := p_mtl_txn_rec.schedule_group;
      lv_mtl_txn_rec.build_sequence := p_mtl_txn_rec.build_sequence;
      lv_mtl_txn_rec.schedule_number := p_mtl_txn_rec.schedule_number;
      lv_mtl_txn_rec.scheduled_flag := p_mtl_txn_rec.scheduled_flag;
      lv_mtl_txn_rec.flow_schedule := p_mtl_txn_rec.flow_schedule;
      lv_mtl_txn_rec.cost_group_id := p_mtl_txn_rec.cost_group_id;
      lv_mtl_txn_rec.kanban_card_id := p_mtl_txn_rec.kanban_card_id;
      lv_mtl_txn_rec.qa_collection_id := p_mtl_txn_rec.qa_collection_id;
      lv_mtl_txn_rec.overcompletion_transaction_qty :=
                                 p_mtl_txn_rec.overcompletion_transaction_qty;
      lv_mtl_txn_rec.overcompletion_primary_qty :=
                                     p_mtl_txn_rec.overcompletion_primary_qty;
      lv_mtl_txn_rec.overcompletion_transaction_id :=
                                  p_mtl_txn_rec.overcompletion_transaction_id;
      lv_mtl_txn_rec.end_item_unit_number :=
                                           p_mtl_txn_rec.end_item_unit_number;
      lv_mtl_txn_rec.scheduled_payback_date :=
                                         p_mtl_txn_rec.scheduled_payback_date;
      lv_mtl_txn_rec.org_cost_group_id := p_mtl_txn_rec.org_cost_group_id;
      lv_mtl_txn_rec.cost_type_id := p_mtl_txn_rec.cost_type_id;
      lv_mtl_txn_rec.source_lot_number := p_mtl_txn_rec.source_lot_number;
      lv_mtl_txn_rec.transfer_cost_group_id :=
                                         p_mtl_txn_rec.transfer_cost_group_id;
      lv_mtl_txn_rec.lpn_id := p_mtl_txn_rec.lpn_id;
      lv_mtl_txn_rec.transfer_lpn_id := p_mtl_txn_rec.transfer_lpn_id;
      lv_mtl_txn_rec.content_lpn_id := p_mtl_txn_rec.content_lpn_id;
      lv_mtl_txn_rec.xml_document_id := p_mtl_txn_rec.xml_document_id;
      lv_mtl_txn_rec.organization_type := p_mtl_txn_rec.organization_type;
      lv_mtl_txn_rec.transfer_organization_type :=
                                     p_mtl_txn_rec.transfer_organization_type;
      lv_mtl_txn_rec.owning_organization_id :=
                                         p_mtl_txn_rec.owning_organization_id;
      lv_mtl_txn_rec.owning_tp_type := p_mtl_txn_rec.owning_tp_type;
      lv_mtl_txn_rec.xfr_owning_organization_id :=
                                     p_mtl_txn_rec.xfr_owning_organization_id;
      lv_mtl_txn_rec.transfer_owning_tp_type :=
                                        p_mtl_txn_rec.transfer_owning_tp_type;
      lv_mtl_txn_rec.planning_organization_id :=
                                       p_mtl_txn_rec.planning_organization_id;
      lv_mtl_txn_rec.planning_tp_type := p_mtl_txn_rec.planning_tp_type;
      lv_mtl_txn_rec.xfr_planning_organization_id :=
                                   p_mtl_txn_rec.xfr_planning_organization_id;
      lv_mtl_txn_rec.transfer_planning_tp_type :=
                                      p_mtl_txn_rec.transfer_planning_tp_type;
      lv_mtl_txn_rec.secondary_uom_code := p_mtl_txn_rec.secondary_uom_code;
      lv_mtl_txn_rec.secondary_transaction_quantity :=
                                 p_mtl_txn_rec.secondary_transaction_quantity;
      lv_mtl_txn_rec.transaction_group_id :=
                                           p_mtl_txn_rec.transaction_group_id;
      lv_mtl_txn_rec.transaction_group_seq :=
                                          p_mtl_txn_rec.transaction_group_seq;
      lv_mtl_txn_rec.representative_lot_number :=
                                      p_mtl_txn_rec.representative_lot_number;
      lv_mtl_txn_rec.transaction_batch_id :=
                                           p_mtl_txn_rec.transaction_batch_id;
      lv_mtl_txn_rec.transaction_batch_seq :=
                                          p_mtl_txn_rec.transaction_batch_seq;
      lv_mtl_txn_rec.rebuild_item_id := p_mtl_txn_rec.rebuild_item_id;
      lv_mtl_txn_rec.rebuild_serial_number :=
                                          p_mtl_txn_rec.rebuild_serial_number;
      lv_mtl_txn_rec.rebuild_activity_id := p_mtl_txn_rec.rebuild_activity_id;
      lv_mtl_txn_rec.rebuild_job_name := p_mtl_txn_rec.rebuild_job_name;
      lv_mtl_txn_rec.move_transaction_id := p_mtl_txn_rec.move_transaction_id;
      lv_mtl_txn_rec.completion_transaction_id :=
                                      p_mtl_txn_rec.completion_transaction_id;
      lv_mtl_txn_rec.wip_supply_type := p_mtl_txn_rec.wip_supply_type;
      /* Now Start Validating  */
      lv_message := 'Start of Validation';
      display_message (lv_message);

      IF lv_mtl_txn_rec.transaction_type_id = 2
      THEN                                   /* For Sub Inventory Transfer */
         lv_message :=
               'Transaction_interface_id :'
            || lv_mtl_txn_rec.transaction_interface_id
            || 'is for Sub inventory Transfer';
         /* Validating Quantity */
         display_message (lv_message);

         IF lv_mtl_txn_rec.transaction_quantity < 0
         THEN
            lv_message :=
                  'Transaction Quantity For Transaction ID '
               || lv_mtl_txn_rec.transaction_interface_id
               || 'is less than 0';
            display_message (lv_message);
            ln_err_cnt := ln_err_cnt + 1;
            g_errors_tbl (ln_err_cnt).error_message := lv_message;
            g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                       lv_mtl_txn_rec.transaction_interface_id;
            bilc_inv_errors (g_errors_tbl);
            COMMIT;
         END IF;

         /* Validating Transaction Type */
         BEGIN
            SELECT 1
              INTO v_chk
              FROM mtl_transaction_types
             WHERE transaction_type_id = lv_mtl_txn_rec.transaction_type_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               ln_err_cnt := ln_err_cnt + 1;
               lv_message :=
                     'Transaction Type '
                  || lv_mtl_txn_rec.transaction_type_id
                  || 'Does Not exists';
               g_errors_tbl (ln_err_cnt).error_message := lv_message;
               g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                       lv_mtl_txn_rec.transaction_interface_id;
               bilc_inv_errors (g_errors_tbl);
               display_message (lv_message);
               COMMIT;
         END;

         /* Validating  From Inventory Organization */
         BEGIN
            SELECT 1
              INTO v_chk
              FROM DUAL
             WHERE EXISTS (
                        SELECT organization_id
                          FROM mtl_parameters
                         WHERE organization_id =
                                                lv_mtl_txn_rec.organization_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               ln_err_cnt := ln_err_cnt + 1;
               lv_message :=
                     'The source Inventory Organization '
                  || lv_mtl_txn_rec.organization_id
                  || 'Does not exists';
               g_errors_tbl (ln_err_cnt).error_message := lv_message;
               g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                       lv_mtl_txn_rec.transaction_interface_id;
               bilc_inv_errors (g_errors_tbl);
               display_message (lv_message);
         END;

         /* Validating the Item for the Inventory Organization */
         BEGIN
            SELECT 1
              INTO v_chk
              FROM DUAL
             WHERE EXISTS (
                      SELECT inventory_item_id
                        FROM mtl_system_items_b
                       WHERE organization_id = lv_mtl_txn_rec.organization_id
                         AND inventory_item_id =
                                              lv_mtl_txn_rec.inventory_item_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               ln_err_cnt := ln_err_cnt + 1;
               lv_message :=
                     'The Item'
                  || lv_mtl_txn_rec.inventory_item_id
                  || 'Does not exists in the Source Organization  '
                  || lv_mtl_txn_rec.organization_id;
               g_errors_tbl (ln_err_cnt).error_message := lv_message;
               g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                       lv_mtl_txn_rec.transaction_interface_id;
               bilc_inv_errors (g_errors_tbl);
               display_message (lv_message);
         END;

         BEGIN
            /* Getting the Lot Controlled Code for the Item */
            SELECT lot_control_code
              INTO v_lot_control_code
              FROM mtl_system_items_b
             WHERE organization_id = lv_mtl_txn_rec.organization_id
               AND inventory_item_id = lv_mtl_txn_rec.inventory_item_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               ln_err_cnt := ln_err_cnt + 1;
               lv_message :=
                     'The Item '
                  || lv_mtl_txn_rec.inventory_item_id
                  || ' Does not have any Lot Controlled code';
               g_errors_tbl (ln_err_cnt).error_message := lv_message;
               g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                       lv_mtl_txn_rec.transaction_interface_id;
               bilc_inv_errors (g_errors_tbl);
               display_message (lv_message);
         END;

         BEGIN            /* Validatimng the existance of From subinventory */
            SELECT 1
              INTO v_chk
              FROM DUAL
             WHERE EXISTS (
                      SELECT secondary_inventory_name
                        FROM mtl_secondary_inventories
                       WHERE organization_id = lv_mtl_txn_rec.organization_id
                         AND secondary_inventory_name =
                                              lv_mtl_txn_rec.subinventory_code);
         /* Need to verify */
         EXCEPTION
            WHEN OTHERS
            THEN
               ln_err_cnt := ln_err_cnt + 1;
               lv_message :=
                     'Source Subinventory '
                  || lv_mtl_txn_rec.subinventory_code
                  || ' Does not exists in Inventory Organization'
                  || lv_mtl_txn_rec.organization_id;
               g_errors_tbl (ln_err_cnt).error_message := lv_message;
               g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                       lv_mtl_txn_rec.transaction_interface_id;
               bilc_inv_errors (g_errors_tbl);
               display_message (lv_message);
         END;

         BEGIN     /* Validatimng the exixtance of Destination subinventory */
            SELECT 1
              INTO v_chk
              FROM DUAL
             WHERE EXISTS (
                      SELECT secondary_inventory_name
                        FROM mtl_secondary_inventories
                       WHERE organization_id = lv_mtl_txn_rec.organization_id
                         AND secondary_inventory_name =
                                          lv_mtl_txn_rec.transfer_subinventory);
         EXCEPTION
            WHEN OTHERS
            THEN
               ln_err_cnt := ln_err_cnt + 1;
               lv_message :=
                     'Destination Subinventory '
                  || lv_mtl_txn_rec.subinventory_code
                  || ' Does not exists in Organization'
                  || lv_mtl_txn_rec.organization_id;
               g_errors_tbl (ln_err_cnt).error_message := lv_message;
               g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                       lv_mtl_txn_rec.transaction_interface_id;
               bilc_inv_errors (g_errors_tbl);
               display_message (lv_message);
         END;

/* Validating Locator Controlled */
         IF lv_mtl_txn_rec.locator_id IS NOT NULL
         THEN                                  /* validating source locator */
            BEGIN
               SELECT 1
                 INTO v_chk
                 FROM DUAL
                WHERE EXISTS (
                         SELECT mlk.inventory_location_id
                           FROM mtl_item_locations_kfv mlk,
                                mtl_secondary_inventories misc
                          WHERE mlk.organization_id = misc.organization_id
                            AND mlk.subinventory_code =
                                                 misc.secondary_inventory_name
                            /* Needs to be verified */
                            AND mlk.inventory_item_id =
                                              lv_mtl_txn_rec.inventory_item_id
                            AND mlk.subinventory_code =
                                              lv_mtl_txn_rec.subinventory_code
                            AND misc.locator_type <> 1);
            EXCEPTION
               WHEN OTHERS
               THEN
                  ln_err_cnt := ln_err_cnt + 1;
                  lv_message :=
                        'Source Locator '
                     || lv_mtl_txn_rec.locator_id
                     || ' Does not exists in Organization'
                     || lv_mtl_txn_rec.organization_id;
                  g_errors_tbl (ln_err_cnt).error_message := lv_message;
                  g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                       lv_mtl_txn_rec.transaction_interface_id;
                  bilc_inv_errors (g_errors_tbl);
                  display_message (lv_message);
            END;
         END IF;

         IF lv_mtl_txn_rec.transfer_locator IS NOT NULL
         THEN                              /* validating Destinationlocator */
            BEGIN
               SELECT 1
                 INTO v_chk
                 FROM DUAL
                WHERE EXISTS (
                         SELECT inventory_location_id
                           FROM mtl_item_locations_kfv mlk,
                                mtl_secondary_inventories misc
                          WHERE mlk.organization_id = misc.organization_id
                            AND mlk.subinventory_code =
                                                 misc.secondary_inventory_name
                            AND mlk.inventory_item_id =
                                              lv_mtl_txn_rec.inventory_item_id
                            AND mlk.subinventory_code =
                                          lv_mtl_txn_rec.transfer_subinventory
                            AND misc.locator_type <> 1);
            EXCEPTION
               WHEN OTHERS
               THEN
                  ln_err_cnt := ln_err_cnt + 1;
                  lv_message :=
                        'Destination Locator'
                     || lv_mtl_txn_rec.transfer_locator
                     || ' Does not exists in Organization'
                     || lv_mtl_txn_rec.organization_id;
                  g_errors_tbl (ln_err_cnt).error_message := lv_message;
                  g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                       lv_mtl_txn_rec.transaction_interface_id;
                  bilc_inv_errors (g_errors_tbl);
                  display_message (lv_message);
            END;
         END IF;
      ELSE
/* Validation for MIsc Receipt */
         lv_message :=
               'Transactioninterface_id :'
            || lv_mtl_txn_rec.transaction_interface_id
            || 'is for Misc Receipt';
         /* VAlidating Quantity */
         display_message (lv_message);

         IF lv_mtl_txn_rec.transaction_quantity < 0
         THEN
            ln_err_cnt := ln_err_cnt + 1;
            lv_message := 'Quantity is less than 0';
            g_errors_tbl (ln_err_cnt).error_message := lv_message;
            g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                      lv_mtl_txn_rec.transaction_interface_id;
            bilc_inv_errors (g_errors_tbl);
         END IF;

         /* Validating Transaction Type */
         BEGIN
            SELECT 1
              INTO v_chk
              FROM mtl_transaction_types
             WHERE transaction_type_id = lv_mtl_txn_rec.transaction_type_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               ln_err_cnt := ln_err_cnt + 1;
               lv_message :=
                     'Transaction Type'
                  || lv_mtl_txn_rec.transaction_type_id
                  || 'Does Not exists';
               g_errors_tbl (ln_err_cnt).error_message := lv_message;
               g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                       lv_mtl_txn_rec.transaction_interface_id;
               bilc_inv_errors (g_errors_tbl);
               display_message (lv_message);
         END;

         /* Validating  From Inventory Organization */
         BEGIN
            SELECT 1
              INTO v_chk
              FROM DUAL
             WHERE EXISTS (
                        SELECT organization_id
                          FROM mtl_parameters
                         WHERE organization_id =
                                                lv_mtl_txn_rec.organization_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               ln_err_cnt := ln_err_cnt + 1;
               lv_message :=
                     'The source Inventory Organization'
                  || lv_mtl_txn_rec.organization_id
                  || 'Does not exists';
               g_errors_tbl (ln_err_cnt).error_message := lv_message;
               g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                       lv_mtl_txn_rec.transaction_interface_id;
               bilc_inv_errors (g_errors_tbl);
               display_message (lv_message);
         END;

         /* Validating the Item for the Inventory Organization */
         BEGIN
            SELECT 1
              INTO v_chk
              FROM DUAL
             WHERE EXISTS (
                      SELECT inventory_item_id
                        FROM mtl_system_items_b
                       WHERE organization_id = lv_mtl_txn_rec.organization_id
                         AND inventory_item_id =
                                              lv_mtl_txn_rec.inventory_item_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               ln_err_cnt := ln_err_cnt + 1;
               lv_message :=
                     'The Item'
                  || lv_mtl_txn_rec.inventory_item_id
                  || 'Does not exists in the Source Organization '
                  || lv_mtl_txn_rec.organization_id;
               g_errors_tbl (ln_err_cnt).error_message := lv_message;
               g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                       lv_mtl_txn_rec.transaction_interface_id;
               bilc_inv_errors (g_errors_tbl);
               display_message (lv_message);
         END;

         BEGIN
            SELECT lot_control_code
              INTO v_lot_control_code
              FROM mtl_system_items_b
             WHERE organization_id = lv_mtl_txn_rec.organization_id
               AND inventory_item_id = lv_mtl_txn_rec.inventory_item_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               ln_err_cnt := ln_err_cnt + 1;
               lv_message :=
                     'The Item'
                  || lv_mtl_txn_rec.inventory_item_id
                  || 'Does not have any Lot Controlled code';
               g_errors_tbl (ln_err_cnt).error_message := lv_message;
               g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                       lv_mtl_txn_rec.transaction_interface_id;
               bilc_inv_errors (g_errors_tbl);
               display_message (lv_message);
         END;

         BEGIN            /* Validatimng the exixtance of From subinventory */
            SELECT 1
              INTO v_chk
              FROM DUAL
             WHERE EXISTS (
                      SELECT secondary_inventory_name
                        FROM mtl_secondary_inventories
                       WHERE organization_id = lv_mtl_txn_rec.organization_id
                         AND secondary_inventory_name =
                                              lv_mtl_txn_rec.subinventory_code);
         EXCEPTION
            WHEN OTHERS
            THEN
               ln_err_cnt := ln_err_cnt + 1;
               lv_message :=
                     'Source Subinventory'
                  || lv_mtl_txn_rec.subinventory_code
                  || ' Does not exists in Organization'
                  || lv_mtl_txn_rec.organization_id;
               g_errors_tbl (ln_err_cnt).error_message := lv_message;
               g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                       lv_mtl_txn_rec.transaction_interface_id;
               bilc_inv_errors (g_errors_tbl);
               display_message (lv_message);
         END;

/* Validating Locator Controlled */
         IF lv_mtl_txn_rec.locator_id IS NOT NULL
         THEN                                  /* validating source locator */
            BEGIN
               SELECT 1
                 INTO v_chk
                 FROM DUAL
                WHERE EXISTS (
                         SELECT inventory_location_id
                           FROM mtl_item_locations_kfv mlk,
                                mtl_secondary_inventories misc
                          WHERE mlk.organization_id = misc.organization_id
                            AND mlk.subinventory_code =
                                                 misc.secondary_inventory_name
                            AND mlk.inventory_item_id =
                                              lv_mtl_txn_rec.inventory_item_id
                            AND mlk.subinventory_code =
                                              lv_mtl_txn_rec.subinventory_code
                            AND misc.locator_type <> 1);
            EXCEPTION
               WHEN OTHERS
               THEN
                  ln_err_cnt := ln_err_cnt + 1;
                  lv_message :=
                        'Source Locator '
                     || lv_mtl_txn_rec.locator_id
                     || ' Does not exists in Organization'
                     || lv_mtl_txn_rec.organization_id;
                  g_errors_tbl (ln_err_cnt).error_message := lv_message;
                  g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                       lv_mtl_txn_rec.transaction_interface_id;
                  bilc_inv_errors (g_errors_tbl);
                  display_message (lv_message);
            END;
         END IF;

         IF lv_mtl_txn_rec.transfer_locator IS NOT NULL
         THEN                             /* validating Destination locator */
            BEGIN
               SELECT 1
                 INTO v_chk
                 FROM DUAL
                WHERE EXISTS (
                         SELECT inventory_location_id
                           FROM mtl_item_locations_kfv mlk,
                                mtl_secondary_inventories misc
                          WHERE mlk.organization_id = misc.organization_id
                            AND mlk.subinventory_code =
                                                 misc.secondary_inventory_name
                            AND mlk.inventory_item_id =
                                              lv_mtl_txn_rec.inventory_item_id
                            AND mlk.subinventory_code =
                                          lv_mtl_txn_rec.transfer_subinventory
                            AND misc.locator_type <> 1);
            EXCEPTION
               WHEN OTHERS
               THEN
                  ln_err_cnt := ln_err_cnt + 1;
                  lv_message :=
                        'Destination Locator '
                     || lv_mtl_txn_rec.transfer_locator
                     || ' Does not exists in Organization'
                     || lv_mtl_txn_rec.organization_id;
                  g_errors_tbl (ln_err_cnt).error_message := lv_message;
                  g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                       lv_mtl_txn_rec.transaction_interface_id;
                  bilc_inv_errors (g_errors_tbl);
                  display_message (lv_message);
            END;
         END IF;

         IF lv_mtl_txn_rec.distribution_account_id IS NOT NULL
         THEN
            BEGIN
               SELECT 1
                 INTO v_chk
                 FROM DUAL
                WHERE EXISTS (
                         SELECT code_combination_id
                           FROM gl_code_combinations
                          WHERE code_combination_id =
                                        lv_mtl_txn_rec.distribution_account_id);
            EXCEPTION
               WHEN OTHERS
               THEN
                  ln_err_cnt := ln_err_cnt + 1;
                  lv_message :=
                        'The Destination account ID '
                     || lv_mtl_txn_rec.distribution_account_id
                     || 'is invalid ';
                  g_errors_tbl (ln_err_cnt).error_message := lv_message;
                  g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                       lv_mtl_txn_rec.transaction_interface_id;
                  bilc_inv_errors (g_errors_tbl);
                  display_message (lv_message);
            END;
         END IF;
      END IF;                                         /*  Main if ends here */

      IF ln_err_cnt = 0
      THEN                               /* Now begining inserting */   --if 1
         BEGIN
            INSERT INTO mtl_transactions_interface
                        (source_header_id,
                         source_line_id, transaction_mode,
                         source_code, process_flag,
                         transaction_interface_id,
                         transaction_date,
                         inventory_item_id,
                         transaction_uom,
                         organization_id,
                         subinventory_code,
                         locator_id,
                         transfer_organization,
                         transfer_subinventory,
                         transfer_locator,
                         transaction_quantity,
                         transaction_type_id,
                         last_update_date,
                         last_updated_by,
                         creation_date,
                         created_by
                        )
                 VALUES (lv_mtl_txn_rec.source_header_id,
                         lv_mtl_txn_rec.source_line_id, 3,
                         lv_mtl_txn_rec.source_code, 1,
                         lv_mtl_txn_rec.transaction_interface_id,
                         lv_mtl_txn_rec.transaction_date,
                         lv_mtl_txn_rec.inventory_item_id,
                         lv_mtl_txn_rec.transaction_uom,
                         lv_mtl_txn_rec.organization_id,
                         lv_mtl_txn_rec.subinventory_code,
                         lv_mtl_txn_rec.locator_id,
                         lv_mtl_txn_rec.transfer_organization,
                         lv_mtl_txn_rec.transfer_subinventory,
                         lv_mtl_txn_rec.transfer_locator,
                         lv_mtl_txn_rec.transaction_quantity,
                         lv_mtl_txn_rec.transaction_type_id,
                         lv_mtl_txn_rec.last_update_date,
                         lv_mtl_txn_rec.last_updated_by,
                         lv_mtl_txn_rec.creation_date,
                         lv_mtl_txn_rec.created_by
                        );

            UPDATE bilc_mtl_txn_stg_tbl
               SET status = 'SUCESS'
             WHERE staging_id = lv_mtl_txn_rec.staging_id;

            COMMIT;
            display_message
               (   'Now inserting into mtl_transactions_interface for Transaction : '
                || lv_mtl_txn_rec.transaction_interface_id
               );
            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               ln_err_cnt := ln_err_cnt + 1;
               ROLLBACK;
               lv_message :=
                     'Error while inserting data into mtl_transactions_interface tables due to '
                  || SQLERRM;
               g_errors_tbl (ln_err_cnt).error_message := lv_message;
               g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                       lv_mtl_txn_rec.transaction_interface_id;
               bilc_inv_errors (g_errors_tbl);
               display_message (lv_message);

               UPDATE bilc_mtl_txn_stg_tbl
                  SET status = 'ERROR'
                WHERE staging_id = lv_mtl_txn_rec.staging_id;

               DELETE FROM mtl_transactions_interface
                     WHERE transaction_interface_id =
                                       lv_mtl_txn_rec.transaction_interface_id;

               COMMIT;
         END;

         IF ln_err_cnt = 0
         THEN                 /* Now inserting into Lots Interface */ ----if 2
            lv_message := 'Now inserting into lots interface ';
            display_message (ln_err_cnt || lv_message);

/* First checking wether the parent record have been created in mtl_itansactions_interface */
            BEGIN
               SELECT 1
                 INTO v_chk
                 FROM mtl_transactions_interface
                WHERE transaction_interface_id =
                                       lv_mtl_txn_rec.transaction_interface_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  ln_err_cnt := ln_err_cnt + 1;
                  lv_message :=
                        'The Parent Transaction  '
                     || lv_mtl_txn_rec.transaction_interface_id
                     || 'has not been created in the interface table ';
                  g_errors_tbl (ln_err_cnt).error_message := lv_message;
                  g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                       lv_mtl_txn_rec.transaction_interface_id;
                  bilc_inv_errors (g_errors_tbl);
                  display_message (lv_message);

                  UPDATE bilc_mtl_txn_stg_tbl
                     SET status = 'ERROR'
                   WHERE staging_id = lv_mtl_txn_rec.staging_id;

                  COMMIT;
            END;

            IF ln_err_cnt = 0
            THEN                                                      ----if 3
               FOR i IN 1 .. p_mtl_lots_txn_tbl.COUNT
               LOOP
                  /* Assining Lots Data */
                  lv_mtl_lots_txn_tbl (i).staging_id :=
                                            p_mtl_lots_txn_tbl (i).staging_id;
                  lv_mtl_lots_txn_tbl (i).last_update_date := SYSDATE;
                  lv_mtl_lots_txn_tbl (i).last_updated_by :=
                                                           fnd_global.user_id;
                  lv_mtl_lots_txn_tbl (i).creation_date := SYSDATE;
                  lv_mtl_lots_txn_tbl (i).created_by := fnd_global.user_id;
                  lv_mtl_lots_txn_tbl (i).transaction_quantity :=
                                  p_mtl_lots_txn_tbl (i).transaction_quantity;
                  lv_mtl_lots_txn_tbl (i).transaction_interface_id :=
                              p_mtl_lots_txn_tbl (i).transaction_interface_id;
                  lv_mtl_lots_txn_tbl (i).serial_transaction_temp_id :=
                            p_mtl_lots_txn_tbl (i).serial_transaction_temp_id;
                  lv_mtl_lots_txn_tbl (i).lot_number :=
                                            p_mtl_lots_txn_tbl (i).lot_number;

                  IF v_lot_control_code = 2
                  THEN                           /* Item is lot controlled */
           /* Lot Number should be provided */
                     IF p_mtl_lots_txn_tbl (i).lot_number IS NULL
                     THEN
                        ln_err_cnt := ln_err_cnt + 1;
                        lv_message :=
                           'Item is Lot Controlled but Lot Number is not provided';
                        g_errors_tbl (ln_err_cnt).error_message := lv_message;
                        g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                      lv_mtl_txn_rec.transaction_interface_id;
                        bilc_inv_errors (g_errors_tbl);
                        display_message (lv_message);
                     END IF;
                  ELSE
                     IF p_mtl_lots_txn_tbl (i).lot_number IS NOT NULL
                     THEN
                        ln_err_cnt := ln_err_cnt + 1;
                        lv_message :=
                           'Item is Not Lot Controlled but Lot Number is  provided';
                        g_errors_tbl (ln_err_cnt).error_message := lv_message;
                        g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                      lv_mtl_txn_rec.transaction_interface_id;
                        bilc_inv_errors (g_errors_tbl);
                        display_message (lv_message);
                     END IF;
                  END IF;

                  BEGIN
                     INSERT INTO mtl_transaction_lots_interface
                                 (lot_number,
                                  transaction_quantity,
                                  transaction_interface_id,
                                  serial_transaction_temp_id,
                                  last_update_date,
                                  last_updated_by,
                                  creation_date,
                                  created_by
                                 )
                          VALUES (lv_mtl_lots_txn_tbl (i).lot_number,
                                  lv_mtl_lots_txn_tbl (i).transaction_quantity,
                                  lv_mtl_lots_txn_tbl (i).transaction_interface_id,
                                  lv_mtl_lots_txn_tbl (i).serial_transaction_temp_id,
                                  lv_mtl_lots_txn_tbl (i).last_update_date,
                                  lv_mtl_lots_txn_tbl (i).last_updated_by,
                                  lv_mtl_lots_txn_tbl (i).creation_date,
                                  lv_mtl_lots_txn_tbl (i).created_by
                                 );

                     UPDATE bilc_mtl_txn_lots_stg_tbl
                        SET status = 'SUCESS'
                      WHERE staging_id = lv_mtl_lots_txn_tbl (i).staging_id;

                     COMMIT;
                     display_message
                        (   'Now inserting into mtl_transaction_lots_interface for Transaction : '
                         || lv_mtl_lots_txn_tbl (i).transaction_interface_id
                        );
                     COMMIT;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        ROLLBACK;
                        ln_err_cnt := ln_err_cnt + 1;
                        lv_message :=
                              'Error while insertinf data into MTL_TRANSACTION_LOTS_INTERFACE table Due to '
                           || SQLERRM;
                        g_errors_tbl (ln_err_cnt).error_message := lv_message;
                        g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                              lv_mtl_lots_txn_tbl (i).transaction_interface_id;
                        bilc_inv_errors (g_errors_tbl);
                        display_message (lv_message);

                        DELETE FROM mtl_transactions_interface
                              WHERE transaction_interface_id =
                                       lv_mtl_lots_txn_tbl (i).transaction_interface_id;

                        UPDATE bilc_mtl_txn_stg_tbl
                           SET status = 'ERROR'
                         WHERE staging_id = lv_mtl_txn_rec.staging_id;

                        UPDATE bilc_mtl_txn_lots_stg_tbl
                           SET status = 'ERROR'
                         WHERE staging_id = lv_mtl_lots_txn_tbl (i).staging_id;

                        COMMIT;
                  END;
               END LOOP;

               IF ln_err_cnt = 0
               THEN                                                     --if 4
                  FOR i IN 1 .. p_mtl_sln_txn_tbl.COUNT
                  LOOP
                     display_message
                        (   'Opened the table loop for Serial Txn for transaction Interface Id :'
                         || p_mtl_sln_txn_tbl (i).transaction_interface_id
                        );
                     lv_mtl_sln_txn_tbl (i).staging_id :=
                                              p_mtl_sln_txn_tbl (i).staging_id;
                     lv_mtl_sln_txn_tbl (i).transaction_interface_id :=
                                p_mtl_sln_txn_tbl (i).transaction_interface_id;
                     lv_mtl_sln_txn_tbl (i).last_update_date := SYSDATE;
                     lv_mtl_sln_txn_tbl (i).last_updated_by :=
                                                            fnd_global.user_id;
                     lv_mtl_sln_txn_tbl (i).creation_date := SYSDATE;
                     lv_mtl_sln_txn_tbl (i).created_by := fnd_global.user_id;

/* Check wether Parent record have been  created in the lots table */
                     /*BEGIN
                        SELECT 1
                          INTO v_chk
                          FROM mtl_transaction_lots_interface
                         WHERE serial_transaction_temp_id =
                                  lv_mtl_sln_txn_tbl (i).transaction_interface_id;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           ln_err_cnt := ln_err_cnt + 1;
                           lv_message :=
                                 'The LOT interface data has not been populated for   '
                              || lv_mtl_txn_rec.transaction_interface_id;
                           g_errors_tbl (ln_err_cnt).error_message :=
                                                                    lv_message;
                           g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                       lv_mtl_txn_rec.transaction_interface_id;
                           g_errors_tbl (ln_err_cnt).mtl_serial_txn_id :=
                               lv_mtl_sln_txn_tbl (i).transaction_interface_id;
                           bilc_inv_errors (g_errors_tbl);
                           display_message (lv_message);

                           UPDATE bilc_mtl_txn_stg_tbl
                              SET status = 'ERROR'
                            WHERE staging_id = lv_mtl_txn_rec.staging_id;

                           COMMIT;
                     END;*/
                     IF ln_err_cnt = 0
                     THEN                                              -- if 5
                        BEGIN
                           INSERT INTO mtl_serial_numbers_interface
                                       (transaction_interface_id,
                                        last_update_date,
                                        last_updated_by,
                                        creation_date,
                                        created_by
                                       )
                                VALUES (lv_mtl_sln_txn_tbl (i).transaction_interface_id,
                                        lv_mtl_sln_txn_tbl (i).last_update_date,
                                        lv_mtl_sln_txn_tbl (i).last_updated_by,
                                        lv_mtl_sln_txn_tbl (i).creation_date,
                                        lv_mtl_sln_txn_tbl (i).created_by
                                       );    /*  Values to be put here later*/

                           UPDATE bilc_mtl_sln_stg_tbl
                              SET status = 'SUCESS'
                            WHERE staging_id =
                                             lv_mtl_sln_txn_tbl (i).staging_id;

                           COMMIT;
                           display_message
                              (   'Now inserting into mtl_serial_numbers_interface for Transaction : '
                               || lv_mtl_sln_txn_tbl (i).transaction_interface_id
                              );
                           COMMIT;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              ln_err_cnt := ln_err_cnt + 1;
                              lv_message :=
                                    'The Serial interface data has not been populated for '
                                 || SQLERRM
                                 || p_mtl_sln_txn_tbl (i).transaction_interface_id;
                              g_errors_tbl (ln_err_cnt).error_message :=
                                                                    lv_message;
                              g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                       lv_mtl_txn_rec.transaction_interface_id;
                              g_errors_tbl (ln_err_cnt).mtl_lot_txn_id :=
                                 lv_mtl_sln_txn_tbl (i).transaction_interface_id;
                              g_errors_tbl (ln_err_cnt).mtl_serial_txn_id :=
                                 lv_mtl_sln_txn_tbl (i).transaction_interface_id;
                              bilc_inv_errors (g_errors_tbl);
                              display_message (lv_message);

                              UPDATE bilc_mtl_sln_stg_tbl
                                 SET status = 'ERROR'
                               WHERE staging_id =
                                              p_mtl_sln_txn_tbl (i).staging_id;

                              UPDATE bilc_mtl_txn_stg_tbl
                                 SET status = 'ERROR'
                               WHERE staging_id = lv_mtl_txn_rec.staging_id;

                              COMMIT;
                        END;
                     END IF;
                  --end if 5
                  END LOOP;
               END IF;                                             ---end if 4
            END IF;                                                --- end if3
         END IF;                                                           --2
      ELSE
         ln_err_cnt := ln_err_cnt + 1;
         lv_message :=
               'The validation failed for Transaction ID  :'
            || lv_mtl_txn_rec.transaction_interface_id;
         display_message (ln_err_cnt || lv_message);

         UPDATE bilc_mtl_txn_stg_tbl
            SET status = 'ERROR'
          WHERE transaction_interface_id =
                                       lv_mtl_txn_rec.transaction_interface_id;

         COMMIT;
      END IF;

      IF ln_err_cnt = 0
      THEN
         display_message
                       ('Sucessfully inserted data into the interface tables');
      ELSE
         display_message
            ('There was a problem in inserting data into the interface tables'
            );

         UPDATE bilc_mtl_txn_stg_tbl
            SET status = 'ERROR'
          WHERE transaction_interface_id =
                                       lv_mtl_txn_rec.transaction_interface_id;

         UPDATE bilc_mtl_txn_lots_stg_tbl
            SET status = 'ERROR'
          WHERE transaction_interface_id =
                                       lv_mtl_txn_rec.transaction_interface_id;

         COMMIT;
      END IF;
   ---1
   EXCEPTION
      WHEN OTHERS
      THEN
         lv_message := 'Error in the Procedure : BILC_TXN_PROCESS_PRC';
         g_errors_tbl (ln_err_cnt).error_message := lv_message;
         g_errors_tbl (ln_err_cnt).mtl_txn_id :=
                                      lv_mtl_txn_rec.transaction_interface_id;
         bilc_inv_errors (g_errors_tbl);
   END bilc_txn_process_prc;

   PROCEDURE bilc_inv_errors (inv_error_tbl g_errors_tbl_type)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      FOR i IN 1 .. inv_error_tbl.COUNT
      LOOP
         INSERT INTO bilc_inv_txn_errors_tbl
                     (error_id,
                      mtl_txn_id,
                      mtl_lot_txn_id,
                      mtl_serial_txn_id,
                      error_message, created_by,
                      creation_date, last_updated_by, last_update_date,
                      last_update_login, program_application_id,
                      program_id, request_id
                     )
              VALUES (bilc_inv_txn_errors_tbl_s.NEXTVAL,
                      inv_error_tbl (i).mtl_txn_id,
                      inv_error_tbl (i).mtl_lot_txn_id,
                      inv_error_tbl (i).mtl_serial_txn_id,
                      inv_error_tbl (i).error_message, fnd_global.user_id,
                      SYSDATE, fnd_global.user_id, SYSDATE,
                      fnd_global.login_id, fnd_global.prog_appl_id,
                      fnd_global.conc_program_id, fnd_global.conc_request_id
                     );
      END LOOP;

      COMMIT;
   END bilc_inv_errors;

   PROCEDURE display_message (p_message VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, p_message);
   END display_message;
END bilc_mtl_txn_interface_pkg;
/