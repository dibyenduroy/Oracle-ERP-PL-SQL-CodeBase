CREATE OR REPLACE PACKAGE BODY APPS.BNE_PARAMETER_UTILS AS
/* $Header: bneparamb.pls 115.51 2003/01/06 01:32:38 hcops noship $ */

----------------------------------------------------------------------------------
--  FUNCTION:            CREATE_PARAM_LIST_ALL                                	--
--                                                                            	--
--  DESCRIPTION:         Inserts into BNE_PARAM_LISTS_B/_TL                    	--
--                       Parameters are the column values for these tables    	--
--                                                                            	--
--  PARAMETERS: P_APPLICATION_ID	= BNE_PARAM_LISTS_B.APPLICATION_ID      	    --
--		P_PARAM_LIST_CODE    	= BNE_PARAM_LISTS_B.PARAM_LIST_CODE				          --
--		P_PARAM_LIST_NAME  	= BNE_PARAM_LISTS_TL.PARAM_LIST_NAME   				        --
--		P_PERSISTENT      	= BNE_PARAM_LISTS_B.PERSISTENT_FLAG     			        --
--		P_COMMENTS        	= BNE_PARAM_LISTS_B.COMMENTS            			        --
--		P_ATTRIBUTE_APP_ID	= BNE_PARAM_LISTS_B.ATTRIBUTE_APP_ID				          --
--		P_ATTRIBUTE_CODE    = BNE_PARAM_LISTS_B.ATTRIBUTE_ID        			        --
--		P_LIST_RESOLVER    	= BNE_PARAM_LISTS_B.LIST_RESOLVER       			        --
--		P_PROMPT_LEFT      	= BNE_PARAM_LISTS_TL.PROMPT_LEFT       				        --
--		P_PROMPT_ABOVE     	= BNE_PARAM_LISTS_TL.PROMPT_ABOVE       			        --
--		P_USER_NAME			    = BNE_PARAM_LISTS_TL.USER_NAME						            --
--		P_USER_TIP         	= BNE_PARAM_LISTS_TL.USER_TIP           			        --
--																				                                      --
--  RETURN: 	         parameter list key. E.g 101:CODE 						            --
--                                                                            	--
--  MODIFICATION HISTORY                                                      	--
--  Date       Username  Description                                          	--
--  4-Oct-02   KDOBINSO  CREATED                                              	--
--  7-Oct-02   KDOBINSO  UPDATED FOR WEB ADI REPOSITORY CHANGE                  --
----------------------------------------------------------------------------------

-- all values for BNE_PARAM_LIST/_TL

FUNCTION CREATE_PARAM_LIST_ALL(	P_APPLICATION_ID   in BNE_PARAM_LISTS_B.APPLICATION_ID%type,
					P_PARAM_LIST_CODE  in BNE_PARAM_LISTS_B.PARAM_LIST_CODE%type,
					P_PERSISTENT       in BNE_PARAM_LISTS_B.PERSISTENT_FLAG%type,
					P_COMMENTS         in BNE_PARAM_LISTS_B.COMMENTS%type,
					P_ATTRIBUTE_APP_ID in BNE_PARAM_LISTS_B.ATTRIBUTE_APP_ID%type,
					P_ATTRIBUTE_CODE   in BNE_PARAM_LISTS_B.ATTRIBUTE_CODE%type,
					P_LIST_RESOLVER    in BNE_PARAM_LISTS_B.LIST_RESOLVER%type,
					P_PROMPT_LEFT      in BNE_PARAM_LISTS_TL.PROMPT_LEFT%type,
					P_PROMPT_ABOVE     in BNE_PARAM_LISTS_TL.PROMPT_ABOVE%type,
					P_USER_NAME	       in BNE_PARAM_LISTS_TL.USER_NAME%type,
					P_USER_TIP         in BNE_PARAM_LISTS_TL.USER_TIP%type )

	RETURN BNE_PARAM_LISTS_TL.PARAM_LIST_CODE%type AS VN_KEY BNE_PARAM_LISTS_TL.PARAM_LIST_CODE%type;

	VN_OBJECT_VERSION_NUM 	BNE_PARAM_LISTS_B.OBJECT_VERSION_NUMBER%type;
	VV_PARAM_LIST_CODE		BNE_PARAM_LISTS_B.PARAM_LIST_CODE%type;

BEGIN
	-- defaults

	VN_OBJECT_VERSION_NUM 	:= 1;

	-- a key accepts only codes that are uppercase
	VV_PARAM_LIST_CODE	:= UPPER(P_PARAM_LIST_CODE);

	-- create the key
	VN_KEY := P_APPLICATION_ID || ':' || VV_PARAM_LIST_CODE;


	INSERT INTO BNE_PARAM_LISTS_B (    APPLICATION_ID,
					  PARAM_LIST_CODE,
					  OBJECT_VERSION_NUMBER,
					  PERSISTENT_FLAG,
					  COMMENTS,
					  ATTRIBUTE_APP_ID,
					  ATTRIBUTE_CODE,
					  LIST_RESOLVER,
					  LAST_UPDATE_DATE,
					  LAST_UPDATED_BY,
					  CREATION_DATE,
					  CREATED_BY,
					  LAST_UPDATE_LOGIN  ) VALUES

					( P_APPLICATION_ID,
					  VV_PARAM_LIST_CODE,
					  VN_OBJECT_VERSION_NUM,
					  P_PERSISTENT,
					  P_COMMENTS,
					  P_ATTRIBUTE_APP_ID,
					  P_ATTRIBUTE_CODE,
					  P_LIST_RESOLVER,
					  SYSDATE,
					  FND_GLOBAL.USER_ID,
					  SYSDATE,
					  FND_GLOBAL.USER_ID,
					  NULL );


	INSERT INTO BNE_PARAM_LISTS_TL   (APPLICATION_ID,
					  PARAM_LIST_CODE,
					  LANGUAGE,
					  SOURCE_LANG,
					  USER_NAME,
					  USER_TIP,
					  PROMPT_LEFT,
					  PROMPT_ABOVE,
					  LAST_UPDATE_DATE,
					  LAST_UPDATED_BY,
					  CREATION_DATE,
					  CREATED_BY,
					  LAST_UPDATE_LOGIN ) VALUES

					( P_APPLICATION_ID,
					  VV_PARAM_LIST_CODE,
					  FND_GLOBAL.CURRENT_LANGUAGE,
					  FND_GLOBAL.CURRENT_LANGUAGE,
					  P_USER_NAME,
					  P_USER_TIP,
					  P_PROMPT_LEFT,
					  P_PROMPT_ABOVE,
					  SYSDATE,
					  FND_GLOBAL.USER_ID,
					  SYSDATE,
					  FND_GLOBAL.USER_ID,
					  NULL );

	RETURN (VN_KEY);

END CREATE_PARAM_LIST_ALL;


--------------------------------------------------------------------------------
--  FUNCTION:            CREATE_PARAM_LIST_MINIMAL                            --
--                                                                            --
--  DESCRIPTION:         Inserts into BNE_PARAM_LISTS_B/_TL                   --
--                       Parameters are the not NULL values for these tables  --
--                       Uses FND_GLOBAL.RESP_APPL_ID for the APPLICATION_ID  --
--									                                                          --
--  PARAMETERS: 							                                                --
--		P_PARAM_LIST_CODE = BNE_PARAM_LISTS_B.PARAM_LIST_ID                     --
--		P_PARAM_LIST_NAME = BNE_PARAM_LISTS_TL.PARAM_LIST_NAME 	                --
--		P_PERSISTENT      = BNE_PARAM_LISTS_B.PERSISTENT_FLAG                   --
--			 			                                                                --
--									                                                          --
--  RETURN: 	         parameter list key. E.g. 101:CODE		                  --
--                                                                            --
--  MODIFICATION HISTORY                                                      --
--  Date       Username  Description                                          --
--  8-May-02   KDOBINSO  CREATED    					                                --
--  8-Jul-02   KDOBINSO  UPDATED format of parameters and varibles            --
--  7-Oct-02   KDOBINSO  UPDATED FOR WEB ADI REPOSITORY CHANGE                --
--------------------------------------------------------------------------------


FUNCTION CREATE_PARAM_LIST_MINIMAL( P_PARAM_LIST_CODE   in BNE_PARAM_LISTS_B.PARAM_LIST_CODE%type,
              P_PERSISTENT    in BNE_PARAM_LISTS_B.PERSISTENT_FLAG%type,
              P_USER_NAME			in BNE_PARAM_LISTS_TL.USER_NAME%type)

	RETURN BNE_PARAM_LISTS_TL.PARAM_LIST_CODE%type as VN_KEY BNE_PARAM_LISTS_TL.PARAM_LIST_CODE%type;

BEGIN

	VN_KEY := CREATE_PARAM_LIST_ALL( FND_GLOBAL.RESP_APPL_ID, P_PARAM_LIST_CODE, P_PERSISTENT, NULL, NULL,
					 NULL , NULL, NULL, NULL, P_USER_NAME, NULL);



	RETURN VN_KEY;

END CREATE_PARAM_LIST_MINIMAL;


----------------------------------------------------------------------------------
--  FUNCTION:            CREATE_ATTRIBUTES                                   	  --
--                                                                            	--
--  DESCRIPTION:Inserts into BNE_ATTRIBUTES. The attribute id given   	        --
--			        should be assigned to a parameter list or a parameter.	        --
-- 			        It is suggested that you call GET_NEXT_ATTRIBUTE_SEQ  	        --
-- 		          add to BNE_PARAM_LIST or BNE_PARAM_DEFN using the     	        --
--     			    using the value returned from GET_NEXT_ATTRIBUTE_SEQ  	        --
--		          as the attribute id.                                  	        --
--  			              					      	                                      --
--                                                                            	--
--  PARAMETERS:          P_ATTRIBUTE_ID = BNE_ATTRIBUTES.ATTRIBUTE_ID         	--
--			 P_ATTRIBUTE1  	= BNE_ATTRIBUTES.ATTRIBUTE1           	                --
--			 to                                                   	                --
--			 P_ATTRIBUTE30   = BNE_ATTRIBUTES.ATTRIBUTE30          	                --
--			 			 		   		                                                        --
--						 		                                                              --
--  RETURN: 	         attribute key. E.g. 101:CODE 	  			                  --
-- 										                                                          --
--                                                                            	--
--  MODIFICATION HISTORY                                                      	--
--  Date       Username  Description                                          	--
--  8-May-02   KDOBINSO  CREATED                                              	--
--  7-Oct-02   KDOBINSO  UPDATED FOR WEB ADI REPOSITORY CHANGE                  --
----------------------------------------------------------------------------------


FUNCTION CREATE_ATTRIBUTES (P_APPLICATION_ID	in BNE_ATTRIBUTES.APPLICATION_ID%type,
			    P_ATTRIBUTE_CODE 	in BNE_ATTRIBUTES.ATTRIBUTE_CODE%type,
			    P_ATTRIBUTE1    	in BNE_ATTRIBUTES.ATTRIBUTE1%type,
			    P_ATTRIBUTE2    	in BNE_ATTRIBUTES.ATTRIBUTE2%type,
			    P_ATTRIBUTE3    	in BNE_ATTRIBUTES.ATTRIBUTE3%type,
			    P_ATTRIBUTE4    	in BNE_ATTRIBUTES.ATTRIBUTE4%type,
			    P_ATTRIBUTE5    	in BNE_ATTRIBUTES.ATTRIBUTE5%type,
			    P_ATTRIBUTE6    	in BNE_ATTRIBUTES.ATTRIBUTE6%type,
			    P_ATTRIBUTE7    	in BNE_ATTRIBUTES.ATTRIBUTE7%type,
			    P_ATTRIBUTE8    	in BNE_ATTRIBUTES.ATTRIBUTE8%type,
			    P_ATTRIBUTE9   		in BNE_ATTRIBUTES.ATTRIBUTE9%type,
			    P_ATTRIBUTE10   	in BNE_ATTRIBUTES.ATTRIBUTE10%type,
			    P_ATTRIBUTE11   	in BNE_ATTRIBUTES.ATTRIBUTE11%type,
			    P_ATTRIBUTE12   	in BNE_ATTRIBUTES.ATTRIBUTE12%type,
			    P_ATTRIBUTE13   	in BNE_ATTRIBUTES.ATTRIBUTE13%type,
			    P_ATTRIBUTE14   	in BNE_ATTRIBUTES.ATTRIBUTE14%type,
			    P_ATTRIBUTE15  		in BNE_ATTRIBUTES.ATTRIBUTE15%type,
			    P_ATTRIBUTE16   	in BNE_ATTRIBUTES.ATTRIBUTE16%type,
			    P_ATTRIBUTE17   	in BNE_ATTRIBUTES.ATTRIBUTE17%type,
			    P_ATTRIBUTE18   	in BNE_ATTRIBUTES.ATTRIBUTE18%type,
			    P_ATTRIBUTE19   	in BNE_ATTRIBUTES.ATTRIBUTE19%type,
			    P_ATTRIBUTE20   	in BNE_ATTRIBUTES.ATTRIBUTE20%type,
			    P_ATTRIBUTE21   	in BNE_ATTRIBUTES.ATTRIBUTE21%type,
			    P_ATTRIBUTE22   	in BNE_ATTRIBUTES.ATTRIBUTE22%type,
			    P_ATTRIBUTE23  		in BNE_ATTRIBUTES.ATTRIBUTE23%type,
			    P_ATTRIBUTE24   	in BNE_ATTRIBUTES.ATTRIBUTE24%type,
			    P_ATTRIBUTE25   	in BNE_ATTRIBUTES.ATTRIBUTE25%type,
			    P_ATTRIBUTE26   	in BNE_ATTRIBUTES.ATTRIBUTE26%type,
			    P_ATTRIBUTE27   	in BNE_ATTRIBUTES.ATTRIBUTE27%type,
			    P_ATTRIBUTE28   	in BNE_ATTRIBUTES.ATTRIBUTE28%type,
			    P_ATTRIBUTE29   	in BNE_ATTRIBUTES.ATTRIBUTE29%type,
			    P_ATTRIBUTE30   	in BNE_ATTRIBUTES.ATTRIBUTE30%type )

	RETURN BNE_ATTRIBUTES.ATTRIBUTE_CODE%type as VN_KEY BNE_ATTRIBUTES.ATTRIBUTE_CODE%type;

	VN_OBJECT_VERSION_NUM 	BNE_ATTRIBUTES.OBJECT_VERSION_NUMBER%type;
	VV_ATTRIBUTE_CODE		BNE_ATTRIBUTES.ATTRIBUTE_CODE%type;

BEGIN

	-- defaults

	VN_OBJECT_VERSION_NUM 	:= 1;

	-- code has to be in uppercase to be part of key
	VV_ATTRIBUTE_CODE	:= UPPER(P_ATTRIBUTE_CODE);

	-- create a key
	VN_KEY := P_APPLICATION_ID || ':' || VV_ATTRIBUTE_CODE;

	INSERT INTO BNE_ATTRIBUTES (  	  APPLICATION_ID,
					  ATTRIBUTE_CODE,
					  OBJECT_VERSION_NUMBER,
					  ATTRIBUTE1,
					  ATTRIBUTE2,
					  ATTRIBUTE3,
					  ATTRIBUTE4,
					  ATTRIBUTE5,
					  ATTRIBUTE6,
					  ATTRIBUTE7,
					  ATTRIBUTE8,
					  ATTRIBUTE9,
					  ATTRIBUTE10,
					  ATTRIBUTE11,
					  ATTRIBUTE12,
					  ATTRIBUTE13,
					  ATTRIBUTE14,
					  ATTRIBUTE15,
					  ATTRIBUTE16,
					  ATTRIBUTE17,
					  ATTRIBUTE18,
					  ATTRIBUTE19,
					  ATTRIBUTE20,
					  ATTRIBUTE21,
					  ATTRIBUTE22,
					  ATTRIBUTE23,
					  ATTRIBUTE24,
					  ATTRIBUTE25,
					  ATTRIBUTE26,
					  ATTRIBUTE27,
					  ATTRIBUTE28,
					  ATTRIBUTE29,
					  ATTRIBUTE30,
					  LAST_UPDATE_DATE,
					  LAST_UPDATED_BY,
					  CREATION_DATE,
					  CREATED_BY,
					  LAST_UPDATE_LOGIN)

	VALUES (P_APPLICATION_ID, P_ATTRIBUTE_CODE, VN_OBJECT_VERSION_NUM, P_ATTRIBUTE1, P_ATTRIBUTE2, P_ATTRIBUTE3,
			P_ATTRIBUTE4 ,P_ATTRIBUTE5 , P_ATTRIBUTE6 ,P_ATTRIBUTE7 ,P_ATTRIBUTE8 ,P_ATTRIBUTE9,
			P_ATTRIBUTE10,P_ATTRIBUTE11,P_ATTRIBUTE12,P_ATTRIBUTE13,P_ATTRIBUTE14 ,P_ATTRIBUTE15,
			P_ATTRIBUTE16,P_ATTRIBUTE17,P_ATTRIBUTE18,P_ATTRIBUTE19,P_ATTRIBUTE20,P_ATTRIBUTE21,
			P_ATTRIBUTE22,P_ATTRIBUTE23,P_ATTRIBUTE24,P_ATTRIBUTE25 ,P_ATTRIBUTE26 ,P_ATTRIBUTE27,
			P_ATTRIBUTE28,P_ATTRIBUTE29,P_ATTRIBUTE30, SYSDATE,FND_GLOBAL.USER_ID,SYSDATE, FND_GLOBAL.USER_ID, NULL );

END CREATE_ATTRIBUTES;



--------------------------------------------------------------------------------
--  FUNCTION:            CREATE_ATTRIBUTES_MINIMAL                            --
--                                                                            --
--  DESCRIPTION:         Inserts 10 ATTRIBUTES into BNE_ATTRIBUTES	          --
--			 Uses FND_GLOBAL.RESP_APPL_ID for the APPLICATION_ID                  --
--                                                                            --
--  PARAMETERS:          P_ATTRIBUTE_ID    = BNE_ATTRIBUTES.ATTRIBUTE_ID      --
--			 P_ATTRIBUTE1 	= BNE_ATTRIBUTES.ATTRIBUTE1                           --
--			 to                                                                   --
--			 P_ATTRIBUTE10   = BNE_ATTRIBUTES.ATTRIBUTE10                         --
--						  		                                                          --
--  RETURN: 	         attribute key. E.g. 101:CODE 	       	      	        --
-- 					      				                                                    --
--                                                                            --
--  MODIFICATION HISTORY                                                      --
--  Date       Username  Description                                          --
--  8-May-02   KDOBINSO  CREATED                                              --
--  7-Oct-02   KDOBINSO  UPDATED FOR WEB ADI REPOSITORY CHANGE                --
--------------------------------------------------------------------------------

FUNCTION CREATE_ATTRIBUTES_MINIMAL (P_ATTRIBUTE_CODE  in BNE_ATTRIBUTES.ATTRIBUTE_CODE%type,
				    P_ATTRIBUTE1    in BNE_ATTRIBUTES.ATTRIBUTE1%type,
				    P_ATTRIBUTE2    in BNE_ATTRIBUTES.ATTRIBUTE2%type,
				    P_ATTRIBUTE3    in BNE_ATTRIBUTES.ATTRIBUTE3%type,
				    P_ATTRIBUTE4    in BNE_ATTRIBUTES.ATTRIBUTE4%type,
				    P_ATTRIBUTE5    in BNE_ATTRIBUTES.ATTRIBUTE5%type,
				    P_ATTRIBUTE6    in BNE_ATTRIBUTES.ATTRIBUTE6%type,
				    P_ATTRIBUTE7    in BNE_ATTRIBUTES.ATTRIBUTE7%type,
				    P_ATTRIBUTE8    in BNE_ATTRIBUTES.ATTRIBUTE8%type,
				    P_ATTRIBUTE9    in BNE_ATTRIBUTES.ATTRIBUTE9%type,
				    P_ATTRIBUTE10   in BNE_ATTRIBUTES.ATTRIBUTE10%type )

		RETURN BNE_ATTRIBUTES.ATTRIBUTE_CODE%type as VN_KEY BNE_ATTRIBUTES.ATTRIBUTE_CODE%type;

BEGIN

	VN_KEY := CREATE_ATTRIBUTES(FND_GLOBAL.RESP_APPL_ID, P_ATTRIBUTE_CODE,P_ATTRIBUTE1, P_ATTRIBUTE2, P_ATTRIBUTE3, P_ATTRIBUTE4,
			P_ATTRIBUTE5 ,P_ATTRIBUTE6 , P_ATTRIBUTE7 ,P_ATTRIBUTE8,P_ATTRIBUTE9,P_ATTRIBUTE10,
			NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

	RETURN (VN_KEY);

END CREATE_ATTRIBUTES_MINIMAL;


--------------------------------------------------------------------------------------
--  FUNCTION:             CREATE_LIST_ITEMS_ALL                               		  --
--                                                                            		  --
--  DESCRIPTION:          Inserts into BNE_PARAM_LIST_ITEMS                   		  --
--                                                                            		  --
--  PARAMETERS:           P_APPLICATION_ID	= BNE_PARAM_LIST_ITEMS.APPLICATION_ID 	--
--			  P_PARAM_LIST_CODE 	= BNE_PARAM_LIST_ITEMS.PARAM_LIST_CODE                --
--			  P_PARAM_DEFN_APP_ID = BNE_PARAM_LIST_ITEMS.PARAM_DEFN_APP_ID              --
--			  P_PARAM_DEFN_CODE	= BNE_PARAM_LIST_ITEMS.PARAM_DEFN_CODE 	                --
--			  P_PARAM_NAME    	= BNE_PARAM_LIST_ITEMS.PARAM_NAME     	                --
--			  P_ATTRIBUTE_APP_ID  	= BNE_PARAM_LIST_ITEMS.ATTRIBUTE_APP_ID             --
--			  P_ATTRIBUTE_CODE	= BNE_PARAM_LIST_ITEMS.ATTRIBUTE_CODE 	                --
--			  P_STRING_VAL    	= BNE_PARAM_LIST_ITEMS.STRING_VALUE   	                --
--			  P_DATE_VAL      	= BNE_PARAM_LIST_ITEMS.DATE_VALUE     	                --
--			  P_NUMBER_VAL    	= BNE_PARAM_LIST_ITEMS.NUMBER_VALUE   	                --
--			  P_BOOLEAN_VAL   	= BNE_PARAM_LIST_ITEMS.BOOLEAN_VALUE_FLAG               --
--			  P_FORMULA       	= BNE_PARAM_LIST_ITEMS.FORMULA_VALUE  	                --
--			  P_DESC_VAL      	= BNE_PARAM_LIST_ITEMS.DESC_VALUE     	                --
--											                                                            --
--  RETURN: 	         sequence number of item                              		    --
--                                                                            		  --
--  MODIFICATION HISTORY                                                      		  --
--  Date       Username  Description                                          		  --
--  8-May-02   KDOBINSO  CREATED                                              		  --
--  7-Oct-02   KDOBINSO  UPDATED FOR WEB ADI REPOSITORY CHANGE                      --
--------------------------------------------------------------------------------------


FUNCTION CREATE_LIST_ITEMS_ALL   (P_APPLICATION_ID	in BNE_PARAM_LIST_ITEMS.APPLICATION_ID%type,
				  P_PARAM_LIST_CODE   	in BNE_PARAM_LIST_ITEMS.PARAM_LIST_CODE%type,
				  P_PARAM_DEFN_APP_ID	  in BNE_PARAM_LIST_ITEMS.PARAM_DEFN_APP_ID%type,
				  P_PARAM_DEFN_CODE   	in BNE_PARAM_LIST_ITEMS.PARAM_DEFN_CODE%type,
				  P_PARAM_NAME      	  in BNE_PARAM_LIST_ITEMS.PARAM_NAME%type,
				  P_ATTRIBUTE_APP_ID	  in BNE_PARAM_LIST_ITEMS.ATTRIBUTE_APP_ID%type,
				  P_ATTRIBUTE_CODE    	in BNE_PARAM_LIST_ITEMS.ATTRIBUTE_CODE%type,
				  P_STRING_VAL      	  in BNE_PARAM_LIST_ITEMS.STRING_VALUE%type,
				  P_DATE_VAL        	  in BNE_PARAM_LIST_ITEMS.DATE_VALUE%type,
				  P_NUMBER_VAL      	  in BNE_PARAM_LIST_ITEMS.NUMBER_VALUE%type,
				  P_BOOLEAN_VAL     	  in BNE_PARAM_LIST_ITEMS.BOOLEAN_VALUE_FLAG%type,
				  P_FORMULA        	    in BNE_PARAM_LIST_ITEMS.FORMULA_VALUE%type,
				  P_DESC_VAL         	  in BNE_PARAM_LIST_ITEMS.DESC_VALUE %type )

		RETURN BNE_PARAM_LIST_ITEMS.SEQUENCE_NUM%type AS VN_SEQ_NUM BNE_PARAM_LIST_ITEMS.SEQUENCE_NUM%type;

		VN_OBJECT_VERSION_NUM BNE_PARAM_LIST_ITEMS.OBJECT_VERSION_NUMBER%type;
		VN_LIST_KEY 		  BNE_PARAM_LIST_ITEMS.PARAM_LIST_CODE%type;
		VV_LIST_CODE		  BNE_PARAM_LIST_ITEMS.PARAM_LIST_CODE%type;
BEGIN
	--default value
	VN_OBJECT_VERSION_NUM := 1;

	VV_LIST_CODE 	:= UPPER(P_PARAM_LIST_CODE);

	-- create the key
	VN_LIST_KEY := P_APPLICATION_ID || ':' || VV_LIST_CODE;

	VN_SEQ_NUM := GET_NEXT_ITEM_SEQ(P_APPLICATION_ID , VV_LIST_CODE);

	--dbms_output.put_line('BNE_PARAMETER_UTILS. Seq Num is ' || VN_SEQ_NUM);

	INSERT INTO BNE_PARAM_LIST_ITEMS  (	APPLICATION_ID,
						PARAM_LIST_CODE,
						SEQUENCE_NUM,
						OBJECT_VERSION_NUMBER,
						PARAM_DEFN_APP_ID,
						PARAM_DEFN_CODE,
						PARAM_NAME ,
						ATTRIBUTE_APP_ID,
						ATTRIBUTE_CODE,
						STRING_VALUE,
						DATE_VALUE,
						NUMBER_VALUE,
						BOOLEAN_VALUE_FLAG ,
						FORMULA_VALUE,
						DESC_VALUE ,
						LAST_UPDATE_DATE,
						LAST_UPDATED_BY,
						CREATION_DATE,
						CREATED_BY,
						LAST_UPDATE_LOGIN )
				VALUES (P_APPLICATION_ID,
						VV_LIST_CODE,
						VN_SEQ_NUM,
						VN_OBJECT_VERSION_NUM,
						P_PARAM_DEFN_APP_ID,
						P_PARAM_DEFN_CODE,
						P_PARAM_NAME,
						P_ATTRIBUTE_APP_ID,
						P_ATTRIBUTE_CODE,
						P_STRING_VAL,
						P_DATE_VAL,
						P_NUMBER_VAL ,
						P_BOOLEAN_VAL ,
						P_FORMULA ,
						P_DESC_VAL ,
						SYSDATE,
						FND_GLOBAL.USER_ID,
						SYSDATE,
						FND_GLOBAL.USER_ID,
						NULL );


	RETURN (VN_SEQ_NUM);



END CREATE_LIST_ITEMS_ALL;

------------------------------------------------------------------------------------------
--  FUNCTION:             CREATE_LIST_ITEMS_MINIMAL                            		      --
--                                                                            		      --
--  DESCRIPTION:          Inserts into BNE_PARAM_LIST_ITEMS				                      --
--			  APPLICATION_ID = FND_GLOBAL.RESP_APPL_ID			                                --
--                                                                            		      --
--  PARAMETERS:           P_PARAM_LIST_CODE 	= BNE_PARAM_LIST_ITEMS.PARAM_LIST_CODE    --
--			  P_PARAM_DEFN_APP_ID 	= BNE_PARAM_LIST_ITEMS.PARAM_DEFN_APP_ID                --
--			  P_PARAM_DEFN_CODE	    = BNE_PARAM_LIST_ITEMS.PARAM_DEFN_CODE 	                --
--			  P_PARAM_NAME    	    = BNE_PARAM_LIST_ITEMS.PARAM_NAME     	                --
--			  P_STRING_VAL    	    = BNE_PARAM_LIST_ITEMS.STRING_VALUE   	                --
--			  P_DATE_VAL      	    = BNE_PARAM_LIST_ITEMS.DATE_VALUE     	                --
--			  P_NUMBER_VAL    	    = BNE_PARAM_LIST_ITEMS.NUMBER_VALUE   	                --
--			  P_BOOLEAN_VAL   	    = BNE_PARAM_LIST_ITEMS.BOOLEAN_VALUE_FLAG               --
--			  P_DESC_VAL      	    = BNE_PARAM_LIST_ITEMS.DESC_VALUE     	                --
--											                                                                --
--  RETURN: 	         sequence number of item                              		        --
--                                                                            		      --
--  MODIFICATION HISTORY                                                      		      --
--  Date       Username  Description                                          		      --
--  8-May-02   KDOBINSO  CREATED                                              		      --
--  7-Oct-02   KDOBINSO  UPDATED FOR WEB ADI REPOSITORY CHANGE                          --
------------------------------------------------------------------------------------------


FUNCTION CREATE_LIST_ITEMS_MINIMAL(P_PARAM_LIST_CODE   	in BNE_PARAM_LIST_ITEMS.PARAM_LIST_CODE%type,
				  P_PARAM_DEFN_APP_ID	in BNE_PARAM_LIST_ITEMS.PARAM_DEFN_APP_ID%type,
				  P_PARAM_DEFN_CODE   	in BNE_PARAM_LIST_ITEMS.PARAM_DEFN_CODE%type,
				  P_PARAM_NAME      	in BNE_PARAM_LIST_ITEMS.PARAM_NAME%type,
				  P_STRING_VAL      	in BNE_PARAM_LIST_ITEMS.STRING_VALUE%type,
				  P_DATE_VAL        	in BNE_PARAM_LIST_ITEMS.DATE_VALUE%type,
				  P_NUMBER_VAL      	in BNE_PARAM_LIST_ITEMS.NUMBER_VALUE%type,
				  P_BOOLEAN_VAL     	in BNE_PARAM_LIST_ITEMS.BOOLEAN_VALUE_FLAG%type,
				  P_DESC_VAL        	in BNE_PARAM_LIST_ITEMS.DESC_VALUE %type )

	RETURN BNE_PARAM_LIST_ITEMS.SEQUENCE_NUM%type AS VN_SEQ_NUM BNE_PARAM_LIST_ITEMS.SEQUENCE_NUM%type;

	VN_LIST_KEY 	BNE_PARAM_LIST_ITEMS.PARAM_LIST_CODE%type;

BEGIN

	VN_SEQ_NUM := CREATE_LIST_ITEMS_ALL(FND_GLOBAL.RESP_APPL_ID, P_PARAM_LIST_CODE, P_PARAM_DEFN_APP_ID,
					P_PARAM_DEFN_CODE, P_PARAM_NAME, NULL, NULL, P_STRING_VAL,P_DATE_VAL,
					P_NUMBER_VAL, P_BOOLEAN_VAL, NULL, P_DESC_VAL);

	RETURN (VN_SEQ_NUM);


END CREATE_LIST_ITEMS_MINIMAL;


--------------------------------------------------------------------------------
--  FUNCTION:             GET_PARAM_DEFNS_B                                   --
--                                                                            --
--  DESCRIPTION:          For a parameter name that is given, returns its KEY --
--  			                Has to be unique    	  	      		                --
--                                                                            --
--  PARAMETERS:           P_PARAM_DEFN_ID = BNE_PARAM_DEFN.PARAM_NAME         --
--			                  P_PARAM_SOURCE  = BNE_PARAM_DEFN.PARAM_SOURCE       --
--				  					                                                        --
--  RETURN: 	          parameter KEY. If not found returns NULL	            --
--                                                                            --
--  MODIFICATION HISTORY                                                      --
--  Date       Username  Description                                          --
--  8-May-02   KDOBINSO  CREATED                                              --
--  7-Oct-02   KDOBINSO  UPDATED FOR WEB ADI REPOSITORY CHANGE                --
--------------------------------------------------------------------------------


FUNCTION GET_PARAM_DEFN_ID (P_APPLICATION_ID in BNE_PARAM_DEFNS_B.APPLICATION_ID%type,
		 				   P_PARAM_DEFN_NAME in BNE_PARAM_DEFNS_B.PARAM_NAME%type,
		 		P_PARAM_SOURCE  in BNE_PARAM_DEFNS_B.PARAM_SOURCE%type )
	RETURN BNE_PARAM_DEFNS_B.PARAM_DEFN_CODE%type AS VV_DEFN_KEY BNE_PARAM_DEFNS_B.PARAM_DEFN_CODE%type;

	VN_APPLICATION_ID BNE_PARAM_DEFNS_B.APPLICATION_ID%type;
	VV_DEFN_CODE	  BNE_PARAM_DEFNS_B.PARAM_DEFN_CODE%type;
BEGIN

	  --dbms_output.put_line('Param Defn Name is ' || P_PARAM_DEFN_NAME);
	  --dbms_output.put_line('Param Source is ' || P_PARAM_SOURCE);

	SELECT 	APPLICATION_ID, PARAM_DEFN_CODE
	INTO 	VN_APPLICATION_ID, VV_DEFN_CODE
	FROM 	BNE_PARAM_DEFNS_B
	WHERE 	PARAM_NAME = P_PARAM_DEFN_NAME
	AND 	PARAM_SOURCE = P_PARAM_SOURCE
	AND		APPLICATION_ID = P_APPLICATION_ID;


	VV_DEFN_KEY := VN_APPLICATION_ID || ':' || VV_DEFN_CODE;

	--dbms_output.put_line('Param Defn is ' || VV_DEFN_KEY);

	RETURN VV_DEFN_KEY;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			VV_DEFN_KEY := NULL;
			RETURN VV_DEFN_KEY;

END GET_PARAM_DEFN_ID;



------------------------------------------------------------------------------------
--  FUNCTION:             CREATE_PARAM_ALL                                    	  --
--                                                                            	  --
--  DESCRIPTION:          Create a parameter. Inserts into BNE_PARAM_DEFNS_B/_TL  --
--										                                                            --
--                                                                            	  --
--  PARAMETERS:           all columns in BNE_PARAM_DEFNS_B/_TL                 	  --
--									   	                                                          --
--  RETURN: 	          parameter KEY. 					                                  --
--                                                                            	  --
--  MODIFICATION HISTORY                                                      	  --
--  Date       Username  Description                                          	  --
--  8-May-02   KDOBINSO  CREATED                                              	  --
--  7-Oct-02   KDOBINSO  UPDATED FOR WEB ADI REPOSITORY CHANGE                    --
------------------------------------------------------------------------------------


FUNCTION CREATE_PARAM_ALL(	P_APPLICATION_ID   in BNE_PARAM_DEFNS_B.APPLICATION_ID%type,
				P_PARAM_CODE   	    in BNE_PARAM_DEFNS_B.PARAM_DEFN_CODE%type,
				P_PARAM_NAME 	      in BNE_PARAM_DEFNS_B.PARAM_NAME%type,
				P_PARAM_SOURCE 	    in BNE_PARAM_DEFNS_B.PARAM_SOURCE%type,
				P_CATEGORY 	   	    in BNE_PARAM_DEFNS_B.PARAM_CATEGORY%type,
				P_DATA_TYPE 	      in BNE_PARAM_DEFNS_B.DATATYPE%type,
				P_ATTRIBUTE_APP_ID  in BNE_PARAM_DEFNS_B.ATTRIBUTE_APP_ID%type,
				P_ATTRIBUTE_CODE    in BNE_PARAM_DEFNS_B.ATTRIBUTE_CODE%type,
				P_PARAM_RESOLVER    in BNE_PARAM_DEFNS_B.PARAM_RESOLVER%type,
				P_REQUIRED  	      in BNE_PARAM_DEFNS_B.DEFAULT_REQUIRED_FLAG%type,
				P_VISIBLE 	   	    in BNE_PARAM_DEFNS_B.DEFAULT_VISIBLE_FLAG%type,
				P_MODIFYABLE 	      in BNE_PARAM_DEFNS_B.DEFAULT_USER_MODIFYABLE_FLAG%type,
				P_DEFAULT_STRING    in BNE_PARAM_DEFNS_B.DEFAULT_STRING%type,
				P_DEFAULT_DATE 	    in BNE_PARAM_DEFNS_B.DEFAULT_DATE%type,
				P_DEFAULT_NUM 	    in BNE_PARAM_DEFNS_B.DEFAULT_NUMBER%type,
				P_DEFAULT_BOOLEAN   in BNE_PARAM_DEFNS_B.DEFAULT_BOOLEAN_FLAG%type,
				P_DEFAULT_FORMULA   in BNE_PARAM_DEFNS_B.DEFAULT_FORMULA%type,
				P_VAL_TYPE          in BNE_PARAM_DEFNS_B.VAL_TYPE%type,
				P_VAL_VALUE 	      in BNE_PARAM_DEFNS_B.VAL_VALUE%type,
				P_MAXIMUM_SIZE 	    in BNE_PARAM_DEFNS_B.MAX_SIZE%type,
				P_DISPLAY_TYPE 	    in BNE_PARAM_DEFNS_B.DISPLAY_TYPE%type,
				P_DISPLAY_STYLE     in BNE_PARAM_DEFNS_B.DISPLAY_STYLE%type,
				P_DISPLAY_SIZE 	    in BNE_PARAM_DEFNS_B.DISPLAY_SIZE%type,
				P_HELP_URL 	   	    in BNE_PARAM_DEFNS_B.HELP_URL%type,
				P_FORMAT_MASK 	    in BNE_PARAM_DEFNS_B.FORMAT_MASK%type,
				P_DEFAULT_DESC 	    in BNE_PARAM_DEFNS_TL.DEFAULT_DESC%type,
				P_PROMPT_LEFT 	    in BNE_PARAM_DEFNS_TL.PROMPT_LEFT%type,
				P_PROMPT_ABOVE 	    in BNE_PARAM_DEFNS_TL.PROMPT_ABOVE%type,
				P_USER_NAME	   	    in BNE_PARAM_DEFNS_TL.USER_NAME%type,
				P_USER_TIP  	      in BNE_PARAM_DEFNS_TL.USER_TIP%type,
				P_ACCESS_KEY 	      in BNE_PARAM_DEFNS_TL.ACCESS_KEY%type)
	RETURN BNE_PARAM_DEFNS_B.PARAM_DEFN_CODE%type AS VV_KEY BNE_PARAM_DEFNS_B.PARAM_DEFN_CODE%type;

	VN_OBJECT_VERSION_NUM BNE_PARAM_DEFNS_B.OBJECT_VERSION_NUMBER%type;

BEGIN
	--default values

	VN_OBJECT_VERSION_NUM := 1;

	--dbms_output.put_line('BNE_PARAMETER_UTILS.CREATE_PARAM_ALL. KEY is ' || P_APPLICATION_ID || ':' || P_PARAM_CODE);


	VV_KEY := P_APPLICATION_ID || ':' || P_PARAM_CODE;


	INSERT INTO BNE_PARAM_DEFNS_B (	  APPLICATION_ID,
            PARAM_DEFN_CODE,
            OBJECT_VERSION_NUMBER,
					  PARAM_NAME ,
					  PARAM_SOURCE,
					  PARAM_CATEGORY,
					  DATATYPE,
					  ATTRIBUTE_APP_ID,
					  ATTRIBUTE_CODE,
					  PARAM_RESOLVER,
					  DEFAULT_REQUIRED_FLAG,
					  DEFAULT_VISIBLE_FLAG,
					  DEFAULT_USER_MODIFYABLE_FLAG,
					  DEFAULT_STRING,
					  DEFAULT_DATE,
					  DEFAULT_NUMBER,
					  DEFAULT_BOOLEAN_FLAG,
					  DEFAULT_FORMULA,
					  VAL_TYPE,
					  VAL_VALUE,
					  MAX_SIZE,
					  DISPLAY_TYPE,
					  DISPLAY_STYLE,
					  DISPLAY_SIZE,
					  HELP_URL,
					  FORMAT_MASK,
					  LAST_UPDATE_DATE,
					  LAST_UPDATED_BY,
					  CREATION_DATE,
					  CREATED_BY,
					  LAST_UPDATE_LOGIN )
				VALUES (P_APPLICATION_ID,
					P_PARAM_CODE,
					VN_OBJECT_VERSION_NUM,
					P_PARAM_NAME,
					P_PARAM_SOURCE,
					P_CATEGORY,
					P_DATA_TYPE,
					P_ATTRIBUTE_APP_ID,
					P_ATTRIBUTE_CODE,
					P_PARAM_RESOLVER,
					P_REQUIRED,
					P_VISIBLE,
					P_MODIFYABLE,
					P_DEFAULT_STRING,
					P_DEFAULT_DATE,
					P_DEFAULT_NUM,
					P_DEFAULT_BOOLEAN,
					P_DEFAULT_FORMULA,
					P_VAL_TYPE,
					P_VAL_VALUE,
					P_MAXIMUM_SIZE,
					P_DISPLAY_TYPE,
					P_DISPLAY_STYLE,
					P_DISPLAY_SIZE,
					P_HELP_URL,
					P_FORMAT_MASK,
					SYSDATE,
					FND_GLOBAL.USER_ID,
					SYSDATE,
					FND_GLOBAL.USER_ID,
					NULL );


	INSERT INTO BNE_PARAM_DEFNS_TL (     APPLICATION_ID,
					     PARAM_DEFN_CODE,
					     LANGUAGE,
					     SOURCE_LANG,
					     DEFAULT_STRING,
					     DEFAULT_DESC,
					     PROMPT_LEFT,
					     PROMPT_ABOVE,
					     USER_NAME,
					     USER_TIP,
					     ACCESS_KEY,
					     LAST_UPDATE_DATE,
					     LAST_UPDATED_BY,
					     CREATION_DATE,
					     CREATED_BY,
					     LAST_UPDATE_LOGIN )
				VALUES (P_APPLICATION_ID,
					P_PARAM_CODE,
					FND_GLOBAL.CURRENT_LANGUAGE,
					FND_GLOBAL.CURRENT_LANGUAGE,
					P_DEFAULT_STRING,
					P_DEFAULT_DESC,
					P_PROMPT_LEFT,
					P_PROMPT_ABOVE,
					P_USER_NAME,
					P_USER_TIP,
					P_ACCESS_KEY,
					SYSDATE,
					FND_GLOBAL.USER_ID,
					SYSDATE,
					FND_GLOBAL.USER_ID,
					NULL );
	RETURN (VV_KEY);

END CREATE_PARAM_ALL;




--------------------------------------------------------------------------------
--  FUNCTION:             CREATE_PARAM_MINIMAL                                --
--                                                                            --
--  DESCRIPTION:          Create a parameter. Inserts into BNE_PARAM_DEFN/_TL --
--  			                Parameters are the not NULL values for these tables --
--                        APPLICATION_ID = FND_GLOBAL.RESP_APPL_ID            --
--  PARAMETERS:           not NULL columns in BNE_PARAM_DEFN/_TL              --
--				  					                                                        --
--  RETURN: 	          parameter name                                        --
--                                                                            --
--  MODIFICATION HISTORY                                                      --
--  Date       Username  Description                                          --
--  8-May-02   KDOBINSO  CREATED                                              --
--  7-Oct-02   KDOBINSO  UPDATED FOR WEB ADI REPOSITORY CHANGE                --
--------------------------------------------------------------------------------

FUNCTION CREATE_PARAM_MINIMAL (	P_PARAM_CODE      in BNE_PARAM_DEFNS_B.PARAM_DEFN_CODE%type,
				P_PARAM_NAME 	    in BNE_PARAM_DEFNS_B.PARAM_NAME%type,
				P_PARAM_SOURCE 	  in BNE_PARAM_DEFNS_B.PARAM_SOURCE%type,
				P_CATEGORY 	  	  in BNE_PARAM_DEFNS_B.PARAM_CATEGORY%type,
				P_DATA_TYPE 	    in BNE_PARAM_DEFNS_B.DATATYPE%type,
				P_REQUIRED 	  	  in BNE_PARAM_DEFNS_B.DEFAULT_REQUIRED_FLAG%type,
				P_VISIBLE 	  	  in BNE_PARAM_DEFNS_B.DEFAULT_VISIBLE_FLAG%type,
				P_MODIFYABLE 	    in BNE_PARAM_DEFNS_B.DEFAULT_USER_MODIFYABLE_FLAG%type,
				P_DEFAULT_STRING  in BNE_PARAM_DEFNS_B.DEFAULT_STRING%type,
				P_DEFAULT_DATE 	  in BNE_PARAM_DEFNS_B.DEFAULT_DATE%type,
				P_DEFAULT_NUM 	  in BNE_PARAM_DEFNS_B.DEFAULT_NUMBER%type,
				P_DEFAULT_BOOLEAN in BNE_PARAM_DEFNS_B.DEFAULT_BOOLEAN_FLAG%type,
				P_VAL_TYPE        in BNE_PARAM_DEFNS_B.VAL_TYPE%type,
				P_MAXIMUM_SIZE 	  in BNE_PARAM_DEFNS_B.MAX_SIZE%type,
				P_DISPLAY_TYPE 	  in BNE_PARAM_DEFNS_B.DISPLAY_TYPE%type,
				P_DISPLAY_STYLE   in BNE_PARAM_DEFNS_B.DISPLAY_STYLE%type,
				P_DISPLAY_SIZE 	  in BNE_PARAM_DEFNS_B.DISPLAY_SIZE%type,
				P_USER_NAME	  	  in BNE_PARAM_DEFNS_TL.USER_NAME%type)

		RETURN BNE_PARAM_DEFNS_B.PARAM_DEFN_CODE%type AS VN_KEY BNE_PARAM_DEFNS_B.PARAM_DEFN_CODE%type;

BEGIN

	VN_KEY := CREATE_PARAM_ALL( FND_GLOBAL.RESP_APPL_ID, P_PARAM_CODE,P_PARAM_NAME,P_PARAM_SOURCE,P_CATEGORY,P_DATA_TYPE,NULL,
				  NULL,NULL, P_REQUIRED,P_VISIBLE,P_MODIFYABLE,P_DEFAULT_STRING,P_DEFAULT_DATE,P_DEFAULT_NUM,P_DEFAULT_BOOLEAN,NULL,P_VAL_TYPE,
				  NULL,P_MAXIMUM_SIZE,P_DISPLAY_TYPE,P_DISPLAY_STYLE,P_DISPLAY_SIZE,NULL,NULL,NULL,NULL,NULL,
				  P_USER_NAME,NULL,NULL);

	RETURN (VN_KEY);

END CREATE_PARAM_MINIMAL;




--------------------------------------------------------------------------------
--  FUNCTION:             GET_NEXT_ITEM_SEQ                                   --
--                                                                            --
--  DESCRIPTION:          For a parameter list you can add items. Gets the    --
--  			  		  next seq number     		      --
--                                                                            --
--  PARAMETERS:           parameter list id                                   --
--					 				      --
--  RETURN: 	          seq number or 1 if new list                         --
--                                                                            --
--  MODIFICATION HISTORY                                                      --
--  Date       Username  Description                                          --
--  8-May-02   KDOBINSO  CREATED                                              --
--  7-Oct-02   KDOBINSO  UPDATED FOR WEB ADI REPOSITORY CHANGE                  --
--------------------------------------------------------------------------------


FUNCTION GET_NEXT_ITEM_SEQ (	P_APPLICATION_ID  in BNE_PARAM_LIST_ITEMS.APPLICATION_ID%type,
                              P_PARAM_LIST_CODE in BNE_PARAM_LIST_ITEMS.PARAM_LIST_CODE%type)
	RETURN BNE_PARAM_LIST_ITEMS.SEQUENCE_NUM%type AS VN_SEQ_NUM BNE_PARAM_LIST_ITEMS.SEQUENCE_NUM%type;


BEGIN
	SELECT MAX(SEQUENCE_NUM)
	INTO VN_SEQ_NUM
	FROM BNE_PARAM_LIST_ITEMS
	WHERE PARAM_LIST_CODE = P_PARAM_LIST_CODE
	AND APPLICATION_ID = P_APPLICATION_ID;


	IF(VN_SEQ_NUM IS NOT NULL) THEN
		VN_SEQ_NUM := VN_SEQ_NUM +1;
	ELSE
		VN_SEQ_NUM := 1;
	END IF;


	RETURN (VN_SEQ_NUM);

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			VN_SEQ_NUM := 1;
			RETURN (VN_SEQ_NUM);

END GET_NEXT_ITEM_SEQ;



END BNE_PARAMETER_UTILS;
/