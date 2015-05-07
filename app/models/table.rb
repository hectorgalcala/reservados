class Table < ActiveRecord::Base

	belongs_to :restaurant


	validates :seats, 		:presence => true,:numericality => { :only_integer => true , :greater_than => 0 }
	validates :quantity, 		:presence => true,:numericality => { :only_integer => true , :greater_than => 0 }
	validates :restaurant_id, 		:presence => true,:numericality => { :only_integer => true , :greater_than => 0 }
end
