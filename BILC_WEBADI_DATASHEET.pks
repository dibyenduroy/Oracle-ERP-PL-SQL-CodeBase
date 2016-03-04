CREATE OR REPLACE PACKAGE APPS.BILC_WEBADI_DATASHEET As
Procedure create_lov(p_interface_code           Varchar2
                     ,p_application_id          number default 800
                     ,p_interface_col           Varchar2
                     ,p_module_name             Varchar2 Default Null
                     ,p_val_id_col              Varchar2
                     ,p_val_mean_col            Varchar2
                     ,p_val_desc_col            Varchar2 Default Null
                     ,p_val_obj_name            Varchar2
                     ,p_val_addl_w_c            Varchar2
                     );
End BILC_WEBADI_DATASHEET;
/