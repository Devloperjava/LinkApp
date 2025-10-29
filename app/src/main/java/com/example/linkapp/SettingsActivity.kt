package com.example.linkapp

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import androidx.appcompat.app.AppCompatActivity
import com.linkapp.util.LocaleHelper
import java.util.Locale

class SettingsActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Apply saved locale
        LocaleHelper.applyLocale(this)
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_settings)

        val btnEn = findViewById<Button>(R.id.btn_lang_en)
        val btnAr = findViewById<Button>(R.id.btn_lang_ar)

        btnEn.setOnClickListener {
            LocaleHelper.saveLocale(this, Locale.forLanguageTag("en"))
            recreateApp()
        }

        btnAr.setOnClickListener {
            LocaleHelper.saveLocale(this, Locale.forLanguageTag("ar"))
            recreateApp()
        }
    }

    private fun recreateApp() {
        // Restart MainActivity to apply language change
        val i = Intent(this, MainActivity::class.java)
        i.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(i)
        finish()
    }
}
