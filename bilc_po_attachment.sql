/* Formatted on 2009/09/09 10:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FUNCTION apps.bilc_po_attachment (
   p_po_header_id                      NUMBER,
   p_type                              VARCHAR2
)
   RETURN VARCHAR2
AS
   lv_flag                       VARCHAR2 (1);
   lv_file_name                  VARCHAR2 (300);
   ln_po_header_id               NUMBER;

   CURSOR c_po_line
   IS
      SELECT po_line_id
        FROM po_lines_all
       WHERE po_header_id = p_po_header_id;

   CURSOR c_po_line_loc (p_header_id NUMBER)
   IS
      SELECT line_location_id
        FROM po_line_locations_all
       WHERE po_header_id = p_header_id
         AND NVL (po_release_id, 1) =
                NVL (DECODE (p_type,
                             'PO_REL', p_header_id,
                             po_release_id
                            ),
                     1
                    );
BEGIN
   lv_file_name := fnd_profile.VALUE ('BILC_PO_ATTC_FILE_NAME');

   IF p_type = 'PO'
   THEN
      BEGIN
         SELECT 'Y'
           INTO lv_flag
           FROM DUAL
          WHERE EXISTS (
                   SELECT 1
                     FROM fnd_attached_docs_form_vl fadf
                    WHERE entity_name = 'PO_HEAD'
                      AND datatype_name = 'File'
                      AND pk1_value = p_po_header_id
                      AND function_name = 'PO_POXPOEPO'
                      AND file_name = lv_file_name);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      FOR c_line IN c_po_line
      LOOP
         BEGIN
            SELECT 'Y'
              INTO lv_flag
              FROM DUAL
             WHERE EXISTS (
                      SELECT 1
                        FROM fnd_attached_docs_form_vl fadf
                       WHERE entity_name = 'PO_LINES'
                         AND datatype_name = 'File'
                         AND pk1_value = c_line.po_line_id
                         AND function_name = 'PO_POXPOEPO'
                         AND file_name = lv_file_name);
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END LOOP;

      FOR c_line_loc IN c_po_line_loc (p_po_header_id)
      LOOP
         BEGIN
            SELECT 'Y'
              INTO lv_flag
              FROM DUAL
             WHERE EXISTS (
                      SELECT 1
                        FROM fnd_attached_docs_form_vl fadf
                       WHERE entity_name = 'PO_SHIPMENTS'
                         AND datatype_name = 'File'
                         AND pk1_value = c_line_loc.line_location_id
                         AND function_name = 'PO_POXPOEPO'
                         AND file_name = lv_file_name);
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END LOOP;
   END IF;

   IF p_type = 'REL'
   THEN
      BEGIN
         SELECT DISTINCT po_header_id
                    INTO ln_po_header_id
                    FROM po_releases_all
                   WHERE po_release_id = p_po_header_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         SELECT 'Y'
           INTO lv_flag
           FROM DUAL
          WHERE EXISTS (
                   SELECT 1
                     FROM fnd_attached_docs_form_vl fadf
                    WHERE entity_name = 'PO_RELEASES'
                      AND datatype_name = 'File'
                      AND pk1_value = p_po_header_id
                      AND function_name = 'PO_POXPOERL'
                      AND file_name = lv_file_name);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      FOR c_line_loc IN c_po_line_loc (ln_po_header_id)
      LOOP
         BEGIN
            SELECT 'Y'
              INTO lv_flag
              FROM DUAL
             WHERE EXISTS (
                      SELECT 1
                        FROM fnd_attached_docs_form_vl fadf
                       WHERE entity_name = 'PO_SHIPMENTS'
                         AND datatype_name = 'File'
                         AND pk1_value = c_line_loc.line_location_id
                         AND function_name = 'PO_POXPOERL'
                         AND file_name = lv_file_name);
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END LOOP;
   END IF;

   IF lv_flag = 'Y'
   THEN
      RETURN lv_flag;
   ELSE
      RETURN 'N';
   END IF;
END;
/