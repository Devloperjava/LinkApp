package com.linkapp.util

import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import java.util.Locale
import android.content.res.Configuration

object LocaleHelper {
    private const val PREFS_NAME = "linkapp_prefs"
    private const val KEY_LOCALE = "app_locale"

    fun getSavedLocale(context: Context): Locale? {
        val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val tag = prefs.getString(KEY_LOCALE, null) ?: return null
        return Locale.forLanguageTag(tag)
    }

    fun saveLocale(context: Context, locale: Locale) {
        val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_LOCALE, locale.toLanguageTag()).apply()
        updateResources(context, locale)
    }

    fun applyLocale(context: Context): Context {
        val locale = getSavedLocale(context) ?: return context
        return updateResources(context, locale)
    }

    private fun updateResources(context: Context, locale: Locale): Context {
        Locale.setDefault(locale)
        val res = context.resources
        val config = Configuration(res.configuration)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            config.setLocale(locale)
            config.setLayoutDirection(locale)
            return context.createConfigurationContext(config)
        } else {
            config.locale = locale
            config.setLayoutDirection(locale)
            res.updateConfiguration(config, res.displayMetrics)
            return context
        }
    }
}
