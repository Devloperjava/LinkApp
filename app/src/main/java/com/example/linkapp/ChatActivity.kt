package com.example.linkapp

import android.os.Bundle
import android.widget.ArrayAdapter
import androidx.appcompat.app.AppCompatActivity
import com.example.linkapp.databinding.ActivityChatBinding

class ChatActivity : AppCompatActivity() {
    private lateinit var binding: ActivityChatBinding
    private var chatId: String = "" 

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityChatBinding.inflate(layoutInflater)
        setContentView(binding.root)

        chatId = intent.getStringExtra("chatId") ?: "default"
        binding.tvChatTitle.text = chatId

        refreshMessages()

        binding.btnSend.setOnClickListener {
            val text = binding.etMessage.text.toString().trim()
            if (text.isNotEmpty()) {
                val msg = Message("me", text)
                MessageRepository.addMessage(chatId, msg)
                binding.etMessage.setText("")
                refreshMessages()
            }
        }
    }

    private fun refreshMessages() {
        val messages = MessageRepository.getMessages(chatId)
        val items = messages.map { "${it.sender}: ${it.text}" }
        val adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, items)
        binding.lvMessages.adapter = adapter
    }
}
