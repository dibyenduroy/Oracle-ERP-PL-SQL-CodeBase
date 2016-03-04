CREATE OR REPLACE PACKAGE APPS.bilc_ap_inv_header_upload_pkg
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
   PROCEDURE bilc_inv_header_insert (
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
      p_po_number                    IN   VARCHAR2 DEFAULT NULL,--attribute10
      p_po_line_number               IN   VARCHAR2 DEFAULT NULL,--attribute11
      p_attribute12                  IN   VARCHAR2 DEFAULT NULL,
      p_attribute13                  IN   VARCHAR2 DEFAULT NULL,
      p_attribute14                  IN   VARCHAR2 DEFAULT NULL,
      p_attribute15                  IN   VARCHAR2 DEFAULT NULL,
      p_source                       IN   VARCHAR2,
      p_doc_category_code            IN   VARCHAR2,
      p_payment_method_lookup_code   IN   VARCHAR2 DEFAULT NULL,
      p_pay_group_lookup_code        IN   VARCHAR2 DEFAULT NULL,
      p_header_gl_date               IN   VARCHAR2,
      p_org_id                       IN   NUMBER);
END bilc_ap_inv_header_upload_pkg;
/