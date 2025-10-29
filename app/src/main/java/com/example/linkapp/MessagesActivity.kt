package com.example.linkapp

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.linkapp.databinding.ActivityMessagesBinding
import com.example.linkapp.ui.ConversationAdapter
import kotlinx.coroutines.launch

class MessagesActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMessagesBinding
    private lateinit var adapter: ConversationAdapter

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMessagesBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Ensure repository initialized (in case Application didn't)
        MessageRepository.init(applicationContext)

        adapter = ConversationAdapter { chatId ->
            val i = Intent(this, ChatActivity::class.java)
            i.putExtra("chatId", chatId)
            startActivity(i)
        }

        binding.rvConversations.layoutManager = LinearLayoutManager(this)
        binding.rvConversations.adapter = adapter

        // Collect conversations flow
        lifecycleScope.launch {
            MessageRepository.getConversationsFlow().collect { list ->
                adapter.submitList(list)
            }
        }

        binding.btnNewChat.setOnClickListener {
            val id = "chat_${System.currentTimeMillis()}"
            lifecycleScope.launch {
                MessageRepository.addMessageSuspend(id, Message("me", "Hi", System.currentTimeMillis()))
                val i = Intent(this@MessagesActivity, ChatActivity::class.java)
                i.putExtra("chatId", id)
                startActivity(i)
            }
        }
    }
}
