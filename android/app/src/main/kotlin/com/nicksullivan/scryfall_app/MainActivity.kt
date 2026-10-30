package com.nicksullivan.scryfall_app

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.provider.DocumentsContract.Document
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.FileNotFoundException
import java.util.concurrent.Executors

/// Hosts the "art_folder" channel: "Download all art" writes into a folder
/// the user picked through the Storage Access Framework, so it needs no
/// storage permission and can overwrite files it wrote before.
class MainActivity : FlutterActivity() {
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var pendingPick: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "scryfall_app/art_folder")
            .setMethodCallHandler(::onCall)
    }

    private fun onCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickFolder" -> pickFolder(result)
            "hasAccess" -> result.success(hasAccess(tree(call)))
            "listFiles" -> background(result) { listFiles(tree(call)) }
            "writeFile" -> background(result) {
                writeFile(
                    tree(call),
                    call.argument<String>("name")!!,
                    call.argument<String>("existing"),
                    call.argument<ByteArray>("bytes")!!,
                )
            }
            "openFolder" -> result.success(openFolder(tree(call)))
            else -> result.notImplemented()
        }
    }

    private fun tree(call: MethodCall) = Uri.parse(call.argument<String>("uri")!!)

    private fun rootDoc(tree: Uri) =
        DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))

    private fun pickFolder(result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("BUSY", "Folder picker already open", null)
            return
        }
        pendingPick = result
        @Suppress("DEPRECATION")
        startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT_TREE), PICK_FOLDER)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_FOLDER) return
        val result = pendingPick ?: return
        pendingPick = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        // Persisted so the grant survives restarts; the app never asks again
        // unless the user revokes it or deletes the folder.
        contentResolver.takePersistableUriPermission(
            uri, Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        )
        result.success(mapOf("uri" to uri.toString(), "name" to displayName(uri)))
    }

    private fun displayName(tree: Uri): String =
        contentResolver.query(rootDoc(tree), arrayOf(Document.COLUMN_DISPLAY_NAME), null, null, null)
            ?.use { if (it.moveToFirst()) it.getString(0) else null }
            ?: tree.lastPathSegment
            ?: "folder"

    private fun hasAccess(tree: Uri) =
        contentResolver.persistedUriPermissions.any { it.uri == tree && it.isWritePermission }

    /// File name → document uri for the folder's direct children, listed once
    /// per export so overwrite checks don't query per file.
    private fun listFiles(tree: Uri): Map<String, String> {
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(
            tree, DocumentsContract.getTreeDocumentId(tree)
        )
        val cursor = contentResolver.query(
            children, arrayOf(Document.COLUMN_DOCUMENT_ID, Document.COLUMN_DISPLAY_NAME), null, null, null
        ) ?: throw FileNotFoundException("Cannot list $tree")
        val out = mutableMapOf<String, String>()
        cursor.use {
            while (it.moveToNext()) {
                out[it.getString(1)] = DocumentsContract.buildDocumentUriUsingTree(tree, it.getString(0)).toString()
            }
        }
        return out
    }

    /// Truncating "wt" mode overwrites an existing document in place; returns
    /// the document uri so the caller can overwrite it again next time.
    private fun writeFile(tree: Uri, name: String, existing: String?, bytes: ByteArray): String {
        val target = existing?.let(Uri::parse)
            ?: DocumentsContract.createDocument(contentResolver, rootDoc(tree), "image/png", name)
            ?: throw FileNotFoundException("Cannot create $name")
        (contentResolver.openOutputStream(target, "wt") ?: throw FileNotFoundException(name))
            .use { it.write(bytes) }
        return target.toString()
    }

    private fun openFolder(tree: Uri): Boolean = try {
        startActivity(
            Intent(Intent.ACTION_VIEW)
                .setDataAndType(rootDoc(tree), Document.MIME_TYPE_DIR)
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        )
        true
    } catch (e: ActivityNotFoundException) {
        false
    }

    /// Runs I/O off the main thread; a revoked grant or deleted folder comes
    /// back as NO_ACCESS so Dart can ask for a new folder.
    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        io.execute {
            val outcome = runCatching(work)
            main.post {
                outcome.fold(
                    { result.success(it) },
                    { e ->
                        val lost = e is SecurityException || e is FileNotFoundException ||
                            e is IllegalArgumentException
                        result.error(if (lost) "NO_ACCESS" else "IO", e.message, null)
                    },
                )
            }
        }
    }

    private companion object {
        const val PICK_FOLDER = 7301
    }
}
