$tempDir = "$env:TEMP\AI_Chat_Install"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
Set-Location $tempDir

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
    $installerPath = "$tempDir\python_installer.exe"
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
    while True:
        try:
            client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            server_ip = input("Введите IP-адрес сервера: ")
            if not server_ip:
                print("IP-адрес не может быть пустым!")
                continue
            port = 5000
            print(f"Подключение к {server_ip}...")
            client.connect((server_ip, port))
            print("Подключено к серверу!")
            print()
            while True:
                message = input("Вы: ")
                if message.lower() == 'exit':
                    return
                elif message.lower() == 'clear':
                    clear_screen()
                    print_header()
                    continue
                client.send(message.encode('utf-8'))
                response = client.recv(1024).decode('utf-8')
                print(f"AI: {response}")
                print()
        except ConnectionRefusedError:
            print("Не удалось подключиться к серверу.")
            print("Проверьте:")
            print("1. Правильность IP-адреса")
            print("2. Запущен ли сервер")
            print("3. Компьютеры в одной сети")
            print()
            retry = input("Хотите попробовать снова? (y/n): ")
            if retry.lower() != 'y':
                return
        except Exception as e:
            print(f"Ошибка: {e}")
            print()
            retry = input("Хотите попробовать снова? (y/n): ")
            if retry.lower() != 'y':
                return
        finally:
            try:
                client.close()
            except:
                pass

if __name__ == "__main__":
    try:
        start_client()
    except KeyboardInterrupt:
        print("\\nПрограмма завершена")
    except Exception as e:
        print(f"\\nНеожиданная ошибка: {e}")
    finally:
        print("\\nДо свидания!")
        input("Нажмите Enter для выхода...")
'@

Write-Host "=== Установка AI Чат-клиента ==="
Write-Host ""

if (-not (Check-Python)) {
    if (-not (Install-Python)) {
        Write-Host "Ошибка: Не удалось установить Python. Установка прервана."
        exit
    }
}

Set-Content -Path "$tempDir\client.py" -Value $clientCode

chcp 65001
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8

python "$tempDir\client.py"
Remove-Item -Path $tempDir -Recurse -Force
