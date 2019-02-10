episodes = [ 
  { audio: '+++++[MID]++++[MID]++++[POST]', id: 'kld-412' }, ### is "dag-532" and "dag-523" intended in the instructions?
  { audio: '[PRE][PRE]+++++[MID]+++[MID]+++++[POST]', id: 'abc-444' },
  { id: 'dag-892', audio: '++++[MID]++++[MID]++++[POST]' },
  { id: 'abc-123', audio: '[PRE]++++[MID]++++[MID]++[MID]++[POST]' },
  { id: 'hab-812', audio: '[PRE][PRE]++++[MID]++++[MID]++[MID]++[POST]' },
  { id: 'efa-931', audio: '[PRE][PRE]++++++++++' },
  { id: 'paj-103', audio: '++++[MID]+++++[MID]++++[MID]++[POST]' },
  
]

campaigns = [
    [
  { audio: "*AcmeA*", type: "PRE", targets: ["dag-523"], revenue: 12 },
  { audio: "*AcmeB*", type: "MID", targets: ["dag-523"], revenue: 4 },
  { audio: "*AcmeC*", type: "MID", targets: ["dag-523"], revenue: 14 }
],
  [
    { audio: '*AcmeA*', type: 'PRE', targets: ['dag-892', 'hab-812'], revenue: 1 },
    { audio: '*AcmeB*', type: 'MID', targets: ['dag-892', 'hab-812'], revenue: 4 },
    { audio: '*AcmeC*', type: 'MID', targets: ['dag-892', 'hab-812'], revenue: 5 }
  ],

  [
    { audio: '*TacoCat*', type: 'MID', targets: ['abc-123', 'dag-892'], revenue: 3 }
  ],
  [
    { audio: '*CorpCorpA*', type: 'PRE', targets: ['abc-123', 'dag-892'], revenue: 11 },
    { audio: '*CorpCorpB*', type: 'POST', targets: ['abc-123', 'dag-892'], revenue: 7 }
  ], [
    { audio: '*FurryDogA*', type: 'PRE', targets: ['dag-892', 'hab-812', 'efa-931'], revenue: 11 },
    { audio: '*FurryDogB*', type: 'PRE', targets: ['dag-892', 'hab-812', 'efa-931'], revenue: 7 }

  ],
  [
    { audio: '*GiantGiraffeA*', type: 'MID', targets: ['paj-103', 'abc-123'], revenue: 9 },
    { audio: '*GiantGiraffeB*', type: 'MID', targets: ['paj-103', 'abc-123'], revenue: 4 }
  ],
  [
  { audio: "*CorpCorp*", type: "POST", targets: ["afs-354", "dag-523"], revenue: 3 }
]

].flatten

class Campaign
  def initialize(target)
    @target = target
    @ads = Hash.new { |h, k| h[k] = [] } # ideally this would be a priority queue instead of array
  end

# load up campaign with ads and it will sort them by revenue descending
# categorizes and sorts by type
  def <<(ad)
    @ads[ad[:type]] << ad if ad[:targets].include?(@target)
    @ads[ad[:type]].sort! { |a, b| b[:revenue] <=> a[:revenue] } # => sort these on insert
  end

  # return highest revenue ad of type
  def next_ad(type)
    if item = @ads[type].shift
      item[:audio]
    else
      ''
    end
  end
end

# manageages campaigns and manages them by target
class Campaigns
  def initialize
    @h = Hash.new { |h, k| h[k] = Campaign.new(k) } # init nil key with Campaign object
  end

  def self.from_campaigns(campaigns) # constructor
    new.tap do |c| # tap keeps it clean, but prolly not everyone likes it
      c << campaigns
    end
  end

  def <<(items)
    Array(items).each do |item|
      item[:targets].each do |target|
        @h[target] << item # calling campaign << operator so this is always sorted!
      end
    end
  end

  private def next_ad(campaign, type)
    if campaign = @h[campaign] # checks for key existence
      campaign.next_ad(type)
    else
        ""
    end
  end

  def insert_ads(episode)
    (episode[:audio].dup).tap do |audio|
      %w[PRE MID POST].each do |type|
        true while audio.sub!("[#{type}]") do |_match|
                     next_ad(episode[:id], type)
                   end
      end
    end
end
end

# iterate all episodes and insert ads
episodes.each do |episode|
  c = Campaigns.from_campaigns(campaigns)
  puts format("%-10s: %s\n", episode[:id], c.insert_ads(episode))
end

# => 
# kld-412   : +++++++++++++
# abc-444   : +++++++++++++
# dag-892   : ++++*AcmeC*++++*AcmeB*++++*CorpCorpB*
# abc-123   : *CorpCorpA*++++*GiantGiraffeA*++++*GiantGiraffeB*++*TacoCat*++*CorpCorpB*
# hab-812   : *FurryDogA**FurryDogB*++++*AcmeC*++++*AcmeB*++++
# efa-931   : *FurryDogA**FurryDogB*++++++++++
# paj-103   : ++++*GiantGiraffeA*+++++*GiantGiraffeB*++++++
