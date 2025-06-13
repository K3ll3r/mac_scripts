import requests
import json


# --- Configuration ---
# Replace with your Jamf Pro instance URL (e.g., "https://your-jamf-pro-instance.jamfcloud.com")
JAMF_PRO_URL = "https://your-jamf-pro-instance.jamfcloud.com"
# Replace with your Jamf Pro API username
JAMF_API_USERNAME = "apiuser"
# Replace with your Jamf Pro API password
JAMF_API_PASSWORD = "apipassword"

# Users to create (replace with your desired user details)
USERS_TO_CREATE = [
    {
        "plainPassword": "testpassword4321", # IMPORTANT: Use strong, unique passwords
        "username": "rebecca.bunch@domain.com",
        "realname": "Rebecca Bunch",
        "email": "rebecca.bunch@domain.com",
        "phone": "",
        "ldapServerId": 1,
        "distinguishedName": "uid=rebecca.bunch@domain.com,ou=users,dc=company,dc=okta,dc=com",
        "siteId": -1,
        "accessLevel": "GroupBasedAccess",
        "privilegeLevel": "CUSTOM",
        "lastPasswordChange": "1970-01-01T00:00:00",
        "changePasswordOnNextLogin": False,
        "failedLoginAttempts": 0,
        "accountStatus": "Enabled"
    },
    {
        "plainPassword": "testpassword4321", # IMPORTANT: Use strong, unique passwords
        "username": "josh.chan@domain.com",
        "realname": "Josh Chan",
        "email": "josh.chan@domain.com",
        "phone": "",
        "ldapServerId": 1,
        "distinguishedName": "uid=josh.chan@domain.com,ou=users,dc=company,dc=okta,dc=com",
        "siteId": -1,
        "accessLevel": "GroupBasedAccess",
        "privilegeLevel": "CUSTOM",
        "lastPasswordChange": "1970-01-01T00:00:00",
        "changePasswordOnNextLogin": False,
        "failedLoginAttempts": 0,
        "accountStatus": "Enabled"
    },
        {
        "plainPassword": "testpassword4321", # IMPORTANT: Use strong, unique passwords
        "username": "paula.proctor@domain.com",
        "realname": "Paula Proctor",
        "email": "paula.proctor@domain.com",
        "phone": "",
        "ldapServerId": 1,
        "distinguishedName": "uid=paula.proctor@domain.com,ou=users,dc=company,dc=okta,dc=com",
        "siteId": -1,
        "accessLevel": "GroupBasedAccess",
        "privilegeLevel": "CUSTOM",
        "lastPasswordChange": "1970-01-01T00:00:00",
        "changePasswordOnNextLogin": False,
        "failedLoginAttempts": 0,
        "accountStatus": "Enabled"
    }
]

# --- Functions ---

def get_jamf_auth_token(jamf_pro_url, username, password):
    """
    Obtains an authentication token from the Jamf Pro API.
    """
    token_url = f"{jamf_pro_url}/api/v1/auth/token"
    headers = {"Content-Type": "application/json"}
    try:
        response = requests.post(token_url, auth=(username, password), headers=headers)
        response.raise_for_status()  # Raise an HTTPError for bad responses (4xx or 5xx)
        return response.json()["token"]
    except requests.exceptions.RequestException as e:
        print(f"Error obtaining Jamf Pro API token: {e}")
        return None

def create_jamf_user(jamf_pro_url, auth_token, user_data):
    """
    Creates a new user account in Jamf Pro.
    """
    users_url = f"{jamf_pro_url}/api/v1/accounts"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {auth_token}"
    }
    try:
        response = requests.post(users_url, headers=headers, data=json.dumps(user_data))
        response.raise_for_status()
        print(f"Successfully created user: {user_data['realname']}")
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error creating user {user_data['realname']}: {e}")
        if response is not None:
            print(f"Response content: {response.text}")
        return None

# --- Main Execution ---
if __name__ == "__main__":
    if JAMF_PRO_URL == "YOUR_JAMF_PRO_URL" or \
       JAMF_API_USERNAME == "YOUR_API_USERNAME" or \
       JAMF_API_PASSWORD == "YOUR_API_PASSWORD":
        print("Please update the JAMF_PRO_URL, JAMF_API_USERNAME, and JAMF_API_PASSWORD variables with your Jamf Pro instance details.")
    else:
        print("Attempting to get Jamf Pro API token...")
        token = get_jamf_auth_token(JAMF_PRO_URL, JAMF_API_USERNAME, JAMF_API_PASSWORD)

        if token:
            print("Successfully obtained Jamf Pro API token.")
            for user in USERS_TO_CREATE:
                print(f"\nAttempting to create user: {user['realname']}...")
                create_jamf_user(JAMF_PRO_URL, token, user)
        else:
            print("Failed to obtain Jamf Pro API token. Cannot proceed with user creation.")

