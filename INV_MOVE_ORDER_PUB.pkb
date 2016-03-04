CREATE OR REPLACE PACKAGE BODY INV_Move_Order_PUB AS
/* $Header: INVPTROB.pls 115.17.115100.2 2004/10/30 12:27:57 vsunkesh ship $ */

--  Global constant holding the package name

G_PKG_NAME                    CONSTANT VARCHAR2(30) := 'INV_Move_Order_PUB';

g_inventory_item_id	NUMBER := NULL;
g_primary_uom_code	VARCHAR2(3) := NULL;
g_restrict_subinventories_code NUMBER;
g_restrict_locators_code NUMBER;


PROCEDURE print_debug(p_message in varchar2, p_module in varchar2) IS
begin
  dbms_output.put_line(p_message);
  inv_trx_util_pub.trace(p_message, p_module);
end;

--  Forward declaration of Procedure Id_To_Value

PROCEDURE Id_To_Value
(   p_trohdr_rec                    IN  Trohdr_Rec_Type
,   p_trolin_tbl                    IN  Trolin_Tbl_Type
,   x_trohdr_val_rec                OUT NOCOPY Trohdr_Val_Rec_Type
,   x_trolin_val_tbl                OUT NOCOPY Trolin_Val_Tbl_Type
);

--  Forward declaration of procedure Value_To_Id

PROCEDURE Value_To_Id
(   x_return_status                 OUT NOCOPY VARCHAR2
,   p_trohdr_rec                    IN  Trohdr_Rec_Type
,   p_trohdr_val_rec                IN  Trohdr_Val_Rec_Type
,   p_trolin_tbl                    IN  Trolin_Tbl_Type
,   p_trolin_val_tbl                IN  Trolin_Val_Tbl_Type
,   x_trohdr_rec                    IN OUT NOCOPY Trohdr_Rec_Type
,   x_trolin_tbl                    IN OUT NOCOPY Trolin_Tbl_Type
);
--  Start of Comments
--  API name    Create_Move_Order_Header
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

PROCEDURE Create_Move_Order_Header
(   p_api_version_number            IN  NUMBER
,   p_init_msg_list                 IN  VARCHAR2 := FND_API.G_FALSE
,   p_return_values                 IN  VARCHAR2 := FND_API.G_FALSE
,   p_commit                        IN  VARCHAR2 := FND_API.G_FALSE
,   x_return_status                 OUT NOCOPY VARCHAR2
,   x_msg_count                     OUT NOCOPY NUMBER
,   x_msg_data                      OUT NOCOPY VARCHAR2
,   p_trohdr_rec                    IN  Trohdr_Rec_Type := G_MISS_TROHDR_REC
,   p_trohdr_val_rec                IN  Trohdr_Val_Rec_Type := G_MISS_TROHDR_VAL_REC
,   x_trohdr_rec                    IN OUT NOCOPY Trohdr_Rec_Type
,   x_trohdr_val_rec                IN OUT NOCOPY Trohdr_Val_Rec_Type
,   p_validation_flag		    IN VARCHAR2
) IS
l_api_version_number          CONSTANT NUMBER := 1.0;
l_api_name                    CONSTANT VARCHAR2(30):= 'Create_Move_Order_Header';
l_control_rec                 INV_GLOBALS.Control_Rec_Type;
l_return_status               VARCHAR2(1);
l_trohdr_rec                  Trohdr_Rec_Type;
l_trolin_tbl                  Trolin_Tbl_Type := G_MISS_TROLIN_TBL;
l_trolin_val_tbl              Trolin_Val_Tbl_Type := G_MISS_TROLIN_VAL_TBL;
    l_debug number := NVL(FND_PROFILE.VALUE('INV_DEBUG_TRACE'),0);
BEGIN
    if l_debug = 1 THEN
      print_debug('enter Create Move Order Header', l_api_name);
    end if;
    --  Standard call to check for call compatibility
    IF NOT FND_API.Compatible_API_Call
           (   l_api_version_number
           ,   p_api_version_number
           ,   l_api_name
           ,   G_PKG_NAME
           )
    THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

  g_primary_uom_code := NULL;
  g_inventory_item_id := NULL;
  IF NVL(p_validation_flag,g_validation_yes) = g_validation_no THEN
    If l_debug = 1 THEN
      print_debug('No Validation', l_api_name);
    End If;
    x_trohdr_rec := p_trohdr_rec;
    --set default values
    x_trohdr_rec.date_required := sysdate;
    x_trohdr_rec.description := NULL;
    x_trohdr_rec.from_subinventory_code := NULL;
    x_trohdr_rec.header_id := INV_TRANSFER_ORDER_PVT.get_next_header_id;
    x_trohdr_rec.program_application_id := NULL;
    x_trohdr_rec.program_id := NULL;
    x_trohdr_rec.program_update_date := NULL;
    x_trohdr_rec.request_id := NULL;
    x_trohdr_rec.status_date := sysdate;
    x_trohdr_rec.to_account_id := NULL;
    x_trohdr_rec.to_subinventory_code := NULL;
    x_trohdr_rec.ship_to_location_id := NULL;

    x_trohdr_rec.attribute_category:= NULL;
    x_trohdr_rec.attribute1 := NULL;
    x_trohdr_rec.attribute2 := NULL;
    x_trohdr_rec.attribute3 := NULL;
    x_trohdr_rec.attribute4 := NULL;
    x_trohdr_rec.attribute5 := NULL;
    x_trohdr_rec.attribute6 := NULL;
    x_trohdr_rec.attribute7 := NULL;
    x_trohdr_rec.attribute8 := NULL;
    x_trohdr_rec.attribute9 := NULL;
    x_trohdr_rec.attribute10 := NULL;
    x_trohdr_rec.attribute11 := NULL;
    x_trohdr_rec.attribute12 := NULL;
    x_trohdr_rec.attribute13 := NULL;
    x_trohdr_rec.attribute14 := NULL;
    x_trohdr_rec.attribute15 := NULL;
    inv_trohdr_util.insert_row(x_trohdr_rec);
    x_return_status := fnd_api.g_ret_sts_success;

  ELSE
    If l_debug = 1 THEN
      print_debug('Validation turned on', l_api_name);
    End If;
    l_control_rec.controlled_operation := TRUE;
    l_control_Rec.process_entity := INV_GLOBALS.G_ENTITY_TROHDR;
    l_control_Rec.default_attributes := TRUE;
    l_control_rec.change_attributes := TRUE;
    l_control_rec.write_to_db := TRUE;

    If l_debug = 1 THEN
      print_debug('Call to process_transfer_order', l_api_name);
    End If;
    --  Call INV_Transfer_Order_PVT.Process_Transfer_Order
    INV_Transfer_Order_PVT.Process_Transfer_Order
    (   p_api_version_number          => 1.0
    ,   p_init_msg_list               => p_init_msg_list
    ,   p_commit                      => p_commit
    ,   p_validation_level            => FND_API.G_VALID_LEVEL_FULL
    ,   p_control_rec                 => l_control_rec
    ,   x_return_status               => x_return_status
    ,   x_msg_count                   => x_msg_count
    ,   x_msg_data                    => x_msg_data
    ,   p_trohdr_rec                  => p_trohdr_rec
    ,   p_trohdr_val_rec              => p_trohdr_val_rec
    ,   p_trolin_tbl                  => l_trolin_tbl
    ,   p_trolin_val_tbl              => l_trolin_val_tbl
    ,   x_trohdr_rec                  => l_trohdr_rec
    ,   x_trolin_tbl                  => l_trolin_tbl
    );

    IF x_return_status = fnd_api.g_ret_sts_error THEN
      If l_debug = 1 THEN
        print_debug('Error from process_transfer_order',l_api_name);
      End If;
      RAISE fnd_api.g_exc_error;
    ELSIF x_return_status = fnd_api.g_ret_sts_unexp_error THEN
      If l_debug = 1 THEN
        print_debug('Unexpected error from process_transfer_order',l_api_name);
      End If;
      RAISE fnd_api.g_exc_unexpected_error;
    END IF;

    --  Load Id OUT parameters.

    x_trohdr_rec                   := l_trohdr_rec;
    if( p_commit = FND_API.G_TRUE ) Then
	commit;
    end if;
    --x_trolin_tbl                   := p_trolin_tbl;

    --  If p_return_values is TRUE then convert Ids to Values.

    IF FND_API.to_Boolean(p_return_values) THEN

        Id_To_Value
        (   p_trohdr_rec                  => p_trohdr_rec
        ,   p_trolin_tbl                  => l_trolin_tbl
        ,   x_trohdr_val_rec              => x_trohdr_val_rec
        ,   x_trolin_val_tbl              => l_trolin_val_tbl
        );

    END IF;
  END IF;

  If l_debug = 1 THEN
    print_debug('End Create Move Order Header', l_api_name);
  End If;
EXCEPTION

    WHEN FND_API.G_EXC_ERROR THEN
        x_return_status := FND_API.G_RET_STS_ERROR;

        --  Get message count and data
        FND_MSG_PUB.Count_And_Get
        (   p_count                       => x_msg_count
        ,   p_data                        => x_msg_data
        );

    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

        --  Get message count and data
        FND_MSG_PUB.Count_And_Get
        (   p_count                       => x_msg_count
        ,   p_data                        => x_msg_data
        );

    WHEN OTHERS THEN
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

        IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
            FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME , 'Create_Move_Order_Header');
        END IF;

        --  Get message count and data
        FND_MSG_PUB.Count_And_Get
        (   p_count                       => x_msg_count
        ,   p_data                        => x_msg_data
        );

END Create_Move_Order_Header;


--  Start of Comments
--  API name    Create_Move_Order_Lines
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
,   p_validation_flag		    IN VARCHAR2
)
IS
l_api_version_number          CONSTANT NUMBER := 1.0;
l_api_name                    CONSTANT VARCHAR2(30):= 'Create_Move_Order_Lines';
l_control_rec                 INV_GLOBALS.Control_Rec_Type;
l_return_status               VARCHAR2(1);
l_trohdr_rec                  Trohdr_Rec_Type := G_MISS_TROHDR_REC;
l_trohdr_val_rec              Trohdr_Val_Rec_Type := G_MISS_TROHDR_VAL_REC;
l_trolin_tbl                  Trolin_Tbl_Type := p_trolin_tbl;
l_trolin_tbl_out	      Trolin_Tbl_Type;
l_dummy			      NUMBER;
l_index			      NUMBER;
l_primary_uom_code	      VARCHAR2(3);
l_restrict_locators_code      NUMBER := NULL;
l_restrict_subinventories_code NUMBER:= NULL;
l_result		      VARCHAR2(1);
l_current_ship_set_id 	      NUMBER;
l_failed_ship_set_id	      NUMBER;
l_first_ship_set_record	      NUMBER;

    l_debug number := NVL(FND_PROFILE.VALUE('INV_DEBUG_TRACE'),0);
BEGIN

    --  Standard call to check for call compatibility

    IF NOT FND_API.Compatible_API_Call
           (   l_api_version_number
           ,   p_api_version_number
           ,   l_api_name
           ,   G_PKG_NAME
           )
    THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

/*
    --  Perform Value to Id conversion
    Value_To_Id
    (   x_return_status               => l_return_status
    ,   p_trohdr_rec                  => l_trohdr_rec
    ,   p_trohdr_val_rec              => l_trohdr_val_rec
    ,   p_trolin_tbl                  => p_trolin_tbl
    ,   p_trolin_val_tbl              => p_trolin_val_tbl
    ,   x_trohdr_rec                  => l_trohdr_rec
    ,   x_trolin_tbl                  => l_trolin_tbl
    );

    IF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    ELSIF l_return_status = FND_API.G_RET_STS_ERROR THEN
        RAISE FND_API.G_EXC_ERROR;
    END IF;
*/
    --l_control_rec.process_entity := INV_GLOBALS.G_ENTITY_TROLIN;
    --l_control_rec.controlled_operation := TRUE;
    --l_control_rec.write_to_db := FND_API.to_boolean(p_commit);

  IF NVL(p_validation_flag,g_validation_yes) = g_validation_no THEN
    l_index := p_trolin_tbl.FIRST;
    Loop
      x_trolin_tbl(l_index) := p_trolin_tbl(l_index);
      x_trolin_tbl(l_Index).return_status := fnd_api.g_ret_sts_success;
      l_restrict_subinventories_code := NULL;
      l_restrict_locators_code := NULL;
      IF x_trolin_tbl(l_index).ship_set_id IS NOT NULL AND
	 x_trolin_tbl(l_index).ship_set_id <> fnd_api.g_miss_num AND
	 x_trolin_tbl(l_index).ship_set_id <> l_current_ship_set_id THEN
	SAVEPOINT SHIPSET_SP;
	l_current_ship_set_id := x_trolin_tbl(l_index).ship_set_id;
	l_first_ship_set_record := l_index;
      ELSIF (x_trolin_tbl(l_index).ship_set_id IS NULL OR
	    x_trolin_tbl(l_index).ship_set_Id = fnd_api.g_miss_num) AND
	    l_current_ship_set_id IS NOT NULL THEN
	l_current_ship_set_id := NULL;
	l_first_ship_set_record := NULL;
      END IF;
      SELECT  MTL_TXN_REQUEST_LINES_S.NEXTVAL
        INTO  x_trolin_tbl(l_index).line_id
        FROM  DUAL;

      If x_trolin_tbl(l_index).transaction_type_id = 52 Then
        x_trolin_tbl(l_index).transaction_source_type_id := 2;
      Elsif x_trolin_tbl(l_index).transaction_type_id = 53 Then
        x_trolin_tbl(l_index).transaction_source_type_id := 8;
      Else
        select transaction_source_type_id
          into x_trolin_tbl(l_index).transaction_source_type_id
          from mtl_transaction_types
         where transaction_type_id=x_trolin_tbl(l_index).transaction_type_id;
      End If;
      IF x_trolin_tbl(l_index).primary_quantity IS NULL OR
         x_trolin_tbl(l_index).primary_quantity = fnd_api.g_miss_num THEN
	--find primary quantity
        print_debug('finding primary quantity', l_api_name);
        IF g_inventory_item_id = x_trolin_tbl(l_index).inventory_item_id THEN
          print_debug('Using saved primary uom code', l_api_name);
	  l_primary_uom_code := g_primary_uom_code;
        ELSE
          print_debug('Selecting primary uom code', l_api_name);
          SELECT primary_uom_code
		,nvl(restrict_locators_code,0)
		,nvl(restrict_subinventories_code,0)
      	    INTO l_primary_uom_code
		,l_restrict_locators_code
		,l_restrict_subinventories_code
      	    FROM mtl_system_items
     	   WHERE organization_id = x_trolin_tbl(l_index).organization_id
       	     AND inventory_item_id = x_trolin_tbl(l_index).inventory_item_id;

	  g_inventory_item_id := x_trolin_tbl(l_index).inventory_item_id;
	  g_primary_uom_code := l_primary_uom_code;
	  g_restrict_locators_code := l_restrict_locators_code;
	  g_restrict_subinventories_code := l_restrict_subinventories_code;
        END IF;

	IF l_primary_uom_code = x_trolin_tbl(l_index).uom_code THEN
	  x_trolin_tbl(l_index).primary_quantity :=
		x_trolin_tbl(l_index).quantity;
	ELSE
          x_trolin_tbl(l_index).primary_quantity :=
	    inv_convert.inv_um_convert(
		  item_id =>  x_trolin_tbl(l_index).inventory_item_id
		, PRECISION => NULL
	        , from_quantity => x_trolin_tbl(l_index).quantity
		, from_unit => x_trolin_tbl(l_index).uom_code
		, to_unit => l_primary_uom_code
		, from_name => NULL
		, to_name => NULL);
          print_debug('primary_quantity = ' ||
		x_trolin_tbl(l_index).primary_quantity, l_api_name);
	  IF x_trolin_tbl(l_index).primary_quantity < 0 THEN
	    print_debug('Error during conversion. Primary quantity less that 0',
		      l_api_name);
            RAISE fnd_api.g_exc_error;
          END IF;
        END IF; -- primary uom = txn uom
      END IF; -- primary qty is missing

      IF x_trolin_tbl(l_index).to_subinventory_code IS NOT NULL THEN
	If l_restrict_subinventories_code IS NULL THEN
	  If g_inventory_item_id = x_trolin_tbl(l_index).inventory_item_id Then
	    l_restrict_subinventories_code := g_restrict_subinventories_code;
	    l_restrict_locators_code := g_restrict_locators_code;
	  Else  -- item doesn't match saved item
            SELECT primary_uom_code
	  	  ,nvl(restrict_locators_code,0)
		  ,nvl(restrict_subinventories_code,0)
      	      INTO l_primary_uom_code
		  ,l_restrict_locators_code
		  ,l_restrict_subinventories_code
      	      FROM mtl_system_items
     	     WHERE organization_id = x_trolin_tbl(l_index).organization_id
       	       AND inventory_item_id = x_trolin_tbl(l_index).inventory_item_id;

	    g_inventory_item_id :=  x_trolin_tbl(l_index).inventory_item_id;
	    g_primary_uom_code := l_primary_uom_code;
	    g_restrict_subinventories_code := l_restrict_subinventories_code;
	    g_restrict_locators_code := l_restrict_locators_code;
	  End If; -- inventory item matches
	End If; -- restrict subs is null
	If l_restrict_locators_code = 1 And
	   x_trolin_tbl(l_index).to_locator_id IS NOT NULL Then
	  BEGIN
            SELECT 'Y'
	      INTO l_result
              FROM DUAL
             WHERE exists (
                SELECT secondary_locator
                  FROM mtl_secondary_locators
                 WHERE organization_id = x_trolin_tbl(l_index).organization_id
                   AND secondary_locator = x_trolin_tbl(l_index).to_locator_id
		   AND inventory_item_id =
                        x_trolin_tbl(l_index).inventory_item_id);
           EXCEPTION
             WHEN NO_DATA_FOUND THEN
               x_trolin_tbl(l_index).return_status:= fnd_api.g_ret_sts_error;
           END;

	Elsif l_restrict_subinventories_code = 1 Then
	  BEGIN
	    SELECT 'Y'
	      INTO l_result
	      FROM DUAL
	     WHERE exists (
		SELECT secondary_inventory
		  FROM mtl_item_sub_inventories
		 WHERE organization_id = x_trolin_tbl(l_index).organization_id
		   AND secondary_inventory =
			x_trolin_tbl(l_index).to_subinventory_code
		   AND inventory_item_id =
			x_trolin_tbl(l_index).inventory_item_id);
	   EXCEPTION
	     WHEN NO_DATA_FOUND THEN
	       x_trolin_tbl(l_index).return_status:= fnd_api.g_ret_sts_error;
	   END;
	End If;
      END IF; -- to sub is not null

      x_trolin_tbl(l_index).from_subinventory_id := NULL;
      x_trolin_tbl(l_index).lot_number := NULL;
      x_trolin_tbl(l_index).program_application_id := NULL;
      x_trolin_tbl(l_index).program_id := NULL;
      x_trolin_tbl(l_index).program_update_date := NULL;
      x_trolin_tbl(l_index).quantity_delivered := NULL;
      x_trolin_tbl(l_index).quantity_detailed := NULL;
      x_trolin_tbl(l_index).reason_id := NULL;
      x_trolin_tbl(l_index).reference := NULL;
      x_trolin_tbl(l_index).reference_id := NULL;
      x_trolin_tbl(l_index).reference_type_code := NULL;
      x_trolin_tbl(l_index).request_id := NULL;
      x_trolin_tbl(l_index).revision := NULL;
      x_trolin_tbl(l_index).serial_number_end := NULL;
      x_trolin_tbl(l_index).serial_number_start := NULL;
      x_trolin_tbl(l_index).status_date :=sysdate;
      x_trolin_tbl(l_index).to_account_id := NULL;
      x_trolin_tbl(l_index).to_subinventory_id := NULL;
      x_trolin_tbl(l_index).transaction_header_id := NULL;
      x_trolin_tbl(l_index).txn_source_id := NULL;
      x_trolin_tbl(l_index).txn_source_line_detail_id := NULL;
      x_trolin_tbl(l_index).to_organization_id := NULL;
      x_trolin_tbl(l_index).pick_strategy_id := NULL;
      x_trolin_tbl(l_index).put_away_strategy_id := NULL;
      x_trolin_tbl(l_index).ship_to_location_id := NULL;
      x_trolin_tbl(l_index).from_cost_group_id := NULL;
      x_trolin_tbl(l_index).to_cost_group_id := NULL;
      x_trolin_tbl(l_index).lpn_id := NULL;
      x_trolin_tbl(l_index).to_lpn_id := NULL;
      x_trolin_tbl(l_index).pick_methodology_id := NULL;
      x_trolin_tbl(l_index).container_item_id := NULL;
      x_trolin_tbl(l_index).carton_grouping_id := NULL;
      x_trolin_tbl(l_index).inspection_status := NULL;
      x_trolin_tbl(l_index).wms_process_flag := NULL;
      x_trolin_tbl(l_index).pick_slip_number := NULL;
      x_trolin_tbl(l_index).pick_slip_date := NULL;
      x_trolin_tbl(l_index).required_quantity := NULL;

      x_trolin_tbl(l_index).attribute_category := NULL;
      x_trolin_tbl(l_index).attribute1 := NULL;
      x_trolin_tbl(l_index).attribute2 := NULL;
      x_trolin_tbl(l_index).attribute3 := NULL;
      x_trolin_tbl(l_index).attribute4 := NULL;
      x_trolin_tbl(l_index).attribute5 := NULL;
      x_trolin_tbl(l_index).attribute6 := NULL;
      x_trolin_tbl(l_index).attribute7 := NULL;
      x_trolin_tbl(l_index).attribute8 := NULL;
      x_trolin_tbl(l_index).attribute9 := NULL;
      x_trolin_tbl(l_index).attribute10 := NULL;
      x_trolin_tbl(l_index).attribute11 := NULL;
      x_trolin_tbl(l_index).attribute12 := NULL;
      x_trolin_tbl(l_index).attribute13 := NULL;
      x_trolin_tbl(l_index).attribute14 := NULL;
      x_trolin_tbl(l_index).attribute15 := NULL;

      IF x_trolin_tbl(l_index).return_status = fnd_api.g_ret_sts_success THEN
        inv_trolin_util.insert_row(x_trolin_tbl(l_index));
      ELSIF l_current_ship_set_id IS NOT NULL THEN
	ROLLBACK to SHIPSET_SP;
	l_index := l_first_ship_set_record;
	LOOP --loop through all records in shipset

	  --only copy record to x_trolin_tbl if we haven't already done so
	  IF not x_trolin_tbl.exists(l_index) THEN
	    x_trolin_tbl(l_index) := p_trolin_tbl(l_index);
	  END IF;
	  x_trolin_tbl(l_index).return_status := fnd_api.g_ret_sts_error;

	  --exit when we just edited the last record
	  EXIT WHEN l_index = p_trolin_tbl.LAST;

	  --goto next record
          l_index := p_trolin_tbl.NEXT(l_index);

	  --if the current record has a different shipset, we've marked
	  -- all the shipset records as bad, and l_index points to the first
	  -- good record. Set back to previous record, since pointer gets
	  -- updated after this loop ends. Exit loop through shipset records
	  IF p_trolin_tbl(l_index).ship_set_id IS NULL OR
	     p_trolin_tbl(l_index).ship_set_id = fnd_api.g_miss_num OR
	     p_trolin_tbl(l_index).ship_set_id <> l_current_ship_set_id THEN
	     l_index := p_trolin_tbl.prior(l_index);
	    EXIT;
	  END IF;
	END LOOP; --loop for all records in shipset
	l_current_ship_set_id := NULL;
	l_first_ship_set_record := NULL;
      END IF; --return status on record

      EXIT WHEN l_index = p_trolin_tbl.LAST;
      l_index := p_trolin_tbl.NEXT(l_index);
    END LOOP;  -- loop throUgh p_trolin_tbl
    x_return_status := fnd_api.g_ret_sts_success;
  ELSE
    l_control_rec.controlled_operation := TRUE;
    l_control_Rec.process_entity := INV_GLOBALS.G_ENTITY_TROLIN;
    l_control_Rec.default_attributes := TRUE;
    l_control_rec.change_attributes := TRUE;
    l_control_rec.write_to_db := TRUE;
    --  Call INV_Transfer_Order_PVT.Process_Transfer_Order
    if( l_trolin_tbl.count > 0 ) then
	for i in 1..l_trolin_tbl.count LOOP
	    --inv_debug.message('trolin.line_id is ' || l_trolin_tbl(l).line_id);
/* to fix bug 1402677: Also we shouldn't change the operation here
	    if( (l_trolin_tbl(i).line_id <> FND_API.G_MISS_NUM OR l_trolin_tbl(i).line_id is NULL ) AND
		l_trolin_tbl(i).operation = INV_GLOBALS.G_OPR_CREATE ) then
		l_trolin_tbl(i).operation := INV_GLOBALS.G_OPR_UPDATE;
	    els*/
            if (l_trolin_tbl(i).operation = INV_GLOBALS.G_OPR_UPDATE and
		(l_trolin_tbl(i).line_id = FND_API.G_MISS_NUM OR
		 l_trolin_tbl(i).line_id is null ) ) then
	        --inv_debug.message('update and no line id');
  		fnd_message.set_name('INV', 'INV_ATTRIBUTE_REQUIRED');
		fnd_message.set_token('ATTRIBUTE', 'LINE_ID');
		fnd_msg_pub.add;
		raise fnd_api.g_exc_error;
	    end if;

	    if( l_trolin_tbl(i).header_id is not null
		and l_trolin_tbl(i).header_id <> FND_API.G_MISS_NUM ) then
		--inv_debug.message('check if the header_id exists');
	        select count(*)
	        into l_dummy
		from mtl_txn_request_headers
	        where header_id = l_trolin_tbl(i).header_id
	        and organization_id = l_trolin_tbl(i).organization_id;
	        --inv_debug.message('l_dummy is ' || l_dummy);
                if( l_dummy = 0 ) then
		    --inv_debug.message('header id not found');
		    FND_MESSAGE.SET_NAME('INV', 'INV_FIELD_INVALID');
		    FND_MESSAGE.SET_TOKEN('ENTITY1', 'Header_Id');
		    FND_MSG_PUB.ADD;
		    raise fnd_api.g_exc_error;
		else
		   l_trohdr_rec := inv_trohdr_util.query_row(p_header_id => l_trolin_tbl(i).header_id);
	        end if;
	    end if;
        end loop;
    end if;


    INV_Transfer_Order_PVT.Process_Transfer_Order
    (   p_api_version_number          => 1.0
    ,   p_init_msg_list               => p_init_msg_list
    ,   p_validation_level            => FND_API.G_VALID_LEVEL_FULL
    ,   p_commit                      => p_commit
    ,   x_return_status               => x_return_status
    ,   x_msg_count                   => x_msg_count
    ,   x_msg_data                    => x_msg_data
    ,   p_control_rec                 => l_control_rec
    ,   p_trohdr_rec                  => l_trohdr_rec
    ,   p_trohdr_val_rec              => l_trohdr_val_rec
    ,   p_trolin_tbl                  => l_trolin_tbl
    ,   p_trolin_val_tbl              => p_trolin_val_tbl
    ,   x_trohdr_rec                  => l_trohdr_rec
    ,   x_trolin_tbl                  => l_trolin_tbl_out
    );

    --  Load Id OUT parameters.

    --x_trohdr_rec                   := p_trohdr_rec;
    x_trolin_tbl                   := l_trolin_tbl_out;

    if( p_commit = FND_API.G_TRUE ) Then
	commit;
    end if;
    --  If p_return_values is TRUE then convert Ids to Values.

    IF FND_API.to_Boolean(p_return_values) THEN

        Id_To_Value
        (   p_trohdr_rec                  => l_trohdr_rec
        ,   p_trolin_tbl                  => p_trolin_tbl
        ,   x_trohdr_val_rec              => l_trohdr_val_rec
        ,   x_trolin_val_tbl              => x_trolin_val_tbl
        );

    END IF;
  END IF;
EXCEPTION

    WHEN FND_API.G_EXC_ERROR THEN

	--inv_debug.message('returning error');
        x_return_status := FND_API.G_RET_STS_ERROR;

        --  Get message count and data
        FND_MSG_PUB.Count_And_Get
        (   p_count                       => x_msg_count
        ,   p_data                        => x_msg_data
        );

    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

        --  Get message count and data
        FND_MSG_PUB.Count_And_Get
        (   p_count                       => x_msg_count
        ,   p_data                        => x_msg_data
        );

    WHEN OTHERS THEN

        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

        IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
        THEN
            FND_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Process_Move_Order'
            );
        END IF;

        --  Get message count and data

        FND_MSG_PUB.Count_And_Get
        (   p_count                       => x_msg_count
        ,   p_data                        => x_msg_data
        );

END Create_Move_Order_Lines;

--  Start of Comments
--  API name    Process_Move_Order
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
)
IS
l_api_version_number          CONSTANT NUMBER := 1.0;
l_api_name                    CONSTANT VARCHAR2(30):= 'Process_Move_Order';
l_control_rec                 INV_GLOBALS.Control_Rec_Type;
l_return_status               VARCHAR2(1);
l_trohdr_rec                  Trohdr_Rec_Type;
l_trolin_tbl                  Trolin_Tbl_Type;
    l_debug number := NVL(FND_PROFILE.VALUE('INV_DEBUG_TRACE'),0);
BEGIN

    --  Standard call to check for call compatibility

    IF NOT FND_API.Compatible_API_Call
           (   l_api_version_number
           ,   p_api_version_number
           ,   l_api_name
           ,   G_PKG_NAME
           )
    THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

    l_control_Rec.process_entity := INV_GLOBALS.G_ENTITY_ALL;
/*
    --  Perform Value to Id conversion
    Value_To_Id
    (   x_return_status               => l_return_status
    ,   p_trohdr_rec                  => p_trohdr_rec
    ,   p_trohdr_val_rec              => p_trohdr_val_rec
    ,   p_trolin_tbl                  => p_trolin_tbl
    ,   p_trolin_val_tbl              => p_trolin_val_tbl
    ,   x_trohdr_rec                  => l_trohdr_rec
    ,   x_trolin_tbl                  => l_trolin_tbl
    );

    IF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    ELSIF l_return_status = FND_API.G_RET_STS_ERROR THEN
        RAISE FND_API.G_EXC_ERROR;
    END IF;
*/

    --  Call INV_Transfer_Order_PVT.Process_Transfer_Order

    INV_Transfer_Order_PVT.Process_Transfer_Order
    (   p_api_version_number          => 1.0
    ,   p_init_msg_list               => p_init_msg_list
    ,   p_validation_level            => FND_API.G_VALID_LEVEL_FULL
    ,   p_commit                      => p_commit
    ,   x_return_status               => x_return_status
    ,   x_msg_count                   => x_msg_count
    ,   x_msg_data                    => x_msg_data
    ,   p_control_rec                 => l_control_rec
    ,   p_trohdr_rec                  => p_trohdr_rec
    ,   p_trohdr_val_rec              => p_trohdr_val_rec
    ,   p_trolin_tbl                  => p_trolin_tbl
    ,   p_trolin_val_tbl              => p_trolin_val_tbl
    ,   x_trohdr_rec                  => l_trohdr_rec
    ,   x_trolin_tbl                  => l_trolin_tbl
    );

    --  Load Id OUT parameters.

    x_trohdr_rec                   := l_trohdr_rec;
    x_trolin_tbl                   := l_trolin_tbl;

    if p_commit = FND_API.G_TRUE then
	commit;
    end if;
    --  If p_return_values is TRUE then convert Ids to Values.

    IF FND_API.to_Boolean(p_return_values) THEN

        Id_To_Value
        (   p_trohdr_rec                  => p_trohdr_rec
        ,   p_trolin_tbl                  => p_trolin_tbl
        ,   x_trohdr_val_rec              => x_trohdr_val_rec
        ,   x_trolin_val_tbl              => x_trolin_val_tbl
        );

    END IF;

EXCEPTION

    WHEN FND_API.G_EXC_ERROR THEN

        x_return_status := FND_API.G_RET_STS_ERROR;

        --  Get message count and data

        FND_MSG_PUB.Count_And_Get
        (   p_count                       => x_msg_count
        ,   p_data                        => x_msg_data
        );

    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

        --  Get message count and data

        FND_MSG_PUB.Count_And_Get
        (   p_count                       => x_msg_count
        ,   p_data                        => x_msg_data
        );

    WHEN OTHERS THEN

        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

        IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
        THEN
            FND_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Process_Move_Order'
            );
        END IF;

        --  Get message count and data

        FND_MSG_PUB.Count_And_Get
        (   p_count                       => x_msg_count
        ,   p_data                        => x_msg_data
        );

END Process_Move_Order;

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
)
IS
l_api_version_number          CONSTANT NUMBER := 1.0;
l_api_name                    CONSTANT VARCHAR2(30):= 'Lock_Move_Order';
l_return_status               VARCHAR2(1);
l_trohdr_rec                  Trohdr_Rec_Type;
l_trolin_tbl                  Trolin_Tbl_Type;
    l_debug number := NVL(FND_PROFILE.VALUE('INV_DEBUG_TRACE'),0);
BEGIN

    --  Standard call to check for call compatibility

    IF NOT FND_API.Compatible_API_Call
           (   l_api_version_number
           ,   p_api_version_number
           ,   l_api_name
           ,   G_PKG_NAME
           )
    THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

    --  Perform Value to Id conversion

    Value_To_Id
    (   x_return_status               => l_return_status
    ,   p_trohdr_rec                  => p_trohdr_rec
    ,   p_trohdr_val_rec              => p_trohdr_val_rec
    ,   p_trolin_tbl                  => p_trolin_tbl
    ,   p_trolin_val_tbl              => p_trolin_val_tbl
    ,   x_trohdr_rec                  => l_trohdr_rec
    ,   x_trolin_tbl                  => l_trolin_tbl
    );

    IF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    ELSIF l_return_status = FND_API.G_RET_STS_ERROR THEN
        RAISE FND_API.G_EXC_ERROR;
    END IF;


    --  Call INV_Transfer_Order_PVT.Lock_Transfer_Order

    INV_Transfer_Order_PVT.Lock_Transfer_Order
    (   p_api_version_number          => 1.0
    ,   p_init_msg_list               => p_init_msg_list
    ,   x_return_status               => x_return_status
    ,   x_msg_count                   => x_msg_count
    ,   x_msg_data                    => x_msg_data
    ,   p_trohdr_rec                  => l_trohdr_rec
    ,   p_trolin_tbl                  => l_trolin_tbl
    ,   x_trohdr_rec                  => l_trohdr_rec
    ,   x_trolin_tbl                  => l_trolin_tbl
    );

    --  Load Id OUT parameters.

    x_trohdr_rec                   := l_trohdr_rec;
    x_trolin_tbl                   := l_trolin_tbl;

    --  If p_return_values is TRUE then convert Ids to Values.

    IF FND_API.to_Boolean(p_return_values) THEN

        Id_To_Value
        (   p_trohdr_rec                  => l_trohdr_rec
        ,   p_trolin_tbl                  => l_trolin_tbl
        ,   x_trohdr_val_rec              => x_trohdr_val_rec
        ,   x_trolin_val_tbl              => x_trolin_val_tbl
        );

    END IF;

EXCEPTION

    WHEN FND_API.G_EXC_ERROR THEN

        x_return_status := FND_API.G_RET_STS_ERROR;

        --  Get message count and data

        FND_MSG_PUB.Count_And_Get
        (   p_count                       => x_msg_count
        ,   p_data                        => x_msg_data
        );

    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

        --  Get message count and data

        FND_MSG_PUB.Count_And_Get
        (   p_count                       => x_msg_count
        ,   p_data                        => x_msg_data
        );

    WHEN OTHERS THEN

        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

        IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
        THEN
            FND_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Lock_Move_Order'
            );
        END IF;

        --  Get message count and data

        FND_MSG_PUB.Count_And_Get
        (   p_count                       => x_msg_count
        ,   p_data                        => x_msg_data
        );

END Lock_Move_Order;

--  Start of Comments
--  API name    Get_Move_Order
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
)
IS
l_api_version_number          CONSTANT NUMBER := 1.0;
l_api_name                    CONSTANT VARCHAR2(30):= 'Get_Move_Order';
l_header_id                   NUMBER := p_header_id;
l_trohdr_rec                  INV_Move_Order_PUB.Trohdr_Rec_Type;
l_trolin_tbl                  INV_Move_Order_PUB.Trolin_Tbl_Type;
    l_debug number := NVL(FND_PROFILE.VALUE('INV_DEBUG_TRACE'),0);
BEGIN

    --  Standard call to check for call compatibility

    IF NOT FND_API.Compatible_API_Call
           (   l_api_version_number
           ,   p_api_version_number
           ,   l_api_name
           ,   G_PKG_NAME
           )
    THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

    --  Standard check for Val/ID conversion

    IF  p_header = FND_API.G_MISS_CHAR
    THEN

        l_header_id := p_header_id;

    ELSIF p_header_id <> FND_API.G_MISS_NUM THEN

        l_header_id := p_header_id;

        IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_SUCCESS)
        THEN

            FND_MESSAGE.SET_NAME('INV','FND_BOTH_VAL_AND_ID_EXIST');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE','header');
            FND_MSG_PUB.Add;

        END IF;

    ELSE

        --  Convert Value to Id

        l_header_id := INV_Value_To_Id.header
        (   p_header                      => p_header
        );

        IF l_header_id = FND_API.G_MISS_NUM THEN
            IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_ERROR)
            THEN

                FND_MESSAGE.SET_NAME('INV','Invalid Business Object Value');
                FND_MESSAGE.SET_TOKEN('ATTRIBUTE','header');
                FND_MSG_PUB.Add;

            END IF;
        END IF;

        RAISE FND_API.G_EXC_ERROR;

    END IF;


    --  Call INV_Transfer_Order_PVT.Get_Transfer_Order

    INV_Transfer_Order_PVT.Get_Transfer_Order
    (   p_api_version_number          => 1.0
    ,   p_init_msg_list               => p_init_msg_list
    ,   x_return_status               => x_return_status
    ,   x_msg_count                   => x_msg_count
    ,   x_msg_data                    => x_msg_data
    ,   p_header_id                   => l_header_id
    ,   x_trohdr_rec                  => l_trohdr_rec
    ,   x_trolin_tbl                  => l_trolin_tbl
    );

    --  Load Id OUT parameters.

    x_trohdr_rec                   := l_trohdr_rec;
    x_trolin_tbl                   := l_trolin_tbl;

    --  If p_return_values is TRUE then convert Ids to Values.

    IF FND_API.TO_BOOLEAN(p_return_values) THEN

        Id_To_Value
        (   p_trohdr_rec                  => l_trohdr_rec
        ,   p_trolin_tbl                  => l_trolin_tbl
        ,   x_trohdr_val_rec              => x_trohdr_val_rec
        ,   x_trolin_val_tbl              => x_trolin_val_tbl
        );

    END IF;

    --  Set return status

    x_return_status := FND_API.G_RET_STS_SUCCESS;

    --  Get message count and data

    FND_MSG_PUB.Count_And_Get
    (   p_count                       => x_msg_count
    ,   p_data                        => x_msg_data
    );


EXCEPTION

    WHEN FND_API.G_EXC_ERROR THEN

        x_return_status := FND_API.G_RET_STS_ERROR;

        --  Get message count and data

        FND_MSG_PUB.Count_And_Get
        (   p_count                       => x_msg_count
        ,   p_data                        => x_msg_data
        );

    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

        --  Get message count and data

        FND_MSG_PUB.Count_And_Get
        (   p_count                       => x_msg_count
        ,   p_data                        => x_msg_data
        );

    WHEN OTHERS THEN

        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

        IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
        THEN
            FND_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Get_Move_Order'
            );
        END IF;

        --  Get message count and data

        FND_MSG_PUB.Count_And_Get
        (   p_count                       => x_msg_count
        ,   p_data                        => x_msg_data
        );

END Get_Move_Order;

--  Procedure Id_To_Value

PROCEDURE Id_To_Value
(   p_trohdr_rec                    IN  Trohdr_Rec_Type
,   p_trolin_tbl                    IN  Trolin_Tbl_Type
,   x_trohdr_val_rec                OUT NOCOPY Trohdr_Val_Rec_Type
,   x_trolin_val_tbl                OUT NOCOPY Trolin_Val_Tbl_Type
)
IS
    l_debug number := NVL(FND_PROFILE.VALUE('INV_DEBUG_TRACE'),0);
BEGIN

    --  Convert trohdr

    x_trohdr_val_rec := INV_Trohdr_Util.Get_Values(p_trohdr_rec);

    --  Convert trolin

    FOR I IN 1..p_trolin_tbl.COUNT LOOP
        x_trolin_val_tbl(I) :=
            INV_Trolin_Util.Get_Values(p_trolin_tbl(I));
    END LOOP;

EXCEPTION

    WHEN OTHERS THEN

        IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
        THEN
            FND_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Id_To_Value'
            );
        END IF;

        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END Id_To_Value;

--  Procedure Value_To_Id

PROCEDURE Value_To_Id
(   x_return_status                 OUT NOCOPY VARCHAR2
,   p_trohdr_rec                    IN  Trohdr_Rec_Type
,   p_trohdr_val_rec                IN  Trohdr_Val_Rec_Type
,   p_trolin_tbl                    IN  Trolin_Tbl_Type
,   p_trolin_val_tbl                IN  Trolin_Val_Tbl_Type
,   x_trohdr_rec                    IN OUT NOCOPY Trohdr_Rec_Type
,   x_trolin_tbl                    IN OUT NOCOPY Trolin_Tbl_Type
)
IS
l_trohdr_rec                  Trohdr_Rec_Type;
l_trolin_rec                  Trolin_Rec_Type;
l_index                       BINARY_INTEGER;
    l_debug number := NVL(FND_PROFILE.VALUE('INV_DEBUG_TRACE'),0);
BEGIN

    --  Init x_return_status.

    x_return_status := FND_API.G_RET_STS_SUCCESS;

    --  Convert trohdr

    l_trohdr_rec := INV_Trohdr_Util.Get_Ids
    (   p_trohdr_rec                  => p_trohdr_rec
    ,   p_trohdr_val_rec              => p_trohdr_val_rec
    );

    x_trohdr_rec                   := l_trohdr_rec;

    IF l_trohdr_rec.return_status = FND_API.G_RET_STS_ERROR THEN
        x_return_status := FND_API.G_RET_STS_ERROR;
    END IF;

    --  Convert trolin

    x_trolin_tbl := p_trolin_tbl;

    l_index := p_trolin_val_tbl.FIRST;

    WHILE l_index IS NOT NULL LOOP

        l_trolin_rec := INV_Trolin_Util.Get_Ids
        (   p_trolin_rec                  => p_trolin_tbl(l_index)
        ,   p_trolin_val_rec              => p_trolin_val_tbl(l_index)
        );

        x_trolin_tbl(l_index)          := l_trolin_rec;

        IF l_trolin_rec.return_status = FND_API.G_RET_STS_ERROR THEN
            x_return_status := FND_API.G_RET_STS_ERROR;
        END IF;

        l_index := p_trolin_val_tbl.NEXT(l_index);

    END LOOP;

EXCEPTION

    WHEN OTHERS THEN

        IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
        THEN
            FND_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Value_To_Id'
            );
        END IF;

        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END Value_To_Id;

PROCEDURE Process_Move_Order_Line
(
    p_api_version_number        IN NUMBER
,   p_init_msg_list             IN VARCHAR2 := FND_API.G_FALSE
,   p_return_values             IN VARCHAR2 := FND_API.G_FALSE
,   p_commit                    IN VARCHAR2 := FND_API.G_TRUE
,   x_return_status             OUT NOCOPY VARCHAR2
,   x_msg_count                 OUT NOCOPY NUMBER
,   x_msg_data                  OUT NOCOPY VARCHAR2
,   p_trolin_tbl                IN Trolin_Tbl_Type
,   p_trolin_old_tbl            IN Trolin_Tbl_Type
,   x_trolin_tbl                IN OUT NOCOPY Trolin_Tbl_Type
) IS
l_api_version_number          CONSTANT NUMBER := 1.0;
l_api_name                    CONSTANT VARCHAR2(30):= 'Update_Move_Order_line';
l_control_rec                 INV_GLOBALS.Control_Rec_Type;
l_return_status               VARCHAR2(1);
l_trohdr_rec                  Trohdr_Rec_Type := G_MISS_TROHDR_REC;
l_trohdr_val_rec              Trohdr_Val_Rec_Type := G_MISS_TROHDR_VAL_REC;
l_trolin_tbl                  Trolin_Tbl_Type := p_trolin_tbl;
l_trolin_val_tbl              Trolin_Val_Tbl_Type := G_MISS_TROLIN_VAL_TBL;
    l_debug number := NVL(FND_PROFILE.VALUE('INV_DEBUG_TRACE'),0);
BEGIN

    --  Standard call to check for call compatibility
    IF NOT FND_API.Compatible_API_Call
           (   l_api_version_number
           ,   p_api_version_number
           ,   l_api_name
           ,   G_PKG_NAME
           )
    THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

    l_control_rec.controlled_operation := TRUE;
    l_control_Rec.validate_entity := TRUE;
    l_control_Rec.process_entity := INV_GLOBALS.G_ENTITY_TROLIN;
    l_control_rec.write_to_db := TRUE;
    l_control_Rec.default_attributes := FALSE;
    l_control_Rec.change_attributes := FALSE;
    l_control_rec.process := FALSE;

    --  Call INV_Transfer_Order_PVT.Process_Transfer_Order
    -- inv_debug.message('calling inv_transfer_order_pvt.process_transfer_order');
    -- inv_debug.message('l_trolin_tbl count is ' || p_trolin_tbl.COUNT);
    /*for l_count in 1..p_trolin_tbl.COUNT LOOP
	-- inv_debug.message('l_trolin_tbl.line_id is ' || p_trolin_tbl(l_count).line_id);
        -- inv_debug.message('l_trolin_tbl.operation is ' || p_trolin_tbl(l_count).operation);
    end loop; */
    INV_Transfer_Order_PVT.Process_Transfer_Order
    (   p_api_version_number          => 1.0
    ,   p_init_msg_list               => p_init_msg_list
    ,   p_commit                      => p_commit
    ,   p_validation_level            => FND_API.G_VALID_LEVEL_FULL
    ,   p_control_rec                 => l_control_rec
    ,   x_return_status               => x_return_status
    ,   x_msg_count                   => x_msg_count
    ,   x_msg_data                    => x_msg_data
    ,   p_trolin_tbl                  => p_trolin_tbl
    ,   p_trolin_val_tbl              => l_trolin_val_tbl
    ,   x_trohdr_rec                  => l_trohdr_rec
    ,   x_trolin_tbl                  => l_trolin_tbl
    );

    --  Load Id OUT parameters.

    --x_trohdr_rec                   := p_trohdr_rec;
    x_trolin_tbl                   := l_trolin_tbl;
    if( p_commit = FND_API.G_TRUE ) then
	commit;
    end if;
    --  If p_return_values is TRUE then convert Ids to Values.

    IF FND_API.to_Boolean(p_return_values) THEN

        Id_To_Value
        (   p_trohdr_rec                  => l_trohdr_rec
        ,   p_trolin_tbl                  => l_trolin_tbl
        ,   x_trohdr_val_rec              => l_trohdr_val_rec
        ,   x_trolin_val_tbl              => l_trolin_val_tbl
        );

    END IF;

EXCEPTION

    WHEN FND_API.G_EXC_ERROR THEN

        x_return_status := FND_API.G_RET_STS_ERROR;

        --  Get message count and data

        FND_MSG_PUB.Count_And_Get
        (   p_count                       => x_msg_count
        ,   p_data                        => x_msg_data
        );

    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

        --  Get message count and data

        FND_MSG_PUB.Count_And_Get
        (   p_count                       => x_msg_count
        ,   p_data                        => x_msg_data
        );

        FND_MSG_PUB.Count_And_Get
        (   p_count                       => x_msg_count
        ,   p_data                        => x_msg_data
        );

    WHEN OTHERS THEN

        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

        IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
        THEN
            FND_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Process_Move_Order'
            );
        END IF;

        --  Get message count and data
        FND_MSG_PUB.Count_And_Get
        (   p_count                       => x_msg_count
        ,   p_data                        => x_msg_data
        );
   END Process_Move_Order_Line;


END INV_Move_Order_PUB;
/

