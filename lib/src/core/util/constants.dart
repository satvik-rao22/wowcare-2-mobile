const kBaseUrlforhttp = '661b8bff65444945d04fb58a.mockapi.io';

const accessTokenUrlQA =
    'https://login.childcarewow.app/realms/wowcare_qa/protocol/openid-connect/token';
const accessTokenUrlpreprod =
    'https://login.childcarewow.app/realms/wowcare_preprod/protocol/openid-connect/token';
const accessTokenUrlprod =
    'https://login.childcarewow.net/realms/wowcare/protocol/openid-connect/token';

const resetPasswordurlQA =
    'https://login.qa.techvgi.com/realms/school_erp_qa/login-actions/reset-credentials?client_id=erp_sso';
const resetPasswordurlPreprod =
    'https://login.qa.techvgi.com/realms/school_erp_preprod/login-actions/reset-credentials?client_id=erp_sso';
const resetPasswordurlProd =
    'https://login.childcarewow.net/realms/wowcare/login-actions/reset-credentials?client_id=wowcare_sso';

const qa = 'https://qa.childcarewow.app/wowcare-qa/';
const atoconn =
    "https://qa.childcarewow.app/wowcare-preprod/"; // api :-  https://backend.childcarewow.net/

const preprod = 'https://qa.childcarewow.app/wowcare-preprod/';
const prod =
    "https://backend.childcarewow.net/"; //'https://api.childcarewow.net/backend/';

const local = 'http://192.168.1.17:8181/';
const local1 = 'http://192.168.29.200:8181/';

// const baseUrl = qa;
const baseUrl = prod;

const String appVersion = '1.2.6';
const String envDeployment = baseUrl == qa
    ? 'QA-'
    : baseUrl == preprod
        ? 'UAT-'
        : baseUrl == prod
            ? ''
            : '';

const accessTokenUrl = baseUrl == preprod
    ? accessTokenUrlpreprod
    : baseUrl == prod
        ? accessTokenUrlprod
        : accessTokenUrlQA;

const resetPasswordurl = baseUrl == preprod
    ? resetPasswordurlPreprod
    : baseUrl == prod
        ? resetPasswordurlProd
        : resetPasswordurlQA;

final String vapidKey = baseUrl == qa
    ? "BHSxm5wnLbVb-zC4JEqEGE3LvJGTHanYlNMwyIFub2fEm4yypflWLndcsucSgGN3ny1NhEiRMkz7S5Rl7G-DYdc"
    : baseUrl == preprod
        ? "BOMsC9jrYpOAARwJNpb1AoSOpY_l7xdAcVxIGZ-_uA9gEcriQLZeGPy8uCbtfA4A7-J9uhwhn_xYvuoZNuwFh1c"
        : baseUrl == prod
            ? "BHSxm5wnLbVb-zC4JEqEGE3LvJGTHanYlNMwyIFub2fEm4yypflWLndcsucSgGN3ny1NhEiRMkz7S5Rl7G-DYdc"
            : "";

// To use QA server, change the base URL below:
// const wowcareSchoolMsBaseUrl = 'https://your-qa-server-url/wowcare-school-ms';
// Note: Use buildApiUrl() function for all API endpoints instead of hardcoded URLs
// Example: buildApiUrl(APIPathHelper.getValue(APIPath.paymentGatewayTransactions))

/// Utility function to construct API URLs without double slashes
String buildApiUrl(String endpoint) {
  // Remove trailing slash from baseUrl if it exists
  String cleanBaseUrl = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;

  // Remove leading slash from endpoint if it exists
  String cleanEndpoint =
      endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;

  return '$cleanBaseUrl/$cleanEndpoint';
}
