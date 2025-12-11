This script will change the default authentication method in microsoft 365 for the users from the push to SMS.
You need to create an app with the permissions:
  *  AuditLog.Read.All
  *  UserAuthentication.Method.ReadWrite.All


After that you will need to following info for the config file:
  * Tenenet ID
  * Client ID
  * Client Secret
  * Proxy server (if one is needed00)

In the script file, change the $configPath to the location of your script.
