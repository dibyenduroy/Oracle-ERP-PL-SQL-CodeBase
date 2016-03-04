CREATE OR REPLACE PACKAGE BILC_MTL_TXN_INTERFACE_PKG

AS
--
--
--
-- **************************************************************************************
-- *                                                                                    *
-- * PL/SQL Package     :       BILC_MTL_TXN_INTERFACE_PKG                              *
-- * Date               :       27-July-2009                                            *
-- * Purpose            :  Package is used for Populating Subinventory Transfer/Misc    *
---*                       Receipt Transactions                                         *
-- *                                                                                    *
-- *------------------------------------------------------------------------------------*
-- * Modifications      :                                                               *
-- *                                                                                    *
-- * Version     DD-MON-YYYY     Person        Changes Made                             *
-- * ----------  -------------  ------------  ----------------------------------------- *
-- * DRAFT1A     27-July-2009   Dibyendu     Initial Draft Version                 *
-- *                                                                                    *
-- **************************************************************************************


g_mtl_txn_rec   bilc_mtl_txn_stg_tbl%ROWTYPE ;

TYPE g_mtl_lots_txn_tbl_type is table of bilc_mtl_txn_lots_stg_tbl%ROWTYPE INDEX BY BINARY_INTEGER;
g_mtl_lots_txn_tbl  g_mtl_lots_txn_tbl_type;
g_mtl_lots_txn_tbl_dummy  g_mtl_lots_txn_tbl_type;

TYPE g_mtl_sln_txn_tbl_type is table of bilc_mtl_sln_stg_tbl%ROWTYPE INDEX BY BINARY_INTEGER;
g_mtl_sln_txn_tbl g_mtl_sln_txn_tbl_type;

g_mtl_sln_txn_tbl_dummy g_mtl_sln_txn_tbl_type;

TYPE g_errors_tbl_type is TABLE OF bilc_inv_txn_errors_tbl%ROWTYPE INDEX BY BINARY_INTEGER;
g_errors_tbl g_errors_tbl_type;

g_errors_tbl_dummy g_errors_tbl_type;


PROCEDURE BILC_CALL_MAIN;

PROCEDURE BILC_TXN_STG_PRC(errbuf OUT VARCHAR2,retcode OUT NUMBER);

PROCEDURE BILC_TXN_PROCESS_PRC(p_mtl_txn_rec   IN bilc_mtl_txn_stg_tbl%ROWTYPE,p_mtl_lots_txn_tbl IN g_mtl_lots_txn_tbl_type,p_mtl_sln_txn_tbl IN g_mtl_sln_txn_tbl_type);

PROCEDURE display_message (p_message VARCHAR2);

PROCEDURE bilc_inv_errors (inv_error_tbl g_errors_tbl_type);

END BILC_MTL_TXN_INTERFACE_PKG;
/

