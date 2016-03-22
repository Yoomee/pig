# Pig

## Installation

Add Pig to your Gemfile:

```ruby
gem 'pig', git: "https://#{ENV['GITHUB_PIG_TOKEN']}:x-oauth-basic@github.com/yoomee/pig.git", tag: '0.0.7.0'
```

Run the bundle command to install it.

To install it simply run:

```bash
rails g pig:install
rake db:migrate
# Optional (but recommended - Pig can seed some defaults to get you up and trotting quickly.
rake pig:db:seed
```

If you take a look in your `config/routes.rb` file you should now see the Pig mounted, the default route for all pig admin functionality is `/admin`, this may be modified by editing:

```ruby
# config/initializers/pig.rb
config.mount_path = 'admin'
```

To run the cucumber tests you will need phantomjs, if you're on OSX it can be installed with:

```
brew install phantomjs
```

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

### Custom field types
Sometimes the predefined field types in Pig (Single line of text, rich text, boolean, etc) aren't enough. The following steps allow creation of custom types.

Add the following line to the Pig config initializer

    config.content_types = { my_custom_field: 'Display name' }

Create 2 new files in your application, the first file defines how the custom field will be rendered when editing the page. Pig uses [formtastic](https://github.com/justinfrench/formtastic) for all its inputs.
```ruby
# /app/inputs/my_custom_field_input.rb
class StoryTagsInput < FormtasticBootstrap::Inputs::SelectInput
  def input_html_options
    super.merge(class: "my-custom-input")
  end
end
```
The second file defines `get/set` for the value of the field.

```ruby
# /app/types/pig/my_custom_field_type.rb
module Pig
  class MyCustomFieldType < Type
    def get(content_package)
      super(content_package).do_custom_stuff
    end
  end
end
```
#### Thats it!
