import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clinicdb/patient_details_screen.dart';
import 'package:clinicdb/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Set up a FakeCloudFirestore instance
  late FakeCloudFirestore fakeFirestore;
  const String patientId = 'test_patient_id_theme';

  setUpAll(() async {
    // Mock SharedPreferences for _loadPlannedTreatment within PatientDetailsScreen
    // SharedPreferences.setMockInitialValues({}); needs to be called before FakeCloudFirestore usually
    // to avoid any async issues during setup.
    SharedPreferences.setMockInitialValues({
      'planned_treatment_$patientId': 'Initial planned treatment for test.',
    });
  });

  setUp(() async {
    fakeFirestore = FakeCloudFirestore();
    // Populate with necessary patient data
    await fakeFirestore.collection('patients').doc(patientId).set({
      'surname': 'ThemeTest',
      'name': 'Patient',
      'age': 35,
      'price': 60000.0, // Ensure double for price
      'photoUrl': null,
      'payments': [
        {'amount': 15000.0, 'date': Timestamp.now()} // Ensure double for amount
      ],
      'hadConsultation': true,
      'waitingList': false,
      'secondStage': true,
      'hotPatient': false,
      'additionalPhotos': [],
      'city': 'Test City',
      'phone': '(123) 456-78-90',
      // Add any other fields that PatientDetailsScreen might expect to avoid null errors
    });

    // Mock the treatments collection as PatientDetailsScreen tries to read it
    // Even an empty mock can prevent null/missing collection errors during build.
    // Add a dummy treatment to ensure _getTreatmentCounts doesn't fail if it expects data
     await fakeFirestore.collection('treatments').add({
      'patientId': patientId,
      'treatmentType': 'Кариес',
      'toothNumber': [11, 12],
      'date': Timestamp.now(),
    });
  });

  testWidgets('PatientDetailsScreen applies dark theme correctly', (WidgetTester tester) async {
    // Override Firestore instance with the fake one for this test
    final originalFirestore = FirebaseFirestore.instance;
    FirebaseFirestore.instance = fakeFirestore;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeData, // Apply the app's default dark theme
        home: PatientDetailsScreen(patientId: patientId),
      ),
    );

    // Allow time for Firebase streams and UI to build
    // Using pumpAndSettle with a timeout to avoid infinite pump in case of issues
    await tester.pumpAndSettle(Duration(seconds: 5)); 

    // Verify Scaffold Background Color
    final ScaffoldState scaffoldState = tester.firstState(find.byType(Scaffold));
    expect(scaffoldState.widget.backgroundColor, AppTheme.darkBackgroundColor);

    // Verify AppBar Background Color
    final AppBar appBar = tester.widget(find.byType(AppBar));
    expect(appBar.backgroundColor, AppTheme.darkSurfaceColor); // As per AppTheme.themeData.appBarTheme

    // Verify Patient Name Text Color (assuming it's within the patientInfoCard)
    // The text is '${patientData['surname']} ${patientData['name']}'
    // For RichText, it's better to find by a common ancestor or a more specific Key if available.
    // However, if it's a simple Text widget, this should work.
    // We need to find the Text widget that displays "ThemeTest Patient"
    final patientNameFinder = find.text('ThemeTest Patient');
    expect(patientNameFinder, findsOneWidget);
    Text patientNameText = tester.widget(patientNameFinder);
    // The nameStyle in _buildPatientDetails uses Colors.white directly.
    expect(patientNameText.style?.color, Colors.white); 

    // Verify Patient Info Card's Background Color (using the Key added)
    final patientInfoCardFinder = find.byKey(Key('patientInfoCard'));
    expect(patientInfoCardFinder, findsOneWidget);
    final Container patientInfoCardContainer = tester.widget(patientInfoCardFinder);
    // The card uses kDarkCardDecoration which has a specific color.
    expect((patientInfoCardContainer.decoration as BoxDecoration).color, AppTheme.darkCardColor);

    // Verify a toggle's active color (e.g., the 'Второй этап' switch)
    // The 'Второй этап' toggle is associated with 'secondStage' field, which is true.
    // We find the Switch widget that is likely after the Text 'Второй этап'
    final switchFinder = find.widgetWithText(Row, 'Второй этап').descendant(of: find.byType(Row), matching: find.byType(Switch));
    expect(switchFinder, findsOneWidget);
    Switch stageSwitch = tester.widget(switchFinder);
    expect(stageSwitch.activeColor, AppTheme.primaryColor); // From AppTheme.themeData.colorScheme.primary

    // Restore original Firestore instance
    FirebaseFirestore.instance = originalFirestore;
  });
}
