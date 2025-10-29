package com.example.linkapp

import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import com.example.linkapp.databinding.ActivityMainBinding
import android.content.Intent
import com.linkapp.util.SessionManager

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        binding.textView.text = "👋 Welcome to LinkApp!"

        binding.btnMessages.setOnClickListener {
            startActivity(Intent(this, com.example.linkapp.MessagesActivity::class.java))
        }

        binding.btnProfile.setOnClickListener {
            startActivity(Intent(this, com.example.linkapp.RegisterActivity::class.java))
        }

        binding.btnLogout.setOnClickListener {
            val session = SessionManager(this)
            session.logout()
            startActivity(Intent(this, com.linkapp.ui.activities.LoginActivity::class.java))
            finish()
        }
    }
}
