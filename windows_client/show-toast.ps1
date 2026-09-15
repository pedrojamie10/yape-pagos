param (
    [string]$Title = "¡Yape Recibido! S/ 25.00",
    [string]$Sender = "Cliente",
    [string]$App = "Yape"
)

try {
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

    $time = (Get-Date).ToString("hh:mm tt")
    $toastXml = @"
<toast duration="short">
    <visual>
        <binding template="ToastGeneric">
            <text>$Title</text>
            <text>De: $Sender - $time</text>
            <text>Confirmado vía $App en tiempo real</text>
        </binding>
    </visual>
    <audio src="ms-winsoundevent:Notification.Reminder"/>
</toast>
"@

    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xml.LoadXml($toastXml)
    $toast = New-Object Windows.UI.Notifications.ToastNotification $xml
    
    # Usar un AppID de Windows para que aparezca con icono y sonido
    $appId = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
    Write-Output "Toast displayed: $Title | $Sender"
} catch {
    Write-Error "Error mostrando toast: $_"
}
