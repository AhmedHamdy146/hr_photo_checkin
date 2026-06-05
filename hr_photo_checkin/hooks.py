app_name = "hr_photo_checkin"
app_title = "Hr Photo Checkin"
app_publisher = "Ahmed Hamdy"
app_description = "أHr photo checkin"
app_email = "ah.hamd221@gmail.com"
app_license = "mit"

# Apps
# ------------------

required_apps = ["hrms"]

# ---------------------------------------------------------------------------
# Fixtures
# Only the Employee Checkin custom field is a fixture.
# The toggle lives in our own Single DocType (Hr Photo Checkin Settings)
# which is part of this app — no fixture needed for it.
# ---------------------------------------------------------------------------
fixtures = [
    {
        "dt": "Custom Field",
        "filters": [["dt", "=", "Employee Checkin"]]
    },
]

# ---------------------------------------------------------------------------
# doc_events — validation hook on Employee Checkin
# Never touches hrms source;
# ---------------------------------------------------------------------------
doc_events = {
    "Employee Checkin": {
        "validate": "hr_photo_checkin.hr_photo_checkin.validation.require_photo",
    }
}


# doctype_js
#   employee_checkin.js  — mandatory field + photo thumbnail on the form
#   hr_settings.js       — injects a "Photo Check-in Settings" button into
#                          the HR Settings form so the user can reach our
#                          settings page without leaving HR Settings.
#                          (We cannot add fields to HR Settings directly —
#                          Frappe v16 blocks Custom Fields on Single DocTypes
#                          that belong to another app.)
# ---------------------------------------------------------------------------
doctype_js = {
    "HR Settings":      "public/js/hr_settings.js",
}
doctype_list_js = {
    "Employee Checkin": "public/js/employee_checkin_list.js",
}
 

