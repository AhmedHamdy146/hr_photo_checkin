/**
 * hr_photo_checkin/public/js/hr_settings.js
 *
 * Loaded via the `doctype_js` hook onto the HR Settings form.
 *
 * Why this exists
 * ---------------
 * Frappe v16 blocks adding Custom Fields to Single DocTypes owned by another
 * app — so we cannot add our toggle directly inside HR Settings.
 * Instead, we inject a button that takes the user to our own settings page
 * (Hr Photo Checkin Settings) in one click, making discovery easy without
 * touching any hrms source.
 */

frappe.ui.form.on("HR Settings", {
    refresh(frm) {
        frm.add_custom_button(
            __("Photo Check-in Settings"),
            () => {
                frappe.set_route(
                    "Form",
                    "Hr Photo Checkin Settings",
                    "Hr Photo Checkin Settings"
                );
            },
            __("Integrations")  // groups the button under an "Integrations" dropdown
                                // remove this third argument if you want a top-level button
        );
    }
});