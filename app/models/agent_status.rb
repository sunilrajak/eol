# Enumerated list of statuses for an Agent.  For now, mainly distinguishing between active, archived, and pending agents.
class AgentStatus < SpeciesSchemaModel
  has_many :content_partners
    
  # Find the "Active" AgentStatus.
  def self.active
    cached_find(:label, 'Active')
  end 

  # Find the "Inactive" AgentStatus.
  def self.inactive
    cached_find(:label, 'Inactive')
  end 
  
end
