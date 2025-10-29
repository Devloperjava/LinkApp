package com.linkapp.ui.activities

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.appcompat.app.AppCompatActivity
import com.linkapp.R

class SplashActivity : AppCompatActivity() {
    
    private val splashTimeOut: Long = 2000 // 2 seconds
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_splash)
        
        initializeApp()
    }
    
    private fun initializeApp() {
        Handler(Looper.getMainLooper()).postDelayed({
            checkAuthentication()
        }, splashTimeOut)
    }
    
    private fun checkAuthentication() {
        val session = com.linkapp.util.SessionManager(this)
        val intent = if (session.isLoggedIn()) {
            Intent(this, MainActivity::class.java)
        } else {
            Intent(this, LoginActivity::class.java)
        }

        startActivity(intent)
        finish()
    }
}
