package com.example.linkapp.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query

@Dao
interface MessageDao {
    @Query("SELECT * FROM messages WHERE chatId = :chatId ORDER BY timestamp ASC")
    fun getMessagesForChat(chatId: String): kotlinx.coroutines.flow.Flow<List<MessageEntity>>

    @Insert
    suspend fun insert(message: MessageEntity)

    @Query("SELECT DISTINCT chatId FROM messages")
    fun getChatIds(): kotlinx.coroutines.flow.Flow<List<String>>
}
