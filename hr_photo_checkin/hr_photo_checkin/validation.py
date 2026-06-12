import frappe
from frappe import _

SETTINGS_DOCTYPE = "Hr Photo Checkin Settings"


def require_photo(doc, method=None):
    """Validate that a check-in photo is present when the feature is enabled.
    Raises:
        frappe.ValidationError: when the toggle is on and the photo is missing."""
    if not _photo_required():
        return  # feature is off — nothing to validate
    if not doc.custom_check_in_photo:
        frappe.throw(
            msg=_(
                "A check-in photo is required. Please upload a photo before saving."
                " (Hr Photo Checkin Settings → Require Photo on Check-in is enabled)"
            ),
            exc=frappe.ValidationError,
            title=_("Photo Required"),
        )


def _photo_required() -> bool:
    """Return True when the Hr Photo Checkin Settings toggle is switched on."""
    try:
        return bool(
            frappe.db.get_single_value(SETTINGS_DOCTYPE, "require_photo_on_check_in")
        )
    except Exception:
        # Graceful degradation: if the DocType hasn't been migrated yet,
        # treat the feature as disabled rather than crashing every save.
        return False
