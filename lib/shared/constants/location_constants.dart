class UsState {
  const UsState({required this.name, required this.abbreviation});

  final String name;
  final String abbreviation;
}

class Country {
  const Country({required this.name, required this.code});

  final String name;
  final String code;
}

class TimezoneOption {
  const TimezoneOption({required this.name, required this.label});

  final String name;
  final String label;
}

/// Complete list of US states (plus District of Columbia).
const List<UsState> US_STATES = [
  UsState(name: 'Alabama', abbreviation: 'AL'),
  UsState(name: 'Alaska', abbreviation: 'AK'),
  UsState(name: 'Arizona', abbreviation: 'AZ'),
  UsState(name: 'Arkansas', abbreviation: 'AR'),
  UsState(name: 'California', abbreviation: 'CA'),
  UsState(name: 'Colorado', abbreviation: 'CO'),
  UsState(name: 'Connecticut', abbreviation: 'CT'),
  UsState(name: 'Delaware', abbreviation: 'DE'),
  UsState(name: 'Florida', abbreviation: 'FL'),
  UsState(name: 'Georgia', abbreviation: 'GA'),
  UsState(name: 'Hawaii', abbreviation: 'HI'),
  UsState(name: 'Idaho', abbreviation: 'ID'),
  UsState(name: 'Illinois', abbreviation: 'IL'),
  UsState(name: 'Indiana', abbreviation: 'IN'),
  UsState(name: 'Iowa', abbreviation: 'IA'),
  UsState(name: 'Kansas', abbreviation: 'KS'),
  UsState(name: 'Kentucky', abbreviation: 'KY'),
  UsState(name: 'Louisiana', abbreviation: 'LA'),
  UsState(name: 'Maine', abbreviation: 'ME'),
  UsState(name: 'Maryland', abbreviation: 'MD'),
  UsState(name: 'Massachusetts', abbreviation: 'MA'),
  UsState(name: 'Michigan', abbreviation: 'MI'),
  UsState(name: 'Minnesota', abbreviation: 'MN'),
  UsState(name: 'Mississippi', abbreviation: 'MS'),
  UsState(name: 'Missouri', abbreviation: 'MO'),
  UsState(name: 'Montana', abbreviation: 'MT'),
  UsState(name: 'Nebraska', abbreviation: 'NE'),
  UsState(name: 'Nevada', abbreviation: 'NV'),
  UsState(name: 'New Hampshire', abbreviation: 'NH'),
  UsState(name: 'New Jersey', abbreviation: 'NJ'),
  UsState(name: 'New Mexico', abbreviation: 'NM'),
  UsState(name: 'New York', abbreviation: 'NY'),
  UsState(name: 'North Carolina', abbreviation: 'NC'),
  UsState(name: 'North Dakota', abbreviation: 'ND'),
  UsState(name: 'Ohio', abbreviation: 'OH'),
  UsState(name: 'Oklahoma', abbreviation: 'OK'),
  UsState(name: 'Oregon', abbreviation: 'OR'),
  UsState(name: 'Pennsylvania', abbreviation: 'PA'),
  UsState(name: 'Rhode Island', abbreviation: 'RI'),
  UsState(name: 'South Carolina', abbreviation: 'SC'),
  UsState(name: 'South Dakota', abbreviation: 'SD'),
  UsState(name: 'Tennessee', abbreviation: 'TN'),
  UsState(name: 'Texas', abbreviation: 'TX'),
  UsState(name: 'Utah', abbreviation: 'UT'),
  UsState(name: 'Vermont', abbreviation: 'VT'),
  UsState(name: 'Virginia', abbreviation: 'VA'),
  UsState(name: 'Washington', abbreviation: 'WA'),
  UsState(name: 'West Virginia', abbreviation: 'WV'),
  UsState(name: 'Wisconsin', abbreviation: 'WI'),
  UsState(name: 'Wyoming', abbreviation: 'WY'),
  UsState(name: 'District of Columbia', abbreviation: 'DC'),
];

/// Supported countries.
const List<Country> COUNTRY_LIST = [
  Country(name: 'United States', code: 'US'),
  Country(name: 'United Kingdom', code: 'UK'),
];

/// Common timezones used in the app.
const List<TimezoneOption> TIMEZONE_LIST = [
  TimezoneOption(name: 'America/New_York', label: 'Eastern Time (ET)'),
  TimezoneOption(name: 'America/Chicago', label: 'Central Time (CT)'),
  TimezoneOption(name: 'America/Denver', label: 'Mountain Time (MT)'),
  TimezoneOption(name: 'America/Los_Angeles', label: 'Pacific Time (PT)'),
  TimezoneOption(name: 'America/Phoenix', label: 'Arizona (MST - No DST)'),
  TimezoneOption(name: 'America/Anchorage', label: 'Alaska Time (AKT)'),
  TimezoneOption(name: 'Pacific/Honolulu', label: 'Hawaii Time (HST)'),
  TimezoneOption(name: 'America/Detroit', label: 'Detroit (ET)'),
  TimezoneOption(name: 'America/Indiana/Indianapolis', label: 'Indiana (ET)'),
  TimezoneOption(name: 'America/Boise', label: 'Boise (MT)'),
  TimezoneOption(name: 'Europe/London', label: 'London (GMT/BST)'),
  TimezoneOption(name: 'Australia/Sydney', label: 'Sydney (AEST)'),
  TimezoneOption(name: 'Australia/Melbourne', label: 'Melbourne (AEST)'),
  TimezoneOption(name: 'Australia/Brisbane', label: 'Brisbane (AEST)'),
  TimezoneOption(name: 'Australia/Perth', label: 'Perth (AWST)'),
  TimezoneOption(name: 'Australia/Adelaide', label: 'Adelaide (ACST)'),
];


