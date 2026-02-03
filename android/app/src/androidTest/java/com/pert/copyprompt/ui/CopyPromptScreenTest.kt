package com.pert.copyprompt.ui

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.pert.copyprompt.viewmodel.CopyPromptViewModel
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class CopyPromptScreenTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    private fun createViewModel(): CopyPromptViewModel {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        return CopyPromptViewModel(context)
    }

    @Test
    fun copyButton_isDisabled_whenPromptIsEmpty() {
        val vm = createViewModel()
        composeTestRule.setContent {
            CopyPromptScreen(viewModel = vm)
        }
        composeTestRule.onNodeWithContentDescription("Copy to clipboard")
            .assertIsDisplayed()
            .assertIsNotEnabled()
    }

    @Test
    fun copyButton_isEnabled_whenPromptIsSet() {
        val vm = createViewModel()
        vm.setConditionedPrompt("Test prompt content")
        composeTestRule.setContent {
            CopyPromptScreen(viewModel = vm)
        }
        composeTestRule.onNodeWithContentDescription("Copy to clipboard")
            .assertIsDisplayed()
            .assertIsEnabled()
    }

    @Test
    fun promptText_isDisplayed_whenSet() {
        val vm = createViewModel()
        vm.setConditionedPrompt("Visible prompt text")
        composeTestRule.setContent {
            CopyPromptScreen(viewModel = vm)
        }
        composeTestRule.onNodeWithText("Visible prompt text")
            .assertIsDisplayed()
    }

    @Test
    fun toast_isDisplayed_afterCopy() {
        val vm = createViewModel()
        vm.setConditionedPrompt("Copy me")
        composeTestRule.setContent {
            CopyPromptScreen(viewModel = vm)
        }
        composeTestRule.onNodeWithContentDescription("Copy to clipboard")
            .performClick()
        composeTestRule.onNodeWithText("Copied to clipboard")
            .assertIsDisplayed()
    }
}
