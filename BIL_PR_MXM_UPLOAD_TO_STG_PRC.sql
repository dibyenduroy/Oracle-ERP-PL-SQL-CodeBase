CREATE OR REPLACE PROCEDURE BIL_PR_MXM_UPLOAD_TO_STG_PRC(p_source bil_pr_stg.source%type DEFAULT 'Expense',
                                     p_req_type bil_pr_stg.req_type%type DEFAULT 'Purchase Requisition',
									 p_currency  bil_pr_stg.currency%type DEFAULT 'INR',
                                     p_pr_num in bil_pr_stg.pr_num%type,
									p_pr_desc in bil_pr_stg.pr_desc%type,
									p_preparer in bil_pr_stg.preparer%type,
									p_status in bil_pr_stg.status%type DEFAULT 'NEW',
									p_maximo_work_order in bil_pr_stg.maximo_work_order%type,
									p_maximo_pr_number in bil_pr_stg.maximo_pr_number%type,
									p_operating_unit in bil_pr_stg.operating_unit%type ,
									p_creation_date in bil_pr_stg.creation_date%type,
									p_line_num in bil_pr_stg.line_num%type,
									p_line_type in bil_pr_stg.line_type%type,
									p_pr_line_desc in bil_pr_stg.pr_line_desc%type,
									p_item in bil_pr_stg.item%type,
									p_item_category in bil_pr_stg.item_category%type,
									p_uom in bil_pr_stg.uom%type,
									p_quantity in bil_pr_stg.quantity%type,
									p_price in bil_pr_stg.price%type,
									p_need_by_date in bil_pr_stg.need_by_date%type,
									p_destination in bil_pr_stg.destination%type,
									p_requester in bil_pr_stg.requester%type,
									p_organization_code in bil_pr_stg.organization_code%type,
									p_location in bil_pr_stg.location%type,
									p_vendor_name in bil_pr_stg.vendor_name%type,
									p_contact in bil_pr_stg.contact%type,
									p_charge_account in bil_pr_stg.charge_account_d%type,
									p_accrual_account in bil_pr_stg.accrual_account_d%type,
									p_variance_account in bil_pr_stg.variance_account%type,
									p_CODE_COMBINATION_ID in bil_pr_stg.variance_account%type,
									p_organization_id in  bil_pr_stg.organization_id%type)
IS


p_ou_flag varchar2(10);
p_item_flag varchar2(10);
p_uom_flag  varchar2(10);
p_requestor_flag varchar2(10);
p_requestor_id number;
p_organization_flag varchar2(10);
v_preparer_id number;
v_vendor_id number;
v_vendor_site_id number;
v_vendor_site_code varchar2(200);
v_requester_id number;

BEGIN


select person_id into v_preparer_id from per_people_f where full_name=p_preparer and effective_end_date>sysdate;

select vendor_id into v_vendor_id from po_vendors where vendor_name= p_vendor_name;

select vendor_site_id,vendor_site_code into v_vendor_site_id,v_vendor_site_code from po_vendor_sites_all where vendor_id=v_vendor_id and org_id=p_organization_id;

select person_id into v_requester_id from per_people_f where full_name=p_requester and effective_end_date>sysdate;


/* Formatted on 2009/06/11 14:58 (Formatter Plus v4.8.7) */
INSERT INTO bil_pr_stg
             (staging_id, pr_num, pr_desc, req_type,
              preparer, preparer_id, status, maximo_work_order,
              maximo_pr_number, operating_unit, creation_date,
              line_num, line_type, pr_line_desc, item,
              item_category, uom, quantity, price, need_by_date,
              currency, destination, requester, requester_id,
              organization_code, organization_id, LOCATION, SOURCE,
              vendor_name, vendor_id, vendor_site_id,
              vendor_site_code, contact, process_flag, charge_account_d,
              accrual_account_d, variance_account, code_combination_id,
              last_update_date, last_updated_by)
     VALUES (bil_pr_stg_seq.NEXTVAL, p_pr_num, p_pr_desc, p_req_type,
             p_preparer, v_preparer_id, p_status, p_maximo_work_order,
             p_maximo_pr_number, p_operating_unit, p_creation_date,
             p_line_num, p_line_type, p_pr_line_desc, p_item,
             p_item_category, p_uom, p_quantity, p_price, p_need_by_date,
             p_currency, p_destination, p_requester,v_requester_id,
             p_organization_code, p_organization_id, p_location, p_source,
             p_vendor_name, v_vendor_id, v_vendor_site_id,
             v_vendor_site_code, p_contact, 'N', p_charge_account,
             p_accrual_account, p_variance_account, p_code_combination_id,
             SYSDATE, 'MXM');

COMMIT ;



-- fnd_file.put_line (FND_FILE.LOG,'One Row inserted for PR Num: '||p_pr_num);
-- 
-- /* Begin Validating the Header Record */
-- 
-- fnd_file.put_line (FND_FILE.LOG,'Validating the header Record');
-- 
-- select 'Y' into p_ou_flag 
-- from hr_operating_units where
-- organization_id=p_operating_unit;
-- 
-- if p_ou_flag ='Y' then
-- fnd_file.put_line (FND_FILE.LOG,'OU'||p_operating_unit||' for PR Num :'||p_pr_num||'is valid');
-- 
-- else
-- 
-- update bil_pr_stg set process_flag='E'
-- where pr_num=p_pr_num and operating_unit=p_operating_unit;
-- commit;
-- end if;
-- 
-- fnd_file.put_line (FND_FILE.LOG,' Finished Validating the header Record');
-- /* End of validating the header record */ 
-- 
-- 
-- /* Begin Validating the Line Record */
-- 
-- fnd_file.put_line (FND_FILE.LOG,'Validating the line Record');
-- 
-- select 'Y' into p_item_flag from dual where exists (select 1 from mtl_system_items_b where inventory_item_id=p_item and organization_id=p_organization);
-- 
-- if p_item_flag='Y' then
-- 
-- fnd_file.put_line (FND_FILE.LOG,'The item for PR no: '||p_pr_num||'and line num '||p_line_num||'is valid');
-- 
-- else
-- 
-- update bil_pr_stg set process_flag='E'
-- where pr_num=p_pr_num and line_num=p_line_num and organization=p_organization;
-- commit;
-- 
-- end if;
-- 
-- select 'Y' into p_uom_flag from dual where exists ( select 1 from mtl_system_items_b where inventory_item_id=p_item and organization_id=p_organization and primary_unit_of_measure=p_uom);
-- 
-- if p_uom_flag='Y' then
-- fnd_file.put_line (FND_FILE.LOG,'The item for PR no: '||p_pr_num||'and line num '||p_line_num||'has a valid UOM');
-- else
-- update bil_pr_stg set process_flag='E'
-- where pr_num=p_pr_num and line_num=p_line_num and organization=p_organization and uom=p_uom;
-- commit;
-- fnd_file.put_line (FND_FILE.LOG,'The item for PR no: '||p_pr_num||'and line num '||p_line_num||'has a invalid UOM');
-- end if;
-- 
-- select 'Y' into  p_requestor_flag from dual where exists ( select 1 from per_people_f where full_name=p_requester);
-- 
-- if p_requestor_flag='Y' then
-- fnd_file.put_line (FND_FILE.LOG,'The Requestor'||p_requester||' for PR no: '||p_pr_num||'and line num '||p_line_num||'exists');
-- select person_id into p_requestor_id from per_people_f where full_name=p_requester;
-- 
-- update bil_pr_stg set requester_id=p_requestor_id
-- where pr_num=p_pr_num and requester=p_requester;
-- commit;
-- else
-- 
-- update bil_pr_stg set process_flag='E'
-- where pr_num=p_pr_num and line_num=p_line_num and organization=p_organization and requester=p_requester;
-- commit;
-- 
-- end if;
-- 
-- select 'Y' into p_organization_flag
-- from dual
-- where exists( select 1 from org_organization_definitions where organization_id=p_organization);
-- 
-- if p_organization_flag='Y' then
-- fnd_file.put_line (FND_FILE.LOG,'The Organization for PR no: '||p_pr_num||'and line num '||p_line_num||'exists');
-- else
-- 
-- update bil_pr_stg set process_flag='E'
-- where pr_num=p_pr_num and line_num=p_line_num and organization=p_organization; 
-- 
-- commit;
-- 
-- end if;
-- 
-- /* End Validating Line Record */
-- 
exception when others then
fnd_file.put_line (FND_FILE.LOG,'Program Errored out due to '||sqlerrm);

end BIL_PR_MXM_UPLOAD_TO_STG_PRC;