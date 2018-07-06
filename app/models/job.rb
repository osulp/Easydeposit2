class Job < ActiveRecord::Base
  belongs_to :publication, autosave: true, inverse_of: :jobs, optional: true

  HARVESTED_NEW = { name: 'Harvest New Publication', status: 'completed' }
  HARVEST = { name: 'Harvest Records from Web Of Science' }
end
