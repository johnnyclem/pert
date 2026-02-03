package com.pert.copyprompt.viewmodel

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.media.SoundPool
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.pert.copyprompt.R
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class CopyPromptViewModel(private val context: Context) : ViewModel() {

    var conditionedPrompt by mutableStateOf("")
        private set

    var isConditioned by mutableStateOf(false)
        private set

    var showToast by mutableStateOf(false)
        private set

    var toastMessage by mutableStateOf("Copied to clipboard")
        private set

    var isCopyButtonPressed by mutableStateOf(false)
        private set

    private var soundPool: SoundPool? = null
    private var soundId: Int = 0
    private var soundLoaded: Boolean = false

    init {
        loadSound()
    }

    private fun loadSound() {
        try {
            soundPool = SoundPool.Builder()
                .setMaxStreams(1)
                .build()
                .also { pool ->
                    pool.setOnLoadCompleteListener { _, _, status ->
                        soundLoaded = status == 0
                    }
                    soundId = pool.load(context, R.raw.copy, 1)
                }
        } catch (_: Exception) {
            // Sound loading failed; copy will still work without sound
        }
    }

    fun setConditionedPrompt(prompt: String) {
        conditionedPrompt = prompt
        isConditioned = true
    }

    fun copyToClipboard() {
        if (conditionedPrompt.isEmpty()) return

        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = ClipData.newPlainText("conditioned_prompt", conditionedPrompt)
        clipboard.setPrimaryClip(clip)
        playSound()

        toastMessage = "Copied to clipboard"
        showToast = true

        viewModelScope.launch {
            delay(1500)
            showToast = false
        }
    }

    fun onConditioningComplete(prompt: String) {
        setConditionedPrompt(prompt)
        autoCopy()
    }

    private fun autoCopy() {
        if (conditionedPrompt.isEmpty()) return

        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = ClipData.newPlainText("conditioned_prompt", conditionedPrompt)
        clipboard.setPrimaryClip(clip)
        playSound()

        toastMessage = "Prompt automatically copied to clipboard"
        showToast = true

        viewModelScope.launch {
            delay(1500)
            showToast = false
        }
    }

    fun animateCopyButton() {
        isCopyButtonPressed = true

        viewModelScope.launch {
            delay(150)
            isCopyButtonPressed = false
        }
    }

    private fun playSound() {
        if (soundLoaded) {
            soundPool?.play(soundId, 1f, 1f, 1, 0, 1f)
        }
    }

    override fun onCleared() {
        super.onCleared()
        soundPool?.release()
    }

    class Factory(private val context: Context) : ViewModelProvider.Factory {
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            if (modelClass.isAssignableFrom(CopyPromptViewModel::class.java)) {
                @Suppress("UNCHECKED_CAST")
                return CopyPromptViewModel(context.applicationContext) as T
            }
            throw IllegalArgumentException("Unknown ViewModel class")
        }
    }
}
