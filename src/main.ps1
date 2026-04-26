# ==================================================================================
# DECO SENTRY PRO v4.0.0
# Скрипт комплексного мониторинга сетевых узлов DECO
# Разработчик: М. Чувилев (Chuvilev M.)
# Дата: 13.04.2026
# ==================================================================================
# ОСОБЕННОСТИ:
# - Интерфейс на базе WPF (Windows Presentation Foundation)
# - Кастомный неоновый дизайн (Black & Lime Green)
# - Интегрированное логирование в реальном времени (UI Console)
# - Система автоматического контроля аптайма
# - Экспорт данных в формате CSV для АХЧ
# - Совместимость с упаковщиками EXE (запрет тернарных операторов и Read-Only свойств)
# ==================================================================================

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing
$ProgressPreference = 'SilentlyContinue'

# --- Глобальные переменные и статистика ---
$script:Version = "4.0.0"
$script:IsMonitoring = $false
$script:Stats = @{}

# База данных узлов
$script:DecoData = [ordered]@{
    "f0-a7-31-b8-f1-78" = @{ Name = "Каб. 21"; IP = "192.168.31.103" }
    "f0-a7-31-b8-d5-98" = @{ Name = "Каб. D598"; IP = "192.168.31.110" }
    "f0-a7-31-b8-d5-b0" = @{ Name = "медблок"; IP = "192.168.31.134" } 
    "cc-5d-4e-fd-30-55" = @{ Name = "Каб. 138 (?)"; IP = "192.168.31.138" }
    "e8-ff-1e-dc-6d-7c" = @{ Name = "Каб. 42"; IP = "192.168.31.15" }
    "f0-a7-31-b8-f2-f0" = @{ Name = "Каб. 11"; IP = "192.168.31.219" }
    "f0-a7-31-b8-f2-f8" = @{ Name = "Каб. 60"; IP = "192.168.31.139" }
    "f0-a7-31-b8-d5-90" = @{ Name = "Каб. 41"; IP = "192.168.31.56" }
    "cc-5d-4e-ff-26-bf" = @{ Name = "Каб. 91 (?)"; IP = "192.168.31.91" }
    "b0-19-21-7a-f2-48" = @{ Name = "Каб. 13"; IP = "192.168.31.59" }
}

# Инициализация счетчиков
foreach($mac in $script:DecoData.Keys) { 
    $script:Stats[$mac] = [PSCustomObject]@{ UpCount=0; LastStatus=$true; TotalChecks=0 } 
}

# --- Импорт Win32 API для кастомизации Windows Frame ---
$Win32Code = @"
using System;
using System.Runtime.InteropServices;
public class Win32Theme {
    [DllImport("dwmapi.dll")]
    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int dark, int size);
    public static void Apply(IntPtr hwnd) {
        int d = 1;
        DwmSetWindowAttribute(hwnd, 20, ref d, 4);
    }
}
"@
if (-not ([System.Management.Automation.PSTypeName]"Win32Theme").Type) { Add-Type -TypeDefinition $Win32Code }

# --- Функционал Логирования ---
function Write-SentryLog($msg) {
    $time = Get-Date -Format "HH:mm:ss"
    $logBox.Dispatcher.Invoke([Action]{
        $logBox.AppendText("[$time] $msg`r`n")
        $logBox.ScrollToEnd()
    })
}

# --- Создание Кастомного Уведомления ---
function Show-SentryAlert($msg) {
    $alert = New-Object Windows.Window
    $alert.Title = "SYSTEM MESSAGE"
    $alert.Width = 360
    $alert.Height = 190
    $alert.Background = [Windows.Media.Brushes]::Black
    $alert.WindowStartupLocation = "CenterOwner"
    $alert.Owner = $window
    $alert.ResizeMode = "NoResize"
    $alert.ShowInTaskbar = $false
    
    $alert.Add_SourceInitialized({ 
        [Win32Theme]::Apply((New-Object System.Windows.Interop.WindowInteropHelper($alert)).Handle) 
    })
    
    $alertStack = New-Object Windows.Controls.StackPanel
    $alertStack.VerticalAlignment = "Center"
    
    $alertText = New-Object Windows.Controls.TextBlock
    $alertText.Text = $msg
    $alertText.Foreground = [Windows.Media.Brushes]::LimeGreen
    $alertText.TextAlignment = "Center"
    $alertText.FontSize = 13
    $alertText.FontWeight = "Bold"
    $alertText.Margin = "25"
    $alertText.TextWrapping = "Wrap"
    
    $alertShadow = New-Object Windows.Media.Effects.DropShadowEffect
    $alertShadow.Color = [Windows.Media.Colors]::LimeGreen
    $alertShadow.BlurRadius = 15
    $alertShadow.ShadowDepth = 0
    $alertText.Effect = $alertShadow
    
    $okBtn = New-Object Windows.Controls.Button
    $okBtn.Content = "ПРИНЯТО"
    $okBtn.Width = 110
    $okBtn.Height = 35
    $okBtn.Background = [Windows.Media.Brushes]::Black
    $okBtn.Foreground = [Windows.Media.Brushes]::White
    $okBtn.BorderBrush = [Windows.Media.Brushes]::LimeGreen
    $okBtn.BorderThickness = 1
    $okBtn.Cursor = [Windows.Input.Cursors]::Hand
    $okBtn.Add_Click({ $alert.Close() })
    
    [void]$alertStack.Children.Add($alertText)
    [void]$alertStack.Children.Add($okBtn)
    $alert.Content = $alertStack
    $alert.ShowDialog() | Out-Null
}

# --- Главное Окно Приложения ---
$window = New-Object Windows.Window
$window.Title = "Deco Sentry Pro v$($script:Version)"
$window.Width = 440
$window.Height = 850
$window.Background = [Windows.Media.Brushes]::Black
$window.ResizeMode = "NoResize"
$window.WindowStartupLocation = "CenterScreen"
$window.Add_SourceInitialized({ 
    [Win32Theme]::Apply((New-Object System.Windows.Interop.WindowInteropHelper($window)).Handle) 
})

$rootStack = New-Object Windows.Controls.StackPanel
$rootStack.Margin = "35"
$window.Content = $rootStack

# Логотип/Заголовок
$uiHeader = New-Object Windows.Controls.TextBlock
$uiHeader.Text = "DECO SENTRY"
$uiHeader.Foreground = [Windows.Media.Brushes]::LimeGreen
$uiHeader.FontSize = 42
$uiHeader.FontWeight = "ExtraBold"
$uiHeader.HorizontalAlignment = "Center"
$uiHeader.Margin = "0,0,0,10"

$headerGlow = New-Object Windows.Media.Effects.DropShadowEffect
$headerGlow.Color = [Windows.Media.Colors]::LimeGreen
$headerGlow.BlurRadius = 30
$headerGlow.ShadowDepth = 0
$uiHeader.Effect = $headerGlow
[void]$rootStack.Children.Add($uiHeader)

# Индикатор прогресса
$pBar = New-Object Windows.Controls.ProgressBar
$pBar.Height = 4
$pBar.Minimum = 0
$pBar.Maximum = 100
$pBar.Value = 0
$pBar.Margin = "0,20,0,30"
$pBar.BorderThickness = 0
$pBar.Background = [Windows.Media.Brush](New-Object Windows.Media.BrushConverter).ConvertFromString("#151515")
$pBar.Foreground = [Windows.Media.Brushes]::LimeGreen

$pbGlow = New-Object Windows.Media.Effects.DropShadowEffect
$pbGlow.Color = [Windows.Media.Colors]::LimeGreen
$pbGlow.BlurRadius = 12
$pbGlow.ShadowDepth = 0
$pBar.Effect = $pbGlow
[void]$rootStack.Children.Add($pBar)

# Конструктор кнопок
function Create-NeonButton($label, $colorCode, $glowCode) {
    $border = New-Object Windows.Controls.Border
    $border.CornerRadius = 15
    $border.Height = 60
    $border.Margin = "0,0,0,18"
    $border.BorderThickness = 1
    $border.BorderBrush = [Windows.Media.Brushes]::DarkSlateGray
    $border.Background = [Windows.Media.Brush](New-Object Windows.Media.BrushConverter).ConvertFromString($colorCode)
    
    $btnGlow = New-Object Windows.Media.Effects.DropShadowEffect
    $btnGlow.Color = [Windows.Media.ColorConverter]::ConvertFromString($glowCode)
    $btnGlow.BlurRadius = 15
    $btnGlow.ShadowDepth = 0
    $btnGlow.Opacity = 0.5
    $border.Effect = $btnGlow
    
    $btn = New-Object Windows.Controls.Button
    $btn.Content = $label
    $btn.Background = [Windows.Media.Brushes]::Transparent
    $btn.Foreground = [Windows.Media.Brushes]::White
    $btn.FontWeight = "Bold"
    $btn.FontSize = 14
    $btn.BorderThickness = 0
    $btn.Cursor = [Windows.Input.Cursors]::Hand
    
    $border.Child = $btn
    return @($border, $btn)
}

$btnDiag = Create-NeonButton "БЫСТРАЯ ДИАГНОСТИКА" "#1DB954" "#1DB954"
[void]$rootStack.Children.Add($btnDiag[0])

$btnWatch = Create-NeonButton "МОНИТОРИНГ СЕТИ" "#222222" "#FFFFFF"
[void]$rootStack.Children.Add($btnWatch[0])

$btnSave = Create-NeonButton "ВЫГРУЗИТЬ ДЛЯ АХЧ" "#D4145A" "#D4145A"
[void]$rootStack.Children.Add($btnSave[0])

# Консоль мониторинга
$logBox = New-Object Windows.Controls.TextBox
$logBox.Height = 200
$logBox.Background = [Windows.Media.Brushes]::Black
$logBox.Foreground = [Windows.Media.Brushes]::LimeGreen
$logBox.IsReadOnly = $true
$logBox.FontFamily = "Consolas"
$logBox.Padding = "12"
$logBox.FontSize = 11
$logBox.BorderThickness = 1
$logBox.BorderBrush = [Windows.Media.Brushes]::DarkSlateGray
$logBox.VerticalScrollBarVisibility = "Auto"
$logBox.TextWrapping = "Wrap"
[void]$rootStack.Children.Add($logBox)

# --- Основная логика ядра ---
$CoreTask = {
    param([bool]$UpdateUI)
    
    $pingObj = New-Object System.Net.NetworkInformation.Ping
    $batchResults = New-Object System.Collections.ArrayList
    $nodeKeys = $script:DecoData.Keys
    $nodeCount = $nodeKeys.Count
    $currentStep = 0
    
    foreach ($mac in $nodeKeys) {
        $currentStep++
        $item = $script:DecoData[$mac]
        
        if ($UpdateUI) { Write-SentryLog "Сканирование: $($item.Name)" }
        
        $isOnline = $false
        try { 
            $replyStatus = $pingObj.Send($item.IP, 500)
            if ($replyStatus.Status -eq "Success") { $isOnline = $true } 
        } catch { }
        
        # Обновление внутренней статистики
        $script:Stats[$mac].LastStatus = $isOnline
        $script:Stats[$mac].TotalChecks++
        if ($isOnline) { $script:Stats[$mac].UpCount++ }
        
        # Обновление прогресса
        if ($UpdateUI) {
            $pBar.Value = ($currentStep / $nodeCount) * 100
            $pBar.Dispatcher.Invoke([Action]{}, "Background")
        }
        
        # Формирование текстового статуса без использования Inline IF
        $visualStatus = "○ OFFLINE"
        if ($isOnline) { $visualStatus = "● ONLINE" }
        
        # Расчет процента доступности
        $rawUptime = ($script:Stats[$mac].UpCount / [math]::Max(1, $script:Stats[$mac].TotalChecks)) * 100
        $finalUptime = [math]::Round($rawUptime)
        
        # Сборка объекта результата (совместимый метод)
        $resultRow = New-Object PSObject
        $resultRow | Add-Member -MemberType NoteProperty -Name "Point" -Value $item.Name
        $resultRow | Add-Member -MemberType NoteProperty -Name "IP" -Value $item.IP
        $resultRow | Add-Member -MemberType NoteProperty -Name "Status" -Value $visualStatus
        $resultRow | Add-Member -MemberType NoteProperty -Name "Uptime" -Value "$finalUptime%"
        
        [void]$batchResults.Add($resultRow)
    }
    
    if ($UpdateUI) { $pBar.Value = 0 }
    return $batchResults
}

# --- Функция отображения детального отчета ---
function Show-ReportView($dataList) {
    $subWin = New-Object Windows.Window
    $subWin.Title = "DIAGNOSTIC REPORT"
    $subWin.Width = 520; $subWin.Height = 600
    $subWin.Background = [Windows.Media.Brushes]::Black
    $subWin.WindowStartupLocation = "CenterOwner"; $subWin.Owner = $window
    
    $subWin.Add_SourceInitialized({ 
        [Win32Theme]::Apply((New-Object System.Windows.Interop.WindowInteropHelper($subWin)).Handle) 
    })
    
    $subLayout = New-Object Windows.Controls.StackPanel; $subLayout.Margin = "25"
    
    $dataGrid = New-Object Windows.Controls.ListView
    $dataGrid.ItemsSource = $dataList
    $dataGrid.Background = [Windows.Media.Brushes]::Black
    $dataGrid.Foreground = [Windows.Media.Brushes]::LimeGreen
    $dataGrid.BorderThickness = 0
    $dataGrid.FontFamily = "Consolas"
    
    $viewDef = New-Object Windows.Controls.GridView
    $colNames = @("Point", "IP", "Status", "Uptime")
    
    foreach($name in $colNames) {
        $col = New-Object Windows.Controls.GridViewColumn
        $col.Header = $name
        $col.Width = 115
        $col.DisplayMemberBinding = New-Object Windows.Data.Binding $name
        [void]$viewDef.Columns.Add($col)
    }
    
    $dataGrid.View = $viewDef
    [void]$subLayout.Children.Add($dataGrid)
    $subWin.Content = $subLayout
    $subWin.ShowDialog() | Out-Null
}

# --- Обработка событий кнопок ---

$btnDiag[1].Add_Click({
    Write-SentryLog "РУЧНОЙ ПЕРЕЗАПУСК ДИАГНОСТИКИ..."
    $results = &$CoreTask -UpdateUI $true
    Write-SentryLog "СКАНИРОВАНИЕ ЗАВЕРШЕНО. ВЫВОД ОТЧЕТА."
    Show-ReportView $results
})

$mainTimer = New-Object Windows.Threading.DispatcherTimer
$mainTimer.Interval = [TimeSpan]::FromSeconds(30)
$mainTimer.Add_Tick({ 
    $null = &$CoreTask -UpdateUI $false
    Write-SentryLog "ФОНОВАЯ СИНХРОНИЗАЦИЯ: OK"
})

$btnWatch[1].Add_Click({
    if (-not $script:IsMonitoring) {
        $script:IsMonitoring = $true
        $btnWatch[0].Background = [Windows.Media.Brushes]::LimeGreen
        $btnWatch[1].Foreground = [Windows.Media.Brushes]::Black
        $mainTimer.Start()
        Write-SentryLog "РЕЖИМ МОНИТОРИНГА: АКТИВИРОВАН."
    } else {
        $script:IsMonitoring = $false
        $btnWatch[0].Background = [Windows.Media.Brush](New-Object Windows.Media.BrushConverter).ConvertFromString("#222222")
        $btnWatch[1].Foreground = [Windows.Media.Brushes]::White
        $mainTimer.Stop()
        Write-SentryLog "РЕЖИМ МОНИТОРИНГА: ОСТАНОВЛЕН."
    }
})

$btnSave[1].Add_Click({
    Write-SentryLog "ЭКСПОРТ ДАННЫХ В CSV..."
    try {
        $desktopPath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "DECO_REPORT_AXCH.csv")
        $exportPayload = New-Object System.Collections.ArrayList
        
        foreach($mac in $script:DecoData.Keys) {
            $sData = $script:Stats[$mac]
            $upValue = [math]::Round(($sData.UpCount / [math]::Max(1, $sData.TotalChecks)) * 100)
            
            $statusFlag = "DOWN"
            if ($sData.LastStatus) { $statusFlag = "OK" }
            
            $row = New-Object PSObject
            $row | Add-Member -MemberType NoteProperty -Name "Cabinet" -Value $script:DecoData[$mac].Name
            $row | Add-Member -MemberType NoteProperty -Name "Availability" -Value "$upValue%"
            $row | Add-Member -MemberType NoteProperty -Name "CurrentStatus" -Value $statusFlag
            [void]$exportPayload.Add($row)
        }
        
        $exportPayload | Export-Csv -Path $desktopPath -NoTypeInformation -Encoding utf8 -Delimiter ";"
        Write-SentryLog "ФАЙЛ СОХРАНЕН: DECO_REPORT_AXCH.csv"
        Show-SentryAlert "ДАННЫЕ УСПЕШНО ВЫГРУЖЕНЫ НА РАБОЧИЙ СТОЛ."
    } catch {
        Write-SentryLog "КРИТИЧЕСКАЯ ОШИБКА ПРИ ЭКСПОРТЕ."
        Show-SentryAlert "ОШИБКА: НЕ УДАЛОСЬ СОХРАНИТЬ ФАЙЛ."
    }
})

# Запуск приложения
Write-SentryLog "СИСТЕМА DECO SENTRY PRO v$($script:Version) ЗАПУЩЕНА."
Write-SentryLog "ОЖИДАНИЕ КОМАНДЫ..."
[void]$window.ShowDialog()
