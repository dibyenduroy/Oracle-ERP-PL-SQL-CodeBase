CREATE OR REPLACE PACKAGE APPS.bilc_ap_inv_upload_pkg
AS
-- +===================================================================+
-- | Package Name:       bilc_ap_inv_upload_pkg                        |
-- |Description      :   This Package  is used by the WebADI as a    |
--|                    toolto push data to invoice interface after  |
-- |                      performing business validations,            |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                  |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A                     Initial draft version   |
-- +===================================================================+
   PROCEDURE bilc_inv_interface_insert (
      p_invoice_num                  IN   VARCHAR2,
      p_invoice_type_lookup_code     IN   VARCHAR2,
      p_invoice_date                 IN   VARCHAR2,
      p_vendor_name                  IN   VARCHAR2,
      p_vendor_num                   IN   VARCHAR2,
      p_vendor_site_code             IN   VARCHAR2,
      p_invoice_amount               IN   NUMBER,
      p_invoice_currency_code        IN   VARCHAR2,
      p_exchange_rate                IN   NUMBER,
      p_exchange_rate_type           IN   VARCHAR2,
      p_exchange_date                IN   VARCHAR2,
      p_terms_name                   IN   VARCHAR2,
      p_description                  IN   VARCHAR2,
      p_attribute_category           IN   VARCHAR2 DEFAULT NULL,
      p_attribute1                   IN   VARCHAR2 DEFAULT NULL,
      p_attribute2                   IN   VARCHAR2 DEFAULT NULL,
      p_attribute3                   IN   VARCHAR2 DEFAULT NULL,
      p_attribute4                   IN   VARCHAR2 DEFAULT NULL,
      p_attribute5                   IN   VARCHAR2 DEFAULT NULL,
      p_attribute6                   IN   VARCHAR2 DEFAULT NULL,
      p_attribute7                   IN   VARCHAR2 DEFAULT NULL,
      p_attribute8                   IN   VARCHAR2 DEFAULT NULL,
      p_attribute9                   IN   VARCHAR2 DEFAULT NULL,
      p_attribute10                  IN   VARCHAR2 DEFAULT NULL,
      p_attribute11                  IN   VARCHAR2 DEFAULT NULL,
      p_attribute12                  IN   VARCHAR2 DEFAULT NULL,
      p_attribute13                  IN   VARCHAR2 DEFAULT NULL,
      p_attribute14                  IN   VARCHAR2 DEFAULT NULL,
      p_attribute15                  IN   VARCHAR2 DEFAULT NULL,
      p_source                       IN   VARCHAR2,
      p_doc_category_code            IN   VARCHAR2,
      p_payment_method_lookup_code   IN   VARCHAR2 DEFAULT NULL,
      p_pay_group_lookup_code        IN   VARCHAR2 DEFAULT NULL,
      p_header_gl_date               IN   VARCHAR2,
      p_prepay_num                   IN   VARCHAR2,
      p_prepay_dist_num              IN   NUMBER DEFAULT NULL,
      p_prepay_apply_amount          IN   NUMBER DEFAULT NULL,
      p_prepay_gl_date               IN   VARCHAR2,
      p_org_id                       IN   NUMBER,
      p_line_type_lookup_code        IN   VARCHAR2,
      p_line_amount                  IN   NUMBER,
      p_dist_gl_date                 IN   VARCHAR2,
      p_line_description             IN   VARCHAR2,
      p_distribution_set_name        IN   VARCHAR2,
      p_segment1                     IN   VARCHAR2,
      p_segment2                     IN   VARCHAR2,
      p_segment3                     IN   VARCHAR2,
      p_segment4                     IN   VARCHAR2,
      p_segment5                     IN   VARCHAR2,
      p_segment6                     IN   VARCHAR2,
      p_segment7                     IN   VARCHAR2,
      --p_segment8                     IN   VARCHAR2,
      --p_segment9                     IN   VARCHAR2,
      p_context                      IN   VARCHAR2,
      p_tds_tax                      IN   VARCHAR2,
      p_wct_tax                      IN   VARCHAR2,
      p_esi_tax                      IN   VARCHAR2,
      p_line_attribute4              IN   VARCHAR2 DEFAULT NULL,
      --p_dpis                         IN   VARCHAR2,
      p_line_attribute6              IN   VARCHAR2 DEFAULT NULL,
      p_line_attribute7              IN   VARCHAR2 DEFAULT NULL,
      p_line_attribute8              IN   VARCHAR2 DEFAULT NULL,
      p_line_attribute9              IN   VARCHAR2 DEFAULT NULL,
      p_line_attribute10             IN   VARCHAR2 DEFAULT NULL,
      p_line_attribute11             IN   VARCHAR2 DEFAULT NULL,
      --p_location                     IN   VARCHAR2,
      --p_asset_category               IN   VARCHAR2,
      p_line_attribute14             IN   VARCHAR2 DEFAULT NULL,
      p_line_attribute15             IN   VARCHAR2 DEFAULT NULL
   );
END bilc_ap_inv_upload_pkg;
/