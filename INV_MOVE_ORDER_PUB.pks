CREATE OR REPLACE PACKAGE INV_Move_Order_PUB AUTHID CURRENT_USER AS
/* $Header: INVPTROS.pls 115.17.115100.3 2004/12/07 10:59:21 amohamme ship $ */
/*#
 * Use these procedures to create and process Move Order Headers and Lines
 * @rep:scope public
 * @rep:product INV
 * @rep:lifecycle active
 * @rep:displayname Move Order API
 * @rep:category BUSINESS_ENTITY INV_MOVE_ORDER
 */
-------------------------------------------------------------------------------
-- Record types for move order header and move order lines
-------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--  Trohdr record type
--  Record type to hold a move order header record
--------------------------------------------------------------------------------

g_miss_char varchar2(1) := fnd_api.g_miss_char;
g_miss_num  number      := fnd_api.g_miss_num;
g_miss_date date        := fnd_api.g_miss_date;

TYPE Trohdr_Rec_Type IS RECORD
(   attribute1                    VARCHAR2(150)  := G_MISS_CHAR
,   attribute10                   VARCHAR2(150)  := G_MISS_CHAR
,   attribute11                   VARCHAR2(150)  := G_MISS_CHAR
,   attribute12                   VARCHAR2(150)  := G_MISS_CHAR
,   attribute13                   VARCHAR2(150)  := G_MISS_CHAR
,   attribute14                   VARCHAR2(150)  := G_MISS_CHAR
,   attribute15                   VARCHAR2(150)  := G_MISS_CHAR
,   attribute2                    VARCHAR2(150)  := G_MISS_CHAR
,   attribute3                    VARCHAR2(150)  := G_MISS_CHAR
,   attribute4                    VARCHAR2(150)  := G_MISS_CHAR
,   attribute5                    VARCHAR2(150)  := G_MISS_CHAR
,   attribute6                    VARCHAR2(150)  := G_MISS_CHAR
,   attribute7                    VARCHAR2(150)  := G_MISS_CHAR
,   attribute8                    VARCHAR2(150)  := G_MISS_CHAR
,   attribute9                    VARCHAR2(150)  := G_MISS_CHAR
,   attribute_category            VARCHAR2(30)   := G_MISS_CHAR
,   created_by                    NUMBER         := G_MISS_NUM
,   creation_date                 DATE           := G_MISS_DATE
,   date_required                 DATE           := G_MISS_DATE
,   description                   VARCHAR2(240)  := G_MISS_CHAR
,   from_subinventory_code        VARCHAR2(10)   := G_MISS_CHAR
,   header_id                     NUMBER         := G_MISS_NUM
,   header_status                 NUMBER         := G_MISS_NUM
,   last_updated_by               NUMBER         := G_MISS_NUM
,   last_update_date              DATE           := G_MISS_DATE
,   last_update_login             NUMBER         := G_MISS_NUM
,   organization_id               NUMBER         := G_MISS_NUM
,   program_application_id        NUMBER         := G_MISS_NUM
,   program_id                    NUMBER         := G_MISS_NUM
,   program_update_date           DATE           := G_MISS_DATE
,   request_id                    NUMBER         := G_MISS_NUM
,   request_number                VARCHAR2(30)   := G_MISS_CHAR
,   status_date                   DATE           := G_MISS_DATE
,   to_account_id                 NUMBER         := G_MISS_NUM
,   to_subinventory_code          VARCHAR2(10)   := G_MISS_CHAR
,   move_order_type	          NUMBER         := G_MISS_NUM
,   transaction_type_id		  NUMBER	 := G_MISS_NUM
,   grouping_rule_id		  NUMBER	 := G_MISS_NUM
,   ship_to_location_id           NUMBER         := G_MISS_NUM
,   return_status                 VARCHAR2(1)    := G_MISS_CHAR
,   db_flag                       VARCHAR2(1)    := G_MISS_CHAR
,   operation                     VARCHAR2(30)   := G_MISS_CHAR
);


TYPE Trohdr_Tbl_Type IS TABLE OF Trohdr_Rec_Type
    INDEX BY BINARY_INTEGER;

--  Trohdr value record type

TYPE Trohdr_Val_Rec_Type IS RECORD
(   from_subinventory             VARCHAR2(240)  := FND_API.G_MISS_CHAR
,   header                        VARCHAR2(240)  := FND_API.G_MISS_CHAR
,   organization                  VARCHAR2(240)  := FND_API.G_MISS_CHAR
,   to_account                    VARCHAR2(2000)  := FND_API.G_MISS_CHAR
,   to_subinventory               VARCHAR2(240)  := FND_API.G_MISS_CHAR
,   move_order_type               VARCHAR2(240)  := FND_API.G_MISS_CHAR
,   transaction_type		  VARCHAR2(240)  := FND_API.G_MISS_CHAR
);

TYPE Trohdr_Val_Tbl_Type IS TABLE OF Trohdr_Val_Rec_Type
    INDEX BY BINARY_INTEGER;

--  Trolin record type

TYPE Trolin_Rec_Type IS RECORD
(   attribute1                    VARCHAR2(150)  := FND_API.G_MISS_CHAR
,   attribute10                   VARCHAR2(150)  := FND_API.G_MISS_CHAR
,   attribute11                   VARCHAR2(150)  := FND_API.G_MISS_CHAR
,   attribute12                   VARCHAR2(150)  := FND_API.G_MISS_CHAR
,   attribute13                   VARCHAR2(150)  := FND_API.G_MISS_CHAR
,   attribute14                   VARCHAR2(150)  := FND_API.G_MISS_CHAR
,   attribute15                   VARCHAR2(150)  := FND_API.G_MISS_CHAR
,   attribute2                    VARCHAR2(150)  := FND_API.G_MISS_CHAR
,   attribute3                    VARCHAR2(150)  := FND_API.G_MISS_CHAR
,   attribute4                    VARCHAR2(150)  := FND_API.G_MISS_CHAR
,   attribute5                    VARCHAR2(150)  := FND_API.G_MISS_CHAR
,   attribute6                    VARCHAR2(150)  := FND_API.G_MISS_CHAR
,   attribute7                    VARCHAR2(150)  := FND_API.G_MISS_CHAR
,   attribute8                    VARCHAR2(150)  := FND_API.G_MISS_CHAR
,   attribute9                    VARCHAR2(150)  := FND_API.G_MISS_CHAR
,   attribute_category            VARCHAR2(30)   := FND_API.G_MISS_CHAR
,   created_by                    NUMBER         := FND_API.G_MISS_NUM
,   creation_date                 DATE           := FND_API.G_MISS_DATE
,   date_required                 DATE           := FND_API.G_MISS_DATE
,   from_locator_id               NUMBER         := FND_API.G_MISS_NUM
,   from_subinventory_code        VARCHAR2(10)   := FND_API.G_MISS_CHAR
,   from_subinventory_id          NUMBER         := FND_API.G_MISS_NUM
,   header_id                     NUMBER         := FND_API.G_MISS_NUM
,   inventory_item_id             NUMBER         := FND_API.G_MISS_NUM
,   last_updated_by               NUMBER         := FND_API.G_MISS_NUM
,   last_update_date              DATE           := FND_API.G_MISS_DATE
,   last_update_login             NUMBER         := FND_API.G_MISS_NUM
,   line_id                       NUMBER         := FND_API.G_MISS_NUM
,   line_number                   NUMBER         := FND_API.G_MISS_NUM
,   line_status                   NUMBER         := FND_API.G_MISS_NUM
,   lot_number                    VARCHAR2(30)   := FND_API.G_MISS_CHAR
,   organization_id               NUMBER         := FND_API.G_MISS_NUM
,   program_application_id        NUMBER         := FND_API.G_MISS_NUM
,   program_id                    NUMBER         := FND_API.G_MISS_NUM
,   program_update_date           DATE           := FND_API.G_MISS_DATE
,   project_id                    NUMBER         := FND_API.G_MISS_NUM
,   quantity                      NUMBER         := FND_API.G_MISS_NUM
,   quantity_delivered            NUMBER         := FND_API.G_MISS_NUM
,   quantity_detailed             NUMBER         := FND_API.G_MISS_NUM
,   reason_id                     NUMBER         := FND_API.G_MISS_NUM
,   reference                     VARCHAR2(240)  := FND_API.G_MISS_CHAR
,   reference_id                  NUMBER         := FND_API.G_MISS_NUM
,   reference_type_code           NUMBER         := FND_API.G_MISS_NUM
,   request_id                    NUMBER         := FND_API.G_MISS_NUM
,   revision                      VARCHAR2(3)    := FND_API.G_MISS_CHAR
,   serial_number_end             VARCHAR2(30)   := FND_API.G_MISS_CHAR
,   serial_number_start           VARCHAR2(30)   := FND_API.G_MISS_CHAR
,   status_date                   DATE           := FND_API.G_MISS_DATE
,   task_id                       NUMBER         := FND_API.G_MISS_NUM
,   to_account_id                 NUMBER         := FND_API.G_MISS_NUM
,   to_locator_id                 NUMBER         := FND_API.G_MISS_NUM
,   to_subinventory_code          VARCHAR2(10)   := FND_API.G_MISS_CHAR
,   to_subinventory_id            NUMBER         := FND_API.G_MISS_NUM
,   transaction_header_id         NUMBER         := FND_API.G_MISS_NUM
,   transaction_type_id		  NUMBER	 := FND_API.G_MISS_NUM
,   txn_source_id		  NUMBER	 := FND_API.G_MISS_NUM
,   txn_source_line_id		  NUMBER	 := FND_API.G_MISS_NUM
,   txn_source_line_detail_id	  NUMBER	 := FND_API.G_MISS_NUM
,   transaction_source_type_id	  NUMBER	 := FND_API.G_MISS_NUM
,   primary_quantity		  NUMBER	 := FND_API.G_MISS_NUM
,   to_organization_id		  NUMBER	 := FND_API.G_MISS_NUM
,   pick_strategy_id		  NUMBER	 := FND_API.G_MISS_NUM
,   put_away_strategy_id	  NUMBER	 := FND_API.G_MISS_NUM
,   uom_code                      VARCHAR2(3)    := FND_API.G_MISS_CHAR
,   unit_number			  VARCHAR2(30)	 := FND_API.G_MISS_CHAR
,   ship_to_location_id           NUMBER         := FND_API.G_MISS_NUM
,   from_cost_group_id		  NUMBER	 := FND_API.G_MISS_NUM
,   to_cost_group_id		  NUMBER	 := FND_API.G_MISS_NUM
,   lpn_id			  NUMBER	 := FND_API.G_MISS_NUM
,   to_lpn_id			  NUMBER	 := FND_API.G_MISS_NUM
,   pick_methodology_id		  NUMBER	 := FND_API.G_MISS_NUM
,   container_item_id		  NUMBER	 := FND_API.G_MISS_NUM
,   carton_grouping_id		  NUMBER	 := FND_API.G_MISS_NUM
,   return_status                 VARCHAR2(1)    := FND_API.G_MISS_CHAR
,   db_flag                       VARCHAR2(1)    := FND_API.G_MISS_CHAR
,   operation                     VARCHAR2(30)   := FND_API.G_MISS_CHAR
,   inspection_status             NUMBER         :=NULL
,   wms_process_flag              NUMBER         :=NULL
,   pick_slip_number              NUMBER         :=NULL
,   pick_slip_date                DATE           :=NULL
,   ship_set_id                   NUMBER         :=NULL
,   ship_model_id                 NUMBER         :=NULL
,   model_quantity                NUMBER         :=NULL
,   required_quantity             NUMBER         :=NULL);

TYPE Trolin_Tbl_Type IS TABLE OF Trolin_Rec_Type
    INDEX BY BINARY_INTEGER;

--  Trolin value record type

TYPE Trolin_Val_Rec_Type IS RECORD
(   from_locator                  VARCHAR2(2000)  := FND_API.G_MISS_CHAR
,   from_subinventory             VARCHAR2(240)  := FND_API.G_MISS_CHAR
,   header                        VARCHAR2(240)  := FND_API.G_MISS_CHAR
,   inventory_item                VARCHAR2(2000)  := FND_API.G_MISS_CHAR
,   line                          VARCHAR2(240)  := FND_API.G_MISS_CHAR
,   organization                  VARCHAR2(240)  := FND_API.G_MISS_CHAR
,   project                       VARCHAR2(240)  := FND_API.G_MISS_CHAR
,   reason                        VARCHAR2(240)  := FND_API.G_MISS_CHAR
,   reference                     VARCHAR2(240)  := FND_API.G_MISS_CHAR
,   reference_type                VARCHAR2(240)  := FND_API.G_MISS_CHAR
,   task                          VARCHAR2(240)  := FND_API.G_MISS_CHAR
,   to_account                    VARCHAR2(2000)  := FND_API.G_MISS_CHAR
,   to_locator                    VARCHAR2(2000)  := FND_API.G_MISS_CHAR
,   to_subinventory               VARCHAR2(240)  := FND_API.G_MISS_CHAR
,   transaction_header            VARCHAR2(240)  := FND_API.G_MISS_CHAR
,   uom                           VARCHAR2(240)  := FND_API.G_MISS_CHAR
,   transaction_type		  VARCHAR2(240)  := FND_API.G_MISS_CHAR
,   to_organization		  VARCHAR2(240)  := FND_API.G_MISS_CHAR
);

TYPE Trolin_Val_Tbl_Type IS TABLE OF Trolin_Val_Rec_Type
    INDEX BY BINARY_INTEGER;

--  Variables representing missing records and tables

G_MISS_TROHDR_REC             Trohdr_Rec_Type;
G_MISS_TROHDR_VAL_REC         Trohdr_Val_Rec_Type;
G_MISS_TROHDR_TBL             Trohdr_Tbl_Type;
G_MISS_TROHDR_VAL_TBL         Trohdr_Val_Tbl_Type;
G_MISS_TROLIN_REC             Trolin_Rec_Type;
G_MISS_TROLIN_VAL_REC         Trolin_Val_Rec_Type;
G_MISS_TROLIN_TBL             Trolin_Tbl_Type;
G_MISS_TROLIN_VAL_TBL         Trolin_Val_Tbl_Type;


--global variables used in parameter p_validation_flag
g_validation_yes VARCHAR2(1) := 'Y';
g_validation_no VARCHAR2(1) := 'N';


-------------------------------------------------------------------------------
-- Procedures and Functions
-------------------------------------------------------------------------------

--  Procedures
--   	Create_Move_Order_Header
--  Input Parameters
--	p_api_version_number	API version number (current version is 1.0)
--
--	p_init_msg_list		Valid values: FND_API.G_FALSE or FND_API.G_TRUE.
--				if set to FND_API.G_TRUE
--					initialize error message list
--			        if set to FND_API.G_FALSE - not initialize error
--					message list
--	p_return_values		valid values: FND_API.G_FALSE or FND_API.G_TRUE
--	p_commit		whether or not to commit the changes to database
--	p_trohdr_rec		record contains information to be used to create the
--				move order header
--	p_trohdr_val_rec	contains information values as supposed to internal
--				IDs used to create the move order header
--
--  Output Parameter:
--  	x_return_status		= FND_API.G_RET_STS_SUCCESS, if succeeded
--				= FND_API.G_RET_STS_EXC_ERROR, if an expected error occured
--				= FND_API.G_RET_STS_UNEXP_ERROR, if an unexpected error occured
--
--	x_msg_count		Number of error message in the error message list
--
--	x_msg_data		If the number of error message in the error message list is one,
--				the error message is in the output parameter
--
--	x_trohdr_rec		The information of move order header that got created
--
--	x_trohdr_val_Rec	The information values of move order header that got created
--
--  Example
--	The following code creates a move order header with the following information:
--	   organization_id 	207
--	   default from_subinventory_code 'FGI'
--	   default to_subinventory_code   'Stores'
-- 	   move_order_type	1 (Move Order Requisition)
--	   default transaction_type : subinventory_transfer
--	   header_status 	preapproved
--
-- declare
--    l_trohdr_rec            INV_Move_Order_PUB.Trohdr_Rec_Type;
--    l_return_status         VARCHAR2(1):= FND_API.G_RET_STS_SUCCESS;
--    l_msg_count             NUMBER;
--    l_msg_data              VARCHAR2(240);
--    l_trohdr_val_rec        INV_Move_Order_PUB.Trohdr_Val_Rec_Type;
--    l_commit                VARCHAR2(1) := FND_API.G_TRUE;
-- begin
--    l_trohdr_rec.created_by                 :=  1068;
--    l_trohdr_rec.creation_date              :=  sysdate;
--    l_trohdr_rec.date_required              :=  sysdate;
--    l_trohdr_rec.from_subinventory_code     :=  'FGI';
--    l_trohdr_rec.header_status     	      :=  INV_Globals.G_TO_STATUS_PREAPPROVED;
--    l_trohdr_rec.last_updated_by            :=   1068;
--    l_trohdr_rec.last_update_date           :=   sysdate;
--    l_trohdr_rec.last_update_login          :=   1068;
--    l_trohdr_rec.organization_id            :=   207;
--    l_trohdr_rec.status_date                :=   sysdate;
--    l_trohdr_rec.to_subinventory_code       :=   'Stores';
--    l_trohdr_rec.transaction_type_id        :=   INV_GLOBALS.G_TYPE_TRANSFER_ORDER_SUBXFR;
--    l_trohdr_rec.move_order_type	      :=   INV_GLOBALS.G_MOVE_ORDER_REQUISITION;
--    l_trohdr_rec.db_flag                    :=   FND_API.G_TRUE;
--    l_trohdr_rec.operation                  :=   INV_GLOBALS.G_OPR_CREATE;
--
--    INV_Move_Order_PUB.Create_Move_Order_Header(
--         p_api_version_number => 1,
--         p_init_msg_list => FND_API.G_FALSE,
--         p_return_values => FND_API.G_TRUE,
--         p_commit => l_commit,
--         x_return_status => l_return_status,
--         x_msg_count => l_msg_count,
--         x_msg_data => msg,
--         p_trohdr_rec => l_trohdr_rec,
--         p_trohdr_val_rec => l_trohdr_val_rec,
--         x_trohdr_rec    => l_trohdr_rec,
--         x_trohdr_val_rec => l_trohdr_val_rec
--     );
--
--     IF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
--             FND_MSG_PUB.Add_Exc_Msg
--             (   'INV_Move_Order_PUB'
--             ,   'Create_move_orders'
--             );
--         RAISE FND_API.G_EXC_ERROR;
--     ELSIF l_return_status = FND_API.G_RET_STS_ERROR THEN
--             FND_MSG_PUB.Add_Exc_Msg
--             (   'INV_Move_Order_PUB'
--             ,   'Create_move_orders'
--             );
--         RAISE FND_API.G_EXC_ERROR;
--     END IF;
--     dbms_output.put_line(l_return_status);
-- EXCEPTION
--
--     WHEN FND_API.G_EXC_ERROR THEN
--
--        Raise FND_API.G_EXC_ERROR;
--
--     WHEN OTHERS THEN
--         IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
--         THEN
--             FND_MSG_PUB.Add_Exc_Msg
--             (   'INV_Move_Order_PUB'
--             ,   'Create_Move_Orders'
--             );
--         END IF;
--        Raise FND_API.G_EXC_UNEXPECTED_ERROR;
-- end;
--
--  Version     Current version = 1.0
--              Initial version = 1.0
--
--  End of Comments

/*#
 * Use this procedure to create a new Move order Header.
 * @param p_api_version_number API version is passed as input in this variable
 * @paraminfo {@rep:required}
 * @param p_init_msg_list fnd_api.g_false or fnd_api.g_true is passed as input in this variable to determine whether to Initialize message list or not
 * @paraminfo {@rep:required}
 * @param p_return_values fnd_api.g_false or fnd_api.g_true is passed as input in this variable to determine whether to commit or not
 * @paraminfo {@rep:required}
 * @param p_commit fnd_api.g_false or fnd_api.g_true is passed as input in this variable to determine whether to commit or not
 * @paraminfo {@rep:required}
 * @param x_return_status Return Status indiacation success or failure.
 * @paraminfo {@rep:required}
 * @param x_msg_count message count from the error stack in case of failure
 * @paraminfo {@rep:required}
 * @param x_msg_data x_msg_data Return the error message in case of failure
 * @paraminfo {@rep:required}
 * @param p_trohdr_rec The record that contains the information to be used to create the move order header is passed as input in this variable
 * @paraminfo {@rep:required}
 * @param p_trohdr_val_rec The record that contains the information values to be used to create the move order header is passed as input in this variable
 * @paraminfo {@rep:required}
 * @param x_trohdr_rec Return the record containing information of the move order header created
 * @paraminfo {@rep:required}
 * @param x_trohdr_val_rec Return the record containing information values of the move order header created
 * @paraminfo {@rep:required}
 * @param p_validation_flag flag specifying the data needds to be validated or not is passed as input in this variable
 * @rep:scope public
 * @rep:lifecycle active
 * @rep:displayname Create Move Order header
 */
PROCEDURE Create_Move_Order_Header
(   p_api_version_number            IN  NUMBER
,   p_init_msg_list                 IN  VARCHAR2 := FND_API.G_FALSE
,   p_return_values                 IN  VARCHAR2 := FND_API.G_FALSE
,   p_commit                        IN  VARCHAR2 := FND_API.G_FALSE
,   x_return_status                 OUT NOCOPY VARCHAR2
,   x_msg_count                     OUT NOCOPY NUMBER
,   x_msg_data                      OUT NOCOPY VARCHAR2
,   p_trohdr_rec                    IN  Trohdr_Rec_Type :=
                                        G_MISS_TROHDR_REC
,   p_trohdr_val_rec                IN  Trohdr_Val_Rec_Type :=
                                        G_MISS_TROHDR_VAL_REC
,   x_trohdr_rec                    IN OUT NOCOPY Trohdr_Rec_Type
,   x_trohdr_val_rec                IN OUT NOCOPY Trohdr_Val_Rec_Type
,   p_validation_flag		    IN VARCHAR2 DEFAULT g_validation_yes
);

--  Start of Comments
--  Procedures
--   	Create_Move_Order_Lines
--  Input Parameters
--	p_api_version_number	API version number (current version is 1.0)
--
--	p_init_msg_list		Valid values: FND_API.G_FALSE or FND_API.G_TRUE.
--				if set to FND_API.G_TRUE
--					initialize error message list
--			        if set to FND_API.G_FALSE - not initialize error
--					message list
--	p_return_values		valid values: FND_API.G_FALSE or FND_API.G_TRUE
--	p_commit		whether or not to commit the changes to database
--	p_trolin_tbl		a table of records contains information to be used to
--				create the move order lines
--	p_trohdr_val_tbl	contains information values as supposed to internal
--				IDs used to create the move order lines
--
--  Output Parameter:
--  	x_return_status		= FND_API.G_RET_STS_SUCCESS, if succeeded
--				= FND_API.G_RET_STS_EXC_ERROR, if an expected error occured
--				= FND_API.G_RET_STS_UNEXP_ERROR, if an unexpected error occured
--
--	x_msg_count		Number of error message in the error message list
--
--	x_msg_data		If the number of error message in the error message list is one,
--				the error message is in the output parameter
--
--	x_trohdr_tbl		The information of move order lines that got created
--
--	x_trohdr_val_tbl	The information values of move order lines that got created
--
--  Example
--	The following code creates a move order header with the following information:
--	   header_id 		4125 - this header_id is the header number for the move order
--				header that got genereated when the create_move_order_header
--				is executed
--	   organization_id 	207
--	   inventory_item_id    155
--	   from_subinventory_code 'FGI'
--	   to_subinventory_code   'Stores'
--	   line_status 	preapproved
--
-- declare
--    l_trolin_tbl            INV_Move_Order_PUB.Trolin_Tbl_Type;
--    l_return_status         VARCHAR2(1):= FND_API.G_RET_STS_SUCCESS;
--    l_msg_count             NUMBER;
--    l_msg_data              VARCHAR2(240);
--    l_trohdr_val_rec        INV_Move_Order_PUB.Trolin_Val_Tbl_Type;
--    l_commit                VARCHAR2(1) := FND_API.G_TRUE;
--    l_order_count	      NUMBER := 1; /* total number of lines */
-- begin
--   l_line_num := l_line_num + 1;
--   l_trolin_tbl(l_order_count).header_id           := l_trohdr_rec.header_id;
--   l_trolin_tbl(l_order_count).created_by          := FND_GLOBAL.USER_ID;
--   l_trolin_tbl(l_order_count).creation_date       := sysdate;
--   l_trolin_tbl(l_order_count).date_required       := sysdate;
--   l_trolin_tbl(l_order_count).from_subinventory_code     := 'FGI';
--   l_trolin_tbl(l_order_count).inventory_item_id  := 155;
--   l_trolin_tbl(l_order_count).last_updated_by    := FND_GLOBAL.USER_ID;
--   l_trolin_tbl(l_order_count).last_update_date   := sysdate;
--   l_trolin_tbl(l_order_count).last_update_login  := FND_GLOBAL.LOGIN_ID;
--   l_trolin_tbl(l_order_count).line_id            := FND_API.G_MISS_NUM;
--   l_trolin_tbl(l_order_count).line_number        := l_line_num;
--   l_trolin_tbl(l_order_count).line_status        :=
--                                        INV_Globals.G_TO_STATUS_PREAPPROVED;
--   l_trolin_tbl(l_order_count).organization_id    := 207;
--   l_trolin_tbl(l_order_count).quantity           := 100;
--   l_trolin_tbl(l_order_count).status_date        := sysdate;
--   l_trolin_tbl(l_order_count).to_subinventory_code   := 'Stores';
--   l_trolin_tbl(l_order_count).uom_code     := 'Ea';
--   l_trolin_tbl(l_order_count).db_flag      := FND_API.G_TRUE;
--   l_trolin_tbl(l_order_count).operation    := INV_GLOBALS.G_OPR_CREATE;

--/*inv_debug.message('calling inv_transfer_order_pvt.process_transfer_order');*/
--    INV_Move_Order_PUB.Create_Move_Order_Lines
--        (  p_api_version_number       => 1.0 ,
--           p_init_msg_list            => 'T',
--           p_commit                   => FND_API.G_TRUE,
--           x_return_status            => l_return_status,
--           x_msg_count                => l_msg_count,
--           x_msg_data                 => l_msg_data,
--           p_trolin_tbl               => l_trolin_tbl,
--           p_trolin_val_tbl           => l_trolin_val_tbl,
--           x_trolin_tbl               => l_trolin_tbl,
--           x_trolin_val_tbl           => l_trolin_val_tbl
--        );
--
--    l_trohdr_rec.db_flag                    :=   FND_API.G_TRUE;
--    l_trohdr_rec.operation                  :=   INV_GLOBALS.G_OPR_CREATE;
--
--     IF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
--             FND_MSG_PUB.Add_Exc_Msg
--             (   'INV_Move_Order_PUB'
--             ,   'Create_move_orders'
--             );
--         RAISE FND_API.G_EXC_ERROR;
--     ELSIF l_return_status = FND_API.G_RET_STS_ERROR THEN
--             FND_MSG_PUB.Add_Exc_Msg
--             (   'INV_Move_Order_PUB'
--             ,   'Create_move_orders'
--             );
--         RAISE FND_API.G_EXC_ERROR;
--     END IF;
--     dbms_output.put_line(l_return_status);
-- EXCEPTION
--
--     WHEN FND_API.G_EXC_ERROR THEN
--
--        Raise FND_API.G_EXC_ERROR;
--
--     WHEN OTHERS THEN
--         IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
--        THEN
--            FND_MSG_PUB.Add_Exc_Msg
--            (   'INV_Move_Order_PUB'
--            ,   'Create_Move_Orders'
--            );
--        END IF;
--       Raise FND_API.G_EXC_UNEXPECTED_ERROR;
--end;
--
--  Version     Current version = 1.0
--              Initial version = 1.0
--
--  End of Comments
/*#
 * Use this procedure to create a move order line for a given move order header.
 * @param p_api_version_number API version is passed as input in this variable
 * @paraminfo {@rep:required}
 * @param p_init_msg_list fnd_api.g_false or fnd_api.g_true is passed as input in this variable to determine whether to Initialize message list or not
 * @paraminfo {@rep:required}
 * @param p_return_values fnd_api.g_false or fnd_api.g_true is passed as input in this variable to determine whether to commit or not
 * @paraminfo {@rep:required}
 * @param p_commit fnd_api.g_false or fnd_api.g_true is passed as input in this variable to determine whether to commit or not
 * @paraminfo {@rep:required}
 * @param x_return_status Return Status indiacation success or failure.
 * @paraminfo {@rep:required}
 * @param x_msg_count message count from the error stack in case of failure
 * @paraminfo {@rep:required}
 * @param x_msg_data x_msg_data Return the error message in case of failure
 * @paraminfo {@rep:required}
 * @param p_trolin_tbl The record that contains the information to be used to create the move order line is passed as input in this variable
 * @paraminfo {@rep:required}
 * @param p_trolin_val_tbl The record that contains the information values to be used to create the move order line is passed as input in this variable
 * @paraminfo {@rep:required}
 * @param x_trolin_tbl Return the record containing information of the move order line created
 * @paraminfo {@rep:required}
 * @param x_trolin_val_tbl Return the record containing information values of the move order line created
 * @paraminfo {@rep:required}
 * @param p_validation_flag flag specifying the data needds to be validated or not is passed as input in this variable
 * @rep:scope public
 * @rep:lifecycle active
 * @rep:displayname Create Move Order Lines
 */
PROCEDURE Create_Move_Order_Lines
(   p_api_version_number            IN  NUMBER
,   p_init_msg_list                 IN  VARCHAR2 := FND_API.G_FALSE
,   p_return_values                 IN  VARCHAR2 := FND_API.G_FALSE
,   p_commit                        IN  VARCHAR2 := FND_API.G_FALSE
,   x_return_status                 OUT NOCOPY VARCHAR2
,   x_msg_count                     OUT NOCOPY NUMBER
,   x_msg_data                      OUT NOCOPY VARCHAR2
,   p_trolin_tbl                    IN  Trolin_Tbl_Type :=
                                        G_MISS_TROLIN_TBL
,   p_trolin_val_tbl                IN  Trolin_Val_Tbl_Type :=
                                        G_MISS_TROLIN_VAL_TBL
,   x_trolin_tbl                    IN OUT NOCOPY Trolin_Tbl_Type
,   x_trolin_val_tbl                IN OUT NOCOPY Trolin_Val_Tbl_Type
,   p_validation_flag		    IN VARCHAR2  := g_validation_yes
);

--  Procedures
--   	Process_Move_Order_PUB
-- 	This procedure is use to process  move orders (both headers and lines)
--	i.e., to create or update move orders.
--  Input Parameters
--	p_api_version_number	API version number (current version is 1.0)
--
--	p_init_msg_list		Valid values: FND_API.G_FALSE or FND_API.G_TRUE.
--				if set to FND_API.G_TRUE
--					initialize error message list
--			        if set to FND_API.G_FALSE - not initialize error
--					message list
--	p_return_values		valid values: FND_API.G_FALSE or FND_API.G_TRUE
--	p_commit		whether or not to commit the changes to database
--	p_trohdr_rec		record contains information to be used to create the
--				move order header
--	p_trohdr_val_rec	contains information values as supposed to internal
--				IDs used to create the move order header
--	p_trolin_tbl		a table of records contains information to be used to
--				create the move order lines
--	p_trohdr_val_tbl	contains information values as supposed to internal
--				IDs used to create the move order lines
--
--  Output Parameter:
--  	x_return_status		= FND_API.G_RET_STS_SUCCESS, if succeeded
--				= FND_API.G_RET_STS_EXC_ERROR, if an expected error occured
--				= FND_API.G_RET_STS_UNEXP_ERROR, if an unexpected error occured
--
--	x_msg_count		Number of error message in the error message list
--
--	x_msg_data		If the number of error message in the error message list is one,
--				the error message is in the output parameter
--
--	x_trohdr_rec		The information of move order header that got created
--
--	x_trohdr_val_Rec	The information values of move order header that got created
--
--	x_trohdr_tbl		The information of move order lines that got created
--
--	x_trohdr_val_tbl	The information values of move order lines that got created
--
--
--  Example
--	The following code creates a move order header with the following information:
--	   Header Information:
--	   organization_id 	207
--	   default from_subinventory_code 'FGI'
--	   default to_subinventory_code   'Stores'
-- 	   move_order_type	1 (Move Order Requisition)
--	   default transaction_type : subinventory_transfer
--	   header_status 	preapproved
--	   Line Information:
--		inventory_item_id 155
--		from_subinventory_code 'FGI'
--		to_subinventory_code 'Stores'
--		Quantity 100
--		Uom_Code 'Ea'
--		Line_status: preapproved
-- declare
--    l_trohdr_rec            INV_Move_Order_PUB.Trohdr_Rec_Type;
--    l_trolin_tbl            INV_Move_Order_PUB.Trolin_Tbl_Type;
--    l_trolin_val_tbl        INV_Move_Order_PUB.Trolin_Val_Tbl_Type;
--    l_return_status         VARCHAR2(1):= FND_API.G_RET_STS_SUCCESS;
--    l_msg_count             NUMBER;
--    l_msg_data              VARCHAR2(240);
--    msg                     VARCHAR2(2000);
--    l_header_id             Number := FND_API.G_MISS_NUM;
--    l_line_num              Number := 0;
--    l_order_count           NUMBER := 1;
--    l_trohdr_val_rec        INV_Move_Order_PUB.Trohdr_Val_Rec_Type;
--    l_commit                VARCHAR2(1) := FND_API.G_TRUE;
--    p_need_by_date          DATE := sysdate;
--    p_src_subinv            VARCHAR2(30);
-- begin
-- dbms_output.put_line('In create transfer order');
--    l_trohdr_rec.created_by                 :=  1068;
--    l_trohdr_rec.creation_date              :=  sysdate;
--    l_trohdr_rec.date_required              :=  sysdate;
--    l_trohdr_rec.from_subinventory_code     :=  'FGI';
--    l_trohdr_rec.header_status     :=  INV_Globals.G_TO_STATUS_PREAPPROVED;
--    l_trohdr_rec.last_updated_by            :=   1068;
--    l_trohdr_rec.last_update_date           :=   sysdate;
--    l_trohdr_rec.last_update_login          :=   1068;
--    l_trohdr_rec.organization_id            :=   207;
--    l_trohdr_rec.status_date                :=   sysdate;
--    l_trohdr_rec.to_subinventory_code       :=   'Stores';
--    l_trohdr_rec.transaction_type_id        :=   INV_GLOBALS.G_TYPE_TRANSFER_ORDER_SUBXFR;
--    l_trohdr_rec.db_flag                    :=   FND_API.G_TRUE;
--    l_trohdr_rec.operation                  :=   INV_GLOBALS.G_OPR_CREATE;
--
--    l_line_num := l_line_num + 1;
 --   l_trolin_tbl(l_order_count).header_id           := l_trohdr_rec.header_id;
--    l_trolin_tbl(l_order_count).created_by          := FND_GLOBAL.USER_ID;
--    l_trolin_tbl(l_order_count).creation_date       := sysdate;
--    l_trolin_tbl(l_order_count).date_required       := sysdate;
--    l_trolin_tbl(l_order_count).from_subinventory_code     := 'FGI';
--    l_trolin_tbl(l_order_count).inventory_item_id  := 155;
--    l_trolin_tbl(l_order_count).last_updated_by    := FND_GLOBAL.USER_ID;
--    l_trolin_tbl(l_order_count).last_update_date   := sysdate;
--    l_trolin_tbl(l_order_count).last_updated_by    := FND_GLOBAL.USER_ID;
--    l_trolin_tbl(l_order_count).last_update_date   := sysdate;
--    l_trolin_tbl(l_order_count).last_update_login  := FND_GLOBAL.LOGIN_ID;
--    l_trolin_tbl(l_order_count).line_id            := FND_API.G_MISS_NUM;
--    l_trolin_tbl(l_order_count).line_number        := l_line_num;
--    l_trolin_tbl(l_order_count).line_status        :=
--                                         INV_Globals.G_TO_STATUS_PREAPPROVED;
--    l_trolin_tbl(l_order_count).organization_id    := 207;
--    l_trolin_tbl(l_order_count).quantity           := 100;
--    l_trolin_tbl(l_order_count).status_date        := sysdate;
--    l_trolin_tbl(l_order_count).to_subinventory_code   := 'Stores';
--    l_trolin_tbl(l_order_count).uom_code     := 'Ea';
--    l_trolin_tbl(l_order_count).db_flag      := FND_API.G_TRUE;
--    l_trolin_tbl(l_order_count).operation    := INV_GLOBALS.G_OPR_CREATE;
--
-- /*inv_debug.message('calling inv_transfer_order_pvt.process_transfer_order');*/
--     INV_Move_Order_PUB.Process_Move_Order
--         (  p_api_version_number       => 1.0 ,
--            p_init_msg_list            => 'T',
--            p_commit                   => FND_API.G_TRUE,
--            x_return_status            => l_return_status,
--            x_msg_count                => l_msg_count,
--            x_msg_data                 => l_msg_data,
--	      p_trohdr_rec		 => l_trohdr_rec,
--	      p_trohdr_val_rec		 => l_trohdr_val_rec,
--            p_trolin_tbl               => l_trolin_tbl,
--            p_trolin_val_tbl           => l_trolin_val_tbl,
--	      x_trohdr_rec		 => l_trohdr_rec,
--	      x_trohdr_val_rec		 => l_trohdr_val_rec,
--            x_trolin_tbl               => l_trolin_tbl,
--            x_trolin_val_tbl           => l_trolin_val_tbl
--         );
--
--     IF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
--             FND_MSG_PUB.Add_Exc_Msg
--             (   'INV_Move_Order_PUB'
--             ,   'Process_Move_Order'
--             );
--         RAISE FND_API.G_EXC_ERROR;
--     ELSIF l_return_status = FND_API.G_RET_STS_ERROR THEN
--             FND_MSG_PUB.Add_Exc_Msg
--             (   'INV_Move_Order_PUB'
--             ,   'Process_Move_Order'
--             );
--         RAISE FND_API.G_EXC_ERROR;
--     END IF;
--     dbms_output.put_line(l_return_status);
-- EXCEPTION
--
--     WHEN FND_API.G_EXC_ERROR THEN
--
--        Raise FND_API.G_EXC_ERROR;
--
--     WHEN OTHERS THEN
--         IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
--         THEN
--             FND_MSG_PUB.Add_Exc_Msg
--             (   'INV_Move_Order_PUB'
--             ,   'Process_Move_Order'
--             );
--         END IF;
--             );
--         END IF;
--        Raise FND_API.G_EXC_UNEXPECTED_ERROR;
-- end;


--
--
--  Version     Current version = 1.0
--              Initial version = 1.0
--
--  Notes
--
--  End of Comments
/*#
 * Use this procedure to process a move order and its lines. If the move order or
 * lines exist the procedure updates them with the passed values.
 * If no header or line exists, new data will be created for you.
 * @param p_api_version_number API version is passed as input in this variable
 * @paraminfo {@rep:required}
 * @param p_init_msg_list fnd_api.g_false or fnd_api.g_true is passed as input in this variable to determine whether to Initialize message list or not
 * @paraminfo {@rep:required}
 * @param p_return_values fnd_api.g_false or fnd_api.g_true is passed as input in this variable to determine whether to commit or not
 * @paraminfo {@rep:required}
 * @param p_commit fnd_api.g_false or fnd_api.g_true is passed as input in this variable to determine whether to commit or not
 * @paraminfo {@rep:required}
 * @param x_return_status Return Status indiacation success or failure.
 * @paraminfo {@rep:required}
 * @param x_msg_count message count from the error stack in case of failure
 * @paraminfo {@rep:required}
 * @param x_msg_data x_msg_data Return the error message in case of failure
 * @paraminfo {@rep:required}
 * @param p_trohdr_rec The record that contains the information of the move order header is passed as input in this variable
 * @paraminfo {@rep:required}
 * @param p_trohdr_val_rec The record that contains the information values of the move order header is passed as input in this variable
 * @paraminfo {@rep:required}
 * @param p_trolin_tbl The table that contains the information of the move order line is passed as input in this variable
 * @paraminfo {@rep:required}
 * @param p_trolin_val_tbl The table that contains the information values of create the move order line is passed as input in this variable
 * @paraminfo {@rep:required}
 * @param x_trohdr_rec Return the record containing information of the move order header created
 * @paraminfo {@rep:required}
 * @param x_trohdr_val_rec Return the record containing information values of the move order header created
 * @paraminfo {@rep:required}
 * @param x_trolin_tbl Return the table containing information of the move order line created
 * @paraminfo {@rep:required}
 * @param x_trolin_val_tbl Return the table containing information values of the move order line created
 * @paraminfo {@rep:required}
 * @rep:scope public
 * @rep:lifecycle active
 * @rep:displayname Process Move Order
 */
PROCEDURE Process_Move_Order
(   p_api_version_number            IN  NUMBER
,   p_init_msg_list                 IN  VARCHAR2 := FND_API.G_FALSE
,   p_return_values                 IN  VARCHAR2 := FND_API.G_FALSE
,   p_commit                        IN  VARCHAR2 := FND_API.G_FALSE
,   x_return_status                 OUT NOCOPY VARCHAR2
,   x_msg_count                     OUT NOCOPY NUMBER
,   x_msg_data                      OUT NOCOPY VARCHAR2
,   p_trohdr_rec                    IN  Trohdr_Rec_Type :=
                                        G_MISS_TROHDR_REC
,   p_trohdr_val_rec                IN  Trohdr_Val_Rec_Type :=
                                        G_MISS_TROHDR_VAL_REC
,   p_trolin_tbl                    IN  Trolin_Tbl_Type :=
                                        G_MISS_TROLIN_TBL
,   p_trolin_val_tbl                IN  Trolin_Val_Tbl_Type :=
                                        G_MISS_TROLIN_VAL_TBL
,   x_trohdr_rec                    IN OUT NOCOPY Trohdr_Rec_Type
,   x_trohdr_val_rec                IN OUT NOCOPY Trohdr_Val_Rec_Type
,   x_trolin_tbl                    IN OUT NOCOPY Trolin_Tbl_Type
,   x_trolin_val_tbl                IN OUT NOCOPY Trolin_Val_Tbl_Type
);

--  Start of Comments
--  API name    Lock_Move_Order
--  Type        Public
--  Function
--
--  Pre-reqs
--
--  Parameters
--
--  Version     Current version = 1.0
--              Initial version = 1.0
--
--  Notes
--
--  End of Comments

--  Procedures
--   	Create_Move_Order_Header
--  Input Parameters
--	p_api_version_number	API version number (current version is 1.0)
--
--	p_init_msg_list		Valid values: FND_API.G_FALSE or FND_API.G_TRUE.
--				if set to FND_API.G_TRUE
--					initialize error message list
--			        if set to FND_API.G_FALSE - not initialize error
--					message list
--	p_return_values		valid values: FND_API.G_FALSE or FND_API.G_TRUE
--	p_commit		whether or not to commit the changes to database
--	p_trohdr_rec		record contains information to be used to lock the
--				move order header
--	p_trohdr_val_rec	contains information values as supposed to internal
--				IDs used to lock the move order header
--	p_trolin_tbl		a table of records contains information to be used to
--				lock the move order lines
--	p_trohdr_val_tbl	contains information values as supposed to internal
--				IDs used to lock the move order lines
--
--  Output Parameter:
--  	x_return_status		= FND_API.G_RET_STS_SUCCESS, if succeeded
--				= FND_API.G_RET_STS_EXC_ERROR, if an expected error occured
--				= FND_API.G_RET_STS_UNEXP_ERROR, if an unexpected error occured
--
--	x_msg_count		Number of error message in the error message list
--
--	x_msg_data		If the number of error message in the error message list is one,
--				the error message is in the output parameter
--
--	x_trohdr_rec		The information of move order header that got locked
--
--	x_trohdr_val_Rec	The information values of move order header that got locked
--
--	x_trohdr_tbl		The move order lines records that got locked
--
--	x_trohdr_val_tbl	The information values of move order lines record that got locked
--
/*#
 * Use this procedure to lock a move order header and its lines.
 * @param p_api_version_number API version is passed as input in this variable
 * @paraminfo {@rep:required}
 * @param p_init_msg_list fnd_api.g_false or fnd_api.g_true is passed as input in this variable to determine whether to Initialize message list or not
 * @paraminfo {@rep:required}
 * @param p_return_values fnd_api.g_false or fnd_api.g_true is passed as input in this variable to determine whether to commit or not
 * @paraminfo {@rep:required}
 * @param x_return_status Return Status indiacation success or failure.
 * @paraminfo {@rep:required}
 * @param x_msg_count message count from the error stack in case of failure
 * @paraminfo {@rep:required}
 * @param x_msg_data x_msg_data Return the error message in case of failure
 * @paraminfo {@rep:required}
 * @param p_trohdr_rec The record that contains the information of the move order header is passed as input in this variable
 * @paraminfo {@rep:required}
 * @param p_trohdr_val_rec The record that contains the information values of the move order header is passed as input in this variable
 * @paraminfo {@rep:required}
 * @param p_trolin_tbl The table that contains the information of the move order line is passed as input in this variable
 * @paraminfo {@rep:required}
 * @param p_trolin_val_tbl The table that contains the information values of create the move order line is passed as input in this variable
 * @paraminfo {@rep:required}
 * @param x_trohdr_rec Return the record containing information of the move order header locked
 * @paraminfo {@rep:required}
 * @param x_trohdr_val_rec Return the record containing information values of the move order header locked
 * @paraminfo {@rep:required}
 * @param x_trolin_tbl Return the table containing information of the move order lines locked
 * @paraminfo {@rep:required}
 * @param x_trolin_val_tbl Return the table containing information values of the move order lines locked
 * @paraminfo {@rep:required}
 * @rep:scope public
 * @rep:lifecycle active
 * @rep:displayname Lock Move Order
 */
PROCEDURE Lock_Move_Order
(   p_api_version_number            IN  NUMBER
,   p_init_msg_list                 IN  VARCHAR2 := FND_API.G_FALSE
,   p_return_values                 IN  VARCHAR2 := FND_API.G_FALSE
,   x_return_status                 OUT NOCOPY VARCHAR2
,   x_msg_count                     OUT NOCOPY NUMBER
,   x_msg_data                      OUT NOCOPY VARCHAR2
,   p_trohdr_rec                    IN  Trohdr_Rec_Type :=
                                        G_MISS_TROHDR_REC
,   p_trohdr_val_rec                IN  Trohdr_Val_Rec_Type :=
                                        G_MISS_TROHDR_VAL_REC
,   p_trolin_tbl                    IN  Trolin_Tbl_Type :=
                                        G_MISS_TROLIN_TBL
,   p_trolin_val_tbl                IN  Trolin_Val_Tbl_Type :=
                                        G_MISS_TROLIN_VAL_TBL
,   x_trohdr_rec                    IN OUT NOCOPY Trohdr_Rec_Type
,   x_trohdr_val_rec                IN OUT NOCOPY Trohdr_Val_Rec_Type
,   x_trolin_tbl                    IN OUT NOCOPY Trolin_Tbl_Type
,   x_trolin_val_tbl                IN OUT NOCOPY Trolin_Val_Tbl_Type
);

--  Procedures
--   	Get_Move_Order
--  Input Parameters
--	p_api_version_number	API version number (current version is 1.0)
--
--	p_init_msg_list		Valid values: FND_API.G_FALSE or FND_API.G_TRUE.
--				if set to FND_API.G_TRUE
--					initialize error message list
--			        if set to FND_API.G_FALSE - not initialize error
--					message list
--	p_return_values		valid values: FND_API.G_FALSE or FND_API.G_TRUE
--	p_commit		whether or not to commit the changes to database
--	p_header_id		the header_id of the transfer order that you want to get
--	p_header		the header description of the transfer order that you want to get
--
--  Output Parameter:
--  	x_return_status		= FND_API.G_RET_STS_SUCCESS, if succeeded
--				= FND_API.G_RET_STS_EXC_ERROR, if an expected error occured
--				= FND_API.G_RET_STS_UNEXP_ERROR, if an unexpected error occured
--
--	x_msg_count		Number of error message in the error message list
--
--	x_msg_data		If the number of error message in the error message list is one,
--				the error message is in the output parameter
--
--	x_trohdr_rec		The information of move order header with the header_id requested
--
--	x_trohdr_val_Rec	The information values of move order header for the requested header_id
--
--	x_trohdr_tbl		The move order lines records for the requested header_id
--
--	x_trohdr_val_tbl	The information values of move order lines record for the requested
--				header_id
--
/*#
 * Use this procedure to get a move order and its lines.
 * @param p_api_version_number API version is passed as input in this variable
 * @paraminfo {@rep:required}
 * @param p_init_msg_list fnd_api.g_false or fnd_api.g_true is passed as input in this variable to determine whether to Initialize message list or not
 * @paraminfo {@rep:required}
 * @param p_return_values fnd_api.g_false or fnd_api.g_true is passed as input in this variable to determine whether to commit or not
 * @paraminfo {@rep:required}
 * @param x_return_status Return Status indiacation success or failure.
 * @paraminfo {@rep:required}
 * @param x_msg_count message count from the error stack in case of failure
 * @paraminfo {@rep:required}
 * @param x_msg_data x_msg_data Return the error message in case of failure
 * @paraminfo {@rep:required}
 * @param p_header_id the identifier of the move order header is passed as input in this variable
 * @paraminfo {@rep:required}
 * @param p_header the request number of the move order header is passed as input in this variable
 * @paraminfo {@rep:required}
 * @param x_trohdr_rec Return the record containing information of the move order header
 * @paraminfo {@rep:required}
 * @param x_trohdr_val_rec Return the record containing information values of the move order header
 * @paraminfo {@rep:required}
 * @param x_trolin_tbl Return the table containing information of the move order lines
 * @paraminfo {@rep:required}
 * @param x_trolin_val_tbl Return the table containing information values of the move order lines
 * @paraminfo {@rep:required}
 * @rep:scope public
 * @rep:lifecycle active
 * @rep:displayname Get Move Order
 */
PROCEDURE Get_Move_Order
(   p_api_version_number            IN  NUMBER
,   p_init_msg_list                 IN  VARCHAR2 := FND_API.G_FALSE
,   p_return_values                 IN  VARCHAR2 := FND_API.G_FALSE
,   x_return_status                 OUT NOCOPY VARCHAR2
,   x_msg_count                     OUT NOCOPY NUMBER
,   x_msg_data                      OUT NOCOPY VARCHAR2
,   p_header_id                     IN  NUMBER :=
                                        FND_API.G_MISS_NUM
,   p_header                        IN  VARCHAR2 :=
                                        FND_API.G_MISS_CHAR
,   x_trohdr_rec                    OUT NOCOPY Trohdr_Rec_Type
,   x_trohdr_val_rec                OUT NOCOPY Trohdr_Val_Rec_Type
,   x_trolin_tbl                    OUT NOCOPY Trolin_Tbl_Type
,   x_trolin_val_tbl                OUT NOCOPY Trolin_Val_Tbl_Type
);

/*#
 * Use this procedure to process a move order line.
 * @param p_api_version_number API version is passed as input in this variable
 * @paraminfo {@rep:required}
 * @param p_init_msg_list fnd_api.g_false or fnd_api.g_true is passed as input in this variable to determine whether to Initialize message list or not
 * @paraminfo {@rep:required}
 * @param p_return_values fnd_api.g_false or fnd_api.g_true is passed as input in this variable to determine whether to commit or not
 * @paraminfo {@rep:required}
 * @param p_commit fnd_api.g_false or fnd_api.g_true is passed as input in this variable to determine whether to commit or not
 * @paraminfo {@rep:required}
 * @param x_return_status Return Status indiacation success or failure.
 * @paraminfo {@rep:required}
 * @param x_msg_count message count from the error stack in case of failure
 * @paraminfo {@rep:required}
 * @param x_msg_data x_msg_data Return the error message in case of failure
 * @paraminfo {@rep:required}
 * @param p_trolin_tbl The table that contains the information of the move order line is passed as input in this variable
 * @paraminfo {@rep:required}
 * @param p_trolin_old_tbl this table is not used now
 * @paraminfo {@rep:required}
 * @param x_trolin_tbl Return the table containing information of the move order lines locked
 * @paraminfo {@rep:required}
 * @rep:scope public
 * @rep:lifecycle active
 * @rep:displayname Process Move ORder Line
 */
PROCEDURE Process_Move_Order_Line
(
    p_api_version_number	IN NUMBER
,   p_init_msg_list		IN VARCHAR2 := FND_API.G_FALSE
,   p_return_values		IN VARCHAR2 := FND_API.G_FALSE
,   p_commit			IN VARCHAR2 := FND_API.G_TRUE
,   x_return_status		OUT NOCOPY VARCHAR2
,   x_msg_count			OUT NOCOPY NUMBER
,   x_msg_data			OUT NOCOPY VARCHAR2
,   p_trolin_tbl		IN Trolin_Tbl_Type
,   p_trolin_old_tbl		IN Trolin_Tbl_Type
,   x_trolin_tbl		IN OUT NOCOPY Trolin_Tbl_Type
);

END INV_Move_Order_PUB;
/

