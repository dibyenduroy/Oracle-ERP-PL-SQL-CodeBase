--DROP VIEW APPS.BILC_PN_CUST_SITE_ATTR_V;

/* Formatted on 2009/09/23 18:04 (Formatter Plus v4.8.8) */
--CREATE OR REPLACE FORCE VIEW apps.bilc_pn_cust_site_attr_v (location_id,
                                                            customer_id,
                                                            type_of_tower,
                                                            city,
                                                            state,
                                                            quantity_of_antennae_sector1,
                                                            quantity_of_antennae_sector2,
                                                            quantity_of_antennae_sector3,
                                                            quantity_of_antennae_sector4,
                                                            quantity_of_antennae_sector5,
                                                            quantity_of_antennae_sector6,
                                                            dia_of_mw_antennae1,
                                                            dia_of_mw_antennae2,
                                                            dia_of_mw_antennae3,
                                                            dia_of_mw_antennae4,
                                                            dia_of_mw_antennae5,
                                                            dia_of_mw_antennae6,
                                                            height_of_highest_antennae,
                                                            total_configuration_for_bts_1,
                                                            total_configuration_for_bts_2,
                                                            total_configuration_for_bts_3,
                                                            total_configuration_for_bts_4,
                                                            total_configuration_for_bts_5,
                                                            total_configuration_for_bts_6,
                                                            wind_speed,
                                                            power_load,
                                                            type_of_bts_1,
                                                            type_of_bts_2,
                                                            type_of_bts_3,
                                                            type_of_bts_4,
                                                            type_of_bts_5,
                                                            type_of_bts_6,
                                                            floor_space_for_bts_1,
                                                            floor_space_for_bts_2,
                                                            floor_space_for_bts_3,
                                                            floor_space_for_bts_4,
                                                            floor_space_for_bts_5,
                                                            floor_space_for_bts_6,
                                                            mw_antennae_ma,
                                                            height_of_antennae_ma,
                                                            windspeed_ma,
                                                            proposed_tenure,
                                                            opex_ratio,
                                                            operator_siteid,
                                                            bts_model1,
                                                            bts_type1,
                                                            bts_make1,
                                                            powerrequiremnet1,
                                                            bts_model2,
                                                            bts_make2,
                                                            powerrequiremnet2,
                                                            bts_model3,
                                                            bts_make3,
                                                            powerrequiremnet3,
                                                            bts_model4,
                                                            bts_make4,
                                                            powerrequiremnet4,
                                                            bts_model5,
                                                            bts_make5,
                                                            powerrequiremnet5,
                                                            bts_model6,
                                                            bts_make6,
                                                            powerrequiremnet6,
                                                            no_of_racks,
                                                            type_of_antennae1,
                                                            no_of_sectors1,
                                                            antennae_frequency_band1,
                                                            antennae_gain1,
                                                            type_of_antennae2,
                                                            no_of_sectors2,
                                                            antennae_frequency_band2,
                                                            antennae_gain2,
                                                            type_of_antennae3,
                                                            no_of_sectors3,
                                                            antennae_frequency_band3,
                                                            antennae_gain3,
                                                            type_of_antennae4,
                                                            no_of_sectors4,
                                                            antennae_frequency_band4,
                                                            antennae_gain4,
                                                            type_of_antennae5,
                                                            no_of_sectors5,
                                                            antennae_frequency_band5,
                                                            antennae_gain5,
                                                            type_of_antennae6,
                                                            no_of_sectors6,
                                                            antennae_frequency_band6,
                                                            antennae_gain6,
                                                            cabinate_no,
                                                            power_type,
                                                            mw_ant_no,
                                                            mw_ant_height1,
                                                            mw_ant_height2,
                                                            mw_ant_height3,
                                                            mw_ant_height4,
                                                            mw_ant_height5,
                                                            mw_ant_height6,
                                                            mntheightrwant1,
                                                            mntheightrwant2,
                                                            mntheightrwant3,
                                                            mntheightrwant4,
                                                            mntheightrwant5,
                                                            mntheightrwant6,
                                                            desired_rfi_date,
                                                            estimated_rent,
                                                            planned_rfi_date,
                                                            difficult_site,
                                                            fibre_connectivity,
                                                            latitude,
                                                            longitude,
                                                            sitetype,
                                                            battery_backup,
                                                            vlotage,
                                                            equipment_type_1,
                                                            equipment_type_2,
                                                            equipment_type_3,
                                                            equipment_type_4,
                                                            equipment_type_5,
                                                            equipment_type_6,
                                                            equipment_height_1,
                                                            equipment_height_2,
                                                            equipment_height_3,
                                                            equipment_height_4,
                                                            equipment_height_5,
                                                            equipment_height_6,
                                                            site_category
                                                           )
AS
   SELECT   bpsi.site_id location_id, bscp.customer_id,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_tower_type, bpsi.attribute_value,
                        NULL
                       )
               ) type_of_tower,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_city, bpsi.attribute_value,
                         NULL
                        )
                ) city,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_state, bpsi.attribute_value,
                         NULL
                        )
                ) state,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_quantity_of_gsm_cdma1, bpsi.attribute_value,
                        NULL
                       )
               ) quantity_of_antennae_sector1,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_quantity_of_gsm_cdma2, bpsi.attribute_value,
                        NULL
                       )
               ) quantity_of_antennae_sector2,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_quantity_of_gsm_cdma3, bpsi.attribute_value,
                        NULL
                       )
               ) quantity_of_antennae_sector3,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_quantity_of_gsm_cdma4, bpsi.attribute_value,
                        NULL
                       )
               ) quantity_of_antennae_sector4,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_quantity_of_gsm_cdma5, bpsi.attribute_value,
                        NULL
                       )
               ) quantity_of_antennae_sector5,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_quantity_of_gsm_cdma6, bpsi.attribute_value,
                        NULL
                       )
               ) quantity_of_antennae_sector6,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_mw_ant_dia1, bpsi.attribute_value,
                        NULL
                       )
               ) dia_of_mw_antennae1,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_mw_ant_dia2, bpsi.attribute_value,
                        NULL
                       )
               ) dia_of_mw_antennae2,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_mw_ant_dia3, bpsi.attribute_value,
                        NULL
                       )
               ) dia_of_mw_antennae3,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_mw_ant_dia4, bpsi.attribute_value,
                        NULL
                       )
               ) dia_of_mw_antennae4,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_mw_ant_dia5, bpsi.attribute_value,
                        NULL
                       )
               ) dia_of_mw_antennae5,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_mw_ant_dia6, bpsi.attribute_value,
                        NULL
                       )
               ) dia_of_mw_antennae6,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_height_ant, bpsi.attribute_value,
                        NULL
                       )
               ) height_of_highest_antennae,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_total_config1, bpsi.attribute_value,
                        NULL
                       )
               ) total_configuration_for_bts_1,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_total_config2, bpsi.attribute_value,
                        NULL
                       )
               ) total_configuration_for_bts_2,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_total_config3, bpsi.attribute_value,
                        NULL
                       )
               ) total_configuration_for_bts_3,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_total_config4, bpsi.attribute_value,
                        NULL
                       )
               ) total_configuration_for_bts_4,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_total_config5, bpsi.attribute_value,
                        NULL
                       )
               ) total_configuration_for_bts_5,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_total_config6, bpsi.attribute_value,
                        NULL
                       )
               ) total_configuration_for_bts_6,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_wind_speed, bpsi.attribute_value,
                         NULL
                        )
                ) wind_speed,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_power_load, bpsi.attribute_value,
                         NULL
                        )
                ) power_load,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_bts_type1, bpsi.attribute_value,
                         NULL
                        )
                ) type_of_bts_1,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_bts_type2, bpsi.attribute_value,
                         NULL
                        )
                ) type_of_bts_2,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_bts_type3, bpsi.attribute_value,
                         NULL
                        )
                ) type_of_bts_3,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_bts_type4, bpsi.attribute_value,
                         NULL
                        )
                ) type_of_bts_4,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_bts_type5, bpsi.attribute_value,
                         NULL
                        )
                ) type_of_bts_5,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_bts_type6, bpsi.attribute_value,
                         NULL
                        )
                ) type_of_bts_6,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_floorspace1, bpsi.attribute_value,
                        NULL
                       )
               ) floor_space_for_bts_1,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_floorspace2, bpsi.attribute_value,
                        NULL
                       )
               ) floor_space_for_bts_2,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_floorspace3, bpsi.attribute_value,
                        NULL
                       )
               ) floor_space_for_bts_3,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_floorspace4, bpsi.attribute_value,
                        NULL
                       )
               ) floor_space_for_bts_4,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_floorspace5, bpsi.attribute_value,
                        NULL
                       )
               ) floor_space_for_bts_5,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_floorspace6, bpsi.attribute_value,
                        NULL
                       )
               ) floor_space_for_bts_6,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_mw_ma, bpsi.attribute_value,
                         NULL
                        )
                ) mw_antennae_ma,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_height_ma, bpsi.attribute_value,
                        NULL
                       )
               ) height_of_antennae_ma,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_windspeed_ma, bpsi.attribute_value,
                        NULL
                       )
               ) windspeed_ma,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_tenure, bpsi.attribute_value,
                         NULL
                        )
                ) proposed_tenure,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_opex_ratio, bpsi.attribute_value,
                         NULL
                        )
                ) opex_ratio,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_operator_siteid, bpsi.attribute_value,
                        NULL
                       )
               ) operator_siteid,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_model_bts1, bpsi.attribute_value,
                         NULL
                        )
                ) bts_model1,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_bts_type1, bpsi.attribute_value,
                         NULL
                        )
                ) bts_type1,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_make_bts1, bpsi.attribute_value,
                         NULL
                        )
                ) bts_make1,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_power_req1, bpsi.attribute_value,
                        NULL
                       )
               ) powerrequiremnet1,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_model_bts2, bpsi.attribute_value,
                         NULL
                        )
                ) bts_model2,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_make_bts2, bpsi.attribute_value,
                         NULL
                        )
                ) bts_make2,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_power_req2, bpsi.attribute_value,
                        NULL
                       )
               ) powerrequiremnet2,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_model_bts3, bpsi.attribute_value,
                         NULL
                        )
                ) bts_model3,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_make_bts3, bpsi.attribute_value,
                         NULL
                        )
                ) bts_make3,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_power_req3, bpsi.attribute_value,
                        NULL
                       )
               ) powerrequiremnet3,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_model_bts4, bpsi.attribute_value,
                         NULL
                        )
                ) bts_model4,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_make_bts4, bpsi.attribute_value,
                         NULL
                        )
                ) bts_make4,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_power_req4, bpsi.attribute_value,
                        NULL
                       )
               ) powerrequiremnet4,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_model_bts5, bpsi.attribute_value,
                         NULL
                        )
                ) bts_model5,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_make_bts5, bpsi.attribute_value,
                         NULL
                        )
                ) bts_make5,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_power_req5, bpsi.attribute_value,
                        NULL
                       )
               ) powerrequiremnet5,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_model_bts6, bpsi.attribute_value,
                         NULL
                        )
                ) bts_model6,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_make_bts6, bpsi.attribute_value,
                         NULL
                        )
                ) bts_make6,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_power_req6, bpsi.attribute_value,
                        NULL
                       )
               ) powerrequiremnet6,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_no_of_racks, bpsi.attribute_value,
                         NULL
                        )
                ) no_of_racks,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_antennae_type1, bpsi.attribute_value,
                        NULL
                       )
               ) type_of_antennae1,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_no_of_sector1, bpsi.attribute_value,
                        NULL
                       )
               ) no_of_sectors1,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_antennae_fb1, bpsi.attribute_value,
                        NULL
                       )
               ) antennae_frequency_band1,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_antennae_gn1, bpsi.attribute_value,
                        NULL
                       )
               ) antennae_gain1,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_antennae_type2, bpsi.attribute_value,
                        NULL
                       )
               ) type_of_antennae2,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_no_of_sector2, bpsi.attribute_value,
                        NULL
                       )
               ) no_of_sectors2,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_antennae_fb2, bpsi.attribute_value,
                        NULL
                       )
               ) antennae_frequency_band2,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_antennae_gn2, bpsi.attribute_value,
                        NULL
                       )
               ) antennae_gain2,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_antennae_type3, bpsi.attribute_value,
                        NULL
                       )
               ) type_of_antennae3,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_no_of_sector3, bpsi.attribute_value,
                        NULL
                       )
               ) no_of_sectors3,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_antennae_fb3, bpsi.attribute_value,
                        NULL
                       )
               ) antennae_frequency_band3,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_antennae_gn3, bpsi.attribute_value,
                        NULL
                       )
               ) antennae_gain3,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_antennae_type4, bpsi.attribute_value,
                        NULL
                       )
               ) type_of_antennae4,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_no_of_sector4, bpsi.attribute_value,
                        NULL
                       )
               ) no_of_sectors4,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_antennae_fb4, bpsi.attribute_value,
                        NULL
                       )
               ) antennae_frequency_band4,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_antennae_gn4, bpsi.attribute_value,
                        NULL
                       )
               ) antennae_gain4,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_antennae_type5, bpsi.attribute_value,
                        NULL
                       )
               ) type_of_antennae5,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_no_of_sector5, bpsi.attribute_value,
                        NULL
                       )
               ) no_of_sectors5,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_antennae_fb5, bpsi.attribute_value,
                        NULL
                       )
               ) antennae_frequency_band5,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_antennae_gn5, bpsi.attribute_value,
                        NULL
                       )
               ) antennae_gain5,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_antennae_type6, bpsi.attribute_value,
                        NULL
                       )
               ) type_of_antennae6,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_no_of_sector6, bpsi.attribute_value,
                        NULL
                       )
               ) no_of_sectors6,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_antennae_fb6, bpsi.attribute_value,
                        NULL
                       )
               ) antennae_frequency_band6,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_antennae_gn6, bpsi.attribute_value,
                        NULL
                       )
               ) antennae_gain6,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_cabinate_no, bpsi.attribute_value,
                         NULL
                        )
                ) cabinate_no,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_power_type, bpsi.attribute_value,
                         NULL
                        )
                ) power_type,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_mw_ant_no, bpsi.attribute_value,
                         NULL
                        )
                ) mw_ant_no,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_height_mw1, bpsi.attribute_value,
                        NULL
                       )
               ) mw_ant_height1,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_height_mw2, bpsi.attribute_value,
                        NULL
                       )
               ) mw_ant_height2,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_height_mw3, bpsi.attribute_value,
                        NULL
                       )
               ) mw_ant_height3,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_height_mw4, bpsi.attribute_value,
                        NULL
                       )
               ) mw_ant_height4,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_height_mw5, bpsi.attribute_value,
                        NULL
                       )
               ) mw_ant_height5,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_height_mw6, bpsi.attribute_value,
                        NULL
                       )
               ) mw_ant_height6,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_mu_height1, bpsi.attribute_value,
                        NULL
                       )
               ) mntheightrwant1,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_mu_height2, bpsi.attribute_value,
                        NULL
                       )
               ) mntheightrwant2,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_mu_height3, bpsi.attribute_value,
                        NULL
                       )
               ) mntheightrwant3,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_mu_height4, bpsi.attribute_value,
                        NULL
                       )
               ) mntheightrwant4,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_mu_height5, bpsi.attribute_value,
                        NULL
                       )
               ) mntheightrwant5,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_mu_height6, bpsi.attribute_value,
                        NULL
                       )
               ) mntheightrwant6,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_desired_rfi_date, bpsi.attribute_value,
                        NULL
                       )
               ) desired_rfi_date,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_estimated_rent, bpsi.attribute_value,
                        NULL
                       )
               ) estimated_rent,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_planned_rfi_date, bpsi.attribute_value,
                        NULL
                       )
               ) planned_rfi_date,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_difficult_site, bpsi.attribute_value,
                        NULL
                       )
               ) difficult_site,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_fibre_connectivity, bpsi.attribute_value,
                        NULL
                       )
               ) fibre_connectivity,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_latitude, bpsi.attribute_value,
                         NULL
                        )
                ) p1lat,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_longitude, bpsi.attribute_value,
                         NULL
                        )
                ) p1long,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_sitetype, bpsi.attribute_value,
                         NULL
                        )
                ) sitetype,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_battery_backup, bpsi.attribute_value,
                        NULL
                       )
               ) battery_backup,
            MAX (DECODE (bpam.attribute_name,
                         bilc_pn_rent_var_pkg.get_gc_voltage, bpsi.attribute_value,
                         NULL
                        )
                ) vlotage,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_equipment_type1, bpsi.attribute_value,
                        NULL
                       )
               ) equipment_type_1,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_equipment_type2, bpsi.attribute_value,
                        NULL
                       )
               ) equipment_type_2,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_equipment_type3, bpsi.attribute_value,
                        NULL
                       )
               ) equipment_type_3,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_equipment_type4, bpsi.attribute_value,
                        NULL
                       )
               ) equipment_type_4,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_equipment_type5, bpsi.attribute_value,
                        NULL
                       )
               ) equipment_type_5,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_equipment_type6, bpsi.attribute_value,
                        NULL
                       )
               ) equipment_type_6,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_equipment_height1, bpsi.attribute_value,
                        NULL
                       )
               ) equipment_height_1,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_equipment_height2, bpsi.attribute_value,
                        NULL
                       )
               ) equipment_height_2,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_equipment_height3, bpsi.attribute_value,
                        NULL
                       )
               ) equipment_height_3,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_equipment_height4, bpsi.attribute_value,
                        NULL
                       )
               ) equipment_height_4,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_equipment_height5, bpsi.attribute_value,
                        NULL
                       )
               ) equipment_height_5,
            MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_equipment_height6, bpsi.attribute_value,
                        NULL
                       )
               ) equipment_height_6,
                MAX
               (DECODE (bpam.attribute_name,
                        bilc_pn_rent_var_pkg.get_gc_site_category, bpsi.attribute_value,
                        NULL
                       )
               ) gc_site_category
       FROM bilc_pn_site_info bpsi,
            bilc_pn_attribute_master bpam,
            bilc_pn_site_cust_map bscp
      WHERE bpsi.attribute_id = bpam.attribute_id
--and    bpsi.site_id=1900
        AND bpam.attribute_name IN
               (bilc_pn_rent_var_pkg.get_gc_city,
                bilc_pn_rent_var_pkg.get_gc_state,
                bilc_pn_rent_var_pkg.get_gc_tower_type,
                bilc_pn_rent_var_pkg.get_gc_bts_type1,
                bilc_pn_rent_var_pkg.get_gc_bts_type2,
                bilc_pn_rent_var_pkg.get_gc_bts_type3,
                bilc_pn_rent_var_pkg.get_gc_bts_type4,
                bilc_pn_rent_var_pkg.get_gc_bts_type5,
                bilc_pn_rent_var_pkg.get_gc_bts_type6,
                bilc_pn_rent_var_pkg.get_gc_floorspace1,
                bilc_pn_rent_var_pkg.get_gc_floorspace2,
                bilc_pn_rent_var_pkg.get_gc_floorspace3,
                bilc_pn_rent_var_pkg.get_gc_floorspace4,
                bilc_pn_rent_var_pkg.get_gc_floorspace5,
                bilc_pn_rent_var_pkg.get_gc_floorspace6,
                bilc_pn_rent_var_pkg.get_gc_mw_ma,
                bilc_pn_rent_var_pkg.get_gc_height_ma,
                bilc_pn_rent_var_pkg.get_gc_windspeed_ma,
                bilc_pn_rent_var_pkg.get_gc_tenure,
                bilc_pn_rent_var_pkg.get_gc_opex_ratio,
                bilc_pn_rent_var_pkg.get_gc_power_load,
                bilc_pn_rent_var_pkg.get_gc_windspeed,
                bilc_pn_rent_var_pkg.get_gc_total_config1,
                bilc_pn_rent_var_pkg.get_gc_total_config2,
                bilc_pn_rent_var_pkg.get_gc_total_config3,
                bilc_pn_rent_var_pkg.get_gc_total_config4,
                bilc_pn_rent_var_pkg.get_gc_total_config5,
                bilc_pn_rent_var_pkg.get_gc_total_config6,
                bilc_pn_rent_var_pkg.get_gc_height_ant,
                bilc_pn_rent_var_pkg.get_gc_mw_ant_dia1,
                bilc_pn_rent_var_pkg.get_gc_mw_ant_dia2,
                bilc_pn_rent_var_pkg.get_gc_mw_ant_dia3,
                bilc_pn_rent_var_pkg.get_gc_mw_ant_dia4,
                bilc_pn_rent_var_pkg.get_gc_mw_ant_dia5,
                bilc_pn_rent_var_pkg.get_gc_mw_ant_dia6,
                bilc_pn_rent_var_pkg.get_gc_quantity_of_gsm_cdma1,
                bilc_pn_rent_var_pkg.get_gc_quantity_of_gsm_cdma2,
                bilc_pn_rent_var_pkg.get_gc_quantity_of_gsm_cdma3,
                bilc_pn_rent_var_pkg.get_gc_quantity_of_gsm_cdma4,
                bilc_pn_rent_var_pkg.get_gc_quantity_of_gsm_cdma5,
                bilc_pn_rent_var_pkg.get_gc_quantity_of_gsm_cdma6,
                bilc_pn_rent_var_pkg.get_gc_operator_siteid,
                bilc_pn_rent_var_pkg.get_gc_model_bts1,
                bilc_pn_rent_var_pkg.get_gc_bts_type1,
                bilc_pn_rent_var_pkg.get_gc_make_bts1,
                bilc_pn_rent_var_pkg.get_gc_power_req1,
                bilc_pn_rent_var_pkg.get_gc_model_bts2,
                bilc_pn_rent_var_pkg.get_gc_power_req2,
                bilc_pn_rent_var_pkg.get_gc_model_bts3,
                bilc_pn_rent_var_pkg.get_gc_make_bts2,
                bilc_pn_rent_var_pkg.get_gc_make_bts3,
                bilc_pn_rent_var_pkg.get_gc_power_req3,
                bilc_pn_rent_var_pkg.get_gc_model_bts4,
                bilc_pn_rent_var_pkg.get_gc_make_bts4,
                bilc_pn_rent_var_pkg.get_gc_power_req4,
                bilc_pn_rent_var_pkg.get_gc_model_bts5,
                bilc_pn_rent_var_pkg.get_gc_make_bts5,
                bilc_pn_rent_var_pkg.get_gc_power_req5,
                bilc_pn_rent_var_pkg.get_gc_model_bts6,
                bilc_pn_rent_var_pkg.get_gc_make_bts6,
                bilc_pn_rent_var_pkg.get_gc_power_req6,
                bilc_pn_rent_var_pkg.get_gc_no_of_racks,
                bilc_pn_rent_var_pkg.get_gc_antennae_type1,
                bilc_pn_rent_var_pkg.get_gc_no_of_sector1,
                bilc_pn_rent_var_pkg.get_gc_antennae_fb1,
                bilc_pn_rent_var_pkg.get_gc_antennae_gn1,
                bilc_pn_rent_var_pkg.get_gc_antennae_type2,
                bilc_pn_rent_var_pkg.get_gc_no_of_sector2,
                bilc_pn_rent_var_pkg.get_gc_antennae_fb2,
                bilc_pn_rent_var_pkg.get_gc_antennae_gn2,
                bilc_pn_rent_var_pkg.get_gc_antennae_type3,
                bilc_pn_rent_var_pkg.get_gc_no_of_sector3,
                bilc_pn_rent_var_pkg.get_gc_antennae_fb3,
                bilc_pn_rent_var_pkg.get_gc_antennae_gn3,
                bilc_pn_rent_var_pkg.get_gc_antennae_type4,
                bilc_pn_rent_var_pkg.get_gc_no_of_sector4,
                bilc_pn_rent_var_pkg.get_gc_antennae_fb4,
                bilc_pn_rent_var_pkg.get_gc_antennae_gn4,
                bilc_pn_rent_var_pkg.get_gc_antennae_type5,
                bilc_pn_rent_var_pkg.get_gc_no_of_sector5,
                bilc_pn_rent_var_pkg.get_gc_antennae_fb5,
                bilc_pn_rent_var_pkg.get_gc_antennae_gn5,
                bilc_pn_rent_var_pkg.get_gc_antennae_type6,
                bilc_pn_rent_var_pkg.get_gc_no_of_sector6,
                bilc_pn_rent_var_pkg.get_gc_antennae_fb6,
                bilc_pn_rent_var_pkg.get_gc_antennae_gn6,
                bilc_pn_rent_var_pkg.get_gc_cabinate_no,
                bilc_pn_rent_var_pkg.get_gc_power_type,
                bilc_pn_rent_var_pkg.get_gc_mw_ant_no,
                bilc_pn_rent_var_pkg.get_gc_height_mw1,
                bilc_pn_rent_var_pkg.get_gc_height_mw2,
                bilc_pn_rent_var_pkg.get_gc_height_mw3,
                bilc_pn_rent_var_pkg.get_gc_height_mw4,
                bilc_pn_rent_var_pkg.get_gc_height_mw5,
                bilc_pn_rent_var_pkg.get_gc_height_mw6,
                bilc_pn_rent_var_pkg.get_gc_mu_height1,
                bilc_pn_rent_var_pkg.get_gc_mu_height2,
                bilc_pn_rent_var_pkg.get_gc_mu_height3,
                bilc_pn_rent_var_pkg.get_gc_mu_height4,
                bilc_pn_rent_var_pkg.get_gc_mu_height5,
                bilc_pn_rent_var_pkg.get_gc_mu_height6,
                bilc_pn_rent_var_pkg.get_gc_desired_rfi_date,
                bilc_pn_rent_var_pkg.get_gc_estimated_rent,
                bilc_pn_rent_var_pkg.get_gc_planned_rfi_date,
                bilc_pn_rent_var_pkg.get_gc_difficult_site,
                bilc_pn_rent_var_pkg.get_gc_fibre_connectivity,
                bilc_pn_rent_var_pkg.get_gc_latitude,
                bilc_pn_rent_var_pkg.get_gc_longitude,
                bilc_pn_rent_var_pkg.get_gc_sitetype,
                bilc_pn_rent_var_pkg.get_gc_battery_backup,
                bilc_pn_rent_var_pkg.get_gc_voltage,
                bilc_pn_rent_var_pkg.get_gc_equipment_type1,
                bilc_pn_rent_var_pkg.get_gc_equipment_type2,
                bilc_pn_rent_var_pkg.get_gc_equipment_type3,
                bilc_pn_rent_var_pkg.get_gc_equipment_type4,
                bilc_pn_rent_var_pkg.get_gc_equipment_type5,
                bilc_pn_rent_var_pkg.get_gc_equipment_type6,
                bilc_pn_rent_var_pkg.get_gc_equipment_height1,
                bilc_pn_rent_var_pkg.get_gc_equipment_height2,
                bilc_pn_rent_var_pkg.get_gc_equipment_height3,
                bilc_pn_rent_var_pkg.get_gc_equipment_height4,
                bilc_pn_rent_var_pkg.get_gc_equipment_height5,
                bilc_pn_rent_var_pkg.get_gc_equipment_height6,
                bilc_pn_rent_var_pkg.get_gc_site_category
               )
        AND bscp.cust_site_trx_id(+) = bpsi.cust_site_trx_id
   GROUP BY bpsi.site_id, bscp.customer_id;



