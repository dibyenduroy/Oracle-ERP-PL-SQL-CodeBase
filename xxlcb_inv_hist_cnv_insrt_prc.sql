create procedure XXLCB_INV_HIST_CNV_INSRT_PRC

is

declare

cursor inv_hist_cur
is
select * from xxlcb.xxlcb_inv_hist_stg
where << status flag = 'P'>> 

type xx_tbl is table of xxlcb.xxlcb_inv_hist_stg%rowtype;

xx_t xx_tbl;

begin

open inv_hist_cur

fetch inv_hist_cur bulk collect into xx_t limit 1000


if xx_t.count :=0 then

dbms_output.put_line('There are no records in the Staging table');

end if;


forall i in 1..xx_t.count loop

<<insert into the respective base tables INV_IL_CUR_DM and INV_ITEM_LD_DM >>
end loop


if mod(xx_t.count,1000)==0 then
commit
end if;


exception when others then
<< Do something>>

end;

