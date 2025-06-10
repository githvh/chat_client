# Проверка и установка Python
function Check-Python {
    try {
        $pythonVersion = python --version
        Write-Host "Python уже установлен: $pythonVersion"
        return $true
    }
    catch {
        Write-Host "Python не найден. Начинаем установку..."
        return $false
    }
}

function Install-Python {
    Write-Host "Скачивание Python..."
    $pythonUrl = "https://www.python.org/ftp/python/3.9.7/python-3.9.7-amd64.exe"
    $installerPath = "$env:TEMP\python_installer.exe"
    
    try {
        Invoke-WebRequest -Uri $pythonUrl -OutFile $installerPath
        Write-Host "Установка Python..."
        Start-Process -FilePath $installerPath -ArgumentList "/quiet", "InstallAllUsers=1", "PrependPath=1" -Wait
        Remove-Item $installerPath
        Write-Host "Python успешно установлен!"
        return $true
    }
    catch {
        Write-Host "Ошибка при установке Python: $_"
        return $false
    }
}

# Создание клиентского скрипта
function Create-ClientScript {
    $clientCode = @'
import socket
import sys
import os

def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

def print_header():
    print("=" * 50)
    print("           ПРОСТОЙ AI ЧАТ КЛИЕНТ")
    print("=" * 50)
    print("Для выхода введите 'exit'")
    print("Для очистки экрана введите 'clear'")
    print("=" * 50)
    print()

def start_client():
    clear_screen()
    print_header()
    
    # Создаем клиентский сокет (изначально пустышка)
    client = None

    while True:
        try:
            # Запрашиваем IP-адрес сервера
            server_ip = input("Введите IP-адрес сервера (для IPv6 используйте квадратные скобки, например: [::1]): ")
            if not server_ip:
                print("IP-адрес не может быть пустым!")
                continue
                
            port = 5000
            
            # Определяем, является ли IP-адрес IPv6 или IPv4
            if ':' in server_ip:
                # IPv6 адрес
                addr_family = socket.AF_INET6
                # Удаляем квадратные скобки, если они есть, для корректной обработки
                if server_ip.startswith('[') and server_ip.endswith(']'):
                    server_ip = server_ip[1:-1]
                # Для IPv6 connect требует кортеж из 4 элементов: (host, port, flowinfo, scopeid)
                server_address = (server_ip, port, 0, 0) 
            else:
                # IPv4 адрес
                addr_family = socket.AF_INET
                server_address = (server_ip, port)

            # Создаем клиентский сокет соответствующего типа
            client = socket.socket(addr_family, socket.SOCK_STREAM)

            # Подключаемся к серверу
            print(f"Подключение к {server_ip}...")
            client.connect(server_address)
            print("Подключено к серверу!")
            print()
            
            while True:
                # Получаем сообщение от пользователя
                message = input("Вы: ")
                
                if message.lower() == 'exit':
                    return
                elif message.lower() == 'clear':
                    clear_screen()
                    print_header()
                    continue
                
                # Отправляем сообщение серверу
                client.send(message.encode('utf-8'))
                
                # Получаем ответ от сервера
                response = client.recv(1024).decode('utf-8')
                print(f"AI: {response}")
                print()
                
        except ConnectionRefusedError:
            print("Не удалось подключиться к серверу.")
            print("Проверьте:")
            print("1. Правильность IP-адреса")
            print("2. Запущен ли сервер")
            print("3. Открыты ли нужные порты") # Обновлено сообщение
            print()
            retry = input("Хотите попробовать снова? (y/n): ")
            if retry.lower() != 'y':
                return
            # Пересоздаем клиентский сокет, чтобы можно было попробовать снова с новым адресом
            if client:
                client.close() # Закрываем старый сокет перед созданием нового
            client = None # Сбросим сокет, чтобы он был создан заново при следующей итерации
            
        except Exception as e:
            print(f"Ошибка: {e}")
            print()
            retry = input("Хотите попробовать снова? (y/n): ")
            if retry.lower() != 'y':
                return
            # Пересоздаем клиентский сокет, чтобы можно было попробовать снова с новым адресом
            if client:
                client.close() # Закрываем старый сокет перед созданием нового
            client = None # Сбросим сокет, чтобы он был создан заново при следующей итерации
            
        finally:
            # Закрываем сокет только если он был успешно создан
            if client:
                try:
                    client.close()
                except:
                    pass

if __name__ == "__main__":
    try:
        start_client()
    except KeyboardInterrupt:
        print("\nПрограмма завершена")
    except Exception as e:
        print(f"\nНеожиданная ошибка: {e}")
    finally:
        print("\nДо свидания!")
        input("Нажмите Enter для выхода...")
'@

    $clientPath = "$env:USERPROFILE\AI_Chat\simple_client.py"
    New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\AI_Chat" | Out-Null
    Set-Content -Path $clientPath -Value $clientCode
    return $clientPath
}

# Создание bat-файла для запуска
function Create-Launcher {
    $launcherCode = @'
@echo off
echo Запуск AI чат-клиента...
python "%~dp0simple_client.py"
pause
'@

    $launcherPath = "$env:USERPROFILE\AI_Chat\start_chat.bat"
    Set-Content -Path $launcherPath -Value $launcherCode
    return $launcherPath
}

# Создание ярлыка на рабочем столе
function Create-Shortcut {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\AI Chat.lnk")
    $Shortcut.TargetPath = "$env:USERPROFILE\AI_Chat\start_chat.bat"
    $Shortcut.WorkingDirectory = "$env:USERPROFILE\AI_Chat"
    $Shortcut.Save()
}

# Основной процесс установки
Write-Host "=== Установка AI Чат-клиента ==="
Write-Host ""

if (-not (Check-Python)) {
    if (-not (Install-Python)) {
        Write-Host "Ошибка: Не удалось установить Python. Установка прервана."
        exit
    }
}

Write-Host "Создание клиентского скрипта..."
$clientPath = Create-ClientScript

Write-Host "Создание файла запуска..."
$launcherPath = Create-Launcher

Write-Host "Создание ярлыка на рабочем столе..."
Create-Shortcut

Write-Host ""
Write-Host "=== Установка завершена! ==="
Write-Host "Клиент установлен в: $env:USERPROFILE\AI_Chat"
Write-Host "Ярлык создан на рабочем столе"
Write-Host ""
Write-Host "Для запуска клиента:"
Write-Host "1. Дважды кликните на ярлык 'AI Chat' на рабочем столе"
Write-Host "2. Или запустите файл: $launcherPath"
Write-Host ""
Write-Host "Нажмите любую клавишу для выхода..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 
