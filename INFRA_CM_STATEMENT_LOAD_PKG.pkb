CREATE OR REPLACE PACKAGE BODY APPS.INFRA_CM_STATEMENT_LOAD_PKG
AS
   PROCEDURE INFRA_STATEMENT_UPLOAD_PROC (
      p_line_number        IN       NUMBER,
	  p_statement_number   IN       VARCHAR2,
      p_bank_account_num   IN       VARCHAR2,
      p_trx_date           IN       DATE,
      p_amount             IN       NUMBER,
      p_bank_trx_number    IN       VARCHAR2,
	  p_line_desc          IN       VARCHAR2,
	    p_org_id           IN       number,
	  p_bank_trans_code    IN       number
   )
   IS
      v_errm            VARCHAR2(4000) := NULL;
      v_org_id          NUMBER;
	  p_currency_code   VARCHAR2(20);
	  v_count           NUMBER    :=0;
	  v_cnt             NUMBER;
	  x                 VARCHAR2(4000);
	  v_amount          VARCHAR2(4000);
	  v_attribute1      VARCHAR2(4000);
	  v_header_count    INTEGER;
	  v_lines_count     INTEGER;
	  v_base_count      INTEGER     :=0;
	  v_bank_acct       CHAR(1);
	  v_x_cnt number;
	  dup_value			EXCEPTION;
	  PRAGMA EXCEPTION_INIT(DUP_VALUE,-20004);
   BEGIN
      v_org_id := p_org_id ;--Fnd_Profile.value ('ORG_ID');
--v_attribute1:=NULL;
	  --v_attribute1 := p_bank_trx_number||p_trx_date||p_amount;
	BEGIN
		 SELECT '1'
		   INTO v_bank_acct
		   FROM Ap_bank_accounts_all
		  WHERE bank_account_num=p_bank_account_num
		    AND org_id = v_org_id
		  ;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			 RAISE_APPLICATION_ERROR(-20002,'Invalid Account Number :'||p_bank_account_num||' '||v_org_id||p_bank_account_num);
	END;
	  BEGIN
	  SELECT (p_bank_trx_number||p_trx_date||p_amount) INTO v_attribute1 FROM dual;
	  END;
	  --this retrives the functional currency--
	  BEGIN
	  	   SELECT currency_code
		     INTO p_currency_code
			 FROM gl_sets_of_books
			WHERE set_of_books_id = Fnd_Profile.value('GL_SET_OF_BKS_ID')
			;
	  EXCEPTION
	  		   WHEN NO_DATA_FOUND THEN
			   		RAISE_APPLICATION_ERROR(-20001,'Currency Code Not Found');
	  END;
--just now added--
-- Check Trans code
BEGIN
	  	   SELECT trx_code
		     INTO v_count
			 FROM ap_bank_accounts_all a,ce_transaction_codes b
			WHERE a.bank_account_num=p_bank_account_num
		    AND org_id = v_org_id
			and a.bank_account_id=b.bank_account_id and b.trx_code=p_bank_trans_code
			;
	  EXCEPTION
	  		   WHEN NO_DATA_FOUND THEN
			   		RAISE_APPLICATION_ERROR(-20001,'Invalid Bank Transaction Code');
	  END;
---
 SELECT NVL(COUNT(1),0)
   INTO v_count
   FROM ce_statement_lines_interface lin
  WHERE lin.attribute1=v_attribute1
	;
  SELECT NVL(COUNT(1),0)
    INTO v_base_count
	FROM ce_statement_lines csl
   WHERE csl.attribute1=v_attribute1
    ;
	IF v_count=0 AND v_base_count=0 THEN
   	   SELECT COUNT(1)
	     INTO v_header_count
		 FROM ce_statement_headers_int_all
		WHERE statement_number=p_statement_number
          AND bank_account_num=p_bank_account_num
		  AND org_id = v_org_id
		  ;
		 /* SELECT COUNT(1)
	     INTO v_header_count
		 FROM ce_statement_headers_int_all hed,
		       ce_statement_lines_interface lin
		WHERE hed.statement_number=lin.statement_number
		  AND hed.statement_number=p_statement_number
          AND hed.bank_account_num=p_bank_account_num
		  AND hed.org_id = v_org_id
		  AND lin.TRX_DATE=p_TRX_DATE
          AND lin.AMOUNT=p_AMOUNT
		  AND lin.BANK_TRX_NUMBER=p_bank_trx_number; */  ---added by jerome for experiment on 3rd august--
		IF v_header_count=0 THEN
	       INSERT INTO ce_statement_headers_int_all
                  (statement_number,
                   bank_account_num,
                   statement_date,
                   record_status_flag,                            -- n for new
                   currency_code,
                   org_id
                  )
           VALUES (p_statement_number,
                   p_bank_account_num,
                   SYSDATE,
                   'N',
                   p_currency_code,
                   v_org_id
                  );
		END IF;
		SELECT COUNT(1)
	     INTO v_lines_count
		 FROM ce_statement_lines_interface lin
		WHERE TRX_DATE=p_TRX_DATE
          AND AMOUNT=ABS(p_AMOUNT)
		  AND BANK_TRX_NUMBER=p_bank_trx_number;
		  IF v_lines_count =0 THEN

		  v_amount:=p_amount;

		/*  SELECT count(trx_code)
		     INTO v_x_cnt
			 FROM ap_bank_accounts_all a,ce_transaction_codes b
			WHERE a.bank_account_num=p_bank_account_num
		    AND org_id = v_org_id
			and a.bank_account_id=b.bank_account_id and b.trx_code=p_bank_trans_code
			and trx_type like '%CREDIT%';

			if v_x_cnt<>0 and v_amount<0 then
			v_amount:=v_amount*-1;
			end if;

			  SELECT count(trx_code)
		     INTO v_x_cnt
			 FROM ap_bank_accounts_all a,ce_transaction_codes b
			WHERE a.bank_account_num=p_bank_account_num
		    AND org_id = v_org_id
			and a.bank_account_id=b.bank_account_id and b.trx_code=p_bank_trans_code
			and trx_type like '%DEBIT%';

			if v_x_cnt<>0 and v_amount>0 then
			v_amount:=v_amount*-1;
			end if; */


      INSERT INTO ce_statement_lines_interface
                  (bank_account_num,
                   statement_number,
                   line_number,
                   trx_date,
                   trx_code,
                   amount,
                   bank_trx_number,
				   attribute1,
				   trx_text
                  )
           VALUES (p_bank_account_num,
                   p_statement_number,
                   p_line_number,
                   p_trx_date,
                    p_bank_trans_code,--'100',
                   v_amount,--p_amount * -1 ,
                   p_bank_trx_number,
				   v_attribute1,
				   p_line_desc
                  );
				  END IF;
	  ELSE
	  	  RAISE DUP_VALUE;
	  END IF;
--      COMMIT;
   EXCEPTION
   	  WHEN DUP_VAL_ON_INDEX THEN
	  	  RAISE_APPLICATION_ERROR(-20003,'duplicate record ');
		  ROLLBACK;
   	  WHEN DUP_VALUE THEN
	  	  RAISE_APPLICATION_ERROR(-20003,'duplicate record ');
		  ROLLBACK;
      WHEN OTHERS
      THEN
	  	  RAISE_APPLICATION_ERROR(-20003,SQLERRM);
		  ROLLBACK;
   END INFRA_statement_upload_proc;
END INFRA_Cm_Statement_Load_Pkg;
/