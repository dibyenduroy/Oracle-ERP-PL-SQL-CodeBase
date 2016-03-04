CREATE OR REPLACE PACKAGE APPS.bilc_pn_lease_updated IS

   PROCEDURE bilc_pn_lease_update_notify(errbuf         OUT  VARCHAR2,
                                          retcode        OUT  NUMBER,
                                          p_lease_id     IN   NUMBER,
                                          p_role         IN   VARCHAR2);

END bilc_pn_lease_updated;
/