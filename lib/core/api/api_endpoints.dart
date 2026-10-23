class ApiEndpoints {
  ApiEndpoints._();

  // Production by default. Use --dart-define=API_BASE_URL=... for local testing.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://nirmaya-clinic-api.vercel.app/api',
  );

  // Health
  static const String health = '/health/health';

  // Auth
  static const String login = '/auth/login';
  static const String verifyToken = '/auth/verify';

  // Dashboard
  static const String dashboardSummary = '/dashboard/summary';
  static const String dashboardPatients = '/dashboard/patients';
  static const String dashboardPatient = '/dashboard/patient';

  // Patients
  static const String patients = '/patients';
  static String patient(String id) => '/patients/$id';

  // Treatments
  static const String treatments = '/treatments';
  static String treatment(String id) => '/treatments/$id';

  // Visits
  static const String visits = '/visits';
  static const String visitsWithDetails = '/visits/with-details';
  static String visit(String id) => '/visits/$id';

  // Transactions
  static const String transactions = '/transactions';
  static String transaction(String id) => '/transactions/$id';

  // Installments
  static const String installments = '/installments';
  static String installment(String id) => '/installments/$id';

  // Documents
  static const String documents = '/documents';
  static const String documentsUpload = '/documents/upload';
  static String document(String id) => '/documents/$id';

  // Follow-ups
  static const String followups = '/followups';
  static String followup(String id) => '/followups/$id';

  // Doctors
  static const String doctors = '/doctors';
  static String doctor(String id) => '/doctors/$id';

  // Appointments
  static const String appointments = '/appointments';
  static String appointment(String id) => '/appointments/$id';

  // Bills
  static const String generateBill = '/bills/generate';
  static String bill(String id) => '/bills/$id';

  // Audit logs
  static const String auditLogs = '/audit-logs';
}
