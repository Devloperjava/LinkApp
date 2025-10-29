package com.example.linkapp

import android.content.Intent
import android.os.Bundle
import android.widget.ArrayAdapter
import androidx.appcompat.app.AppCompatActivity
import com.example.linkapp.databinding.ActivityMessagesBinding

class MessagesActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMessagesBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMessagesBinding.inflate(layoutInflater)
        setContentView(binding.root)

        refreshList()

        binding.lvConversations.setOnItemClickListener { _, _, position, _ ->
            val convo = binding.lvConversations.adapter.getItem(position) as String
            val i = Intent(this, ChatActivity::class.java)
            i.putExtra("chatId", convo)
            startActivity(i)
        }

        binding.btnNewChat.setOnClickListener {
            // create a new chat with timestamp id
            val id = "chat_${System.currentTimeMillis()}"
            MessageRepository.addMessage(id, Message("me","Hi"))
            val i = Intent(this, ChatActivity::class.java)
            i.putExtra("chatId", id)
            startActivity(i)
        }
    }

    private fun refreshList() {
        val convos = MessageRepository.getConversations()
        val adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, convos)
        binding.lvConversations.adapter = adapter
    }
}
