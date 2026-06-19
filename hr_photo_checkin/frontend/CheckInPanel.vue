<!--
  selfie_checkin override of Frappe HR's src/components/CheckInPanel.vue.
  Wired in via an env-gated Vite alias (HR_OVERRIDE_DIR) in hrms/frontend/vite.config.js.
  Adds a required live selfie to the stock check-in modal and submits through
  selfie_checkin.api.create_checkin (which enforces the selfie + HRMS geofence).
  All "@/..." imports still resolve to HRMS's own src via the "@" alias.
-->
<template>
	<div class="flex flex-col bg-white rounded w-full py-6 px-4 border-none">
		<h2 class="text-lg font-bold text-gray-900">
			{{ __("Hey, {0} 👋", [employee?.data?.first_name]) }}
		</h2>

		<template v-if="settings.data?.allow_employee_checkin_from_mobile_app">
			<div class="font-medium text-sm text-gray-500 mt-1.5" v-if="lastLog">
				<span>{{ __("Last {0} was at {1}", [__(lastLogType), formatTimestamp(lastLog.time)]) }}</span>
				<span class="whitespace-pre"> &middot; </span>
				<router-link :to="{ name: 'EmployeeCheckinListView' }" v-slot="{ navigate }">
					<span @click="navigate" class="underline">View List</span>
				</router-link>
			</div>
			<Button
				class="mt-4 mb-1 drop-shadow-sm py-5 text-base"
				id="open-checkin-modal"
				@click="handleEmployeeCheckin"
			>
				<template #prefix>
					<FeatherIcon
						:name="nextAction.action === 'IN' ? 'arrow-right-circle' : 'arrow-left-circle'"
						class="w-4"
					/>
				</template>
				{{ nextAction.label }}
			</Button>
		</template>

		<div v-else class="font-medium text-sm text-gray-500 mt-1.5">
			{{ dayjs().format("ddd, D MMMM, YYYY") }}
		</div>
	</div>

	<ion-modal
		v-if="settings.data?.allow_employee_checkin_from_mobile_app"
		ref="modal"
		trigger="open-checkin-modal"
		:initial-breakpoint="1"
		:breakpoints="[0, 1]"
	>
		<div class="h-120 w-full flex flex-col items-center justify-center gap-5 p-4 mb-5">
			<div class="flex flex-col gap-1.5 mt-2 items-center justify-center">
				<div class="font-bold text-xl">
					{{ dayjs(checkinTimestamp).format("hh:mm:ss a") }}
				</div>
				<div class="font-medium text-gray-500 text-sm">
					{{ dayjs().format("D MMM, YYYY") }}
				</div>
			</div>

			<template v-if="settings.data?.allow_geolocation_tracking">
				<span v-if="locationStatus" class="font-medium text-gray-500 text-sm">
					{{ locationStatus }}
				</span>

				<div class="rounded border-4 translate-z-0 block overflow-hidden w-full h-170">
					<iframe
						width="100%"
						height="170"
						frameborder="0"
						scrolling="no"
						marginheight="0"
						marginwidth="0"
						style="border: 0"
						:src="`https://maps.google.com/maps?q=${latitude},${longitude}&hl=en&z=15&amp;output=embed`"
					>
					</iframe>
				</div>
			</template>

			<!-- Selfie capture (required for check-in) -->
			<input
				ref="selfieInput"
				type="file"
				accept="image/*"
				capture="user"
				class="hidden"
				@change="onSelfieSelected"
			/>
			<div class="w-full flex flex-col items-center gap-2">
				<img
					v-if="selfie"
					:src="selfie"
					class="w-24 h-24 rounded-full object-cover border"
				/>
				<Button variant="subtle" class="w-full py-5 text-sm" @click="captureSelfie">
					<template #prefix>
						<FeatherIcon name="camera" class="w-4" />
					</template>
					{{ selfie ? __("Retake Selfie") : __("Take Selfie") }}
				</Button>
			</div>

			<Button
				:loading="submitting"
				:disabled="!selfie"
				variant="solid"
				class="w-full py-5 text-sm disabled:bg-gray-400"
				@click="submitLog(nextAction.action)"
			>
				{{ __("Confirm {0}", [nextAction.label]) }}
			</Button>
		</div>
	</ion-modal>
</template>

<script setup>
import { createListResource, call, toast, FeatherIcon } from "frappe-ui"
import { computed, inject, ref, onMounted, onBeforeUnmount } from "vue"
import { IonModal, modalController } from "@ionic/vue"

import { formatTimestamp } from "@/utils/formatters"
import { settings } from "@/data/settings"

const DOCTYPE = "Employee Checkin"

const socket = inject("$socket")
const employee = inject("$employee")
const dayjs = inject("$dayjs")
const __ = inject("$translate")
const checkinTimestamp = ref(null)
const latitude = ref(0)
const longitude = ref(0)
const locationStatus = ref("")
const selfie = ref(null)
const selfieInput = ref(null)
const submitting = ref(false)

const checkins = createListResource({
	doctype: DOCTYPE,
	fields: ["name", "employee", "employee_name", "log_type", "time", "device_id"],
	filters: {
		employee: employee.data.name,
	},
	orderBy: "time desc",
})
checkins.reload()

const lastLog = computed(() => {
	if (checkins.list.loading || !checkins.data) return {}
	return checkins.data[0]
})

const lastLogType = computed(() => {
	return lastLog?.value?.log_type === "IN" ? "check-in" : "check-out"
})

const nextAction = computed(() => {
	return lastLog?.value?.log_type === "IN"
		? { action: "OUT", label: __("Check Out") }
		: { action: "IN", label: __("Check In") }
})

function handleLocationSuccess(position) {
	latitude.value = position.coords.latitude
	longitude.value = position.coords.longitude

	locationStatus.value = [
		__("Latitude: {0}°", [Number(latitude.value).toFixed(5)]),
		__("Longitude: {0}°", [Number(longitude.value).toFixed(5)]),
	].join(", ")
}

function handleLocationError(error) {
	locationStatus.value = "Unable to retrieve your location"
	if (error) locationStatus.value += `: ERROR(${error.code}): ${error.message}`
}

const fetchLocation = () => {
	if (!navigator.geolocation) {
		locationStatus.value = __("Geolocation is not supported by your current browser")
	} else {
		locationStatus.value = __("Locating...")
		navigator.geolocation.getCurrentPosition(handleLocationSuccess, handleLocationError)
	}
}

const handleEmployeeCheckin = () => {
	checkinTimestamp.value = dayjs().format("YYYY-MM-DD HH:mm:ss")
	selfie.value = null

	if (settings.data?.allow_geolocation_tracking) {
		fetchLocation()
	}
}

const captureSelfie = () => {
	selfieInput.value?.click()
}

const onSelfieSelected = (event) => {
	const file = event.target.files?.[0]
	if (!file) return
	const reader = new FileReader()
	reader.onload = () => {
		selfie.value = reader.result
	}
	reader.readAsDataURL(file)
}

const submitLog = async (logType) => {
	const actionLabel = logType === "IN" ? __("Check-in") : __("Check-out")

	if (!selfie.value) {
		toast({
			title: __("Selfie required"),
			text: __("Please take a selfie to check in."),
			icon: "alert-circle",
			position: "bottom-center",
			iconClasses: "text-red-500",
		})
		return
	}

	if (settings.data?.allow_geolocation_tracking && !latitude.value && !longitude.value) {
		toast({
			title: __("Location needed"),
			text: __("Still getting your location. Please wait a moment and try again."),
			icon: "alert-circle",
			position: "bottom-center",
			iconClasses: "text-red-500",
		})
		return
	}

	submitting.value = true
	try {
		await call("selfie_checkin.api.create_checkin", {
			log_type: logType,
			latitude: latitude.value,
			longitude: longitude.value,
			selfie: selfie.value,
		})
		modalController.dismiss()
		selfie.value = null
		checkins.reload()
		toast({
			title: __("Success"),
			text: __("{0} successful!", [actionLabel]),
			icon: "check-circle",
			position: "bottom-center",
			iconClasses: "text-green-500",
		})
	} catch (error) {
		const messages = error?.messages?.length
			? error.messages
			: [error?.message || __("{0} failed!", [actionLabel])]
		for (const message of messages) {
			toast({
				title: __("Error"),
				text: message,
				icon: "alert-circle",
				position: "bottom-center",
				iconClasses: "text-red-500",
			})
		}
	} finally {
		submitting.value = false
	}
}

onMounted(() => {
	socket.emit("doctype_subscribe", DOCTYPE)
	socket.on("list_update", (data) => {
		if (data.doctype == DOCTYPE) {
			checkins.reload()
		}
	})
})

onBeforeUnmount(() => {
	socket.emit("doctype_unsubscribe", DOCTYPE)
	socket.off("list_update")
})
</script>