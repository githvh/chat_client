$tempDir = "$env:TEMP\AI_Chat_Install"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
Set-Location $tempDir

# Проверка и установка Python
function Check-Python {
    try {
        $pythonVersion = python --version
        Write-Host "Python is already installed: $pythonVersion"
        return $true
    }
    catch {
        Write-Host "Python not found. Starting installation..."
        return $false
    }
}

function Install-Python {
    Write-Host "Downloading Python..."
    $pythonUrl = "https://www.python.org/ftp/python/3.9.7/python-3.9.7-amd64.exe"
    $installerPath = "$tempDir\python_installer.exe"
    
    try {
        Invoke-WebRequest -Uri $pythonUrl -OutFile $installerPath
        Write-Host "Installing Python..."
        Start-Process -FilePath $installerPath -ArgumentList "/quiet", "InstallAllUsers=1", "PrependPath=1" -Wait
        Remove-Item $installerPath
        Write-Host "Python installed successfully!"
        return $true
    }
    catch {
        Write-Host "Error installing Python: $_"
        return $false
    }
}

# Создание клиентского скрипта
$clientCode = @'
import socket
import sys
import os

if sys.stdout.encoding.lower() != 'utf-8':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

def print_header():
    print("=" * 50)
    print("           SIMPLE AI CHAT CLIENT")
    print("=" * 50)
    print("Type 'exit' to quit")
    print("Type 'clear' to clear the screen")
    print("=" * 50)
    print()

def start_client():
    clear_screen()
    print_header()
    
    while True:
        try:
            client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            server_ip = input("Enter server IP address: ")
            if not server_ip:
                print("IP address cannot be empty!")
                continue
            port = 5000
            print(f"Connecting to {server_ip}...")
            client.connect((server_ip, port))
            print("Connected to server!")
            print()
            
            while True:
                message = input("You: ")
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
            print("Could not connect to the server.")
            print("Check:")
            print("1. Correct IP address")
            print("2. Server is running")
            print("3. Computers are on the same network")
            print()
            retry = input("Try again? (y/n): ")
            if retry.lower() != 'y':
                return
                
        except Exception as e:
            print(f"Error: {e}")
            print()
            retry = input("Try again? (y/n): ")
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
        print("\nProgram terminated")
    except Exception as e:
        print(f"\nUnexpected error: {e}")
    finally:
        print("\nGoodbye!")
        input("Press Enter to exit...")
'@

# Основной процесс установки
Write-Host "=== Installing AI Chat Client ==="
Write-Host ""

if (-not (Check-Python)) {
    if (-not (Install-Python)) {
        Write-Host "Error: Could not install Python. Installation aborted."
        exit
    }
}

# Создаем файл клиента
Set-Content -Path "$tempDir\client.py" -Value $clientCode -Encoding UTF8

# Устанавливаем кодировку UTF-8 для консоли
chcp 65001
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8

# Запускаем клиент
python "$tempDir\client.py"

# Очищаем временные файлы
Remove-Item -Path $tempDir -Recurse -Force 
