CREATE OR REPLACE PACKAGE APPS.INFRA_CM_STATEMENT_LOAD_PKG
/*******************************************************************************************************************
* Package Name : INFRA_CM_STATEMENT_LOAD_PACKAGE                                                	      	           *
* Purpose      : This package contains procedue body for inserting data in Interface tables		           		   *
*                                                 . Execution of this scrip creates PL/SQL procedure in database   *
*                         							                                                 			   *
*                                                                                                                  *
*                                                                                                                  *
*                                                                                                                  *
* Procedures   :     statement_upload_proc                      			          		           			   *
* -----------------              			           					           								   *
*                                                                 					           		           	   *
*                                                                                     						       *
* enter_details                                                                       					           *
*                                                                                    						       *
*                                                                                     						       *
*                                                                                     						       *
* Change History                                                                      					           *
*                                                                                     						       *
* Version  Date                     Author                  Description                        				       *
* ------   -----------               -----------------              ---------------------------        			   *
* 1.0      12-Dec-2008                 Original Code                      				           *
*										           	 		  													   *
*******************************************************************************************************************/
AS
    PROCEDURE INFRA_STATEMENT_UPLOAD_PROC (
      p_line_number        IN       NUMBER,
	  p_statement_number   IN       VARCHAR2,
      p_bank_account_num   IN       VARCHAR2,
      p_trx_date           IN       DATE,
      p_amount             IN       NUMBER,
      p_bank_trx_number    IN       VARCHAR2,
	  p_line_desc          IN       VARCHAR2,
	  p_org_id             in        number,
	  p_bank_trans_code    in        number
   );
END INFRA_CM_STATEMENT_LOAD_PKG;
/