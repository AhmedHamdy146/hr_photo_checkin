/**
 * hr_photo_checkin/public/js/hr_settings.js
 *
 * Loaded via the `doctype_js` hook onto the HR Settings form.
 *
 * What it does
 * ------------
 * Frappe v16 blocks adding Custom Fields to Single DocTypes owned by another
 * app, so we cannot add our toggle directly to HR Settings via fixtures.
 *
 * Instead, we inject a native-looking checkbox row directly under the
 * "Attendance Settings" section at runtime using JavaScript.
 *
 * The checkbox reads its initial value from Hr Photo Checkin Settings and
 * writes back to it on change — so from the user's perspective it looks and
 * behaves exactly like a real HR Settings field, but the value is actually
 * stored in our own Single DocType.
 */

const SETTINGS_DOCTYPE = "Hr Photo Checkin Settings";
const FIELD_NAME = "require_photo_on_check_in";
const INJECT_AFTER = "allow_geolocation_tracking"; // field name in HR Settings

frappe.ui.form.on("HR Settings", {

    async refresh(frm) {
        await _inject_photo_checkin_toggle(frm);
    },

});

// ---------------------------------------------------------------------------
// Core injection
// ---------------------------------------------------------------------------

async function _inject_photo_checkin_toggle(frm) {
    // Avoid double-injecting on repeated refresh
    if (frm.fields_dict[INJECT_AFTER]?.$wrapper
        .closest(".form-column")
        .find(".hr-photo-checkin-row").length) {
        return;
    }

    // Read current value from our own Single DocType
    let currentValue = false;
    try {
        const val = await frappe.db.get_single_value(SETTINGS_DOCTYPE, FIELD_NAME);
        currentValue = Boolean(val);
    } catch (_) {
        // Settings DocType not yet migrated — render unchecked, silently
    }

    // Build a row that matches Frappe v16's native checkbox layout exactly
    const checked = currentValue ? "checked" : "";
    const $row = $(`
        <div class="hr-photo-checkin-row frappe-control" style="margin-top: 8px;">
            <div class="checkbox" style="display:flex; align-items:center; gap:8px;">
                <input type="checkbox"
                       id="hr-photo-checkin-toggle"
                       class="input-with-feedback"
                       ${checked}
                       style="width:14px; height:14px; cursor:pointer; margin:0;" />
                <label for="hr-photo-checkin-toggle"
                       style="margin:0; font-weight:400; cursor:pointer; font-size:var(--text-md); color:var(--text-color);">
                    ${__("Require Photo on Check-in")}
                </label>
            </div>
        </div>
    `);

    // Insert immediately after the "Allow Geolocation Tracking" row
    const $anchor = frm.fields_dict[INJECT_AFTER]?.$wrapper;
    if ($anchor?.length) {
        $anchor.after($row);
    } else {
        // Fallback: append to the Attendance Settings section if anchor not found
        frm.fields_dict["allow_employee_checkin_from_mobile_app"]
            ?.$wrapper.closest(".section-body").append($row);
    }

    // Wire up the change handler — saves directly to Hr Photo Checkin Settings
    $row.find("input[type=checkbox]").on("change", async function () {
        const $checkbox = $(this);
        const newValue = this.checked ? 1 : 0;

        frappe.call({
            method: "frappe.client.set_value",
            args: {
                doctype: SETTINGS_DOCTYPE,
                name: SETTINGS_DOCTYPE,  // Single DocType: name == doctype
                fieldname: FIELD_NAME,
                value: newValue,
            },
            callback(_r) {
                frappe.show_alert({
                    message: __(
                        newValue
                            ? "Photo check-in requirement enabled."
                            : "Photo check-in requirement disabled."
                    ),
                    indicator: "green",
                });
            },
            error() {
                frappe.show_alert({
                    message: __("Could not save setting. See console for details."),
                    indicator: "red",
                });
                // Revert checkbox so it doesn't show a false state
                $checkbox.prop("checked", !this.checked);
            },
        });
    });
}