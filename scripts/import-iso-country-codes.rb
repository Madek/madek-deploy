# configuration:

# id of the new MetaKey, all iso countries will be keywords there:
# $ export NEW_META_KEY='myvocab:mymetakey'
NEW_META_KEY = 'imported:iso_country_code'

# Optionally: if a text-based MetaKey already exists, it can be migrated
OLD_META_KEY = nil

# checks:
if MetaKey.find_by(id: NEW_META_KEY).present?
  puts "WARN: New Metakey already present! Already migrated?"
  exit 1
end

if OLD_META_KEY && !(old_mkey = MetaKey.find_by(id: OLD_META_KEY)).present?
  puts "ERROR: Old Metakey given, but not found!" \
       "check `$ env | grep MADEK_MIGRATE_ISO_COUNTRY_META_KEY`"
  exit 1
end

# NOTE: no https available :(
DATA_URL = 'http://download.geonames.org/export/dump/countryInfo.txt'
EXTERNAL_URL_BASE = 'http://geonames.org/countries'
LABEL_LANGUAGE = Settings.madek_default_locale || "de"
# LABELS_FILE = "./node_modules/i18n-iso-countries/langs/#{LABEL_LANGUAGE}.json"
LABELS_FILE_URL = "https://unpkg.com/i18n-iso-countries@3.6.1/langs/#{LABEL_LANGUAGE}.json"

# get data
names_by_code = begin
  JSON.parse(`curl '#{LABELS_FILE_URL}'`.chomp)['countries']
rescue => e
  Rails.logger.warn e
  fail "Label Language not found! see "\
    "https://www.npmjs.com/package/i18n-iso-countries#supported-languages \n\n" + e
end

countries = `curl '#{DATA_URL}'`.chomp
  .split("\n")
  .reject { |line| line.start_with? '#' }
  .map {|line| line.split "\t" }
  .map {|fields| {code: fields[0], name: fields[4]}}


ActiveRecord::Base.transaction do
  # prepare meta config
  vocab_id = NEW_META_KEY.split(':').first
  vocab = Vocabulary.find_by(id: vocab_id) || Vocabulary.create!(
    id: vocab_id,
    label: vocab_id.humanize,
    enabled_for_public_use: false, enabled_for_public_view: false)

  mkey = MetaKey.create!(
    id: NEW_META_KEY, vocabulary: vocab, meta_datum_object_type: 'MetaDatum::Keywords')

  # migrate old MetaKey if was given
  if old_mkey
    mkey.update_attributes!(
      old_mkey.attributes
        .except('id', 'vocabulary_id', 'meta_datum_object_type')
        .merge(
          admin_comment: \
            "[Migrated from '#{old_mkey.id}' on #{DateTime.now.utc.as_json}]" + \
            "\n" + (old_mkey.admin_comment || '')))
  end

  keyword_type = RdfClass.find_or_create_by!(id: 'Country')
  keyword_type.update_attributes!(description: 'Country, identified by 2-letter code (ISO-3166)')

  # add all countries as custom keywords
  countries.each do |country|
    code = country[:code]
    uri = "#{EXTERNAL_URL_BASE}/#{code}/"
    name = names_by_code[code]
    flag = code.each_codepoint.map { |c| c + 127397 }.pack('U*').force_encoding('UTF-8') # unicode flag
    term = "#{code} - #{name}".force_encoding('UTF-8')
    description = "#{name} - #{code} - #{flag}".force_encoding('UTF-8')

    kw = Keyword.find_by(meta_key_id: mkey.id, external_uri: uri)
    kw ||= Keyword.create!(term: term, meta_key_id: mkey.id, external_uri: uri)
    kw.update_attributes!(rdf_class: keyword_type, description: description)
  end

  # migrate old MetaData if old MetaKey was given
  if old_mkey
    MetaDatum.where(meta_key_id: OLD_META_KEY).each do |meta_datum|
      # find the resource of the MD
      resource = meta_datum.media_entry || meta_datum.collection || meta_datum.filter_set

      # abort if there is already an MD for the NEW KEY
      next if resource.meta_data.where(meta_key_id: mkey.id).any?

      # find the Country-keyword for this Text,
      # or add it as new one (must be cleaned up manually)
      code = meta_datum.string
      uri = "#{EXTERNAL_URL_BASE}/#{code}/"
      keyword = Keyword.find_by(external_uri: uri, meta_key: mkey)
      unless keyword
        keyword = Keyword.find_or_create_by!(term: meta_datum.string, meta_key: mkey)
        keyword.update_attributes!(
          description: 'MADEK_SYSTEM_INVALID_ISO_COUNTRY_CODE')
      end

      # we need a 'creator' for new MD, but it might not exist in old MD.
      # find the responsible user for the resource and
      creator = meta_datum.created_by || resource.responsible_user

      # copy MetaDatum
      MetaDatum::Keywords.create_with_user!(
        creator,
        meta_datum.attributes
          .except('id', 'type', 'string')
          .merge(meta_key_id: mkey.id, value: keyword, created_by: creator))
    end
  end
end

puts 'OK'
