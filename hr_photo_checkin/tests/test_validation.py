import frappe
from frappe.tests.utils import FrappeTestCase


class TestPhotoCheckinValidation(FrappeTestCase):

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        # Make sure the settings doc exists in the DB
        frappe.get_single("Hr Photo Checkin Settings").save()

    def setUp(self):
        # Reset toggle to OFF before every test so tests don't bleed into each other
        settings = frappe.get_single("Hr Photo Checkin Settings")
        settings.require_photo_on_check_in = 0   # not require_photo_on_check_in
        settings.save()
        self._inserted_docs = []

    def tearDown(self):
        # Clean up any records inserted during the test
        for name in self._inserted_docs:
            frappe.delete_doc("Employee Checkin", name, force=True)
        frappe.db.commit()

    def _create_checkin(self, photo=None):
        employee = frappe.db.get_value("Employee", {}, "name")
        if not employee:
            self.skipTest("No Employee record found in test database.")

        doc = frappe.new_doc("Employee Checkin")
        doc.employee = employee
        doc.log_type = "IN"
        doc.time = frappe.utils.now()
        doc.custom_check_in_photo = photo or ""
        return doc

    def _toggle(self, value):
        settings = frappe.get_single("Hr Photo Checkin Settings")
        settings.require_photo_on_check_in = value  # not require_photo_on_check_in
        settings.save()

    # ------------------------------------------------------------------
    # Case 1 — Toggle ON + photo present → passes
    # ------------------------------------------------------------------
    def test_toggle_on_photo_present(self):
        """Toggle ON + photo present → insert succeeds."""
        self._toggle(1)
        doc = self._create_checkin(photo="/files/test-photo.jpg")
        doc.insert()
        self._inserted_docs.append(doc.name)
        self.assertTrue(doc.name)

    # ------------------------------------------------------------------
    # Case 2 — Toggle ON + photo missing → ValidationError
    # ------------------------------------------------------------------
    def test_toggle_on_photo_missing(self):
        """Toggle ON + photo missing → ValidationError raised."""
        self._toggle(1)
        doc = self._create_checkin(photo=None)
        with self.assertRaises(frappe.ValidationError):
            doc.insert()

    # ------------------------------------------------------------------
    # Case 3 — Toggle OFF + photo missing → passes (no regression)
    # ------------------------------------------------------------------
    def test_toggle_off_photo_missing(self):
        """Toggle OFF + photo missing → insert succeeds."""
        self._toggle(0)
        doc = self._create_checkin(photo=None)
        doc.insert()
        self._inserted_docs.append(doc.name)
        self.assertTrue(doc.name)