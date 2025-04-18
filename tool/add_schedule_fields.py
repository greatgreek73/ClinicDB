from google.cloud import firestore
from google.oauth2 import service_account
import sys
import time

print("Скрипт стартовал")

# === НАСТРОЙКИ ===
SERVICE_ACCOUNT_FILE = 'tool/service_account.json'  # путь к вашему сервисному ключу
FIRESTORE_PROJECT = 'clinicdb-9ec3f'  # ваш Project ID

# Используем обработку исключений для каждого шага
try:
    print("Загрузка файла сервисного аккаунта...")
    firestore_creds = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE
    )
    print("Сервисный аккаунт загружен успешно.")
except Exception as e:
    print(f"ОШИБКА при загрузке сервисного аккаунта: {str(e)}")
    sys.exit(1)

try:
    print("Подключение к Firestore...")
    db = firestore.Client(project=FIRESTORE_PROJECT, credentials=firestore_creds)
    print("Успешно подключились к Firestore.")
except Exception as e:
    print(f"ОШИБКА при подключении к Firestore: {str(e)}")
    sys.exit(1)

# Получаем всех пациентов
patients = []
print("Получение списка пациентов из коллекции 'patients'...")
try:
    # Получаем всех пациентов
    patients_ref = db.collection('patients')
    start_time = time.time()
    patients = list(patients_ref.stream())
    end_time = time.time()
    print(f"Время запроса: {end_time - start_time:.2f} сек.")
    print(f"Найдено пациентов: {len(patients)}")
except Exception as e:
    print(f"ОШИБКА при получении пациентов: {str(e)}")
    sys.exit(1)

# Если нашли хотя бы одного пациента, пробуем обновить
if patients:
    print("Начинаем обновление пациентов...")
    updated = 0
    total = len(patients)
    
    for i, patient in enumerate(patients):
        try:
            data = patient.to_dict()
            update_data = {}
            if 'scheduledByAssistant' not in data:
                update_data['scheduledByAssistant'] = False
            if 'ambiguousSchedule' not in data:
                update_data['ambiguousSchedule'] = False
            
            if update_data:
                # Показываем прогресс только для каждого 5-го пациента или если это особо важно
                if i % 5 == 0 or i == total - 1:
                    print(f"Обрабатываю {i+1}/{total}: {patient.id}")
                
                patient.reference.update(update_data)
                updated += 1
                
                # Детальный вывод только для первых 3 пациентов (для демонстрации)
                if i < 3:
                    print(f"Пациент {patient.id} обновлен: {update_data}")
        except Exception as e:
            print(f"ОШИБКА при обновлении пациента {patient.id}: {str(e)}")
    
    print(f"Готово! Обновлено пациентов: {updated}")
else:
    print("Не найдено пациентов для обновления.")
    
print("Скрипт завершил работу.")
