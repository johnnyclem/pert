package com.pert.copyprompt.ui

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.pert.copyprompt.viewmodel.CopyPromptViewModel

private val WarmBackgroundStart = Color(0xFFFAF2E6)
private val WarmBackgroundEnd = Color(0xFFFCEBE1)
private val WarmTextPrimary = Color(0xFF473828)
private val WarmAccentSoft = Color(0xFFEDA680)
private val CardStroke = Color(0x59DBC7B3)

@Composable
fun CopyPromptScreen(viewModel: CopyPromptViewModel) {
    val scale by animateFloatAsState(
        targetValue = if (viewModel.isCopyButtonPressed) 0.9f else 1f,
        animationSpec = tween(durationMillis = 150),
        label = "copy_button_scale"
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.linearGradient(
                    colors = listOf(WarmBackgroundStart, WarmBackgroundEnd)
                )
            )
    ) {
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            item { Spacer(modifier = Modifier.height(48.dp)) }

            if (viewModel.conditionedPrompt.isNotEmpty()) {
                item {
                    Text(
                        text = viewModel.conditionedPrompt,
                        color = WarmTextPrimary,
                        fontSize = 16.sp,
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(
                                Color.White.copy(alpha = 0.8f),
                                shape = RoundedCornerShape(12.dp)
                            )
                            .border(1.dp, CardStroke, RoundedCornerShape(12.dp))
                            .padding(16.dp)
                    )
                }
            }

            item {
                Spacer(modifier = Modifier.height(20.dp))

                IconButton(
                    onClick = {
                        viewModel.copyToClipboard()
                        viewModel.animateCopyButton()
                    },
                    enabled = viewModel.conditionedPrompt.isNotEmpty(),
                    modifier = Modifier
                        .size(56.dp)
                        .scale(scale)
                        .clip(CircleShape)
                        .background(
                            if (viewModel.conditionedPrompt.isNotEmpty())
                                WarmAccentSoft
                            else
                                WarmAccentSoft.copy(alpha = 0.5f)
                        )
                ) {
                    Icon(
                        imageVector = Icons.Filled.ContentCopy,
                        contentDescription = "Copy to clipboard",
                        tint = Color.White,
                        modifier = Modifier.size(24.dp)
                    )
                }
            }

            item { Spacer(modifier = Modifier.height(48.dp)) }
        }

        // Toast overlay at bottom
        ToastOverlay(
            message = viewModel.toastMessage,
            visible = viewModel.showToast,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 40.dp)
        )
    }
}
