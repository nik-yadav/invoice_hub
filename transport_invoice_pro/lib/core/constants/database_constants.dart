/// Database table, schema, and Hive key constants.
class DatabaseConstants {
  DatabaseConstants._();

  // Supabase Database Tables
  static const String tableProfiles = 'profiles';
  static const String tableOrganizations = 'organizations';
  static const String tableInvoices = 'invoices';
  static const String tableInvoiceItems = 'invoice_items';
  static const String tableVehicles = 'vehicles';
  static const String tableDrivers = 'drivers';
  static const String tableClients = 'clients';

  // Supabase Storage Buckets
  static const String bucketInvoicesPdf = 'invoices-pdf';
  static const String bucketCompanyLogos = 'company-logos';
  static const String bucketSignatures = 'signatures';

  // Local Storage Keys
  static const String keyIsDarkMode = 'is_dark_mode';
  static const String keyAuthToken = 'auth_token';
  static const String keyUserPreferences = 'user_preferences';
  static const String keyLastSyncTimestamp = 'last_sync_timestamp';
}
