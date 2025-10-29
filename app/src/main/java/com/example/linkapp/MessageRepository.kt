package com.example.linkapp

import android.content.Context
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

object MessageRepository {
    private var initialized = false
    private lateinit var db: com.example.linkapp.data.AppDatabase

    fun init(context: Context) {
        if (!initialized) {
            db = com.example.linkapp.data.AppDatabase.getInstance(context)
            initialized = true
        }
    }

    /** Returns a Flow of messages for the given chatId (ordered by timestamp). */
    fun getMessagesFlow(chatId: String): Flow<List<Message>> {
        if (!initialized) return kotlinx.coroutines.flow.flowOf(emptyList())
        return db.messageDao().getMessagesForChat(chatId).map { list ->
            list.map { Message(it.sender, it.text, it.timestamp) }
        }
    }

    /** Insert a message (suspend). */
    suspend fun addMessageSuspend(chatId: String, message: Message) {
        if (!initialized) return
        db.messageDao().insert(
            com.example.linkapp.data.MessageEntity(
                chatId = chatId,
                sender = message.sender,
                text = message.text,
                timestamp = message.timestamp
            )
        )
    }

    /** Returns a Flow of conversation ids. */
    fun getConversationsFlow(): Flow<List<String>> {
        if (!initialized) return kotlinx.coroutines.flow.flowOf(listOf("Alice", "Bob"))
        return db.messageDao().getChatIds()
    }
}
