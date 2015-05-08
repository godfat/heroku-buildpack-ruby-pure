
require 'language_pack'
require 'language_pack/shell_helpers'
require 'language_pack/base'
require 'language_pack/ruby'

module Debug
  def copy from, to
    puts "FROM: #{prepend(from)}, TO: #{prepend(to)}"
    super(prepend(from), prepend(to))
  end

  def prepend path
    if @prefix && !path.to_s.start_with?('/')
      "#{@prefix}/#{path}"
    else
      path
    end
  end

  def read key
    super(prepend(key))
  end

  def exists? key
    super(prepend(key))
  end

  def write key, value, isave=true
    full_key = prepend("vendor/heroku/#{key}")
    FileUtils.mkdir_p(File.dirname(full_key))
    puts "WRITE: #{full_key}, #{value}"
    File.write(full_key, "#{value}\n")
    save if isave
  end
end

LanguagePack::Cache.prepend Debug
LanguagePack::Metadata.prepend Debug

class LanguagePack::RubyPure < LanguagePack::Ruby
  def create_database_yml            ; end
  def run_assets_precompile_rake_task; end
  def default_process_types          ; end

  def self.bundler
    @bundler ||= begin
      gemfile = if bundle_gemfile = env['BUNDLE_GEMFILE']
        puts "=====> BUNDLE_GEMFILE detected, using #{bundle_gemfile}"
        "#{Dir.pwd}/#{bundle_gemfile}"
      end
      LanguagePack::Helpers::BundlerWrapper.
        new(:gemfile_path => gemfile).install
    end
  end

  def self.env
    LanguagePack::ShellHelpers.user_env_hash
  end

  def build_bundler
    if bundle_gemfile = self.class.env['BUNDLE_GEMFILE']
      prefix = File.dirname(bundle_gemfile)

      # relocate bin
      set_env_override 'PATH',
                       "$HOME/#{prefix}/#{bundler_binstubs_path}:$PATH"

      # relocate cache
      cache    .instance_variable_set(:@prefix, prefix)
      @metadata.instance_variable_set(:@prefix, prefix)
    end

    super
  end

  def pipe cmd, opts
    if opts[:env] && (bundle_gemfile = self.class.env['BUNDLE_GEMFILE'])
      opts[:env]['BUNDLE_GEMFILE'] = "#{Dir.pwd}/#{bundle_gemfile}"
    end
    super
  end
end

LanguagePack::ShellHelpers.initialize_env(ARGV[2])
pack = LanguagePack::RubyPure.new(ARGV[0], ARGV[1])
pack.topic("Compiling #{pack.name}")
pack.log("compile") do
  pack.compile
end
