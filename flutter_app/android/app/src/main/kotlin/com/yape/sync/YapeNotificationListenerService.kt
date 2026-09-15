package com.yape.sync

import android.app.Notification
import android.content.Intent
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class YapeNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "YapeNotificationService"
        
        // Paquetes soportados
        const val PKG_YAPE = "com.bcp.innovacxion.yapeapp"
        const val PKG_INTERBANK = "pe.interbank.mobilebanking"
        const val PKG_BBVA = "com.bbva.pe"
        const val PKG_SCOTIABANK = "com.scotiabank.peru"

        var instance: YapeNotificationListenerService? = null
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.d(TAG, "YapeNotificationListenerService iniciado y activo")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "YapeNotificationListenerService detenido")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val packageName = sbn.packageName ?: return
        
        // Filtrar exclusivamente notificaciones de Yape o bancos (Plin)
        val isYape = packageName.equals(PKG_YAPE, ignoreCase = true)
        val isPlin = packageName.contains("interbank", ignoreCase = true) || 
                     packageName.contains("bbva", ignoreCase = true) || 
                     packageName.contains("scotiabank", ignoreCase = true)

        if (!isYape && !isPlin) {
            return
        }

        val extras: Bundle? = sbn.notification?.extras
        val title = extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""

        Log.d(TAG, "Notificación detectada de [$packageName]: Title='$title', Text='$text'")

        // Si la notificación contiene palabras clave de pago
        val combined = "$title $text".lowercase()
        val isPaymentNotice = combined.contains("yape") || 
                              combined.contains("yapearon") || 
                              combined.contains("plin") || 
                              combined.contains("s/")

        if (isPaymentNotice) {
            // Notificar a Flutter a través del MainActivity
            MainActivity.sendNotificationToFlutter(
                mapOf(
                    "package" to packageName,
                    "title" to title,
                    "text" to text,
                    "timestamp" to System.currentTimeMillis()
                )
            )
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
    }
}
