package com.linkapp

import android.app.Application
import androidx.appcompat.app.AppCompatDelegate

class LinkAppApplication : Application() {

    companion object {
        lateinit var instance: LinkAppApplication
            private set
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        
        // Set night mode to follow system
        AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM)
        
        // Initialize app components
        initializeApp()
    }

    private fun initializeApp() {
        // Initialize database, preferences, etc.
        // Initialize message repository (Room)
        com.example.linkapp.MessageRepository.init(this)
    }
}
