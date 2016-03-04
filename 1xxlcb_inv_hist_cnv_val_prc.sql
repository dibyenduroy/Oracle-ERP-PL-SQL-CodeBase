

create procedure XXLCB_INV_HIST_CNV_VAL_PRC

is

declare
<<variables to be declared as when required>>

cursor inv_hist_cur
is
select * from xxlcb.xxlcb_inv_hist_stg


begin

for i in inv_hist_cur loop

<< do the validations on the data >>

<< if validation fails set update status of the stg table accordingly accordingly>>



if mod(v_count,10000)=0 then
commit;
end if;




end loop; 


end;