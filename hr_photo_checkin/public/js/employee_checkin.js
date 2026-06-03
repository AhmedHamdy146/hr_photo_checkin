/**
 * hr_photo_checkin/public/js/employee_checkin.js
 *
 * Loaded via the `doctype_js` hook — extends (never replaces) the standard
 * Employee Checkin form script.
 *
 * What it does
 * ------------
 * 1. Form view: when the photo-required toggle is on, marks check_in_photo
 *    as mandatory client-side so the user gets instant feedback before Save.
 *
 * 2. Form view: shows a small thumbnail preview when a photo is already set.
 *
 * 3. List view: the check_in_photo field shows thumbnails inline
 *    (works via in_list_view: 1 on the fixture field — no extra JS needed).
 *
 * Settings source: Hr Photo Checkin Settings (our own Single DocType).
 * We cannot read from HR Settings directly — Frappe v16 blocks adding
 * Custom Fields to Single DocTypes owned by another app.
 */

const SETTINGS_DOCTYPE = "Hr Photo Checkin Settings";

frappe.ui.form.on("Employee Checkin", {
    // -----------------------------------------------------------------------
    // refresh — runs when the form loads or is refreshed
    // -----------------------------------------------------------------------
    refresh(frm) {
        frm.trigger("toggle_photo_mandatory");
        frm.trigger("render_photo_thumbnail");
    },

    // -----------------------------------------------------------------------
    // toggle_photo_mandatory
    // Mark check_in_photo as required on the form when the setting is on.
    // Result is cached per page load so we don't hammer the server.
    // -----------------------------------------------------------------------
    toggle_photo_mandatory(frm) {
        _get_photo_required_setting().then(required => {
            frm.toggle_reqd("check_in_photo", required);
            if (required && !frm.doc.check_in_photo) {
                frm.set_df_property(
                    "check_in_photo",
                    "description",
                    __("Photo required — 'Require Photo on Check-in' is enabled in Hr Photo Checkin Settings.")
                );
            }
        });
    },

    // -----------------------------------------------------------------------
    // render_photo_thumbnail
    // Shows a small preview above the Attach Image field when a photo exists.
    // -----------------------------------------------------------------------
    render_photo_thumbnail(frm) {
        if (!frm.doc.check_in_photo) return;

        const $wrapper = frm.fields_dict["check_in_photo"].$wrapper;
        $wrapper.find(".hr-photo-preview").remove(); // avoid duplicates on refresh
        $wrapper.prepend(
            `<div class="hr-photo-preview" style="margin-bottom:6px;">
                <img src="${frm.doc.check_in_photo}"
                     style="max-height:120px;border-radius:6px;border:1px solid var(--border-color);"
                     alt="Check-in photo preview" />
             </div>`
        );
    },
});

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

let _cached_setting = null;

async function _get_photo_required_setting() {
    if (_cached_setting !== null) return _cached_setting;
    try {
        const r = await frappe.db.get_single_value(
            SETTINGS_DOCTYPE,
            "require_photo_on_check_in"
        );
        _cached_setting = Boolean(r);
    } catch (_) {
        _cached_setting = false;
    }
    return _cached_setting;
}