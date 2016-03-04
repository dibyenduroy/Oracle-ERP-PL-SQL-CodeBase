/* Formatted on 2009/09/24 15:03 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE BODY apps.bilc_pn_prop_intg_pkg
AS
--
--
--
-- **************************************************************************************
-- *                                                                                    *
-- * PL/SQL Package     :       BILC_PN_PROP_INTG_PKG                                    *
-- * Date               :       17-JULY-2009                                            *
-- * Purpose            :       Package is used for PN Integration                      *
-- *                                                                                    *
-- *------------------------------------------------------------------------------------*
-- * Modifications      :                                                               *
-- *                                                                                    *
-- * Version     DD-MON-YYYY     Person        Changes Made                             *
-- * ----------  -------------  ------------  ----------------------------------------- *
-- * DRAFT1A     17-july-2009     Sumit Gupta     Initial Draft Version                  *
-- *                                                                                    *
-- **************************************************************************************
--
   PROCEDURE dummy_proc (
      p_location_code            IN       VARCHAR2 DEFAULT NULL,
      p_cust_id                           NUMBER DEFAULT NULL,
      p_lat                               NUMBER DEFAULT NULL,
      p_long                              NUMBER DEFAULT NULL,
      p_radius                            NUMBER DEFAULT NULL,
      p_city                              VARCHAR2 DEFAULT NULL,
      p_state                             VARCHAR2 DEFAULT NULL,
      p_site_id                           VARCHAR2 DEFAULT NULL,
      p_tower_type                        VARCHAR2 DEFAULT NULL,
      ERROR_CODE                 OUT      VARCHAR2,
      error_message              OUT      VARCHAR2,
      error_severity             OUT      NUMBER,
      error_status               OUT      NUMBER,
      ERROR_CODE                 OUT      VARCHAR2,
      error_message              OUT      VARCHAR2,
      error_severity             OUT      NUMBER,
      error_status               OUT      NUMBER
   )
----
-- +====================================================================================+
-- |                                                                                    |
-- | Name               :       DUMMY_PROC                                              |
-- | Description        :       Procedure required for Adaptor                          |
-- |                                                                                    |
-- | Parameters         :                                                               |
-- |                                                                                    |
-- |    P_LOCATION_ID          LOCATION_ID                                              |
-- |    P_CUST_ID              CUSTOMER_ID                                                 |
-- |                                                                                    |
-- |                                                                                    |
-- | Returns            :                                                               |
-- |    error_code                                                                        |
-- |    error_message                                                                    |
-- |    error_severity
-- |    error_status                                                                    |
-- +====================================================================================+
--
   IS
   BEGIN
      error_status := 0;
      error_severity := 1;
      ERROR_CODE := NULL;
      error_message := NULL;
   END dummy_proc;

   PROCEDURE bilc_pn_prop_intg_prc (
      p_location_code            IN       VARCHAR2 DEFAULT NULL,
      p_cust_id                           NUMBER DEFAULT NULL,
      p_lat                               NUMBER DEFAULT NULL,
      p_long                              NUMBER DEFAULT NULL,
      p_radius                            NUMBER DEFAULT NULL,
      p_city                              VARCHAR2 DEFAULT NULL,
      p_state                             VARCHAR2 DEFAULT NULL,
      p_site_id                           VARCHAR2 DEFAULT NULL,
      p_tower_type                        VARCHAR2 DEFAULT NULL,
      ref_data1                  OUT      sys_refcursor,
      ref_data2                  OUT      sys_refcursor,
      ref_data3                  OUT      sys_refcursor
   )
--
-- +====================================================================================+
-- |                                                                                    |
-- | Name               :       BILC_PN_PROP_INTG_PRC                                   |
-- | Description        :       Main procedure for creating the ref cursor data         |
-- |                                                                                    |
-- | Parameters         :                                                               |
-- |                                                                                    |
-- |    P_LOCATION_ID          LOCATION_ID                                              |
-- |    P_CUST_ID              CUSTOMER_ID                                              |
-- |                                                                                    |
-- | Returns            :                                                               |
-- |                                                                                    |
-- +====================================================================================+
--
   IS
      ls_where                      VARCHAR2 (30000) := ' AND 1 = 1 ';
      ls_where1                     VARCHAR2 (30000) := ' AND 1 = 1 ';
      ls_where2                     VARCHAR2 (30000) := ' AND 1 = 1 ';
      ls_where3                     VARCHAR2 (30000) := ' AND 1 = 1 ';
      ls_where4                     VARCHAR2 (30000) := ' AND 1 = 1 ';
      p_query1                      VARCHAR2 (30000);
      p_query2                      VARCHAR2 (30000);
      p_query3                      VARCHAR2 (30000);
      lc_location                   NUMBER;
   BEGIN
      IF p_location_code IS NOT NULL
      THEN
         BEGIN
            SELECT location_id
              INTO lc_location
              FROM pn_locations_all
             WHERE location_code = p_location_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_location := -1;
         END;

         ls_where := ls_where || ' AND LOC.LOCATION_ID = ' || lc_location;
      END IF;

      IF p_city IS NOT NULL
      THEN
         ls_where1 := ls_where1 || ' AND a.CITY = ' || '''' || p_city || '''';
      END IF;

      IF p_state IS NOT NULL
      THEN
         ls_where2 :=
                    ls_where2 || ' AND a.STATE = ' || '''' || p_state || '''';
      END IF;

      IF p_site_id IS NOT NULL
      THEN
         ls_where3 := ls_where3 || ' AND a.LOCATION_ID = ' || p_site_id;
      END IF;

      IF p_tower_type IS NOT NULL
      THEN
         ls_where4 :=
               ls_where4
            || ' AND a.type_of_tower = '
            || ''''
            || p_tower_type
            || '''';
      END IF;

      IF p_location_code IS NULL
      THEN
         ls_where :=
               ls_where
            || ' AND LOC.LOCATION_ID  in  (select location_id from BILC_PN_CUST_SITE_ATTR_V a where 1=1 '
            || ls_where1
            || ls_where2
            || ls_where3
            || ls_where4
            || ')';
      END IF;

      IF p_lat IS NOT NULL AND p_long IS NOT NULL AND p_radius IS NOT NULL
      THEN
         ls_where :=
               ls_where
            || ' and bilc_pn_distance_pkg.bilc_pn_distance(a.p1lat,a.p1long, '
            || p_lat
            || ' ,'
            || p_long
            || ') <= '
            || p_radius;
      END IF;

      p_query1 :=
            'SELECT OU.NAME OPERATING_UNIT,FNDC.MEANING TOWER_TYPE,LOC.LOCATION_CODE LOCATION_CODE,LOC.LOCATION_ALIAS ALIAS,PROP.PROPERTY_NAME PROPERTY,LOOT.MEANING PN_LEASED_OR_OWNED,LOC.BUILDING NAME,LOC.ACTIVE_START_DATE "FROM",LOC.ACTIVE_END_DATE "TO",'
         || 'ADDR.ADDRESS_LINE1'
         || '||'',''||'
         || 'ADDR.ADDRESS_LINE2'
         || '||'',''||'
         || 'ADDR.ADDRESS_LINE3'
         || '||'',''||'
         || 'ADDR.ADDRESS_LINE4 ADDRESS,ADDR.COUNTY TALUKA,ADDR.CITY CITY,ADDR.PROVINCE DISTRICT,ADDR.STATE STATE,ADDR.ZIP_CODE POSTAL_CODE,TERR.TERRITORY_SHORT_NAME COUNTRY,LOC.LOCATION_ID LOCATION_ID FROM PN_LOCATIONS_ALL LOC,PN_ADDRESSES_ALL ADDR,FND_TERRITORIES_TL TERR,FND_LOOKUPS FNDC,FND_LOOKUPS LOOT,PN_PROPERTIES_ALL PROP,HR_OPERATING_UNITS OU WHERE LOC.ADDRESS_ID = ADDR.ADDRESS_ID AND ADDR.COUNTRY = TERR.TERRITORY_CODE AND FNDC.LOOKUP_TYPE (+) = ''PN_CLASS_TYPE'' AND FNDC.LOOKUP_CODE = LOC.CLASS AND LOOT.LOOKUP_CODE (+) = LOC.LEASE_OR_OWNED AND LOOT.LOOKUP_TYPE (+) = ''PN_LEASED_OR_OWNED'' AND LOC.PROPERTY_ID = PROP.PROPERTY_ID(+) AND LOC.ORG_ID = OU.ORGANIZATION_ID'
         || 'loc.attribute9 DISTRICT'
         || 'loc.attribute8 TOWN'
         || 'loc.attribute3 CLUSTER'
         || 'loc.attribute2 ZONE'
         || 'loc.attribute15 TENANT_ID'
         || ls_where
         || 'ORDER BY LOC.LOCATION_ID';
      DBMS_OUTPUT.put_line (p_query1);

      OPEN ref_data1 FOR p_query1;

       --P_QUERY2                         :='SELECT PNAM.ATTRIBUTE_NAME ATTRIBUTE_NAME,PNSI.ATTRIBUTE_VALUE ATTRIBUTE_VALUE,LOC.LOCATION_ID LOCATION_ID FROM BIL_PN_SITE_INFO PNSI,BIL_PN_ATTRIBUTE_MASTER PNAM,PN_LOCATIONS_ALL LOC WHERE PNAM.ATTRIBUTE_ID = PNSI.ATTRIBUTE_ID AND SYSDATE BETWEEN PNSI.START_DATE and NVL(PNSI.END_DATE,SYSDATE) AND SYSDATE BETWEEN PNAM.START_DATE and NVL(PNAM.END_DATE,SYSDATE) AND PNSI.CUST_SITE_TRX_ID IS NULL AND PNSI.SITE_ID = LOC.LOCATION_ID'
      -- ||LS_WHERE
       --||'ORDER BY LOCATION_ID,ATTRIBUTE_NAME';
      p_query2 :=
            'SELECT  Type_of_Tower,City,State,latitude,longitude,site_category  from BILC_PN_CUST_SITE_ATTR_V LOC where 1=1 and LOC.CUSTOMER_ID IS NULL '
         || ls_where;
      DBMS_OUTPUT.put_line (p_query2);

      OPEN ref_data2 FOR p_query2;

      IF p_cust_id IS NOT NULL
      THEN
         ls_where := ls_where || 'AND LOC.CUSTOMER_ID = ' || p_cust_id;
      END IF;

      --  P_QUERY3                    :='SELECT PNAM.ATTRIBUTE_NAME ATTRIBUTE_NAME,PNSI.ATTRIBUTE_VALUE ATTRIBUTE_VALUE,LOC.LOCATION_ID LOCATION_ID FROM BIL_PN_SITE_INFO PNSI,BIL_PN_ATTRIBUTE_MASTER PNAM,BIL_PN_SITE_CUST_MAP PNSCM,PN_LOCATIONS_ALL LOC WHERE PNAM.ATTRIBUTE_ID = PNSI.ATTRIBUTE_ID AND SYSDATE BETWEEN PNAM.START_DATE and NVL(PNAM.END_DATE,SYSDATE) AND SYSDATE BETWEEN NVL(PNSI.START_DATE,SYSDATE) and NVL(PNSI.END_DATE,SYSDATE) AND PNSI.CUST_SITE_TRX_ID = PNSCM.CUST_SITE_TRX_ID AND PNSI.SITE_ID = PNSCM.SITE_ID AND SYSDATE BETWEEN PNSCM.START_DATE and NVL(PNSCM.END_DATE,SYSDATE) AND PNSI.SITE_ID = LOC.LOCATION_ID'
       -- ||LS_WHERE
        --||'ORDER BY LOCATION_ID,ATTRIBUTE_NAME';
      p_query3 :=
            ' select location_id site_id,'
         || 'cus.customer_id,'
         || 'cus.customer_name'
         || ' type_of_tower,'
         || 'city,'
         || 'state,'
         || 'quantity_of_antennae_sector1,'
         || 'quantity_of_antennae_sector2,'
         || 'quantity_of_antennae_sector3,'
         || 'quantity_of_antennae_sector4,'
         || 'quantity_of_antennae_sector5,'
         || 'quantity_of_antennae_sector6,'
         || 'dia_of_mw_antennae1,'
         || 'dia_of_mw_antennae2,'
         || 'dia_of_mw_antennae3,'
         || 'dia_of_mw_antennae4,'
         || 'dia_of_mw_antennae5,'
         || 'dia_of_mw_antennae6,'
         || 'height_of_highest_antennae,'
         || 'total_configuration_for_bts_1,'
         || 'total_configuration_for_bts_2,'
         || 'total_configuration_for_bts_3,'
         || 'total_configuration_for_bts_4,'
         || 'total_configuration_for_bts_5,'
         || 'total_configuration_for_bts_6,'
         || 'wind_speed,'
         || 'power_load,'
         || 'type_of_bts_1,'
         || 'type_of_bts_2,'
         || 'type_of_bts_3,'
         || 'type_of_bts_4,'
         || 'type_of_bts_5,'
         || 'type_of_bts_6,'
         || 'floor_space_for_bts_1,'
         || 'floor_space_for_bts_2,'
         || 'floor_space_for_bts_3,'
         || 'floor_space_for_bts_4,'
         || 'floor_space_for_bts_5,'
         || 'floor_space_for_bts_6,'
         || 'mw_antennae_ma,'
         || 'height_of_antennae_ma,'
         || 'windspeed_ma,'
         || 'proposed_tenure,'
         || 'opex_ratio,'
         || 'operator_siteid,'
         || 'bts_model1,'
         || 'bts_type1,'
         || 'bts_make1,'
         || 'powerrequiremnet1,'
         || 'bts_model2,'
         || 'bts_make2,'
         || 'powerrequiremnet2,'
         || 'bts_model3,'
         || 'bts_make3,'
         || 'powerrequiremnet3,'
         || 'bts_model4,'
         || 'bts_make4,'
         || 'powerrequiremnet4,'
         || 'bts_model5,'
         || 'bts_make5,'
         || 'powerrequiremnet5,'
         || 'bts_model6,'
         || 'bts_make6,'
         || 'powerrequiremnet6,'
         || 'no_of_racks,'
         || 'type_of_antennae1,'
         || 'no_of_sectors1,'
         || 'antennae_frequency_band1,'
         || 'antennae_gain1,'
         || 'type_of_antennae2,'
         || 'no_of_sectors2,'
         || 'antennae_frequency_band2,'
         || 'antennae_gain2,'
         || 'type_of_antennae3,'
         || 'no_of_sectors3,'
         || 'antennae_frequency_band3,'
         || 'antennae_gain3,'
         || 'type_of_antennae4,'
         || 'no_of_sectors4,'
         || 'antennae_frequency_band4,'
         || 'antennae_gain4,'
         || 'type_of_antennae5,'
         || 'no_of_sectors5,'
         || 'antennae_frequency_band5,'
         || 'antennae_gain5,'
         || 'type_of_antennae6,'
         || 'no_of_sectors6,'
         || 'antennae_frequency_band6,'
         || 'antennae_gain6,'
         || 'cabinate_no,'
         || 'power_type,'
         || 'mw_ant_no,'
         || 'mw_ant_height1,'
         || 'mw_ant_height2,'
         || 'mw_ant_height3,'
         || 'mw_ant_height4,'
         || 'mw_ant_height5,'
         || 'mw_ant_height6,'
         || 'mntheightrwant1,'
         || 'mntheightrwant2,'
         || 'mntheightrwant3,'
         || 'mntheightrwant4,'
         || 'mntheightrwant5,'
         || 'mntheightrwant6,'
         || 'desired_rfi_date,'
         || 'estimated_rent,'
         || 'planned_rfi_date,'
         || 'difficult_site,'
         || 'fibre_connectivity,'
         || 'sitetype,'
         || 'battery_backup,'
         || 'vlotage,'
         || 'equipment_type_1,'
         || 'equipment_type_2,'
         || 'equipment_type_3,'
         || 'equipment_type_4,'
         || 'equipment_type_5,'
         || 'equipment_type_6,'
         || 'equipment_height_1,'
         || 'equipment_height_2,'
         || 'equipment_height_3,'
         || 'equipment_height_4,'
         || 'equipment_height_5,'
         || 'equipment_height_6      from BILC_PN_CUST_SITE_ATTR_V LOC,RA_CUSTOMERS cus where 1=1 and loc.customer_id=cus.customer_id '
         || ls_where;
      DBMS_OUTPUT.put_line (p_query3);

      OPEN ref_data3 FOR p_query3;
   END bilc_pn_prop_intg_prc;
END bilc_pn_prop_intg_pkg;
/