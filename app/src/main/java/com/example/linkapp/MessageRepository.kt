package com.example.linkapp

object MessageRepository {
    // map of chatId -> messages
    private val chats: MutableMap<String, MutableList<Message>> = mutableMapOf()

    fun getMessages(chatId: String): List<Message> {
        return chats.getOrPut(chatId) { mutableListOf() }
    }

    fun addMessage(chatId: String, message: Message) {
        chats.getOrPut(chatId) { mutableListOf() }.add(message)
    }

    fun getConversations(): List<String> {
        // return chat ids
        return chats.keys.toList().ifEmpty { listOf("Alice", "Bob") }
    }
}
