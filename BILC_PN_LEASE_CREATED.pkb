CREATE OR REPLACE PACKAGE BODY APPS.bilc_pn_lease_created IS

 PROCEDURE bilc_pn_lease_created_notify(errbuf        OUT VARCHAR2,
                                        retcode       OUT NUMBER,
                                        p_lease_id    IN  NUMBER,
                                        p_role        IN  VARCHAR2) IS
    CURSOR cur_user IS
        SELECT fnu.user_name user_name
          FROM per_assignment_extra_info paei,
               per_all_assignments_f paaf,
               per_all_people_f papf,
               fnd_user fnu
         WHERE paei.information_type = 'INFRA_ROLE'
           AND paei.assignment_id = paaf.assignment_id
           AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                   AND paaf.effective_end_date
           AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                   AND papf.effective_end_date
           AND papf.person_id = paaf.person_id
           AND fnu.employee_id = paaf.person_id
           AND paaf.primary_flag = 'Y'
           AND paei.aei_information1 = p_role;
   
   l_itemkey        NUMBER;
   l_msg            VARCHAR2(2000);
   l_lease_num      VARCHAR2(30);
   l_lease_name     VARCHAR2(50);
 BEGIN
 
    BEGIN
       SELECT pl.lease_num, pl.name
         INTO l_lease_num, l_lease_name
         FROM pn_leases_all pl
        WHERE 1 = 1
          AND pl.lease_id = p_lease_id;
    
    END;
    fnd_file.put_line (fnd_file.LOG,'Before Sending Notification');
    FOR rec_user IN cur_user
    LOOP
    BEGIN
       SELECT bil_task_assgn_seq.NEXTVAL
         INTO l_itemkey
         FROM DUAL;
   
       fnd_file.put_line (fnd_file.LOG,'Sending Notification to ' || rec_user.user_name);
       fnd_file.put_line (fnd_file.LOG,'Item Key='||to_char(l_itemkey));
       
       wf_engine.createprocess (itemtype      => 'BTWFNOTF',
                                  itemkey       => l_itemkey,
                                  process       => 'BTVL_NOTIFY_PROCESS');
         
          wf_engine.setitemattrtext ('BTWFNOTF',
                                    l_itemkey,
                                    'USER_NAME',
                                    rec_user.user_name);

          wf_engine.setitemattrtext ('BTWFNOTF',
                                    l_itemkey,
                                    'SUBJECT',
                                    'Lease ' || l_lease_num || ' is Created');

          wf_engine.setitemattrtext('BTWFNOTF',
                                   l_itemkey,
                                   'MESSAGE',
                                   'The lease has been created with the following details:'
                                   || CHR (10)
                                   || CHR (10)
                                   || 'Lease Number    : '
                                   || l_lease_num
                                   || CHR (10)
                                   || 'Lease Name        : '
                                   || l_lease_name
                                   || CHR (10)
                                   ||'Please review and finalize the lease.');

           wf_engine.startprocess ('BTWFNOTF', l_itemkey);

    EXCEPTION WHEN OTHERS THEN
       fnd_file.put_line (fnd_file.LOG,'Notification Error to-- ' || rec_user.user_name);
       fnd_file.put_line (fnd_file.LOG,'ERROR : Notification ' || SQLERRM);
    END;
    END LOOP;
 END bilc_pn_lease_created_notify;
END bilc_pn_lease_created;
/