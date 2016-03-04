CREATE OR REPLACE PACKAGE Bil_PR_UPLOAD_PKG AS

g_miss_char varchar2(1) := NULL;
g_miss_num  number      := NULL;
g_miss_date date        := NULL;
g_interface_source_code varchar2(30):='MXM';
g_source_type_code varchar2(30):='Vendor';
g_destination_type_code varchar2(30):='EXPENSE';
g_authorization_status varchar2(30):='APPROVED';

TYPE PR_Rec_Type IS RECORD
( PR_NUM               NUMBER := G_MISS_NUM,
  PR_DESC              VARCHAR2(200) :=G_MISS_CHAR,
  REQ_TYPE             VARCHAR2(200) :='Purchase Requisition',
  PREPARER             VARCHAR2(200) :=G_MISS_CHAR,
  STATUS               VARCHAR2(30) := G_MISS_CHAR,
  MAXIMO_WORK_ORDER    NUMBER:= G_MISS_NUM,
  MAXIMO_PR_NUMBER     NUMBER :=G_MISS_NUM,
  OPERATING_UNIT       NUMBER :=G_MISS_NUM,
  CREATION_DATE        DATE :=G_MISS_DATE,
  LINE_NUM             NUMBER :=G_MISS_NUM ,
  LINE_TYPE            VARCHAR2(60):=G_MISS_CHAR,
  PR_LINE_DESC         VARCHAR2(200):=G_MISS_CHAR,
  ITEM                 NUMBER :=G_MISS_NUM,
  ITEM_CATEGORY        VARCHAR2(200):= G_MISS_CHAR,
  UOM                  VARCHAR2(30):=G_MISS_CHAR,
  QUANTITY             NUMBER :=G_MISS_NUM,
  PRICE                NUMBER:=G_MISS_NUM,
  NEED_BY_DATE         DATE :=G_MISS_DATE,
  CURRENCY             VARCHAR2(30) :='INR',
  DESTINATION          NUMBER :=G_MISS_NUM,
  REQUESTER            VARCHAR2(100):=G_MISS_CHAR,
  ORGANIZATION_CODE    VARCHAR2(100):=G_MISS_CHAR,
  SOURCE               VARCHAR2(30):='MXM',
  VENDOR_ID            NUMBER := G_MISS_NUM,
  VENDOR_SITE_ID       NUMBER := G_MISS_NUM,
  LOCATION_ID          NUMBER :=G_MISS_NUM,
  CONTACT              VARCHAR2(200) := G_MISS_NUM,
  PROCESS_FLAG         VARCHAR2(30):=G_MISS_CHAR ,
  CHARGE_ACCOUNT_D     VARCHAR2(60):=G_MISS_CHAR,
  ACCRUAL_ACCOUNT_D    VARCHAR2(60):=G_MISS_CHAR,
  VARIANCE_ACCOUNT     VARCHAR2(60):=G_MISS_CHAR,
  ERROR_MESSAGE        VARCHAR2(60):=G_MISS_CHAR,
  PREPARER_ID          NUMBER := G_MISS_NUM,
  REQUESTER_ID         NUMBER := G_MISS_NUM,
  CREATED_BY           NUMBER :=G_MISS_NUM,
  LAST_UPDATE_DATE     DATE :=G_MISS_DATE,
  LAST_UPDATED_BY      VARCHAR2(60):=G_MISS_CHAR,
  STAGING_ID           NUMBER := G_MISS_NUM,
  CODE_COMBINATION_ID  NUMBER := G_MISS_NUM,
  ORGANIZATION_ID      NUMBER := G_MISS_NUM,
  VENDOR_NAME          VARCHAR2(100):=G_MISS_CHAR,
  VENDOR_SITE_CODE     VARCHAR2(100):=G_MISS_CHAR
  

);

TYPE PR_Tbl_Type IS TABLE OF PR_Rec_Type
    INDEX BY BINARY_INTEGER;

--  Variables representing missing records and tables

G_PR_Tbl_Type     PR_Tbl_Type;

 PROCEDURE dummy_proc (
      p_item_id                 NUMBER DEFAULT NULL,
      p_organization_id         NUMBER DEFAULT NULL,
      ERROR_CODE          OUT   VARCHAR2,
      error_message       OUT   VARCHAR2,
      error_severity      OUT   NUMBER,
      error_status        OUT   NUMBER
   );
   
PROCEDURE BIL_PRINT_MSG(p_msg in varchar2);

 PROCEDURE bil_item_integration (
      p_item_id                 NUMBER DEFAULT NULL,
      p_organization_id         NUMBER DEFAULT NULL,
      ref_data            OUT   sys_refcursor
   );
   
PROCEDURE BIL_PR_INTRFCE_UPLOAD (p_pr_rec IN PR_Tbl_Type:=G_PR_Tbl_Type);

END Bil_PR_UPLOAD_PKG;