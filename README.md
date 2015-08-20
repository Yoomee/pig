# Pig

### Google Analytics

To configure Pig to display google analytics info when editing a page the following steps are required.
Set the analytics tracking code in `config/initializers/pig.rb`

    config.ga_code = 'UA-xxxxxxxx-1'

We then have to give Pig the permission to access to the Google analytics API

1. Login to the [Google developer console](https://console.developers.google.com)

##### Enable Access to the analytics API

1. Click **Create Project**
2. Give the project a name
3. Click the newly created project name
4. Enable the *Analytics Api* from the **APIs & auth -> APIs**

##### Create a service account

1. Click the newly created project name
2. Click **Add Credentials** and choose *Sevice Account* from the dropdown
3. Choose *P12* and click **Create**
4. Copy the downloaded \*.p12 file to the project root

##### Add a ga_config.yml file to the project

1. Create a new ga_config.yml file in the root of your project
2. Populate it with the following

    ```
    service_account_email: <Service account email>
    key_file: <The name of the keyfile downloaded in the previous step (Including .p12)>
    key_secret: notasecret
    profileID: <GA tracking code>
    application_name: <The name given to the service account>
    application_version: 1.0
    ```

##### Give the service user access to the analytics account

1. Navigate to [Google Analytics](https://www.google.com/analytics/web/)
2. Click the **admin** tab
3. Choose the relevant account from the drop down
4. Add the service account email to the user management with *Read & analyze* privileges
