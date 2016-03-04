CREATE OR REPLACE PACKAGE BODY bil_item_integration_pkg
AS
   PROCEDURE dummy_proc (
      p_item_id              NUMBER DEFAULT NULL,
      ERROR_CODE       OUT   VARCHAR2,
      error_message    OUT   VARCHAR2,
      error_severity   OUT   NUMBER,
      error_status     OUT   NUMBER
   )
   IS
   BEGIN
      error_status               := 0;
      error_severity             := 1;
      ERROR_CODE                 := NULL;
      error_message              := NULL;
   END dummy_proc;

   PROCEDURE bil_item_integration (
      p_item_id         NUMBER DEFAULT NULL,
      ref_data    OUT   sys_refcursor
   )
   IS
      ls_where                      VARCHAR2 (30000) := ' and 1 = 1 ';
      p_query                       VARCHAR2 (30000);
   BEGIN
      IF p_item_id IS NULL
      THEN
         ls_where                   := ls_where || ' ';
      ELSE
         ls_where                   :=
                     ls_where || ' and msi.inventory_item_id = ' || p_item_id;
      END IF;

      p_query                    :=
            'SELECT msi.inventory_item_id item_id, msi.organization_id organization_id, msi.concatenated_segments item_code, msi.description item_description, msi.primary_unit_of_measure issue_unit, msi.primary_unit_of_measure order_unit, msi.inventory_item_status_code item_status_flag, msi.inventory_item_flag inventory_item_flag, msi.stock_enabled_flag stockable_flag, DECODE (msi.lot_control_code, 2, '''
         || 'Y'
         || ''''
         || ', '''
         || 'N'
         || ''''
         || ') lot_control_flag, mc.concatenated_segments item_commodity, org.organization_name storeroom FROM mtl_system_items_kfv msi, mtl_item_categories mic, mtl_categories_kfv mc, mtl_category_sets mcs, mtl_default_category_sets_fk_v mdcs, org_organization_definitions org WHERE msi.inventory_item_id = mic.inventory_item_id AND msi.organization_id = mic.organization_id AND mic.category_id = mc.category_id AND mic.category_set_id = mcs.category_set_id AND mcs.category_set_id = mdcs.category_set_id AND mdcs.functional_area_desc = '''
         || 'Purchasing'
         || ''''
         || ' AND msi.organization_id = org.organization_id'
         || ls_where;

      OPEN ref_data FOR p_query;
   END bil_item_integration;
END bil_item_integration_pkg;
/

