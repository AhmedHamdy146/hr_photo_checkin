
frappe.listview_settings["Employee Checkin"] = {
    add_fields: ["custom_check_in_photo"],

    formatters: {
        custom_check_in_photo(value) {

            if (!value) return "";

            return `
                <img
                    src="${value}"
                    style="
                        width:40px;
                        height:40px;
                        object-fit:cover;
                        border-radius:6px;
                    "
                />
            `;
        }
    }
};