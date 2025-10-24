package com.example.linkapp

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.button.MaterialButton
import com.google.android.material.textfield.TextInputEditText
import android.widget.Toast

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val btnLogin = findViewById<MaterialButton>(R.id.btnLogin)
        val btnChat = findViewById<MaterialButton>(R.id.btnChat)
        val etUsername = findViewById<TextInputEditText>(R.id.etUsername)
        val etPassword = findViewById<TextInputEditText>(R.id.etPassword)

        btnLogin.setOnClickListener {
            val user = etUsername?.text?.toString().orEmpty()
            val pass = etPassword?.text?.toString().orEmpty()
            Toast.makeText(this, "تسجيل الدخول: $user", Toast.LENGTH_SHORT).show()
            // هنا تضيف لوجيك المصادقة (Firebase/Auth API)
        }

        btnChat.setOnClickListener {
            Toast.makeText(this, "بدء محادثة جديدة...", Toast.LENGTH_SHORT).show()
            // فتح Activity شاشة المحادثة لاحقًا
        }
    }
}
