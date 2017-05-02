class Resmap

  def initialize(user = nil, pass = nil, host = nil)
    user ||= Settings.resmap.user || (raise "Resource Map user is not set")
    pass ||= Settings.resmap.pass || (raise "Resource Map pass is not set")
    host ||= Settings.resmap.host || (raise "Resource Map host is not set")
    @api = ResourceMap::Api.basic_auth(user, pass, host)
  end

  def import_sites(collection_id = nil)
    collection_id ||= Settings.resmap.collection_id || (raise "Resource Map collection id is not set")
    @api.collections.find(collection_id).sites.all.each { |site| yield site if block_given? }
  end

  def self.edit_site_url(site_id)
    "http://#{Settings.resmap.host}/en/collections?editing_site=#{site_id}&collection_id=#{Settings.resmap.collection_id}&z=12"
  end
end
