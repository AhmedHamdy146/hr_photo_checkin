const SETTINGS_DOCTYPE = "Hr Photo Checkin Settings";
const PHOTO_FIELD = "custom_check_in_photo";

frappe.ui.form.on("Employee Checkin", {

    refresh(frm) {
        frm.trigger("toggle_photo_mandatory");
        frm.trigger("render_photo_thumbnail");
    },

    toggle_photo_mandatory(frm) {
        _get_photo_required_setting().then(required => {
            frm.toggle_reqd(PHOTO_FIELD, required);

            frm.set_df_property(
                PHOTO_FIELD,
                "description",
                required
                    ? __("Photo required — 'Require Photo on Check-in' is enabled in Hr Photo Checkin Settings.")
                    : ""
            );
        });
    },

    render_photo_thumbnail(frm) {
        const field = frm.fields_dict[PHOTO_FIELD];

        if (!field?.$wrapper || !frm.doc[PHOTO_FIELD]) {
            return;
        }

        const $wrapper = field.$wrapper;

        $wrapper.find(".hr-photo-preview").remove();

        $wrapper.prepend(`
            <div class="hr-photo-preview" style="margin-bottom:6px;">
                <img
                    src="${frm.doc[PHOTO_FIELD]}"
                    style="
                        max-height:120px;
                        border-radius:6px;
                        border:1px solid var(--border-color);
                    "
                    alt="Check-in photo preview"
                />
            </div>
        `);
    },

});

// ===========================================================================
// Internal helpers
// ===========================================================================

async function _get_photo_required_setting() {
    try {
        const value = await frappe.db.get_single_value(
            SETTINGS_DOCTYPE,
            "require_photo_on_check_in"
        );

        return Boolean(value);
    } catch (_) {
        return false;
    }
}