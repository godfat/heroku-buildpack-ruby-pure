# WHY?

Because we're trying to deploy a pure Rack app with Rails files located
in the same repository, and we DON'T want to precompile assets. We just
want plain old Ruby.

# FEATURES

* Only `bundle install`, no `rake assets:precompile`
* Specify `ENV['BUNDLE_GEMFILE']` to locate `Gemfile`
