package com.josephabel.native_dialog_plus

import android.app.Activity
import android.app.AlertDialog
import android.content.DialogInterface
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.InsetDrawable
import android.util.TypedValue
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.annotation.NonNull
import com.google.android.material.bottomsheet.BottomSheetDialog
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

class NativeDialogPlusPlugin : FlutterPlugin, ActivityAware, NativeDialogHostApi {
    private var activity: Activity? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        NativeDialogHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        NativeDialogHostApi.setUp(binding.binaryMessenger, null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun showDialog(args: ShowDialogArgs, callback: (Result<Long?>) -> Unit) {
        if (args.style == DialogStyle.ACTION_SHEET) {
            showActionSheet(args, callback)
        } else {
            showAlertDialog(args, callback)
        }
    }

    private fun showActionSheet(args: ShowDialogArgs, callback: (Result<Long?>) -> Unit) {
        val act = activity ?: run {
            callback(Result.failure(Exception("No activity available")))
            return
        }

        val bottomSheetDialog = BottomSheetDialog(act, R.style.NativeDialogStyle)
        val view = LayoutInflater.from(act).inflate(R.layout.action_sheet_layout, null)
        view.setBackgroundColor(Color.WHITE)

        val titleView: TextView = view.findViewById(R.id.title)
        val title = args.title ?: ""
        if (title.isNotEmpty()) {
            titleView.text = title
            titleView.visibility = View.VISIBLE
            titleView.setPadding(8, 8, 8, 8)
            titleView.setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            titleView.setTextColor(Color.GRAY)
        }

        val actionContainer: LinearLayout = view.findViewById(R.id.action_container)
        args.actions.forEachIndexed { index, action ->
            val button = Button(act).apply {
                text = action.text
                textAlignment = View.TEXT_ALIGNMENT_VIEW_START
                gravity = android.view.Gravity.START or android.view.Gravity.CENTER_VERTICAL
                setOnClickListener {
                    callback(Result.success(index.toLong()))
                    bottomSheetDialog.dismiss()
                }
                setBackgroundResource(R.drawable.rounded_button)
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
                // Use the custom color if provided, otherwise default to black
                setTextColor(action.color?.toInt() ?: Color.BLACK)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                paint.isFakeBoldText = true
            }
            actionContainer.addView(button)
        }

        bottomSheetDialog.window?.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
        bottomSheetDialog.setContentView(view)
        bottomSheetDialog.show()
    }

    private fun showAlertDialog(args: ShowDialogArgs, callback: (Result<Long?>) -> Unit) {
        val act = activity ?: run {
            callback(Result.failure(Exception("No activity available")))
            return
        }

        val builder = AlertDialog.Builder(act, R.style.NativeDialogStyle)
            .setTitle(args.title ?: "")
            .setMessage(args.message ?: "")
            .setCancelable(args.cancellable)

        args.actions.forEachIndexed { index, action ->
            val listener = DialogInterface.OnClickListener { _, _ ->
                callback(Result.success(index.toLong()))
            }
            when (action.style) {
                ActionStyle.DEFAULT_STYLE -> builder.setPositiveButton(action.text, listener)
                ActionStyle.CANCEL       -> builder.setNeutralButton(action.text, listener)
                ActionStyle.DESTRUCTIVE  -> builder.setNegativeButton(action.text, listener)
            }
        }

        if (args.cancellable) {
            builder.setOnCancelListener { callback(Result.success(null)) }
        }

        val alertDialog = builder.create()
        val inset = InsetDrawable(ColorDrawable(Color.WHITE), 20, 20, 20, 20)
        alertDialog.window?.setBackgroundDrawable(inset)
        alertDialog.show()

        // Apply custom text colors to buttons after show() (buttons only exist post-show)
        args.actions.forEach { action ->
            action.color?.let { colorLong ->
                val color = colorLong.toInt()
                when (action.style) {
                    ActionStyle.DEFAULT_STYLE ->
                        alertDialog.getButton(AlertDialog.BUTTON_POSITIVE)?.setTextColor(color)
                    ActionStyle.CANCEL ->
                        alertDialog.getButton(AlertDialog.BUTTON_NEUTRAL)?.setTextColor(color)
                    ActionStyle.DESTRUCTIVE ->
                        alertDialog.getButton(AlertDialog.BUTTON_NEGATIVE)?.setTextColor(color)
                }
            }
        }
    }
}
