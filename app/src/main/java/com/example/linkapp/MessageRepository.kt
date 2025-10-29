package com.example.linkapp

import android.content.Context
import kotlinx.coroutines.runBlocking

object MessageRepository {
    private var initialized = false
    private lateinit var db: com.example.linkapp.data.AppDatabase

    fun init(context: Context) {
        if (!initialized) {
            db = com.example.linkapp.data.AppDatabase.getInstance(context)
            initialized = true
        }
    }

    fun getMessages(chatId: String): List<Message> = runBlocking {
        if (!initialized) return@runBlocking emptyList<Message>()
        db.messageDao().getMessagesForChat(chatId).map { Message(it.sender, it.text, it.timestamp) }
    }

    fun addMessage(chatId: String, message: Message) {
        if (!initialized) return
        runBlocking {
            db.messageDao().insert(
                com.example.linkapp.data.MessageEntity(
                    chatId = chatId,
                    sender = message.sender,
                    text = message.text,
                    timestamp = message.timestamp
                )
            )
        }
    }

    fun getConversations(): List<String> = runBlocking {
        if (!initialized) return@runBlocking emptyList()
        val ids = db.messageDao().getChatIds()
        if (ids.isEmpty()) listOf("Alice", "Bob") else ids
    }
}
