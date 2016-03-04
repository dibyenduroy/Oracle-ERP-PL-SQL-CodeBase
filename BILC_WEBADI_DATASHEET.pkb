CREATE OR REPLACE PACKAGE BODY APPS.BILC_WEBADI_DATASHEET As
PROCEDURE create_lov(p_interface_code Varchar2
                     ,p_application_id          number default 800
                     ,p_interface_col           Varchar2
                     ,p_module_name             Varchar2 Default Null
                     ,p_val_id_col              Varchar2
                     ,p_val_mean_col            Varchar2
                     ,p_val_desc_col            Varchar2 Default Null
                     ,p_val_obj_name            Varchar2
                     ,p_val_addl_w_c            Varchar2
                     ) Is

l_cmpt_param_list_key      Varchar2(200);
l_param_list_code          Varchar2(200);
l_cmpt_param_list_seq_num  Number(10);
--p_application_id           Number(10) := 800;
l_interface_col            Varchar2(120);
l_inter_seq_num            Number;
l_cmpt_param_defn_key      varchar2(100);

Cursor csr_interface_col Is
Select sequence_num
  From bne_interface_cols_b
 Where interface_code like p_interface_code
   and interface_col_name = p_interface_col;

Begin


 Open csr_interface_col;
 Fetch csr_interface_col Into l_inter_seq_num;

 If csr_interface_col%Found Then

   If p_module_name Is Not Null Then
     l_param_list_code := p_module_name||'_'|| to_char(l_inter_seq_num)||'_LOV';
   Else
     l_param_list_code := substr(p_interface_code,1,17)||to_char(l_inter_seq_num)||'_LOV';

   End If;

 Update bne_interface_cols_b
    Set val_obj_name = p_val_obj_name,
        val_id_col = p_val_id_col,
        val_addl_w_c = p_val_addl_w_c,
        val_mean_col = p_val_mean_col,
        val_desc_col = p_val_desc_col,
        val_type= 'TABLE',
        val_component_app_id = p_application_id,
        val_component_code = l_param_list_code
    Where  interface_code = p_interface_code
      And    sequence_num = l_inter_seq_num;



    Update BNE_INTERFACE_COLS_TL
    Set user_hint = 'LOV'
    Where  interface_code = p_interface_code
    And    sequence_num = l_inter_seq_num;

    l_cmpt_param_list_key := bne_parameter_utils.create_param_list_all
         (p_application_id      => p_application_id
         ,p_param_list_code     => l_param_list_code
         ,p_persistent          => 'Y'
         ,p_comments            => 'LOV: '||P_INTERFACE_COL
         ,p_attribute_app_id    => NULL
         ,p_attribute_code      => NULL
         ,p_list_resolver       => NULL
         ,p_prompt_left         => NULL
         ,p_prompt_above        => NULL
         ,p_user_name           => 'LOV: '||P_INTERFACE_COL
         ,p_user_tip            => NULL);

    l_cmpt_param_list_seq_num :=
        bne_parameter_utils.create_list_items_all
         (p_application_id      => p_application_id
         ,p_param_list_code     => l_param_list_code
         ,p_param_defn_app_id   => 231
         ,p_param_defn_code     => 'TABLE_COLUMN_ALIAS'
         ,p_param_name          => 'table-column-alias'
         ,p_attribute_app_id    => NULL
         ,p_attribute_code      => NULL
         ,p_string_val          => P_INTERFACE_COL
         ,p_number_val          => NULL
         ,p_date_val            => NULL
         ,p_boolean_val         => NULL
         ,p_formula             => NULL
         ,p_desc_val            => P_INTERFACE_COL);


    l_cmpt_param_list_seq_num :=
        bne_parameter_utils.create_list_items_all
         (p_application_id      => p_application_id
         ,p_param_list_code     => l_param_list_code
         ,p_param_defn_app_id   => 231
         ,p_param_defn_code     => 'TABLE_BLOCK_SIZE'
         ,p_param_name          => 'table-block-size'
         ,p_attribute_app_id    => NULL
         ,p_attribute_code      => NULL
         ,p_string_val          => NULL
         ,p_number_val          => NULL
         ,p_date_val            => NULL
         ,p_boolean_val         => NULL
         ,p_formula             => NULL
         ,p_desc_val            => NULL);

    l_cmpt_param_list_seq_num :=
        bne_parameter_utils.create_list_items_all
         (p_application_id      => p_application_id
         ,p_param_list_code     => l_param_list_code
         ,p_param_defn_app_id   => 231
         ,p_param_defn_code     => 'WINDOW_HEIGHT'
         ,p_param_name          => 'window-height'
         ,p_attribute_app_id    => NULL
         ,p_attribute_code      => NULL
         ,p_string_val          => NULL
         ,p_number_val          => NULL
         ,p_date_val            => NULL
         ,p_boolean_val         => NULL
         ,p_formula             => NULL
         ,p_desc_val            => NULL);


    l_cmpt_param_list_seq_num :=
        bne_parameter_utils.create_list_items_all
         (p_application_id      => p_application_id
         ,p_param_list_code     => l_param_list_code
         ,p_param_defn_app_id   => 231
         ,p_param_defn_code     => 'WINDOW_WIDTH'
         ,p_param_name          => 'window-width'
         ,p_attribute_app_id    => NULL
         ,p_attribute_code      => NULL
         ,p_string_val          => NULL
         ,p_number_val          => NULL
         ,p_date_val            => NULL
         ,p_boolean_val         => NULL
         ,p_formula             => NULL
         ,p_desc_val            => NULL);

    l_cmpt_param_list_seq_num :=
        bne_parameter_utils.create_list_items_all
         (p_application_id      => p_application_id
         ,p_param_list_code     => l_param_list_code
         ,p_param_defn_app_id   => 231
         ,p_param_defn_code     => 'WINDOW_START_POS'
         ,p_param_name          => 'window-start-position'
         ,p_attribute_app_id    => NULL
         ,p_attribute_code      => NULL
         ,p_string_val          => NULL
         ,p_number_val          => NULL
         ,p_date_val            => NULL
         ,p_boolean_val         => NULL
         ,p_formula             => NULL
         ,p_desc_val            => NULL);


    l_cmpt_param_list_seq_num :=
        bne_parameter_utils.create_list_items_all
         (p_application_id      => p_application_id
         ,p_param_list_code     => l_param_list_code
         ,p_param_defn_app_id   => 231
         ,p_param_defn_code     => 'TABLE_SELECT_COLUMN'
         ,p_param_name          => 'table-select-column'
         ,p_attribute_app_id    => NULL
         ,p_attribute_code      => NULL
         ,p_string_val          => P_INTERFACE_COL
         ,p_number_val          => NULL
         ,p_date_val            => NULL
         ,p_boolean_val         => NULL
         ,p_formula             => NULL
         ,p_desc_val            => P_INTERFACE_COL);


    l_cmpt_param_list_seq_num :=
        bne_parameter_utils.create_list_items_all
         (p_application_id      => p_application_id
         ,p_param_list_code     => l_param_list_code
         ,p_param_defn_app_id   => 231
         ,p_param_defn_code     => 'TABLE_COLUMNS'
         ,p_param_name          => 'table-columns'
         ,p_attribute_app_id    => NULL
         ,p_attribute_code      => NULL
         ,p_string_val          => p_val_mean_col||','||p_val_id_col
         ,p_number_val          => NULL
         ,p_date_val            => NULL
         ,p_boolean_val         => NULL
         ,p_formula             => NULL
         ,p_desc_val            => p_val_mean_col||','||p_val_id_col );


    l_cmpt_param_list_seq_num :=
        bne_parameter_utils.create_list_items_all
         (p_application_id      => p_application_id
         ,p_param_list_code     => l_param_list_code
         ,p_param_defn_app_id   => 800
         ,p_param_defn_code     => 'PER_RI_TABLE_HEADERS'
         ,p_param_name          => 'table-headers'
         ,p_attribute_app_id    => NULL
         ,p_attribute_code      => NULL
         ,p_string_val          => NULL
         ,p_number_val          => NULL
         ,p_date_val            => NULL
         ,p_boolean_val         => NULL
         ,p_formula             => NULL
         ,p_desc_val            => NULL);

    l_cmpt_param_list_seq_num :=
        bne_parameter_utils.create_list_items_all
         (p_application_id      => 800
         ,p_param_list_code     => l_param_list_code
         ,p_param_defn_app_id   => 800
         ,p_param_defn_code     => 'PER_RI_WINDOW_CAPTION'
         ,p_param_name          => 'window-caption'
         ,p_attribute_app_id    => NULL
         ,p_attribute_code      => NULL
         ,p_string_val          => NULL
         ,p_number_val          => NULL
         ,p_date_val            => NULL
         ,p_boolean_val         => NULL
         ,p_formula             => NULL
         ,p_desc_val            => NULL);


    INSERT INTO bne_components_b
       (application_id, component_code, component_java_class,
        param_list_app_id, param_list_code, object_version_number,
        created_by, creation_date, last_updated_by, last_update_login, last_update_date)
     Select p_application_id, l_param_list_code, 'BneOAValueSet',
           p_application_id, l_param_list_code, 1,
           2, SYSDATE, 2, 2, SYSDATE
       From Dual
       Where not exists (Select 1 From bne_components_b t Where  t.component_code = l_param_list_code);


    INSERT INTO bne_components_tl
       (application_id, component_code, language, source_lang, user_name,
        created_by, creation_date, last_updated_by, last_update_login, last_update_date)
    Select p_application_id, l_param_list_code, 'US', 'US',
           l_param_list_code || ' Component',
           2, SYSDATE, 2, 2, SYSDATE
       From Dual
       Where not exists (Select 1 From bne_components_tl t Where  t.component_code = l_param_list_code);


  Else
    raise_application_error(-20002, 'Invalid Interface Column');
  End If;

End create_lov;
End BILC_WEBADI_DATASHEET;
/