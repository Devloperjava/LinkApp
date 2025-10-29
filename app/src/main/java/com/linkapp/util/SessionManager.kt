package com.linkapp.util

import android.content.Context

class SessionManager(private val context: Context) {
    private val prefs = context.getSharedPreferences("linkapp_prefs", Context.MODE_PRIVATE)

    companion object {
        private const val KEY_IS_LOGGED_IN = "is_logged_in"
        private const val KEY_EMAIL = "user_email"
    }

    fun login(email: String) {
        prefs.edit().putBoolean(KEY_IS_LOGGED_IN, true).putString(KEY_EMAIL, email).apply()
    }

    fun logout() {
        prefs.edit().clear().apply()
    }

    fun isLoggedIn(): Boolean = prefs.getBoolean(KEY_IS_LOGGED_IN, false)

    fun getUserEmail(): String? = prefs.getString(KEY_EMAIL, null)
}
