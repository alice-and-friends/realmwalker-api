class RealWorldLocation < ApplicationRecord
	self.inheritance_column = nil
	# attr_accessor :name, :type, :coordinates, :ext_id
	validates :name, presence: true
	validates :type, presence: true
	validates :ext_id, presence: true
	validates :coordinates, presence: true
	scope :for_npc, -> { where(type: 'npc') }
	scope :for_dungeon, -> { where(type: 'dungeon') }
end
