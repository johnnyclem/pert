package com.pert.copyprompt

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.lifecycle.viewmodel.compose.viewModel
import com.pert.copyprompt.ui.CopyPromptScreen
import com.pert.copyprompt.viewmodel.CopyPromptViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            val vm: CopyPromptViewModel = viewModel(
                factory = CopyPromptViewModel.Factory(applicationContext)
            )
            CopyPromptScreen(viewModel = vm)
        }
    }
}
