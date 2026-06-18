import base64
import frappe
from frappe import _
from frappe.utils import flt
from frappe.utils.file_manager import save_file

_EXT_BY_MIME = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp"}
MAX_SELFIE_BYTES = 5 * 1024 * 1024  # 5 MB

def _save_selfie(selfie_data_url):
    """Decode a base64 data URL into a private File. Returns the File doc."""
    if not selfie_data_url or not selfie_data_url.startswith("data:"):
        frappe.throw(_("A valid selfie image is required."))
    header, _sep, b64_data = selfie_data_url.partition(",")
    if not b64_data:
        frappe.throw(_("A valid selfie image is required."))
    if len(b64_data) * 3 // 4 > MAX_SELFIE_BYTES:
        frappe.throw(_("Selfie image is too large (max 5 MB)."))
    mime = header[len("data:"):].split(";", 1)[0]
    ext = _EXT_BY_MIME.get(mime, ".jpg")
    content = base64.b64decode(b64_data)
    filename = f"checkin-selfie-{frappe.generate_hash(length=10)}{ext}"
    return save_file(filename, content, None, None, decode=False, is_private=1)

@frappe.whitelist()
def create_checkin(log_type, latitude, longitude, selfie):
    if log_type not in ("IN", "OUT"):
        frappe.throw(_("log_type must be IN or OUT."))
    employee = frappe.db.get_value("Employee", {"user_id": frappe.session.user}, "name")
    if not employee:
        frappe.throw(_("No Employee is linked to your user account."))
    file_doc = _save_selfie(selfie)
    checkin = frappe.new_doc("Employee Checkin")
    checkin.employee = employee
    checkin.log_type = log_type
    checkin.time = frappe.utils.now_datetime()
    checkin.latitude = flt(latitude)
    checkin.longitude = flt(longitude)
    checkin.custom_check_in_photo = file_doc.file_url
    checkin.insert(ignore_permissions=True)
    frappe.db.set_value(
        "File",
        file_doc.name,
        {
            "attached_to_doctype": "Employee Checkin",
            "attached_to_name": checkin.name,
            "attached_to_field": "custom_check_in_photo",
        },
    )
    return {"name": checkin.name, "selfie": file_doc.file_url}

@frappe.whitelist()
def upload_selfie(selfie):
    """Desk helper: store a captured selfie and return its file_url."""
    return {"file_url": _save_selfie(selfie).file_url}