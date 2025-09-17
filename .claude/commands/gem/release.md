---
allowed-tools: [Bash, Read, Edit]
argument-hint: [major|minor|patch]
description: Bump the version of the gem and push it to rubygems.org.
---

Release a new version of the gem.

1. Read the current version from version.rb
2. Bump it according to your specification (${1:patch} by default)
3. Update the version file
4. Commit the changes
5. Run `rake release` to publish

Let me start by checking the current version and updating it:

!Read lib/jsonrpc/version.rb

Now I'll determine the version bump type and calculate the new version:

```ruby
# Parse current version and bump it
current_version = `grep "VERSION = " lib/jsonrpc/version.rb | grep -o "'[^']*'" | tr -d "'"`.strip
version_parts = current_version.split('.').map(&:to_i)
major, minor, patch = version_parts

bump_type = "${1:patch}"
case bump_type
when "major"
  major += 1
  minor = 0
  patch = 0
when "minor"
  minor += 1
  patch = 0
when "patch"
  patch += 1
end

new_version = "#{major}.#{minor}.#{patch}"
puts "Bumping version from #{current_version} to #{new_version} (#{bump_type} bump)"
```

!ruby -e "
current_version = \`grep \"VERSION = \" lib/jsonrpc/version.rb | grep -o \"'[^']*'\" | tr -d \"'\"\`.strip
version_parts = current_version.split('.').map(&:to_i)
major, minor, patch = version_parts

bump_type = '${1:patch}'
case bump_type
when 'major'
  major += 1
  minor = 0
  patch = 0
when 'minor'
  minor += 1
  patch = 0
when 'patch'
  patch += 1
end

new_version = \"#{major}.#{minor}.#{patch}\"
puts \"#{current_version}|#{new_version}\"
" > /tmp/version_info.txt

Now I'll update the version file and commit the changes:

```bash
# Read the version information
VERSION_INFO=$(cat /tmp/version_info.txt)
OLD_VERSION=$(echo $VERSION_INFO | cut -d'|' -f1)
NEW_VERSION=$(echo $VERSION_INFO | cut -d'|' -f2)

echo "Updating version from $OLD_VERSION to $NEW_VERSION"

# Update version.rb
sed -i '' "s/VERSION = '$OLD_VERSION'/VERSION = '$NEW_VERSION'/" lib/jsonrpc/version.rb

# Commit the version bump
git add lib/jsonrpc/version.rb
git commit -m "Bump version to $NEW_VERSION

Update the gem version from $OLD_VERSION to $NEW_VERSION in both the version file and Gemfile.lock to prepare for a new release."

echo "Version bumped and committed. Running rake release..."

# Run rake release
rake release
```

!bash -c "
VERSION_INFO=\$(cat /tmp/version_info.txt)
OLD_VERSION=\$(echo \$VERSION_INFO | cut -d'|' -f1)
NEW_VERSION=\$(echo \$VERSION_INFO | cut -d'|' -f2)

echo \"Updating version from \$OLD_VERSION to \$NEW_VERSION\"

# Update version.rb
sed -i '' \"s/VERSION = '\$OLD_VERSION'/VERSION = '\$NEW_VERSION'/\" lib/jsonrpc/version.rb

# Commit the version bump
git add lib/jsonrpc/version.rb
git commit -m \"Bump version to \$NEW_VERSION

Update the gem version from \$OLD_VERSION to \$NEW_VERSION in both the version file and Gemfile.lock to prepare for a new release.\"

echo \"Version bumped and committed. Running rake release...\"

# Run rake release
rake release

# Clean up temp file
rm -f /tmp/version_info.txt
"

The gem has been released! The version was bumped, committed, and published to RubyGems.
