package com.pert.copyprompt.viewmodel

import android.content.ClipboardManager
import android.content.Context
import android.media.SoundPool
import com.pert.copyprompt.R
import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.mockito.kotlin.any
import org.mockito.kotlin.eq
import org.mockito.kotlin.mock
import org.mockito.kotlin.whenever

@OptIn(ExperimentalCoroutinesApi::class)
class CopyPromptViewModelTest {

    @get:Rule
    val instantTaskExecutorRule = InstantTaskExecutorRule()

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var context: Context
    private lateinit var clipboardManager: ClipboardManager

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        clipboardManager = mock()
        context = mock {
            on { getSystemService(eq(Context.CLIPBOARD_SERVICE)) }.thenReturn(clipboardManager)
            on { applicationContext }.thenReturn(it)
            on { resources }.thenReturn(mock())
        }
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    private fun createViewModel(): CopyPromptViewModel {
        // We use a mock context so SoundPool.load will fail gracefully
        return CopyPromptViewModel(context)
    }

    @Test
    fun `initial state has empty prompt and default values`() {
        val vm = createViewModel()
        assertEquals("", vm.conditionedPrompt)
        assertFalse(vm.isConditioned)
        assertFalse(vm.showToast)
        assertEquals("Copied to clipboard", vm.toastMessage)
        assertFalse(vm.isCopyButtonPressed)
    }

    @Test
    fun `setConditionedPrompt updates prompt and sets isConditioned`() {
        val vm = createViewModel()
        vm.setConditionedPrompt("Test prompt")
        assertEquals("Test prompt", vm.conditionedPrompt)
        assertTrue(vm.isConditioned)
    }

    @Test
    fun `setConditionedPrompt with empty string still sets isConditioned`() {
        val vm = createViewModel()
        vm.setConditionedPrompt("")
        assertEquals("", vm.conditionedPrompt)
        assertTrue(vm.isConditioned)
    }

    @Test
    fun `copyToClipboard with empty prompt does nothing`() {
        val vm = createViewModel()
        vm.copyToClipboard()
        assertFalse(vm.showToast)
    }

    @Test
    fun `copyToClipboard with content shows toast`() {
        val vm = createViewModel()
        vm.setConditionedPrompt("Copy me")
        vm.copyToClipboard()
        assertTrue(vm.showToast)
        assertEquals("Copied to clipboard", vm.toastMessage)
    }

    @Test
    fun `onConditioningComplete sets prompt and shows auto-copy toast`() {
        val vm = createViewModel()
        vm.onConditioningComplete("Conditioned result")
        assertEquals("Conditioned result", vm.conditionedPrompt)
        assertTrue(vm.isConditioned)
        assertTrue(vm.showToast)
        assertEquals("Prompt automatically copied to clipboard", vm.toastMessage)
    }

    @Test
    fun `animateCopyButton sets pressed state`() {
        val vm = createViewModel()
        vm.animateCopyButton()
        assertTrue(vm.isCopyButtonPressed)
    }

    @Test
    fun `animateCopyButton resets after delay`() = runTest {
        val vm = createViewModel()
        vm.animateCopyButton()
        assertTrue(vm.isCopyButtonPressed)
        advanceUntilIdle()
        assertFalse(vm.isCopyButtonPressed)
    }

    @Test
    fun `toast hides after delay`() = runTest {
        val vm = createViewModel()
        vm.setConditionedPrompt("Some text")
        vm.copyToClipboard()
        assertTrue(vm.showToast)
        advanceUntilIdle()
        assertFalse(vm.showToast)
    }

    @Test
    fun `setConditionedPrompt multiple times overwrites previous value`() {
        val vm = createViewModel()
        vm.setConditionedPrompt("First")
        assertEquals("First", vm.conditionedPrompt)
        vm.setConditionedPrompt("Second")
        assertEquals("Second", vm.conditionedPrompt)
    }

    @Test
    fun `large prompt is accepted`() {
        val vm = createViewModel()
        val largePrompt = "A".repeat(100_000)
        vm.setConditionedPrompt(largePrompt)
        assertEquals(largePrompt, vm.conditionedPrompt)
    }

    @Test
    fun `copy sound asset file exists in raw resources`() {
        val resId = R.raw.copy
        assertTrue("R.raw.copy resource ID should be non-zero", resId != 0)
    }
}
