# Copyright (c) 2023, Frappe Technologies Pvt. Ltd. and contributors
# For license information, please see license.txt

import frappe
from frappe import _
from frappe.model.document import Document
from twilio.rest import Client
from twilio.base.exceptions import TwilioRestException


class CRMTwilioSettings(Document):
    # System creates TwiML app & API keys with this name.
    friendly_resource_name = "Frappe CRM"

    def validate(self):
        self.validate_twilio_account()

    def on_update(self):
        # Single doctype records are created in DB at time of installation and those field values are set as null.
        # This condition make sure that we handle null.
        if not self.account_sid:
            return

        twilio = Client(self.account_sid, self.get_password("auth_token"))
        self.set_api_credentials(twilio)
        self.set_application_credentials(twilio)

        if self.enable_byoc:
            self.validate_byoc_trunk()

        self.reload()

    def validate_twilio_account(self):
        try:
            twilio = Client(self.account_sid, self.get_password("auth_token"))
            twilio.api.accounts(self.account_sid).fetch()
            return twilio
        except Exception:
            frappe.throw(_("Invalid Account SID or Auth Token."))

    def validate_byoc_trunk(self):
        """Validate BYOC trunk SID format and accessibility (correct API + clean logging)"""
        if not self.enable_byoc:
            return  # BYOC is disabled, skip check

        sid = self.byoc_trunk_sid
        if not sid or not sid.startswith("BY"):
            frappe.throw(
                _("Please provide a valid BYOC Trunk SID (starts with 'BY')"))

        auth_token = self.get_password("auth_token")
        if not auth_token:
            frappe.throw(_("Auth Token is missing or not saved yet"))

        try:
            client = Client(self.account_sid, auth_token)
            trunk = client.voice.v1.byoc_trunks(sid).fetch()

            # Optional success log (can be removed in production)
            frappe.logger().info(
                f"[Twilio BYOC] Trunk '{trunk.friendly_name}' validated successfully (SID: {trunk.sid})")

        except TwilioRestException as e:
            short_title = f"[Twilio BYOC] Error accessing BYOC SID {sid[:10]}...: {e.status}"
            long_body = f"Twilio API Error: {e.msg}\nStatus: {e.status}\nCode: {e.code}\nMore Info: {e.more_info}"

            frappe.log_error(title=short_title, message=long_body)
            frappe.throw(
                _("Invalid or inaccessible BYOC Trunk SID. Please verify it in your Twilio account."))

    def set_api_credentials(self, twilio):
        """Generate Twilio API credentials if not exist and update them."""
        if self.api_key and self.api_secret:
            return
        new_key = self.create_api_key(twilio)
        self.api_key = new_key.sid
        self.api_secret = new_key.secret
        frappe.db.set_value(
            "CRM Twilio Settings",
            "CRM Twilio Settings",
            {"api_key": self.api_key, "api_secret": self.api_secret},
        )

    def set_application_credentials(self, twilio):
        """Generate TwiML app credentials if not exist and update them."""
        credentials = self.get_application(
            twilio) or self.create_application(twilio)
        self.twiml_sid = credentials.sid
        frappe.db.set_value("CRM Twilio Settings",
                            "CRM Twilio Settings", "twiml_sid", self.twiml_sid)

    def create_api_key(self, twilio):
        """Create API keys in twilio account."""
        try:
            return twilio.new_keys.create(friendly_name=self.friendly_resource_name)
        except Exception:
            frappe.log_error(title=_("Twilio API credential creation error."))
            frappe.throw(_("Twilio API credential creation error."))

    def get_twilio_voice_url(self):
        url_path = "/api/method/crm.integrations.twilio.api.voice"
        return get_public_url(url_path)

    def get_application(self, twilio, friendly_name=None):
        """Get TwiML App from twilio account if exists."""
        friendly_name = friendly_name or self.friendly_resource_name
        applications = twilio.applications.list(friendly_name)
        return applications and applications[0]

    def create_application(self, twilio, friendly_name=None):
        """Create TwilML App in twilio account."""
        friendly_name = friendly_name or self.friendly_resource_name
        application = twilio.applications.create(
            voice_method="POST", voice_url=self.get_twilio_voice_url(), friendly_name=friendly_name
        )
        return application


def get_public_url(path: str | None = None):
    from frappe.utils import get_url

    return get_url().split(":8", 1)[0] + path
