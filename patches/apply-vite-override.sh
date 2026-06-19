#!/bin/bash
set -e

echo "=== Applying HR Photo Checkin Vite Alias Override ==="

CONFIG_FILE="/workspace/development/frappe-bench/apps/hrms/frontend/vite.config.js"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ HRMS vite.config.js not found!"
  exit 1
fi

# Add the override block if not present
if ! grep -q "HR_OVERRIDE_DIR" "$CONFIG_FILE"; then
  cat >> "$CONFIG_FILE" << 'EOF'

	// === HR PHOTO CHECKIN OVERRIDE (vite-alias) - Safe & env-gated ===
	const path = require('path');
	resolve: {
		alias: {
			// Specific override MUST come BEFORE general "@" alias
			...(process.env.HR_OVERRIDE_DIR ? {
				"@/components/CheckInPanel.vue": path.resolve(
					process.env.HR_OVERRIDE_DIR,
					"CheckInPanel.vue"
				),
				"frappe-ui": path.resolve(__dirname, "node_modules/frappe-ui"),
				"@ionic/vue": path.resolve(__dirname, "node_modules/@ionic/vue"),
				"vue": path.resolve(__dirname, "node_modules/vue"),
			} : {}),
			"@": path.resolve(__dirname, "src"),
		},
		dedupe: ["vue", "frappe-ui"],
	},
	// === END HR PHOTO CHECKIN OVERRIDE ===
EOF
  echo "✅ Vite alias override added successfully"
else
  echo "✅ Vite alias already present"
fi