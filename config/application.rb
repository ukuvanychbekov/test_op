#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative 'boot'

require 'rails/all'
require 'active_support'
require 'active_support/dependencies'
require 'core_extensions'
require "view_component"
require "primer/view_components/engine"

# Silence deprecations early on for testing on CI and production
ActiveSupport::Deprecation.silenced =
  (Rails.env.production? && !ENV['OPENPROJECT_SHOW_DEPRECATIONS']) ||
  (Rails.env.test? && ENV.fetch('CI', nil))

if defined?(Bundler)
  # Require the gems listed in Gemfile, including any gems
  # you've limited to :test, :development, or :production.
  Bundler.require(*Rails.groups(:opf_plugins))
end

require_relative '../lib_static/open_project/configuration'

module OpenProject
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Initialize configuration defaults for a Rails version.
    #
    # This includes defaults for versions prior to the target version. See the
    # configuration guide at
    # https://guides.rubyonrails.org/configuring.html#versioned-default-values
    # for the default values associated with a particular version.
    #
    # Goal is to reach 7.0 defaults. Overridden defaults should be stored in
    # specific initializers files. See
    # https://community.openproject.org/wp/45463 for details.
    config.load_defaults 5.0

    # Do not require `belongs_to` associations to be present by default.
    # Rails 5.0+ default is true. Because of history, lots of tests fail when
    # set to true.
    config.active_record.belongs_to_required_by_default = false

    # Sets up logging for STDOUT and configures the default logger formatter
    # so that all environments receive level and timestamp information
    #
    # Use default logging formatter so that PID and timestamp are not suppressed.
    config.log_formatter = ::Logger::Formatter.new

    # Set up the cache store based on our configuration
    config.cache_store = OpenProject::Configuration.cache_store_configuration

    # Set up STDOUT logging if requested
    if ENV["RAILS_LOG_TO_STDOUT"].present?
      logger           = ActiveSupport::Logger.new($stdout)
      logger.formatter = config.log_formatter
      # Prepend all log lines with the following tags.
      config.log_tags = [:request_id]
      config.logger = ActiveSupport::TaggedLogging.new(logger)
    end

    # Use Rack::Deflater to gzip/deflate all the responses if the
    # HTTP_ACCEPT_ENCODING header is set appropriately. As Rack::ETag as
    # Rack::Deflater adds a timestamp to the content which would result in a
    # different ETag on every request, Rack::Deflater has to be in the chain of
    # middlewares after Rack::ETag.  #insert_before is used because on
    # responses, the middleware stack is processed from top to bottom.
    config.middleware.insert_before Rack::ETag,
                                    Rack::Deflater,
                                    if: lambda { |_env, _code, headers, _body|
                                      # Firefox fails to properly decode gzip attachments
                                      # We thus avoid deflating if sending gzip already.
                                      content_type = headers['Content-Type']
                                      content_type != 'application/x-gzip'
                                    }

    config.middleware.use Rack::Attack
    # Ensure that tempfiles are cleared after request
    # http://stackoverflow.com/questions/4590229
    config.middleware.use Rack::TempfileReaper

    # Custom directories with classes and modules you want to be autoloadable.
    config.enable_dependency_loading = true
    config.paths.add Rails.root.join('lib').to_s, eager_load: true
    config.paths.add Rails.root.join('lib/constraints').to_s, eager_load: true

    # Add lookbook preview paths when enabled
    if OpenProject::Configuration.lookbook_enabled?
      config.paths.add Primer::ViewComponents::Engine.root.join('app/components').to_s, eager_load: true
      config.paths.add Rails.root.join("lookbook/previews").to_s, eager_load: true
      config.paths.add Primer::ViewComponents::Engine.root.join('previews').to_s, eager_load: true
    end

    # Constants in lib_static should only be loaded once and never be unloaded.
    # That directory contains configurations and patches to rails core functionality.
    config.autoload_once_paths << Rails.root.join('lib_static').to_s

    # Use our own error rendering for prettier error pages
    config.exceptions_app = routes

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # Add locales from crowdin translations to i18n
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', 'crowdin', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en

    # Fall back to default locale
    config.i18n.fallbacks = true

    # Enable serialization of types [Symbol, Date, Time]
    config.active_record.yaml_column_permitted_classes = [Symbol, Date, Time, ActiveSupport::HashWithIndifferentAccess]

    # Include tstzrange columns in the list of time zone aware types
    ActiveRecord::Base.time_zone_aware_types += [:tstzrange]

    # Activate being able to specify the format in which full_message works.
    # Doing this, it is e.g. possible to avoid having the format of '%{attribute} %{message}' which
    # will always prepend the attribute name to the error message.
    # The formats can then be specified using the `format:` key within the [local].yml file in every
    # layer of activerecord.errors down to the individual level of the message, e.g.
    # activerecord.errors.models.project.attributes.types.format
    config.active_model.i18n_customize_full_message = true

    # Enable cascade key lookup for i18n
    I18n.backend.class.send(:include, I18n::Backend::Cascade)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = 'utf-8'

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Make Active Record use stable #cache_key alongside new #cache_version method.
    # This is needed for recyclable cache keys.
    # We will want check https://blog.heroku.com/cache-invalidation-rails-5-2-dalli-store
    # and test if we can enable this in the long run
    # Rails.application.config.active_record.cache_versioning = true

    # Use AES-256-GCM authenticated encryption for encrypted cookies.
    # Also, embed cookie expiry in signed or encrypted cookies for increased security.
    #
    # This option is not backwards compatible with earlier Rails versions.
    # It's best enabled when your entire app is migrated and stable on 5.2.
    #
    # Existing cookies will be converted on read then written with the new scheme.
    Rails.application.config.action_dispatch.use_authenticated_cookie_encryption = true

    # Use AES-256-GCM authenticated encryption as default cipher for encrypting messages
    # instead of AES-256-CBC, when use_authenticated_message_encryption is set to true.
    Rails.application.config.active_support.use_authenticated_message_encryption = true

    # Use SHA-1 instead of MD5 to generate non-sensitive digests, such as the ETag header.
    Rails.application.config.active_support.hash_digest_class = ::Digest::SHA1

    # This option is not backwards compatible with earlier Rails versions.
    # It's best enabled when your entire app is migrated and stable on 6.0.
    Rails.application.config.action_dispatch.use_cookies_with_metadata = true

    # Make `form_with` generate id attributes for any generated HTML tags.
    # Rails.application.config.action_view.form_with_generates_ids = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    config.active_record.schema_format = :sql

    # Load any local configuration that is kept out of source control
    # (e.g. patches).
    if File.exist?(File.join(File.dirname(__FILE__), 'additional_environment.rb'))
      instance_eval File.read(File.join(File.dirname(__FILE__), 'additional_environment.rb'))
    end

    # initialize variable for register plugin tests
    config.plugins_to_test_paths = []

    # Configure the relative url root to be whatever the configuration is set to.
    # This allows for setting the root either via config file or via environment variable.
    config.action_controller.relative_url_root = OpenProject::Configuration['rails_relative_url_root']

    config.active_job.queue_adapter = :delayed_job

    config.action_controller.asset_host = OpenProject::Configuration::AssetHost.value

    # Return false instead of self when enqueuing is aborted from a callback.
    # Rails.application.config.active_job.return_false_on_aborted_enqueue = true

    config.log_level = OpenProject::Configuration['log_level'].to_sym

    # Enable the Rails 7 cache format
    config.active_support.cache_format_version = 7.0

    config.after_initialize do
      Settings::Definition.add_all
    end

    def self.root_url
      "#{Setting.protocol}://#{Setting.host_name}"
    end

    ##
    # Load core and engine tasks we're interested in
    def self.load_rake_tasks
      load_tasks
      Doorkeeper::Rake.load_tasks
    end
  end
end
