package com.linkapp.ui.activities

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.linkapp.databinding.ActivityLoginBinding

/**
 * Simple LoginActivity implementation using ViewBinding.
 * - Validates non-empty email/password
 * - On success navigates to MainActivity
 */
class LoginActivity : AppCompatActivity() {

    private lateinit var binding: ActivityLoginBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityLoginBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.btnLogin.setOnClickListener {
            val email = binding.etEmail.text.toString().trim()
            val password = binding.etPassword.text.toString()

            if (email.isEmpty() || password.isEmpty()) {
                Toast.makeText(this, "الرجاء إدخال البريد وكلمة المرور", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            // TODO: Replace with real authentication
            // For now, accept any non-empty credentials
            val intent = Intent(this, MainActivity::class.java)
            startActivity(intent)
            finish()
        }
    }
}
