CREATE OR REPLACE PACKAGE BODY APPS.bilc_insert_doccategory_pkg
------------------------------------------------------------------------------------
--    File Name    : bilc_insert_doccategory_pkg.pkb
--    Date         : 27-July-2009
--    Author       : Jaswant Singh Hooda
--    Description  :
--
--    Version      :1.0
--
--
--  Modification History :
--  Who              Date          Reason
-------------------------------------------------------------------------------------
IS
   PROCEDURE insert_doccategory (retcode    OUT      NUMBER,
                                 errbuf     OUT      VARCHAR2,
                                 p_org_id   IN       NUMBER,
                                 p_source   IN       VARCHAR2) IS
      CURSOR rec_cur IS
         SELECT *
           FROM ap_invoices_interface
          WHERE SOURCE = p_source--'ISP'
            AND doc_category_code IS NULL
            AND status IS NULL
            AND org_id = p_org_id;

      TYPE rec_cur_type IS TABLE OF rec_cur%ROWTYPE
         INDEX BY BINARY_INTEGER;

      rec_info              rec_cur_type;
      v_process_record      NUMBER;
      tot_rec               NUMBER := 0;
      exit_procedure        EXCEPTION;
      exit_row              EXCEPTION;
      l_debug_spot          VARCHAR2 (4000);
      v_document_category   VARCHAR2 (2000);
      v_error               VARCHAR2 (2000);
      p_user_id             fnd_user.user_id%TYPE := Fnd_Profile.value_wnps ('USER_ID');
      p_login_id            fnd_user.user_id%TYPE := Fnd_Profile.value_wnps ('LOGIN_ID');
      l_request_id          NUMBER;
      l_error               NUMBER                  := 0;
      l_attr_cat            VARCHAR2 (100);
      l_scm_head            VARCHAR2 (100);
      l_fin_head            VARCHAR2 (100);
      l_requester           VARCHAR2 (100);
      l_supervisor          VARCHAR2 (100);
      lv_error              VARCHAR2 (2000);
	  p_batch_name          VARCHAR2 (100);
   BEGIN
      Fnd_File.put_line(Fnd_File.LOG,'************Start of BILC_insert_doccategory************');
      --DBMS_OUTPUT.put_line('************Start of BILC_insert_doccategory************');
      BILC_Insert_Doccategory_Pkg.BILC_report_format;

      ------ formating report output
      IF (p_source = 'ISP') THEN
         p_batch_name := 'ISP ' || TO_CHAR (SYSDATE, 'DD-Mon-YYYY HH24:MI:SS');
      END IF;

      IF (p_source = 'Oracle Property Manager') THEN
         p_batch_name := 'PN-Rent Invoice ' || TO_CHAR (SYSDATE, 'DD-Mon-YYYY HH24:MI:SS');
      END IF;

      ----- to get document category for ORG_id;
      BEGIN
         v_document_category := get_doc_category (p_org_id, v_error);

         IF v_error IS NOT NULL THEN
            l_error := 1;
            l_debug_spot := v_error;
            RAISE exit_procedure;
         END IF;
      END;

      BEGIN
         OPEN rec_cur;

         FETCH rec_cur
         BULK COLLECT INTO rec_info;

         CLOSE rec_cur;

         IF rec_info.COUNT = 0 THEN
            Fnd_File.put_line (Fnd_File.LOG, ' No Record to process');
            Fnd_File.put_line (Fnd_File.output, ' No Record to process');
            l_debug_spot := 'No line to process';
            RAISE exit_procedure;
         ELSE
            v_process_record := rec_info.COUNT;
            Fnd_File.put_line (Fnd_File.LOG,'Got ' || rec_info.COUNT|| ' lines to process.');
            --DBMS_OUTPUT.put_line (   'Got '|| rec_info.COUNT || ' asset lines to process.');
         END IF;
      END;

      BEGIN
         FOR i IN rec_info.FIRST .. rec_info.LAST
         LOOP
            tot_rec := tot_rec + 1;

            UPDATE ap_invoices_interface
               SET doc_category_code = v_document_category,
                   attribute_category = l_attr_cat,
                   attribute6 =  l_scm_head,
                   attribute7 = l_requester,
                   attribute8 = l_supervisor,
                   attribute9 = l_fin_head
             WHERE invoice_id = rec_info (i).invoice_id;
         END LOOP;
      END;

      --DBMS_OUTPUT.put_line (   'Total number of Records :-           '|| rec_info.COUNT );
      --DBMS_OUTPUT.put_line ('Total number of Records Processed:-  ' || tot_rec);
      --DBMS_OUTPUT.put_line (   'Total number of Records Error Out:-  '|| (NVL (rec_info.COUNT, 0) - NVL (tot_rec, 0)));
      Fnd_File.put_line (Fnd_File.output, 'Batch Name :- ' || p_batch_name);
      Fnd_File.put_line (Fnd_File.output,'Total number of Records :- ' || rec_info.COUNT);
      Fnd_File.put_line (Fnd_File.output,'Total number of Records Processed:- ' || tot_rec);
      Fnd_File.put_line (Fnd_File.output,'Total number of Records Error Out:- '|| (NVL (rec_info.COUNT, 0) - NVL (tot_rec, 0)));
      
      COMMIT;

      BEGIN
         IF v_error IS NULL AND rec_info.COUNT > 0
         THEN
            l_request_id :=Fnd_Request.submit_request ('SQLAP',
                                           'APXIIMPT',
                                           NULL,
                                           NULL,
                                           FALSE,
                                           p_source,
                                           NULL,
                                           p_batch_name,
                                           'Courier Hold',		-- hold name
                                           'Courier Hold',		-- hold reason
                                           NULL,
                                           'N',
                                           'N',
                                           'N',
                                           'N',
                                           1000,
                                           p_user_id,
                                           p_login_id,
                                           Fnd_Global.local_chr (0),
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
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL
                                          );
         END IF;
      END;
   EXCEPTION
      WHEN exit_procedure THEN
         IF l_error = 1 THEN
            RAISE_APPLICATION_ERROR (-20001, v_error);
         ELSE
            Fnd_File.put_line (Fnd_File.LOG,'EXIT_PROCEDURE EXCEPTION: ' || l_debug_spot);
         END IF;
      WHEN OTHERS THEN
         Fnd_File.put_line (Fnd_File.LOG,'OTHERS EXCEPTION: at row  '|| l_debug_spot|| ' '|| SQLERRM);
   END insert_doccategory;

   FUNCTION get_doc_category (p_org_id IN NUMBER, p_error OUT VARCHAR2) RETURN VARCHAR2 IS
      v_doc_category   VARCHAR2 (240);
   BEGIN
      SELECT doc_category_code
        INTO v_doc_category
        FROM q_bil_pn_doc_cat_ou_mapping_v
       WHERE aop_circle_id = TO_CHAR(p_org_id);

      RETURN (v_doc_category);
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         p_error := 'No Operating Unit vs Sequence defined in your quality plan';
         RETURN (p_error);
      WHEN TOO_MANY_ROWS THEN
         p_error := 'Duplicate Sequence defined for this Operating Unit';
         RETURN (p_error);
      WHEN OTHERS THEN
         p_error := 'An error occured in OTHERS';
         RETURN (p_error || '-' || SQLERRM);
   END get_doc_category;

   PROCEDURE bilc_report_format IS
      v_request_id     NUMBER := Fnd_Global.conc_request_id;
      v_program_name   VARCHAR2 (200);
      v_requestor      VARCHAR2 (200);
   BEGIN
      BEGIN
         SELECT program, requestor
           INTO v_program_name, v_requestor
           FROM fnd_conc_req_summary_v
          WHERE request_id = v_request_id;
      EXCEPTION
         WHEN OTHERS THEN
            v_program_name := NULL;
      END;

      Fnd_File.put_line (apps.Fnd_File.output, ' ');
      Fnd_File.put_line (apps.Fnd_File.output, LPAD (v_program_name, 80));
      Fnd_File.put_line (apps.Fnd_File.output, ' ');
      Fnd_File.put_line (Fnd_File.output, 'Requestor    :- ' || v_requestor);
      Fnd_File.put_line (Fnd_File.output, 'Request Id   :- ' || v_request_id);
      Fnd_File.put_line (Fnd_File.output,'Start Time     :- '|| TO_CHAR (SYSDATE, 'DD-MON-YY HH:MI:SS AM'));
      Fnd_File.put_line (apps.Fnd_File.output, ' ');
      Fnd_File.put_line (apps.Fnd_File.output, ' ');
      Fnd_File.put_line (apps.Fnd_File.output, ' ');
      Fnd_File.put_line (apps.Fnd_File.output, ' ');
   END BILC_report_format;
END Bilc_Insert_Doccategory_Pkg;
/