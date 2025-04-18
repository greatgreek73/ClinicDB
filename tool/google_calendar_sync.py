import os
import datetime
from googleapiclient.discovery import build
from google.oauth2 import service_account
from google.cloud import firestore

# === НАСТРОЙКИ ===
SCOPES = ['https://www.googleapis.com/auth/calendar.readonly']
SERVICE_ACCOUNT_FILE = 'tool/service_account.json'  # Убедитесь, что файл находится в этой папке
CALENDAR_ID = 'nms.dentalclinik@gmail.com'  # Или ваш ID календаря
FIRESTORE_PROJECT = 'clinicdb-9ec3f'  # ← Ваш Project ID из Google Cloud

def get_calendar_service(creds):
    service = build('calendar', 'v3', credentials=creds)
    return service

def get_events(service, calendar_id, time_min, time_max):
    events_result = service.events().list(
        calendarId=calendar_id,
        timeMin=time_min.isoformat(),
        timeMax=time_max.isoformat(),
        singleEvents=True,
        orderBy='startTime'
    ).execute()
    return events_result.get('items', [])

def main():
    # Авторизация для Google Calendar
    calendar_creds = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE,
        scopes=['https://www.googleapis.com/auth/calendar.readonly']
    )
    service = get_calendar_service(calendar_creds)

    # Авторизация для Firestore — без SCOPES
    firestore_creds = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE
    )
    db = firestore.Client(project=FIRESTORE_PROJECT, credentials=firestore_creds)

    # Получаем все события за большой период
    time_min = datetime.datetime(2000, 1, 1, tzinfo=datetime.timezone.utc)
    time_max = datetime.datetime(2100, 1, 1, tzinfo=datetime.timezone.utc)

    events = get_events(service, CALENDAR_ID, time_min, time_max)
    print(f'Найдено событий: {len(events)}')

    updated_ids = []
    for event in events:
        summary = event.get('summary', '')
        event_id = event.get('id')
        if not summary:
            continue

        # Извлекаем фамилию — первое слово и очищаем от знаков препинания
        first_word = summary.split()[0].strip()
        # Удаляем запятые и другие знаки препинания
        surname = ''.join(c for c in first_word if c.isalpha() or c.isspace()).strip().capitalize()
        
        print(f"Обрабатываю событие: '{summary}', извлеченная фамилия: '{surname}'")
        
        if not surname:
            print(f"Пропускаю событие '{summary}' - не удалось извлечь фамилию")
            continue

        # Попробуем найти пациента несколькими способами (с учетом регистра и без)
        patients_ref = db.collection('patients')
        
        # Попытка 1: Точное соответствие (как в оригинале)
        query1 = patients_ref.where('surname', '==', surname)
        patients1 = list(query1.stream())
        
        # Попытка 2: Поиск по searchKey (всегда в нижнем регистре)
        query2 = patients_ref.where('searchKey', '==', surname.lower())
        patients2 = list(query2.stream())
        
        # Попытка 3: Поиск с другим регистром (все в нижнем регистре)
        query3 = patients_ref.where('surname', '==', surname.lower())
        patients3 = list(query3.stream())
        
        # Попытка 4: Первая буква заглавная, остальные строчные
        surname_title = surname.title()
        query4 = patients_ref.where('surname', '==', surname_title)
        patients4 = list(query4.stream())
        
        # Объединяем все результаты, исключая дубликаты по ID
        all_patients = {}
        for p in patients1 + patients2 + patients3 + patients4:
            all_patients[p.id] = p
        
        patients = list(all_patients.values())
        
        print(f"Поиск пациента '{surname}': найдено {len(patients)} вариантов")
        if len(patients) > 0:
            variants = [f"{p.to_dict().get('surname')} ({p.id})" for p in patients]
            print(f"Найденные варианты: {', '.join(variants)}")

        if len(patients) == 1:
            patient_doc = patients[0]
            print(f'Обновляю пациента: {surname} ({patient_doc.id})')
            # Получаем дату начала события
            event_start = event.get('start', {}).get('dateTime')
            if event_start:
                # Firestore принимает datetime, преобразуем строку в datetime
                from dateutil import parser
                event_start_dt = parser.isoparse(event_start)
            else:
                event_start_dt = None

            update_data = {
                'scheduledByAssistant': True,
                'calendarEventId': event_id,
                'ambiguousSchedule': firestore.DELETE_FIELD
            }
            if event_start_dt:
                update_data['eventStart'] = event_start_dt

            patient_doc.reference.update(update_data)
            updated_ids.append(patient_doc.id)
        elif len(patients) > 1:
            print(f'Найдено несколько пациентов с фамилией {surname}')
            for patient_doc in patients:
                patient_doc.reference.update({
                    'scheduledByAssistant': True,
                    'calendarEventId': event_id,
                    'ambiguousSchedule': True
                })
                updated_ids.append(patient_doc.id)
        else:
            print(f'Пациент с фамилией {surname} не найден')

    # Выводим итоговые значения для обновлённых пациентов
    print("\nПроверка обновлённых документов:")
    for pid in updated_ids:
        doc = db.collection('patients').document(pid).get()
        if doc.exists:
            data = doc.to_dict()
            print(f"{pid}: scheduledByAssistant={data.get('scheduledByAssistant')}, ambiguousSchedule={data.get('ambiguousSchedule')}, surname={data.get('surname')}, name={data.get('name')}")
        else:
            print(f"{pid}: документ не найден")

if __name__ == '__main__':
    main()
