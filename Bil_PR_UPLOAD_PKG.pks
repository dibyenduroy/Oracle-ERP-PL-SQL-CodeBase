/* Formatted on 2009/06/15 09:38 (Formatter Plus v4.8.7) */
CREATE OR REPLACE PACKAGE bil_pr_upload_pkg
AS
   g_miss_char               VARCHAR2 (1)  := NULL;
   g_miss_num                NUMBER        := NULL;
   g_miss_date               DATE          := NULL;
   g_interface_source_code   VARCHAR2 (30) := 'MXM';
   g_source_type_code        VARCHAR2 (30) := 'Vendor';
   g_destination_type_code   VARCHAR2 (30) := 'EXPENSE';
   g_authorization_status    VARCHAR2 (30) := 'APPROVED';
  

   TYPE pr_rec_type IS RECORD (
      pr_num                          NUMBER         := g_miss_num,
      pr_desc                         VARCHAR2 (200) := g_miss_char,
      req_type                        VARCHAR2 (200)
                                                    := 'Purchase Requisition',
      preparer                        VARCHAR2 (200) := g_miss_char,
      status                          VARCHAR2 (30)  := g_miss_char,
      maximo_work_order               NUMBER         := g_miss_num,
      maximo_pr_number                NUMBER         := g_miss_num,
      operating_unit                  NUMBER         := g_miss_num,
      operating_unit_name             VARCHAR2 (300) := g_miss_char,
      creation_date                   DATE           := g_miss_date,
      line_num                        NUMBER         := g_miss_num,
      line_type                       VARCHAR2 (60)  := g_miss_char,
      pr_line_desc                    VARCHAR2 (200) := g_miss_char,
      item                            NUMBER         := g_miss_num,
      item_name                       VARCHAR2 (300) := g_miss_char,
      item_category                   VARCHAR2 (150) := g_miss_char,
      uom                             VARCHAR2 (30)  := g_miss_char,
      quantity                        NUMBER         := g_miss_num,
      price                           NUMBER         := g_miss_num,
      need_by_date                    DATE           := g_miss_date,
      currency                        VARCHAR2 (30)  := 'INR',
      destination                     NUMBER         := g_miss_num,
      requester                       VARCHAR2 (100) := g_miss_char,
      organization_code               VARCHAR2 (100) := g_miss_char,
      SOURCE                          VARCHAR2 (30)  := 'MXM',
      vendor_id                       NUMBER         := g_miss_num,
      vendor_site_id                  NUMBER         := g_miss_num,
      location_id                     NUMBER         := g_miss_num,
      contact                         VARCHAR2 (200) := g_miss_char,
      process_flag                    VARCHAR2 (30)  := g_miss_char,
      charge_account_d                VARCHAR2 (60)  := g_miss_char,
      accrual_account_d               VARCHAR2 (60)  := g_miss_char,
      variance_account                VARCHAR2 (60)  := g_miss_char,
      error_message                   VARCHAR2 (60)  := g_miss_char,
      preparer_id                     NUMBER         := g_miss_num,
      requester_id                    NUMBER         := g_miss_num,
      created_by                      NUMBER         := g_miss_num,
      last_update_date                DATE           := g_miss_date,
      staging_id                      NUMBER         := g_miss_num,
      code_combination_id             NUMBER         := g_miss_num,
      organization_id                 NUMBER         := g_miss_num,
      vendor_name                     VARCHAR2 (100) := g_miss_char,
      vendor_site_code                VARCHAR2 (100) := g_miss_char,
      transaction_id                  NUMBER         := g_miss_num,
      request_id                      NUMBER         := g_miss_num,
      program_id                      NUMBER         := g_miss_num,
      program_application_id          NUMBER         := g_miss_num,
      program_update_date             DATE           := g_miss_date,
      last_updated_by                 NUMBER         := g_miss_num,
      last_update_login               NUMBER         := g_miss_num,
      interface_source_line_id        NUMBER         := g_miss_num,
      source_type_code                VARCHAR2 (25)  := g_miss_char,
      requisition_header_id           NUMBER         := g_miss_num,
      requisition_line_id             NUMBER         := g_miss_num,
      req_distribution_id             NUMBER         := g_miss_num,
      batch_id                        NUMBER         := g_miss_num,
      group_code                      VARCHAR2 (30)  := g_miss_char,
      delete_enabled_flag             VARCHAR2 (1)   := g_miss_char,
      update_enabled_flag             VARCHAR2 (1)   := g_miss_char,
      approver_id                     NUMBER (9)     := g_miss_num,
      approver_name                   VARCHAR2 (240) := g_miss_char,
      approval_path_id                NUMBER         := g_miss_num,
      note_to_approver                VARCHAR2 (480) := g_miss_char,
      autosource_flag                 VARCHAR2 (1)   := g_miss_char,
      req_number_segment1             VARCHAR2 (20)  := g_miss_char,
      req_number_segment2             VARCHAR2 (20)  := g_miss_char,
      req_number_segment3             VARCHAR2 (20)  := g_miss_char,
      req_number_segment4             VARCHAR2 (20)  := g_miss_char,
      req_number_segment5             VARCHAR2 (20)  := g_miss_char,
      header_description              VARCHAR2 (240) := g_miss_char,
      header_attribute_category       VARCHAR2 (30)  := g_miss_char,
      header_attribute1               VARCHAR2 (150) := g_miss_char,
      header_attribute2               VARCHAR2 (150) := g_miss_char,
      header_attribute3               VARCHAR2 (150) := g_miss_char,
      header_attribute4               VARCHAR2 (150) := g_miss_char,
      header_attribute5               VARCHAR2 (150) := g_miss_char,
      header_attribute6               VARCHAR2 (150) := g_miss_char,
      header_attribute7               VARCHAR2 (150) := g_miss_char,
      header_attribute8               VARCHAR2 (150) := g_miss_char,
      header_attribute9               VARCHAR2 (150) := g_miss_char,
      header_attribute10              VARCHAR2 (150) := g_miss_char,
      header_attribute11              VARCHAR2 (150) := g_miss_char,
      header_attribute12              VARCHAR2 (150) := g_miss_char,
      header_attribute13              VARCHAR2 (150) := g_miss_char,
      header_attribute14              VARCHAR2 (150) := g_miss_char,
      urgent_flag                     VARCHAR2 (1)   := g_miss_char,
      header_attribute15              VARCHAR2 (150) := g_miss_char,
      rfq_required_flag               VARCHAR2 (1)   := g_miss_char,
      justification                   VARCHAR2 (480) := g_miss_char,
      note_to_buyer                   VARCHAR2 (480) := g_miss_char,
      note_to_receiver                VARCHAR2 (480) := g_miss_char,
      item_segment1                   VARCHAR2 (40)  := g_miss_char,
      item_segment2                   VARCHAR2 (40)  := g_miss_char,
      item_segment3                   VARCHAR2 (40)  := g_miss_char,
      item_segment4                   VARCHAR2 (40)  := g_miss_char,
      item_segment5                   VARCHAR2 (40)  := g_miss_char,
      item_segment6                   VARCHAR2 (40)  := g_miss_char,
      item_segment7                   VARCHAR2 (40)  := g_miss_char,
      item_segment8                   VARCHAR2 (40)  := g_miss_char,
      item_segment9                   VARCHAR2 (40)  := g_miss_char,
      item_segment10                  VARCHAR2 (40)  := g_miss_char,
      item_segment11                  VARCHAR2 (40)  := g_miss_char,
      item_segment12                  VARCHAR2 (40)  := g_miss_char,
      item_segment13                  VARCHAR2 (40)  := g_miss_char,
      item_segment14                  VARCHAR2 (40)  := g_miss_char,
      item_segment15                  VARCHAR2 (40)  := g_miss_char,
      item_segment16                  VARCHAR2 (40)  := g_miss_char,
      item_segment17                  VARCHAR2 (40)  := g_miss_char,
      item_segment18                  VARCHAR2 (40)  := g_miss_char,
      item_segment19                  VARCHAR2 (40)  := g_miss_char,
      item_segment20                  VARCHAR2 (40)  := g_miss_char,
      item_revision                   VARCHAR2 (3)   := g_miss_char,
      charge_account_segment1         VARCHAR2 (25)  := g_miss_char,
      charge_account_segment2         VARCHAR2 (25)  := g_miss_char,
      charge_account_segment3         VARCHAR2 (25)  := g_miss_char,
      charge_account_segment4         VARCHAR2 (25)  := g_miss_char,
      charge_account_segment5         VARCHAR2 (25)  := g_miss_char,
      charge_account_segment6         VARCHAR2 (25)  := g_miss_char,
      charge_account_segment7         VARCHAR2 (25)  := g_miss_char,
      charge_account_segment8         VARCHAR2 (25)  := g_miss_char,
      charge_account_segment9         VARCHAR2 (25)  := g_miss_char,
      charge_account_segment10        VARCHAR2 (25)  := g_miss_char,
      charge_account_segment11        VARCHAR2 (25)  := g_miss_char,
      charge_account_segment12        VARCHAR2 (25)  := g_miss_char,
      charge_account_segment13        VARCHAR2 (25)  := g_miss_char,
      charge_account_segment14        VARCHAR2 (25)  := g_miss_char,
      charge_account_segment15        VARCHAR2 (25)  := g_miss_char,
      charge_account_segment16        VARCHAR2 (25)  := g_miss_char,
      charge_account_segment17        VARCHAR2 (25)  := g_miss_char,
      charge_account_segment18        VARCHAR2 (25)  := g_miss_char,
      charge_account_segment19        VARCHAR2 (25)  := g_miss_char,
      charge_account_segment20        VARCHAR2 (25)  := g_miss_char,
      charge_account_segment21        VARCHAR2 (25)  := g_miss_char,
      charge_account_segment22        VARCHAR2 (25)  := g_miss_char,
      charge_account_segment23        VARCHAR2 (25)  := g_miss_char,
      charge_account_segment24        VARCHAR2 (25)  := g_miss_char,
      charge_account_segment25        VARCHAR2 (25)  := g_miss_char,
      charge_account_segment26        VARCHAR2 (25)  := g_miss_char,
      charge_account_segment27        VARCHAR2 (25)  := g_miss_char,
      charge_account_segment28        VARCHAR2 (25)  := g_miss_char,
      charge_account_segment29        VARCHAR2 (25)  := g_miss_char,
      charge_account_segment30        VARCHAR2 (25)  := g_miss_char,
      category_id                     NUMBER         := g_miss_num,
      category_segment1               VARCHAR2 (40)  := g_miss_char,
      category_segment2               VARCHAR2 (40)  := g_miss_char,
      category_segment3               VARCHAR2 (40)  := g_miss_char,
      category_segment4               VARCHAR2 (40)  := g_miss_char,
      category_segment5               VARCHAR2 (40)  := g_miss_char,
      category_segment6               VARCHAR2 (40)  := g_miss_char,
      category_segment7               VARCHAR2 (40)  := g_miss_char,
      category_segment8               VARCHAR2 (40)  := g_miss_char,
      category_segment9               VARCHAR2 (40)  := g_miss_char,
      category_segment10              VARCHAR2 (40)  := g_miss_char,
      category_segment11              VARCHAR2 (40)  := g_miss_char,
      category_segment12              VARCHAR2 (40)  := g_miss_char,
      category_segment13              VARCHAR2 (40)  := g_miss_char,
      category_segment14              VARCHAR2 (40)  := g_miss_char,
      category_segment15              VARCHAR2 (40)  := g_miss_char,
      category_segment16              VARCHAR2 (40)  := g_miss_char,
      category_segment17              VARCHAR2 (40)  := g_miss_char,
      category_segment18              VARCHAR2 (40)  := g_miss_char,
      category_segment19              VARCHAR2 (40)  := g_miss_char,
      category_segment20              VARCHAR2 (40)  := g_miss_char,
      uom_code                        VARCHAR2 (3)   := g_miss_char,
      line_type_id                    NUMBER         := g_miss_num,
      un_number_id                    NUMBER         := g_miss_num,
      un_number                       VARCHAR2 (25)  := g_miss_char,
      hazard_class_id                 NUMBER         := g_miss_num,
      hazard_class                    VARCHAR2 (40)  := g_miss_char,
      must_use_sugg_vendor_flag       VARCHAR2 (10)  := g_miss_char,
      reference_num                   VARCHAR2 (25)  := g_miss_char,
      wip_entity_id                   NUMBER         := g_miss_num,
      wip_line_id                     NUMBER         := g_miss_num,
      wip_operation_seq_num           NUMBER         := g_miss_num,
      wip_resource_seq_num            NUMBER         := g_miss_num,
      wip_repetitive_schedule_id      NUMBER         := g_miss_num,
      project_num                     VARCHAR2 (25)  := g_miss_char,
      task_num                        VARCHAR2 (25)  := g_miss_char,
      expenditure_type                VARCHAR2 (30)  := g_miss_char,
      source_organization_id          NUMBER         := g_miss_num,
      source_organization_code        VARCHAR2 (3)   := g_miss_char,
      source_subinventory             VARCHAR2 (10)  := g_miss_char,
      destination_organization_code   VARCHAR2 (3)   := g_miss_char,
      destination_subinventory        VARCHAR2 (10)  := g_miss_char,
      deliver_to_location_id          NUMBER         := g_miss_num,
      deliver_to_location_code        VARCHAR2 (60)  := g_miss_char,
      suggested_buyer_id              NUMBER (9)     := g_miss_num,
      suggested_buyer_name            VARCHAR2 (240) := g_miss_char,
      suggested_vendor_name           VARCHAR2 (240) := g_miss_char,
      suggested_vendor_site           VARCHAR2 (15)  := g_miss_char,
      suggested_vendor_site_id        NUMBER         := g_miss_num,
      suggested_vendor_contact        VARCHAR2 (80)  := g_miss_char,
      suggested_vendor_contact_id     NUMBER         := g_miss_num,
      suggested_vendor_phone          VARCHAR2 (25)  := g_miss_char,
      suggested_vendor_item_num       VARCHAR2 (25)  := g_miss_char,
      line_attribute_category         VARCHAR2 (30)  := g_miss_char,
      line_attribute1                 VARCHAR2 (150) := g_miss_char,
      line_attribute2                 VARCHAR2 (150) := g_miss_char,
      line_attribute3                 VARCHAR2 (150) := g_miss_char,
      line_attribute4                 VARCHAR2 (150) := g_miss_char,
      line_attribute5                 VARCHAR2 (150) := g_miss_char,
      line_attribute6                 VARCHAR2 (150) := g_miss_char,
      line_attribute7                 VARCHAR2 (150) := g_miss_char,
      line_attribute8                 VARCHAR2 (150) := g_miss_char,
      line_attribute9                 VARCHAR2 (150) := g_miss_char,
      line_attribute10                VARCHAR2 (150) := g_miss_char,
      line_attribute11                VARCHAR2 (150) := g_miss_char,
      line_attribute12                VARCHAR2 (150) := g_miss_char,
      line_attribute13                VARCHAR2 (150) := g_miss_char,
      line_attribute14                VARCHAR2 (150) := g_miss_char,
      line_attribute15                VARCHAR2 (150) := g_miss_char,
      note1_id                        NUMBER         := g_miss_num,
      note2_id                        NUMBER         := g_miss_num,
      note3_id                        NUMBER         := g_miss_num,
      note4_id                        NUMBER         := g_miss_num,
      note5_id                        NUMBER         := g_miss_num,
      note6_id                        NUMBER         := g_miss_num,
      note7_id                        NUMBER         := g_miss_num,
      note8_id                        NUMBER         := g_miss_num,
      note9_id                        NUMBER         := g_miss_num,
      note10_id                       NUMBER         := g_miss_num,
      note1_title                     VARCHAR2 (80)  := g_miss_char,
      note2_title                     VARCHAR2 (80)  := g_miss_char,
      note3_title                     VARCHAR2 (80)  := g_miss_char,
      note4_title                     VARCHAR2 (80)  := g_miss_char,
      note5_title                     VARCHAR2 (80)  := g_miss_char,
      note6_title                     VARCHAR2 (80)  := g_miss_char,
      note7_title                     VARCHAR2 (80)  := g_miss_char,
      note8_title                     VARCHAR2 (80)  := g_miss_char,
      note9_title                     VARCHAR2 (80)  := g_miss_char,
      note10_title                    VARCHAR2 (80)  := g_miss_char,
      gl_date                         DATE           := g_miss_date,
      dist_attribute_category         VARCHAR2 (30)  := g_miss_char,
      distribution_attribute1         VARCHAR2 (150) := g_miss_char,
      distribution_attribute2         VARCHAR2 (150) := g_miss_char,
      distribution_attribute3         VARCHAR2 (150) := g_miss_char,
      distribution_attribute4         VARCHAR2 (150) := g_miss_char,
      distribution_attribute5         VARCHAR2 (150) := g_miss_char,
      distribution_attribute6         VARCHAR2 (150) := g_miss_char,
      distribution_attribute7         VARCHAR2 (150) := g_miss_char,
      distribution_attribute8         VARCHAR2 (150) := g_miss_char,
      distribution_attribute9         VARCHAR2 (150) := g_miss_char,
      distribution_attribute10        VARCHAR2 (150) := g_miss_char,
      distribution_attribute11        VARCHAR2 (150) := g_miss_char,
      distribution_attribute12        VARCHAR2 (150) := g_miss_char,
      distribution_attribute13        VARCHAR2 (150) := g_miss_char,
      distribution_attribute14        VARCHAR2 (150) := g_miss_char,
      distribution_attribute15        VARCHAR2 (150) := g_miss_char,
      bom_resource_id                 NUMBER         := g_miss_num,
      budget_account_id               NUMBER         := g_miss_num,
      ussgl_transaction_code          VARCHAR2 (30)  := g_miss_char,
      government_context              VARCHAR2 (30)  := g_miss_char,
      currency_unit_price             NUMBER         := g_miss_num,
      rate                            NUMBER         := g_miss_num,
      rate_date                       DATE           := g_miss_date,
      rate_type                       VARCHAR2 (30)  := g_miss_char,
      prevent_encumbrance_flag        VARCHAR2 (1)   := g_miss_char,
      autosource_doc_header_id        NUMBER         := g_miss_num,
      autosource_doc_line_num         NUMBER         := g_miss_num,
      project_accounting_context      VARCHAR2 (30)  := g_miss_char,
      expenditure_organization_id     NUMBER         := g_miss_num,
      project_id                      NUMBER         := g_miss_num,
      task_id                         NUMBER         := g_miss_num,
      end_item_unit_number            VARCHAR2 (30)  := g_miss_char,
      expenditure_item_date           DATE           := g_miss_date,
      document_type_code              VARCHAR2 (25)  := g_miss_char,
      transaction_reason_code         VARCHAR2 (25)  := g_miss_char,
      allocation_type                 VARCHAR2 (25)  := g_miss_char,
      allocation_value                NUMBER         := g_miss_num,
      multi_distributions             VARCHAR2 (1)   := g_miss_char,
      req_dist_sequence_id            NUMBER         := g_miss_num,
      kanban_card_id                  NUMBER         := g_miss_num,
      emergency_po_num                VARCHAR2 (20)  := g_miss_char,
      award_id                        NUMBER (15)    := g_miss_num,
      tax_code_id                     NUMBER         := g_miss_num,
      oke_contract_header_id          NUMBER         := g_miss_num,
      oke_contract_num                VARCHAR2 (120) := g_miss_char,
      oke_contract_version_id         NUMBER         := g_miss_num,
      oke_contract_line_id            NUMBER         := g_miss_num,
      oke_contract_line_num           VARCHAR2 (150) := g_miss_char,
      oke_contract_deliverable_id     NUMBER         := g_miss_num,
      oke_contract_deliverable_num    VARCHAR2 (150) := g_miss_char,
      secondary_unit_of_measure       VARCHAR2 (25)  := g_miss_char,
      secondary_uom_code              VARCHAR2 (3)   := g_miss_char,
      secondary_quantity              NUMBER         := g_miss_num,
      preferred_grade                 VARCHAR2 (25)  := g_miss_char,
      vmi_flag                        VARCHAR2 (1)   := g_miss_char,
      tax_user_override_flag          VARCHAR2 (1)   := g_miss_char,
      amount                          NUMBER         := g_miss_num,
      currency_amount                 NUMBER         := g_miss_num,
      ship_method                     VARCHAR2 (30)  := g_miss_char,
      estimated_pickup_date           DATE           := g_miss_date,
      base_unit_price                 NUMBER         := g_miss_num,
      negotiated_by_preparer_flag     VARCHAR2 (1)   := g_miss_char
   );

   TYPE pr_tbl_type IS TABLE OF pr_rec_type
      INDEX BY BINARY_INTEGER;

--  Variables representing missing records and tables
   g_pr_tbl_type             pr_tbl_type;

   PROCEDURE dummy_proc (
      p_item_id                 NUMBER DEFAULT NULL,
      p_organization_id         NUMBER DEFAULT NULL,
      ERROR_CODE          OUT   VARCHAR2,
      error_message       OUT   VARCHAR2,
      error_severity      OUT   NUMBER,
      error_status        OUT   NUMBER
   );

   PROCEDURE bil_pr_intrfce_upload (p_pr_rec IN pr_tbl_type := g_pr_tbl_type);
END bil_pr_upload_pkg;
