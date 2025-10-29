package com.example.linkapp

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.linkapp.databinding.ActivityChatBinding
import com.example.linkapp.ui.MessageAdapter
import kotlinx.coroutines.launch

class ChatActivity : AppCompatActivity() {
    private lateinit var binding: ActivityChatBinding
    private var chatId: String = ""
    private lateinit var adapter: MessageAdapter

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityChatBinding.inflate(layoutInflater)
        setContentView(binding.root)

        MessageRepository.init(applicationContext)

        chatId = intent.getStringExtra("chatId") ?: "default"
        binding.tvChatTitle.text = chatId

        adapter = MessageAdapter(emptyList())
        binding.rvMessages.layoutManager = LinearLayoutManager(this)
        binding.rvMessages.adapter = adapter

        // Collect messages for this chat
        lifecycleScope.launch {
            MessageRepository.getMessagesFlow(chatId).collect { list ->
                adapter.submitList(list)
                // scroll to bottom
                binding.rvMessages.scrollToPosition(maxOf(0, list.size - 1))
            }
        }

        binding.btnSend.setOnClickListener {
            val text = binding.etMessage.text.toString().trim()
            if (text.isNotEmpty()) {
                val msg = Message("me", text, System.currentTimeMillis())
                lifecycleScope.launch {
                    MessageRepository.addMessageSuspend(chatId, msg)
                    // clear input after insertion
                    binding.etMessage.setText("")
                }
            }
        }
    }
}
