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

        # Извлекаем фамилию — первое слово
        surname = summary.split()[0].strip().capitalize()
        if not surname:
            continue

        patients_ref = db.collection('patients')
        query = patients_ref.where('surname', '==', surname)
        patients = list(query.stream())

        if len(patients) == 1:
            patient_doc = patients[0]
            print(f'Обновляю пациента: {surname} ({patient_doc.id})')
            patient_doc.reference.update({
                'scheduledByAssistant': True,
                'calendarEventId': event_id,
                'ambiguousSchedule': firestore.DELETE_FIELD
            })
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
