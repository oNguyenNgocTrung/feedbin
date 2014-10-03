class FaviconScheduler
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform
    Feed.select(:id, :host).find_in_batches(batch_size: 10_000) do |feeds|
      Sidekiq::Client.push_bulk(
        'args'  => feeds.map{ |feed| [feed.host] },
        'class' => 'FaviconFetcher',
        'queue' => 'default',
        'retry' => false
      )
    end
  end

end