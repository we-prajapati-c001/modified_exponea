package com.exponea.style

import android.view.View
import com.exponea.asColor

data class AppInboxListViewStyle(
    var backgroundColor: String? = null,
    var item: AppInboxListItemStyle? = null
) {
    fun applyTo(target: View) {
        backgroundColor?.asColor()?.let {
            target.setBackgroundColor(it)
        }
        // note: 'item' style is used elsewhere due to performance reasons
    }
}
